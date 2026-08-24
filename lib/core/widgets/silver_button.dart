import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';

enum SilverButtonVariant {
  primary, // Solid filled high-contrast Telegram button
  secondary, // Soft elevated surface with fine border
  champagneAccent, // Luxury champagne gold accent
  textOnly, // Clean text button
}

/// Telegram-style Modern Luxury Action Button adapting to Dark and Light modes
class SilverButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final SilverButtonVariant variant;
  final bool isFullWidth;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;

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

  @override
  State<SilverButton> createState() => _SilverButtonState();
}

class _SilverButtonState extends State<SilverButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    Color bg;
    Color fg;
    Border? border;
    List<BoxShadow> shadows = [];

    switch (widget.variant) {
      case SilverButtonVariant.primary:
        bg = isDark ? AppColors.primaryButtonFill : AppColors.primaryButtonFillLight;
        fg = isDark ? AppColors.primaryButtonText : AppColors.primaryButtonTextLight;
        border = null;
        shadows = [
          BoxShadow(
            color: (isDark ? AppColors.silverPrimary : Colors.black).withValues(alpha: _isPressed ? 0.08 : 0.18),
            blurRadius: _isPressed ? 4 : 12,
            offset: Offset(0, _isPressed ? 1 : 4),
          ),
        ];
        break;
      case SilverButtonVariant.secondary:
        bg = isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover;
        fg = isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary;
        border = Border.all(
          color: isDark ? AppColors.silverBorder.withValues(alpha: 0.22) : AppColors.lightBorder,
          width: 0.8,
        );
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ];
        break;
      case SilverButtonVariant.champagneAccent:
        bg = AppColors.accentChampagne;
        fg = const Color(0xFF140F08);
        border = null;
        shadows = [
          BoxShadow(
            color: AppColors.accentChampagne.withValues(alpha: _isPressed ? 0.18 : 0.3),
            blurRadius: _isPressed ? 6 : 14,
            offset: Offset(0, _isPressed ? 1 : 4),
          ),
        ];
        break;
      case SilverButtonVariant.textOnly:
        bg = Colors.transparent;
        fg = isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary;
        border = null;
        shadows = [];
        break;
    }

    Widget content;
    if (widget.isLoading) {
      content = Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(fg),
          ),
        ),
      );
    } else {
      content = Row(
        mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 16.5, color: fg),
            const SizedBox(width: 7),
          ],
          Text(
            widget.label,
            style: AppTypography.button.copyWith(
              color: fg,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      );
    }

    Widget btn = Container(
      height: widget.height,
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: widget.onPressed == null ? bg.withValues(alpha: 0.4) : bg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: border,
        boxShadow: widget.onPressed != null ? shadows : null,
      ),
      child: content,
    );

    if (widget.onPressed == null || widget.isLoading) {
      return widget.isFullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.972 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.isFullWidth ? SizedBox(width: double.infinity, child: btn) : btn,
      ),
    );
  }
}
