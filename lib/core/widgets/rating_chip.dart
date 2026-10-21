import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';

/// Clean Clinic Rating Chip displaying Google source (e.g. 4.9 (Google / 120))
class RatingChip extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final bool isCompact;
  final bool showGoogleSource;

  const RatingChip({
    super.key,
    required this.rating,
    this.reviewCount,
    this.isCompact = false,
    this.showGoogleSource = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!rating.isFinite || rating < 1 || rating > 5) {
      return const SizedBox.shrink();
    }

    final isDark = AppColors.isDark(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 3.5,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF111A2E).withValues(alpha: 0.9)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? AppColors.starGold.withValues(alpha: 0.35)
              : const Color(0xFFFDE68A),
          width: 0.6,
        ),
      ),
      child: Wrap(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 3,
        children: [
          const Icon(Icons.star_rounded, size: 13, color: AppColors.starGold),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.textPrimary : const Color(0xFF78350F),
              fontWeight: FontWeight.w700,
              fontSize: isCompact ? 10.5 : 11.5,
            ),
          ),
          if (showGoogleSource) ...[
            const SizedBox(width: 5),
            Text(
              'Google',
              style: AppTypography.caption.copyWith(
                fontSize: isCompact ? 9 : 10,
                color: AppColors.subtext(context),
              ),
            ),
          ],
          if (reviewCount != null && reviewCount! > 0) ...[
            const SizedBox(width: 3),
            Text(
              '($reviewCount)',
              style: AppTypography.caption.copyWith(
                color: isDark
                    ? AppColors.silverMuted
                    : AppColors.lightTextMuted,
                fontSize: isCompact ? 9 : 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
