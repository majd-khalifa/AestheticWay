import 'package:aesthetic_way/core/widgets/patient_media_placeholder.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/widgets/patient_media_banner.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/home/data/home_repository.dart';
import 'package:aesthetic_way/features/home/data/models/home_feed_model.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/products/presentation/widgets/brand_product_media.dart';
import 'support/settle_preview_images.dart';

Map<String, dynamic> _clinic(String id, String? tier) => {
  'id': id,
  'name_en': 'Public clinic',
  'subscription_tier': ?tier,
  'is_featured': true,
  'city': 'Dubai',
};

class _Client implements ApiClient {
  bool failDirectory = false;
  final calls = <String>[];
  final queries = <Map<String, dynamic>?>[];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    calls.add(path);
    queries.add(queryParameters);
    if (failDirectory && path == 'clinics/') {
      throw StateError('Directory unavailable');
    }
    final data = path == 'home/feed/'
        ? {
            'featured_ads': [
              {
                'id': 'ad-uuid',
                'clinic': _clinic('paid-ad', null),
                'subscription_tier': 'VIP',
              },
            ],
            'nearby_clinics': [_clinic('vip-no-ad', null)],
          }
        : {
            'count': 3,
            'next': null,
            'results': [
              {
                ..._clinic('vip-no-ad', 'vip'),
                'cover_image': '/media/genuine.jpg',
                'google_place_id': 'fixture-configured-place',
                'google_rating': 4.6,
                'google_reviews_count': 30,
              },
              _clinic('featured-no-ad', 'featured'),
              _clinic('basic', 'basic'),
            ],
          };
    return Response<T>(
      data: data as T,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }
}

