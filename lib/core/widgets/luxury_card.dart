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

    final effectiveBorder =
        widget.customBorder ??
        Border.all(
          color: widget.isVip
              ? AppColors.goldText(context).withValues(alpha: 0.28)
              : AppColors.border(context),
          width: 0.7,
        );
    final effectiveGradient = widget.gradient;
    final effectiveBg = effectiveGradient == null
        ? (widget.backgroundColor ?? AppColors.surface(context))
        : null;
    final shadows = isDark
        ? <BoxShadow>[]
        : [
            BoxShadow(
              color: const Color(
                0xFF16263A,
              ).withValues(alpha: _isPressed ? 0.025 : 0.045),
              blurRadius: 18,
              spreadRadius: -4,
              offset: const Offset(0, 6),
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
      return Semantics(
        button: true,
        child: FocusableActionDetector(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap?.call();
                return null;
              },
            ),
          },
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedScale(
              scale: _isPressed ? 0.992 : 1.0,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: cardContent,
            ),
          ),
        ),
      );
    }

    return cardContent;
  }
}
