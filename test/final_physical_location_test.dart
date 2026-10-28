import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_address_search.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/widgets/clinic_location_selector.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/google_business/presentation/google_business_screen.dart';
import 'package:aesthetic_way/features/locations/data/uae_location_repository.dart';
import 'package:aesthetic_way/features/locations/presentation/nearby_clinics_screen.dart';
import 'package:aesthetic_way/features/locations/services/patient_location_controller.dart';
import 'package:aesthetic_way/features/locations/data/nearby_clinics_repository.dart';
import 'backend_401560b_integration_test.dart' as source;
import 'google_business_readiness_test.dart' show BusinessFixture;
import 'nearby_locality_readiness_test.dart' show NearbyFixture, row;
import 'uae_location_qa_test.dart' show LocationProvider;
import 'onboarding_review_workflows_test.dart' as f;
import 'support/patient_visual_harness.dart';
import 'support/offline_map_test_cache.dart';

Map<String, dynamic> address({bool bilingual = false}) => {
  'lat': '25.2315000',
  'lon': '55.3242000',
  'display_name': 'Healthcare City, Dubai',
  'address': {
    'country_code': 'ae',
    'city': 'Dubai',
    'state': 'Dubai',
    if (bilingual) ...{
      'road:en': 'Returned street',
      'road:ar': 'الشارع المسترجع',
    },
  },
};

