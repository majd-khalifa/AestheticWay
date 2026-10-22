import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/features/articles/presentation/screens/articles_screen.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';
import 'package:aesthetic_way/features/profile/presentation/screens/profile_screen.dart';
import 'package:aesthetic_way/features/navigation/main_nav_screen.dart';
import 'support/settle_preview_images.dart';
import 'support/settle_expected_media_errors.dart';
import 'package:aesthetic_way/features/treatments/presentation/screens/treatments_screen.dart';
import 'package:aesthetic_way/core/widgets/async_action_button.dart';
// Synthetic test-only records. Photographs have provenance in fixtures/media/README.md;
// neither these records nor fixture photographs are supplied to production.
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/theme/app_theme.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinic_profile_screen.dart';
import 'package:aesthetic_way/features/practitioners/presentation/screens/practitioners_screen.dart';

const previewClinicId = '11111111-1111-4111-8111-111111111111';
bool populated = true;
bool failedMedia = false;
const premiumReview = bool.fromEnvironment('PREMIUM_PLACEHOLDER_REVIEW');
late File corruptPreview;
bool isCorrupt(ImageProvider provider) {
  if (provider is ResizeImage) return isCorrupt(provider.imageProvider);
  return provider is FileImage &&
      provider.file.absolute.uri == corruptPreview.absolute.uri;
}

Object? mediaState(Object? value, [String? field]) {
  const scalar = {
    'logo',
    'cover_image',
    'image_url',
    'avatar_url',
    'cover_image_url',
  };
  if (value is Map<String, dynamic>) {
    return value.map((k, v) => MapEntry(k, mediaState(v, k)));
  }
  if (field == 'gallery_images' && value is List) {
    return !populated
        ? <String>[]
        : value
              .map((v) => failedMedia ? corruptPreview.uri.toString() : v)
              .toList();
  }
  if (value is List) return value.map((v) => mediaState(v)).toList();
  if (scalar.contains(field) && value is String && value.isNotEmpty) {
    return !populated
        ? ''
        : failedMedia
        ? corruptPreview.uri.toString()
        : value;
  }
  return value;
}

Map<String, dynamic> clinicPreview() =>
    mediaState(previewClinic) as Map<String, dynamic>;
