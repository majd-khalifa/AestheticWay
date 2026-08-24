import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';

/// Clean Distance & Location Chip (Fully Bilingual)
class DistanceChip extends StatelessWidget {
  final double? distanceKm;
  final String? areaName;

  const DistanceChip({
    super.key,
    this.distanceKm,
    this.areaName,
  });

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    String label;
    if (distanceKm != null) {
      label = '${distanceKm!.toStringAsFixed(1)} ${loc.tr("unit_km")}';
      if (areaName != null && areaName!.isNotEmpty) {
        label = '$areaName • $label';
      }
    } else {
      label = areaName ?? (loc.isArabic ? 'دبي' : 'Dubai');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceHover,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle, width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 12,
            color: AppColors.silverSecondary,
          ),
          const SizedBox(width: 3.5),
          Flexible(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.silverPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
