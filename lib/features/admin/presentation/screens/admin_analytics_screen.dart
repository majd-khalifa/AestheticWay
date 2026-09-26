import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/tier_badge.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';

/// Super Admin Tab 5: Dedicated Analytics & Patient Engagement Breakdown per Clinic
class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final adminService = AdminPortalService();
    final isDark = AppColors.isDark(context);

    return ListenableBuilder(
      listenable: Listenable.merge([loc, adminService]),
      builder: (context, _) {
        final tableData = adminService.analyticsTable;

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          body: RefreshIndicator(
            onRefresh: () => adminService.loadAnalytics(),
            color: AppColors.accentChampagne,
            backgroundColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
            // Top Overview Banner
            LuxuryCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.insights_rounded, color: AppColors.accentChampagne, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          loc.tr('admin_analytics_title'),
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.tr('admin_analytics_sub'),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.mutedText(context),
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Global Attribution Counters Grid (strictly from backend GET /admin/analytics/)
            Row(
              children: [
                Expanded(
                  child: _AnalyticsHeaderBox(
                    label: loc.tr('admin_total_events'),
                    value: NumberFormat('#,###').format(adminService.analytics.totalEvents),
                    icon: Icons.insights_rounded,
                    isGold: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AnalyticsHeaderBox(
                    label: loc.tr('admin_total_app_opens'),
                    value: NumberFormat('#,###').format(adminService.analytics.appOpens),
                    icon: Icons.smartphone_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AnalyticsHeaderBox(
                    label: loc.tr('admin_clinic_views'),
                    value: NumberFormat('#,###').format(adminService.analytics.clinicViews),
                    icon: Icons.remove_red_eye_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _AnalyticsHeaderBox(
                    label: loc.tr('admin_table_whatsapp'),
                    value: '${adminService.analytics.whatsappTaps}',
                    icon: Icons.chat_bubble_outline_rounded,
                    iconColor: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _AnalyticsHeaderBox(
                    label: loc.tr('admin_table_calls'),
                    value: '${adminService.analytics.callTaps}',
                    icon: Icons.phone_in_talk_rounded,
                    iconColor: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _AnalyticsHeaderBox(
                    label: loc.tr('admin_maps_taps'),
                    value: '${adminService.analytics.mapsTaps}',
                    icon: Icons.map_outlined,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _AnalyticsHeaderBox(
                    label: loc.tr('admin_lead_submissions'),
                    value: '${adminService.analytics.leadSubmissions}',
                    icon: Icons.mark_email_read_outlined,
                    isGold: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Per-Clinic Performance Breakdown Section
            Row(
              children: [
                const Icon(Icons.insights_rounded, size: 16, color: AppColors.accentChampagne),
                const SizedBox(width: 6),
                Text(
                  loc.isArabic ? 'أداء وتفاعل المرضى حسب العيادة' : 'Patient Engagement by Clinic',
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...tableData.map((item) {
              final clinic = adminService.clinics.where((c) => c.id == item.clinicId).firstOrNull;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LuxuryCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clinic Header with Tier
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  clinic != null
                                      ? (loc.isArabic ? clinic.nameAr : clinic.nameEn)
                                      : (loc.isArabic ? item.clinicNameAr : item.clinicNameEn),
                                  style: AppTypography.cardTitle.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  clinic?.city ?? item.city,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.mutedText(context),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TierBadge(tier: clinic?.subscriptionTier ?? item.tier),
                        ],
                      ),
                      const Divider(height: 16),

                      // Metric Columns: Events | Leads | Branches | Offers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _MetricStatItem(
                            label: loc.tr('admin_events_count'),
                            value: NumberFormat('#,###').format(item.eventsCount),
                            isGold: true,
                          ),
                          _MetricStatItem(
                            label: loc.tr('admin_table_leads'),
                            value: '${clinic?.leadsCount ?? item.leads}',
                          ),
                          _MetricStatItem(
                            label: loc.tr('admin_clinic_branches'),
                            value: '${clinic?.branchesCount ?? 0}',
                          ),
                          _MetricStatItem(
                            label: loc.tr('admin_clinic_offers'),
                            value: '${clinic?.offersCount ?? 0}',
                            color: const Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Referral & Rewards Platform Supervision (strictly from backend dashboard)
            LuxuryCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.card_giftcard_rounded, color: AppColors.accentChampagne, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        loc.tr('referral_title'),
                        style: AppTypography.cardTitle.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _AnalyticsHeaderBox(
                          label: loc.tr('admin_total_referrals'),
                          value: '${adminService.dashboard.totalReferrals}',
                          icon: Icons.person_add_alt_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AnalyticsHeaderBox(
                          label: loc.tr('admin_redeemed_codes'),
                          value: '${adminService.dashboard.totalRedeemedReferralCodes}',
                          icon: Icons.check_circle_outline_rounded,
                          isGold: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  },
);
  }
}

class _AnalyticsHeaderBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isGold;
  final Color? iconColor;

  const _AnalyticsHeaderBox({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 10.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: iconColor ?? (isGold ? AppColors.accentChampagne : AppColors.mutedText(context))),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.cardTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isGold ? AppColors.accentChampagne : (isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricStatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isGold;
  final Color? color;

  const _MetricStatItem({
    required this.label,
    required this.value,
    this.isGold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            color: color ?? (isGold ? AppColors.accentChampagne : (isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary)),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 10),
        ),
      ],
    );
  }
}
