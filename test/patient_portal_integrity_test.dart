import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/features/auth/data/models/auth_models.dart';
import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/utils/clinic_location.dart';
import 'package:aesthetic_way/core/utils/maps_launcher.dart';
import 'package:aesthetic_way/core/utils/source_text.dart';
import 'package:aesthetic_way/features/appointment_lead/data/leads_repository.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/clinics/presentation/widgets/google_clinic_rating.dart';
import 'package:aesthetic_way/features/home/data/models/home_feed_model.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/products/presentation/widgets/brand_product_media.dart';
import 'package:aesthetic_way/features/referral/models/referral_model.dart';
import 'package:aesthetic_way/features/referral/services/referral_service.dart';
import 'support/patient_fixtures.dart';

class PatientRecordingClient implements ApiClient {
  PatientRecordingClient({this.response, this.failure});
  final Object? response;
  final Object? failure;
  final List<Map<String, dynamic>> posts = [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    posts.add(Map<String, dynamic>.from(data as Map));
    if (failure != null) throw failure!;
    return Response<T>(
      data: response as T?,
      statusCode: 201,
      requestOptions: RequestOptions(path: path),
    );
  }
}

void main() {
  setUp(() {
    LocaleService().setLanguage(AppLanguage.english);
  });
  tearDown(() {
    ReferralService().resetTestingState();
  });
  test(
    'Missing or cross-role identity is never treated as a patient session',
    () {
      expect(UserModel.fromJson({}).isPatient, isFalse);
      for (final role in [
        '',
        'clinic_admin',
        'super_admin',
        'clinic_staff',
        'unknown',
      ]) {
        AuthState().login(name: 'Fixture', phone: '+971501234567', role: role);
        expect(AuthState().isPatient, isFalse);
      }
      AuthState().login(
        name: 'Fixture',
        phone: '+971501234567',
        role: 'patient',
      );
      expect(AuthState().isPatient, isTrue);
    },
  );
  test(
    'Missing fields never manufacture Google data, hours, city or verification',
    () {
      final clinic = ClinicModel.fromJson({
        'rating': 4.9,
        'review_count': 123,
        'is_featured': true,
      });
      expect(clinic.rating, 0);
      expect(clinic.reviewCount, 0);
      expect(clinic.workingHoursEn, isEmpty);
      expect(clinic.workingHoursAr, isEmpty);
      expect(clinic.isVerified, isFalse);
      expect(clinic.city, isEmpty);
      expect(clinic.subscriptionTier, SubscriptionTier.basic);
      expect(clinic.mainPhone, isEmpty);
      expect(clinic.hasMapLocation, isFalse);
    },
  );
  test(
    'Missing localization uses actual other-language text without rewriting CMS content',
    () {
      expect(
        ClinicModel.fromJson({
          'name_ar': '',
          'name_en': 'Source Clinic',
        }).nameAr,
        'Source Clinic',
      );
      expect(
        ClinicModel.fromJson({'name_en': '', 'name_ar': 'عيادة المصدر'}).nameEn,
        'عيادة المصدر',
      );
      expect(
        ProductModel.fromJson({
          'name_en': '',
          'name_ar': 'سيروم المصدر',
        }).nameEn,
        'سيروم المصدر',
      );
      expect(
        firstSourceText(['', '  unchanged CMS text  ']),
        '  unchanged CMS text  ',
      );
    },
  );
  test('Google numeric validity and review-count semantics', () {
    for (final value in [0, -1, 5.1, 'NaN', 'Infinity', 'garbage']) {
      expect(
        ClinicModel.fromJson({
          'google_place_id': 'fixture-place-id',
          'google_rating': value,
          'google_reviews_count': 10,
        }).hasGoogleRating,
        isFalse,
      );
    }
    for (final count in [0, -1, 1.5, 'invalid', true]) {
      expect(
        ClinicModel.fromJson({
          'google_place_id': 'fixture-place-id',
          'google_rating': 4.8,
          'google_reviews_count': count,
        }).hasGoogleRating,
        isFalse,
      );
    }
    final clinic = ClinicModel.fromJson({
      'google_place_id': 'fixture-place-id',
      'google_rating': '4.8',
      'google_reviews_count': '127',
    });
    expect(clinic.hasGoogleRating, isTrue);
    expect(clinic.googleReviewsCount, 127);
    expect(ClinicModel.fromJson({'google_rating': 4.8}).googleReviewsCount, 0);
  });
  test('Tier is independent of featured and verification flags', () {
    for (final tier in ['vip', 'VIP', 'featured', 'Featured', 'basic']) {
      final clinic = ClinicModel.fromJson({
        'subscription_tier': tier,
        'is_featured': false,
        'is_verified': false,
      });
      expect(clinic.subscriptionTier.apiValue, tier.toLowerCase());
      expect(clinic.isVerified, isFalse);
    }
    expect(
      ClinicModel.fromJson({
        'subscription_tier': 'unknown',
        'is_featured': true,
      }).isEligibleForTopCarousel,
      isFalse,
    );
  });
  test('Only known practitioner metadata is treated as known', () {
    final unknown = PractitionerModel.fromJson({});
    expect(unknown.hasKnownType, isFalse);
    expect(unknown.rating, 0);
    expect(unknown.yearsOfExperience, 0);
    expect(unknown.languages, isEmpty);
    expect(unknown.specialtyEn, isEmpty);
    for (final type in ['doctor', 'nurse', 'licensed_professional']) {
      expect(PractitionerModel.fromJson({'type': type}).type.value, type);
      expect(PractitionerModel.fromJson({'type': type}).hasKnownType, isTrue);
    }
  });
  test(
    'Maps require a genuine Google destination or finite valid coordinates',
    () {
      expect(verifiedGoogleMapsUri('https://evil.example/maps'), isNull);
      expect(ClinicCoordinates.parse(double.nan, 55), isNull);
      expect(ClinicCoordinates.parse(0, 0), isNull);
      expect(ClinicCoordinates.parse(91, 55), isNull);
      expect(
        MapsLauncher.verifiedPlaceUri(
          placeId: 'ChIJ-fixture',
        )!.queryParameters['query_place_id'],
        'ChIJ-fixture',
      );
      expect(
        patientClinic(extra: {'latitude': 25.2, 'longitude': 55.3}).mapsUri,
        isNotNull,
      );
    },
  );
  for (final hasRating in [true, false]) {
    for (final hasMap in [true, false]) {
      testWidgets('Google badge rating=$hasRating map=$hasMap stays truthful', (
        tester,
      ) async {
        final clinic = patientClinic(
          extra: {
            if (hasRating) 'google_place_id': 'fixture-place-id',
            if (hasRating) 'google_rating': 4.7,
            if (hasRating) 'google_reviews_count': 56,
            if (hasMap)
              'google_maps_url': 'https://maps.google.com/?cid=fixture',
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: GoogleClinicRating(clinic: clinic)),
          ),
        );
        expect(find.text('Google'), hasRating ? findsOneWidget : findsNothing);
        expect(find.text('4.7'), hasRating ? findsOneWidget : findsNothing);
        expect(find.byType(InkWell), hasRating ? findsOneWidget : findsNothing);
        expect(find.textContaining('New on Google'), findsNothing);
      });
    }
  }
  test(
    'Featured ads retain verified nested clinic/media and paid ad ordering',
    () {
      final feed = HomeFeedModel.fromJson({
        'featured_ads': [
          {
            'id': 'ad',
            'subscription_tier': 'Featured',
            'clinic': {'id': patientClinicId, 'is_featured': false},
            'image_url': '',
            'image': '/media/ad.png',
            'video_url': '/media/reel.mp4',
          },
        ],
        'nearby_clinics': [
          {'id': patientClinicId, 'is_featured': true},
        ],
      });
      expect(
        feed.featuredAds.single.clinic!.subscriptionTier,
        SubscriptionTier.basic,
      );
      expect(feed.featuredAds.single.isSponsored, isTrue);
      expect(feed.featuredAds.single.image, endsWith('/media/ad.png'));
      expect(feed.featuredAds.single.clinic!.coverImageUrl, isEmpty);
      expect(feed.featuredAds.single.videoUrl, endsWith('/media/reel.mp4'));
      expect(feed.nearbyClinics.single.isEligibleForTopCarousel, isFalse);
    },
  );
  test('Brand identity never falls back to the advertising clinic', () {
    final product = ProductModel.fromJson({
      'clinic': {'name_en': 'Clinic identity'},
      'name_en': 'Serum',
    });
    expect(productBrandLabel(product, LocaleService()), isEmpty);
    expect(
      productBrandLabel(
        product.copyWith(sponsorCompany: 'Actual sponsor'),
        LocaleService(),
      ),
      'Actual sponsor',
    );
  });
  test('Only authentic returned invite links are accepted', () {
    expect(
      PatientReferralStatusModel.fromJson({
        'referral_code': 'hardcoded',
      }).inviteLink,
      isEmpty,
    );
    for (final link in [
      'http://aestheticway.ae/invite/a',
      'https://evil.example/invite/a',
      'https://aestheticway.ae/invite/',
      'https://aestheticway.ae/invite/a?token=x',
      'https://aestheticway.ae/invite/a/b',
    ]) {
      expect(authenticInviteLink(link), isNull);
    }
    expect(
      patientReferralStatus().inviteLink,
      'https://aestheticway.ae/invite/fixture-token',
    );
    ReferralService().resetTestingState();
    expect(ReferralService().inviteLink, isEmpty);
    ReferralService().enableMockMode(
      testStatus: patientReferralStatus(invites: 35, points: 625),
    );
    expect(ReferralService().currentPoints, 625);
    expect(ReferralService().isMilestoneAwarded(35), isTrue);
    expect(ReferralService().isMilestoneAwarded(50), isFalse);
  });
  test('Placeholder clinic IDs are rejected before any API call', () async {
    final client = PatientRecordingClient();
    await expectLater(
      LeadsRepository(apiClient: client).createLead({'clinic': 'clinic-id'}),
      throwsA(isA<ApiException>()),
    );
    expect(client.posts, isEmpty);
  });
  test(
    'Unconfirmed and failed responses cannot produce synthetic success',
    () async {
      for (final response in [
        {'success': false},
        {'success': true},
      ]) {
        final client = PatientRecordingClient(response: response);
        await expectLater(
          LeadsRepository(
            apiClient: client,
          ).createLead({'clinic': patientClinicId}),
          throwsA(isA<ApiException>()),
        );
      }
      final client = PatientRecordingClient(
        failure: const ApiException(
          message: 'offline',
          errorCode: 'CONNECTION_ERROR',
        ),
      );
      await expectLater(
        LeadsRepository(
          apiClient: client,
        ).createLead({'clinic': patientClinicId}),
        throwsA(isA<ApiException>()),
      );
    },
  );
  test(
    'Independent product inquiry sends no fabricated clinic relationship',
    () async {
      final client = PatientRecordingClient(
        response: {
          'success': true,
          'lead_reference': 'FIXTURE-1',
          'created_at': '2026-10-20T12:00:00Z',
        },
      );
      final result = await LeadsRepository(apiClient: client).createLead({
        'product': patientOfferId,
        'lead_type': 'product_inquiry',
        'consent_accepted': true,
      });
      expect(result.success, isTrue);
      expect(client.posts.single.containsKey('clinic'), isFalse);
    },
  );
  testWidgets(
    'Inquiry payload keeps actual offer, international prefix and consent; double tap submits once',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      AuthState().login(name: 'Fixture Patient', phone: '+447700900123');
      final repo = FixtureLeadsRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: AppointmentRequestScreen(
            clinic: patientClinic(),
            selectedOfferId: patientOfferId,
            selectedOfferTitle: 'Fixture offer',
            leadsRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('+44'), findsOneWidget);
      await tester.tap(find.byType(Checkbox));
      final submit = find.text(LocaleService().tr('submit_lead_btn'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.tap(submit, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(repo.calls, 1);
      expect(repo.lastPayload!['clinic'], patientClinicId);
      expect(repo.lastPayload!['offer'], patientOfferId);
      expect(repo.lastPayload!['lead_type'], 'offer');
      expect(repo.lastPayload!['patient_phone'], '+447700900123');
      expect(repo.lastPayload!['consent_accepted'], isTrue);
      expect(repo.lastPayload!.containsKey('preferred_time_window'), isFalse);
      expect(find.text('تم إرسال طلبك وستتواصل العيادة معك'), findsOneWidget);
    },
  );
  test(
    'Changing a paged query clears records from the old filter even on failure',
    () async {
      var fail = false;
      final page = PagedCollection<String>(
        keyOf: (s) => s,
        loader: (_, q) async {
          if (fail) throw const ApiException(message: 'unavailable');
          return PageItems(['Dubai record'], hasMore: false);
        },
      );
      await page.refresh(query: {'city': 'Dubai'});
      expect(page.items, ['Dubai record']);
      fail = true;
      await page.refresh(query: {'city': 'Abu Dhabi'});
      expect(page.items, isEmpty);
      expect(page.error, 'unavailable');
      page.dispose();
    },
  );
}
