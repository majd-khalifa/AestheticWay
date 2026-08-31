import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';

/// Lightweight Before & After Comparison Showcase Widget
class BeforeAfterPreview extends StatelessWidget {
  final String beforeImageUrl;
  final String afterImageUrl;
  final String titleAr;
  final String titleEn;
  final String? subtitleAr;
  final String? subtitleEn;

  const BeforeAfterPreview({
    super.key,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    required this.titleAr,
    required this.titleEn,
    this.subtitleAr,
    this.subtitleEn,
  });

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    return LuxuryCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_fix_high_rounded, color: AppColors.accentChampagne, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.isArabic ? titleAr : titleEn,
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              if (subtitleAr != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.15 : 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    loc.isArabic ? subtitleAr! : (subtitleEn ?? subtitleAr!),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.accentChampagne,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Before Image
              Expanded(
                child: _ComparisonImage(
                  imageUrl: beforeImageUrl,
                  label: loc.tr('before_label'),
                  isAfter: false,
                ),
              ),
              const SizedBox(width: 8),
              // After Image
              Expanded(
                child: _ComparisonImage(
                  imageUrl: afterImageUrl,
                  label: loc.tr('after_label'),
                  isAfter: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonImage extends StatelessWidget {
  final String imageUrl;
  final String label;
  final bool isAfter;

  const _ComparisonImage({
    required this.imageUrl,
    required this.label,
    required this.isAfter,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAfter
              ? AppColors.accentChampagne.withValues(alpha: 0.6)
              : AppColors.border(context),
          width: isAfter ? 1.2 : 0.8,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined, color: AppColors.silverMuted, size: 24),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isAfter
                    ? AppColors.accentChampagne.withValues(alpha: 0.9)
                    : Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: isAfter ? const Color(0xFF070B16) : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 10.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
