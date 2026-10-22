import 'core/widgets/luxury_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_service.dart';
import 'core/localization/app_locale.dart';
import 'core/auth/guest_auth_guard.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureImageCacheBudget();
  await Future.wait([
    LocaleService().init(),
    ThemeService().init(),
    AuthState().restoreSession(),
  ]);
  runApp(const AestheticWayApp());
}

/// AESTHETIC WAY - Root Application Widget with Dynamic Locale and Theme Switching (Light / Dark)
class AestheticWayApp extends StatelessWidget {
  final Widget? homeScreen;

  const AestheticWayApp({super.key, this.homeScreen});

  @override
  Widget build(BuildContext context) {
    final localeService = LocaleService();
    final themeService = ThemeService();

    return ListenableBuilder(
      listenable: Listenable.merge([localeService, themeService, AuthState()]),
      builder: (context, _) {
        return MaterialApp(
          // Destroy every old route/dialog (including private lead snapshots)
          // whenever login, logout, account switching or role changes occur.
          key: ValueKey('session-${AuthState().sessionEpoch}'),
          title: 'AESTHETIC WAY',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          // Dynamic Language / Locale configuration (English LTR default / Arabic RTL)
          locale: localeService.locale,
          supportedLocales: const [Locale('en', 'US'), Locale('ar', 'AE')],
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
