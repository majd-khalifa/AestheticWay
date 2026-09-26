import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/rating_chip.dart';
import 'package:aesthetic_way/core/widgets/distance_chip.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/utils/maps_launcher.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';

/// Nearby Verified Clinics Section with Breathable Luxury Cards & Dual-Theme Adaptation
class NearbyClinicsSection extends StatelessWidget {
  final List<ClinicModel> clinics;
  final ValueChanged<ClinicModel> onClinicTap;
  final ValueChanged<ClinicModel> onRequestTap;
  final ValueChanged<ClinicModel> onContactTap;

  const NearbyClinicsSection({
    super.key,
    required this.clinics,
    required this.onClinicTap,
    required this.onRequestTap,
    required this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    if (clinics.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.12 : 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.accentChampagne.withValues(alpha: 0.4),
                        width: 0.7,
                      ),
                    ),
                    child: const Icon(
                      Icons.near_me_outlined,
                      size: 15,
                      color: AppColors.accentChampagne,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.tr('nearby_title'),
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              // Map View Quick Link
              TextButton.icon(
                onPressed: () {
                  final first = clinics.first;
                  MapsLauncher.openMapLocation(
                    latitude: first.latitude,
                    longitude: first.longitude,
                    placeId: first.googlePlaceId,
                    placeName: loc.isArabic ? first.nameAr : first.nameEn,
                  );
                },
                icon: const Icon(Icons.map_outlined, size: 14, color: AppColors.accentChampagne),
                label: Text(
                  loc.tr('map_view'),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accentChampagne,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: clinics.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final clinic = clinics[index];
              return StaggeredEntrance(
                index: index,
                child: _NearbyClinicCard(
                  clinic: clinic,
                  loc: loc,
                  onTap: () => onClinicTap(clinic),
                  onRequestTap: () => onRequestTap(clinic),
                  onContactTap: () => onContactTap(clinic),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NearbyClinicCard extends StatelessWidget {
  final ClinicModel clinic;
  final LocaleService loc;
  final VoidCallback onTap;
  final VoidCallback onRequestTap;
  final VoidCallback onContactTap;

  const _NearbyClinicCard({
    required this.clinic,
    required this.loc,
    required this.onTap,
    required this.onRequestTap,
    required this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return LuxuryCard(
      isVip: clinic.subscriptionTier == SubscriptionTier.vipPlatinum,
      padding: EdgeInsets.zero,
      borderRadius: 18,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // High-resolution rounded image
                LuxuryImage(
                  imageUrl: clinic.coverImageUrl,
                  width: 78,
                  height: 78,
                  borderRadius: BorderRadius.circular(14),
                  fit: BoxFit.cover,
                  placeholderIcon: Icons.local_hospital_outlined,
                  iconSize: 32,
                ),
                const SizedBox(width: 14),
                // Clinic Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              loc.isArabic ? clinic.nameAr : clinic.nameEn,
                              style: AppTypography.cardTitle.copyWith(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        loc.isArabic ? clinic.addressAr : clinic.addressEn,
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.silverMuted : AppColors.lightTextMuted,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        children: [
                          RatingChip(
                            rating: clinic.rating,
                            reviewCount: clinic.reviewCount,
                            isCompact: true,
                            showGoogleSource: true,
                          ),
                          DistanceChip(
                            distanceKm: clinic.distanceKm,
                            areaName: loc.isArabic ? clinic.areaAr : clinic.areaEn,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action Buttons Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardSurfaceSubtle : AppColors.lightCardSurfaceSubtle,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17)),
              border: Border(
                top: BorderSide(
                  color: AppColors.border(context),
                  width: 0.75,
                ),
              ),
            ),
            child: Row(
              children: [
                // Secondary Contact Outline Button
                OutlinedButton(
                  onPressed: onContactTap,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(
                      color: AppColors.border(context),
                      width: 0.8,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    loc.tr('contact_btn'),
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                const Spacer(),
                // Primary Lead CTA Button
                ElevatedButton(
                  onPressed: onRequestTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    loc.tr('request_appointment'),
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.backgroundDeep : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
