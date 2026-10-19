import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/features/home/data/models/home_feed_model.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/articles/models/article_model.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/clinics/data/clinics_repository.dart';
import 'package:aesthetic_way/features/offers/data/offers_repository.dart';
import 'package:aesthetic_way/features/products/data/products_repository.dart';
import 'package:aesthetic_way/features/articles/data/articles_repository.dart';
import 'package:aesthetic_way/features/treatments/data/treatments_repository.dart';

void main() {
  group('Discovery Data Layer Tests', () {
    test('HomeFeedModel parses JSON feed from backend correctly', () {
      final sampleJson = {
        'featured_ads': [
          {
            'id': 'ad-1',
            'image': 'https://example.com/banner.jpg',
            'link': 'https://example.com',
          },
        ],
        'categories': [
          {
            'id': 'cat-1',
            'name_en': 'Laser & Light',
            'name_ar': 'الليزر والضوء',
            'slug': 'laser-and-light',
            'icon': '',
          },
        ],
        'active_offers': [
          {
            'id': 'off-1',
            'title_en': 'Luxury Hydrafacial',
            'title_ar': 'هيدرافاشيال فاخر',
            'original_price': '1200.00',
            'offer_price': '750.00',
            'clinic': {
              'id': 'clinic-1',
              'name_en': 'Downtown Clinic',
              'name_ar': 'عيادة داون تاون',
            },
          },
        ],
        'nearby_clinics': [
          {
            'id': 'clinic-1',
            'name_en': 'Downtown Clinic',
            'name_ar': 'عيادة داون تاون',
            'city': 'Dubai',
            'is_featured': true,
            'google_rating': '4.9',
            'distance': '1250.5',
          },
        ],
      };

      final feed = HomeFeedModel.fromJson(sampleJson);

      expect(feed.featuredAds.length, 1);
      expect(feed.featuredAds.first.id, 'ad-1');

      expect(feed.categories.length, 1);
      expect(feed.categories.first.nameEn, 'Laser & Light');

      expect(feed.activeOffers.length, 1);
      expect(feed.activeOffers.first.offerPrice, 750.0);
      expect(feed.activeOffers.first.discountPercentage, 38);

      expect(feed.nearbyClinics.length, 1);
      expect(feed.nearbyClinics.first.rating, 4.9);
      expect(feed.nearbyClinics.first.isEligibleForTopCarousel, isTrue);
    });

    test('ClinicModel correctly maps branches, coordinates and contacts', () {
      final clinicJson = {
        'id': 'clinic-uuid-1',
        'name_en': 'Luxe Derma Jumeirah',
        'name_ar': 'لوكس ديرما جميرا',
        'city': 'Dubai',
        'phone': '+97143001122',
        'whatsapp': '+971501112233',
        'google_rating': '4.8',
        'distance': '3.2',
        'latitude': '25.2048',
        'longitude': '55.2708',
        'branches': [
          {
            'id': 'branch-1',
            'name_en': 'Jumeirah 1',
            'name_ar': 'جميرا 1',
            'phone': '+97143001123',
            'latitude': '25.2100',
            'longitude': '55.2800',
          },
        ],
      };

      final clinic = ClinicModel.fromJson(clinicJson);

      expect(clinic.nameEn, 'Luxe Derma Jumeirah');
      expect(clinic.mainPhone, '+97143001122');
      expect(clinic.latitude, 25.2048);
      expect(clinic.branches.length, 1);
      expect(clinic.branches.first.nameEn, 'Jumeirah 1');
    });

    test(
      'OfferModel calculates discount percentage and handles ends_at dates',
      () {
        final offerJson = {
          'id': 'offer-1',
          'title_ar': 'عرض البوتوكس',
          'title_en': 'Botox Package',
          'original_price': '2000.00',
          'offer_price': '1000.00',
          'ends_at': DateTime.now()
              .add(const Duration(days: 10))
              .toIso8601String(),
          'clinic': {
            'id': 'clinic-abc',
            'name_ar': 'عيادة النور',
            'name_en': 'Al Noor Clinic',
            'logo': 'https://example.com/clinic_logo.png',
          },
        };

        final offer = OfferModel.fromJson(offerJson);

        expect(offer.discountPercentage, 50);
        expect(offer.clinicId, 'clinic-abc');
        expect(offer.clinicNameEn, 'Al Noor Clinic');
        expect(offer.clinicLogoUrl, 'https://example.com/clinic_logo.png');
        expect(offer.daysRemaining >= 9, isTrue);
      },
    );

    test('Models correctly extract clinicLogoUrl from nested clinic JSON', () {
      final product = ProductModel.fromJson({
        'id': 'prod-1',
        'name_ar': 'كريم طبي',
        'name_en': 'Medical Cream',
        'clinic': {
          'id': 'c-1',
          'name_ar': 'العيادة',
          'logo': 'https://example.com/c1_logo.png',
        },
      });
      expect(product.clinicLogoUrl, equals('https://example.com/c1_logo.png'));

      final article = ArticleModel.fromJson({
        'id': 'art-1',
        'title_ar': 'دليل العناية بالبشرة',
        'title_en': 'Skincare Guide',
        'content_ar': 'محتوى',
        'content_en': 'content',
        'clinic': {
          'id': 'c-2',
          'name_ar': 'العيادة',
          'logo': 'https://example.com/c2_logo.png',
        },
      });
      expect(article.clinicLogoUrl, equals('https://example.com/c2_logo.png'));

      final treatment = TreatmentModel.fromJson({
        'id': 't-1',
        'name_ar': 'جلسة نضارة',
        'name_en': 'Glow Session',
        'clinic': {
          'id': 'c-3',
          'name_ar': 'العيادة',
          'logo': 'https://example.com/c3_logo.png',
        },
      });
      expect(
        treatment.clinicLogoUrl,
        equals('https://example.com/c3_logo.png'),
      );

      final practitioner = PractitionerModel.fromJson({
        'id': 'p-1',
        'name_ar': 'د. سارة',
        'name_en': 'Dr. Sarah',
        'specialty_ar': 'جلدية',
        'specialty_en': 'Dermatology',
        'type': 'doctor',
        'clinic': {
          'id': 'c-4',
          'name_ar': 'عيادة دبي',
          'logo': 'https://example.com/c4_logo.png',
        },
      });
      expect(
        practitioner.clinicLogoUrl,
        equals('https://example.com/c4_logo.png'),
      );
    });
  });

  group('Repository Pagination Query Parameters Tests', () {
    late _TestCaptureInterceptor interceptor;
    late ApiClient apiClient;

    setUp(() {
      interceptor = _TestCaptureInterceptor();
      apiClient = ApiClient();
      apiClient.dio.interceptors.insert(0, interceptor);
    });

    tearDown(() {
      apiClient.dio.interceptors.remove(interceptor);
    });

    test(
      'ClinicsRepository passes page and pageSize in query parameters',
      () async {
        final repo = ClinicsRepository(apiClient: apiClient);
        await repo.getClinics(page: 3, pageSize: 25);
        expect(interceptor.lastQueryParams?['page'], equals(3));
        expect(interceptor.lastQueryParams?['page_size'], equals(20));
      },
    );

    test(
      'OffersRepository passes page and pageSize in query parameters',
      () async {
        final repo = OffersRepository(apiClient: apiClient);
        await repo.getOffers(page: 2, pageSize: 20);
        expect(interceptor.lastQueryParams?['page'], equals(2));
        expect(interceptor.lastQueryParams?['page_size'], equals(20));
      },
    );

    test(
      'ProductsRepository passes page and pageSize in query parameters',
      () async {
        final repo = ProductsRepository(apiClient: apiClient);
        await repo.getProducts(page: 4, pageSize: 15);
        expect(interceptor.lastQueryParams?['page'], equals(4));
        expect(interceptor.lastQueryParams?['page_size'], equals(20));
      },
    );

    test(
      'ArticlesRepository passes page and pageSize in query parameters',
      () async {
        final repo = ArticlesRepository(apiClient: apiClient);
        await repo.getArticles(page: 5, pageSize: 10);
        expect(interceptor.lastQueryParams?['page'], equals(5));
        expect(interceptor.lastQueryParams?['page_size'], equals(20));
      },
    );

    test(
      'TreatmentsRepository passes page and pageSize in query parameters',
      () async {
        final repo = TreatmentsRepository(apiClient: apiClient);
        await repo.getTreatments(page: 2, pageSize: 30);
        expect(interceptor.lastQueryParams?['page'], equals(2));
        expect(interceptor.lastQueryParams?['page_size'], equals(20));
      },
    );
  });
}

class _TestCaptureInterceptor extends Interceptor {
  Map<String, dynamic>? lastQueryParams;
  String? lastPath;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    lastPath = options.path;
    lastQueryParams = options.queryParameters;
    handler.resolve(
      Response(requestOptions: options, data: {'results': []}, statusCode: 200),
    );
  }
}
