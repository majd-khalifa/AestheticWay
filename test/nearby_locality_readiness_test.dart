import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/utils/clinic_location.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/locations/models/uae_location.dart';
import 'package:aesthetic_way/features/locations/data/uae_location_repository.dart';
import 'package:aesthetic_way/features/locations/data/nearby_clinics_repository.dart';
import 'package:aesthetic_way/features/locations/services/patient_location_controller.dart';
import 'package:aesthetic_way/features/locations/services/nearby_discovery_controller.dart';
import 'package:aesthetic_way/features/locations/presentation/uae_location_picker.dart';
import 'package:aesthetic_way/features/locations/presentation/nearby_clinics_screen.dart';
import 'uae_location_qa_test.dart' show LocationProvider;
import 'onboarding_review_workflows_test.dart' as f;
import 'support/patient_visual_harness.dart';

NearbyClinic row(String id, double km, {String tier = 'basic'}) => NearbyClinic(
  clinic: ClinicModel.fromJson({
    'id': id,
    'name_en': 'Disposable clinic $id',
    'name_ar': 'عيادة اختبار $id',
    'subscription_tier': tier,
    'city': 'Dubai',
  }),
  distanceKm: km,
  branchId: 'branch-$id',
  branchLocation: const ClinicCoordinates(25.1, 55.2),
);

class NearbyFixture extends NearbyClinicsRepository {
  bool available = true;
  final pages = <int>[], selections = <NearbySearchQuery>[];
  Future<NearbyClinicsPage> Function(NearbySearchQuery, int)? reply;
  @override
  bool get supported => available;
  @override
  Future<NearbyClinicsPage> search(NearbySearchQuery query, {int page = 1}) {
    pages.add(page);
    selections.add(query);
    return reply?.call(query, page) ??
        Future.value(
          NearbyClinicsPage(
            [row('nearest-basic', 1.125), row('farther-vip', 4.5, tier: 'vip')],
            reference: query.origin == null
                ? NearbyDistanceReference.selectedLocality
                : NearbyDistanceReference.device,
          ),
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    AuthState().login(
      name: 'Disposable QA',
      phone: 'fixture-patient',
      role: 'patient',
    );
  });
  tearDown(() => AuthState().logout());
  UaeLocality dubai([String? area = 'jumeirah']) {
    final city = compatibilityUaeCatalog.resolve('Dubai')!;
    return UaeLocality(
      city,
      compatibilityUaeCatalog.resolveArea(area, cityCode: city.code),
    );
  }

