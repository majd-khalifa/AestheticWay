import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';

/// Understated, editorial empty state with soft champagne-tinted framing
class LuxuryEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double iconSize;

  const LuxuryEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconSize = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: LuxuryCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.12 : 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentChampagne.withValues(alpha: 0.35),
                  width: 0.9,
                ),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: AppColors.accentChampagne,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.cardTitle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: AppColors.mutedText(context),
                  fontSize: 12,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accentChampagne.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded, size: 14, color: AppColors.accentChampagne),
                      const SizedBox(width: 6),
                      Text(
                        actionLabel!,
                        style: const TextStyle(
                          color: AppColors.accentChampagne,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
