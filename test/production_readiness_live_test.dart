import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_settings_screen.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/referral/data/referral_repository.dart';
import 'package:aesthetic_way/features/referral/models/referral_model.dart';
import 'package:aesthetic_way/features/referral/services/referral_service.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';

class _FakeReferralRepository implements ReferralRepository {
  String? lastVerifiedCode;
  String? lastRedeemedCode;

  @override
  Future<Map<String, dynamic>> verifyClinicDiscountCode(String code) async {
    lastVerifiedCode = code;
    return {
      'is_valid': true,
      'status': 'available',
      'code': code,
      'patient_name': 'دانة المزروعي',
      'expires_at': '2026-12-31T00:00:00Z',
    };
  }

  @override
  Future<Map<String, dynamic>> redeemClinicDiscountCode(String code) async {
    lastRedeemedCode = code;
    return {
      'success': true,
      'code': code,
      'redeemed_clinic': 'عيادة الأناقة الطبية',
    };
  }

  @override
  Future<PatientReferralStatusModel> getMyReferralStatus() async {
    throw UnimplementedError();
  }

  @override
  Future<CollectCodeResult> collectDiscountCode() async {
    throw UnimplementedError();
  }
}

class _FakeClinicCatalogRepository implements ClinicCatalogRepository {
  Map<String, dynamic>? lastUpdatedProfilePayload;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<ClinicModel> getClinicProfile() async {
    return const ClinicModel(
      id: 'clinic-live-1',
      nameAr: 'عيادة النخبة التخصصية',
      nameEn: 'Elite Specialty Clinic',
      descriptionAr: 'عيادة جلدية وتجميل رائدة',
      descriptionEn: 'Leading dermatology clinic',
      coverImageUrl: '',
      galleryImages: [],
      logoUrl: '',
      rating: 4.9,
      reviewCount: 42,
      subscriptionTier: SubscriptionTier.vipPlatinum,
      city: 'Dubai',
      areaAr: 'جميرا',
      areaEn: 'Jumeirah',
      addressAr: 'شارع جميرا، دبي',
      addressEn: 'Jumeirah Beach Rd, Dubai',
      mainPhone: '+971501112233',
      whatsapp: '+971501112233',
      googleMapsUrl: 'https://maps.google.com/?q=Elite+Clinic',
    );
  }

  @override
  Future<ClinicModel> updateClinicProfile(Map<String, dynamic> data) async {
    lastUpdatedProfilePayload = data;
    return ClinicModel(
      id: 'clinic-live-1',
      nameAr: data['name_ar']?.toString() ?? '',
      nameEn: data['name_en']?.toString() ?? '',
      descriptionAr: data['description_ar']?.toString() ?? '',
      descriptionEn: data['description_en']?.toString() ?? '',
      coverImageUrl: '',
      galleryImages: const [],
      logoUrl: '',
      rating: 4.9,
      reviewCount: 42,
      subscriptionTier: SubscriptionTier.vipPlatinum,
      city: 'Dubai',
      areaAr: data['address_ar']?.toString() ?? 'جميرا',
      areaEn: 'Jumeirah',
      addressAr: data['address_ar']?.toString() ?? 'جميرا',
      addressEn: 'Jumeirah',
      mainPhone: data['phone']?.toString() ?? '',
      whatsapp: data['whatsapp']?.toString() ?? '',
      googleMapsUrl: data['google_maps_url']?.toString(),
    );
  }
}

