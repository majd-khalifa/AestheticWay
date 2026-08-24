import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';

/// Elevated Luxury Card supporting Dark and Light Modes with adaptive shadows and rim borders
class LuxuryCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Border? customBorder;
  final bool hasGlow;
  final bool isVip;

  const LuxuryCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.borderRadius = 18,
    this.backgroundColor,
    this.gradient,
    this.customBorder,
    this.hasGlow = false,
    this.isVip = false,
  });

  @override
  State<LuxuryCard> createState() => _LuxuryCardState();
}

class _LuxuryCardState extends State<LuxuryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final effectiveBorder = widget.customBorder ??
        Border.all(
          color: widget.isVip
              ? AppColors.accentChampagne.withValues(alpha: isDark ? 0.55 : 0.75)
              : (widget.hasGlow
                  ? AppColors.borderHighlight
                  : (isDark
                      ? AppColors.silverBorder.withValues(alpha: 0.2)
                      : AppColors.lightBorder)),
          width: widget.isVip ? 1.0 : 0.8,
        );

    final effectiveGradient = widget.gradient ??
        (widget.isVip
            ? (isDark ? AppColors.vipCardGradient : AppColors.vipCardGradientLight)
            : (widget.backgroundColor == null ? (isDark ? AppColors.cardGradient : null) : null));

    final effectiveBg = widget.backgroundColor ??
        (effectiveGradient == null
            ? (isDark ? AppColors.cardSurface : AppColors.lightCardSurface)
            : null);

    final shadows = isDark
        ? [
            // Dark Mode Deep Ambient Layered Shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: _isPressed ? 0.3 : 0.52),
              blurRadius: _isPressed ? 10 : 24,
              offset: Offset(0, _isPressed ? 3 : 8),
              spreadRadius: _isPressed ? -3 : -2,
            ),
            BoxShadow(
              color: (widget.isVip ? AppColors.accentChampagne : AppColors.silverPrimary)
                  .withValues(alpha: widget.hasGlow || widget.isVip ? 0.1 : 0.035),
              blurRadius: 1,
              spreadRadius: 0.5,
              offset: const Offset(0, -0.5),
            ),
            if (widget.isVip || widget.hasGlow)
              BoxShadow(
                color: AppColors.accentChampagne.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 1,
              ),
          ]
        : [
            // Light Mode Soft Luxury Ambient Shadow
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: _isPressed ? 0.04 : 0.07),
              blurRadius: _isPressed ? 6 : 18,
              offset: Offset(0, _isPressed ? 2 : 6),
              spreadRadius: _isPressed ? -2 : 0,
            ),
            if (widget.isVip || widget.hasGlow)
              BoxShadow(
                color: AppColors.accentChampagne.withValues(alpha: 0.18),
                blurRadius: 16,
                spreadRadius: 1,
              ),
          ];

    final cardContent = Container(
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: effectiveBorder,
        boxShadow: shadows,
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