Object response(String path) => mediaState(_response(path))!;
const _photo = 'assets/images/onboarding/onboarding_1.jpeg';
final previewClinic = <String, dynamic>{
  'id': previewClinicId,
  'name_en': 'Sample Medical Aesthetics',
  'name_ar': 'عيادة نموذجية للتجميل الطبي',
  'subscription_tier': 'vip',
  'city': 'Dubai',
  'address_en': 'Jumeirah, Dubai',
  'address_ar': 'جميرا، دبي',
  'logo': 'assets/images/aesthetic_way_logo.png',
  'cover_image': _photo,
  'gallery_images': [_photo, 'assets/images/onboarding/onboarding_2.webp'],
  'google_place_id': 'preview-test-place-id',
  'google_rating': 4.7,
  'google_reviews_count': 125,
  'google_maps_url': 'https://www.google.com/maps/search/?api=1&query=Dubai',
  'description_en':
      'Clinic-provided information about dermatology and medical aesthetic consultations.',
  'description_ar':
      'معلومات تقدمها العيادة حول استشارات الأمراض الجلدية والتجميل الطبي.',
  'branches': <dynamic>[],
  'practitioners': <dynamic>[],
  'treatments': <dynamic>[],
};
final _offer = <String, dynamic>{
  'id': '22222222-2222-4222-8222-222222222222',
  'clinic': previewClinic,
  'title_en': 'Skin consultation',
  'title_ar': 'استشارة للبشرة',
  'description_en': 'Discuss your skin concerns with the clinic.',
  'description_ar': 'ناقش احتياجات بشرتك مع العيادة.',
  'image_url': File(
    'test/fixtures/media/portrait_photo.png',
  ).absolute.uri.toString(),
  'original_price': '600',
  'offer_price': '450',
};
final _product = <String, dynamic>{
  'id': '55555555-5555-4555-8555-555555555555',
  'name_en': 'Fragrance showcase',
  'name_ar': 'عرض عطر تجميلي',
  'brand_name_en': 'Sample Skincare',
  'brand_name_ar': 'علامة نموذجية للعناية',
  'sponsor_company': 'Sample Cosmetics',
  'description_en': 'Cosmetic brand showcase.',
  'description_ar': 'عرض علامة تجميل.',
};
final _practitioner = <String, dynamic>{
  'id': '44444444-4444-4444-8444-444444444444',
  'clinic': previewClinic,
  'type': 'doctor',
  'name_en': 'Sample Practitioner',
  'name_ar': 'ممارس نموذجي',
  'speciality_en': 'Dermatology',
  'speciality_ar': 'الأمراض الجلدية',
  'bio_en': 'Biography supplied by the clinic.',
  'bio_ar': 'سيرة تقدمها العيادة.',
};
Object _response(String path) {
  final clinic = {
    ...previewClinic,
    if (!populated) ...{
      'cover_image': '',
      'gallery_images': <String>[],
      'google_rating': null,
      'google_reviews_count': 0,
    },
  };
  final offer = {..._offer, 'clinic': clinic, if (!populated) 'image_url': ''};
  final product = {
    ..._product,
    if (populated)
      'image_url': File(
        'test/fixtures/media/fragrance_photo.jpg',
      ).absolute.uri.toString(),
  };
  final practitioner = {
    ..._practitioner,
    'clinic': clinic,
    if (populated)
      'avatar_url': File(
        'test/fixtures/media/portrait_photo.png',
      ).absolute.uri.toString(),
  };
  if (path == 'home/feed/') {
    return {
      'featured_ads': [
        {'id': 'ad-1', 'subscription_tier': 'VIP', 'clinic': clinic},
      ],
      'nearby_clinics': [clinic],
      'active_offers': [offer],
      'categories': [],
    };
  }
  if (path == 'clinics/$previewClinicId/') {
    return {
      ...clinic,
      'practitioners': [
        {
          for (final field in [
            'id',
            'name_en',
            'name_ar',
            'type',
            'speciality_en',
            'speciality_ar',
            'avatar_url',
          ])
            if (practitioner.containsKey(field)) field: practitioner[field],
        },
      ],
      'treatments': [
        {
          'id': '77777777-7777-4777-8777-777777777777',
          'name_en': 'Skin consultation',
          'name_ar': 'استشارة للبشرة',
          'image_url': populated ? _photo : '',
          'description_en': 'Discuss care options with the clinic.',
          'description_ar': 'ناقش خيارات العناية مع العيادة.',
          'category': null,
          'price': null,
        },
      ],
    };
  }
  if (path == 'auth/me/') {
    return {
      'id': 'fixture-patient',
      'full_name': 'Preview Patient',
      'role': 'patient',
      'phone': '+971501234567',
    };
  }
  return {
    'count': 1,
    'next': null,
    'results': switch (path) {
      'clinics/' => [clinic],
      'products/' => [product],
      'offers/' => [offer],
      'practitioners/' => [practitioner],
      'articles/' => [
        {
          'id': '66666666-6666-4666-8666-666666666666',
          'title_en': 'Understanding your skin consultation',
          'title_ar': 'تعرّف على استشارة البشرة',
          'content_en':
              'An editorial preview using synthetic test data. Learn what to discuss with a medical professional.',
          'content_ar':
              'معاينة تحريرية ببيانات اختبار اصطناعية. تعرّف على ما يمكنك مناقشته مع المختص الطبي.',
          'cover_image_url': populated
              ? File(
                  'test/fixtures/media/portrait_photo.png',
                ).absolute.uri.toString()
              : '',
          'clinic': clinic,
        },
      ],
      'treatments/' => [
        {
          'id': '77777777-7777-4777-8777-777777777777',
          'name_en': 'Skin consultation',
          'name_ar': 'استشارة للبشرة',
          'image_url': populated ? _photo : '',
          'description_en': 'Discuss care options with the clinic.',
          'description_ar': 'ناقش خيارات العناية مع العيادة.',
        },
      ],
      _ => [],
    },
  };
}

