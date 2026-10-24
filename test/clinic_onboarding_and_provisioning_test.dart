import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/clinic_portal/data/models/clinic_setup_checklist_model.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/widgets/clinic_setup_checklist_card.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_dashboard_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_clinics_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_clinic_detail_sheet.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_create_clinic_dialog.dart';
import 'package:aesthetic_way/features/admin/models/admin_clinic_model.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Clinic Provisioning & Onboarding API Config & Model Tests', () {
    test('ApiConfig contains new onboarding and branch endpoints', () {
      expect(ApiConfig.clinicBranches, equals('clinic-portal/branches/'));
      expect(
        ApiConfig.clinicBranchDetail('branch-123'),
        equals('clinic-portal/branches/branch-123/'),
      );
      expect(
        ApiConfig.clinicSetupChecklist,
        equals('clinic-portal/profile/setup-checklist/'),
      );
      expect(
        ApiConfig.clinicSubmitForReview,
        equals('clinic-portal/profile/submit-for-review/'),
      );
      expect(
        ApiConfig.adminClinicResetPassword('clinic-456'),
        equals('admin/clinics/clinic-456/reset-admin-password/'),
      );
    });

    test('ClinicBranch model parses and serializes correctly', () {
      final json = {
        'id': 'branch-uuid-1',
        'name_en': 'Downtown Dubai Branch',
        'name_ar': 'فرع وسط مدينة دبي',
        'city': 'Dubai',
        'address_en': 'Boulevard Plaza Tower 1',
        'address_ar': 'برج بوليفارد بلازا 1',
        'phone': '+97143990011',
        'latitude': 25.1972,
        'longitude': 55.2744,
        'google_place_id': 'ChIJ12345Place',
        'google_maps_url': 'https://maps.google.com/?q=25.1972,55.2744',
        'is_main_branch': true,
        'is_active': true,
      };

      final branch = ClinicBranch.fromJson(json);
      expect(branch.id, equals('branch-uuid-1'));
      expect(branch.nameEn, equals('Downtown Dubai Branch'));
      expect(branch.nameAr, equals('فرع وسط مدينة دبي'));
      expect(branch.city, equals('Dubai'));
      expect(branch.isMainBranch, isTrue);
      expect(branch.isActive, isTrue);
      expect(branch.latitude, closeTo(25.1972, 0.0001));

      final outputJson = branch.toJson();
      expect(outputJson['name_en'], equals('Downtown Dubai Branch'));
      expect(outputJson['is_main_branch'], isTrue);
      expect(outputJson['google_place_id'], equals('ChIJ12345Place'));
    });

    test('ClinicSetupChecklistModel parses readiness and items accurately', () {
      final json = {
        'clinic_id': 'clinic-test-99',
        'setup_status': 'draft',
        'progress_percentage': 80,
        'is_ready_for_review': false,
        'items': [
          {
            'key': 'branding',
            'title_en': 'Clinic Branding (Logo & Cover)',
            'title_ar': 'الهوية البصرية',
            'is_completed': true,
            'route': '/clinic/profile',
          },
          {
            'key': 'practitioners',
            'title_en': 'At Least One Practitioner',
            'title_ar': 'طبيب واحد على الأقل',
            'is_completed': false,
            'route': '/clinic/practitioners',
          },
        ],
      };

      final model = ClinicSetupChecklistModel.fromJson(json);
      expect(model.clinicId, equals('clinic-test-99'));
      expect(model.setupStatus, equals('draft'));
      expect(model.progressPercentage, equals(80));
      expect(model.isReadyForReview, isFalse);
      expect(model.items.length, equals(2));
      expect(model.items[0].key, equals('branding'));
      expect(model.items[0].isCompleted, isTrue);
      expect(model.items[1].key, equals('practitioners'));
      expect(model.items[1].isCompleted, isFalse);
    });

    test(
      'ClinicModel setupStatus defaults to approved and reflects server response',
      () {
        const defaultClinic = ClinicModel(
          id: 'c1',
          nameAr: 'عيادة',
          nameEn: 'Clinic',
          descriptionAr: '',
          descriptionEn: '',
          coverImageUrl: '',
          galleryImages: [],
          logoUrl: '',
          rating: 5.0,
          reviewCount: 0,
          subscriptionTier: SubscriptionTier.basic,
          city: 'Dubai',
          areaAr: 'دبي',
          addressAr: 'دبي',
        );
        expect(defaultClinic.setupStatus, equals('approved'));

        final draftClinic = ClinicModel.fromJson({
          'id': 'c2',
          'name_en': 'Draft Clinic',
          'name_ar': 'عيادة مسودة',
          'city': 'Abu Dhabi',
          'setup_status': 'draft',
        });
        expect(draftClinic.setupStatus, equals('draft'));
      },
    );
  });

  group('Super Admin Provisioning UI Widget Tests', () {
    testWidgets(
      'AdminClinicsScreen renders Add Clinic Floating Action Button',
      (tester) async {
        AdminPortalService().enableMockMode();

        await tester.pumpWidget(const MaterialApp(home: AdminClinicsScreen()));
        await tester.pumpAndSettle();

        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);
        expect(find.byIcon(Icons.add_business_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'AdminCreateClinicDialog renders clinic & admin inputs with auto-generate password',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: AdminCreateClinicDialog())),
        );
        await tester.pumpAndSettle();

        expect(find.text('Clinic identity'), findsOneWidget);
        expect(find.text('Initial Administrator Credentials'), findsOneWidget);
        expect(
          find.byIcon(Icons.refresh_rounded),
          findsOneWidget,
        ); // Auto-generate password button

        // Tap Auto-Generate password button
        await tester.tap(find.byIcon(Icons.refresh_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Provision Clinic & Administrator'), findsOneWidget);
      },
    );

    testWidgets('AdminClinicDetailSheet renders Reset Admin Password button', (
      tester,
    ) async {
      AdminPortalService().enableMockMode();

      const testClinic = AdminClinicModel(
        id: 'clinic-adm-01',
        nameEn: 'Test Aesthetic Clinic',
        nameAr: 'عيادة تجريبية',
        city: 'Dubai',
        status: 'active',
        subscriptionTier: SubscriptionTier.vipPlatinum,
        isActive: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AdminClinicDetailSheet(clinic: testClinic)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset Admin Password'), findsOneWidget);
      expect(find.byIcon(Icons.lock_reset_rounded), findsOneWidget);
    });
  });

  group('Clinic Portal Onboarding & Setup Checklist Widget Tests', () {
    testWidgets(
      'ClinicSetupChecklistCard displays items and calculates progress',
      (tester) async {
        final checklist = ClinicSetupChecklistModel(
          clinicId: 'clinic-active',
          setupStatus: 'draft',
          progressPercentage: 60,
          isReadyForReview: false,
          items: const [
            ClinicSetupChecklistItem(
              key: 'branding',
              titleEn: 'Clinic Branding (Logo & Cover)',
              titleAr: 'الهوية البصرية',
              isCompleted: true,
            ),
            ClinicSetupChecklistItem(
              key: 'branch',
              titleEn: 'Main Branch Location & Map',
              titleAr: 'الفرع الرئيسي',
              isCompleted: true,
            ),
            ClinicSetupChecklistItem(
              key: 'practitioners',
              titleEn: 'At Least One Practitioner',
              titleAr: 'طبيب واحد على الأقل',
              isCompleted: false,
            ),
            ClinicSetupChecklistItem(
              key: 'treatments',
              titleEn: 'At least 1 Treatment Service',
              titleAr: 'خدمة واحدة على الأقل',
              isCompleted: false,
            ),
          ],
        );

        const clinic = ClinicModel(
          id: 'clinic-active',
          nameAr: 'عيادة تجريبية',
          nameEn: 'Test Clinic',
          descriptionAr: '',
          descriptionEn: '',
          coverImageUrl: '',
          galleryImages: [],
          logoUrl: '',
          rating: 5.0,
          reviewCount: 0,
          subscriptionTier: SubscriptionTier.basic,
          city: 'Dubai',
          areaAr: 'دبي',
          addressAr: 'دبي',
          setupStatus: 'draft',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ClinicSetupChecklistCard(
                clinic: clinic,
                checklist: checklist,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Clinic Profile Setup'), findsOneWidget);
        expect(find.text('60%'), findsOneWidget);
        expect(find.text('Clinic Branding (Logo & Cover)'), findsOneWidget);
        expect(find.text('At Least One Practitioner'), findsOneWidget);
        expect(find.text('Submit Clinic Profile for Review'), findsOneWidget);
      },
    );

    testWidgets(
      'ClinicDashboardScreen displays ClinicSetupChecklistCard when setupStatus is draft',
      (tester) async {
        const draftClinic = ClinicModel(
          id: 'clinic-draft-01',
          nameAr: 'عيادة جديدة',
          nameEn: 'New Partner Clinic',
          descriptionAr: '',
          descriptionEn: '',
          coverImageUrl: '',
          galleryImages: [],
          logoUrl: '',
          rating: 5.0,
          reviewCount: 0,
          subscriptionTier: SubscriptionTier.basic,
          city: 'Dubai',
          areaAr: 'دبي',
          addressAr: 'دبي',
          setupStatus: 'draft',
        );
        ClinicPortalService().enableMockMode(testClinic: draftClinic);

        await tester.pumpWidget(
          MaterialApp(
            home: ClinicDashboardScreen(
              onNavigateToLeads: () {},
              onNavigateToOffers: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // In draft mode, ClinicSetupChecklistCard is present
        expect(find.byType(ClinicSetupChecklistCard), findsOneWidget);
      },
    );
  });
}
