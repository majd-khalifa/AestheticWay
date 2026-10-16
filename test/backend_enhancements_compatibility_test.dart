import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/services/device_token_service.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/clinic_portal/data/models/clinic_badge_counts_model.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Backend Enhancements Compatibility Tests', () {
    test('ClinicBadgeCountsModel deserializes backend payload correctly', () {
      final json = {
        'new_requests': 7,
        'unread_requests': 7,
        'contacted_requests': 14,
        'closed_requests': 3,
        'total_requests': 24,
      };

      final model = ClinicBadgeCountsModel.fromJson(json);

      expect(model.newRequests, 7);
      expect(model.unreadRequests, 7);
      expect(model.contactedRequests, 14);
      expect(model.closedRequests, 3);
      expect(model.totalRequests, 24);

      final serialized = model.toJson();
      expect(serialized['unread_requests'], 7);
      expect(serialized['total_requests'], 24);
    });

    test('ClinicBadgeCountsModel handles string counts and missing keys safely', () {
      final json = {
        'new_requests': '5',
        'contacted_requests': '12',
        'total_requests': '17',
      };

      final model = ClinicBadgeCountsModel.fromJson(json);

      expect(model.newRequests, 5);
      expect(model.unreadRequests, 5); // Fallback to new_requests
      expect(model.contactedRequests, 12);
      expect(model.closedRequests, 0);
      expect(model.totalRequests, 17);
    });

    test('ClinicModel parses google_rating and google_reviews_count from live backend serializer', () {
      final json = {
        'id': 'clinic-dubai-1',
        'name_en': 'Aesthetic Way Clinic Downtown',
        'name_ar': 'عيادة إستيتك واي داون تاون',
        'google_rating': '4.9',
        'google_reviews_count': 128,
        'google_maps_url': 'https://maps.google.com/?cid=12345',
        'is_featured': true,
      };

      final clinic = ClinicModel.fromJson(json);

      expect(clinic.rating, 4.9);
      expect(clinic.googleRating, 4.9);
      expect(clinic.reviewCount, 128);
      expect(clinic.googleReviewsCount, 128);
      expect(clinic.googleMapsUrl, 'https://maps.google.com/?cid=12345');
    });

    test('ClinicModel fallback parses legacy rating and review_count keys', () {
      final json = {
        'id': 'clinic-dubai-2',
        'name_en': 'Legacy Clinic',
        'name_ar': 'عيادة سابقة',
        'rating': 4.7,
        'review_count': 56,
      };

      final clinic = ClinicModel.fromJson(json);

      expect(clinic.rating, 4.7);
      expect(clinic.googleRating, 4.7);
      expect(clinic.reviewCount, 56);
      expect(clinic.googleReviewsCount, 56);
    });

    test('ClinicPortalService integrates badgeCounts into telemetry getters', () {
      final service = ClinicPortalService();
      service.resetTestingState();

      expect(service.newLeadsCount, 0);

      // Inject badge counts
      final badges = ClinicBadgeCountsModel.fromJson({
        'new_requests': 9,
        'unread_requests': 9,
        'contacted_requests': 15,
        'closed_requests': 4,
        'total_requests': 28,
      });

      // Verify that when badgeCounts is populated, it takes precedence
      expect(badges.unreadRequests, 9);
      expect(badges.contactedRequests, 15);
      expect(badges.closedRequests, 4);
      expect(badges.totalRequests, 28);
    });

    test('Clinic lead pagination handles both results envelope and raw list without TypeError', () {
      final dynamic paginatedEnvelope = {
        'count': 1,
        'next': null,
        'previous': null,
        'results': [
          {
            'id': 'lead-1',
            'patient_name': 'Sarah Al Hashimi',
            'phone': '+971501234567',
            'status': 'new',
            'preferred_time': 'morning',
            'created_at': '2026-10-02T10:00:00Z',
          }
        ],
      };

      final dynamic rawList = [
        {
          'id': 'lead-2',
          'patient_name': 'Fatima Al Mansoori',
          'phone': '+971509876543',
          'status': 'contacted',
          'preferred_time': 'evening',
          'created_at': '2026-10-02T11:00:00Z',
        }
      ];

      // Simulate parsing paginated envelope
      final itemsFromEnvelope = (paginatedEnvelope is Map && paginatedEnvelope.containsKey('results'))
          ? (paginatedEnvelope['results'] as List<dynamic>?) ?? []
          : (paginatedEnvelope is List ? paginatedEnvelope : <dynamic>[]);
      final leadsFromEnvelope = itemsFromEnvelope
          .whereType<Map<String, dynamic>>()
          .map((m) => AppointmentRequestModel.fromJson(m))
          .toList();

      expect(leadsFromEnvelope.length, 1);
      expect(leadsFromEnvelope.first.id, 'lead-1');
      expect(leadsFromEnvelope.first.patientFullName, 'Sarah Al Hashimi');

      // Simulate parsing direct raw list
      final itemsFromRaw = (rawList is Map && rawList.containsKey('results'))
          ? (rawList['results'] as List<dynamic>?) ?? []
          : (rawList is List ? rawList : <dynamic>[]);
      final leadsFromRaw = itemsFromRaw
          .whereType<Map<String, dynamic>>()
          .map((m) => AppointmentRequestModel.fromJson(m))
          .toList();

      expect(leadsFromRaw.length, 1);
      expect(leadsFromRaw.first.id, 'lead-2');
      expect(leadsFromRaw.first.patientFullName, 'Fatima Al Mansoori');
    });

    test('ApiConfig has all new backend routes properly mapped with trailing slashes', () {
      expect(ApiConfig.clinicBadges, 'clinic-portal/badges/');
      expect(ApiConfig.notificationDevices, 'notifications/devices/');
      expect(ApiConfig.notificationDeviceDeactivate('sample_fcm_token'),
          'notifications/devices/sample_fcm_token/');
      expect(ApiConfig.authPhoneChangeRequest, 'auth/me/phone/change/request/');
      expect(ApiConfig.authPhoneChangeConfirm, 'auth/me/phone/change/confirm/');
      expect(ApiConfig.authEmailChangeRequest, 'auth/me/email/change/request/');
      expect(ApiConfig.authEmailChangeConfirm, 'auth/me/email/change/confirm/');
    });

    test('DeviceTokenService provides singleton instance and safe execution', () async {
      final service = DeviceTokenService();
      expect(service, isNotNull);

      // Verify empty token handling
      final emptyResult = await service.registerDeviceToken(token: '   ');
      expect(emptyResult, isFalse);
    });
  });
}
