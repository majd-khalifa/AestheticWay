import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// AESTHETIC WAY Luxury Medical Theme System (Dark + Soft Light Luxury)
class AppTheme {
  // ==========================================
  // DARK THEME (Default)
  // ==========================================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDeep,
      primaryColor: AppColors.silverPrimary,
      canvasColor: AppColors.cardSurface,
      cardColor: AppColors.cardSurface,
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppColors.silverBorder.withValues(alpha: 0.2),
            width: 0.75,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.silverPrimary,
          foregroundColor: AppColors.backgroundDeep,
          elevation: 2,
          shadowColor: AppColors.silverPrimary.withValues(alpha: 0.25),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTypography.button.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.silverPrimary,
          side: BorderSide(
            color: AppColors.silverBorder.withValues(alpha: 0.22),
            width: 0.8,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTypography.button.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.cardSurface,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.silverPrimary,
        onPrimary: AppColors.backgroundDeep,
        secondary: AppColors.silverLight,
        onSecondary: AppColors.backgroundDeep,
        surface: AppColors.cardSurface,
        onSurface: AppColors.textPrimary,
        error: AppColors.errorRed,
        onError: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDeep,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.silverPrimary),
        titleTextStyle: AppTypography.screenTitle,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundBase,
        selectedItemColor: AppColors.accentChampagne,
        unselectedItemColor: AppColors.silverMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardSurface,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary.withValues(alpha: 0.68),
          fontWeight: FontWeight.w400,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.silverPrimary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.silverPrimary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.silverBorder.withValues(alpha: 0.15),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF131B2E),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.silverPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.silverBorder.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // LIGHT THEME (Soft Light Luxury)
  // ==========================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.primarySoftNavy,
      canvasColor: AppColors.lightCardSurface,
      cardColor: AppColors.lightCardSurface,
      cardTheme: CardThemeData(
        color: AppColors.lightCardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.lightBorder, width: 0.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightTextPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTypography.button.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: Colors.white,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          side: const BorderSide(color: AppColors.lightBorder, width: 0.9),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTypography.button.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.lightCardSurface,
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightTextPrimary,
        onPrimary: Colors.white,
        secondary: AppColors.primarySoftNavy,
        onSecondary: Colors.white,
        surface: AppColors.lightCardSurface,
        onSurface: AppColors.lightTextPrimary,
        error: AppColors.errorRed,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: AppTypography.screenTitle.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightCardSurface,
        selectedItemColor: AppColors.accentChampagne,
        unselectedItemColor: AppColors.lightTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCardSurface,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.lightTextPrimary.withValues(alpha: 0.68),
          fontWeight: FontWeight.w400,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primarySoftNavy,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFFF8FAFC),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.lightTextPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.lightBorder, width: 0.9),
        ),
      ),
    );
  }
}
