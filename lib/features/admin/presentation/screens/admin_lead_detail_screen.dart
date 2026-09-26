import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';
import 'package:aesthetic_way/features/admin/models/admin_lead_model.dart';

/// Super Admin Lead Detail Screen — READ-ONLY Supervision View
/// Ensures strict role separation: Super Admin observes volume & quality without executing clinic operations
class AdminLeadDetailScreen extends StatelessWidget {
  final AdminLeadModel lead;

  const AdminLeadDetailScreen({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    Color statusColor;
    String statusText;
    switch (lead.leadStatus) {
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

    String timeWindowText;
    switch (lead.preferredTimeWindow.toLowerCase()) {
      case 'afternoon':
        timeWindowText = loc.tr('time_afternoon');
        break;
      case 'evening':
        timeWindowText = loc.tr('time_evening');
        break;
      case 'morning':
      default:
        timeWindowText = loc.tr('time_morning');
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        title: Text(
          loc.tr('admin_lead_inspect_title'),
          style: AppTypography.screenTitle.copyWith(
            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Supervision Mode Notice Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.12 : 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accentChampagne.withValues(alpha: 0.45), width: 0.8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.accentChampagne, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    loc.tr('admin_lead_monitoring_banner'),
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Header Status & Reference Card
          LuxuryCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lead.referenceCode,
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentChampagne,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${loc.isArabic ? "تاريخ إرسال الطلب:" : "Received on:"} ${DateFormat('yyyy/MM/dd – hh:mm a').format(lead.createdAt)}',
                  style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Clinic Destination Card
          LuxuryCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.isArabic ? 'العيادة المستلمة للطلب' : 'Recipient Clinic',
                  style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 11),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.apartment_rounded, size: 18, color: AppColors.accentChampagne),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        loc.isArabic ? lead.clinicNameAr : (lead.clinicNameEn.isNotEmpty ? lead.clinicNameEn : lead.clinicNameAr),
                        style: AppTypography.cardTitle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(right: 28),
                  child: Text(
                    loc.isArabic ? lead.branchNameAr : (lead.branchNameEn.isNotEmpty ? lead.branchNameEn : lead.branchNameAr),
                    style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Patient & Service Details Card (Read-Only)
          LuxuryCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.tr('contact_info_title'),
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const Divider(height: 16),
                _ReadOnlyRow(
                  icon: Icons.person_outline_rounded,
                  label: loc.tr('full_name'),
                  value: lead.patientFullName,
                ),
                const SizedBox(height: 10),
                _ReadOnlyRow(
                  icon: Icons.phone_outlined,
                  label: loc.tr('phone_uae'),
                  value: lead.patientPhone,
                ),
                const Divider(height: 20),
                _ReadOnlyRow(
                  icon: Icons.medical_services_outlined,
                  label: loc.isArabic ? 'الخدمة / الباقة المطلوبة' : 'Requested Service',
                  value: lead.serviceNameAr,
                ),
                const SizedBox(height: 10),
                _ReadOnlyRow(
                  icon: Icons.calendar_today_outlined,
                  label: loc.tr('select_date'),
                  value: DateFormat('yyyy/MM/dd').format(lead.preferredDate),
                ),
                const SizedBox(height: 10),
                _ReadOnlyRow(
                  icon: Icons.access_time_rounded,
                  label: loc.tr('preferred_time'),
                  value: timeWindowText,
                ),
                if (lead.notes.isNotEmpty) ...[
                  const Divider(height: 20),
                  _ReadOnlyRow(
                    icon: Icons.notes_rounded,
                    label: loc.tr('notes_opt'),
                    value: lead.notes,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReadOnlyRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.mutedText(context)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 11),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
