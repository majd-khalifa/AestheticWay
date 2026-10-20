import 'package:flutter/material.dart';

/// AESTHETIC WAY Design System - Dual Theme Palette (Dark + Soft Light Luxury)
/// High-end UAE market with Midnight Obsidian, Soft Light Luxury, Pure Platinum & Champagne Gold
abstract class AppColors {
  // ==========================================
  // DARK THEME TOKENS (Default)
  // ==========================================
  static const Color backgroundDeep = Color(0xFF070C1A); // Dark Canvas
  static const Color backgroundBase = Color(0xFF0B1220); // Base layer
  static const Color backgroundElevated = Color(0xFF0F172A);

  static const Color cardSurface = Color(0xFF111A2E); // Dark Card Surface
  static const Color cardSurfaceLight = Color(0xFF16233B);
  static const Color cardSurfaceHover = Color(0xFF192542);
  static const Color cardSurfaceSubtle = Color(0xFF0A101E);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF9AA9BD);

  static const Color silverPrimary = Color(0xFFF1F5F9);
  static const Color silverLight = Color(0xFFFFFFFF);
  static const Color silverSecondary = Color(0xFFCBD5E1);
  static const Color silverMuted = Color(0xFF9AA9BD);
  static const Color silverBorder = Color(0xFF334155);

  // ==========================================
  // LIGHT THEME TOKENS (Soft Light Luxury)
  // ==========================================
  static const Color lightBackground = Color(0xFFF4F6FA); // Soft Light Canvas
  static const Color lightCardSurface = Color(0xFFFFFFFF); // Pure White Card
  static const Color lightCardSurfaceHover = Color(0xFFEEF2F6);
  static const Color lightCardSurfaceSubtle = Color(0xFFF8FAFC);

  static const Color lightTextPrimary = Color(
    0xFF0A0E17,
  ); // Deep Obsidian Navy text
  static const Color lightTextSecondary = Color(
    0xFF1E293B,
  ); // High-contrast Slate Charcoal
  static const Color lightTextMuted = Color(
    0xFF334155,
  ); // Strong readable Slate

  static const Color lightBorder = Color(0xFFD9E1EC); // Soft Luxury Border
  static const Color primarySoftNavy = Color(
    0xFF1F3A5F,
  ); // Primary soft navy for chips/links

  // ==========================================
  // SHARED LUXURY ACCENTS (Both Themes)
  // ==========================================
  static const Color accentChampagne = Color(
    0xFFC8A97E,
  ); // Universal Luxury Gold
  static const Color lightGold = Color(0xFF9A7B1C);
  static const Color darkGold = Color(0xFFD4AF37);
  // Normal-size labels need a deeper bronze to meet 4.5:1 on soft light surfaces.
  static const Color lightGoldText = Color(0xFF806615);
  static Color goldText(BuildContext context) =>
      isDark(context) ? darkGold : lightGoldText;

  static const Color accentChampagneBright = Color(0xFFDFC49F);
  static const Color accentChampagneSoft = Color(0xFF241B10);
  static const Color accentChampagneGlow = Color(0x33C8A97E);

  static const Color accentIceBlue = Color(0xFF3B82F6);
  static const Color accentIceBlueSoft = Color(0xFF172554);

  static const Color medicalBlue = Color(0xFF1D4ED8);
  static const Color nurseTeal = Color(0xFF0F766E);
  static const Color specialistSilver = Color(0xFF475569);

  // B2B Subscription Tiers
  static const Color vipChampagneGold = Color(0xFFC8A97E);
  static const Color vipGold = Color(0xFFC8A97E);
  static const Color vipGoldDark = Color(0xFF1F170C);
  static const Color featuredPlatinum = Color(0xFF94A3B8);

  // Status & Utility Colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color starGold = Color(0xFFF59E0B);

  static Color positiveText(BuildContext context) =>
      isDark(context) ? const Color(0xFF6EE7B7) : const Color(0xFF166534);
  static Color dangerText(BuildContext context) =>
      isDark(context) ? const Color(0xFFFDA4AF) : const Color(0xFF9F1239);
  static Color warningText(BuildContext context) =>
      isDark(context) ? const Color(0xFFFDE68A) : const Color(0xFF854D0E);
  static Color infoText(BuildContext context) =>
      isDark(context) ? const Color(0xFFBFDBFE) : const Color(0xFF1E3A8A);

  // Button Tones
  static const Color primaryButtonFill = Color(0xFFF1F5F9);
  static const Color primaryButtonText = Color(0xFF050811);
  static const Color primaryButtonFillLight = Color(0xFF0F172A);
  static const Color primaryButtonTextLight = Color(0xFFFFFFFF);

  // Dynamic Borders
  static Color borderSubtle = const Color(0xFF94A3B8).withValues(alpha: 0.14);
  static Color borderHighlight = const Color(0xFFE2E8F0).withValues(alpha: 0.3);
  static Color borderAccent = const Color(0xFFC8A97E).withValues(alpha: 0.5);

  // ==========================================
  // CONTEXT-AWARE THEME HELPERS
  // ==========================================
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color bg(BuildContext context) {
    return isDark(context) ? backgroundDeep : lightBackground;
  }

  static Color surface(BuildContext context) {
    return isDark(context) ? cardSurface : lightCardSurface;
  }

  static Color surfaceHover(BuildContext context) {
    return isDark(context) ? cardSurfaceHover : lightCardSurfaceHover;
  }

  static Color surfaceSubtle(BuildContext context) {
    return isDark(context) ? cardSurfaceSubtle : lightCardSurfaceSubtle;
  }

  static const Color lightBackgroundAlt = lightCardSurfaceSubtle;

  static Color text(BuildContext context) {
    return isDark(context) ? textPrimary : lightTextPrimary;
  }

  static Color primaryText(BuildContext context) => text(context);

  static Color subtext(BuildContext context) {
    return isDark(context) ? textSecondary : lightTextSecondary;
  }

  static Color secondaryText(BuildContext context) => subtext(context);

  static Color mutedText(BuildContext context) {
    return isDark(context) ? textMuted : lightTextMuted;
  }

  static Color border(BuildContext context) {
    return isDark(context) ? silverBorder.withValues(alpha: 0.22) : lightBorder;
  }

  static LinearGradient cardGrad(BuildContext context) {
    if (isDark(context)) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF131C32), Color(0xFF0D1424)],
      );
    } else {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF9FBFC)],
      );
    }
  }

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF131C32), Color(0xFF0D1424)],
  );

  static const LinearGradient vipCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A192A), Color(0xFF0F1524)],
  );

  static const LinearGradient vipCardGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFCF9F4), Color(0xFFFFFFFF)],
  );

  static const LinearGradient vipBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDFC49F), Color(0xFF785D36), Color(0xFFDFC49F)],
  );
}
