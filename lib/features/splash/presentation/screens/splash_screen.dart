import '../../../auth/data/auth_repository.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/widgets/app_brand_logo.dart';
import 'package:aesthetic_way/features/onboarding/services/onboarding_service.dart';
import 'package:aesthetic_way/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/features/navigation/main_nav_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_main_nav_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_main_nav_screen.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/login_screen.dart';

/// Screen 1: Luxury Splash Screen with Official Brand Logo & Onboarding-Aware Navigation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.authRepository, this.onboardingService});
  final AuthRepository? authRepository;
  final OnboardingService? onboardingService;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _timer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();

    // Auto navigate after splash duration
    _timer = Timer(const Duration(milliseconds: 1600), _navigateNext);
  }

  Future<void> _navigateNext() async {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _timer?.cancel();

    final onboarding = widget.onboardingService ?? OnboardingService();
    await onboarding.init();
    if (!mounted) return;
    // Cached roles are not proof of a live session. An established user never
    // sees introduction again, including when verification forces logout.
    final hadSession = AuthState().isLoggedIn;
    final identityEpoch = AuthState().sessionEpoch;
    if (hadSession) {
      await onboarding.recordAuthenticatedSession();
      if (!mounted) return;
      try {
        await (widget.authRepository ?? AuthRepository()).getMe();
      } catch (_) {
        if (AuthState().sessionEpoch == identityEpoch) AuthState().logout();
      }
      if (!mounted) return;
      // A replacement login owns navigation; never route it using an old check.
      if (AuthState().isLoggedIn && AuthState().sessionEpoch != identityEpoch) {
        return;
      }
    }
    final hasSeenOnboarding = hadSession || onboarding.hasSeenOnboarding;
    Widget nextScreen;

    if (AuthState().isLoggedIn) {
      final role = AuthState().userRole;
      if (role == 'super_admin') {
        nextScreen = const AdminMainNavScreen();
      } else if (role == 'clinic_admin' || role == 'clinic_staff') {
        nextScreen = const ClinicMainNavScreen();
      } else if (role == 'patient') {
        nextScreen = const MainNavScreen();
      } else {
        AuthState().logout();
        nextScreen = const LoginScreen();
      }
    } else if (!hasSeenOnboarding) {
      nextScreen = const OnboardingScreen();
    } else {
      nextScreen = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateNext,
      behavior: HitTestBehavior.opaque,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value:
            (AppColors.isDark(context)
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark)
                .copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: AppColors.bg(context),
                ),
        child: Scaffold(
          backgroundColor: AppColors.bg(context),
          body: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: AppBrandLogo.splash(height: 300, width: 300),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
