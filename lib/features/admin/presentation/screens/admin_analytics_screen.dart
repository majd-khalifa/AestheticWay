import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/tier_badge.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';
import 'package:aesthetic_way/features/referral/services/referral_service.dart';
import 'package:aesthetic_way/features/referral/models/referral_model.dart';

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
          body: ListView(
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

            // Global Attribution Counters Grid
            Row(
              children: [
                Expanded(
                  child: _AnalyticsHeaderBox(
                    label: loc.tr('admin_total_app_opens'),
                    value: NumberFormat('#,###').format(adminService.totalAppOpens),
                    icon: Icons.smartphone_rounded,
                    isGold: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AnalyticsHeaderBox(
                    label: loc.tr('admin_active_users'),
                    value: NumberFormat('#,###').format(adminService.activeUsersCount),
                    icon: Icons.people_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _AnalyticsHeaderBox(
                    label: loc.tr('admin_table_leads'),
                    value: '${adminService.totalLeadsCount}',
                    icon: Icons.mark_email_read_outlined,
                    isGold: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AnalyticsHeaderBox(
                    label: loc.tr('admin_table_whatsapp'),
                    value: '${adminService.totalWhatsappTaps}',
                    icon: Icons.chat_bubble_outline_rounded,
                    iconColor: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AnalyticsHeaderBox(
                    label: loc.tr('admin_table_calls'),
                    value: '${adminService.totalCallTaps}',
                    icon: Icons.phone_in_talk_rounded,
                    iconColor: const Color(0xFF3B82F6),
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
                                  loc.isArabic ? item.clinicNameAr : item.clinicNameEn,
                                  style: AppTypography.cardTitle.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.city,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.mutedText(context),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TierBadge(tier: item.tier),
                        ],
                      ),
                      const Divider(height: 16),

                      // Metric Columns: Views | Leads | WhatsApp | Calls | Rate
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _MetricStatItem(
                            label: loc.tr('admin_table_views'),
                            value: NumberFormat('#,###').format(item.appViews),
                          ),
                          _MetricStatItem(
                            label: loc.tr('admin_table_leads'),
                            value: '${item.totalLeads}',
                            isGold: true,
                          ),
                          _MetricStatItem(
                            label: loc.tr('admin_table_whatsapp'),
                            value: '${item.whatsappTaps}',
                            color: const Color(0xFF10B981),
                          ),
                          _MetricStatItem(
                            label: loc.tr('admin_table_calls'),
                            value: '${item.callTaps}',
                            color: const Color(0xFF3B82F6),
                          ),
                          _MetricStatItem(
                            label: loc.tr('admin_table_conversion'),
                            value: '${item.engagementRate.toStringAsFixed(1)}%',
                            isGold: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Referral & Rewards Platform Supervision
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
                          value: '${ReferralService().successfulInvites + 120}',
                          icon: Icons.person_add_alt_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AnalyticsHeaderBox(
                          label: loc.tr('admin_issued_coupons'),
                          value: '${ReferralService().allPlatformCodes.length}',
                          icon: Icons.confirmation_number_outlined,
                          isGold: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AnalyticsHeaderBox(
                          label: loc.tr('admin_redeemed_coupons'),
                          value: '${ReferralService().allPlatformCodes.where((c) => c.status == ReferralCodeStatus.used).length}',
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: const Color(0xFF10B981),
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
