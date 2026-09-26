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

  group('LuxuryImage and LuxuryAvatar Widget Tests', () {
    testWidgets('LuxuryImage renders placeholder without crashing when URL is empty string ""', (tester) async {
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
      expect(find.byIcon(Icons.local_hospital_outlined), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('LuxuryImage renders placeholder without crashing when URL is null or invalid', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LuxuryImage(
              imageUrl: 'file:///',
              width: 100,
              height: 100,
              placeholderIcon: Icons.spa_outlined,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LuxuryImage), findsOneWidget);
      expect(find.byIcon(Icons.spa_outlined), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('LuxuryAvatar renders placeholder without crashing when avatar URL is empty or null', (tester) async {
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
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
      expect(find.byType(Image), findsNothing);
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
