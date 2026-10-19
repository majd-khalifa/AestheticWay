import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum SilverButtonVariant { primary, secondary, champagneAccent, textOnly }

/// Native button semantics with a minimum touch target and flexible Arabic labels.
class SilverButton extends StatelessWidget {
  const SilverButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = SilverButtonVariant.primary,
    this.isFullWidth = false,
    this.height = 48,
    this.borderRadius = 14,
    this.padding,
    this.isLoading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final SilverButtonVariant variant;
  final bool isFullWidth;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;
  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark(context);
    final (background, foreground) = switch (variant) {
      SilverButtonVariant.primary => (
        dark ? AppColors.primaryButtonFill : AppColors.primaryButtonFillLight,
        dark ? AppColors.primaryButtonText : AppColors.primaryButtonTextLight,
      ),
      SilverButtonVariant.secondary => (
        AppColors.surfaceHover(context),
        AppColors.text(context),
      ),
      SilverButtonVariant.champagneAccent => (
        AppColors.accentChampagne,
        AppColors.backgroundDeep,
      ),
      SilverButtonVariant.textOnly => (
        Colors.transparent,
        AppColors.text(context),
      ),
    };
    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size(0, height < 48 ? 48 : height),
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        disabledBackgroundColor: background.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: variant == SilverButtonVariant.secondary
              ? BorderSide(color: AppColors.border(context), width: 0.7)
              : BorderSide.none,
        ),
      ),
      child: isLoading
          ? SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foreground,
                semanticsLabel: label,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.button.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );
    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
