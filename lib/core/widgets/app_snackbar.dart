import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';

/// SnackBar severity types
enum AppSnackBarType {
  info,
  success,
  error,
  warning,
}

/// Unified Luxury App SnackBar Helper for AESTHETIC WAY
/// Guarantees high-contrast readable text, distinct Dark/Light elevated surface,
/// floating behavior, icons, and consistent duration across all screens.
class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (message.trim().isEmpty) return;

    final isDark = AppColors.isDark(context);

    // High-contrast background and styling based on type and theme
    Color bg;
    Color border;
    Color iconColor;
    IconData icon;
    Color textColor;

    switch (type) {
      case AppSnackBarType.success:
        bg = isDark ? const Color(0xFF062817) : const Color(0xFFE8F8F0);
        border = const Color(0xFF10B981);
        iconColor = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
        textColor = isDark ? const Color(0xFFE6F4EA) : const Color(0xFF065F46);
        break;
      case AppSnackBarType.error:
        bg = isDark ? const Color(0xFF2C0B0E) : const Color(0xFFFDE8E8);
        border = AppColors.errorRed;
        iconColor = AppColors.errorRed;
        icon = Icons.error_outline_rounded;
        textColor = isDark ? const Color(0xFFFCE8E6) : const Color(0xFF991B1B);
        break;
      case AppSnackBarType.warning:
        bg = isDark ? const Color(0xFF2B1D06) : const Color(0xFFFEF3C7);
        border = AppColors.accentChampagne;
        iconColor = isDark ? AppColors.accentChampagne : const Color(0xFFB45309);
        icon = Icons.warning_amber_rounded;
        textColor = isDark ? const Color(0xFFFEF3C7) : const Color(0xFF78350F);
        break;
      case AppSnackBarType.info:
        bg = isDark ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9);
        border = isDark ? AppColors.silverSecondary.withValues(alpha: 0.5) : const Color(0xFF94A3B8);
        iconColor = isDark ? AppColors.accentChampagne : const Color(0xFF0F172A);
        icon = Icons.info_outline_rounded;
        textColor = isDark ? AppColors.silverPrimary : const Color(0xFF0F172A);
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1.0),
        ),
        duration: duration,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: iconColor,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static void success(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: AppSnackBarType.success, duration: duration);
  }

  static void error(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: AppSnackBarType.error, duration: duration);
  }

  static void warning(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: AppSnackBarType.warning, duration: duration);
  }

  static void info(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: AppSnackBarType.info, duration: duration);
  }
}

/// Global convenience function
void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackBarType type = AppSnackBarType.info,
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  AppSnackBar.show(
    context,
    message,
    type: type,
    duration: duration,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}
