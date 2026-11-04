import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';

import 'analytics_ids.dart';
export 'analytics_ids.dart' show isAnalyticsUuid;
import '../auth/guest_auth_guard.dart';
import '../auth/session_snapshot.dart';
import '../auth/token_storage.dart';
import '../network/api_config.dart';
import '../network/auth_interceptor.dart';
import '../network/api_exception.dart';

/// Opt-in only after approved QA. Never enabled by a release/preview helper.
const patientAnalyticsEnabled = bool.fromEnvironment(
  'AW_ENABLE_PATIENT_ANALYTICS',
  defaultValue: false,
);

enum PatientEventType {
  appOpen('app_open'),
  clinicView('clinic_view'),
  whatsappTap('whatsapp_tap'),
  callTap('call_tap'),
  mapsTap('maps_tap');

  const PatientEventType(this.wire);
  final String wire;
}

/// Only source-confirmed navigation enums, never user-entered metadata.
enum PatientSurface {
  app,
  home,
  clinicList('clinic_list'),
  clinicProfile('clinic_profile'),
  clinicDetails('clinic_details'),
  maps;

  const PatientSurface([String? wire]) : _wire = wire;
  final String? _wire;
  String get wire => _wire ?? name;
}

class PatientAttribution {
  const PatientAttribution(
    this.clinicId, {
    this.branchId,
    this.surface = PatientSurface.clinicProfile,
  });
  final String clinicId;
  final String? branchId;
  final PatientSurface surface;
}

abstract interface class PatientEventSender {
  Future<Response<Object?>> send(
    Map<String, Object> body,
    CancelToken cancellation, {
    required int sessionEpoch,
  });
}

