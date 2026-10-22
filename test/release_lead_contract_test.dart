import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/appointment_lead/data/leads_repository.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';

// Synthetic protocol fixtures only. No production credentials or patient data.
const _clinic = '550e8400-e29b-41d4-a716-446655440000';
const _lead = '990e8400-e29b-41d4-a716-446655440000';
const _reference = '#REQ-FIXTURE-INTERNAL';
Map<String, dynamic> _row(String status) => {
  'id': _lead,
  'reference_code': _reference,
  'status': status,
  'created_at': '2026-10-23T08:00:00Z',
  'clinic': _clinic,
  'clinic_summary': {'id': _clinic, 'name_en': 'Fixture clinic'},
  'service_name': 'Fixture consultation',
  'internal_notes': [
    {'note': 'must not enter patient model'},
  ],
};
ResponseBody _body(int status, Object value, {bool retry = false}) =>
    ResponseBody.fromString(
      jsonEncode(value),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        if (retry) 'retry-after': ['15'],
      },
    );

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  final repo = LeadsRepository(apiClient: api);
  late HttpClientAdapter original;
  setUp(() async {
    original = api.dio.httpClientAdapter;
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    await TokenStorage().saveTokens(
      accessToken: 'fixture-access-not-a-real-jwt',
      refreshToken: 'fixture-refresh-not-a-real-jwt',
    );
    await TokenStorage().saveUser({'id': 'fixture-patient', 'role': 'patient'});
    AuthState().login(name: 'Fixture patient', phone: '', role: 'patient');
    api.updateBaseUrl('https://fixture.invalid/api/v1/');
  });
  tearDown(() async {
    api.dio.httpClientAdapter = original;
    await TokenStorage().clear();
    AuthState().logout();
    ApiConfig.resetBaseUrl();
    api.updateBaseUrl(ApiConfig.defaultProductionBaseUrl);
    ApiConfig.resetBaseUrl();
  });

  test(
    'd1023b0 POST JSON preserves confirmations and notifies history once',
    () async {
      final adapter = _Adapter(
        (o) => _body(201, {
          'success': true,
          'lead_reference': _reference,
          'confirmation_message':
              'Your request has been sent and the clinic will contact you',
          'created_at': '2026-10-23T08:00:00Z',
        }),
      );
      api.dio.httpClientAdapter = adapter;
      final before = LeadsRepository.refreshNotifier.value;
      final payload = <String, dynamic>{
        'clinic': _clinic,
        'consent_accepted': true,
        'service_name': 'Fixture consultation',
        'notes': 'Fixture note',
        'preferred_time_window': '',
      };
      final result = await repo.createLead(payload);
      expect(result.success, isTrue);
      expect(result.leadReference, _reference);
      expect(LeadsRepository.refreshNotifier.value, before + 1);
      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/v1/leads/');
      expect(request.contentType, contains('application/json'));
      expect(request.data, payload);
      expect(
        request.headers['Authorization'],
        'Bearer fixture-access-not-a-real-jwt',
      );
      for (final forbidden in [
        'patient',
        'patient_id',
        'status',
        'reference_code',
        'preferred_date',
        'time_slot',
      ]) {
        expect((request.data as Map).containsKey(forbidden), isFalse);
      }
    },
  );

  test(
    'lead Retry-After15 blocks repeated writes but permits My Requests recovery',
    () async {
      final adapter = _Adapter(
        (o) => o.method == 'POST'
            ? _body(429, {
                'detail':
                    'A request for this service at this clinic was already submitted recently.',
              }, retry: true)
            : _body(200, {
                'count': 1,
                'next': null,
                'results': [_row('new')],
              }),
      );
      api.dio.httpClientAdapter = adapter;
      final before = LeadsRepository.refreshNotifier.value;
      await expectLater(
        repo.createLead({'clinic': _clinic, 'consent_accepted': true}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.retryAfter,
            'server deadline',
            const Duration(seconds: 15),
          ),
        ),
      );
      expect(LeadsRepository.refreshNotifier.value, before);
      final history = await repo.getMyLeads();
      expect(history.single.id, _lead);
      expect(history.single.referenceCode, _reference);
      expect(history.single.internalNotes, isEmpty);
      await expectLater(
        repo.createLead({'clinic': _clinic, 'consent_accepted': true}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isLocalBackpressure,
            'duplicate tap guard',
            true,
          ),
        ),
      );
      expect(adapter.requests.map((o) => o.method), ['POST', 'GET']);
    },
  );

  for (final status in ['new', 'contacted', 'closed']) {
    test(
      'history $status retains server UUID and bounded account-scoped pagination',
      () async {
        final adapter = _Adapter(
          (o) => _body(200, {
            'count': 21,
            'next': null,
            'results': [_row(status)],
          }),
        );
        api.dio.httpClientAdapter = adapter;
        final history = await repo.getMyLeads(status: status, page: 2);
        expect(history.single.status, switch (status) {
          'new' => AppointmentLeadStatus.sent,
          'contacted' => AppointmentLeadStatus.contacted,
          _ => AppointmentLeadStatus.closed,
        });
        expect(history.single.id, _lead);
        expect(adapter.requests.single.uri.path, '/api/v1/leads/my/');
        expect(adapter.requests.single.queryParameters, {
          'page': 2,
          'page_size': 20,
          'status': status,
        });
      },
    );
  }

  for (final serviceFailure in [false, true]) {
    test(
      'global ${serviceFailure ? 503 : 429} still protects every endpoint',
      () async {
        final adapter = _Adapter(
          (o) => _body(serviceFailure ? 503 : 429, {
            'detail': 'Temporarily unavailable',
          }, retry: true),
        );
        api.dio.httpClientAdapter = adapter;
        await expectLater(repo.getMyLeads(), throwsA(isA<ApiException>()));
        await expectLater(
          repo.createLead({'clinic': _clinic, 'consent_accepted': true}),
          throwsA(
            isA<ApiException>().having(
              (e) => e.isLocalBackpressure,
              'global protection',
              true,
            ),
          ),
        );
        expect(adapter.requests, hasLength(1));
      },
    );
  }

  test(
    'reference/path manipulation never becomes an API detail URL; backend404 has no fallback',
    () async {
      final adapter = _Adapter((o) => _body(404, {'detail': 'Not found.'}));
      api.dio.httpClientAdapter = adapter;
      for (final id in [
        _reference,
        '../auth/me/',
        'https://other.invalid/private',
        '',
      ]) {
        await expectLater(
          repo.getMyLeadDetail(id),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'invalid ID', 400),
          ),
        );
      }
      expect(adapter.requests, isEmpty);
      await expectLater(
        repo.getMyLeadDetail(_lead),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'backend denial',
            404,
          ),
        ),
      );
      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.uri.path, '/api/v1/leads/$_lead/');
    },
  );
}
