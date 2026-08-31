import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_lead_detail_screen.dart';

/// Super Admin Tab 1: Global Platform Dashboard with Key KPIs, Counters & Live Activity Stream
class AdminDashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToClinics;
  final VoidCallback onNavigateToLeads;
  final VoidCallback onNavigateToAnalytics;

  const AdminDashboardScreen({
    super.key,
    required this.onNavigateToClinics,
    required this.onNavigateToLeads,
    required this.onNavigateToAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final adminService = AdminPortalService();
    final isDark = AppColors.isDark(context);

    return ListenableBuilder(
      listenable: Listenable.merge([loc, adminService]),
      builder: (context, _) {
        final recentLeads = adminService.allLeads.take(4).toList();

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
            // Top Welcome Card
            LuxuryCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.accentChampagne.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accentChampagne.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.shield_outlined, color: AppColors.accentChampagne, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.isArabic ? 'لوحة القيادة والمتابعة المركزية' : 'Platform Operations & Metrics',
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.isArabic ? 'Aesthetic Way — دولة الإمارات' : 'Aesthetic Way — UAE Market',
                          style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Key Metrics Grid (3 Rows x 2 Columns)
            Row(
              children: [
                Expanded(
                  child: _AdminKpiCard(
                    title: loc.tr('admin_total_app_opens'),
                    value: NumberFormat('#,###').format(adminService.totalAppOpens),
                    subtitle: '${NumberFormat('#,###').format(adminService.activeUsersCount)} ${loc.tr('admin_active_users')}',
                    icon: Icons.phone_android_rounded,
                    isGold: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AdminKpiCard(
                    title: loc.tr('admin_active_clinics'),
                    value: '${adminService.activeClinicsCount}',
                    subtitle: '${adminService.clinics.length} ${loc.isArabic ? "مسجلة بالمنصة" : "Registered"}',
                    icon: Icons.apartment_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _AdminKpiCard(
                    title: loc.tr('admin_total_leads'),
                    value: '${adminService.totalLeadsCount}',
                    subtitle: '${adminService.todayLeadsCount} ${loc.tr('admin_today_leads')}',
                    icon: Icons.mark_email_read_rounded,
                    isGold: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AdminKpiCard(
                    title: loc.tr('admin_today_leads'),
                    value: '${adminService.todayLeadsCount}',
                    subtitle: loc.isArabic ? 'طلبات استشارة اليوم' : 'Today\'s Inquiries',
                    icon: Icons.today_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _AdminKpiCard(
                    title: loc.tr('admin_whatsapp_taps'),
                    value: '${adminService.totalWhatsappTaps}',
                    subtitle: loc.isArabic ? 'محادثات فورية مباشرة' : 'Direct Patient Chats',
                    icon: Icons.chat_bubble_outline_rounded,
                    iconColor: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AdminKpiCard(
                    title: loc.tr('admin_call_taps'),
                    value: '${adminService.totalCallTaps}',
                    subtitle: loc.isArabic ? 'مكالمات هاتفية مباشرة' : 'Direct Phone Calls',
                    icon: Icons.phone_in_talk_rounded,
                    iconColor: const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Shortcuts Row
            Text(
              loc.tr('clinic_quick_actions'),
              style: AppTypography.cardTitle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _AdminShortcutBtn(
                    label: loc.tr('admin_nav_clinics'),
                    icon: Icons.apartment_rounded,
                    onTap: onNavigateToClinics,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AdminShortcutBtn(
                    label: loc.tr('admin_nav_leads'),
                    icon: Icons.mark_email_read_rounded,
                    onTap: onNavigateToLeads,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AdminShortcutBtn(
                    label: loc.tr('admin_nav_analytics'),
                    icon: Icons.analytics_rounded,
                    onTap: onNavigateToAnalytics,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recent Live Activity Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.tr('admin_recent_activity'),
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                TextButton(
                  onPressed: onNavigateToLeads,
                  child: Text(
                    loc.isArabic ? 'عرض الكل' : 'View All',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.accentChampagne,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            ...recentLeads.map((lead) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AdminLeadStreamTile(
                  lead: lead,
                  onTap: () {
                    Navigator.push(
                      context,
                      LuxuryPageRoute(page: AdminLeadDetailScreen(lead: lead)),
                    );
                  },
                ),
              );
            }),

            const SizedBox(height: 16),

            // Regulatory Disclaimer Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(context), width: 0.8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_user_outlined, color: AppColors.accentChampagne, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loc.tr('admin_lead_monitoring_note'),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.mutedText(context),
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
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

class _AdminKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool isGold;
  final Color? iconColor;

  const _AdminKpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.isGold = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return LuxuryCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.mutedText(context),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                icon,
                size: 18,
                color: iconColor ?? (isGold ? AppColors.accentChampagne : AppColors.mutedText(context)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.heroTitle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isGold
                  ? AppColors.accentChampagne
                  : (isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              color: AppColors.mutedText(context),
              fontSize: 10.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AdminShortcutBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminShortcutBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context), width: 0.8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.accentChampagne),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminLeadStreamTile extends StatelessWidget {
  final AppointmentRequestModel lead;
  final VoidCallback onTap;

  const _AdminLeadStreamTile({required this.lead, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    Color statusColor;
    String statusText;
    switch (lead.status) {
      case AppointmentLeadStatus.sent:
        statusColor = const Color(0xFFF59E0B);
        statusText = loc.tr('clinic_lead_status_new');
        break;
      case AppointmentLeadStatus.contacted:
        statusColor = const Color(0xFF3B82F6);
        statusText = loc.tr('clinic_lead_status_contacted');
        break;
      case AppointmentLeadStatus.closed:
        statusColor = const Color(0xFF10B981);
        statusText = loc.tr('clinic_lead_status_closed');
        break;
    }

    return LuxuryCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
            child: const Icon(Icons.apartment_rounded, color: AppColors.accentChampagne, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lead.clinicNameAr,
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${lead.patientFullName} • ${lead.serviceNameAr}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.mutedText(context),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