  test(
    'three-level hierarchy validates parent city and preserves address text',
    () {
      final value = dubai();
      expect(value.city.emirateCode, 'ae-du');
      expect(value.area!.cityCode, value.city.code);
      expect(value.label(true), 'دبي • جميرا');
      expect(
        value.addressWithArea('Building A', arabic: false),
        'Jumeirah • Building A',
      );
      expect(
        value.addressWithArea('Jumeirah • Building A', arabic: false),
        'Jumeirah • Building A',
      );
      expect(
        () =>
            UaeLocality(compatibilityUaeCatalog.resolve('Al Ain')!, value.area),
        throwsArgumentError,
      );
      expect(compatibilityUaeCatalog.authoritative, false);
    },
  );
  test('area aliases resolve only within their own city', () {
    expect(
      compatibilityUaeCatalog.resolveArea('جميرا', cityCode: 'dubai')?.code,
      'jumeirah',
    );
    expect(
      compatibilityUaeCatalog.resolveArea('جميرا', cityCode: 'abu-dhabi'),
      isNull,
    );
    expect(
      compatibilityUaeCatalog
          .resolveArea('al-bateen', cityCode: 'abu-dhabi')
          ?.nameAr,
      'البطين',
    );
  });
  test(
    'manual selection retains area in memory and clears it on city/session change',
    () {
      final c = PatientLocationController(provider: LocationProvider());
      c.selectLocality(dubai());
      expect(c.areaCode, 'jumeirah');
      expect(c.locality!.area!.code, 'jumeirah');
      c.selectCity('Al Ain');
      expect(c.areaCode, isNull);
      c.selectLocality(dubai());
      AuthState().logout();
      expect(c.areaCode, isNull);
      expect(c.position, isNull);
      c.dispose();
    },
  );
  test(
    'foreground permission revocation clears coordinates without another permission request',
    () async {
      final p = LocationProvider();
      final c = PatientLocationController(provider: p);
      await c.useDeviceLocation();
      expect(c.position, isNotNull);
      p.grant = LocationPermission.deniedForever;
      await c.revalidatePermission();
      expect(c.position, isNull);
      expect(c.state, PatientLocationState.deniedForever);
      expect(p.asks, 0);
      c.dispose();
    },
  );
  testWidgets(
    'server distance order includes Basic before paid tier, with no client calculation',
    (tester) async {
      final loc = PatientLocationController(provider: LocationProvider());
      loc.selectLocality(dubai());
      final repo = NearbyFixture();
      final controller = NearbyDiscoveryController(loc, repo);
      await tester.pump(const Duration(milliseconds: 351));
      expect(controller.paging.items.map((r) => r.clinic.id), [
        'nearest-basic',
        'farther-vip',
      ]);
      expect(controller.paging.items.first.distanceKm, 1.125);
      expect(
        controller.distanceLabel(controller.paging.items.first),
        contains('selected locality'),
      );
      expect(repo.selections.single.locality!.area!.code, 'jumeirah');
      expect(repo.selections.single.origin, isNull);
      controller.dispose();
      loc.dispose();
    },
  );
  testWidgets(
    'stable pages deduplicate clinic/branch entries and coalesce load-more taps',
    (tester) async {
      final loc = PatientLocationController(provider: LocationProvider())
        ..selectLocality(dubai());
      final repo = NearbyFixture();
      repo.reply = (q, p) async => NearbyClinicsPage(
        p == 1 ? [row('a', 1), row('b', 2)] : [row('b', 2), row('c', 3)],
        hasMore: p == 1,
        total: 3,
        reference: NearbyDistanceReference.selectedLocality,
      );
      final c = NearbyDiscoveryController(loc, repo);
      await tester.pump(const Duration(milliseconds: 351));
      await Future.wait([c.paging.loadMore(), c.paging.loadMore()]);
      expect(repo.pages, [1, 2]);
      expect(c.paging.items.map((r) => r.clinic.id), ['a', 'b', 'c']);
      expect(c.paging.hasMore, false);
      c.dispose();
      loc.dispose();
    },
  );
  for (final invalid in ['unsorted', 'unknownReference', 'deviceWithoutGps']) {
    testWidgets('unverified nearby response stays an error: $invalid', (
      tester,
    ) async {
      final loc = PatientLocationController(provider: LocationProvider())
        ..selectLocality(dubai());
      final repo = NearbyFixture();
      repo.reply = (q, p) async => NearbyClinicsPage(
        invalid == 'unsorted'
            ? [row('bad', 5), row('near', 1)]
            : [row('row', 1)],
        reference: invalid == 'unknownReference'
            ? NearbyDistanceReference.unknown
            : invalid == 'deviceWithoutGps'
            ? NearbyDistanceReference.device
            : NearbyDistanceReference.selectedLocality,
      );
      final c = NearbyDiscoveryController(loc, repo);
      await tester.pump(const Duration(milliseconds: 351));
      expect(c.paging.items, isEmpty);
      expect(c.paging.error, isNotNull);
      c.dispose();
      loc.dispose();
    });
  }
  testWidgets(
    'unsupported adapter makes zero nearby requests and keeps city browsing honest',
    (tester) async {
      final loc = PatientLocationController(provider: LocationProvider())
        ..selectLocality(dubai());
      final repo = NearbyFixture()..available = false;
      final c = NearbyDiscoveryController(loc, repo);
      await tester.pump(const Duration(milliseconds: 351));
      expect(repo.pages, isEmpty);
      expect(c.paging.items, isEmpty);
      c.dispose();
      loc.dispose();
    },
  );
  testWidgets('manual change rejects old result and old distance reference', (
    tester,
  ) async {
    final wait = Completer<NearbyClinicsPage>();
    final loc = PatientLocationController(provider: LocationProvider())
      ..selectLocality(dubai());
    final repo = NearbyFixture();
    repo.reply = (q, p) => q.locality!.city.code == 'dubai'
        ? wait.future
        : Future.value(
            NearbyClinicsPage([
              row('new-city', 2),
            ], reference: NearbyDistanceReference.selectedLocality),
          );
    final c = NearbyDiscoveryController(loc, repo);
    await tester.pump(const Duration(milliseconds: 351));
    loc.selectCity('Al Ain');
    await tester.pump(const Duration(milliseconds: 351));
    wait.complete(
      NearbyClinicsPage([
        row('stale', 1),
      ], reference: NearbyDistanceReference.device),
    );
    await tester.pump();
    expect(c.paging.items.single.clinic.id, 'new-city');
    expect(c.reference, NearbyDistanceReference.selectedLocality);
    c.dispose();
    loc.dispose();
  });
  testWidgets(
    'backgrounding invalidates a pending response and does not start another request',
    (tester) async {
      final wait = Completer<NearbyClinicsPage>();
      final loc = PatientLocationController(provider: LocationProvider())
        ..selectLocality(dubai());
      final repo = NearbyFixture()..reply = (q, p) => wait.future;
      final c = NearbyDiscoveryController(loc, repo);
      await tester.pump(const Duration(milliseconds: 351));
      c.setActive(false);
      wait.complete(
        NearbyClinicsPage([
          row('late', 1),
        ], reference: NearbyDistanceReference.selectedLocality),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(c.paging.items, isEmpty);
      expect(repo.pages, [1]);
      c.dispose();
      loc.dispose();
    },
  );
  testWidgets('logout removes nearby results and drops late pages', (
    tester,
  ) async {
    final loc = PatientLocationController(provider: LocationProvider())
      ..selectLocality(dubai());
    final repo = NearbyFixture();
    final c = NearbyDiscoveryController(loc, repo);
    await tester.pump(const Duration(milliseconds: 351));
    expect(c.paging.items, isNotEmpty);
    AuthState().logout();
    await tester.pump();
    expect(c.paging.items, isEmpty);
    expect(loc.position, isNull);
    c.dispose();
    loc.dispose();
  });
  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      testWidgets('emirate city area picker dark=$dark ar=$ar', (tester) async {
        await f.render(
          tester,
          const Scaffold(
            body: UaeLocationPicker(
              selected: 'Dubai',
              includeAreas: true,
              repository: BundledUaeLocationRepository(),
            ),
          ),
          dark: dark,
          ar: ar,
        );
        await tester.tap(
          find.byWidgetPredicate(
            (w) =>
                w is ListTile &&
                w.title is Text &&
                (w.title as Text).data == (ar ? 'دبي' : 'Dubai'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('locality-area-jumeirah')),
          120,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(find.text(ar ? 'جميرا' : 'Jumeirah'), findsOneWidget);
        await f.capture(
          tester,
          'locality_areas_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
        );
        await tester.enterText(
          find.byType(TextField),
          ar ? 'جميرا' : 'Jumeirah',
        );
        await tester.pump();
        expect(find.text(ar ? 'البرشاء' : 'Al Barsha'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
      });
      testWidgets('nearby unavailable map/list dark=$dark ar=$ar', (
        tester,
      ) async {
        await f.render(tester, const NearbyClinicsScreen(), dark: dark, ar: ar);
        expect(
          find.textContaining(
            ar ? 'البحث عن الأقرب غير متاح' : 'Nearby search is not available',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('km away'), findsNothing);
        await f.capture(
          tester,
          'nearby_unavailable_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
      });
    }
  }
  testWidgets(
    'future adapter renders only explicit server distance, no subscription labels',
    (tester) async {
      final loc = PatientLocationController(provider: LocationProvider());
      await loc.useDeviceLocation();
      await f.render(
        tester,
        NearbyClinicsScreen(location: loc, repository: NearbyFixture()),
      );
      await tester.pump(const Duration(milliseconds: 351));
      await tester.pumpAndSettle();
      expect(find.textContaining('Approximately 1.1 km away'), findsOneWidget);
      expect(find.textContaining('VIP'), findsNothing);
      await f.capture(tester, 'nearby_fixture_server_distance');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      loc.dispose();
      await tester.binding.setSurfaceSize(null);
    },
  );
}
