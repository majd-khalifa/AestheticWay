import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_service.dart';
import 'core/localization/app_locale.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AestheticWayApp());
}

/// AESTHETIC WAY - Root Application Widget with Dynamic Locale and Theme Switching (Dark / Light)
class AestheticWayApp extends StatelessWidget {
  final Widget? homeScreen;

  const AestheticWayApp({super.key, this.homeScreen});

  @override
  Widget build(BuildContext context) {
    final localeService = LocaleService();
    final themeService = ThemeService();

    return ListenableBuilder(
      listenable: Listenable.merge([localeService, themeService]),
      builder: (context, _) {
        return MaterialApp(
          title: 'AESTHETIC WAY',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          // Dynamic Language / Locale configuration (Arabic RTL / English LTR)
          locale: localeService.locale,
          supportedLocales: const [
            Locale('ar', 'AE'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: homeScreen ?? const SplashScreen(),
        );
      },
    );
  }
}
