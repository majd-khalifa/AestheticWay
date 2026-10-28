import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/features/admin/models/admin_clinic_model.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_clinic_reviews_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_clinic_detail_sheet.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_media_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_media_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_profile_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_dashboard_screen.dart';
import 'package:aesthetic_way/features/treatments/presentation/category_requests_screen.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'onboarding_review_workflows_test.dart' as f;
import 'clinic_media_contract_test.dart' show Gallery, Profile;
import 'support/patient_visual_harness.dart';
import 'support/settle_preview_images.dart';
import 'package:dio/dio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  final api = ApiClient(), service = ClinicPortalService();
  late HttpClientAdapter original;
  final logo = File(
    'test/fixtures/media/packaging_fixture.png',
  ).absolute.uri.toString();
  final photo = File(
    'test/fixtures/media/fragrance_photo.jpg',
  ).absolute.uri.toString();
  Map<String, dynamic> row() => {
    ...f.clinic(),
    'name_en': 'Local Media QA Clinic',
    'name_ar': 'عيادة اختبار الوسائط',
    'status': 'active',
    'subscription_tier': 'vip',
    'logo': logo,
    'cover_image': photo,
    'video_ad_file': null,
    'description_en': 'Disposable visual fixture; no production clinic data.',
    'description_ar': 'بيانات عرض مؤقتة لا تتضمن معلومات عيادة فعلية.',
    'city': 'dubai',
    'practitioners_count': 0,
    'treatments_count': 0,
  };
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    AuthState().logout();
    service.resetTestingState();
    AdminPortalService().resetTestingState();
    original = api.dio.httpClientAdapter;
    api.updateBaseUrl('https://fixture.invalid/api/v1/');
    api.dio.httpClientAdapter = f.Adapter((o) {
      if (o.path == 'admin/clinics/${f.id}/' ||
          o.path == ApiConfig.clinicProfile) {
        return f.body(row());
      }
      if (o.path.contains('setup-checklist')) {
        return f.body({
          'clinic_id': f.id,
          'setup_status': 'submitted',
          'progress_percentage': 100,
          'is_ready_for_review': true,
          'items': [
            {
              'key': 'branding',
              'title_en': 'Logo and cover',
              'title_ar': 'الشعار والغلاف',
              'is_completed': true,
            },
            {
              'key': 'practitioners',
              'title_en': 'Practitioner',
              'title_ar': 'ممارس',
              'is_completed': true,
            },
          ],
        });
      }
      if (o.path.contains('category-requests')) {
        return f.body(
          f.page([
            {
              'id': f.proposalId,
              'name_en': 'Local taxonomy QA',
              'name_ar': 'تصنيف اختبار محلي',
              'status': 'pending',
            },
          ]),
        );
      }
      if (o.path.contains('dashboard')) {
        return f.body({
          'clinic_id': f.id,
          'clinic_name': 'Local Media QA Clinic',
        });
      }
      return f.body(f.page([]));
    });
  });
  tearDown(() async {
    api.dio.httpClientAdapter = original;
    api.updateBaseUrl(ApiConfig.defaultProductionBaseUrl);
    ApiConfig.resetBaseUrl();
    service.resetTestingState();
    AdminPortalService().resetTestingState();
    AuthState().logout();
    await TokenStorage().clear();
  });
  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      for (final screen in [
        'review',
        'details',
        'media',
        'dashboard',
        'profile',
        'categories',
      ]) {
        testWidgets('portal media comparison $screen dark=$dark ar=$ar', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(430, 1000);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final clinicRole = ['media', 'dashboard', 'profile'].contains(screen);
          AuthState().login(
            name: 'Local QA',
            phone: 'disposable',
            role: clinicRole ? 'clinic_admin' : 'super_admin',
          );
          final model = ClinicModel.fromJson(row());
          service.setActiveClinicForTesting(model);
          final gallery = Gallery()
            ..saved.addAll([
              ClinicGalleryAsset(id: f.proposalId, clinicId: f.id, url: photo),
              ClinicGalleryAsset(id: f.id, clinicId: f.id, url: logo),
            ]);
          if (screen == 'media') {
            service.setCatalogRepositoryForTesting(Profile()..current = model);
          }
          final Widget view = switch (screen) {
            'review' => const AdminClinicReviewDetail(clinicId: f.id),
            'details' => Scaffold(
              body: AdminClinicDetailSheet(
                clinic: AdminClinicModel.fromJson(row()),
              ),
            ),
            'media' => ClinicMediaScreen(repository: gallery),
            'dashboard' => ClinicDashboardScreen(
              onNavigateToLeads: () {},
              onNavigateToOffers: () {},
            ),
            'profile' => const ClinicProfileScreen(),
            _ => const CategoryRequestsScreen(admin: true),
          };
          await f.render(tester, view, dark: dark, ar: ar);
          await settlePreviewImages(tester);
          await f.capture(
            tester,
            'polish_${screen}_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          if (screen == 'media') {
            final choose = find.text(
              ar ? 'اختيار فيديو من المعرض' : 'Select gallery video',
            );
            await tester.scrollUntilVisible(choose, 200);
            await tester.pumpAndSettle();
            await tester.ensureVisible(choose);
            await tester.pumpAndSettle();
            await settlePreviewImages(tester);
            await f.capture(
              tester,
              'polish_video_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
            );
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          await tester.binding.setSurfaceSize(null);
        });
      }
    }
  }
}
