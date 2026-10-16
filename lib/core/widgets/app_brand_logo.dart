import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';

/// Official Client Logo Widget for AESTHETIC WAY
/// Uses strictly the official client asset: assets/images/aesthetic_way_logo.png
class AppBrandLogo extends StatelessWidget {
  static const String assetPath = 'assets/images/aesthetic_way_logo.png';
  static const Color brandNavyCanvas = Color(0xFF070C1A);

  final double? height;
  final double? width;
  final BoxFit fit;
  final bool isSplash;

  const AppBrandLogo({
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.isSplash = false,
  });

  /// Factory constructor for Home / Onboarding / Auth Header
  /// Displays the official logo prominently with a brand dark-navy badge so silver lettering reads clearly in Light & Dark modes.
  const AppBrandLogo.header({
    super.key,
    this.height = 46,
    this.width = 104,
    this.fit = BoxFit.contain,
  }) : isSplash = false;

  /// Factory constructor for Auth Screens (Login, Register, Forgot Password)
  /// Gives a prominent, balanced luxury presence matching the splash screen standard.
  const AppBrandLogo.auth({
    super.key,
    this.height = 144,
    this.width = 184,
    this.fit = BoxFit.contain,
  }) : isSplash = true;

  /// Factory constructor for Splash Screen (large, centered, fills visual focus)
  const AppBrandLogo.splash({
    super.key,
    this.height = 290,
    this.width = 290,
    this.fit = BoxFit.contain,
  }) : isSplash = true;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? (isSplash ? 290.0 : 46.0);
    final effectiveWidth = width ?? (isSplash ? 290.0 : effectiveHeight * 2.15);

    final imageWidget = Image.asset(
      assetPath,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback text if asset fails to load in isolated test environments
        return Center(
          child: Text(
            'AESTHETIC WAY',
            style: TextStyle(
              color: const Color(0xFFE2E8F0),
              fontSize: effectiveHeight <= 52 ? 14 : 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontFamily: 'serif',
            ),
          ),
        );
      },
    );

    if (isSplash) {
      return Container(
        width: effectiveWidth,
        height: effectiveHeight,
        decoration: BoxDecoration(
          color: brandNavyCanvas,
          borderRadius: BorderRadius.circular(28),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Align(
            alignment: Alignment.center,
            widthFactor: 0.78,
            heightFactor: 0.72,
            child: imageWidget,
          ),
        ),
      );
    }

    return Container(
      width: effectiveWidth,
      height: effectiveHeight,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: brandNavyCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentChampagne.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Align(
          alignment: Alignment.center,
          widthFactor: 0.78,
          heightFactor: 0.56,
          child: imageWidget,
        ),
      ),
    );
  }
}
