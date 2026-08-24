import 'package:flutter/material.dart';

/// Official Client Logo Widget for AESTHETIC WAY
/// Uses strictly the official client asset: assets/images/aesthetic_way_logo.png
class AppBrandLogo extends StatelessWidget {
  final double? height;
  final double? width;
  final BoxFit fit;

  const AppBrandLogo({
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  /// Factory constructor for Home Header (clean height ~30dp without clipping letters)
  const AppBrandLogo.header({
    super.key,
    this.height = 30,
    this.width,
    this.fit = BoxFit.contain,
  });

  /// Factory constructor for Splash Screen (prominent centered official logo)
  const AppBrandLogo.splash({
    super.key,
    this.height = 130,
    this.width = 240,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/aesthetic_way_logo.png',
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback text if asset fails to load in isolated test environments
        return Text(
          'AESTHETIC WAY',
          style: TextStyle(
            color: const Color(0xFFE2E8F0),
            fontSize: height != null && height! <= 32 ? 14 : 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontFamily: 'serif',
          ),
        );
      },
    );
  }
}