class Addresses extends ClinicAddressSearch {
  List<ClinicAddressResult> rows = [
    ClinicAddressResult.fromJson(address(), language: 'en')!,
  ];
  int calls = 0;
  @override
  Future<List<ClinicAddressResult>> search(
    String query, {
    required String language,
    CancelToken? cancelToken,
  }) async {
    calls++;
    return rows;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  late ApiClient api;
  late HttpClientAdapter old;
  setUp(() async {
    final cache = OfflineMapTestCache();
    addTearDown(cache.close);
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    AuthState().login(
      name: 'Disposable QA',
      phone: 'fixture',
      role: 'clinic_admin',
    );
    api = ApiClient();
    old = api.dio.httpClientAdapter;
    api.dio.httpClientAdapter = f.Adapter(
      (r) => f.body(source.catalog[r.path.split('/')[1]]),
    );
    ServerUaeLocationRepository.loaded = await ServerUaeLocationRepository(
      api: api,
    ).load();
    api.dio.httpClientAdapter = old;
  });
  tearDown(() {
    api.dio.httpClientAdapter = old;
    ClinicPortalService().resetTestingState();
    ServerUaeLocationRepository.loaded = null;
    AuthState().logout();
  });
  test(
    'OSM uses only genuine localized fields and never fabricates a translation',
    () {
      final one = ClinicAddressResult.fromJson(address(), language: 'en')!;
      expect(one.addressEn, 'Healthcare City, Dubai');
      expect(one.addressAr, isEmpty);
      final two = ClinicAddressResult.fromJson(
        address(bilingual: true),
        language: 'en',
      )!;
      expect(two.addressEn, 'Returned street');
      expect(two.addressAr, 'الشارع المسترجع');
      expect(
        ClinicAddressResult.fromJson(address(), language: 'ar')!.addressAr,
        isEmpty,
      );
    },
  );
  test(
    'outside UAE, reversed coordinates, missing country and nonfinite values are rejected',
    () {
      for (final d in [
        {...address(), 'lat': '55.32', 'lon': '25.23'},
        {...address(), 'lat': 'NaN'},
        {
          ...address(),
          'address': {'country_code': 'gb'},
        },
        {...address(), 'lat': '0'},
      ]) {
        expect(ClinicAddressResult.fromJson(d, language: 'en'), isNull);
      }
      expect(ClinicLocationSelection.validCoordinates(55.32, 25.23), false);
    },
  );
  test(
    'display-language fallback is never copied into an empty language editor',
    () {
      final c = ClinicModel.fromJson({
        ...f.clinic(),
        'address_en': 'Actual English',
        'address_ar': '',
      });
      expect(c.addressAr, 'Actual English');
      expect(c.editableAddressAr, isEmpty);
      expect(c.editableAddressEn, 'Actual English');
    },
  );
  for (final stale in [false, true]) {
    test(
      'location save is a six-field partial PATCH plus freshGET, stale=$stale',
      () async {
        final before = {
          ...f.clinic(),
          'city': 'Dubai',
          'emirate': 'Dubai',
          'address_en': 'Old',
          'address_ar': '',
          'latitude': '25.1',
          'longitude': '55.2',
          'google_place_id': 'Preserved-ID',
        };
        final saved = {
          ...before,
          'address_en': 'New',
          'latitude': '25.2315',
          'longitude': '55.3242',
        };
        final wire = f.Adapter(
          (r) => f.body(r.method == 'PATCH' || !stale ? saved : before),
        );
        api.dio.httpClientAdapter = wire;
        final service = ClinicPortalService()..resetTestingState();
        service.setActiveClinicForTesting(ClinicModel.fromJson(before));
        service.setCatalogRepositoryForTesting(
          ClinicCatalogRepository(apiClient: api),
        );
        final saving = service.updateClinicCoordinates(
          city: 'Dubai',
          emirate: 'Dubai',
          addressAr: '',
          addressEn: 'New',
          latitude: 25.2315,
          longitude: 55.3242,
        );
        if (stale) {
          await expectLater(saving, throwsA(isA<ApiException>()));
          expect(service.activeClinic.editableAddressEn, 'Old');
        } else {
          await saving;
          expect(service.activeClinic.editableAddressEn, 'New');
          expect(service.activeClinic.googlePlaceId, 'Preserved-ID');
        }
        expect(wire.requests.map((r) => r.method), ['PATCH', 'GET']);
        expect((wire.requests.first.data as Map).keys.toSet(), {
          'city',
          'emirate',
          'address_ar',
          'address_en',
          'latitude',
          'longitude',
        });
      },
    );
  }
  test('city/emirate conflict fails before any request', () async {
    final wire = f.Adapter((r) => f.body(f.clinic()));
    api.dio.httpClientAdapter = wire;
    await expectLater(
      ClinicPortalService().updateClinicCoordinates(
        city: 'Dubai',
        emirate: 'Abu Dhabi',
        addressAr: '',
        addressEn: '',
        latitude: 25.2,
        longitude: 55.3,
      ),
      throwsA(isA<ApiException>()),
    );
    expect(wire.requests, isEmpty);
  });
  testWidgets(
    'pasted Google name uses disclosed city query context without silently linking',
    (tester) async {
      final repo = BusinessFixture();
      await f.render(
        tester,
        GoogleBusinessScreen(
          repository: repo,
          initialQuery: '\u200fReturned   clinic',
          searchCity: 'Dubai',
        ),
      );
      await tester.pump(const Duration(milliseconds: 351));
      expect(repo.queries.single, 'Returned clinic, Dubai');
      expect(repo.links, isEmpty);
      await tester.tap(find.byType(FilterChip));
      await tester.pump(const Duration(milliseconds: 351));
      expect(repo.queries.last, 'Returned clinic');
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'OSM selection confirms overwrite, preserves unavailable Arabic, and requires entrance confirmation',
    (tester) async {
      final addresses = Addresses();
      ClinicLocationSelection? selection;
      await f.render(
        tester,
        Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () async {
                selection = await showClinicLocationSelector(
                  ctx,
                  city: 'Dubai',
                  addressAr: 'نص محفوظ',
                  addressEn: 'Owner edit',
                  latitude: 25.1,
                  longitude: 55.2,
                  addressSearch: addresses,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('clinic-address-search'));
      await tester.ensureVisible(field);
      await tester.enterText(field, 'Healthcare City');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('clinic-address-result-Healthcare City, Dubai'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Cancel'),
        ),
      );
      await tester.pumpAndSettle();
      final scroll = find
          .descendant(
            of: find.byKey(const ValueKey('clinic-location-form')),
            matching: find.byType(Scrollable),
          )
          .first;
      Future<void> reveal(Finder target, double delta) async {
        final position = tester.state<ScrollableState>(scroll).position;
        for (var i = 0; i < 20 && target.evaluate().isEmpty; i++) {
          position.jumpTo(
            (position.pixels + delta).clamp(
              position.minScrollExtent,
              position.maxScrollExtent,
            ),
          );
          await tester.pump();
        }
        expect(target, findsOneWidget);
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
      }

      await reveal(find.byKey(const ValueKey('clinic-address-en')), 250);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('clinic-address-en')))
            .controller!
            .text,
        'Owner edit',
      );
      await reveal(
        find.byKey(
          const ValueKey('clinic-address-result-Healthcare City, Dubai'),
        ),
        -250,
      );
      await tester.tap(
        find.byKey(
          const ValueKey('clinic-address-result-Healthcare City, Dubai'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use address'));
      await tester.pumpAndSettle();
      await reveal(find.byKey(const ValueKey('clinic-address-en')), 250);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('clinic-address-en')))
            .controller!
            .text,
        'Healthcare City, Dubai',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('clinic-address-ar')))
            .controller!
            .text,
        'نص محفوظ',
      );
      final save = find.widgetWithText(FilledButton, 'Use This Location');
      await reveal(save, 250);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      final confirm = find.text('Confirm pin is the exact clinic location');
      await reveal(confirm, -200);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm entrance'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(selection!.latitude, 25.2315);
      expect(selection!.longitude, 55.3242);
      expect(selection!.addressAr, 'نص محفوظ');
      expect(addresses.calls, 1);
      addresses.close();
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  for (final gps in [false, true]) {
    testWidgets(
      'Nearby origin heading and server-only distance, gps=$gps at320dp180percent',
      (tester) async {
        AuthState().login(
          name: 'Disposable QA',
          phone: 'fixture',
          role: 'patient',
        );
        final loc = PatientLocationController(provider: LocationProvider());
        if (gps) {
          await loc.useDeviceLocation();
        } else {
          loc.selectCity('Dubai');
        }
        final repo = NearbyFixture()
          ..reply = (q, p) async => NearbyClinicsPage(
            [
              NearbyClinic(
                clinic: row('last', 2.4).clinic,
                distanceKm: gps ? 2.4 : null,
              ),
            ],
            reference: gps
                ? NearbyDistanceReference.device
                : NearbyDistanceReference.manualLocality,
          );
        await f.render(
          tester,
          Builder(
            builder: (ctx) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(
                textScaler: const TextScaler.linear(1.8),
                viewPadding: const EdgeInsets.only(bottom: 34),
              ),
              child: NearbyClinicsScreen(location: loc, repository: repo),
            ),
          ),
          width: 320,
        );
        await tester.pump(const Duration(milliseconds: 351));
        await tester.pumpAndSettle();
        expect(
          find.text(
            gps ? 'Near my current location' : 'Browsing clinics in Dubai',
          ),
          findsOneWidget,
        );
        final cta = find.text('Request consultation');
        await tester.ensureVisible(cta);
        await tester.pumpAndSettle();
        expect(
          find.text('Approximately 2.4 km away'),
          gps ? findsOneWidget : findsNothing,
        );
        expect(tester.getRect(cta).bottom, lessThan(966));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        loc.dispose();
        await tester.binding.setSurfaceSize(null);
      },
    );
  }
}