void main() {
  group('Production Readiness Audit Verification Tests (AUD-01 to AUD-08)', () {
    test('AUD-05: ApiConfig uses relative paths without leading slash and supports setBaseUrl', () {
      expect(ApiConfig.authMe, 'auth/me/');
      expect(ApiConfig.practitioners, 'practitioners/');
      expect(ApiConfig.practitionerDetail('abc-123'), 'practitioners/abc-123/');
      expect(ApiConfig.treatments, 'treatments/');
      expect(ApiConfig.treatmentDetail('trt-456'), 'treatments/trt-456/');
      expect(ApiConfig.categories, 'categories/');
      expect(ApiConfig.clinicProfile, 'clinic-portal/profile/');
      expect(ApiConfig.clinicDiscountVerify, 'clinic-portal/discount-codes/verify/');
      expect(ApiConfig.clinicDiscountRedeem, 'clinic-portal/discount-codes/redeem/');

      // Verify none of the static paths start with '/'
      final paths = [
        ApiConfig.authMe,
        ApiConfig.practitioners,
        ApiConfig.treatments,
        ApiConfig.categories,
        ApiConfig.clinicProfile,
        ApiConfig.clinicDiscountVerify,
        ApiConfig.clinicDiscountRedeem,
      ];
      for (final p in paths) {
        expect(p.startsWith('/'), isFalse, reason: 'Path $p must not start with /');
      }

      ApiConfig.setBaseUrl('https://staging.aestheticway.ae/api/v1');
      expect(ApiConfig.baseUrl, 'https://staging.aestheticway.ae/api/v1/');
      ApiConfig.resetBaseUrl();
    });

    test('AUD-01: PractitionerModel.fromJson parses nested clinic and treatments from public serializer', () {
      final json = {
        'id': 'pract-uuid-1',
        'name_ar': 'د. راشد الفلاسي',
        'name_en': 'Dr. Rashid Al Falasi',
        'role': 'doctor',
        'speciality_ar': 'جراحة التجميل والترميم',
        'speciality_en': 'Plastic & Reconstructive Surgery',
        'bio_ar': 'استشاري معتمد في جراحات التجميل.',
        'bio_en': 'Board-certified plastic surgery consultant.',
        'experience_years': 15,
        'clinic': {
          'id': 'clinic-uuid-99',
          'name_ar': 'مركز دبي الملكي للتجميل',
          'name_en': 'Dubai Royal Aesthetics Center',
          'city': 'Dubai',
        },
        'treatments': [
          {'id': 't-1', 'name_ar': 'شد الوجه الجراحي', 'name_en': 'Facelift'},
          {'id': 't-2', 'name_ar': 'تجميل الأنف', 'name_en': 'Rhinoplasty'},
        ],
      };

      final model = PractitionerModel.fromJson(json);
      expect(model.id, 'pract-uuid-1');
      expect(model.nameAr, 'د. راشد الفلاسي');
      expect(model.clinicId, 'clinic-uuid-99');
      expect(model.clinicNameAr, 'مركز دبي الملكي للتجميل');
      expect(model.clinicNameEn, 'Dubai Royal Aesthetics Center');
      expect(model.yearsOfExperience, 15);
      expect(model.procedures, contains('شد الوجه الجراحي'));
    });

    test('AUD-02: TreatmentModel.fromJson parses nested clinic, category, and duration_minutes', () {
      final json = {
        'id': 'trt-uuid-1',
        'name_ar': 'هيدرافيشيال بلاتينيوم',
        'name_en': 'Platinum HydraFacial',
        'description_ar': 'تنظيف عميق وترطيب طبي للبشرة.',
        'description_en': 'Deep medical facial cleansing and hydration.',
        'duration_minutes': 45,
        'price': '950.00',
        'clinic': {
          'id': 'clinic-uuid-55',
          'name_ar': 'عيادة جميرا للجلدية',
          'name_en': 'Jumeirah Dermatology Clinic',
        },
        'category': {
          'id': 'cat-uuid-10',
          'name_ar': 'العناية بالبشرة',
          'name_en': 'Skincare',
        },
      };

      final model = TreatmentModel.fromJson(json);
      expect(model.id, 'trt-uuid-1');
      expect(model.clinicId, 'clinic-uuid-55');
      expect(model.clinicNameAr, 'عيادة جميرا للجلدية');
      expect(model.categoryId, 'cat-uuid-10');
      expect(model.categoryAr, 'العناية بالبشرة');
      expect(model.durationText, '45 دقيقة');
      expect(model.durationTextEn, '45 mins');
      expect(model.price, 950.0);
    });

    test('AUD-03: ReferralService starts clean without mock codes and verifies/redeems via live repository', () async {
      final service = ReferralService();
      service.resetTestingState();

      // Production state starts empty before enableMockMode
      expect(service.allPlatformCodes, isEmpty);

      final fakeRepo = _FakeReferralRepository();
      service.setRepositoryForTesting(fakeRepo);

      final verified = await service.verifyClinicCodeLive('AW-15-9999');
      expect(fakeRepo.lastVerifiedCode, 'AW-15-9999');
      expect(verified, isNotNull);
      expect(verified!.code, 'AW-15-9999');
      expect(verified.isAvailable, isTrue);
      expect(verified.userName, 'دانة المزروعي');

      final redeemed = await service.redeemClinicCodeLive(
        code: 'AW-15-9999',
        clinicId: 'clinic-1',
        clinicName: 'عيادة الأناقة الطبية',
      );
      expect(redeemed, isTrue);
      expect(fakeRepo.lastRedeemedCode, 'AW-15-9999');
      expect(service.verifyCode('AW-15-9999')?.isUsed, isTrue);
    });

    test('AUD-04 & AUD-06: ClinicPortalService starts clean and updates clinic profile via PATCH /clinic-portal/profile/', () async {
      final service = ClinicPortalService();
      service.resetTestingState();

      // Production state starts empty before enableMockMode
      expect(service.clinicLeads, isEmpty);
      expect(service.clinicOffers, isEmpty);
      expect(service.clinicPractitioners, isEmpty);

      final fakeCatalogRepo = _FakeClinicCatalogRepository();
      service.setCatalogRepositoryForTesting(fakeCatalogRepo);

      await service.updateClinicProfile(
        nameAr: 'عيادة النخبة المحدثة',
        nameEn: 'Updated Elite Clinic',
        descriptionAr: 'وصف محدث للعيادة',
        descriptionEn: 'Updated clinic description',
        phone: '+971509998877',
        whatsapp: '+971509998877',
        addressAr: 'وسط مدينة دبي',
        googleMapsUrl: 'https://maps.google.com/?q=Updated+Elite',
      );

      expect(fakeCatalogRepo.lastUpdatedProfilePayload, isNotNull);
      expect(fakeCatalogRepo.lastUpdatedProfilePayload!['name_ar'], 'عيادة النخبة المحدثة');
      expect(fakeCatalogRepo.lastUpdatedProfilePayload!['phone'], '+971509998877');
      expect(fakeCatalogRepo.lastUpdatedProfilePayload!['google_maps_url'], 'https://maps.google.com/?q=Updated+Elite');
      expect(service.activeClinic.nameAr, 'عيادة النخبة المحدثة');
      expect(service.activeClinic.mainPhone, '+971509998877');
    });

    testWidgets('AUD-08: AdminSettingsScreen binds header card to AuthState userName and userEmail', (tester) async {
      final adminService = AdminPortalService();
      adminService.resetTestingState();
      expect(adminService.clinics, isEmpty);
      expect(adminService.allLeads, isEmpty);

      AuthState().login(
        role: 'super_admin',
        name: 'خالد المنصوري - المدير العام',
        email: 'khalid.admin@aestheticway.ae',
        phone: '+971500000001',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('خالد المنصوري - المدير العام'), findsOneWidget);
      expect(find.text('khalid.admin@aestheticway.ae'), findsOneWidget);
      expect(find.text('admin@aestheticway.ae'), findsNothing);
    });
  });
}
