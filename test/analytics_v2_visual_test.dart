import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/admin/data/analytics_v2_repository.dart';
import 'package:aesthetic_way/features/admin/presentation/widgets/analytics_v2_panel.dart';
import 'package:aesthetic_way/features/admin/presentation/widgets/admin_components.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_analytics_screen.dart';
import 'support/patient_visual_harness.dart';
import 'analytics_v2_reporting_test.dart'
    show fixture, clone, query, ReportingApi;

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  const output = String.fromEnvironment('ANALYTICS_V2_CAPTURE_DIR');
  if (output.isEmpty) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(output).create(recursive: true);
    await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

ReportingApi responses() => ReportingApi()
  ..reply = (path, p) async {
    final f = fixture();
    if (path == AnalyticsV2Repository.clinicsPath) {
      return clone(
        f[p['search'] == 'عيادة اصطناعية 23'
            ? 'search_ar'
            : p['page'] == 2
            ? 'page2'
            : 'list'],
      );
    }
    if (path.contains('00000000-0000-0000-0000-000000000002')) {
      return clone(f['detail_zero']);
    }
    if (path.contains('00000000-0000-0000-0000-000000000004')) {
      return clone(f['detail_unavailable']);
    }
    return clone(f['detail']);
  };

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
  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      final name = '${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}';
      testWidgets(
        'V2 actual coverage, clinic selection and bounded layouts $name',
        (tester) async {
          unawaited(
            LocaleService().setLanguage(
              ar ? AppLanguage.arabic : AppLanguage.english,
            ),
          );
          await tester.binding.setSurfaceSize(const Size(390, 844));
          final key = GlobalKey(), api = responses();
          await tester.pumpWidget(
            MaterialApp(
              theme: patientVisualTheme(dark: dark),
              locale: Locale(ar ? 'ar' : 'en'),
              supportedLocales: const [Locale('en'), Locale('ar')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: RepaintBoundary(
                key: key,
                child: Scaffold(
                  body: AnalyticsV2Panel(
                    repository: AnalyticsV2Repository(client: api),
                    initialQuery: query(),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(ar ? 'تحليلات العيادات V2' : 'Clinic Analytics V2'),
            findsOneWidget,
          );
          final appCard = tester.widget<AdminMetricCard>(
            find.byType(AdminMetricCard).first,
          );
          expect(
            appCard.value,
            '—',
          ); // One observed app open does not imply coverage.
          expect(tester.takeException(), isNull);
          await capture(tester, key, 'v2_${name}_overview');
          for (final (number, expected) in [(1, '5'), (2, '0'), (4, '—')]) {
            final scrollable = find.byType(Scrollable).first;
            tester.state<ScrollableState>(scrollable).position.jumpTo(0);
            await tester.pumpAndSettle();
            final label = ar
                ? 'عيادة اصطناعية $number'
                : 'Synthetic clinic $number';
            await tester.scrollUntilVisible(
              find.text(label),
              300,
              scrollable: scrollable,
              maxScrolls: 50,
            );
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text(label));
            await tester.pumpAndSettle();
            expect(find.text(label).hitTestable(), findsOneWidget);
            await tester.tap(find.text(label));
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.byKey(const ValueKey('analytics-v2-total')),
              400,
              scrollable: scrollable,
              maxScrolls: 50,
            );
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<Text>(
                    find.byKey(const ValueKey('analytics-v2-total')),
                  )
                  .data,
              expected,
            );
            expect(tester.takeException(), isNull);
            await tester.ensureVisible(
              find.byKey(const ValueKey('analytics-v2-detail')),
            );
            await tester.pumpAndSettle();
            final state = number == 1
                ? 'clinic'
                : number == 2
                ? 'zero'
                : 'unavailable';
            await capture(tester, key, 'v2_${name}_$state');
          }
          expect(
            api.calls.where((p) => p == AnalyticsV2Repository.clinicsPath),
            hasLength(1),
          );
          await tester.pumpWidget(const SizedBox());
          await tester.binding.setSurfaceSize(null);
        },
      );
    }
  }
  testWidgets(
    'Arabic server search, directory pagination and archive filter use V2 queries',
    (tester) async {
      final api = responses();
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalyticsV2Panel(
              repository: AnalyticsV2Repository(client: api),
              initialQuery: query(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Next page'),
        450,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 50,
      );
      await tester.tap(find.text('Next page'));
      await tester.pumpAndSettle();
      expect(api.parameters.last['page'], 2);
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'عيادة اصطناعية 23');
      await tester.pump(const Duration(milliseconds: 351));
      await tester.pumpAndSettle();
      expect(api.parameters.last['search'], 'عيادة اصطناعية 23');
      expect(api.parameters.last['page'], 1);
      final toggle = find.byType(SwitchListTile);
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(api.parameters.last['include_deleted'], true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'V2 is the default analytics destination; patient role cannot issue reporting requests',
    (tester) async {
      AuthState().logout();
      AuthState().login(name: 'Synthetic', phone: 'synthetic', role: 'patient');
      final api = responses();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalyticsV2Panel(
              repository: AnalyticsV2Repository(client: api),
              initialQuery: query(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(api.calls, isEmpty);
      expect(find.textContaining('Super Admin'), findsOneWidget);
      expect(const AdminAnalyticsScreen().initialTab, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('V2 report fits narrow Arabic RTL at160-percent text scale', (
    tester,
  ) async {
    unawaited(LocaleService().setLanguage(AppLanguage.arabic));
    await tester.binding.setSurfaceSize(const Size(360, 900));
    final api = responses();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 900),
            textScaler: TextScaler.linear(1.6),
          ),
          child: Scaffold(
            body: AnalyticsV2Panel(
              repository: AnalyticsV2Repository(client: api),
              initialQuery: query(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('الصفحة التالية'),
      400,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 60,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
}
