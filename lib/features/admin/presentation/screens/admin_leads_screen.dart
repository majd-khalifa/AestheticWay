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

/// Super Admin Tab 3: Platform-wide Consultation Leads Registry with Clinic & Status Filtering
class AdminLeadsScreen extends StatefulWidget {
  const AdminLeadsScreen({super.key});

  @override
  State<AdminLeadsScreen> createState() => _AdminLeadsScreenState();
}

class _AdminLeadsScreenState extends State<AdminLeadsScreen> {
  String? _selectedClinicId;
  int _selectedStatusIndex = 0; // 0: All, 1: New, 2: Contacted, 3: Closed
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final adminService = AdminPortalService();
    final isDark = AppColors.isDark(context);

    return ListenableBuilder(
      listenable: Listenable.merge([loc, adminService]),
      builder: (context, _) {
        AppointmentLeadStatus? statusFilter;
        if (_selectedStatusIndex == 1) statusFilter = AppointmentLeadStatus.sent;
        if (_selectedStatusIndex == 2) statusFilter = AppointmentLeadStatus.contacted;
        if (_selectedStatusIndex == 3) statusFilter = AppointmentLeadStatus.closed;

        var leads = adminService.getFilteredLeads(
          clinicId: _selectedClinicId,
          status: statusFilter,
        );

        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          leads = leads.where((l) =>
              l.patientFullName.toLowerCase().contains(q) ||
              l.patientPhone.contains(q) ||
              l.serviceNameAr.toLowerCase().contains(q) ||
              l.clinicNameAr.toLowerCase().contains(q)).toList();
        }

        final statusTabs = [
          '${loc.tr('status_all')} (${adminService.totalLeadsCount})',
          loc.tr('clinic_lead_status_new'),
          loc.tr('clinic_lead_status_contacted'),
          loc.tr('clinic_lead_status_closed'),
        ];

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          body: Column(
            children: [
              // Supervision Notice Banner
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.12 : 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accentChampagne.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.accentChampagne, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.tr('admin_lead_monitoring_banner'),
                          style: TextStyle(
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: loc.isArabic ? 'بحث بالاسم، العيادة، الخدمة، أو الهاتف...' : 'Search by name, clinic, service or phone...',
                    hintStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.mutedText(context)),
                    filled: true,
                    fillColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context), width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accentChampagne, width: 1.4),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),

              // Clinic Filter Dropdown Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context), width: 0.8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedClinicId,
                      isExpanded: true,
                      dropdownColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                      hint: Row(
                        children: [
                          const Icon(Icons.apartment_rounded, size: 16, color: AppColors.accentChampagne),
                          const SizedBox(width: 8),
                          Text(
                            loc.tr('admin_filter_all_clinics'),
                            style: TextStyle(
                              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            loc.tr('admin_filter_all_clinics'),
                            style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 12.5),
                          ),
                        ),
                        ...adminService.clinics.map((c) {
                          return DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(
                              loc.isArabic ? c.nameAr : c.nameEn,
                              style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 12.5),
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedClinicId = val;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Status Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: List.generate(statusTabs.length, (index) {
                    final isSelected = _selectedStatusIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          statusTabs[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected ? AppColors.backgroundDeep : AppColors.mutedText(context),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.accentChampagne,
                        backgroundColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurface,
                        side: BorderSide(
                          color: isSelected ? AppColors.accentChampagne : AppColors.border(context),
                          width: 0.8,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onSelected: (_) {
                          setState(() {
                            _selectedStatusIndex = index;
                          });
                        },
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 6),

              // Leads Stream
              Expanded(
                child: leads.isEmpty
                    ? Center(
                        child: Text(
                          loc.tr('clinic_no_leads'),
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedText(context)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                        itemCount: leads.length,
                        itemBuilder: (context, index) {
                          final lead = leads[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AdminLeadRegistryCard(
                              lead: lead,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  LuxuryPageRoute(page: AdminLeadDetailScreen(lead: lead)),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminLeadRegistryCard extends StatelessWidget {
  final AppointmentRequestModel lead;
  final VoidCallback onTap;

  const _AdminLeadRegistryCard({required this.lead, required this.onTap});

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
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.apartment_rounded, size: 16, color: AppColors.accentChampagne),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lead.clinicNameAr,
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
          const Divider(height: 14),

          // Patient & Service Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.patientFullName,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('yyyy/MM/dd').format(lead.preferredDate),
                    style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 11),
                  ),
                  Text(
                    lead.referenceCode,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.accentChampagne,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
