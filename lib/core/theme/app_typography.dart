import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';

/// AESTHETIC WAY Luxury Medical Typography Scale
abstract class AppTypography {
  static const TextStyle heroTitle = TextStyle(
    fontSize: 28,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextStyle screenTitle = TextStyle(
    fontSize: 21,
    height: 1.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15.5,
    height: 1.5,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 14.5,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    height: 1.6,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: AppColors.backgroundDeep,
    letterSpacing: 0.2,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 10.5,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );
}
