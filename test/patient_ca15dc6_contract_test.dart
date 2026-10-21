import 'package:aesthetic_way/features/clinics/presentation/screens/clinic_profile_screen.dart';
import 'package:aesthetic_way/features/offers/data/offers_repository.dart';
import 'dart:io';
import 'package:aesthetic_way/core/theme/app_theme.dart';
import 'package:aesthetic_way/core/theme/patient_design.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/features/practitioners/presentation/widgets/patient_practitioner_card.dart';
// Response-shaped fixtures from ca15dc6's public serializers. These tests prove
// Flutter compatibility and rendering, not the running server or Google sync.
import 'dart:async';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/articles/models/article_model.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/clinics/data/clinics_repository.dart';
import 'package:aesthetic_way/features/clinics/presentation/widgets/patient_clinic_gallery.dart';
import 'package:aesthetic_way/features/home/data/models/home_feed_model.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/practitioners/data/practitioners_repository.dart';
import 'package:aesthetic_way/features/practitioners/presentation/screens/practitioners_screen.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/patient_fixtures.dart';
import 'support/settle_preview_images.dart';

const _cdn = 'https://cdn.example.invalid';
const _staffId = '44444444-4444-4444-8444-444444444444';

class _Staff extends PractitionersRepository {
  @override
  Future<List<PractitionerModel>> getPractitioners({
    String? clinicId,
    String? city,
    String? type,
    String? types,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async => PageItems([
    PractitionerModel.fromJson({
      'id': _staffId,
      'name_en': 'Test practitioner',
      'type': 'doctor',
      'clinic': {'id': patientClinicId, 'name_en': 'Test clinic'},
    }),
  ], hasMore: false);
}

class _DelayedClinic extends ClinicsRepository {
  int calls = 0;
  final pending = Completer<ClinicModel>();
  @override
  Future<ClinicModel> getClinicDetail(String idOrSlug) {
    calls++;
    return pending.future;
  }
}

class _PreviewOffers extends OffersRepository {
  int calls = 0;
  @override
  Future<List<OfferModel>> getOffers({
    String? clinicId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    calls++;
    expect(clinicId, patientClinicId);
    expect(page, 1);
    expect(pageSize, 20);
    return PageItems([
      OfferModel.fromJson({
        'id': patientOfferId,
        'title_en': 'Test offer',
        'clinic': {'id': patientClinicId, 'name_en': 'Test clinic'},
      }),
    ], hasMore: false);
  }
}

void main() {
  test('ca15dc6 clinic gallery remains independent of logo and cover', () {
    final clinic = patientClinic(
      extra: {
        'logo': '$_cdn/logo.png',
        'cover_image': '$_cdn/cover.jpg',
        'gallery_images': ['$_cdn/reception.jpg', '$_cdn/interior.jpg'],
        'video_url': '$_cdn/video.mp4',
        'video_ad_file': '$_cdn/video.mp4',
      },
    );
    expect(clinic.logoUrl, '$_cdn/logo.png');
    expect(clinic.coverImageUrl, '$_cdn/cover.jpg');
    expect(clinic.galleryImages, ['$_cdn/reception.jpg', '$_cdn/interior.jpg']);
    expect(clinic.primaryPhotoUrl, '$_cdn/cover.jpg');
    expect(clinic.videoUrl, '$_cdn/video.mp4');
  });
  test(
    'ca15dc6 video-only ad has no fictitious poster; genuine poster wins',
    () {
      final video = FeaturedAdApiModel.fromJson({
        'id': 'ad',
        'media_type': 'video',
        'image_url': '',
        'image': null,
        'video_url': '$_cdn/ad.mp4',
        'subscription_tier': 'VIP',
      });
      expect(video.image, isEmpty);
      expect(video.videoUrl, '$_cdn/ad.mp4');
      final withPoster = FeaturedAdApiModel.fromJson({
        'id': 'ad',
        'media_type': 'video',
        'image_url': '$_cdn/poster.jpg',
        'image': '$_cdn/legacy.jpg',
        'video_url': '$_cdn/ad.mp4',
      });
      expect(withPoster.image, '$_cdn/poster.jpg');
      expect(withPoster.videoUrl, '$_cdn/ad.mp4');
    },
  );
  test(
    'ca15dc6 resolved catalog images take precedence over legacy strings',
    () {
      final product = ProductModel.fromJson({
        'image_url': '$_cdn/product.jpg',
        'image': '$_cdn/old.jpg',
        'brand_name_en': 'Supplied brand',
        'brand_name_ar': 'علامة',
        'sponsor_company': 'Supplied sponsor',
      });
      final offer = OfferModel.fromJson({
        'image_url': '$_cdn/offer.jpg',
        'image': '$_cdn/old.jpg',
      });
      final staff = PractitionerModel.fromJson({
        'avatar_url': '$_cdn/portrait.jpg',
        'avatar': '$_cdn/old.jpg',
      });
      final article = ArticleModel.fromJson({
        'cover_image_url': '$_cdn/editorial.jpg',
        'cover_image': '$_cdn/old.jpg',
        'author_practitioner': {
          'name_en': 'Supplied author',
          'avatar_url': '$_cdn/author.jpg',
        },
      });
      expect(product.imageUrl, '$_cdn/product.jpg');
      expect(product.brandNameEn, 'Supplied brand');
      expect(product.sponsorCompany, 'Supplied sponsor');
      expect(offer.imageUrl, '$_cdn/offer.jpg');
      expect(staff.avatarUrl, '$_cdn/portrait.jpg');
      expect(article.coverImageUrl, '$_cdn/editorial.jpg');
      expect(article.authorDoctorAvatar, '$_cdn/author.jpg');
    },
  );
  test(
    'Google aggregates come only from valid Google fields, never legacy rating',
    () {
      final clinic = patientClinic(
        extra: {
          'google_rating': '4.6',
          'google_reviews_count': 27,
          'google_place_id': 'source-place-id',
          'google_maps_url':
              'https://www.google.com/maps/search/?api=1&query=Dubai',
        },
      );
      expect(clinic.hasGoogleRating, isTrue);
      expect(clinic.googleRating, 4.6);
      expect(clinic.googleReviewsCount, 27);
      expect(clinic.googlePlaceId, 'source-place-id');
      expect(clinic.mapsUri?.host, 'www.google.com');
      for (final rating in [null, '', 'NaN', -1, 6]) {
        expect(
          patientClinic(
            extra: {
              'google_rating': rating,
              'google_reviews_count': 27,
              'rating': 5,
              'review_count': 999,
            },
          ).hasGoogleRating,
          isFalse,
        );
      }
    },
  );
  testWidgets(
    'Single decoded clinic photo has no redundant counter or thumbnails',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PatientClinicGallery(
              images: ['assets/images/onboarding/onboarding_1.jpeg'],
            ),
          ),
        ),
      );
      await settlePreviewImages(tester);
      expect(find.text('1/1'), findsNothing);
      expect(find.byIcon(Icons.photo_library_outlined), findsNothing);
      expect(find.byType(RawImage), findsWidgets);
      expect(
        tester
            .widgetList<RawImage>(find.byType(RawImage))
            .any((i) => i.image != null),
        isTrue,
      );
    },
  );
  testWidgets(
    'Staff directory consultation acknowledges immediately, suppresses duplicates and uses fetched clinic',
    (tester) async {
      unawaited(LocaleService().setLanguage(AppLanguage.english));
      AuthState().login(name: 'Test patient', phone: '+971501234567');
      final clinics = _DelayedClinic();
      await tester.pumpWidget(
        MaterialApp(
          home: PractitionersScreen(
            repository: _Staff(),
            clinicsRepository: clinics,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final request = find.text(LocaleService().tr('request_consultation'));
      await tester.tap(request);
      await tester.tap(request, warnIfMissed: false);
      await tester.pump();
      expect(find.text('Opening consultation'), findsOneWidget);
      expect(clinics.calls, 1);
      clinics.pending.complete(patientClinic());
      await tester.pumpAndSettle();
      expect(find.byType(AppointmentRequestScreen), findsOneWidget);
      final form = tester.widget<AppointmentRequestScreen>(
        find.byType(AppointmentRequestScreen),
      );
      expect(form.clinic.id, patientClinicId);
      expect(form.preselectedPractitioner?.id, _staffId);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    for (final dark in [false, true]) {
      for (final arabic in [false, true]) {
        testWidgets(
          'Decoded portrait composition $width dark=$dark rtl=$arabic at 160%',
          (tester) async {
            await tester.binding.setSurfaceSize(Size(width, 1000));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            unawaited(
              LocaleService().setLanguage(
                arabic ? AppLanguage.arabic : AppLanguage.english,
              ),
            );
            final photo = File(
              'test/fixtures/media/portrait_photo.png',
            ).absolute.uri.toString();
            final professional = PractitionerModel.fromJson({
              'name_en': 'Portrait layout fixture',
              'name_ar': 'اختبار تنسيق صورة المختص',
              'avatar_url': photo,
              'speciality_en': 'Supplied specialty',
              'speciality_ar': 'التخصص المقدم من العيادة',
              'clinic': {
                'name_en': 'Clinic fixture',
                'name_ar': 'عيادة الاختبار',
              },
            });
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.6)),
                  child: Directionality(
                    textDirection: arabic
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: child!,
                  ),
                ),
                home: PatientDesign(
                  builder: (context) => Scaffold(
                    body: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: PatientPractitionerCard(
                        practitioner: professional,
                        onTap: () {},
                        onInquiry: () {},
                      ),
                    ),
                  ),
                ),
              ),
            );
            await settlePreviewImages(tester);
            final portrait = find.byWidgetPredicate(
              (w) => w is LuxuryImage && w.imageUrl == photo,
            );
            final photoSize = tester.getSize(portrait);
            expect(photoSize.width, greaterThan(width * .3));
            expect(photoSize.height, greaterThanOrEqualTo(200));
            final frames = tester.widgetList<RawImage>(
              find.descendant(of: portrait, matching: find.byType(RawImage)),
            );
            expect(
              frames.any(
                (f) =>
                    f.image != null &&
                    f.image!.width > 1 &&
                    f.image!.height > 1,
              ),
              isTrue,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
  testWidgets(
    'Consultation context uses genuine gallery media when cover is absent',
    (tester) async {
      unawaited(LocaleService().setLanguage(AppLanguage.english));
      const photo = 'assets/images/onboarding/onboarding_1.jpeg';
      final clinic = patientClinic(
        extra: {
          'cover_image': null,
          'gallery_images': [photo],
        },
      );
      await tester.pumpWidget(
        MaterialApp(home: AppointmentRequestScreen(clinic: clinic)),
      );
      await settlePreviewImages(tester);
      final image = find.byWidgetPredicate(
        (w) => w is LuxuryImage && w.imageUrl == photo,
      );
      expect(image, findsOneWidget);
      expect(
        tester
            .widgetList<RawImage>(
              find.descendant(of: image, matching: find.byType(RawImage)),
            )
            .any((frame) => frame.image != null && frame.image!.width > 1),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'About offer preview remains lazy, bounded and shared with the Offers tab',
    (tester) async {
      unawaited(LocaleService().setLanguage(AppLanguage.english));
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final clinic = patientClinic(
        extra: {
          'cover_image': 'assets/images/onboarding/onboarding_1.jpeg',
          'description_en': List.filled(
            30,
            'Clinic-supplied description.',
          ).join(' '),
        },
      );
      final offers = _PreviewOffers();
      await tester.pumpWidget(
        MaterialApp(
          home: ClinicProfileScreen(
            clinic: clinic,
            clinicsRepository: FixtureClinicsRepository(clinic),
            offersRepository: offers,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(offers.calls, 0);
      await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(offers.calls, 1);
      expect(find.text('Test offer'), findsOneWidget);
      final tab = find.text(LocaleService().tr('tab_offers')).first;
      await tester.ensureVisible(tab);
      await tester.tap(tab);
      await tester.pumpAndSettle();
      expect(offers.calls, 1);
      expect(find.text('Test offer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final dark in [false, true]) {
    for (final arabic in [false, true]) {
      testWidgets(
        'Consultation CTA remains reachable above keyboard dark=$dark rtl=$arabic at 160%',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 700);
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          tester.view.viewPadding = const FakeViewPadding(bottom: 24);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetViewInsets);
          addTearDown(tester.view.resetViewPadding);
          final semantics = tester.ensureSemantics();

          unawaited(
            LocaleService().setLanguage(
              arabic ? AppLanguage.arabic : AppLanguage.english,
            ),
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.6),
                  disableAnimations: true,
                ),
                child: Directionality(
                  textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
                  child: child!,
                ),
              ),
              home: AppointmentRequestScreen(clinic: patientClinic()),
            ),
          );
          await tester.pumpAndSettle();
          final label = LocaleService().tr('submit_lead_btn');
          final button = find.ancestor(
            of: find.text(label),
            matching: find.byType(FilledButton),
          );
          await tester.scrollUntilVisible(
            button,
            240,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          final bounds = tester.getRect(button);
          expect(bounds.bottom, lessThanOrEqualTo(420));
          expect(bounds.top, greaterThanOrEqualTo(56));
          expect(
            tester.getSemantics(button).getSemanticsData().label,
            contains(label),
          );
          expect(tester.takeException(), isNull);
          semantics.dispose();
        },
      );
    }
  }
}
