import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/features/admin/models/admin_dashboard_model.dart';
import 'package:aesthetic_way/features/admin/models/admin_clinic_model.dart';
import 'package:aesthetic_way/features/admin/models/admin_lead_model.dart';
import 'package:aesthetic_way/features/admin/models/admin_analytics_model.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/core/network/api_config.dart';

void main() {
  group('Admin Portal API Domain Models Serialization Tests', () {
    test('AdminDashboardModel deserializes accurately from real backend schema', () {
      final json = {
        'total_clinics': 12,
        'active_clinics': 10,
        'suspended_clinics': 2,
        'total_leads': 245,
        'scheduled_leads': 45,
        'completed_leads': 55,
        'total_patients': 1420,
        'total_offers': 18,
        'total_analytics_events': 32400,
        'leads_by_status': {
          'new': 30,
          'contacted': 115,
          'closed': 55,
        },
      };

      final model = AdminDashboardModel.fromJson(json);
      expect(model.totalClinics, equals(12));
      expect(model.activeClinics, equals(10));
      expect(model.suspendedClinics, equals(2));
      expect(model.totalLeads, equals(245));
      expect(model.scheduledLeads, equals(45));
      expect(model.completedLeads, equals(55));
      expect(model.totalPatients, equals(1420));
      expect(model.totalOffers, equals(18));
      expect(model.totalAnalyticsEvents, equals(32400));
      expect(model.leadsByStatus['new'], equals(30));
      expect(model.leadsByStatus['contacted'], equals(115));
    });

    test('AdminClinicModel deserializes correctly with branches, tiers and status', () {
      final json = {
        'id': 'c0a80123-4567-89ab-cdef-0123456789ab',
        'name_en': 'Elite Aesthetic Clinic',
        'name_ar': 'عيادة إيليت التجميلية',
        'slug': 'elite-aesthetic-clinic',
        'city': 'Dubai',
        'emirate': 'Dubai',
        'status': 'active',
        'subscription_tier': 'vip',
        'is_active': true,
        'is_featured': true,
        'display_order': 1,
        'phone': '+97143000000',
        'whatsapp': '+971501112233',
        'email': 'info@eliteclinic.ae',
        'logo': 'https://example.com/logo.png',
        'cover_image': 'https://example.com/cover.png',
        'branches_count': 2,
        'practitioners_count': 6,
        'treatments_count': 24,
        'offers_count': 4,
        'leads_count': 82,
        'branches': [
          {
            'id': 'b1',
            'name_en': 'Jumeirah Branch',
            'name_ar': 'فرع جميرا',
            'address_en': 'Al Wasl Road',
            'city': 'Dubai',
            'phone': '+97143000001',
            'is_main_branch': true,
            'is_active': true,
            'latitude': 25.1972,
            'longitude': 55.2744,
          }
        ],
        'leads_by_status': {
          'new': 12,
          'contacted': 45,
          'closed': 25,
        },
      };

      final clinic = AdminClinicModel.fromJson(json);
      expect(clinic.id, equals('c0a80123-4567-89ab-cdef-0123456789ab'));
      expect(clinic.nameEn, equals('Elite Aesthetic Clinic'));
      expect(clinic.nameAr, equals('عيادة إيليت التجميلية'));
      expect(clinic.subscriptionTier, equals(SubscriptionTier.vipPlatinum));
      expect(clinic.isActive, isTrue);
      expect(clinic.isSuspended, isFalse);
      expect(clinic.branchesCount, equals(2));
      expect(clinic.practitionersCount, equals(6));
      expect(clinic.treatmentsCount, equals(24));
      expect(clinic.leadsCount, equals(82));
      expect(clinic.branches.length, equals(1));
      expect(clinic.branches.first.latitude, closeTo(25.1972, 0.0001));
      expect(clinic.branches.first.longitude, closeTo(55.2744, 0.0001));
      expect(clinic.leadsByStatus['new'], equals(12));
    });

    test('AdminLeadModel deserializes strictly read-only supervision lead', () {
      final json = {
        'id': 'lead-98765',
        'reference_code': 'AW-2026-9876',
        'status': 'new',
        'lead_type': 'consultation',
        'service_name': 'Hydrafacial Elite Treatment',
        'clinic': {
          'id': 'clinic-01',
          'name_en': 'Silk Touch Dermatology',
          'name_ar': 'سيلك تاتش للجلدية',
          'city': 'Abu Dhabi',
          'phone': '+97125550000',
        },
        'branch': {
          'id': 'br-01',
          'name_en': 'Corniche Branch',
        },
        'practitioner': {
          'id': 'dr-01',
          'name_en': 'Dr. Layla',
        },
        'patient_name': 'Reem Al Falasi',
        'patient_phone': '+971509988776',
        'patient_email': 'reem@example.ae',
        'preferred_time_window': 'afternoon',
        'notes': 'Looking for consultation on acne scarring treatment',
        'consent_accepted': true,
        'created_at': '2026-09-20T10:30:00Z',
      };

      final lead = AdminLeadModel.fromJson(json);
      expect(lead.id, equals('lead-98765'));
      expect(lead.referenceCode, equals('AW-2026-9876'));
      expect(lead.status, equals('new'));
      expect(lead.clinicNameAr, equals('سيلك تاتش للجلدية'));
      expect(lead.clinicCity, equals('Abu Dhabi'));
      expect(lead.patientName, equals('Reem Al Falasi'));
      expect(lead.patientPhone, equals('+971509988776'));
      expect(lead.patientEmail, equals('reem@example.ae'));
      expect(lead.preferredTimeWindow, equals('afternoon'));
      expect(lead.consentAccepted, isTrue);
      expect(lead.createdAt.year, equals(2026));
    });

    test('AdminAnalyticsModel deserializes aggregates and clinic engagement list', () {
      final json = {
        'date_from': '2026-09-01',
        'date_to': '2026-09-20',
        'total_events': 15200,
        'app_opens': 4300,
        'clinic_views': 8600,
        'whatsapp_taps': 520,
        'call_taps': 380,
        'maps_taps': 240,
        'lead_submissions': 160,
        'clinic_engagement': [
          {
            'clinic_id': 'clinic-1',
            'clinic_name': 'Kaya Clinic',
            'events_count': 640,
            'views': 450,
            'whatsapp_taps': 65,
            'call_taps': 45,
            'leads_count': 32,
          }
        ]
      };

      final analytics = AdminAnalyticsModel.fromJson(json);
      expect(analytics.totalEvents, equals(15200));
      expect(analytics.appOpens, equals(4300));
      expect(analytics.clinicViews, equals(8600));
      expect(analytics.whatsappTaps, equals(520));
      expect(analytics.callTaps, equals(380));
      expect(analytics.mapsTaps, equals(240));
      expect(analytics.leadSubmissions, equals(160));
      expect(analytics.clinicEngagement.length, equals(1));

      final entry = analytics.clinicEngagement.first;
      expect(entry.clinicId, equals('clinic-1'));
      expect(entry.clinicName, equals('Kaya Clinic'));
      expect(entry.views, equals(450));
      expect(entry.whatsappTaps, equals(65));
      expect(entry.callTaps, equals(45));
      expect(entry.leads, equals(32));
      expect(entry.totalDirectEngagement, equals(65 + 45 + 32));
    });
  });

  group('Admin Portal Endpoint Contracts & Boundaries', () {
    test('ApiConfig contains all Super Admin endpoint constants with correct REST paths', () {
      expect(ApiConfig.adminDashboard, equals('admin/dashboard/'));
      expect(ApiConfig.adminClinics, equals('admin/clinics/'));
      expect(ApiConfig.adminClinicDetail('123'), equals('admin/clinics/123/'));
      expect(ApiConfig.adminClinicSuspend('123'), equals('admin/clinics/123/suspend/'));
      expect(ApiConfig.adminClinicActivate('123'), equals('admin/clinics/123/activate/'));
      expect(ApiConfig.adminClinicVerify('123'), equals('admin/clinics/123/verify/'));
      expect(ApiConfig.adminLeads, equals('admin/leads/'));
      expect(ApiConfig.adminLeadDetail('456'), equals('admin/leads/456/'));
      expect(ApiConfig.adminOffers, equals('admin/offers/'));
      expect(ApiConfig.adminOfferDetail('789'), equals('admin/offers/789/'));
      expect(ApiConfig.adminOfferApprove('789'), equals('admin/offers/789/approve/'));
      expect(ApiConfig.adminOfferReject('789'), equals('admin/offers/789/reject/'));
      expect(ApiConfig.adminOfferSuspend('789'), equals('admin/offers/789/suspend/'));
      expect(ApiConfig.adminOfferRestore('789'), equals('admin/offers/789/restore/'));
      expect(ApiConfig.adminProducts, equals('admin/products/'));
      expect(ApiConfig.adminProductDetail('prod-1'), equals('admin/products/prod-1/'));
      expect(ApiConfig.adminProductApprove('prod-1'), equals('admin/products/prod-1/approve/'));
      expect(ApiConfig.adminProductSuspend('prod-1'), equals('admin/products/prod-1/suspend/'));
      expect(ApiConfig.adminArticles, equals('admin/articles/'));
      expect(ApiConfig.adminArticleDetail('art-1'), equals('admin/articles/art-1/'));
      expect(ApiConfig.adminArticleApprove('art-1'), equals('admin/articles/art-1/approve/'));
      expect(ApiConfig.adminArticleSuspend('art-1'), equals('admin/articles/art-1/suspend/'));
      expect(ApiConfig.adminAnalytics, equals('admin/analytics/'));
      expect(ApiConfig.adminSettings, equals('admin/settings/'));
    });
  });
}
