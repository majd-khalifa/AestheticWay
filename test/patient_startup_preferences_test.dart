import 'dart:io';
import 'package:aesthetic_way/main.dart' as application;
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/theme_service.dart';
import 'package:aesthetic_way/features/splash/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/settle_preview_images.dart';

void main() {
  for (final saved in [
    <String, String>{},
    {'aw_pref_locale': 'en', 'aw_pref_theme_mode': 'dark'},
    {'aw_pref_locale': 'ar', 'aw_pref_theme_mode': 'light'},
    {'aw_pref_locale': 'ar', 'aw_pref_theme_mode': 'dark'},
  ]) {
    testWidgets(
      'actual bootstrap hydrates before splash on Arabic/Dark device saved=$saved',
      (tester) async {
        // Establish this test's fake frame epoch before runApp schedules its
        // warm-up frame (the previous capture may have advanced time).
        await tester.pumpWidget(const SizedBox.shrink());
        FlutterSecureStorage.setMockInitialValues({});
        // A previous in-memory state cannot substitute for the next cold read.
        await LocaleService().setLanguage(AppLanguage.arabic);
        await ThemeService().setThemeMode(ThemeMode.dark);
        AuthState().logout();
        FlutterSecureStorage.setMockInitialValues(saved);
        tester.platformDispatcher.localesTestValue = const [Locale('ar', 'AE')];
        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        // The in-memory storage adapter completes in the test zone. Running
        // runApp in the real zone would mix wall-clock warm-up ticks with the
        // next test's fake animation epoch after a captured splash animation.
        await application.main();
        await tester.pump();
        final context = tester.element(find.byType(SplashScreen));
        expect(
          Localizations.localeOf(context).languageCode,
          saved['aw_pref_locale'] ?? 'en',
        );
        expect(
          Directionality.of(context),
          saved['aw_pref_locale'] == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
        );
        final dark = saved['aw_pref_theme_mode'] == 'dark';
        expect(
          Theme.of(context).brightness,
          dark ? Brightness.dark : Brightness.light,
        );
        expect(
          tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          dark ? AppColors.backgroundDeep : AppColors.lightBackground,
        );
        expect(tester.takeException(), isNull);
        const output = String.fromEnvironment('PATIENT_STARTUP_CAPTURE_DIR');
        if (output.isNotEmpty) {
          await tester.pump(const Duration(milliseconds: 400));
          await settlePreviewImages(tester);
          await expectLater(
            find.byType(Scaffold),
            matchesGoldenFile(
              Uri.file(
                '$output/splash_${saved['aw_pref_locale'] ?? 'en'}_${saved['aw_pref_theme_mode'] ?? 'light'}.png',
              ),
            ),
          );
        }
        // Dispose the real splash's timer, without reaching its authenticated router.
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  for (final mode in [ThemeMode.light, ThemeMode.dark, ThemeMode.system]) {
    testWidgets('saved ${mode.name} reacts only as selected when OS changes', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({
        'aw_pref_locale': 'en',
        'aw_pref_theme_mode': mode.name,
      });
      await Future.wait([LocaleService().init(), ThemeService().init()]);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(
        const application.AestheticWayApp(
          homeScreen: Scaffold(body: Text('probe')),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('probe'))).brightness,
        mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
      );
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('probe'))).brightness,
        mode == ThemeMode.light ? Brightness.light : Brightness.dark,
      );
    });
  }
  test(
    'native Android day/night and Android12 launch resources never inherit system Dark',
    () {
      final root = Directory('android/app/src/main/res');
      for (final qualifier in [
        'values',
        'values-night',
        'values-v31',
        'values-night-v31',
      ]) {
        final xml = File(
          '${root.path}/$qualifier/styles.xml',
        ).readAsStringSync();
        expect(xml, contains('Theme.Light.NoTitleBar'));
        expect(xml, isNot(contains('Theme.Black')));
        if (qualifier.contains('v31')) {
          expect(xml, contains('android:windowSplashScreenBackground'));
        }
      }
      for (final qualifier in ['drawable', 'drawable-v21']) {
        expect(
          File(
            '${root.path}/$qualifier/launch_background.xml',
          ).readAsStringSync(),
          contains('@color/aw_launch_surface'),
        );
      }
    },
  );
}
