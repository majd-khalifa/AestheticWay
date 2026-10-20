import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/theme/app_theme.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_offers_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_practitioners_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_treatments_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_dashboard_screen.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/treatments/models/category_model.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';

void main() {
  setUp(() {
    LocaleService().setLanguage(AppLanguage.arabic);
    ClinicPortalService().resetTestingState();
    ClinicPortalService().enableMockMode();
  });

  group('Clinic Catalog Models & Serialization Tests', () {
    test('CategoryModel parses backend JSON correctly', () {
      final json = {
        'id': 'cat-123',
        'name_en': 'Injectables & Fillers',
        'name_ar': 'الحقن والفيلر',
        'slug': 'injectables',
        'icon': 'https://example.com/icon.png',
        'display_order': 1,
      };

      final cat = CategoryModel.fromJson(json);
      expect(cat.id, 'cat-123');
      expect(cat.nameEn, 'Injectables & Fillers');
      expect(cat.nameAr, 'الحقن والفيلر');
      expect(cat.slug, 'injectables');
      expect(cat.icon, 'https://example.com/icon.png');
      expect(cat.displayOrder, 1);

      final outJson = cat.toJson();
      expect(outJson['name_en'], 'Injectables & Fillers');
    });

    test(
      'PractitionerModel converts to Portal JSON and copies with modifications',
      () {
        const practitioner = PractitionerModel(
          id: 'p-100',
          nameAr: 'د. ليلى النعيمي',
          nameEn: 'Dr. Layla Al Nuaimi',
          type: PractitionerType.doctor,
          specialtyAr: 'جلدية وتجميل',
          specialtyEn: 'Dermatology',
          classificationAr: 'استشارية جلدية',
          classificationEn: 'Consultant Dermatologist',
          licenseAuthority: 'DHA',
          licenseNumber: 'DHA-P-998877',
          avatarUrl: 'https://example.com/avatar.jpg',
          yearsOfExperience: 10,
          rating: 4.9,
          reviewCount: 25,
          languages: ['العربية', 'English'],
          clinicId: 'clinic-1',
          clinicNameAr: 'عيادة دبي',
          procedures: ['فيلر', 'بوتوكس'],
          aboutAr: 'خبرة واسعة في التجميل',
          aboutEn: 'Experienced in aesthetic medicine',
          status: 'active',
        );

        final portalJson = practitioner.toPortalJson();
        expect(portalJson['name_en'], 'Dr. Layla Al Nuaimi');
        expect(portalJson['name_ar'], 'د. ليلى النعيمي');
        expect(portalJson['type'], 'doctor');
        expect(portalJson.containsKey('license_authority'), isFalse);
        expect(portalJson.containsKey('license_number'), isFalse);
        expect(portalJson['status'], 'active');

        // Strict backend alignment: mock-only fields MUST NOT be sent
        expect(portalJson.containsKey('years_of_experience'), isFalse);
        expect(portalJson.containsKey('languages'), isFalse);
        expect(portalJson.containsKey('procedures'), isFalse);
        expect(portalJson.containsKey('rating'), isFalse);
        expect(portalJson.containsKey('review_count'), isFalse);

        final updated = practitioner.copyWith(
          status: 'inactive',
          specialtyEn: 'Laser Specialist',
        );
        expect(updated.status, 'inactive');
        expect(updated.specialtyEn, 'Laser Specialist');
        expect(updated.nameEn, practitioner.nameEn);
      },
    );

    test(
      'TreatmentModel converts to Portal JSON and handles categories and practitioners',
      () {
        const treatment = TreatmentModel(
          id: 't-200',
          nameAr: 'هايدرافاشيال علاجي',
          nameEn: 'Medical HydraFacial',
          categoryAr: 'علاجات البشرة',
          categoryEn: 'Skin Care',
          categoryId: 'cat-456',
          descriptionAr: 'تنظيف عميق 7 مراحل',
          descriptionEn: '7-step deep cleansing',
          durationText: '45 دقيقة',
          downtimeText: 'بدون نقاهة',
          targetAreaAr: 'الوجه',
          clinicsCount: 1,
          imageUrl: 'https://example.com/facial.jpg',
          price: 850.0,
          status: 'active',
          isActive: true,
          practitionerIds: ['p-100', 'p-101'],
        );

        final portalJson = treatment.toPortalJson();
        expect(portalJson['category'], 'cat-456');
        expect(portalJson['name_en'], 'Medical HydraFacial');
        expect(portalJson['price'], 850.0);
        expect(portalJson['practitioners'], contains('p-100'));
        expect(portalJson['status'], 'active');
        expect(portalJson['is_active'], isTrue);

        // Strict backend alignment: mock-only fields MUST NOT be sent
        expect(portalJson.containsKey('duration_text'), isFalse);
        expect(portalJson.containsKey('downtime_text'), isFalse);
        expect(portalJson.containsKey('target_area'), isFalse);
        expect(portalJson.containsKey('clinics_count'), isFalse);

        final updated = treatment.copyWith(price: 900.0, status: 'inactive');
        expect(updated.price, 900.0);
        expect(updated.status, 'inactive');
      },
    );

    test(
      'OfferModel converts to Portal JSON with mandatory starts_at and ends_at',
      () {
        final now = DateTime.now();
        final ends = now.add(const Duration(days: 30));

        final offer = OfferModel(
          id: 'off-300',
          titleAr: 'عرض البوتوكس الصيفي',
          titleEn: 'Summer Botox Offer',
          clinicId: 'clinic-1',
          clinicNameAr: 'عيادة دبي',
          originalPrice: 1500.0,
          offerPrice: 999.0,
          discountPercentage: 33,
          validUntilText: 'ساري حتى نهاية الشهر',
          daysRemaining: 30,
          termsAr: 'شامل الفحص الطبي',
          termsEn: 'Includes medical exam',
          imageUrl: 'https://example.com/offer.jpg',
          status: 'active',
          isActive: true,
          startsAt: now,
          endsAt: ends,
        );

        final portalJson = offer.toPortalJson();
        expect(portalJson['title_en'], 'Summer Botox Offer');
        expect(portalJson['original_price'], 1500.0);
        expect(portalJson['offer_price'], 999.0);
        expect(portalJson['starts_at'], isNotNull);
        expect(portalJson['ends_at'], isNotNull);
        expect(portalJson['status'], 'active');
        expect(portalJson['is_active'], isTrue);

        // Strict backend alignment: computed UI fields MUST NOT be sent
        expect(portalJson.containsKey('discount_percentage'), isFalse);
        expect(portalJson.containsKey('valid_until_text'), isFalse);
        expect(portalJson.containsKey('days_remaining'), isFalse);

        final suspended = offer.copyWith(status: 'suspended', isActive: false);
        expect(suspended.status, 'suspended');
        expect(suspended.isActive, isFalse);
      },
    );
  });

  group('Clinic Portal Service Catalog CRUD Tests', () {
    test(
      'Service creates, updates, and deletes practitioners correctly',
      () async {
        final service = ClinicPortalService();
        final initialCount = service.clinicPractitioners.length;

        final newP = await service.createPractitioner({
          'id': 'test-doc-1',
          'name_en': 'Dr. Sara Al Ali',
          'name_ar': 'د. سارة العلي',
          'speciality_en': 'Aesthetic Doctor',
          'speciality_ar': 'طبيبة تجميل',
          'type': 'doctor',
          'status': 'active',
        });

        expect(service.clinicPractitioners.length, initialCount + 1);
        expect(newP.nameEn, 'Dr. Sara Al Ali');

        await service.updatePractitioner('test-doc-1', {
          'name_en': 'Dr. Sara Al Ali (Senior)',
          'name_ar': 'د. سارة العلي (استشارية)',
          'speciality_en': 'Consultant Aesthetician',
          'speciality_ar': 'استشارية تجميل',
          'status': 'active',
        });

        final updated = service.clinicPractitioners.firstWhere(
          (p) => p.id == 'test-doc-1',
        );
        expect(updated.nameEn, 'Dr. Sara Al Ali (Senior)');

        await service.deletePractitioner('test-doc-1');
        expect(service.clinicPractitioners.length, initialCount);
      },
    );

    test(
      'Service creates, updates, and deletes treatments correctly',
      () async {
        final service = ClinicPortalService();
        final initialCount = service.clinicTreatments.length;

        final newT = await service.createTreatment({
          'id': 'test-treat-1',
          'name_en': 'Laser Carbon Peel',
          'name_ar': 'تقشير كربوني بالليزر',
          'category_en': 'Skin Care',
          'category_ar': 'عناية بالبشرة',
          'price': 550.0,
          'status': 'active',
          'is_active': true,
        });

        expect(service.clinicTreatments.length, initialCount + 1);
        expect(newT.nameEn, 'Laser Carbon Peel');

        await service.updateTreatment('test-treat-1', {
          'name_en': 'Hollywood Carbon Peel',
          'name_ar': 'تقشير هوليوود الكربوني',
          'price': 650.0,
          'status': 'active',
          'is_active': true,
        });

        final updated = service.clinicTreatments.firstWhere(
          (t) => t.id == 'test-treat-1',
        );
        expect(updated.nameEn, 'Hollywood Carbon Peel');
        expect(updated.price, 650.0);

        await service.deleteTreatment('test-treat-1');
        expect(service.clinicTreatments.length, initialCount);
      },
    );

    test(
      'Service creates, toggles status, and deletes offers correctly',
      () async {
        final service = ClinicPortalService();
        final initialCount = service.clinicOffers.length;

        final newO = await service.createOffer({
          'id': 'test-offer-1',
          'title_en': 'Special Glow Package',
          'title_ar': 'باقة النضارة الخاصة',
          'original_price': 1200.0,
          'offer_price': 800.0,
          'starts_at': DateTime.now().toIso8601String(),
          'ends_at': DateTime.now()
              .add(const Duration(days: 15))
              .toIso8601String(),
          'status': 'active',
          'is_active': true,
        });

        expect(service.clinicOffers.length, initialCount + 1);
        expect(newO.titleEn, 'Special Glow Package');

        // Toggle status to suspended
        await service.toggleOfferStatus('test-offer-1');
        final suspended = service.clinicOffers.firstWhere(
          (o) => o.id == 'test-offer-1',
        );
        expect(suspended.status, 'suspended');
        expect(suspended.isActive, isFalse);

        // Toggle back to active
        await service.toggleOfferStatus('test-offer-1');
        final reactivated = service.clinicOffers.firstWhere(
          (o) => o.id == 'test-offer-1',
        );
        expect(reactivated.status, 'active');
        expect(reactivated.isActive, isTrue);

        await service.deleteOffer('test-offer-1');
        expect(service.clinicOffers.length, initialCount);
      },
    );
  });

  group('Clinic Portal Catalog UI Widget Tests', () {
    testWidgets(
      'ClinicOffersScreen renders active offers, status toggle, and add button',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ClinicOffersScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ClinicOffersScreen), findsOneWidget);
        expect(find.byIcon(Icons.add_circle_outline_rounded), findsWidgets);
        expect(find.text('العروض'), findsOneWidget);
      },
    );

    testWidgets(
      'ClinicPractitionersScreen renders staff list and search input',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ClinicPractitionersScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ClinicPractitionersScreen), findsOneWidget);
        expect(find.text('إدارة الكادر الطبي'), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byIcon(Icons.person_add_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'ClinicTreatmentsScreen renders services and category filters',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ClinicTreatmentsScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ClinicTreatmentsScreen), findsOneWidget);
        expect(find.text('إدارة الخدمات والعلاجات'), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
      },
    );

    testWidgets(
      'ClinicDashboardScreen displays Catalog Management Overview cards',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: ClinicDashboardScreen(
              onNavigateToLeads: () {},
              onNavigateToOffers: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('إدارة الكتالوج والمحتوى'), findsOneWidget);
        expect(find.text('الأطباء'), findsOneWidget);
        expect(find.text('العلاجات'), findsOneWidget);
        expect(find.text('باقات العروض'), findsOneWidget);
        expect(find.text('المنتجات الطبية'), findsOneWidget);
        expect(find.text('المقالات والأدلة'), findsOneWidget);
      },
    );
  });
}
