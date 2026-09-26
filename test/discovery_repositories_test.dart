import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/features/home/data/models/home_feed_model.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';

void main() {
  group('Discovery Data Layer Tests', () {
    test('HomeFeedModel parses JSON feed from backend correctly', () {
      final sampleJson = {
        'featured_ads': [
          {
            'id': 'ad-1',
            'image': 'https://example.com/banner.jpg',
            'link': 'https://example.com',
          }
        ],
        'categories': [
          {
            'id': 'cat-1',
            'name_en': 'Laser & Light',
            'name_ar': 'الليزر والضوء',
            'slug': 'laser-and-light',
            'icon': '',
          }
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
            }
          }
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
          }
        ]
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
          }
        ],
      };

      final clinic = ClinicModel.fromJson(clinicJson);

      expect(clinic.nameEn, 'Luxe Derma Jumeirah');
      expect(clinic.mainPhone, '+97143001122');
      expect(clinic.latitude, 25.2048);
      expect(clinic.branches.length, 1);
      expect(clinic.branches.first.nameEn, 'Jumeirah 1');
    });

    test('OfferModel calculates discount percentage and handles ends_at dates', () {
      final offerJson = {
        'id': 'offer-1',
        'title_ar': 'عرض البوتوكس',
        'title_en': 'Botox Package',
        'original_price': '2000.00',
        'offer_price': '1000.00',
        'ends_at': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
        'clinic': {
          'id': 'clinic-abc',
          'name_ar': 'عيادة النور',
          'name_en': 'Al Noor Clinic',
        }
      };

      final offer = OfferModel.fromJson(offerJson);

      expect(offer.discountPercentage, 50);
      expect(offer.clinicId, 'clinic-abc');
      expect(offer.clinicNameEn, 'Al Noor Clinic');
      expect(offer.daysRemaining >= 9, isTrue);
    });
  });
}
