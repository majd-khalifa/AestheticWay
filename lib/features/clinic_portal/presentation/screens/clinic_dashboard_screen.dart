import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/tier_badge.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_lead_detail_screen.dart';

/// Clinic Tab 1: Luxury Clinic Dashboard Screen with Key Metrics, Shortcuts & Recent Leads
class ClinicDashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToLeads;
  final VoidCallback onNavigateToOffers;

  const ClinicDashboardScreen({
    super.key,
    required this.onNavigateToLeads,
    required this.onNavigateToOffers,
  });

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final clinicService = ClinicPortalService();
    final isDark = AppColors.isDark(context);
    final clinic = clinicService.activeClinic;

    return ListenableBuilder(
      listenable: Listenable.merge([loc, clinicService]),
      builder: (context, _) {
        final recentLeads = clinicService.clinicLeads.take(4).toList();

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.business_rounded, color: AppColors.accentChampagne, size: 20),
                const SizedBox(width: 8),
                Text(
                  loc.tr('clinic_portal_title'),
                  style: AppTypography.screenTitle.copyWith(
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Clinic Partner Header Card
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        clinic.coverImageUrl,
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 58,
                          height: 58,
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
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${clinic.city} • ${loc.isArabic ? clinic.areaAr : clinic.areaEn}',
                            style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                          ),
                          const SizedBox(height: 6),
                          TierBadge(tier: clinic.subscriptionTier),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4 Metrics Summary Grid
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: loc.tr('clinic_new_leads_count'),
                      value: '${clinicService.newLeadsCount}',
                      icon: Icons.mark_email_unread_rounded,
                      isHighlighted: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      title: loc.tr('clinic_today_leads'),
                      value: '${clinicService.clinicLeads.where((l) => l.createdAt.day == DateTime.now().day).length + 2}',
                      icon: Icons.today_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: loc.tr('clinic_total_leads'),
                      value: '${clinicService.totalLeadsCount}',
                      icon: Icons.groups_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      title: loc.tr('clinic_active_offers_count'),
                      value: '${clinicService.activeOffersCount}',
                      icon: Icons.local_offer_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Quick Actions Row
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
                    child: _ShortcutButton(
                      label: loc.tr('clinic_btn_view_new_leads'),
                      icon: Icons.mark_email_unread_outlined,
                      onTap: onNavigateToLeads,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ShortcutButton(
                      label: loc.tr('clinic_btn_add_offer'),
                      icon: Icons.add_circle_outline_rounded,
                      onTap: onNavigateToOffers,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Recent Consultation Leads Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.tr('clinic_recent_leads'),
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

              if (recentLeads.isEmpty)
                LuxuryCard(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      loc.tr('clinic_no_leads'),
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedText(context)),
                    ),
                  ),
                )
              else
                ...recentLeads.map((lead) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _LeadSummaryTile(
                      lead: lead,
                      onTap: () {
                        Navigator.push(
                          context,
                          LuxuryPageRoute(page: ClinicLeadDetailScreen(lead: lead)),
                        );
                      },
                    ),
                  );
                }),

              const SizedBox(height: 16),

              // Platform Notice Box
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
                    const Icon(Icons.info_outline, color: AppColors.accentChampagne, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        loc.tr('clinic_disclaimer'),
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isHighlighted;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.isHighlighted = false,
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
              Text(
                title,
                style: AppTypography.caption.copyWith(
                  color: AppColors.mutedText(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                icon,
                size: 18,
                color: isHighlighted ? AppColors.accentChampagne : AppColors.mutedText(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.heroTitle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isHighlighted
                  ? AppColors.accentChampagne
                  : (isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ShortcutButton({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context), width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.accentChampagne),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadSummaryTile extends StatelessWidget {
  final AppointmentRequestModel lead;
  final VoidCallback onTap;

  const _LeadSummaryTile({required this.lead, required this.onTap});

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
            child: Icon(
              Icons.person,
              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lead.patientFullName,
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lead.serviceNameAr,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.mutedText(context),
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              statusText,
              style: AppTypography.badge.copyWith(
                color: statusColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
