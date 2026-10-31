import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/admin/data/admin_repository.dart';
import 'package:aesthetic_way/features/admin/models/admin_analytics_model.dart';
import 'package:aesthetic_way/features/admin/models/admin_clinic_model.dart';
import 'package:aesthetic_way/features/admin/models/admin_dashboard_model.dart';
import 'package:aesthetic_way/features/admin/models/admin_lead_model.dart';
import 'package:aesthetic_way/features/admin/models/admin_reporting_period.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_analytics_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_leads_screen.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'products_articles_live_test.dart' show FakeApiClient;
import 'package:aesthetic_way/features/admin/presentation/screens/admin_offers_screen.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/articles/models/article_model.dart';
import 'support/patient_visual_harness.dart';

const clinicId = '00000000-0000-4000-8000-000000000021';
Map<String, dynamic> response({
  int total = 7,
  String from = '2026-09-30',
  String to = '2026-10-30',
}) => {
  'date_from': from,
  'date_to': to,
  'total_events': total,
  'app_opens': 0,
  'clinic_views': 0,
  'whatsapp_taps': 0,
  'call_taps': 0,
  'maps_taps': 0,
  'lead_submissions': 7,
  'clinic_engagement': [
    {
      'clinic_id': clinicId,
      'clinic_name': 'Synthetic audit fixture',
      'events_count': 5,
    },
  ],
  'daily_trends': [
    {'date': '2026-10-29', 'total_events': 2},
    {'date': '2026-10-30', 'total_events': 5},
  ],
};

AdminClinicModel clinic() => AdminClinicModel.fromJson({
  'id': clinicId,
  'name_en': 'Synthetic audit fixture',
  'name_ar': 'عيادة اختبار معزول',
  'city': 'Dubai',
  'status': 'active',
  'setup_status': 'approved',
  'leads_count': 4,
});

