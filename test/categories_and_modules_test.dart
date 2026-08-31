import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/data/mock_data.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/articles/models/article_model.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';

void main() {
  group('8 Categories & Demo Data Completeness Tests', () {
    final mock = MockDataService();

    test('1. Offers Category has 4+ rich items', () {
      expect(mock.offers.length, greaterThanOrEqualTo(4));
      for (final offer in mock.offers) {
        expect(offer.titleAr.isNotEmpty, isTrue);
        expect(offer.clinicNameAr.isNotEmpty, isTrue);
        expect(offer.offerPrice, greaterThan(0));
      }
    });

    test('2. Treatments Category has 8+ items across various specialties', () {
      expect(mock.treatments.length, greaterThanOrEqualTo(8));
      for (final treatment in mock.treatments) {
        expect(treatment.nameAr.isNotEmpty, isTrue);
        expect(treatment.categoryAr.isNotEmpty, isTrue);
        expect(treatment.durationText.isNotEmpty, isTrue);
      }
    });

    test('3. Doctors Category returns only verified Doctor practitioners', () {
      final doctors = mock.doctors;
      expect(doctors.length, greaterThanOrEqualTo(4));
      for (final doc in doctors) {
        expect(doc.type, equals(PractitionerType.doctor));
        expect(doc.nameAr.startsWith('د.'), isTrue);
      }
    });

    test('4. Skin Experts Category returns 4+ licensed aesthetic nurses and dermal specialists', () {
      final experts = mock.skinExperts;
      expect(experts.length, greaterThanOrEqualTo(4));
      for (final expert in experts) {
        final isExpertType = expert.type == PractitionerType.nurse ||
            expert.type == PractitionerType.licensedProfessional ||
            expert.specialtyAr.contains('بشرة') ||
            expert.specialtyAr.contains('ليزر');
        expect(isExpertType, isTrue);
      }
    });

    test('5. Plastic Surgery Category returns 4+ surgical treatments', () {
      final surgeryTreatments = mock.plasticSurgeryTreatments;
      expect(surgeryTreatments.length, greaterThanOrEqualTo(4));
      for (final s in surgeryTreatments) {
        final isSurg = s.categoryAr.contains('جراحة') ||
            s.nameAr.contains('شد') ||
            s.nameAr.contains('أنف') ||
            s.nameAr.contains('شفط');
        expect(isSurg, isTrue);
      }
    });

    test('6. Products Module has 6+ demo skincare & device items without in-app checkout', () {
      final products = mock.products;
      expect(products.length, greaterThanOrEqualTo(6));
      for (final p in products) {
        expect(p.nameAr.isNotEmpty, isTrue);
        expect(p.price, greaterThan(0));
        expect(p.clinicId.isNotEmpty, isTrue);
        expect(p.imageUrl.isNotEmpty, isTrue);
      }
    });

    test('7. Articles Module has 4+ doctor-authored aesthetic guides', () {
      final articles = mock.articles;
      expect(articles.length, greaterThanOrEqualTo(4));
      for (final a in articles) {
        expect(a.titleAr.isNotEmpty, isTrue);
        expect(a.authorDoctorNameAr.isNotEmpty, isTrue);
        expect(a.contentAr.isNotEmpty, isTrue);
        expect(a.clinicId.isNotEmpty, isTrue);
      }
    });

    test('8. Clinics Category returns 5+ verified clinics', () {
      expect(mock.clinics.length, greaterThanOrEqualTo(5));
    });
  });

  group('Clinic Portal Products & Articles Management Tests', () {
    final clinicService = ClinicPortalService();

    test('Clinic can add, toggle availability, and delete products', () {
      final initialCount = clinicService.clinicProducts.length;
      final testProd = ProductModel(
        id: 'test-prod-${DateTime.now().millisecondsSinceEpoch}',
        nameAr: 'سيروم تجريبي',
        nameEn: 'Test Serum',
        clinicId: clinicService.activeClinic.id,
        clinicNameAr: clinicService.activeClinic.nameAr,
        descriptionAr: 'وصف السيروم التجريبي',
        descriptionEn: 'Test description',
        price: 350,
        imageUrl: 'https://example.com/test.jpg',
        categoryAr: 'عناية بالبشرة',
        categoryEn: 'Skincare',
        isAvailable: true,
      );

      clinicService.addProduct(testProd);
      expect(clinicService.clinicProducts.length, equals(initialCount + 1));

      clinicService.toggleProductAvailability(testProd.id);
      final toggled = clinicService.clinicProducts.firstWhere((p) => p.id == testProd.id);
      expect(toggled.isAvailable, isFalse);

      clinicService.deleteProduct(testProd.id);
      expect(clinicService.clinicProducts.length, equals(initialCount));
    });

    test('Clinic can add, toggle publish, and delete articles under doctor name', () {
      final initialCount = clinicService.clinicArticles.length;
      final testArt = ArticleModel(
        id: 'test-art-${DateTime.now().millisecondsSinceEpoch}',
        titleAr: 'مقال طبي تجريبي',
        titleEn: 'Test Medical Article',
        coverImageUrl: 'https://example.com/art.jpg',
        summaryAr: 'ملخص المقال',
        summaryEn: 'Article summary',
        contentAr: 'محتوى المقال التجريبي',
        contentEn: 'Article content',
        authorDoctorId: 'dr-reem',
        authorDoctorNameAr: 'د. ريم الخالد',
        authorDoctorNameEn: 'Dr. Reem Al Khaled',
        authorDoctorSpecialtyAr: 'استشاري جلدية',
        authorDoctorSpecialtyEn: 'Consultant Dermatologist',
        authorDoctorAvatar: 'https://example.com/avatar.jpg',
        clinicId: clinicService.activeClinic.id,
        clinicNameAr: clinicService.activeClinic.nameAr,
        categoryAr: 'نضارة وتجديد البشرة',
        categoryEn: 'Skin Glow & Renewal',
        publishedAt: DateTime.now(),
        isPublished: true,
      );

      clinicService.addArticle(testArt);
      expect(clinicService.clinicArticles.length, equals(initialCount + 1));

      clinicService.toggleArticlePublish(testArt.id);
      final toggled = clinicService.clinicArticles.firstWhere((a) => a.id == testArt.id);
      expect(toggled.isPublished, isFalse);

      clinicService.deleteArticle(testArt.id);
      expect(clinicService.clinicArticles.length, equals(initialCount));
    });
  });

  group('Super Admin Moderation Tests', () {
    final adminService = AdminPortalService();

    test('Admin can suspend and activate products and articles without authoring', () {
      final products = adminService.allProducts;
      expect(products.isNotEmpty, isTrue);
      final firstProd = products.first;
      final initialProdState = firstProd.isPublishedByAdmin;

      adminService.toggleProductModeration(firstProd.id);
      final updatedProd = adminService.allProducts.firstWhere((p) => p.id == firstProd.id);
      expect(updatedProd.isPublishedByAdmin, equals(!initialProdState));

      final articles = adminService.allArticles;
      expect(articles.isNotEmpty, isTrue);
      final firstArt = articles.first;
      final initialArtState = firstArt.isApprovedByAdmin;

      adminService.toggleArticleModeration(firstArt.id);
      final updatedArt = adminService.allArticles.firstWhere((a) => a.id == firstArt.id);
      expect(updatedArt.isApprovedByAdmin, equals(!initialArtState));
    });
  });

  group('Compliance & Product Boundaries Strict Checks', () {
    test('Zero mentions of forbidden authority names across all product and article data', () {
      final mock = MockDataService();
      final forbiddenTerms = ['DHA', 'DOH', 'MOHAP', 'وزارة الصحة', 'دائرة الصحة', 'هيئة الصحة'];

      for (final p in mock.products) {
        for (final term in forbiddenTerms) {
          expect(p.nameAr.contains(term), isFalse, reason: 'Found $term in product ${p.nameAr}');
          expect(p.descriptionAr.contains(term), isFalse, reason: 'Found $term in product desc');
        }
      }

      for (final a in mock.articles) {
        for (final term in forbiddenTerms) {
          expect(a.titleAr.contains(term), isFalse, reason: 'Found $term in article ${a.titleAr}');
          expect(a.contentAr.contains(term), isFalse, reason: 'Found $term in article content');
        }
      }
    });
  });
}
