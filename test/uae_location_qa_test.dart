import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/features/locations/data/nearby_clinics_repository.dart';
import 'package:aesthetic_way/features/locations/data/uae_location_repository.dart';
import 'package:aesthetic_way/features/locations/services/patient_location_controller.dart';
import 'package:aesthetic_way/features/locations/presentation/home_location_panel.dart';
import 'package:aesthetic_way/features/locations/presentation/uae_location_picker.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/clinics/data/clinics_repository.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/account_deletion_screen.dart';
import 'onboarding_review_workflows_test.dart' as f;
import 'support/patient_visual_harness.dart';

class LocationProvider implements ForegroundLocationProvider {
  bool enabled = true;
  LocationPermission grant = LocationPermission.whileInUse;
  int reads = 0, asks = 0;
  Future<PatientPosition> Function() answer = () async =>
      const PatientPosition(25.1, 55.2);
  @override
  Future<bool> servicesEnabled() async => enabled;
  @override
  Future<LocationPermission> permission() async => grant;
  @override
  Future<LocationPermission> requestPermission() async {
    asks++;
    return grant;
  }

  @override
  Future<PatientPosition> position() {
    reads++;
    return answer();
  }
}

class BrokenCatalog implements UaeLocationRepository {
  @override
  Future<Never> load() => Future.error(StateError('offline'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    AuthState().login(name: 'Disposable QA', phone: 'fixture', role: 'patient');
  });
  tearDown(() {
    AuthState().logout();
  });
  test(
    'seven emirates are distinct from the explicitly partial city catalog',
    () async {
      final c = await const BundledUaeLocationRepository().load();
      expect(c.emirates.map((e) => e.code).toSet(), hasLength(7));
      expect(c.cities.length, greaterThan(7));
      expect(c.authoritative, false);
      for (final name in [
        'Al Ain',
        'Hatta',
        'Khor Fakkan',
        'Kalba',
        'Dibba Al Hisn',
        'Dibba Al Fujairah',
      ]) {
        expect(c.resolve(name), isNotNull);
      }
      for (final city in c.cities) {
        expect(c.emirateFor(city).code, city.emirateCode);
      }
    },
  );
  for (final alias in [
    'Abu-Dhabi',
    'Abudhabi',
    'أبو ظبي',
    'ابوظبي',
    'abu-dhabi',
  ]) {
    test('legacy alias stable across language changes: $alias', () {
      final city = compatibilityUaeCatalog.resolve(alias)!;
      expect(city.code, 'abu-dhabi');
      expect(compatibilityUaeCatalog.legacyCityQuery(alias), 'Abu Dhabi');
      expect(city.label(true), 'أبوظبي');
      expect(city.code, 'abu-dhabi');
    });
  }
  test(
    'unknown old locality preserved, substring Dubai never replaces another city',
    () {
      expect(
        compatibilityUaeCatalog.legacyCityQuery('Dubai South'),
        'Dubai South',
      );
      expect(compatibilityUaeCatalog.legacyCityQuery('الكل'), isNull);
      expect(
        compatibilityUaeCatalog.resolve('Dibba'),
        isNull,
      ); // Ambiguous municipality.
    },
  );
  test(
    'unsupported nearby boundary never issues an undocumented request',
    () async {
      const repo = UnavailableNearbyClinicsRepository();
      expect(repo.supported, false);
      await expectLater(
        repo.getNearby(const PatientPosition(25.1, 55.2)),
        throwsUnsupportedError,
      );
    },
  );
  test(
    'distance is explicit server km, never inferred from legacy distance',
    () {
      final clinic = ClinicModel.fromJson({
        'id': 'server-clinic',
        'distance': 1250,
      });
      expect(
        clinic.distanceKm,
        0,
        reason: 'Unknown legacy distance is not kilometres',
      );
      expect(ClinicModel.fromJson({'distance_km': 1.25}).distanceKm, 1.25);
      final result = NearbyClinic(clinic: clinic, distanceKm: 1.25);
      expect(result.distanceKm, 1.25);
      expect(
        () => NearbyClinic(clinic: clinic, distanceKm: double.nan),
        throwsArgumentError,
      );
      expect(
        () => NearbyClinic(clinic: clinic, distanceKm: -1),
        throwsArgumentError,
      );
    },
  );
  for (final grant in [
    LocationPermission.denied,
    LocationPermission.deniedForever,
    LocationPermission.unableToDetermine,
  ]) {
    test(
      'permission $grant cannot read coordinates or force a prompt',
      () async {
        final p = LocationProvider()..grant = grant;
        final c = PatientLocationController(provider: p);
        expect(p.asks, 0);
        expect(p.reads, 0);
        await c.useDeviceLocation();
        expect(p.reads, 0);
        expect(c.position, isNull);
        expect(
          c.state,
          grant == LocationPermission.deniedForever
              ? PatientLocationState.deniedForever
              : PatientLocationState.denied,
        );
        c.dispose();
      },
    );
  }
  test('services off falls back without requesting permission', () async {
    final p = LocationProvider()..enabled = false;
    final c = PatientLocationController(provider: p);
    await c.useDeviceLocation();
    expect(c.state, PatientLocationState.disabled);
    expect(p.asks, 0);
    expect(p.reads, 0);
    c.dispose();
  });
  for (final p in [
    const PatientPosition(51.5, -.1),
    const PatientPosition(0, 0),
    const PatientPosition(double.nan, 55.2),
  ]) {
    test(
      'outside coverage and invalid positions never become a Dubai origin: ${p.latitude}',
      () async {
        final provider = LocationProvider()..answer = () async => p;
        final c = PatientLocationController(provider: provider);
        await c.useDeviceLocation();
        expect(c.position, isNull);
        expect([
          PatientLocationState.outsideCoverage,
          PatientLocationState.unavailable,
        ], contains(c.state));
        c.dispose();
      },
    );
  }
  test('timeout offers manual fallback', () async {
    final p = LocationProvider()
      ..answer = () => Future.error(TimeoutException('fixture'));
    final c = PatientLocationController(provider: p);
    await c.useDeviceLocation();
    expect(c.state, PatientLocationState.timeout);
    c.dispose();
  });
  test(
    'manual choice supersedes pending GPS, duplicate taps use one read',
    () async {
      final wait = Completer<PatientPosition>();
      final p = LocationProvider()..answer = () => wait.future;
      final c = PatientLocationController(provider: p);
      final flight = c.useDeviceLocation();
      await Future<void>.delayed(Duration.zero);
      await c.useDeviceLocation();
      c.selectCity('العين');
      wait.complete(const PatientPosition(25.1, 55.2));
      await flight;
      expect(c.city, 'Al Ain');
      expect(c.position, isNull);
      expect(p.reads, 1);
      c.dispose();
    },
  );
  for (final action in ['logout', 'switch', 'dispose', 'background']) {
    test('pending GPS cannot leak after $action', () async {
      final wait = Completer<PatientPosition>();
      final p = LocationProvider()..answer = () => wait.future;
      final c = PatientLocationController(provider: p);
      final flight = c.useDeviceLocation();
      await Future<void>.delayed(Duration.zero);
      switch (action) {
        case 'logout':
          AuthState().logout();
        case 'switch':
          AuthState().login(
            name: 'Other QA',
            phone: 'other-fixture',
            role: 'patient',
          );
        case 'dispose':
          c.dispose();
        case 'background':
          c.releasePosition();
      }
      wait.complete(const PatientPosition(25.1, 55.2));
      await flight;
      expect(c.position, isNull);
      if (action != 'dispose') c.dispose();
    });
  }
  test(
    'foreground approximate position stays in memory and is released',
    () async {
      final p = LocationProvider();
      final c = PatientLocationController(provider: p);
      await c.useDeviceLocation();
      expect(c.state, PatientLocationState.ready);
      expect(c.position?.latitude, 25.1);
      c.releasePosition();
      expect(c.position, isNull);
      c.dispose();
    },
  );
  test(
    'legacy city payload uses verified text contract and bounded page size',
    () async {
      final api = ApiClient();
      final old = api.dio.httpClientAdapter;
      final wire = f.Adapter((r) => f.body(f.page([])));
      api.dio.httpClientAdapter = wire;
      addTearDown(() => api.dio.httpClientAdapter = old);
      await ClinicsRepository(
        apiClient: api,
      ).getClinics(city: 'al-ain', page: 2, pageSize: 999);
      final q = wire.requests.single.queryParameters;
      expect(q, {'city': 'Al Ain', 'page': 2, 'page_size': 20});
      expect(q.containsKey('city_id'), false);
      expect(q.containsKey('latitude'), false);
    },
  );
  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      testWidgets('foreground and manual location panel dark=$dark ar=$ar', (
        tester,
      ) async {
        final p = LocationProvider();
        final c = PatientLocationController(provider: p);
        await f.render(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: HomeLocationPanel(controller: c),
            ),
          ),
          dark: dark,
          ar: ar,
          width: 390,
        );
        expect(p.asks, 0);
        expect(p.reads, 0);
        await f.capture(
          tester,
          'geo_home_panel_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
        );
        await tester.tap(find.byKey(const ValueKey('home-use-location')));
        await tester.pumpAndSettle();
        expect(p.reads, 1);
        expect(
          find.textContaining(
            ar ? 'بانتظار دعم الخادم' : 'awaiting server support',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('km'), findsNothing);
        expect(find.textContaining('VIP'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        c.dispose();
        await tester.binding.setSurfaceSize(null);
      });
      testWidgets('hierarchical city picker dark=$dark ar=$ar', (tester) async {
        await f.render(
          tester,
          const Scaffold(body: UaeLocationPicker(selected: 'Al Ain')),
          dark: dark,
          ar: ar,
        );
        expect(find.text(ar ? 'العين' : 'Al Ain'), findsOneWidget);
        expect(find.text(ar ? 'حتا' : 'Hatta'), findsNothing);
        await f.capture(
          tester,
          'geo_picker_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
        );
        await tester.enterText(find.byType(TextField), 'not-a-city');
        await tester.pump();
        expect(
          find.textContaining(ar ? 'لا توجد مدينة مطابقة' : 'No matching city'),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
      });
    }
  }
  testWidgets('catalog failure has a retry, not invented cities', (
    tester,
  ) async {
    await f.render(
      tester,
      Scaffold(body: UaeLocationPicker(repository: BrokenCatalog())),
    );
    expect(find.textContaining('Locations could not load'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
    'OTP accepted response without destination never claims a guessed recipient',
    (tester) async {
      final api = ApiClient();
      final old = api.dio.httpClientAdapter;
      api.dio.httpClientAdapter = f.Adapter(
        (r) =>
            f.body({'success': true, 'expires_in': 600, 'resend_cooldown': 60}),
      );
      addTearDown(() => api.dio.httpClientAdapter = old);
      await f.render(tester, const AccountDeletionScreen());
      await tester.tap(find.byKey(const ValueKey('deletion-request-code')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('did not identify its delivery channel'),
        findsOneWidget,
      );
      expect(find.text('Code sent.'), findsNothing);
      expect(find.textContaining('Resend in'), findsOneWidget);
      await f.capture(tester, 'deletion_destination_unknown');
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'sole clinic administrator sees honest block and supported portal exit',
    (tester) async {
      final api = ApiClient();
      final old = api.dio.httpClientAdapter;
      final wire = f.Adapter(
        (r) => f.body({
          'success': false,
          'code': 'SOLE_CLINIC_ADMIN',
          'detail': 'private raw clinic name',
        }, 400),
      );
      api.dio.httpClientAdapter = wire;
      addTearDown(() => api.dio.httpClientAdapter = old);
      await f.render(tester, const AccountDeletionScreen());
      await tester.tap(find.byKey(const ValueKey('deletion-request-code')));
      await tester.pumpAndSettle();
      expect(find.text('Return to your portal'), findsOneWidget);
      expect(
        find.textContaining('only active clinic administrator'),
        findsWidgets,
      );
      expect(find.byKey(const ValueKey('deletion-code')), findsNothing);
      expect(find.textContaining('private raw clinic name'), findsNothing);
      expect(wire.requests, hasLength(1));
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  for (final ar in [false, true]) {
    testWidgets(
      'location panel and city field at 320dp and 180 percent ar=$ar',
      (tester) async {
        final c = PatientLocationController(provider: LocationProvider());
        c.selectCity('Ras Al Khaimah');
        await f.render(
          tester,
          Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 1000),
                textScaler: TextScaler.linear(1.8),
              ),
              child: SingleChildScrollView(
                child: HomeLocationPanel(controller: c),
              ),
            ),
          ),
          width: 320,
          ar: ar,
        );
        expect(tester.takeException(), isNull);
        await f.capture(tester, 'geo_scaled_${ar ? 'ar' : 'en'}');
        await tester.pumpWidget(const SizedBox());
        c.dispose();
        await tester.binding.setSurfaceSize(null);
      },
    );
  }
  testWidgets(
    'city picker scrolls its full hierarchy with keyboard and large text',
    (tester) async {
      await f.render(
        tester,
        const Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 700),
              viewInsets: EdgeInsets.only(bottom: 250),
              textScaler: TextScaler.linear(1.8),
            ),
            child: UaeLocationPicker(selected: 'Al Ain'),
          ),
        ),
        width: 320,
      );
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
}
