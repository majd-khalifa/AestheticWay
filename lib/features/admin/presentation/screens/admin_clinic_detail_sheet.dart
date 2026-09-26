import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/tier_badge.dart';
import 'package:aesthetic_way/core/utils/maps_launcher.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/admin/models/admin_clinic_model.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';

/// Super Admin Modal Sheet for inspecting clinic engagement, metrics, status & maps linking
class AdminClinicDetailSheet extends StatelessWidget {
  final AdminClinicModel clinic;

  const AdminClinicDetailSheet({super.key, required this.clinic});

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final adminService = AdminPortalService();
    final isDark = AppColors.isDark(context);

    return ListenableBuilder(
      listenable: adminService,
      builder: (context, _) {
        final metric = adminService.getMetricForClinic(clinic.id);
        final isActive = metric?.isActive ?? true;
        final clinicOffers = adminService.allOffers.where((o) => o.clinicId == clinic.id).toList();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDeep : AppColors.lightCardSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.border(context), width: 0.8)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.mutedText(context).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Clinic Header Row
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        clinic.coverImageUrl,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 54,
                          height: 54,
                          color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                          child: const Icon(Icons.apartment_rounded, color: AppColors.accentChampagne),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.isArabic ? clinic.nameAr : clinic.nameEn,
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${clinic.city} • ${loc.isArabic ? clinic.areaAr : clinic.areaEn}',
                            style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                          ),
                          const SizedBox(height: 4),
                          TierBadge(tier: clinic.subscriptionTier),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4 Clinic Catalog & Leads Counts (strictly from backend AdminClinicModel)
                Row(
                  children: [
                    Expanded(
                      child: _AdminMetricBox(
                        label: loc.tr('admin_table_leads'),
                        value: '${clinic.leadsCount}',
                        icon: Icons.mark_email_read_outlined,
                        isGold: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AdminMetricBox(
                        label: loc.tr('admin_clinic_branches'),
                        value: '${clinic.branchesCount}',
                        icon: Icons.store_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _AdminMetricBox(
                        label: loc.tr('admin_clinic_practitioners'),
                        value: '${clinic.practitionersCount}',
                        icon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AdminMetricBox(
                        label: loc.tr('admin_clinic_offers'),
                        value: '${clinic.offersCount}',
                        icon: Icons.local_offer_outlined,
                        iconColor: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status & Controls Box
                LuxuryCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.tr('admin_toggle_clinic_status'),
                            style: AppTypography.caption.copyWith(
                              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isActive ? loc.tr('admin_clinic_status_active') : loc.tr('admin_clinic_status_suspended'),
                            style: TextStyle(
                              color: isActive ? const Color(0xFF10B981) : AppColors.errorRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: isActive,
                        activeThumbColor: AppColors.accentChampagne,
                        onChanged: (val) {
                          adminService.toggleClinicStatus(clinic.id);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Open in Google Maps
                SilverButton(
                  label: loc.tr('open_in_maps'),
                  icon: Icons.directions_outlined,
                  height: 42,
                  isFullWidth: true,
                  onPressed: () {
                    MapsLauncher.openDirections(
                      latitude: clinic.latitude,
                      longitude: clinic.longitude,
                      destinationTitle: loc.isArabic ? clinic.nameAr : clinic.nameEn,
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Associated Offers Section
                if (clinicOffers.isNotEmpty) ...[
                  Text(
                    '${loc.tr('clinic_nav_offers')} (${clinicOffers.length})',
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...clinicOffers.map((o) {
                    final isSuspended = adminService.isOfferSuspended(o.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border(context), width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                loc.isArabic ? o.titleAr : o.titleEn,
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              isSuspended ? loc.tr('admin_offer_suspended') : loc.tr('admin_offer_active'),
                              style: TextStyle(
                                fontSize: 10,
                                color: isSuspended ? AppColors.errorRed : const Color(0xFF10B981),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isGold;
  final Color? iconColor;

  const _AdminMetricBox({
    required this.label,
    required this.value,
    required this.icon,
    this.isGold = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context), width: 0.8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor ?? (isGold ? AppColors.accentChampagne : AppColors.mutedText(context))),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 10.5),
              ),
              Text(
                value,
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isGold ? AppColors.accentChampagne : (isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
