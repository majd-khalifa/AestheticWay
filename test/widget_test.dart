import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/main.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/theme/theme_service.dart';
import 'package:aesthetic_way/core/widgets/app_brand_logo.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/home/presentation/widgets/featured_ads_carousel.dart';
import 'package:aesthetic_way/features/home/presentation/widgets/home_header.dart';
import 'package:aesthetic_way/features/navigation/main_nav_screen.dart';

void main() {
  setUp(() {
    LocaleService().setLanguage(AppLanguage.english);
    ThemeService().setThemeMode(ThemeMode.light);
  });

  testWidgets('AestheticWayApp launches with default English (LTR), Light theme, prominent logo, and no Home heart icon', (WidgetTester tester) async {
    expect(LocaleService().currentLanguage, equals(AppLanguage.english));
    expect(LocaleService().textDirection, equals(TextDirection.ltr));
    expect(ThemeService().themeMode, equals(ThemeMode.light));
    expect(ThemeService().isLightMode, isTrue);

    await tester.pumpWidget(const AestheticWayApp(homeScreen: MainNavScreen()));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AppBrandLogo), findsWidgets);
    expect(find.text('Home'), findsOneWidget);

    // Verify HomeHeader does NOT show heart / favorites icon
    final headerFinder = find.byType(HomeHeader);
    expect(headerFinder, findsOneWidget);
    expect(
      find.descendant(of: headerFinder, matching: find.byIcon(Icons.favorite_border)),
      findsNothing,
    );
    expect(
      find.descendant(of: headerFinder, matching: find.byIcon(Icons.favorite)),
      findsNothing,
    );
  });

  testWidgets('FeaturedAdsCarousel supports image and 15s muted video slide with graceful fallback', (WidgetTester tester) async {
    final videoClinic = ClinicModel.fromJson({
      'id': 'vip-vid-1',
      'name_ar': 'عيادة إيليت دبي',
      'name_en': 'Elite Clinic Dubai',
      'city': 'Dubai',
      'address_ar': 'جميرا، دبي',
      'address_en': 'Jumeirah, Dubai',
      'subscription_tier': 'vip',
      'cover_image': 'https://aestheticway.ae/media/clinics/cover1.jpg',
      'video_url': 'https://aestheticway.ae/media/ads/vip_reel_15s.mp4',
      'media_type': 'video',
    });

    expect(videoClinic.hasVideoAd, isTrue);
    expect(videoClinic.mediaType, equals('video'));
    expect(videoClinic.videoUrl, equals('https://aestheticway.ae/media/ads/vip_reel_15s.mp4'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeaturedAdsCarousel(
            ads: [videoClinic],
            onClinicTap: (_) {},
            onRequestAppointmentTap: (_) {},
            onContactTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(FeaturedAdSlideMedia), findsOneWidget);
    expect(find.text('15s Video'), findsOneWidget);
    expect(find.text('Elite Clinic Dubai'), findsOneWidget);
  });
}
