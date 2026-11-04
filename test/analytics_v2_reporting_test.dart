import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/admin/data/analytics_v2_repository.dart';
import 'package:aesthetic_way/features/admin/models/analytics_v2.dart';
import 'package:aesthetic_way/features/admin/services/analytics_v2_controller.dart';

Map<String, dynamic> fixture() =>
    jsonDecode(
          File('test/fixtures/analytics_v2_contract.json').readAsStringSync(),
        )
        as Map<String, dynamic>;
Map<String, dynamic> clone(Object value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
AnalyticsV2Query query({
  int page = 1,
  int seriesPage = 1,
  int seriesPageSize = 31,
  bool compare = false,
  String search = '',
  bool deleted = false,
}) => AnalyticsV2Query(
  from: '2026-02-28',
  to: '2026-03-01',
  page: page,
  search: search,
  includeDeleted: deleted,
  seriesPage: seriesPage,
  seriesPageSize: seriesPageSize,
  compare: compare,
);

class ReportingApi implements ApiClient {
  final calls = <String>[];
  final parameters = <Map<String, dynamic>>[];
  Future<Object?> Function(String, Map<String, dynamic>)? reply;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    calls.add(path);
    parameters.add(Map.of(queryParameters ?? {}));
    final data = await reply!(path, queryParameters ?? {});
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: data as T,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    AuthState().logout();
    await TokenStorage().clear();
    AuthState().login(
      name: 'Synthetic admin',
      phone: 'synthetic',
      role: 'super_admin',
    );
  });
  tearDown(() async {
    AuthState().logout();
    await TokenStorage().clear();
  });

  test(
    'Fixture provenance and real Django V2 responses preserve raw/trusted/canonical distinctions',
    () {
      final source = fixture();
      expect(
        source['source_commit'],
        '76a9566176c630d5ac810d874e081339bc70b9c5',
      );
      final first = AnalyticsV2Page.fromJson(clone(source['list']), query());
      expect(first.count, 23);
      expect(first.clinics, hasLength(20));
      expect(first.hasNext, isTrue);
      final row = first.clinics.first.metrics;
      expect(row.values['clinic_views']!.recorded, 2);
      expect(row.values['clinic_views']!.trusted, 1);
      expect(row.values['clinic_views']!.count, 1);
      expect(row.values['lead_submissions']!.count, 1);
      expect(row.total, 5);
      expect(row.recordedTotal, 6);
      expect(first.clinics[1].metrics.total, 0); // Attested zero is real zero.
      expect(
        first.clinics[2].metrics.values['clinic_views']!.coverage,
        AnalyticsCoverage.partial,
      );
      expect(first.clinics[2].metrics.values['clinic_views']!.count, isNull);
      expect(
        first.clinics[3].metrics.values['clinic_views']!.coverage,
        AnalyticsCoverage.unavailable,
      );
      expect(first.clinics[3].metrics.total, isNull);
      expect(first.metadata.appOpens.recorded, 1);
      expect(first.metadata.appOpens.trusted, 1);
      expect(first.metadata.appOpens.count, isNull);
    },
  );
  test(
    'All23 clinics page independently of top ten and search preserves Arabic name/UUID identity',
    () {
      final f = fixture();
      final first = AnalyticsV2Page.fromJson(clone(f['list']), query());
      final second = AnalyticsV2Page.fromJson(
        clone(f['page2']),
        query(page: 2),
      );
      expect(second.hasNext, isFalse);
      expect({
        ...first.clinics.map((c) => c.id),
        ...second.clinics.map((c) => c.id),
      }, hasLength(23));
      final ar = AnalyticsV2Page.fromJson(
        clone(f['search_ar']),
        query(search: 'عيادة اصطناعية 23'),
      );
      expect(ar.count, 1);
      expect(ar.clinics.single.name(true), 'عيادة اصطناعية 23');
    },
  );
  test(
    'Daily series preserves explicit dates and half-open Dubai boundaries; no invented gaps or growth',
    () {
      final f = fixture(), raw = clone(f['detail']);
      final id = (raw['result'] as Map)['clinic_id'] as String;
      final detail = AnalyticsV2Detail.fromJson(raw, query(), id);
      expect(detail.metadata.start, DateTime.utc(2026, 2, 27, 20));
      expect(detail.metadata.end, DateTime.utc(2026, 3, 1, 20));
      expect(detail.days.map((d) => d.date), ['2026-02-28', '2026-03-01']);
      expect(detail.days[0].metrics.values['clinic_views']!.count, 1);
      expect(detail.days[1].metrics.total, 0);
      final p1 = AnalyticsV2Detail.fromJson(
        clone(f['series_page1']),
        query(seriesPageSize: 1),
        id,
      );
      final p2 = AnalyticsV2Detail.fromJson(
        clone(f['series_page2']),
        query(seriesPage: 2, seriesPageSize: 1),
        id,
      );
      expect(p1.hasMoreDays, isTrue);
      expect(p2.hasMoreDays, isFalse);
      expect(p2.days.single.date, '2026-03-01');
      final comparison = AnalyticsV2Detail.fromJson(
        clone(f['comparison']),
        query(compare: true),
        id,
      );
      expect(comparison.comparison!.metrics.total, isNull);
    },
  );
  test(
    'Unknown coverage can never become canonical zero, even if a response incorrectly supplies a number',
    () {
      final raw = clone((fixture()['list'] as Map)['results'][3]);
      (raw['counts'] as Map)['clinic_views'] = 0;
      raw['total_events'] = 0;
      final model = AnalyticsV2Clinic.fromJson(raw);
      expect(model.metrics.values['clinic_views']!.count, isNull);
      expect(model.metrics.total, isNull);
    },
  );
  final invalidMutations = <void Function(Map<String, dynamic>)>[
    (m) => m['schema_version'] = 1,
    (m) => m['timezone'] = 'UTC',
    (m) => m['date_from'] = '2026-02-27',
    (m) => m['start_utc'] = '2026-02-28T00:00:00+00:00',
    (m) => m['end_utc_exclusive'] = '2026-03-01T00:00:00+00:00',
    (m) => (m['results'] as List).first['recorded_counts']['clinic_views'] = -1,
    (m) => (m['results'] as List).first['unique_authenticated_accounts'] = 10,
    (m) => (m['results'] as List).first['total_events'] = 900,
  ];
  for (final mutate in invalidMutations) {
    test(
      'Malformed version/period/metric contract fails closed: ${invalidMutations.indexOf(mutate)}',
      () async {
        final api = ReportingApi();
        api.reply = (_, _) async {
          final json = clone(fixture()['list']);
          mutate(json);
          return json;
        };
        await expectLater(
          AnalyticsV2Repository(client: api).clinics(query()),
          throwsA(isA<ApiException>()),
        );
        expect(api.calls, [AnalyticsV2Repository.clinicsPath]);
      },
    );
  }
  test(
    'Invalid filters fail locally: exact dates, inclusive366-day cap and bounded paging/search',
    () {
      for (final callback in <void Function()>[
        () => AnalyticsV2Query(from: '2026-2-28', to: '2026-03-01'),
        () => AnalyticsV2Query(from: '2026-02-30', to: '2026-03-01'),
        () => AnalyticsV2Query(from: '1999-12-31', to: '2000-01-01'),
        () => AnalyticsV2Query(from: '2026-03-02', to: '2026-03-01'),
        () => AnalyticsV2Query(from: '2024-01-01', to: '2025-01-01'),
        () => query(page: 0),
        () => query(seriesPage: 0),
        () => query(seriesPageSize: 101),
        () => query(search: 'x' * 121),
      ]) {
        expect(callback, throwsFormatException);
      }
      expect(
        AnalyticsV2Query(from: '2024-01-01', to: '2024-12-31').end,
        DateTime.utc(2024, 12, 31, 20),
      );
    },
  );
  test(
    'Repository sends source-confirmed filters to relative API paths and never follows next URL',
    () async {
      final api = ReportingApi();
      api.reply = (path, p) async =>
          clone(fixture()[p['page'] == 2 ? 'page2' : 'list']);
      final repo = AnalyticsV2Repository(client: api);
      await repo.clinics(query(search: 'عيادة', deleted: true));
      await repo.clinics(query(page: 2));
      expect(api.calls, [
        AnalyticsV2Repository.clinicsPath,
        AnalyticsV2Repository.clinicsPath,
      ]);
      expect(api.parameters.first, containsPair('include_deleted', true));
      expect(api.parameters.first, containsPair('search', 'عيادة'));
      expect(api.parameters.first, containsPair('date_from', '2026-02-28'));
      expect(api.parameters.last['page'], 2);
    },
  );
  for (final role in ['patient', 'clinic_admin', 'clinic_staff', 'guest']) {
    test('$role cannot issue V2 reporting requests', () async {
      AuthState().logout();
      if (role != 'guest') {
        AuthState().login(name: 'Synthetic', phone: 'synthetic', role: role);
      }
      final api = ReportingApi();
      await expectLater(
        AnalyticsV2Repository(client: api).clinics(query()),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403)),
      );
      expect(api.calls, isEmpty);
    });
  }
  test(
    '404/401/429 and network failures remain honest errors; no legacy endpoint fallback',
    () async {
      for (final status in [null, 401, 404, 429, 503]) {
        final api = ReportingApi();
        api.reply = (_, _) async => throw ApiException(
          message: 'synthetic failure',
          statusCode: status,
        );
        await expectLater(
          AnalyticsV2Repository(client: api).clinics(query()),
          throwsA(isA<ApiException>()),
        );
        expect(api.calls, [AnalyticsV2Repository.clinicsPath]);
      }
    },
  );
  test(
    'Controller latest filters win and failed later response never restores stale data',
    () async {
      final api = ReportingApi();
      final first = Completer<Object?>(), second = Completer<Object?>();
      api.reply = (_, p) => p['search'] == 'new' ? second.future : first.future;
      final controller = AnalyticsV2Controller(
        repository: AnalyticsV2Repository(client: api),
        initialQuery: query(),
      );
      final a = controller.load(),
          b = controller.load(filters: query(search: 'new'));
      second.complete(clone(fixture()['search_ar']));
      await b;
      expect(controller.page!.count, 1);
      first.complete(clone(fixture()['list']));
      await a;
      expect(controller.page!.count, 1);
      controller.dispose();
    },
  );
  test(
    'Logout removes loaded data immediately and pending report cannot appear for next admin',
    () async {
      final api = ReportingApi();
      final gate = Completer<Object?>();
      api.reply = (_, _) => gate.future;
      final controller = AnalyticsV2Controller(
        repository: AnalyticsV2Repository(client: api),
        initialQuery: query(),
      );
      final pending = controller.load();
      AuthState().logout();
      AuthState().login(
        name: 'Replacement',
        phone: 'other',
        role: 'super_admin',
      );
      gate.complete(clone(fixture()['list']));
      await pending;
      expect(controller.page, isNull);
      expect(controller.detail, isNull);
      expect(controller.error, isNull);
      controller.dispose();
    },
  );
  test(
    'Selected clinic/detail responses cannot cross clinic or period boundaries',
    () async {
      final api = ReportingApi();
      final gate = Completer<Object?>();
      api.reply = (path, _) => path == AnalyticsV2Repository.clinicsPath
          ? Future.value(clone(fixture()['list']))
          : gate.future;
      final controller = AnalyticsV2Controller(
        repository: AnalyticsV2Repository(client: api),
        initialQuery: query(),
      );
      await controller.load();
      final id = controller.page!.clinics.first.id;
      final pending = controller.select(id);
      await controller.load(filters: query(search: 'new'));
      gate.complete(clone(fixture()['detail']));
      await pending;
      expect(controller.detail, isNull);
      final wrong = clone(fixture()['detail']);
      (wrong['result'] as Map)['clinic_id'] = controller.page!.clinics[1].id;
      expect(
        () => AnalyticsV2Detail.fromJson(wrong, query(), id),
        throwsFormatException,
      );
      controller.dispose();
    },
  );
  test(
    'Later clinic selection wins while earlier detail completes after it',
    () async {
      final api = ReportingApi();
      final first = Completer<Object?>(), second = Completer<Object?>();
      api.reply = (path, _) => path == AnalyticsV2Repository.clinicsPath
          ? Future.value(clone(fixture()['list']))
          : path.contains('00000000-0000-0000-0000-000000000002')
          ? second.future
          : first.future;
      final controller = AnalyticsV2Controller(
        repository: AnalyticsV2Repository(client: api),
        initialQuery: query(),
      );
      await controller.load();
      final a = controller.select(controller.page!.clinics[0].id),
          b = controller.select(controller.page!.clinics[1].id);
      second.complete(clone(fixture()['detail_zero']));
      await b;
      expect(controller.detail!.clinic.metrics.total, 0);
      first.complete(clone(fixture()['detail']));
      await a;
      expect(controller.detail!.clinic.id, controller.page!.clinics[1].id);
      controller.dispose();
    },
  );
}
