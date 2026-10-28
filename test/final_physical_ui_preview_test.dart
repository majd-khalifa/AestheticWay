// Same harness also runs against unmodified f20ab75 for honest before images.
// All data/media here are disposable fixtures, not production API evidence.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/widgets/clinic_location_selector.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinic_profile_screen.dart';
import 'package:aesthetic_way/features/clinics/presentation/widgets/filter_bottom_sheet.dart';
import 'package:aesthetic_way/features/home/presentation/widgets/featured_ads_carousel.dart';
import 'package:aesthetic_way/features/google_business/presentation/google_business_screen.dart';
import 'package:aesthetic_way/features/locations/data/uae_location_repository.dart';
import 'package:aesthetic_way/features/locations/data/nearby_clinics_repository.dart';
import 'package:aesthetic_way/features/locations/presentation/nearby_clinics_screen.dart';
import 'package:aesthetic_way/features/locations/presentation/uae_location_picker.dart';
import 'package:aesthetic_way/features/locations/services/patient_location_controller.dart';
import 'onboarding_review_workflows_test.dart' as f;
import 'backend_401560b_integration_test.dart' as source;
import 'physical_qa_location_polish_test.dart' show ActualCatalog;
import 'google_business_readiness_test.dart' show BusinessFixture;
import 'nearby_locality_readiness_test.dart' show NearbyFixture, row;
import 'uae_location_qa_test.dart' show LocationProvider;
import 'support/patient_fixtures.dart';
import 'support/patient_visual_harness.dart';
import 'support/settle_preview_images.dart';
import 'support/offline_map_test_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  setUp(() async {
    final cache = OfflineMapTestCache();
    addTearDown(cache.close);
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    final api = ApiClient(), old = ApiClient().dio.httpClientAdapter;
    api.dio.httpClientAdapter = f.Adapter(
      (r) => f.body(source.catalog[r.path.split('/')[1]] ?? f.page([])),
    );
    ServerUaeLocationRepository.loaded = await ServerUaeLocationRepository(
      api: api,
    ).load();
    addTearDown(() {
      api.dio.httpClientAdapter = old;
      ServerUaeLocationRepository.loaded = null;
      AuthState().logout();
    });
  });
  Future<void> done(WidgetTester tester) async {
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  }

  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      final mode = '${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}';
      testWidgets('render affected patient interfaces $mode', (tester) async {
        tester.view.physicalSize = const Size(430, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        AuthState().login(
          name: 'Disposable QA',
          phone: 'fixture',
          role: 'patient',
        );
        final image = File(
          'test/fixtures/media/portrait_photo.png',
        ).absolute.uri.toString();
        final clinic = patientClinic(
          extra: {
            'cover_image': image,
            'logo': 'assets/images/aesthetic_way_logo.png',
            'gallery_images': [image],
            'video_url': 'https://fixture.invalid/public-showcase.mp4',
            'setup_status': 'approved',
            'subscription_tier': 'vip',
          },
        );
        await f.render(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: Scaffold(
                appBar: AppBar(title: Text(ar ? 'الرئيسية' : 'Home')),
                body: ListView(
                  children: [
                    FeaturedAdsCarousel(
                      ads: [
                        clinic,
                        patientClinic(extra: {'id': 'second-fixture'}),
                      ],
                      onClinicTap: (_) {},
                      onContactTap: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
          dark: dark,
          ar: ar,
        );
        await settlePreviewImages(tester);
        await f.capture(tester, 'featured_$mode');
        await f.render(
          tester,
          ClinicProfileScreen(
            clinic: clinic,
            clinicsRepository: FixtureClinicsRepository(clinic),
          ),
          dark: dark,
          ar: ar,
        );
        await settlePreviewImages(tester);
        await f.capture(tester, 'patient_profile_$mode');
        await tester.pumpWidget(const SizedBox());
        final loc = PatientLocationController(provider: LocationProvider());
        await loc.useDeviceLocation();
        final repo = NearbyFixture()
          ..reply = (q, p) async => NearbyClinicsPage([
            row('fixture', 2.4),
          ], reference: NearbyDistanceReference.device);
        await f.render(
          tester,
          NearbyClinicsScreen(location: loc, repository: repo),
          dark: dark,
          ar: ar,
        );
        await tester.pump(const Duration(milliseconds: 351));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.text(ar ? 'طلب استشارة' : 'Request consultation'),
        );
        await tester.pumpAndSettle();
        await f.capture(tester, 'nearby_gps_$mode');
        loc.selectCity('Dubai');
        repo.reply = (q, p) async => NearbyClinicsPage([
          NearbyClinic(clinic: row('fixture', 2.4).clinic, distanceKm: null),
        ], reference: NearbyDistanceReference.manualLocality);
        await tester.pump(const Duration(milliseconds: 351));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView).first, const Offset(0, 1500));
        await tester.pumpAndSettle();
        await f.capture(tester, 'nearby_manual_$mode');
        await tester.pumpWidget(const SizedBox());
        loc.dispose();
        await done(tester);
      });
      testWidgets('render affected clinic location/filter interfaces $mode', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(430, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        AuthState().login(
          name: 'Disposable QA',
          phone: 'fixture',
          role: 'clinic_admin',
        );
        await f.render(
          tester,
          Scaffold(
            body: UaeLocationPicker(
              selected: 'Dubai',
              selectedAreaCode: 'jumeirah',
              includeAreas: true,
              repository: ActualCatalog(currentUaeCatalog),
            ),
          ),
          dark: dark,
          ar: ar,
        );
        await f.capture(tester, 'locality_$mode');
        await f.render(
          tester,
          Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showClinicLocationSelector(
                  ctx,
                  city: 'Dubai',
                  addressAr: 'نص اختبار محفوظ',
                  addressEn: 'Saved QA address',
                  latitude: 25.2315,
                  longitude: 55.3242,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
          dark: dark,
          ar: ar,
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await f.capture(tester, 'clinic_location_$mode');
        await tester.pumpWidget(const SizedBox());
        await f.render(
          tester,
          GoogleBusinessScreen(repository: BusinessFixture()),
          dark: dark,
          ar: ar,
        );
        final search = find.byType(TextField);
        await tester.enterText(
          search,
          ar ? 'عيادة اختبار' : 'Disposable Clinic',
        );
        await tester.pump(const Duration(milliseconds: 351));
        await tester.pumpAndSettle();
        await f.capture(tester, 'google_business_$mode');
        await tester.tap(find.text('Disposable QA Clinic'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('QA-Selected-Place'));
        await tester.pumpAndSettle();
        await f.capture(tester, 'google_selected_$mode');
        await f.render(
          tester,
          Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => FilterBottomSheet.show(
                  context: ctx,
                  currentFilters: ClinicFilterOptions(selectedCity: 'Dubai'),
                  onApply: (_) {},
                ),
                child: const Text('Open'),
              ),
            ),
          ),
          dark: dark,
          ar: ar,
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await f.capture(tester, 'filters_$mode');
        await done(tester);
      });
    }
  }
}
