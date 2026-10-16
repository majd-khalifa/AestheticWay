import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/rating_chip.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';

void main() {
  group('isValidNetworkImageUrl Tests', () {
    test('returns false for null, empty or whitespace strings', () {
      expect(isValidNetworkImageUrl(null), isFalse);
      expect(isValidNetworkImageUrl(''), isFalse);
      expect(isValidNetworkImageUrl('   '), isFalse);
    });

    test('returns false for non-http(s) schemas or file URIs', () {
      expect(isValidNetworkImageUrl('file:///'), isFalse);
      expect(isValidNetworkImageUrl('ftp://example.com/img.png'), isFalse);
      expect(isValidNetworkImageUrl('assets/images/logo.png'), isFalse);
      expect(isValidNetworkImageUrl('/media/clinics/cover.jpg'), isFalse);
    });

    test('returns true for valid http and https URLs', () {
      expect(isValidNetworkImageUrl('http://127.0.0.1:8000/media/img.jpg'), isTrue);
      expect(isValidNetworkImageUrl('https://example.com/photo.png'), isTrue);
      expect(isValidNetworkImageUrl('  https://example.com/trimmed.jpg  '), isTrue);
    });
  });

  group('computeSafeCacheWidth Tests', () {
    testWidgets('computes safe cache width clamped within 100 and 1080', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final w1 = computeSafeCacheWidth(context, 50, 50);
              final w2 = computeSafeCacheWidth(context, 800, 400);
              final w3 = computeSafeCacheWidth(context, null, null);
              expect(w1, inInclusiveRange(100, 1080));
              expect(w2, inInclusiveRange(100, 1080));
              expect(w3, inInclusiveRange(100, 1080));
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('LuxuryImage and LuxuryAvatar Smart Fallback Hierarchy Tests', () {
    testWidgets('LuxuryImage renders brand emblem asset fallback when imageUrl is empty and no fallbackLogoUrl', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LuxuryImage(
              imageUrl: '',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LuxuryImage), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      final img = tester.widget<Image>(find.byType(Image));
      expect(img.image, isA<ResizeImage>());
      final resize = img.image as ResizeImage;
      expect(resize.imageProvider, isA<AssetImage>());
      final assetImage = resize.imageProvider as AssetImage;
      expect(assetImage.assetName, equals('assets/images/aesthetic_way_logo.png'));
    });

    testWidgets('LuxuryImage renders customPlaceholder when provided and imageUrl is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LuxuryImage(
              imageUrl: '',
              width: 100,
              height: 100,
              customPlaceholder: Icon(Icons.star, key: Key('custom-icon')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LuxuryImage), findsOneWidget);
      expect(find.byKey(const Key('custom-icon')), findsOneWidget);
    });

    testWidgets('LuxuryImage renders clinic logo and gracefully cascades to brand emblem on network failure', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LuxuryImage(
              imageUrl: '',
              fallbackLogoUrl: 'https://example.com/clinic_logo.png',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LuxuryImage), findsOneWidget);
      // In test environment without HTTP mocking, Image.network fails and triggers errorBuilder cascade
      // to the official brand emblem fallback.
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images.isNotEmpty, isTrue);
      final hasEmblem = images.any((img) {
        if (img.image is ResizeImage) {
          final res = img.image as ResizeImage;
          return res.imageProvider is AssetImage &&
              (res.imageProvider as AssetImage).assetName == 'assets/images/aesthetic_way_logo.png';
        }
        return false;
      });
      expect(hasEmblem, isTrue);
    });

    testWidgets('LuxuryAvatar renders brand emblem without crashing when avatar URL is empty or null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LuxuryAvatar(
              imageUrl: '',
              radius: 26,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LuxuryAvatar), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      final img = tester.widget<Image>(find.byType(Image));
      expect(img.image, isA<ResizeImage>());
      final resize = img.image as ResizeImage;
      expect(resize.imageProvider, isA<AssetImage>());
      final assetImage = resize.imageProvider as AssetImage;
      expect(assetImage.assetName, equals('assets/images/aesthetic_way_logo.png'));
    });
  });

  group('ClinicModel Actions & Rating Getters', () {
    test('identifies hasPhone correctly', () {
      const clinicWithNoPhone = ClinicModel(
        id: '1',
        nameAr: 'عيادة',
        nameEn: 'Clinic',
        descriptionAr: '',
        descriptionEn: '',
        coverImageUrl: '',
        galleryImages: [],
        logoUrl: '',
        rating: 0.0,
        reviewCount: 0,
        subscriptionTier: SubscriptionTier.basic,
        city: 'Dubai',
        areaAr: '',
        addressAr: '',
      );
      expect(clinicWithNoPhone.hasPhone, isFalse);

      const clinicWithPhone = ClinicModel(
        id: '2',
        nameAr: 'عيادة',
        nameEn: 'Clinic',
        descriptionAr: '',
        descriptionEn: '',
        coverImageUrl: '',
        galleryImages: [],
        logoUrl: '',
        rating: 0.0,
        reviewCount: 0,
        subscriptionTier: SubscriptionTier.basic,
        city: 'Dubai',
        areaAr: '',
        addressAr: '',
        receptionPhone: '+97141234567',
      );
      expect(clinicWithPhone.hasPhone, isTrue);
      expect(clinicWithPhone.effectivePhone, '+97141234567');
    });

    test('identifies hasWhatsapp correctly based on digits length', () {
      const clinicNoWhatsapp = ClinicModel(
        id: '1',
        nameAr: 'عيادة',
        nameEn: 'Clinic',
        descriptionAr: '',
        descriptionEn: '',
        coverImageUrl: '',
        galleryImages: [],
        logoUrl: '',
        rating: 0.0,
        reviewCount: 0,
        subscriptionTier: SubscriptionTier.basic,
        city: 'Dubai',
        areaAr: '',
        addressAr: '',
        whatsapp: '',
      );
      expect(clinicNoWhatsapp.hasWhatsapp, isFalse);

      const clinicValidWhatsapp = ClinicModel(
        id: '2',
        nameAr: 'عيادة',
        nameEn: 'Clinic',
        descriptionAr: '',
        descriptionEn: '',
        coverImageUrl: '',
        galleryImages: [],
        logoUrl: '',
        rating: 0.0,
        reviewCount: 0,
        subscriptionTier: SubscriptionTier.basic,
        city: 'Dubai',
        areaAr: '',
        addressAr: '',
        whatsapp: '+971 50 123 4567',
      );
      expect(clinicValidWhatsapp.hasWhatsapp, isTrue);
    });

    test('identifies hasMapLocation correctly with coordinates or googleMapsUrl', () {
      const clinicNoMap = ClinicModel(
        id: '1',
        nameAr: 'عيادة',
        nameEn: 'Clinic',
        descriptionAr: '',
        descriptionEn: '',
        coverImageUrl: '',
        galleryImages: [],
        logoUrl: '',
        rating: 0.0,
        reviewCount: 0,
        subscriptionTier: SubscriptionTier.basic,
        city: 'Dubai',
        areaAr: '',
        addressAr: '',
      );
      expect(clinicNoMap.hasMapLocation, isFalse);

      const clinicWithCoords = ClinicModel(
        id: '2',
        nameAr: 'عيادة',
        nameEn: 'Clinic',
        descriptionAr: '',
        descriptionEn: '',
        coverImageUrl: '',
        galleryImages: [],
        logoUrl: '',
        rating: 0.0,
        reviewCount: 0,
        subscriptionTier: SubscriptionTier.basic,
        city: 'Dubai',
        areaAr: '',
        addressAr: '',
        latitude: 25.2048,
        longitude: 55.2708,
      );
      expect(clinicWithCoords.hasMapLocation, isTrue);

      const clinicWithUrl = ClinicModel(
        id: '3',
        nameAr: 'عيادة',
        nameEn: 'Clinic',
        descriptionAr: '',
        descriptionEn: '',
        coverImageUrl: '',
        galleryImages: [],
        logoUrl: '',
        rating: 0.0,
        reviewCount: 0,
        subscriptionTier: SubscriptionTier.basic,
        city: 'Dubai',
        areaAr: '',
        addressAr: '',
        googleMapsUrl: 'https://maps.google.com/?cid=123',
      );
      expect(clinicWithUrl.hasMapLocation, isTrue);
    });

    testWidgets('RatingChip returns SizedBox.shrink when rating is 0.0 without fabricating 4.8', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingChip(rating: 0.0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RatingChip), findsOneWidget);
      expect(find.text('4.8'), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
    });
  });
}