/// Dedicated transport: telemetry failures cannot throttle consultation/API work.
/// Uses the same authenticated-origin/refresh/session protections as ApiClient.
class DioPatientEventSender implements PatientEventSender {
  DioPatientEventSender({Dio? dio, Dio? refreshDio}) : _dio = dio ?? Dio() {
    _dio.interceptors.add(AuthInterceptor(_dio, refreshDio: refreshDio));
  }
  final Dio _dio;
  @override
  Future<Response<Object?>> send(
    Map<String, Object> body,
    CancelToken cancellation, {
    required int sessionEpoch,
  }) async {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 8);
    try {
      return await _dio.post<Object?>(
        'analytics/events/',
        data: body,
        cancelToken: cancellation,
        options: Options(
          contentType: Headers.jsonContentType,
          followRedirects: false,
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          extra: {'aw_auth_session': sessionEpoch},
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }
}

class _PendingEvent {
  _PendingEvent(this.body, this.created, this.session)
    : tokenEpoch = TokenStorage().sessionEpoch;
  final int tokenEpoch;
  final Map<String, Object> body;
  final DateTime created;
  final SessionSnapshot session;
  int attempts = 0;
}

/// No disk queue, PII, anonymous identity, raw diagnostics or lead events.
/// Calls are fire-and-forget; failures never affect the user's real action.
class PatientAnalytics {
  PatientAnalytics({
    PatientEventSender? sender,
    this.enabled = patientAnalyticsEnabled,
    DateTime Function()? now,
    String Function()? eventId,
    this.retryDelay = const Duration(seconds: 2),
    this.deadline = const Duration(seconds: 8),
  }) : _sender = sender ?? DioPatientEventSender(),
       _now = now ?? DateTime.now,
       _eventId = eventId ?? newAnalyticsEventId {
    AuthState().addListener(_sessionChanged);
  }

  static final instance = PatientAnalytics();
  final PatientEventSender _sender;
  final bool enabled;
  final DateTime Function() _now;
  final String Function() _eventId;
  final Duration retryDelay, deadline;
  static const maxPending = 20, maxViewedClinics = 200, maxTapKeys = 128;
  static const eventLifetime = Duration(minutes: 2);
  final _pending = ListQueue<_PendingEvent>();
  final _views = <String>{};
  final _taps = <String, DateTime>{};
  String? _scope;
  bool _opened = false, _draining = false, _disposed = false;
  int _acknowledged = 0, _duplicates = 0;
  Timer? _retry;
  CancelToken? _active;

  // Ephemeral ACK diagnostics, never analytics/reporting totals or UI success.
  bool get canRecord => _eligible;
  int get acknowledgedEvents => _acknowledged;
  int get duplicateAcknowledgments => _duplicates;
  int get pendingEvents => _pending.length + (_active == null ? 0 : 1);

  bool get _eligible =>
      !_disposed &&
      enabled &&
      AuthState().isLoggedIn &&
      AuthState().isPatient &&
      AuthState().isVerified &&
      TokenStorage().currentAccessToken?.isNotEmpty == true;

  String get _currentScope =>
      '${AuthState().sessionEpoch}:${TokenStorage().sessionEpoch}';

  void _sessionChanged() {
    if (!_eligible || _scope != _currentScope) _clear();
  }

  void _clear() {
    _active?.cancel('Analytics session ended');
    _retry?.cancel();
    _retry = null;
    _pending.clear();
    _views.clear();
    _taps.clear();
    _opened = false;
    _acknowledged = 0;
    _duplicates = 0;
    _scope = null;
  }

  void appOpened() => record(PatientEventType.appOpen);

  void clinicViewed(PatientAttribution attribution) =>
      record(PatientEventType.clinicView, attribution: attribution);

  void record(PatientEventType type, {PatientAttribution? attribution}) {
    try {
      _enqueue(type, attribution: attribution);
    } catch (_) {
      // Analytics is best effort, including local UUID/clock failures.
      // Never prevent a real phone, WhatsApp or Maps handoff.
    }
  }

  void _enqueue(PatientEventType type, {PatientAttribution? attribution}) {
    if (!_eligible) return;
    if (_scope != _currentScope) {
      _clear();
      _scope = _currentScope;
    }
    if (type != PatientEventType.appOpen &&
        (attribution == null ||
            !isAnalyticsUuid(attribution.clinicId) ||
            (attribution.branchId != null &&
                !isAnalyticsUuid(attribution.branchId!)))) {
      return;
    }
    if (type == PatientEventType.appOpen && attribution != null) return;
    if (_pending.length >= maxPending) return;
    if (type == PatientEventType.appOpen) {
      if (_opened) return;
      _opened = true;
    } else if (type == PatientEventType.clinicView) {
      // One visible, public clinic profile per authenticated app session.
      if (_views.length >= maxViewedClinics ||
          !_views.add(attribution!.clinicId)) {
        return;
      }
    } else {
      final now = _now();
      _taps.removeWhere(
        (_, at) => now.difference(at) >= const Duration(seconds: 2),
      );
      final key =
          '${type.wire}|${attribution!.clinicId}|${attribution.branchId}';
      if (_taps.containsKey(key) || _taps.length >= maxTapKeys) return;
      _taps[key] = now;
    }
    final id = _eventId();
    if (!isAnalyticsUuid(id)) return;
    final body = Map<String, Object>.unmodifiable({
      'event_id': id.toLowerCase(),
      'event_type': type.wire,
      if (attribution != null) 'clinic': attribution.clinicId,
      if (attribution?.branchId != null) 'branch': attribution!.branchId!,
      'metadata': Map<String, String>.unmodifiable({
        'source': 'patient_app',
        'surface': attribution?.surface.wire ?? 'app',
        'action': switch (type) {
          PatientEventType.appOpen => 'open',
          PatientEventType.clinicView => 'view',
          _ => 'tap',
        },
      }),
    });
    _pending.add(_PendingEvent(body, _now(), SessionSnapshot()));
    _startDrain();
  }

  void _startDrain() {
    unawaited(
      _drain().catchError((Object _) {
        _clear();
      }),
    );
  }

  Future<void> _drain() async {
    if (_draining || _retry != null || !_eligible) return;
    _draining = true;
    try {
      while (_pending.isNotEmpty && _eligible) {
        final event = _pending.removeFirst();
        if (!event.session.isCurrent ||
            _now().difference(event.created) > eventLifetime) {
          continue;
        }
        final token = CancelToken();
        _active = token;
        var timedOut = false;
        final timer = Timer(deadline, () {
          timedOut = true;
          token.cancel('Analytics deadline');
        });
        try {
          final response = await _sender.send(
            event.body,
            token,
            sessionEpoch: event.tokenEpoch,
          );
          if (!event.session.isCurrent) continue;
          final data = response.data;
          final expected = response.statusCode == 201
              ? 'created'
              : response.statusCode == 200
              ? 'duplicate'
              : null;
          // An unrecognized ACK is never classified as a saved event or retried.
          if (expected == null ||
              data is! Map ||
              data['status'] != expected ||
              data['event_id'] != event.body['event_id'] ||
              data['ingestion_version'] != 2) {
            continue;
          }
          _acknowledged++;
          if (expected == 'duplicate') _duplicates++;
        } catch (error) {
          if (!_eligible || !event.session.isCurrent) continue;
          if (error is ApiException && [401, 403].contains(error.statusCode)) {
            _clear();
            break;
          }
          final transient =
              timedOut ||
              (error is ApiException &&
                  (['TIMEOUT', 'CONNECTION_ERROR'].contains(error.errorCode) ||
                      error.statusCode == 429 ||
                      (error.statusCode != null && error.statusCode! >= 500)));
          final wait = error is ApiException && error.retryAfter != null
              ? error.retryAfter!
              : retryDelay;
          if (transient &&
              event.attempts++ == 0 &&
              wait <= const Duration(seconds: 60) &&
              _now().difference(event.created) + wait < eventLifetime) {
            _pending.addFirst(event);
            _retry = Timer(wait, () {
              _retry = null;
              _startDrain();
            });
            break;
          }
          // 400/409/413, cancelled sessions and unknown errors are terminal.
        } finally {
          timer.cancel();
          if (identical(_active, token)) _active = null;
        }
      }
    } finally {
      _draining = false;
    }
  }

  void dispose() {
    _disposed = true;
    _clear();
    AuthState().removeListener(_sessionChanged);
  }
}
