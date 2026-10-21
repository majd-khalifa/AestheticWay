import 'package:aesthetic_way/features/navigation/main_nav_screen.dart';
import 'support/settle_preview_images.dart';
import 'package:aesthetic_way/core/widgets/async_action_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
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
bool populated = true;
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
  final clinic = {...previewClinic, if (!populated) 'cover_image': ''};
  final offer = {..._offer, 'clinic': clinic, if (!populated) 'image_url': ''};
  final product = {
    ..._product,
    if (populated)
      'image_url': File(
        'test/fixtures/media/packaging_fixture.png',
      ).absolute.uri.toString(),
  };
  final practitioner = {
    ..._practitioner,
    'clinic': clinic,
    if (populated)
      'avatar_url': File(
        'test/fixtures/media/portrait_frame_fixture.png',
      ).absolute.uri.toString(),
  };
  if (path == 'home/feed/') {
    return {
      'featured_ads': [
        {
          'id': 'ad-1',
          'subscription_tier': 'VIP',
          'clinic': clinic,
          'image_url': populated ? _photo : '',
        },
      ],
      'nearby_clinics': [clinic],
      'active_offers': [offer],
      'categories': [],
    };
  }
  if (path == 'clinics/$previewClinicId/') return clinic;
  return {
    'count': 1,
    'next': null,
    'results': switch (path) {
      'clinics/' => [clinic],
      'products/' => [product],
      'offers/' => [offer],
      'practitioners/' => [practitioner],
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
  for (final media in [true, false]) {
    for (final dark in [false, true]) {
      for (final arabic in [false, true]) {
        // Full English matrix, plus representative dark Arabic RTL for every screen.
        if (arabic && !dark) continue;
        for (final screen in [
          'home',
          'directory',
          'clinic',
          'products',
          'offers',
          'practitioners',
          'busy',
        ]) {
          final name =
              '${screen}_${media ? 'media' : 'absent'}_${dark ? 'dark' : 'light'}_${arabic ? 'ar' : 'en'}';
          final entry = (
            name,
            dark,
            arabic,
            () => switch (screen) {
              'home' => const MainNavScreen(),
              'directory' => const MainNavScreen(initialIndex: 1),
              'clinic' => ClinicProfileScreen(
                clinic: ClinicModel.fromJson({
                  ...previewClinic,
                  if (!media) 'cover_image': '',
                }),
              ),
              'products' => const MainNavScreen(initialIndex: 2),
              'offers' => const MainNavScreen(initialIndex: 3),
              'practitioners' => const PractitionersScreen(),
              _ => _ConsultationBusyPreview(),
            },
          );
          testWidgets('Media-first preview ${entry.$1}', (tester) async {
            populated = media;
            // FileImage IO must start outside WidgetTester's fake async zone.
            // Warm the exact bounded decoder keys; assertions below still await
            // real decoded frames and reject unreadable fixtures.
            if (media) {
              await tester.runAsync(() async {
                final providers = [
                  boundedImageDecode(
                    (348.6 * tester.view.devicePixelRatio).round(),
                    FileImage(
                      File(
                        'test/fixtures/media/packaging_fixture.png',
                      ).absolute,
                    ),
                    maxHeight: (360 * tester.view.devicePixelRatio).round(),
                  ),
                  boundedImageDecode(
                    (90 * tester.view.devicePixelRatio).round().clamp(
                      100,
                      1080,
                    ),
                    FileImage(
                      File(
                        'test/fixtures/media/portrait_frame_fixture.png',
                      ).absolute,
                    ),
                  ),
                ];
                for (final provider in providers) {
                  final ready = Completer<void>();
                  final stream = provider.resolve(ImageConfiguration.empty);
                  late ImageStreamListener listener;
                  listener = ImageStreamListener(
                    (_, _) {
                      if (!ready.isCompleted) ready.complete();
                    },
                    onError: (Object e, StackTrace? stack) {
                      if (!ready.isCompleted) ready.completeError(e, stack);
                    },
                  );
                  stream.addListener(listener);
                  try {
                    await ready.future;
                  } finally {
                    stream.removeListener(listener);
                  }
                }
              });
            }
            tester.view.physicalSize = const Size(1170, 2532);
            addTearDown(tester.view.resetPhysicalSize);
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
                    titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
                      fontFamily: 'PatientPreview',
                    ),
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
            await settlePreviewImages(tester);
            if (screen == 'busy') {
              await tester.tap(find.byType(FilledButton).first);
              await tester.pump(const Duration(milliseconds: 100));
              await tester.pump(const Duration(milliseconds: 300));
              expect(find.byType(CircularProgressIndicator), findsOneWidget);
            }
            expect(tester.takeException(), isNull);
            const output = String.fromEnvironment('MEDIA_FIRST_CAPTURE_DIR');
            if (output.isNotEmpty) {
              await expectLater(
                find.byKey(const ValueKey('capture')),
                matchesGoldenFile(Uri.file('$output/${entry.$1}.png')),
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
