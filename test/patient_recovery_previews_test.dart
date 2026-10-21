import 'package:aesthetic_way/features/navigation/main_nav_screen.dart';
import 'support/settle_preview_images.dart';
// Synthetic public data only. Photographic previews reuse the existing onboarding
// clinic image; this file never supplies media or invented records to production.
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
  'image_url': _photo,
  'original_price': '600',
  'offer_price': '450',
};
final _product = <String, dynamic>{
  'id': '55555555-5555-4555-8555-555555555555',
  'name_en': 'Daily hydration serum',
  'name_ar': 'سيروم الترطيب اليومي',
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
  if (path == 'home/feed/') {
    return {
      'featured_ads': [
        {
          'id': 'ad-1',
          'subscription_tier': 'VIP',
          'clinic': previewClinic,
          'image_url': _photo,
        },
      ],
      'nearby_clinics': [previewClinic],
      'active_offers': [_offer],
      'categories': [],
    };
  }
  if (path == 'clinics/$previewClinicId/') return previewClinic;
  return {
    'count': 1,
    'next': null,
    'results': switch (path) {
      'clinics/' => [previewClinic],
      'products/' => [_product],
      'offers/' => [_offer],
      'practitioners/' => [_practitioner],
      _ => [],
    },
  };
}

void main() {
  setUpAll(() async {
    final bytes = File('test/fixtures/fonts/DejaVuSans.ttf').readAsBytesSync();
    for (final family in ['PatientPreview', 'serif']) {
      await (FontLoader(
        family,
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
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
              data: _response(options.path),
            ),
          );
        },
      ),
    );
  });
  for (final entry in [
    ('home_light_en', false, false, () => const MainNavScreen()),
    ('home_dark_en', true, false, () => const MainNavScreen()),
    (
      'clinic_light_en',
      false,
      false,
      () => ClinicProfileScreen(clinic: ClinicModel.fromJson(previewClinic)),
    ),
    (
      'clinic_dark_ar',
      true,
      true,
      () => ClinicProfileScreen(clinic: ClinicModel.fromJson(previewClinic)),
    ),
    (
      'products_light_en',
      false,
      false,
      () => const MainNavScreen(initialIndex: 2),
    ),
    (
      'offers_light_en',
      false,
      false,
      () => const MainNavScreen(initialIndex: 3),
    ),
    ('practitioners_light_en', false, false, () => const PractitionersScreen()),
    (
      'directory_light_en',
      false,
      false,
      () => const MainNavScreen(initialIndex: 1),
    ),
  ]) {
    testWidgets('Recovery preview ${entry.$1}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
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
            textTheme: theme.textTheme.apply(fontFamily: 'PatientPreview'),
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
              titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
                fontFamily: 'PatientPreview',
              ),
            ),
          ),
          home: Directionality(
            textDirection: entry.$3 ? TextDirection.rtl : TextDirection.ltr,
            child: RepaintBoundary(
              key: const ValueKey('capture'),
              child: entry.$4(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await settlePreviewImages(tester);
      expect(tester.takeException(), isNull);
      const output = String.fromEnvironment('RECOVERY_CAPTURE_DIR');
      if (output.isNotEmpty) {
        await expectLater(
          find.byKey(const ValueKey('capture')),
          matchesGoldenFile(Uri.file('$output/${entry.$1}.png')),
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
