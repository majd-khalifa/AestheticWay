import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/analytics/patient_analytics.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/services/video_upload_policy.dart';
import 'package:aesthetic_way/features/admin/data/analytics_v2_repository.dart';
import 'package:aesthetic_way/features/admin/models/analytics_v2.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_analytics_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/widgets/analytics_presentation.dart';
import 'package:aesthetic_way/features/admin/presentation/widgets/analytics_v2_panel.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';
import 'analytics_v2_reporting_test.dart'
    show fixture, clone, query, ReportingApi;
import 'analytics_v2_visual_test.dart' show capture, responses;
import 'super_admin_analytics_forensic_test.dart' as legacy;
import 'onboarding_review_workflows_test.dart' as wire;
import 'support/patient_visual_harness.dart';

// Deliberately synthetic server input for a long, sparse page. Production must
// only render these returned dates; it must not fill the missing January10.
final longQuery = AnalyticsV2Query(from: '2026-01-01', to: '2026-02-02');
Map<String, dynamic> window(Map<String, dynamic> json, AnalyticsV2Query q) =>
    json
      ..['date_from'] = q.from
      ..['date_to'] = q.to
      ..['start_utc'] = q.start.toIso8601String()
      ..['end_utc_exclusive'] = q.end.toIso8601String();

Map<String, dynamic> stressRow() {
  final row =
      clone(fixture()['detail_unavailable'])['result'] as Map<String, dynamic>;
  row['recorded_counts']['clinic_views'] = 7;
  row['trusted_recorded_counts']['clinic_views'] = 3;
  row['recorded_total_events'] = 7;
  return row;
}

ReportingApi longPages() => ReportingApi()
  ..reply = (path, params) async {
    if (path == AnalyticsV2Repository.clinicsPath) {
      final list = window(clone(fixture()['list']), longQuery);
      return list
        ..['count'] = 1
        ..['next'] = null
        ..['results'] = [stressRow()];
    }
    final result = window(clone(fixture()['detail_unavailable']), longQuery);
    final dates = [
      for (var i = 0; i < 33; i++)
        DateTime.utc(
          2026,
          1,
          1,
        ).add(Duration(days: i)).toIso8601String().substring(0, 10),
    ]..remove('2026-01-10');
    final page = params['series_page'] as int;
    final selected = dates.skip((page - 1) * 31).take(31);
    final empty = clone((fixture()['detail_unavailable'] as Map)['result']);
    result['result'] = stressRow();
    result['daily_series'] = {
      'count': dates.length,
      'page': page,
      'page_size': 31,
      'results': [
        for (final date in selected)
          {...(date == '2026-01-17' ? stressRow() : empty), 'date': date},
      ],
    };
    return result;
  };

