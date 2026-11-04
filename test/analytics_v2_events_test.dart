import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/analytics/patient_analytics.dart';
import 'package:aesthetic_way/core/analytics/patient_clinic_exposure.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/utils/contact_launcher.dart';
import 'scale_runtime_test.dart' show CallbackAdapter, body;

const clinic = '00000000-0000-4000-8000-000000000001';
const branch = '00000000-0000-4000-8000-000000000002';

Response<Object?> ack(Map<String, Object> data, [int status = 201]) => Response(
  requestOptions: RequestOptions(path: 'analytics/events/'),
  statusCode: status,
  data: {
    'event_id': data['event_id'],
    'ingestion_version': 2,
    'status': status == 200 ? 'duplicate' : 'created',
  },
);

class Sender implements PatientEventSender {
  final calls = <Map<String, Object>>[];
  Future<Response<Object?>> Function(Map<String, Object>)? reply;
  @override
  Future<Response<Object?>> send(
    Map<String, Object> data,
    CancelToken cancel, {
    required int sessionEpoch,
  }) {
    calls.add(data);
    return Future.any([
      reply?.call(data) ?? Future.value(ack(data)),
      cancel.whenCancel.then<Response<Object?>>(
        (_) => throw const ApiException(message: '', isCancelled: true),
      ),
    ]);
  }
}

