import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/app_brand_logo.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/onboarding/services/onboarding_service.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/login_screen.dart';

/// Luxury 3-Step Onboarding Screen with Client Logo, Page Indicator & Smooth Transitions
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _finishing = false;
  String? _saveError;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    if (_finishing) return;
    setState(() {
      _finishing = true;
      _saveError = null;
    });
    await OnboardingService().completeOnboarding();
    if (!mounted) return;
    if (OnboardingService().saveFailed) {
      setState(() {
        _finishing = false;
        _saveError = LocaleService().isArabic
            ? 'تعذر حفظ اختيارك. يرجى المحاولة مجدداً.'
            : 'Could not save your choice. Please try again.';
      });
      return;
    }
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _onNext() {
    if (_finishing) return;
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    final slides = [
      _OnboardingSlideData(
        icon: Icons.domain_rounded,
        imagePath: 'assets/images/onboarding/onboarding_1.jpeg',
        badgeText: loc.isArabic
            ? 'عيادات طبية في الإمارات'
            : 'UAE Medical Clinics',
        title: loc.tr('onboarding_title_1'),
        description: loc.tr('onboarding_desc_1'),
      ),
      _OnboardingSlideData(
        icon: Icons.medical_services_rounded,
        imagePath: 'assets/images/onboarding/onboarding_2.webp',
        badgeText: loc.isArabic
            ? 'أطباء وممارسون صحيون'
            : 'Doctors & Practitioners',
        title: loc.tr('onboarding_title_2'),
        description: loc.tr('onboarding_desc_2'),
      ),
      _OnboardingSlideData(
        icon: Icons.spa_rounded,
        imagePath: 'assets/images/onboarding/onboarding_3.jpeg',
        badgeText: loc.isArabic ? 'ربط وتواصل مباشر' : 'Direct Lead Connection',
        title: loc.tr('onboarding_title_3'),
        description: loc.tr('onboarding_desc_3'),
      ),
    ];

    return ListenableBuilder(
      listenable: loc,
      builder: (context, _) {
        return PopScope(
          canPop: !_finishing,
          child: Stack(
            children: [
              Scaffold(
                backgroundColor: AppColors.bg(context),
                body: SafeArea(
                  child: Column(
                    children: [
                      // Top Bar with Official Logo (Centered, mandatory flow)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Center(
                                child: AppBrandLogo.header(
                                  height: 44,
                                  width: 120,
                                ),
                              ),
                            ),
                            TextButton(
                              key: const ValueKey('skip-introduction'),
                              onPressed: _finishing ? null : _finishOnboarding,
                              child: Text(loc.isArabic ? 'تخطي' : 'Skip'),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Luxury Real Image Presentation Card
                                  Container(
                                    width: 240,
                                    height: 175,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: AppColors.accentChampagne
                                            .withValues(
                                              alpha: isDark ? 0.35 : 0.50,
                                            ),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accentChampagne
                                              .withValues(
                                                alpha: isDark ? 0.12 : 0.15,
                                              ),
                                          blurRadius: 24,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              21,
                                            ),
                                            child: Image.asset(
                                              item.imagePath,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  Container(
                                                    color: isDark
                                                        ? AppColors
                                                              .cardSurfaceHover
                                                        : AppColors
                                                              .lightCardSurface,
                                                    child: Icon(
                                                      item.icon,
                                                      size: 54,
                                                      color: AppColors
                                                          .accentChampagne,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                        // Subtle bottom vignette gradient
                                        Positioned.fill(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(21),
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  (isDark
                                                          ? Colors.black
                                                          : const Color(
                                                              0xFF070B16,
                                                            ))
                                                      .withValues(alpha: 0.45),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Floating Category Icon Badge
                                        Positioned(
                                          bottom: 10,
                                          right: loc.isArabic ? 10 : null,
                                          left: loc.isArabic ? null : 10,
                                          child: Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? AppColors.cardSurface
                                                        .withValues(alpha: 0.88)
                                                  : Colors.white.withValues(
                                                      alpha: 0.92,
                                                    ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.accentChampagne
                                                    .withValues(alpha: 0.6),
                                                width: 1.0,
                                              ),
                                            ),
                                            child: Icon(
                                              item.icon,
                                              size: 16,
                                              color: AppColors.accentChampagne,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Micro Tag
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentChampagne
                                          .withValues(
                                            alpha: isDark ? 0.15 : 0.12,
                                          ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.accentChampagne
                                            .withValues(alpha: 0.4),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      item.badgeText,
                                      style: AppTypography.badge.copyWith(
                                        color: AppColors.goldText(context),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Slide Title
                                  Text(
                                    item.title,
                                    style: AppTypography.heroTitle.copyWith(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? AppColors.silverPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),

                                  // Slide Description
                                  Text(
                                    item.description,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.mutedText(context),
                                      height: 1.6,
                                      fontSize: 13,
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
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_finishing)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x55000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              if (_saveError != null)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 120,
                  child: Material(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _saveError!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _OnboardingSlideData {
  final IconData icon;
  final String imagePath;
  final String badgeText;
  final String title;
  final String description;

  const _OnboardingSlideData({
    required this.icon,
    required this.imagePath,
    required this.badgeText,
    required this.title,
    required this.description,
  });
}