void main() {
  test(
    'Premium subscriptions restore Home without manufacturing ad records',
    () {
      final feed = HomeFeedModel.fromJson({
        'nearby_clinics': [
          _clinic('basic', 'basic'),
          _clinic('featured', 'featured'),
          _clinic('vip', 'vip'),
          _clinic('unknown', null),
        ],
      });
      expect(feed.featuredAds, isEmpty);
      expect(feed.premiumPartners.map((p) => p.clinic.id), ['vip', 'featured']);
      expect(feed.premiumPartners.every((p) => !p.isAdvertisement), isTrue);
    },
  );
  test(
    'Ad and clinic tiers stay independent; VIP priority is stable and Basic/unknown excluded',
    () {
      final feed = HomeFeedModel.fromJson({
        'featured_ads': [
          {
            'id': 'a',
            'subscription_tier': 'Featured',
            'clinic': _clinic('featured-ad', 'vip'),
          },
          {
            'id': 'b',
            'subscription_tier': ' VIP ',
            'clinic': _clinic('vip-ad', 'basic'),
          },
          {
            'id': 'c',
            'subscription_tier': 'Basic',
            'clinic': _clinic('basic-ad', 'basic'),
          },
          {
            'id': 'd',
            'subscription_tier': 'vip_platinum',
            'clinic': _clinic('unverified-alias', 'basic'),
          },
          {'id': 'e', 'subscription_tier': 'VIP', 'clinic': null},
        ],
        'nearby_clinics': [
          _clinic('vip-ad', 'vip'),
          _clinic('subscription-only', 'vip'),
        ],
      });
      expect(feed.premiumPartners.map((p) => p.clinic.id), [
        'vip-ad',
        'subscription-only',
        'featured-ad',
      ]);
      expect(
        feed.premiumPartners.first.clinic.subscriptionTier,
        SubscriptionTier.basic,
      );
      expect(
        feed.premiumPartners.last.clinic.subscriptionTier,
        SubscriptionTier.vipPlatinum,
      );
      expect(feed.premiumPartners.last.isVip, isFalse);
    },
  );
  test(
    'Home enrichment uses one bounded active-only public directory page and retains ad identity',
    () async {
      final client = _Client();
      final feed = await HomeRepository(
        apiClient: client,
      ).getHomeFeed(city: 'Dubai');
      expect(client.calls, ['home/feed/', 'clinics/']);
      expect(client.queries.last, containsPair('page_size', 20));
      expect(client.queries.last, containsPair('city', 'dubai'));
      expect(feed.featuredAds.single.id, 'ad-uuid');
      expect(feed.premiumPartners.where((p) => !p.isAdvertisement).length, 2);
      expect(
        feed.nearbyClinics.single.coverImageUrl,
        'https://aestheticway.ae/media/genuine.jpg',
      );
      expect(feed.nearbyClinics.single.hasGoogleRating, isTrue);
    },
  );
  test(
    'Directory failure cannot discard a successful real sponsored feed',
    () async {
      final client = _Client()..failDirectory = true;
      final feed = await HomeRepository(apiClient: client).getHomeFeed();
      expect(feed.partnerDirectoryUnavailable, isTrue);
      expect(feed.premiumPartners.single.isAdvertisement, isTrue);
      expect(feed.premiumPartners.single.clinic.id, 'paid-ad');
    },
  );
  test('Recover only recognized Django wrappers and preserve signed/CDN bytes', () {
    for (final source in [
      '/media/https%3A/cdn.example.com/clinic%20cover.jpg?token=a%2Fb',
      '/media/https:/cdn.example.com/clinic%20cover.jpg?token=a%2Fb',
      'https://aestheticway.ae/media/https%3A/cdn.example.com/clinic%20cover.jpg?token=a%2Fb',
    ]) {
      expect(
        ApiConfig.resolveUrl(source),
        'https://cdn.example.com/clinic%20cover.jpg?token=a%2Fb',
      );
    }
    for (final source in [
      'https://cdn.example.com/media/https%3A/photo.jpg?sig=a%2Fb',
      'https://aestheticway.ae/media/https%3A/photo.jpg?X-Amz-Signature=a%2Fb',
      'https://cdn.example.com/photo%20x.jpg?X-Amz-Signature=a%2Fb&X-Amz-Date=20261020',
    ]) {
      expect(ApiConfig.resolveUrl(source), source);
    }
    expect(
      ApiConfig.resolveUrl('https://aestheticway.ae'),
      'https://aestheticway.ae',
    );
  });
  testWidgets(
    'Genuine photo decodes with cover geometry; absent media preserves the same frame',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PatientMediaBanner(
                  source: 'assets/images/onboarding/onboarding_1.jpeg',
                  height: 180,
                ),
                PatientMediaBanner(source: '', height: 180),
              ],
            ),
          ),
        ),
      );
      await settlePreviewImages(tester);
      expect(tester.getSize(find.byType(PatientMediaBanner).first).height, 180);
      expect(
        tester.getSize(find.byType(PatientMediaBanner).last).height,
        180.0,
      );
      expect(find.byType(PatientMediaPlaceholder), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.cover);
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    },
  );
  testWidgets(
    'Undecodable native media uses the same full-frame placeholder without hiding identity',
    (tester) async {
      final dir = Directory.systemTemp.createTempSync('aw-broken-media-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/corrupt.png')
        ..writeAsBytesSync([1, 2, 3, 4]);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PatientMediaBanner(source: file.path, height: 180),
                const Text('Actual clinic identity'),
              ],
            ),
          ),
        ),
      );
      // A file decode started during pumpWidget lives in the test's fake
      // async zone. Advance frames and yield real IO until Image.errorBuilder
      // has replaced it; observing a second stream can miss that first error.
      for (var frame = 0; frame < 30; frame++) {
        if (find.byType(PatientMediaPlaceholder).evaluate().isNotEmpty) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(tester.getSize(find.byType(PatientMediaBanner)).height, 180.0);
      expect(find.byType(PatientMediaPlaceholder), findsOneWidget);
      expect(find.text('Actual clinic identity'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Missing product media uses supplied brand identity without prices or fabricated photos',
    (tester) async {
      final product = ProductModel.fromJson({
        'name_en': 'Serum',
        'brand_name_en': 'Actual Brand',
        'sponsor_company': 'Actual Sponsor',
        'price': 999,
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BrandProductMedia(product: product)),
        ),
      );
      expect(find.byType(PatientMediaPlaceholder), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.textContaining('999'), findsNothing);
      expect(
        tester.getSize(find.byType(BrandProductMedia)).height,
        (tester.getSize(find.byType(BrandProductMedia)).width * 1.25).clamp(
          0.0,
          360.0,
        ),
      );
    },
  );
}