Future<void> login({
  String role = 'patient',
  bool verified = true,
  String suffix = '1',
}) async {
  await TokenStorage().saveTokens(
    accessToken: 'synthetic-access-$suffix',
    refreshToken: 'synthetic-refresh-$suffix',
  );
  await TokenStorage().saveUser({
    'id': clinic,
    'phone': 'synthetic-$suffix',
    'role': role,
  });
  AuthState().login(
    name: 'Synthetic',
    phone: 'synthetic-$suffix',
    role: role,
    isVerified: verified,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    AuthState().logout();
    await TokenStorage().clear();
    ApiConfig.resetBaseUrl();
  });
  tearDown(() async {
    AuthState().logout();
    await TokenStorage().clear();
    ApiConfig.resetBaseUrl();
  });

  PatientAnalytics service(
    Sender sender, {
    bool enabled = true,
    DateTime Function()? now,
    Duration? deadline,
  }) {
    var counter = 0;
    final result = PatientAnalytics(
      sender: sender,
      enabled: enabled,
      now: now,
      retryDelay: const Duration(milliseconds: 10),
      deadline: deadline ?? const Duration(seconds: 8),
      eventId: () =>
          '11111111-1111-4111-8111-${(++counter).toString().padLeft(12, '0')}',
    );
    addTearDown(result.dispose);
    return result;
  }

  testWidgets(
    'Default emission flag is disabled; enabling still requires verified patient credentials',
    (tester) async {
      expect(patientAnalyticsEnabled, isFalse);
      final sender = Sender();
      final disabled = service(sender, enabled: false);
      await login();
      disabled.appOpened();
      disabled.clinicViewed(const PatientAttribution(clinic));
      await tester.pump();
      expect(sender.calls, isEmpty);
      expect(
        PatientEventType.values.map((t) => t.wire),
        isNot(contains('lead_submitted')),
      );
    },
  );
  for (final role in [
    'guest',
    'clinic_admin',
    'clinic_staff',
    'super_admin',
    'unverified',
  ]) {
    testWidgets('$role cannot queue or emit patient engagement', (
      tester,
    ) async {
      final sender = Sender();
      final target = service(sender);
      if (role != 'guest') {
        await login(
          role: role == 'unverified' ? 'patient' : role,
          verified: role != 'unverified',
        );
      }
      target.appOpened();
      target.clinicViewed(const PatientAttribution(clinic));
      target.record(
        PatientEventType.callTap,
        attribution: const PatientAttribution(clinic),
      );
      await tester.pump();
      expect(sender.calls, isEmpty);
      expect(target.pendingEvents, 0);
    });
  }
  testWidgets(
    'Wire payload is UUID-bound and enum-only; no user, token, phone, lead or arbitrary metadata',
    (tester) async {
      await login();
      final sender = Sender();
      final target = service(sender);
      target.record(
        PatientEventType.mapsTap,
        attribution: const PatientAttribution(
          clinic,
          branchId: branch,
          surface: PatientSurface.maps,
        ),
      );
      await tester.pump();
      final data = sender.calls.single;
      expect(data.keys.toSet(), {
        'event_id',
        'event_type',
        'clinic',
        'branch',
        'metadata',
      });
      expect(data['metadata'], {
        'source': 'patient_app',
        'surface': 'maps',
        'action': 'tap',
      });
      expect(data['clinic'], clinic);
      expect(data['branch'], branch);
      expect(isAnalyticsUuid(data['event_id']! as String), isTrue);
      expect(jsonEncode(data), isNot(contains('synthetic-access')));
      expect(target.acknowledgedEvents, 1);
      target.record(
        PatientEventType.appOpen,
        attribution: const PatientAttribution(clinic),
      );
      target.clinicViewed(const PatientAttribution('bad-id'));
      target.record(
        PatientEventType.mapsTap,
        attribution: const PatientAttribution(clinic, branchId: 'bad-id'),
      );
      await tester.pump();
      expect(sender.calls, hasLength(1));
    },
  );
  testWidgets(
    'App open/profile restoration/rebuild deduplicate; rapid contact taps collapse for2s',
    (tester) async {
      await login();
      var now = DateTime.utc(2026);
      final sender = Sender();
      final target = service(sender, now: () => now);
      for (var n = 0; n < 10; n++) {
        target.appOpened();
        target.clinicViewed(const PatientAttribution(clinic));
        target.record(
          PatientEventType.callTap,
          attribution: const PatientAttribution(clinic),
        );
      }
      await tester.pump();
      expect(sender.calls, hasLength(3));
      now = now.add(const Duration(seconds: 2));
      target.record(
        PatientEventType.callTap,
        attribution: const PatientAttribution(clinic),
      );
      await tester.pump();
      expect(sender.calls, hasLength(4));
      expect(sender.calls.map((e) => e['event_id']).toSet(), hasLength(4));
    },
  );
  testWidgets(
    'Network retry reuses exact UUID/body and accepts200 duplicate acknowledgment',
    (tester) async {
      await login();
      final sender = Sender();
      final target = service(sender);
      sender.reply = (data) async {
        if (sender.calls.length == 1) {
          throw const ApiException(
            message: 'synthetic network error',
            errorCode: 'CONNECTION_ERROR',
          );
        }
        return ack(data, 200);
      };
      target.appOpened();
      await tester.pump();
      expect(sender.calls, hasLength(1));
      expect(target.acknowledgedEvents, 0);
      await tester.pump(const Duration(milliseconds: 11));
      expect(sender.calls, hasLength(2));
      expect(identical(sender.calls[0], sender.calls[1]), isTrue);
      expect(target.acknowledgedEvents, 1);
      expect(target.duplicateAcknowledgments, 1);
      await tester.pump(const Duration(seconds: 2));
      expect(sender.calls, hasLength(2));
    },
  );
  for (final status in [400, 401, 403, 409, 413]) {
    testWidgets('HTTP$status never retries or reports an acknowledgment', (
      tester,
    ) async {
      await login();
      final sender = Sender();
      final target = service(sender);
      sender.reply = (_) async =>
          throw ApiException(message: 'synthetic failure', statusCode: status);
      target.appOpened();
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(sender.calls, hasLength(1));
      expect(target.acknowledgedEvents, 0);
      expect(target.pendingEvents, 0);
    });
  }
  testWidgets(
    'Unexpected acknowledgment is not success and does not cause an ingestion loop',
    (tester) async {
      await login();
      final sender = Sender();
      final target = service(sender);
      sender.reply = (_) async => Response(
        requestOptions: RequestOptions(),
        statusCode: 201,
        data: {'status': 'created', 'event_id': branch, 'ingestion_version': 1},
      );
      target.appOpened();
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(sender.calls, hasLength(1));
      expect(target.acknowledgedEvents, 0);
    },
  );
  testWidgets(
    '429 respects bounded Retry-After; long cooldown drops instead of retaining an unbounded timer',
    (tester) async {
      await login();
      final sender = Sender();
      final target = service(sender);
      sender.reply = (_) async => throw const ApiException(
        message: 'rate limited',
        statusCode: 429,
        retryAfter: Duration(seconds: 1),
      );
      target.appOpened();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 999));
      expect(sender.calls, hasLength(1));
      await tester.pump(const Duration(milliseconds: 1));
      expect(sender.calls, hasLength(2));
      await tester.pump(const Duration(seconds: 3));
      expect(sender.calls, hasLength(2));
      final other = Sender();
      final drop = service(other);
      other.reply = (_) async => throw const ApiException(
        message: 'long cooldown',
        statusCode: 429,
        retryAfter: Duration(hours: 1),
      );
      drop.appOpened();
      await tester.pump();
      expect(drop.pendingEvents, 0);
    },
  );
  testWidgets(
    'Queue is bounded and logout/account switching cancels old pending/retry work',
    (tester) async {
      await login();
      final sender = Sender();
      final target = service(sender);
      final gate = Completer<Response<Object?>>();
      sender.reply = (_) => gate.future;
      target.appOpened();
      for (var i = 1; i < 70; i++) {
        target.clinicViewed(
          PatientAttribution(
            '00000000-0000-4000-8000-${i.toString().padLeft(12, '0')}',
          ),
        );
      }
      expect(
        target.pendingEvents,
        lessThanOrEqualTo(PatientAnalytics.maxPending + 1),
      );
      AuthState().logout();
      await tester.pump();
      expect(target.pendingEvents, 0);
      await login(suffix: '2');
      sender.reply = (data) async => ack(data);
      target.appOpened();
      await tester.pump();
      gate.complete(ack(sender.calls.first));
      await tester.pump();
      expect(sender.calls, hasLength(2));
      expect(target.acknowledgedEvents, 1);
    },
  );
  testWidgets('Retry is discarded on role change and after event TTL', (
    tester,
  ) async {
    await login();
    var now = DateTime.utc(2026);
    final sender = Sender();
    final target = service(sender, now: () => now);
    sender.reply = (_) async => throw const ApiException(
      message: 'offline',
      errorCode: 'CONNECTION_ERROR',
    );
    target.appOpened();
    await tester.pump();
    now = now.add(const Duration(minutes: 3));
    await tester.pump(const Duration(milliseconds: 11));
    expect(sender.calls, hasLength(1));
    target.clinicViewed(const PatientAttribution(clinic));
    await tester.pump();
    AuthState().login(
      name: 'Synthetic',
      phone: 'synthetic-1',
      role: 'clinic_admin',
      isVerified: true,
    );
    await tester.pump(const Duration(seconds: 3));
    expect(sender.calls, hasLength(2));
    expect(target.pendingEvents, 0);
  });
  test(
    'Expired access refresh preserves event payload; rejected refresh clears session without loops',
    () async {
      for (final refreshStatus in [200, 401]) {
        await login(suffix: '$refreshStatus');
        final dio = Dio(), refresh = Dio();
        var writes = 0, refreshes = 0;
        final payloads = <Object?>[];
        dio.httpClientAdapter = CallbackAdapter((o) async {
          writes++;
          payloads.add(o.data);
          expect(o.followRedirects, isFalse);
          expect(o.uri.origin, Uri.parse(ApiConfig.baseUrl).origin);
          return o.headers['Authorization'] == 'Bearer renewed'
              ? body(201, {
                  'status': 'created',
                  'ingestion_version': 2,
                  'event_id': (o.data as Map)['event_id'],
                })
              : body(401, {});
        });
        refresh.httpClientAdapter = CallbackAdapter((_) async {
          refreshes++;
          return body(refreshStatus, {'access': 'renewed'});
        });
        final sender = DioPatientEventSender(dio: dio, refreshDio: refresh);
        final pending = sender.send(
          {
            'event_id': branch,
            'event_type': 'app_open',
            'metadata': {
              'source': 'patient_app',
              'surface': 'app',
              'action': 'open',
            },
          },
          CancelToken(),
          sessionEpoch: TokenStorage().sessionEpoch,
        );
        if (refreshStatus == 200) {
          expect((await pending).statusCode, 201);
          expect(payloads[0], payloads[1]);
        } else {
          await expectLater(pending, throwsA(isA<ApiException>()));
          expect(TokenStorage().currentAccessToken, isNull);
        }
        expect(refreshes, 1);
        expect(writes, refreshStatus == 200 ? 2 : 1);
        dio.close();
        refresh.close();
      }
    },
  );
  test(
    'Telemetry transport failures cannot place shared consultation API in backpressure',
    () async {
      await login();
      final dio = Dio();
      dio.httpClientAdapter = CallbackAdapter((_) async => body(503, {}));
      final sender = DioPatientEventSender(dio: dio);
      await expectLater(
        sender.send(
          {'event_id': branch, 'event_type': 'app_open'},
          CancelToken(),
          sessionEpoch: TokenStorage().sessionEpoch,
        ),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 503)),
      );
      final api = ApiClient(), original = ApiClient().dio.httpClientAdapter;
      var reads = 0;
      api.dio.httpClientAdapter = CallbackAdapter((_) async {
        reads++;
        return body(200, {'results': []});
      });
      try {
        expect((await api.get('leads/my/')).statusCode, 200);
        expect(reads, 1);
      } finally {
        api.dio.httpClientAdapter = original;
        dio.close();
      }
    },
  );
  test(
    'Contact handoff proceeds during analytics failure and never includes phone/message in payload',
    () async {
      await login();
      final sender = Sender();
      final analytics = service(sender);
      sender.reply = (_) async => throw const ApiException(
        message: 'synthetic denied',
        statusCode: 403,
      );
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (_) async => true);
      try {
        expect(
          await ContactLauncher.makePhoneCall(
            '+971501234567',
            attribution: const PatientAttribution(clinic),
            analytics: analytics,
          ),
          isTrue,
        );
        expect(
          await ContactLauncher.openWhatsApp(
            phoneNumber: '+971501234567',
            message: 'Synthetic private inquiry',
            attribution: const PatientAttribution(clinic),
            analytics: analytics,
          ),
          isTrue,
        );
        expect(jsonEncode(sender.calls), isNot(contains('501234567')));
        expect(jsonEncode(sender.calls), isNot(contains('private inquiry')));
      } finally {
        messenger.setMockMethodCallHandler(channel, null);
      }
    },
  );
  testWidgets(
    'Profile visibility requires public verification, current route, foreground, ticker and dwell; rebuilds do not recount',
    (tester) async {
      await login();
      final sender = Sender();
      final target = service(sender);
      var verified = false, hidden = true;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Offstage(
                offstage: hidden,
                child: PatientClinicExposure(
                  clinicId: clinic,
                  publicDetailVerified: verified,
                  analytics: target,
                  child: const Scaffold(body: Text('Public profile')),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(sender.calls, isEmpty);
      update(() {
        hidden = false;
      });
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(sender.calls, isEmpty);
      update(() {
        verified = true;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 499));
      expect(sender.calls, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(sender.calls, hasLength(1));
      update(() {});
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(sender.calls, hasLength(1));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Covered, background and disposed profiles cannot establish a view',
    (tester) async {
      await login();
      final sender = Sender();
      final target = service(sender);
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          home: PatientClinicExposure(
            clinicId: clinic,
            publicDetailVerified: true,
            analytics: target,
            child: const Scaffold(body: Text('Profile')),
          ),
        ),
      );
      unawaited(
        nav.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Covered')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(sender.calls, isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(sender.calls, isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      expect(sender.calls, isEmpty);
    },
  );
  testWidgets(
    'Branch mismatch rejection keeps attribution and never retries as another clinic/branch',
    (tester) async {
      await login();
      final sender = Sender();
      final analytics = service(sender);
      sender.reply = (_) async => throw const ApiException(
        message: 'Invalid branch',
        statusCode: 400,
        fieldErrors: {
          'branch': ['Branch does not belong to this clinic.'],
        },
      );
      analytics.record(
        PatientEventType.mapsTap,
        attribution: const PatientAttribution(
          clinic,
          branchId: branch,
          surface: PatientSurface.maps,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(sender.calls, hasLength(1));
      expect(sender.calls.single['clinic'], clinic);
      expect(sender.calls.single['branch'], branch);
      expect(analytics.acknowledgedEvents, 0);
    },
  );
  testWidgets(
    'Deadline cancellation retries the same UUID at most once and releases its bounded queue',
    (tester) async {
      await login();
      final sender = Sender();
      final analytics = service(
        sender,
        deadline: const Duration(milliseconds: 10),
      );
      sender.reply = (_) => Completer<Response<Object?>>().future;
      analytics.appOpened();
      await tester.pump();
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 11));
      }
      expect(sender.calls, hasLength(2));
      expect(sender.calls[0]['event_id'], sender.calls[1]['event_id']);
      expect(analytics.pendingEvents, 0);
      expect(analytics.acknowledgedEvents, 0);
    },
  );
  test(
    'Local analytics preparation failure cannot prevent a genuine contact handoff',
    () async {
      await login();
      final sender = Sender();
      final analytics = PatientAnalytics(
        enabled: true,
        sender: sender,
        eventId: () => throw StateError('Synthetic entropy failure'),
      );
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (_) async => true);
      try {
        expect(
          await ContactLauncher.makePhoneCall(
            '+971501234567',
            attribution: const PatientAttribution(clinic),
            analytics: analytics,
          ),
          isTrue,
        );
        expect(sender.calls, isEmpty);
      } finally {
        analytics.dispose();
        messenger.setMockMethodCallHandler(channel, null);
      }
    },
  );
  testWidgets(
    'Inactive tab ticker cannot establish a profile view; activating it requires full dwell',
    (tester) async {
      await login();
      final sender = Sender();
      final analytics = service(sender);
      var active = false;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return TickerMode(
                enabled: active,
                child: PatientClinicExposure(
                  clinicId: clinic,
                  publicDetailVerified: true,
                  analytics: analytics,
                  child: const Scaffold(body: Text('Profile')),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(sender.calls, isEmpty);
      update(() => active = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 499));
      expect(sender.calls, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(sender.calls, hasLength(1));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Account switch restarts profile dwell before any new identity event',
    (tester) async {
      await login();
      final sender = Sender();
      final analytics = service(sender);
      var verified = false;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return PatientClinicExposure(
                clinicId: clinic,
                publicDetailVerified: verified,
                analytics: analytics,
                child: const Scaffold(body: Text('Profile')),
              );
            },
          ),
        ),
      );
      // Start dwell after the initial route animation has genuinely completed.
      await tester.pumpAndSettle();
      update(() => verified = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await login(suffix: 'replacement');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(sender.calls, isEmpty);
      await tester.pump(const Duration(milliseconds: 200));
      expect(sender.calls, hasLength(1));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