Future<void> mount(
  WidgetTester t,
  Widget child, {
  required GlobalKey boundary,
  bool dark = false,
  bool ar = false,
  double width = 390,
  double scale = 1,
}) async {
  unawaited(
    LocaleService().setLanguage(ar ? AppLanguage.arabic : AppLanguage.english),
  );
  await t.binding.setSurfaceSize(Size(width, 900));
  await t.pumpWidget(
    RepaintBoundary(
      key: boundary,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: patientVisualTheme(dark: dark),
        locale: Locale(ar ? 'ar' : 'en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> openFirst(WidgetTester t) async {
  final tile = find
      .byWidgetPredicate(
        (widget) =>
            widget is ListTile &&
            widget.key is ValueKey<String> &&
            (widget.key as ValueKey<String>).value.startsWith(
              'analytics-clinic-',
            ),
      )
      .first;
  await t.ensureVisible(tile);
  await t.pumpAndSettle();
  expect(tile.hitTestable(), findsOneWidget);
  await t.tap(tile);
  await t.pumpAndSettle();
}

Future<void> expandDaily(WidgetTester t, bool ar) async {
  final title = find.text(
    ar ? 'سجلات العيادة اليومية' : 'Daily clinic records',
  );
  await t.ensureVisible(title);
  await t.pumpAndSettle();
  expect(title.hitTestable(), findsOneWidget);
  await t.tap(title);
  await t.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    AuthState().logout();
    await TokenStorage().clear();
    await LocaleService().setLanguage(AppLanguage.english);
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
  test('presentation polish cannot enable either release gate', () {
    expect(patientAnalyticsEnabled, isFalse);
    expect(VideoUploadPolicy.clinicShowcaseUploadsEnabled, isFalse);
  });
  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      testWidgets(
        'sparse daily page preserves observations, nulls and server paging $dark/$ar',
        (t) async {
          final api = longPages(), boundary = GlobalKey();
          await mount(
            t,
            AnalyticsV2Panel(
              repository: AnalyticsV2Repository(client: api),
              initialQuery: longQuery,
            ),
            boundary: boundary,
            dark: dark,
            ar: ar,
          );
          // Internal IDs remain searchable/inspectable but are absent from cards.
          expect(find.text(stressRow()['clinic_id']), findsNothing);
          await openFirst(t);
          expect(
            find.byKey(const ValueKey('analytics-reported-date')),
            findsNothing,
          );
          expect(find.byType(AnalyticsDailyMetrics), findsNothing);
          expect(
            t
                .widget<Text>(find.byKey(const ValueKey('analytics-v2-total')))
                .data,
            '—',
          );
          await expandDaily(t, ar);
          final dropdown = find.byKey(
            const ValueKey('analytics-reported-date'),
          );
          final control = t.widget<DropdownButtonFormField<String>>(dropdown);
          final button = t.widget<DropdownButton<String>>(
            find.descendant(
              of: dropdown,
              matching: find.byType(DropdownButton<String>),
            ),
          );
          expect(control, isNotNull);
          expect(button.items, hasLength(31));
          expect(
            button.items!.map((item) => item.value),
            isNot(contains('2026-01-10')),
          );
          await t.ensureVisible(dropdown);
          await t.pumpAndSettle();
          await t.tap(dropdown);
          await t.pumpAndSettle();
          final observedDay = find.text(
            '2026-01-17 · ${ar ? 'مرصود' : 'Observed'} 7',
          );
          await t.scrollUntilVisible(
            observedDay,
            180,
            scrollable: find.byType(Scrollable).last,
          );
          await t.pumpAndSettle();
          await t.tap(observedDay.hitTestable());
          await t.pumpAndSettle();
          final metrics = find.byType(AnalyticsDailyMetrics);
          expect(
            t
                .widget<Text>(
                  find.byKey(const ValueKey('daily-clinic_views-canonical')),
                )
                .data,
            '—',
          );
          expect(
            find.descendant(
              of: metrics,
              matching: find.text('${ar ? 'مرصود' : 'Observed'} 7'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: metrics,
              matching: find.text('${ar ? 'موثوق' : 'Trusted'} 3'),
            ),
            findsOneWidget,
          );
          expect(t.takeException(), isNull);
          await t.ensureVisible(dropdown);
          await t.pumpAndSettle();
          await capture(
            t,
            boundary,
            'long_daily_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          final next = find.text(ar ? 'الأيام التالية' : 'Next days');
          await t.ensureVisible(next);
          await t.pumpAndSettle();
          await t.tap(next);
          await t.pumpAndSettle();
          expect(api.parameters.last['series_page'], 2);
          expect(
            find.byKey(const ValueKey('analytics-reported-date')),
            findsOneWidget,
          );
          final second = t.widget<DropdownButton<String>>(
            find.byType(DropdownButton<String>),
          );
          expect(second.items!.map((item) => item.value), ['2026-02-02']);
          expect(
            api.calls.where(
              (path) => path == AnalyticsV2Repository.clinicsPath,
            ),
            hasLength(1),
          );
          await t.pumpWidget(const SizedBox());
          await t.binding.setSurfaceSize(null);
        },
      );
      for (final (width, scale) in [(320.0, 1.6), (1024.0, 1.0)]) {
        testWidgets(
          'report controls and KPIs fit width=$width scale=$scale $dark/$ar',
          (t) async {
            final api = responses(), boundary = GlobalKey();
            await mount(
              t,
              AnalyticsV2Panel(
                repository: AnalyticsV2Repository(client: api),
                initialQuery: query(),
              ),
              boundary: boundary,
              dark: dark,
              ar: ar,
              width: width,
              scale: scale,
            );
            expect(t.takeException(), isNull);
            await openFirst(t);
            expect(t.takeException(), isNull);
            expect(
              t
                  .widget<Text>(
                    find.byKey(const ValueKey('analytics-v2-total')),
                  )
                  .data,
              '5',
            );
            await capture(
              t,
              boundary,
              'layout_${width.toInt()}_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
            );
            await expandDaily(t, ar);
            expect(
              find.byKey(const ValueKey('analytics-reported-date')),
              findsOneWidget,
            );
            expect(t.takeException(), isNull);
            await t.tap(
              find.byTooltip(
                ar ? 'إغلاق تقرير العيادة' : 'Close clinic report',
              ),
            );
            await t.pumpAndSettle();
            expect(find.byType(BottomSheet), findsNothing);
            await t.pumpWidget(const SizedBox());
            await t.binding.setSurfaceSize(null);
          },
        );
      }
    }
  }
  testWidgets(
    'an open report loses private identity and values on account switch',
    (t) async {
      await mount(
        t,
        AnalyticsV2Panel(
          repository: AnalyticsV2Repository(client: responses()),
          initialQuery: query(),
        ),
        boundary: GlobalKey(),
      );
      await openFirst(t);
      AuthState().logout();
      AuthState().login(
        name: 'Replacement',
        phone: 'other',
        role: 'super_admin',
      );
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('analytics-v2-detail')), findsNothing);
      expect(find.text('Synthetic clinic 1'), findsNothing);
      expect(find.text('This report is no longer available.'), findsOneWidget);
      await t.tap(find.text('Close'));
      await t.pumpAndSettle();
      await t.pumpWidget(const SizedBox());
      await t.binding.setSurfaceSize(null);
    },
  );

  testWidgets('open-report locale labels update without fetching new metrics', (
    t,
  ) async {
    final api = responses();
    await mount(
      t,
      AnalyticsV2Panel(
        repository: AnalyticsV2Repository(client: api),
        initialQuery: query(),
      ),
      boundary: GlobalKey(),
    );
    await openFirst(t);
    final reads = api.calls.length;
    unawaited(LocaleService().setLanguage(AppLanguage.arabic));
    await t.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('كيف تقرأ هذه الأعداد'),
      ),
      findsOneWidget,
    );
    expect(find.text('مشاهدات العيادة'), findsOneWidget);
    expect(
      t.widget<Text>(find.byKey(const ValueKey('analytics-v2-total'))).data,
      '5',
    );
    expect(api.calls, hasLength(reads));
    await t.pumpWidget(const SizedBox());
    await t.binding.setSurfaceSize(null);
  });

  testWidgets(
    'report error, retry, empty and refresh states never invent counts',
    (t) async {
      final api = ReportingApi()
        ..reply = (_, _) async =>
            throw const ApiException(message: 'Synthetic report unavailable');
      await mount(
        t,
        AnalyticsV2Panel(
          repository: AnalyticsV2Repository(client: api),
          initialQuery: query(),
        ),
        boundary: GlobalKey(),
      );
      expect(find.text('Synthetic report unavailable'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('analytics-platform-app-opens')),
        findsNothing,
      );
      api.reply = (_, _) async => clone(fixture()['list'])
        ..['count'] = 0
        ..['next'] = null
        ..['results'] = [];
      await t.tap(find.text(LocaleService().tr('retry')));
      await t.pumpAndSettle();
      expect(
        find.text('No clinic records match these filters.'),
        findsOneWidget,
      );
      expect(
        t
            .widget<Text>(
              find.byKey(const ValueKey('analytics-platform-app-opens')),
            )
            .data,
        '—',
      );
      final pending = Completer<Object?>();
      api.reply = (_, _) => pending.future;
      unawaited(
        t.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show(),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      pending.complete(clone(fixture()['list']));
      await t.pumpAndSettle();
      expect(find.text('Synthetic clinic 1'), findsOneWidget);
      expect(api.calls, hasLength(3));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'V2 and Legacy switch retains server filters and role-scoped collections',
    (t) async {
      final api = ApiClient(), old = ApiClient().dio.httpClientAdapter;
      final calls = <String>[];
      api.dio.httpClientAdapter = wire.Adapter((request) {
        calls.add(request.path);
        final q = AnalyticsV2Query(
          from: request.queryParameters['date_from'] as String,
          to: request.queryParameters['date_to'] as String,
        );
        return wire.body(window(clone(fixture()['list']), q));
      });
      final service = AdminPortalService(
        repository: legacy.ControlledRepository(),
      );
      addTearDown(() {
        api.dio.httpClientAdapter = old;
        service.resetTestingState();
      });
      await mount(
        t,
        const AdminAnalyticsScreen(),
        boundary: GlobalKey(),
        ar: true,
        dark: true,
        width: 320,
        scale: 1.6,
      );
      await t.enterText(find.byType(TextField), 'saved search');
      await t.pump(const Duration(milliseconds: 351));
      await t.pumpAndSettle();
      final reads = calls.length;
      await t.tap(find.text('السجلات القديمة'));
      await t.pumpAndSettle();
      expect(find.text('سجلات نشاط المنصة'), findsOneWidget);
      await t.tap(find.text('تقارير V2'));
      await t.pumpAndSettle();
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        'saved search',
      );
      expect(calls, hasLength(reads));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.binding.setSurfaceSize(null);
    },
  );
}
