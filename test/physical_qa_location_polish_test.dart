import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/features/locations/data/uae_location_repository.dart';
import 'package:aesthetic_way/features/locations/models/uae_location.dart';
import 'package:aesthetic_way/features/locations/presentation/uae_location_picker.dart';
import 'backend_401560b_integration_test.dart' as source;
import 'onboarding_review_workflows_test.dart' as f;
import 'support/patient_visual_harness.dart';

class ActualCatalog extends UaeLocationRepository {
  ActualCatalog(this.catalog);
  final UaeLocationCatalog catalog;
  @override
  Future<UaeLocationCatalog> load() async => catalog;
}

Future<void> render(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  bool ar = false,
  double width = 430,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await f.render(tester, child, dark: dark, ar: ar, width: width);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late UaeLocationCatalog catalog;
  setUpAll(() async {
    await loadPatientVisualFonts();
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    final api = ApiClient(), old = ApiClient().dio.httpClientAdapter;
    final data = source.catalog;
    api.dio.httpClientAdapter = f.Adapter(
      (r) => f.body(data[r.path.split('/')[1]]),
    );
    try {
      catalog = await ServerUaeLocationRepository(api: api).load();
    } finally {
      api.dio.httpClientAdapter = old;
    }
  });
  setUp(() {
    AuthState().login(name: 'Disposable QA', phone: 'fixture', role: 'patient');
    ServerUaeLocationRepository.loaded = catalog;
  });
  tearDown(() {
    AuthState().logout();
    ServerUaeLocationRepository.loaded = null;
  });
  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      testWidgets(
        'selected city/area path, search and reviewed renders dark=$dark ar=$ar',
        (tester) async {
          await render(
            tester,
            Scaffold(
              body: UaeLocationPicker(
                selected: 'Dubai',
                selectedAreaCode: 'jumeirah',
                includeAreas: true,
                repository: ActualCatalog(catalog),
              ),
            ),
            dark: dark,
            ar: ar,
          );
          final city = find.byKey(const ValueKey('locality-city-dubai'));
          expect(tester.widget<ListTile>(city).selected, true);
          expect(
            find.byKey(const ValueKey('locality-step-emirate')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('locality-step-area')),
            findsOneWidget,
          );
          await f.capture(
            tester,
            'location_after_city_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          await tester.tap(city);
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<ListTile>(
                  find.byKey(const ValueKey('locality-area-jumeirah')),
                )
                .selected,
            true,
          );
          await f.capture(
            tester,
            'location_after_area_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          await tester.enterText(
            find.byKey(const ValueKey('locality-search')),
            ar ? 'البرشاء' : 'Al Barsha',
          );
          await tester.pump();
          expect(
            find.byKey(const ValueKey('locality-area-al-barsha')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('locality-area-jumeirah')),
            findsNothing,
          );
          await tester.tap(find.byKey(const ValueKey('locality-back')));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<TextField>(
                  find.byKey(const ValueKey('locality-search')),
                )
                .controller!
                .text,
            isEmpty,
          );
          expect(
            tester
                .widget<ListTile>(
                  find.byKey(const ValueKey('locality-city-dubai')),
                )
                .selected,
            true,
          );
          await tester.tap(find.byKey(const ValueKey('locality-city-dubai')));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<ListTile>(
                  find.byKey(const ValueKey('locality-area-jumeirah')),
                )
                .selected,
            true,
            reason: 'Back navigation preserves draft and saved selection.',
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.binding.setSurfaceSize(null);
        },
      );
    }
  }
  testWidgets(
    'changing emirate clears old city/area and only shows real children',
    (tester) async {
      await render(
        tester,
        Scaffold(
          body: UaeLocationPicker(
            selected: 'Dubai',
            selectedAreaCode: 'jumeirah',
            includeAreas: true,
            repository: ActualCatalog(catalog),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('locality-step-emirate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('locality-emirate-AD')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('locality-city-dubai')), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('locality-confirm')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('locality-city-al-ain')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('locality-area-jumeirah')),
        findsNothing,
      );
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('locality-whole-city')))
            .selected,
        true,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'selection commits only on confirmation; reopening restores selected area',
    (tester) async {
      UaeLocality? selected;
      await render(
        tester,
        Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () async {
                selected = await showUaeLocalityPicker(
                  ctx,
                  selected: 'Dubai',
                  areaCode: 'jumeirah',
                  repository: ActualCatalog(catalog),
                );
              },
              child: const Text('Open picker'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open picker'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('locality-city-dubai')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('locality-area-al-barsha')),
        150,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.byKey(const ValueKey('locality-area-al-barsha')));
      await tester.pump();
      expect(selected, isNull);
      await tester.ensureVisible(
        find.byKey(const ValueKey('locality-confirm')),
      );
      await tester.tap(find.byKey(const ValueKey('locality-confirm')));
      await tester.pumpAndSettle();
      expect(selected!.city.code, 'dubai');
      expect(selected!.area!.code, 'al-barsha');
      await render(
        tester,
        Scaffold(
          body: UaeLocationPicker(
            selected: selected!.city.code,
            selectedAreaCode: selected!.area!.code,
            includeAreas: true,
            repository: ActualCatalog(catalog),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('locality-city-dubai')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('locality-area-al-barsha')),
        150,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        tester
            .widget<ListTile>(
              find.byKey(const ValueKey('locality-area-al-barsha')),
            )
            .selected,
        true,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'modal Back moves up one step without discarding saved location; close cancels',
    (tester) async {
      UaeLocality? selected;
      await render(
        tester,
        Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () async {
                selected = await showUaeLocalityPicker(
                  ctx,
                  selected: 'Dubai',
                  repository: ActualCatalog(catalog),
                );
              },
              child: const Text('Open picker'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open picker'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('locality-city-dubai')));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('locality-city-dubai')), findsOneWidget);
      expect(selected, isNull);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(selected, isNull);
      expect(find.byType(UaeLocationPicker), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  for (final ar in [false, true]) {
    testWidgets(
      'keyboard scrolling and 180percent text remain usable at320dp ar=$ar',
      (tester) async {
        await render(
          tester,
          Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 700),
                viewInsets: EdgeInsets.only(bottom: 240),
                textScaler: TextScaler.linear(1.8),
              ),
              child: UaeLocationPicker(
                selected: 'Dubai',
                includeAreas: true,
                repository: ActualCatalog(catalog),
              ),
            ),
          ),
          width: 320,
          ar: ar,
        );
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('locality-city-dubai')),
          150,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(find.byKey(const ValueKey('locality-city-dubai')));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('locality-area-al-barsha')),
          150,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('locality-area-al-barsha')),
          150,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(find.byKey(const ValueKey('locality-area-al-barsha')));
        await tester.pump();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('locality-confirm')),
          150,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('locality-confirm')),
              )
              .onPressed,
          isNotNull,
        );
        await f.capture(tester, 'location_scaled_${ar ? 'ar' : 'en'}');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
      },
    );
  }
  testWidgets(
    'location field duplicate taps open one sheet and session change discards result',
    (tester) async {
      String? selected;
      await render(
        tester,
        Scaffold(
          body: UaeLocationField(
            value: 'Dubai',
            onChanged: (s) => selected = s,
          ),
        ),
      );
      final field = find.byType(OutlinedButton).first;
      await tester.tap(field);
      await tester.tap(field, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(UaeLocationPicker), findsOneWidget);
      AuthState().login(
        name: 'Different QA',
        phone: 'fixture-new',
        role: 'patient',
      );
      await tester.tap(find.byKey(const ValueKey('locality-city-dubai')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('locality-confirm')),
      );
      await tester.tap(find.byKey(const ValueKey('locality-confirm')));
      await tester.pumpAndSettle();
      expect(selected, isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
}
