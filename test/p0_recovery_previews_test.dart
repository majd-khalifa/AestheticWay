import 'package:aesthetic_way/core/services/media_operation_trace.dart';
// Identical harness runs on bb9a676 and the updated branch. Fixture-only
// rendering is not physical device, GPS, provider, or R2 verification.
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/widgets/luxury_image_picker_field.dart';
import 'package:aesthetic_way/features/home/presentation/screens/home_screen.dart';
import 'package:aesthetic_way/features/home/presentation/widgets/featured_ads_carousel.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinic_profile_screen.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_media_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_media_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_practitioners_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/widgets/clinic_location_selector.dart';
import 'package:aesthetic_way/features/locations/data/uae_location_repository.dart';
import 'package:aesthetic_way/features/locations/presentation/nearby_clinics_screen.dart';
import 'package:aesthetic_way/features/locations/services/patient_location_controller.dart';
import 'package:aesthetic_way/features/locations/data/nearby_clinics_repository.dart';
import 'onboarding_review_workflows_test.dart' as f;
import 'clinic_media_contract_test.dart' as g;
import 'backend_401560b_integration_test.dart' as source;
import 'nearby_locality_readiness_test.dart' show NearbyFixture, row;
import 'uae_location_qa_test.dart' show LocationProvider;
import 'support/patient_fixtures.dart';
import 'support/patient_visual_harness.dart';
import 'support/recovery_preview_fixtures.dart';
import 'support/offline_map_test_cache.dart';
import 'support/settle_preview_images.dart';

class PreviewGallery extends ClinicMediaRepository {
  final photo = File(
    'test/fixtures/media/portrait_photo.png',
  ).absolute.uri.toString();
  @override
  Future<List<ClinicGalleryAsset>> getGallery(
    String clinicId, {
    int page = 1,
  }) async => [
    ClinicGalleryAsset(id: g.assetId, clinicId: g.clinicId, url: photo),
  ];
  @override
  Future<ClinicGalleryAsset> uploadGallery(
    String clinicId,
    String path, {
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
    MediaOperationTrace? trace,
  }) async => throw ApiException.fromDioError(
    DioException(
      requestOptions: RequestOptions(),
      response: Response(
        requestOptions: RequestOptions(),
        statusCode: 400,
        data: {
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': 'One or more fields failed validation.',
            'fields': {
              'file': [
                'The uploaded file is not a valid image or is corrupted.',
              ],
            },
          },
        },
      ),
    ),
  );
}

