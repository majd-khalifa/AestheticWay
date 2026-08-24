import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/app_brand_logo.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/onboarding/services/onboarding_service.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/login_screen.dart';
import 'package:aesthetic_way/features/navigation/main_nav_screen.dart';

/// Luxury 3-Step Onboarding Screen with Client Logo, Page Indicator & Smooth Transitions
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding({bool toLogin = true}) {
    OnboardingService().completeOnboarding();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            toLogin ? const LoginScreen() : const MainNavScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _onNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding(toLogin: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    final slides = [
      _OnboardingSlideData(
        icon: Icons.domain_rounded,
        badgeText: loc.isArabic ? 'عيادات نخبوية ومعتمدة' : 'Verified Elite Clinics',
        title: loc.tr('onboarding_title_1'),
        description: loc.tr('onboarding_desc_1'),
      ),
      _OnboardingSlideData(
        icon: Icons.auto_awesome_rounded,
        badgeText: loc.isArabic ? 'عروض وباقات حصرية' : 'Exclusive Treatment Offers',
        title: loc.tr('onboarding_title_2'),
        description: loc.tr('onboarding_desc_2'),
      ),
      _OnboardingSlideData(
        icon: Icons.verified_user_rounded,
        badgeText: loc.isArabic ? 'خصوصية وربط مباشر' : 'Direct Lead Connection',
        title: loc.tr('onboarding_title_3'),
        description: loc.tr('onboarding_desc_3'),
      ),
    ];

    return ListenableBuilder(
      listenable: loc,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          body: SafeArea(
            child: Column(
              children: [
                // Top Bar with Official Logo & Skip Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppBrandLogo.header(height: 28),
                      TextButton(
                        onPressed: () => _finishOnboarding(toLogin: false),
                        child: Text(
                          loc.tr('onboarding_skip'),
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.mutedText(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // PageView Slider
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: slides.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = slides[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Luxury Icon Badge Container
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? AppColors.cardSurfaceHover
                                    : AppColors.lightCardSurface,
                                border: Border.all(
                                  color: AppColors.accentChampagne.withValues(
                                    alpha: isDark ? 0.35 : 0.55,
                                  ),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentChampagne.withValues(
                                      alpha: isDark ? 0.15 : 0.18,
                                    ),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  item.icon,
                                  size: 64,
                                  color: AppColors.accentChampagne,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Micro Tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentChampagne.withValues(
                                  alpha: isDark ? 0.15 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.accentChampagne.withValues(
                                    alpha: 0.4,
                                  ),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                item.badgeText,
                                style: AppTypography.badge.copyWith(
                                  color: AppColors.accentChampagne,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Slide Title
                            Text(
                              item.title,
                              style: AppTypography.heroTitle.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.silverPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),

                            // Slide Description
                            Text(
                              item.description,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.mutedText(context),
                                height: 1.6,
                                fontSize: 13.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Controls: Indicator Dots & Action Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Column(
                    children: [
                      // Smooth Page Indicator Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(slides.length, (index) {
                          final isSelected = _currentPage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: isSelected ? 24 : 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentChampagne
                                  : (isDark
                                      ? AppColors.borderSubtle
                                      : AppColors.lightBorder),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Next / Get Started Button
                      SilverButton(
                        label: _currentPage == 2
                            ? loc.tr('onboarding_start')
                            : loc.tr('onboarding_next'),
                        icon: _currentPage == 2
                            ? Icons.check_circle_outline
                            : Icons.arrow_forward_rounded,
                        isFullWidth: true,
                        height: 48,
                        onPressed: _onNext,
                      ),
                      const SizedBox(height: 10),

                      // Guest Bypass Option
                      TextButton(
                        onPressed: () => _finishOnboarding(toLogin: false),
                        child: Text(
                          loc.tr('continue_as_guest'),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.mutedText(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingSlideData {
  final IconData icon;
  final String badgeText;
  final String title;
  final String description;

  const _OnboardingSlideData({
    required this.icon,
    required this.badgeText,
    required this.title,
    required this.description,
  });
}
