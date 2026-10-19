import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/luxury_image.dart';
import '../../../../core/widgets/tier_badge.dart';
import '../../../clinics/models/clinic_model.dart';
import 'clinic_location_selector.dart';

class ClinicEditorialHeader extends StatelessWidget {
  const ClinicEditorialHeader({
    super.key,
    required this.clinic,
    required this.onEdit,
  });
  final ClinicModel clinic;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    final ar = LocaleService().isArabic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 182,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 140,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppColors.isDark(context)
                                ? [
                                    const Color(0xFF26394E),
                                    const Color(0xFF101A2A),
                                  ]
                                : [
                                    const Color(0xFFDCE6EC),
                                    const Color(0xFFBCCDD6),
                                  ],
                          ),
                        ),
                      ),
                      if (clinic.coverImageUrl.isNotEmpty)
                        LuxuryImage(
                          imageUrl: clinic.coverImageUrl,
                          fit: BoxFit.cover,
                        ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0x66070C1A)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PositionedDirectional(
                start: 16,
                top: 104,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: ClinicCatalogThumbnail(
                    imageUrl: clinic.logoUrl,
                    icon: Icons.apartment_rounded,
                    size: 72,
                  ),
                ),
              ),
              PositionedDirectional(
                end: 12,
                top: 12,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface(context),
                    foregroundColor: AppColors.text(context),
                  ),
                  tooltip: ar ? 'تعديل ملف العيادة' : 'Edit Clinic Profile',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ar ? clinic.nameAr : clinic.nameEn,
                style: TextStyle(
                  color: AppColors.text(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                clinicLocationSummary(
                  clinic.city,
                  ar ? clinic.addressAr : clinic.addressEn,
                  arabic: ar,
                ),
                style: TextStyle(
                  color: AppColors.mutedText(context),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              TierBadge(tier: clinic.subscriptionTier),
              if ((ar ? clinic.descriptionAr : clinic.descriptionEn)
                  .trim()
                  .isNotEmpty) ...[
                const Divider(height: 24),
                Text(
                  ar ? clinic.descriptionAr : clinic.descriptionEn,
                  style: TextStyle(
                    color: AppColors.mutedText(context),
                    height: 1.6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ClinicCatalogThumbnail extends StatelessWidget {
  const ClinicCatalogThumbnail({
    super.key,
    required this.imageUrl,
    required this.icon,
    this.size = 48,
  });
  final String imageUrl;
  final IconData icon;
  final double size;
  @override
  Widget build(BuildContext context) => imageUrl.isEmpty
      ? Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.goldText(context).withValues(alpha: .10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: AppColors.goldText(context),
            size: size * .45,
          ),
        )
      : LuxuryImage(
          imageUrl: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(14),
          placeholderIcon: icon,
        );
}

/// Wrapping actions below content keeps the editor usable at large text scales.
class ClinicCatalogMiniRow extends StatelessWidget {
  const ClinicCatalogMiniRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.icon,
    required this.onEdit,
    required this.onDelete,
    this.badge,
  });
  final String title, subtitle, imageUrl;
  final IconData icon;
  final VoidCallback onEdit, onDelete;
  final String? badge;
  @override
  Widget build(BuildContext context) {
    final ar = LocaleService().isArabic;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? AppColors.cardSurfaceHover
            : AppColors.lightCardSurfaceHover,
        border: Border.all(color: AppColors.border(context)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClinicCatalogThumbnail(imageUrl: imageUrl, icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.mutedText(context),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldText(context).withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: AppColors.goldText(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: Text(ar ? 'تعديل' : 'Edit'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.isDark(context)
                      ? const Color(0xFFFDA4AF)
                      : const Color(0xFF9F1239),
                ),
                icon: const Icon(Icons.delete_outline, size: 17),
                label: Text(ar ? 'حذف' : 'Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