void main() {
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    // Keep the corrupt source immutable for the test process lifetime. Native
    // Windows may retain a mapped buffer until GC after codec failure.
    corruptPreview = File(
      'test/fixtures/media/intentionally_corrupt_image.fixture',
    ).absolute;
    final bytes = File('test/fixtures/fonts/DejaVuSans.ttf').readAsBytesSync();
    for (final family in ['PatientPreview', 'serif']) {
      await (FontLoader(
        family,
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
    for (final entry in {
      'PatientDisplay': 'PlayfairDisplay.ttf',
      'PatientArabic': 'NotoSansArabic.ttf',
    }.entries) {
      final data = ByteData.sublistView(
        File('assets/fonts/patient/${entry.value}').readAsBytesSync(),
      );
      await (FontLoader(entry.key)..addFont(Future.value(data))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    ApiClient().dio.interceptors.insert(
      0,
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: response(options.path),
            ),
          );
        },
      ),
    );
  });
  for (final state
      in premiumReview ? ['media', 'absent', 'failed'] : ['media', 'absent']) {
    final media = state == 'media';
    for (final width in premiumReview ? [390.0, 320.0] : [390.0]) {
      for (final dark in [false, true]) {
        for (final arabic in [false, true]) {
          // Full English matrix, plus representative dark Arabic RTL for every screen.
          if (arabic && !dark && !premiumReview) continue;
          for (final screen in [
            'home',
            'directory',
            'clinic',
            'products',
            'offers',
            'practitioners',
            'articles',
            'consultation',
            'profile',
            'clinic_staff',
            'clinic_treatments',
            'clinic_offers',
            'busy',
            if (premiumReview) 'treatments',
          ]) {
            final name =
                '${screen}_${state}_${dark ? 'dark' : 'light'}_${arabic ? 'ar' : 'en'}${width == 320 ? '_w320' : ''}';
            final entry = (
              name,
              dark,
              arabic,
              () => switch (screen) {
                'home' => const MainNavScreen(),
                'directory' => const MainNavScreen(initialIndex: 1),
                'clinic' => ClinicProfileScreen(
                  clinic: ClinicModel.fromJson({
                    ...clinicPreview(),
                    if (state == 'absent') ...{
                      'cover_image': '',
                      'gallery_images': <String>[],
                    },
                  }),
                ),
                'products' => const MainNavScreen(initialIndex: 2),
                'offers' => const MainNavScreen(initialIndex: 3),
                'practitioners' => const PractitionersScreen(),
                'articles' => const ArticlesScreen(),
                'treatments' => const TreatmentsScreen(),
                'profile' => ProfileScreen(onNavigateToRequests: () {}),
                'consultation' => AppointmentRequestScreen(
                  clinic: ClinicModel.fromJson({
                    ...clinicPreview(),
                    if (state == 'absent') ...{
                      'cover_image': '',
                      'gallery_images': <String>[],
                    },
                  }),
                ),
                'clinic_staff' ||
                'clinic_treatments' ||
                'clinic_offers' => ClinicProfileScreen(
                  clinic: ClinicModel.fromJson({
                    ...clinicPreview(),
                    if (state == 'absent') ...{
                      'cover_image': '',
                      'gallery_images': <String>[],
                    },
                  }),
                ),
                _ => _ConsultationBusyPreview(),
              },
            );
            testWidgets('Media-first preview ${entry.$1}', (tester) async {
              populated = state != 'absent';
              failedMedia = state == 'failed';
              AuthState().login(
                name: 'Preview Patient',
                phone: '+971501234567',
              );
              tester.view.devicePixelRatio = 3;
              addTearDown(tester.view.resetDevicePixelRatio);
              tester.view.physicalSize = Size(width * 3, 2532);
              addTearDown(tester.view.resetPhysicalSize);
              await tester.binding.setSurfaceSize(Size(width, 844));
              addTearDown(() => tester.binding.setSurfaceSize(null));
              unawaited(
                LocaleService().setLanguage(
                  entry.$3 ? AppLanguage.arabic : AppLanguage.english,
                ),
              );
              final theme = entry.$2 ? AppTheme.darkTheme : AppTheme.lightTheme;
              await tester.pumpWidget(
                MaterialApp(
                  theme: theme.copyWith(
                    platform: TargetPlatform.android,
                    visualDensity: VisualDensity.standard,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    textTheme: theme.textTheme.apply(
                      fontFamily: 'PatientPreview',
                    ),
                    elevatedButtonTheme: ElevatedButtonThemeData(
                      style: theme.elevatedButtonTheme.style?.copyWith(
                        textStyle: WidgetStatePropertyAll(
                          theme.elevatedButtonTheme.style?.textStyle
                              ?.resolve({})
                              ?.copyWith(fontFamily: 'PatientPreview'),
                        ),
                      ),
                    ),
                    outlinedButtonTheme: OutlinedButtonThemeData(
                      style: theme.outlinedButtonTheme.style?.copyWith(
                        textStyle: WidgetStatePropertyAll(
                          theme.outlinedButtonTheme.style?.textStyle
                              ?.resolve({})
                              ?.copyWith(fontFamily: 'PatientPreview'),
                        ),
                      ),
                    ),
                    appBarTheme: theme.appBarTheme.copyWith(
                      titleTextStyle: theme.appBarTheme.titleTextStyle
                          ?.copyWith(fontFamily: 'PatientPreview'),
                    ),
                  ),
                  home: Directionality(
                    textDirection: entry.$3
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: RepaintBoundary(
                      key: const ValueKey('capture'),
                      child: entry.$4(),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              if (failedMedia) {
                await settleExpectedMediaErrors(
                  tester,
                  isExpectedFailure: isCorrupt,
                );
              } else {
                await settlePreviewImages(tester);
              }
              if (screen.startsWith('clinic_')) {
                final key = screen == 'clinic_staff'
                    ? 'tab_staff'
                    : screen == 'clinic_treatments'
                    ? 'tab_treatments'
                    : 'tab_offers';
                await tester.ensureVisible(
                  find.text(LocaleService().tr(key)).first,
                );
                await tester.tap(find.text(LocaleService().tr(key)).first);
                await tester.pumpAndSettle();
                await tester.drag(
                  find.byType(ListView).first,
                  const Offset(0, -470),
                );
                await tester.pumpAndSettle();
                if (failedMedia) {
                  await settleExpectedMediaErrors(
                    tester,
                    isExpectedFailure: isCorrupt,
                  );
                } else {
                  await settlePreviewImages(tester);
                }
              }
              if (media &&
                  (screen == 'products' || screen == 'practitioners')) {
                final fixture = screen == 'products'
                    ? 'fragrance_photo.jpg'
                    : 'portrait_photo.png';
                final expected = File.fromUri(
                  File('test/fixtures/media/$fixture').absolute.uri,
                );
                final primary = find.byWidgetPredicate(
                  (widget) =>
                      widget is Image &&
                      widget.image is ResizeImage &&
                      (widget.image as ResizeImage).imageProvider
                          is FileImage &&
                      ((widget.image as ResizeImage).imageProvider as FileImage)
                              .file
                              .path ==
                          expected.path,
                );
                expect(
                  primary,
                  findsOneWidget,
                  reason:
                      'The actual file-URI fixture must render, not the brand fallback.',
                );
                final pixels = tester
                    .widget<RawImage>(
                      find.descendant(
                        of: primary,
                        matching: find.byType(RawImage),
                      ),
                    )
                    .image!;
                expect(pixels.width, greaterThan(0));
                expect(pixels.height, greaterThan(0));
              }
              if (screen == 'busy') {
                await tester.tap(find.byType(FilledButton).first);
                await tester.pump(const Duration(milliseconds: 100));
                await tester.pump(const Duration(milliseconds: 300));
                expect(find.byType(CircularProgressIndicator), findsOneWidget);
              }
              for (final tier in [
                'VIP',
                'FEATURED',
                'FEATURED CLINIC',
                'عيادة مميزة',
              ]) {
                expect(
                  find.text(tier),
                  findsNothing,
                  reason:
                      'Internal placement entitlement must never become a patient label.',
                );
              }
              expect(tester.takeException(), isNull);
              const output = String.fromEnvironment('MEDIA_FIRST_CAPTURE_DIR');
              if (output.isNotEmpty) {
                await expectLater(
                  find.byKey(const ValueKey('capture')),
                  matchesGoldenFile(Uri.file('$output/${entry.$1}.png')),
                );
              }
              if (output.isNotEmpty &&
                  (screen == 'home' ||
                      screen == 'consultation' ||
                      screen == 'profile' ||
                      screen == 'clinic')) {
                final scrollable = find.byType(Scrollable).first;
                await tester.drag(scrollable, const Offset(0, -540));
                await tester.pumpAndSettle();
                if (failedMedia) {
                  await settleExpectedMediaErrors(
                    tester,
                    isExpectedFailure: isCorrupt,
                  );
                } else {
                  await settlePreviewImages(tester);
                }
                await expectLater(
                  find.byKey(const ValueKey('capture')),
                  matchesGoldenFile(
                    Uri.file('$output/${entry.$1}_scrolled.png'),
                  ),
                );
              }
              await tester.pumpWidget(const SizedBox.shrink());
              busyCompletion?.complete();
              busyCompletion = null;
            });
          }
        }
      }
    }
  }
}

Completer<void>? busyCompletion;

class _ConsultationBusyPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        LocaleService().isArabic ? 'طلب استشارة' : 'Request consultation',
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            LocaleService().isArabic ? 'استشارة للبشرة' : 'Skin consultation',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            LocaleService().isArabic
                ? 'عيادة نموذجية · بيانات معاينة'
                : 'Sample clinic · Preview fixture',
          ),
          const SizedBox(height: 20),
          AsyncActionButton(
            label: LocaleService().tr('request_consultation'),
            loadingLabel: LocaleService().isArabic
                ? 'جارٍ تحميل العيادة'
                : 'Loading clinic',
            onPressed: (action) async {
              busyCompletion = Completer<void>();
              await action.wait(busyCompletion!.future);
            },
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              LocaleService().isArabic ? 'اكتشف العيادة' : 'Explore clinic',
            ),
          ),
        ],
      ),
    ),
  );
}