Future<void> jump(
  WidgetTester t,
  Finder scroll,
  double delta, {
  Finder? until,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await t.pump();
  final p = t.state<ScrollableState>(scroll).position;
  for (var i = 0; i < 20; i++) {
    if (until != null && until.evaluate().isNotEmpty) {
      await t.ensureVisible(until);
      break;
    }
    p.jumpTo(
      (delta >= 10000
              ? p.maxScrollExtent
              : delta <= -10000
              ? 0
              : p.pixels + delta)
          .clamp(0.0, p.maxScrollExtent)
          .toDouble(),
    );
    await t.pump();
    if (until == null && i > 3) break;
  }
  await t.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  late ApiClient api;
  late HttpClientAdapter old;
  late ImagePickerPlatform oldPicker;
  late GeolocatorPlatform oldGps;
  setUp(() async {
    final cache = OfflineMapTestCache();
    addTearDown(cache.close);
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    api = ApiClient();
    old = api.dio.httpClientAdapter;
    oldPicker = ImagePickerPlatform.instance;
    oldGps = GeolocatorPlatform.instance;
    GeolocatorPlatform.instance = ForegroundGps();
    api.dio.httpClientAdapter = f.Adapter(
      (r) => f.body(source.catalog[r.path.split('/')[1]] ?? f.page([])),
    );
    ServerUaeLocationRepository.loaded = await ServerUaeLocationRepository(
      api: api,
    ).load();
  });
  tearDown(() {
    api.dio.httpClientAdapter = old;
    ImagePickerPlatform.instance = oldPicker;
    GeolocatorPlatform.instance = oldGps;
    ServerUaeLocationRepository.loaded = null;
    ClinicPortalService().resetTestingState();
    AuthState().logout();
  });
  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      final mode = '${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}';
      testWidgets('P0 actual rendered comparisons $mode', (t) async {
        t.view.physicalSize = const Size(430, 1000);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        AuthState().login(
          name: 'Disposable QA',
          phone: 'fixture',
          role: 'patient',
        );
        api.dio.httpClientAdapter = f.Adapter((r) => f.body(homeGpsReply(r)));
        final photo = File(
          'test/fixtures/media/portrait_photo.png',
        ).absolute.uri.toString();
        final clinic = patientClinic(
          extra: {
            'cover_image': photo,
            'gallery_images': [photo],
            'video_url': 'https://fixture.invalid/public.mp4',
            'setup_status': 'approved',
            'subscription_tier': 'vip',
          },
        );
        await f.render(
          t,
          Builder(
            builder: (ctx) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(disableAnimations: true),
              child: Scaffold(
                body: ListView(
                  children: [
                    FeaturedAdsCarousel(
                      ads: [clinic],
                      onClinicTap: (_) {},
                      onContactTap: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
          ar: ar,
          dark: dark,
        );
        await settlePreviewImages(t);
        await f.capture(t, 'featured_controls_$mode');
        await f.render(
          t,
          ClinicProfileScreen(
            clinic: clinic,
            clinicsRepository: FixtureClinicsRepository(clinic),
          ),
          ar: ar,
          dark: dark,
        );
        await settlePreviewImages(t);
        await f.capture(t, 'profile_controls_$mode');
        await f.render(t, const HomeScreen(), ar: ar, dark: dark);
        var scroll = find
            .descendant(
              of: find.byType(CustomScrollView).first,
              matching: find.byType(Scrollable),
            )
            .first;
        await jump(
          t,
          scroll,
          200,
          until: find.byKey(const ValueKey('home-use-location')),
        );
        await t.tap(find.byKey(const ValueKey('home-use-location')));
        await t.pumpAndSettle();
        await t.pump(const Duration(milliseconds: 351));
        await t.pumpAndSettle();
        await jump(
          t,
          scroll,
          200,
          until: find
              .text(ar ? 'عيادة اختبار الموقع' : 'Disposable GPS clinic')
              .last,
        );
        await f.capture(t, 'home_gps_$mode');
        await t.pumpWidget(const SizedBox());
        final loc = PatientLocationController(provider: LocationProvider());
        await loc.useDeviceLocation();
        final nearby = NearbyFixture()
          ..reply = (q, p) async => NearbyClinicsPage([
            row('fixture', 2.4),
          ], reference: NearbyDistanceReference.device);
        await f.render(
          t,
          NearbyClinicsScreen(location: loc, repository: nearby),
          ar: ar,
          dark: dark,
        );
        await t.pump(const Duration(milliseconds: 351));
        await t.pumpAndSettle();
        await t.ensureVisible(
          find.text(ar ? 'طلب استشارة' : 'Request consultation'),
        );
        await t.pumpAndSettle();
        await f.capture(t, 'nearby_distance_$mode');
        await t.pumpWidget(const SizedBox());
        loc.dispose();
        AuthState().login(
          name: 'Disposable QA',
          phone: 'fixture',
          role: 'clinic_admin',
        );
        final saved = <Map<String, dynamic>>[];
        api.dio.httpClientAdapter = f.Adapter((r) {
          if (r.path == 'clinic-portal/profile/') {
            return f.body({...f.clinic(), 'id': g.clinicId, 'city': 'Dubai'});
          }
          if (r.method == 'POST') {
            final data = Map<String, dynamic>.from(r.data as Map);
            if ('${data['title_en']}'.length > 100) {
              return f.body({
                'title_en': [
                  'Ensure this field has no more than 100 characters.',
                ],
              }, 400);
            }
            final d = {'id': f.proposalId, ...data};
            saved.add(d);
            return f.body(d, 201);
          }
          return f.body(f.page(saved));
        });
        final service = ClinicPortalService()..resetTestingState();
        service.setCatalogRepositoryForTesting(
          ClinicCatalogRepository(apiClient: api),
        );
        service.setActiveClinicForTesting(
          ClinicModel.fromJson({
            ...f.clinic(),
            'id': g.clinicId,
            'city': 'Dubai',
          }),
        );
        await f.render(
          t,
          const ClinicPractitionersScreen(),
          ar: ar,
          dark: dark,
        );
        await t.tap(find.text(ar ? 'إضافة ممارس' : 'Add Practitioner').first);
        await t.pumpAndSettle();
        scroll = find
            .descendant(
              of: find.byType(Form),
              matching: find.byType(Scrollable),
            )
            .first;
        await t.tap(
          find.byWidgetPredicate((w) => w is DropdownButtonFormField).first,
        );
        await t.pumpAndSettle();
        await t.tap(find.text(ar ? 'ممرض' : 'Nurse').last);
        await t.pumpAndSettle();
        for (final entry in [
          (
            ar ? 'الاسم الكامل بالإنجليزية' : 'Full Name (English)',
            'Disposable nurse',
          ),
          (ar ? 'الاسم الكامل بالعربية' : 'Full Name (Arabic', 'ممرض اختبار'),
          (ar ? 'التخصص بالإنجليزية' : 'Specialty (English)', 'x' * 120),
        ]) {
          final field = find.byWidgetPredicate(
            (w) =>
                w is TextField &&
                (w.decoration?.labelText?.startsWith(entry.$1) ?? false),
          );
          await jump(t, scroll, 180, until: field);
          expect(field, findsOneWidget, reason: entry.$1);
          await t.enterText(field, entry.$2);
        }
        await jump(t, scroll, 10000);
        await t.tap(find.text(ar ? 'إضافة الممارس' : 'Save Practitioner'));
        await t.pumpAndSettle();
        if (find.byType(Form).evaluate().isNotEmpty) {
          await jump(t, scroll, -10000);
        }
        await f.capture(t, 'practitioner_result_$mode');
        await t.pumpWidget(const SizedBox());
        final picker = g.Picker()..files = [XFile(g.fixture.path)];
        ImagePickerPlatform.instance = picker;
        await f.render(
          t,
          ClinicMediaScreen(repository: PreviewGallery()),
          ar: ar,
          dark: dark,
        );
        scroll = find
            .descendant(
              of: find.byType(ClinicMediaScreen),
              matching: find.byType(Scrollable),
            )
            .first;
        await jump(
          t,
          scroll,
          250,
          until: find.byType(LuxuryImagePickerField).first,
        );
        await t.tap(find.byType(LuxuryImagePickerField).first);
        await t.pumpAndSettle();
        await t.tap(
          find.text(ar ? 'اختيار من معرض الصور' : 'Choose from Gallery'),
        );
        await t.pumpAndSettle();
        await jump(
          t,
          scroll,
          250,
          until: find.text(ar ? 'رفع الصور المحددة' : 'Upload selected photos'),
        );
        await t.tap(
          find.text(ar ? 'رفع الصور المحددة' : 'Upload selected photos'),
        );
        await t.pumpAndSettle();
        await jump(t, scroll, -10000);
        await settlePreviewImages(t);
        await f.capture(t, 'gallery_failure_$mode');
        await t.pumpWidget(const SizedBox());
        await f.render(
          t,
          Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showClinicLocationSelector(
                  ctx,
                  city: 'Dubai',
                  addressAr: '',
                  addressEn: 'Sharjah',
                  latitude: 25.3463,
                  longitude: 55.4209,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
          ar: ar,
          dark: dark,
        );
        await t.tap(find.text('Open'));
        await t.pumpAndSettle();
        await f.capture(t, 'location_conflict_$mode');
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await t.binding.setSurfaceSize(null);
      });
    }
  }
}