class ControlledRepository implements AdminRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  final requests = <String, Completer<AdminAnalyticsModel>>{};
  int analyticsCalls = 0;
  bool delayed = false;
  @override
  Future<AdminAnalyticsModel> getAnalytics({String? dateFrom, String? dateTo}) {
    analyticsCalls++;
    final key = '$dateFrom|$dateTo';
    if (delayed) {
      return requests
          .putIfAbsent(key, Completer<AdminAnalyticsModel>.new)
          .future;
    }
    return Future.value(
      AdminAnalyticsModel.fromJson(
        response(from: dateFrom ?? '2026-09-30', to: dateTo ?? '2026-10-30'),
      ),
    );
  }

  @override
  Future<AdminDashboardModel> getDashboard() async =>
      const AdminDashboardModel(totalClinics: 21);
  @override
  Future<AdminReferralAnalyticsModel> getReferralAnalytics() async =>
      const AdminReferralAnalyticsModel(
        successfulInvites: 3,
        pointsAwarded: 450,
      );
  @override
  Future<List<AdminLeadModel>> getLeads({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? clinicId,
    String? search,
    String? dateFrom,
    String? dateTo,
  }) async => [];
  @override
  Future<List<OfferModel>> getOffers({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? clinicId,
    String? search,
  }) async => [];
  @override
  Future<List<ArticleModel>> getArticles({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? clinicId,
    String? search,
  }) async => [];
  final clinicPages = <int>[];
  @override
  Future<List<AdminClinicModel>> getClinics({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? tier,
    String? setupStatus,
    String? search,
  }) async {
    clinicPages.add(page);
    return PageItems(
      page == 1
          ? [
              for (var i = 0; i < 20; i++)
                AdminClinicModel.fromJson({
                  'id':
                      '00000000-0000-4000-8000-${(i + 1).toString().padLeft(12, '0')}',
                  'name_en': 'First page fixture $i',
                  'name_ar': 'اختبار الصفحة الأولى $i',
                  'city': 'Dubai',
                  'status': 'active',
                }),
            ]
          : [clinic()],
      hasMore: page == 1,
      total: 21,
    );
  }

  @override
  Future<AdminClinicModel> getClinicDetail(String id) async => clinic();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  final service = AdminPortalService();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    service.resetTestingState();
    AuthState().login(
      name: 'Synthetic admin',
      phone: '+971500000010',
      role: 'super_admin',
    );
    LocaleService().setLanguage(AppLanguage.english);
  });
  tearDown(() {
    service.resetTestingState();
  });

  test(
    'absent or invalid measurements remain unavailable; a returned zero is a recorded zero',
    () {
      final model = AdminAnalyticsModel.fromJson({
        'app_opens': 0,
        'maps_taps': null,
        'call_taps': -1,
        'whatsapp_taps': 'invalid',
      });
      expect(model.recordedCount('app_opens'), 0);
      for (final key in [
        'maps_taps',
        'call_taps',
        'whatsapp_taps',
        'total_events',
      ]) {
        expect(model.recordedCount(key), isNull);
      }
    },
  );
  test(
    'platform totals are never inferred from top ten and sparse days are preserved',
    () {
      final model = AdminAnalyticsModel.fromJson(response());
      expect(model.totalEvents, 7);
      expect(model.clinicEngagement.single.eventsCount, 5);
      expect(model.dailyTrends.length, 2);
      expect(model.dailyTrends.map((d) => d.count), [2, 5]);
      expect(AdminClinicModel.fromJson({'id': clinicId}).hasLeadCount, isFalse);
    },
  );
  test('reporting dates reject impossible dates and reversed ranges', () {
    for (final value in [
      '2026-02-29',
      '2026-13-01',
      '2026-1-01',
      'not-a-date',
    ]) {
      expect(() => AdminReportingPeriod.parse(value), throwsFormatException);
    }
    expect(
      () => AdminReportingPeriod.validate('2026-10-30', '2026-09-30'),
      throwsFormatException,
    );
    AdminReportingPeriod.validate('2026-09-30', '2026-10-30');
  });
  test(
    'analytics and lead drills send only supported exact date parameters',
    () async {
      final queries = <Map<String, dynamic>?>[];
      final repo = AdminRepository(
        apiClient: FakeApiClient(
          onGet: (path, q) {
            queries.add(q);
            return path == ApiConfig.adminAnalytics
                ? response()
                : {'count': 0, 'next': null, 'results': []};
          },
        ),
      );
      await repo.getAnalytics(dateFrom: '2026-09-30', dateTo: '2026-10-30');
      await repo.getLeads(
        clinicId: clinicId,
        dateFrom: '2026-09-30',
        dateTo: '2026-10-30',
      );
      expect(queries.first, {
        'date_from': '2026-09-30',
        'date_to': '2026-10-30',
      });
      expect(queries.last!['clinic'], clinicId);
      expect(queries.last!['date_from'], '2026-09-30');
      expect(queries.last!['date_to'], '2026-10-30');
    },
  );
  test(
    'unacknowledged date filters are rejected instead of presenting default figures',
    () async {
      final repo = AdminRepository(
        apiClient: FakeApiClient(onGet: (_, _) => response()),
      );
      await expectLater(
        repo.getAnalytics(dateFrom: '2026-10-01', dateTo: '2026-10-30'),
        throwsA(isA<ApiException>()),
      );
    },
  );
  test('latest period wins when responses complete out of order', () async {
    final repo = ControlledRepository()..delayed = true;
    AdminPortalService(repository: repo);
    final old = service.loadAnalytics(
      dateFrom: '2026-09-01',
      dateTo: '2026-09-30',
    );
    final latest = service.loadAnalytics(
      dateFrom: '2026-10-01',
      dateTo: '2026-10-30',
    );
    repo.requests['2026-10-01|2026-10-30']!.complete(
      AdminAnalyticsModel.fromJson(response(total: 11, from: '2026-10-01')),
    );
    await latest;
    repo.requests['2026-09-01|2026-09-30']!.complete(
      AdminAnalyticsModel.fromJson(
        response(total: 1, from: '2026-09-01', to: '2026-09-30'),
      ),
    );
    await old;
    expect(service.analytics.totalEvents, 11);
    expect(service.analytics.dateFrom, '2026-10-01');
  });
  test(
    'same pending period deduplicates and old session response cannot reappear',
    () async {
      final repo = ControlledRepository()..delayed = true;
      AdminPortalService(repository: repo);
      final a = service.loadAnalytics();
      final b = service.loadAnalytics();
      expect(repo.analyticsCalls, 1);
      service.clearSession();
      repo.requests['null|null']!.complete(
        AdminAnalyticsModel.fromJson(response()),
      );
      await Future.wait([a, b]);
      expect(service.analyticsLoaded, isFalse);
      expect(service.analytics.totalEvents, 0);
    },
  );
  test(
    'dashboard refresh cannot overwrite a date-filtered analytics report',
    () async {
      final repo = ControlledRepository();
      AdminPortalService(repository: repo);
      await service.loadAnalytics(dateFrom: '2026-09-30', dateTo: '2026-10-30');
      await service.loadOverview(refresh: true);
      expect(repo.analyticsCalls, 1);
      expect(service.analytics.dateFrom, '2026-09-30');
      expect(service.overviewLoaded, isTrue);
    },
  );

  for (final dark in [false, true]) {
    for (final arabic in [false, true]) {
      testWidgets(
        'honest analytics renders and captures ${dark ? 'dark' : 'light'}_${arabic ? 'ar' : 'en'}',
        (tester) async {
          LocaleService().setLanguage(
            arabic ? AppLanguage.arabic : AppLanguage.english,
          );
          AdminPortalService(repository: ControlledRepository());
          await tester.binding.setSurfaceSize(const Size(430, 1100));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final boundary = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              theme: patientVisualTheme(dark: dark),
              locale: Locale(arabic ? 'ar' : 'en'),
              supportedLocales: const [Locale('ar'), Locale('en')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: RepaintBoundary(
                key: boundary,
                child: const AdminAnalyticsScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(
              arabic ? 'سجلات نشاط المنصة' : 'Platform activity records',
            ),
            findsOneWidget,
          );
          expect(
            find.textContaining(
              arabic
                  ? 'جمع بيانات النشاط غير مكتمل'
                  : 'Activity collection is incomplete',
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          const folder = String.fromEnvironment('ADMIN_ANALYTICS_CAPTURE_DIR');
          Future<void> capture(String suffix) async {
            if (folder.isEmpty) return;
            await tester.runAsync(() async {
              final frame =
                  await (boundary.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage(pixelRatio: 1);
              final bytes = await frame.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                '$folder/analytics_${dark ? 'dark' : 'light'}_${arabic ? 'ar' : 'en'}_$suffix.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              frame.dispose();
            });
          }

          await capture('top');
          final anyClinic = find.text(
            arabic ? 'اختر أي عيادة' : 'Select any clinic',
          );
          await tester.scrollUntilVisible(
            anyClinic,
            450,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(anyClinic, findsOneWidget);
          await capture('directory');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('period lead drill preserves the main Leads collection query', (
    tester,
  ) async {
    final repo = ControlledRepository();
    AdminPortalService(repository: repo);
    await service.loadCollection('leads', query: {'status': 'new'});
    final original = Map<String, dynamic>.of(service.collection('leads').query);
    await tester.pumpWidget(
      MaterialApp(
        home: AdminLeadsScreen(
          initialClinic: clinic(),
          dateFrom: '2026-09-30',
          dateTo: '2026-10-30',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(service.collection('leads').query, original);
    expect(find.text('2026-09-30 — 2026-10-30 · UTC+4'), findsOneWidget);
  });
  test('dashboard distinguishes missing counts from genuine zero', () {
    final model = AdminDashboardModel.fromJson({'total_leads': 0});
    expect(model.hasMetric('total_leads'), isTrue);
    expect(model.hasMetric('total_patients'), isFalse);
  });
  testWidgets(
    'any clinic beyond the top ten can be selected through server pagination',
    (tester) async {
      final repo = ControlledRepository();
      AdminPortalService(repository: repo);
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: patientVisualTheme(dark: false),
          home: const AdminAnalyticsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      final select = find.text('Select any clinic');
      await tester.scrollUntilVisible(
        select,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(select);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Synthetic audit fixture'),
        ),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(repo.clinicPages, contains(2));
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Synthetic audit fixture'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('All-time saved consultations'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.textContaining('Period-specific views'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'offer and article API searches preserve matches from the other language',
    (tester) async {
      final queries = <String, Map<String, dynamic>>{};
      AdminPortalService(
        repository: AdminRepository(
          apiClient: FakeApiClient(
            onGet: (path, q) {
              queries[path] = Map.of(q ?? {});
              return {
                'count': 1,
                'next': null,
                'results': [
                  {
                    'id': clinicId,
                    'title_en': path == ApiConfig.adminOffers
                        ? 'Offer matched in Arabic'
                        : 'Article matched in Arabic',
                    'title_ar': 'مصدر',
                    'status': 'active',
                  },
                ],
              };
            },
          ),
        ),
      );
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: patientVisualTheme(dark: false),
          home: const AdminOffersScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'مصدر');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(queries[ApiConfig.adminOffers]!['search'], 'مصدر');
      expect(find.text('Offer matched in Arabic'), findsOneWidget);
      await tester.tap(find.text('Articles'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'مصدر');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(queries[ApiConfig.adminArticles]!['search'], 'مصدر');
      expect(find.text('Article matched in Arabic'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'patient cannot open the analytics screen or cause an admin read',
    (tester) async {
      final repo = ControlledRepository();
      AdminPortalService(repository: repo);
      AuthState().login(
        name: 'Synthetic patient',
        phone: '+971500000011',
        role: 'patient',
      );
      await tester.pumpWidget(const MaterialApp(home: AdminAnalyticsScreen()));
      await tester.pumpAndSettle();
      expect(repo.analyticsCalls, 0);
      expect(find.text('Super Admin access is required.'), findsOneWidget);
    },
  );
}
