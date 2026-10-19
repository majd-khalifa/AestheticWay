import 'package:aesthetic_way/core/widgets/pagination_footer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/utils/contact_launcher.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_lead_detail_screen.dart';

/// Clinic Tab 2: Incoming Consultation Leads Manager with Filter Tabs & Quick Actions
class ClinicLeadsScreen extends StatefulWidget {
  const ClinicLeadsScreen({super.key});

  @override
  State<ClinicLeadsScreen> createState() => _ClinicLeadsScreenState();
}

class _ClinicLeadsScreenState extends State<ClinicLeadsScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: New, 2: Contacted, 3: Closed
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ClinicPortalService().loadCollection('leads');
    });
  }

  void _queryChanged() => ClinicPortalService().searchCollection('leads', {
    'search': _searchQuery,
    'status': switch (_selectedFilterIndex) {
      1 => 'new',
      2 => 'contacted',
      3 => 'closed',
      _ => null,
    },
  });

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final clinicService = ClinicPortalService();
    final isDark = AppColors.isDark(context);

    return ListenableBuilder(
      listenable: Listenable.merge([loc, clinicService]),
      builder: (context, _) {
        var leads = clinicService.clinicLeads;

        // Apply Status Filter
        if (_selectedFilterIndex == 1) {
          leads = leads
              .where((l) => l.status == AppointmentLeadStatus.sent)
              .toList();
        } else if (_selectedFilterIndex == 2) {
          leads = leads
              .where((l) => l.status == AppointmentLeadStatus.contacted)
              .toList();
        } else if (_selectedFilterIndex == 3) {
          leads = leads
              .where((l) => l.status == AppointmentLeadStatus.closed)
              .toList();
        }

        // Apply Search Query
        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          leads = leads
              .where(
                (l) =>
                    l.patientFullName.toLowerCase().contains(q) ||
                    l.patientPhone.contains(q) ||
                    l.referenceCode.toLowerCase().contains(q) ||
                    l.serviceNameAr.toLowerCase().contains(q) ||
                    (l.serviceNameEn?.toLowerCase().contains(q) ?? false),
              )
              .toList();
        }

        final filterLabels = [
          '${loc.tr('status_all')} (${clinicService.totalLeadsCount})',
          '${loc.tr('clinic_lead_status_new')} (${clinicService.newLeadsCount})',
          '${loc.tr('clinic_lead_status_contacted')} (${clinicService.contactedLeadsCount})',
          '${loc.tr('clinic_lead_status_closed')} (${clinicService.closedLeadsCount})',
        ];

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Text(
              loc.tr('clinic_nav_leads'),
              style: AppTypography.screenTitle.copyWith(
                color: isDark
                    ? AppColors.silverPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          body: PagedScrollBoundary(
            onLoadMore: () => clinicService.loadMore('leads'),
            child: Column(
              children: [
                // Search Input
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: loc.isArabic
                          ? 'بحث بالاسم، الهاتف، أو الخدمة...'
                          : 'Search by name, phone or service...',
                      hintStyle: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppColors.mutedText(context),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.cardSurface
                          : AppColors.lightCardSurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.border(context),
                          width: 0.8,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.accentChampagne,
                          width: 1.4,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                      _queryChanged();
                    },
                  ),
                ),

                // Filter Tabs Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: List.generate(filterLabels.length, (index) {
                      final isSelected = _selectedFilterIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            filterLabels[index],
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.backgroundDeep
                                  : AppColors.mutedText(context),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.accentChampagne,
                          backgroundColor: isDark
                              ? AppColors.cardSurfaceHover
                              : AppColors.lightCardSurface,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.accentChampagne
                                : AppColors.border(context),
                            width: 0.8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedFilterIndex = index;
                            });
                            _queryChanged();
                          },
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 6),

                // Leads List with Pull-to-Refresh
                Expanded(
                  child:
                      clinicService.isLoading &&
                          clinicService.clinicLeads.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentChampagne,
                            strokeWidth: 2.5,
                          ),
                        )
                      : clinicService.errorMessage != null &&
                            clinicService.clinicLeads.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.amber,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  loc.isArabic
                                      ? 'تعذر تحميل قائمة الطلبات'
                                      : 'Failed to load consultation leads',
                                  style: AppTypography.cardTitle.copyWith(
                                    color: isDark
                                        ? AppColors.silverPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  clinicService.errorMessage!,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.mutedText(context),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => clinicService.loadPortalData(
                                    refresh: true,
                                  ),
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    loc.isArabic ? 'إعادة المحاولة' : 'Retry',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentChampagne,
                                    foregroundColor: AppColors.backgroundDeep,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.accentChampagne,
                          backgroundColor: isDark
                              ? AppColors.cardSurface
                              : Colors.white,
                          onRefresh: () =>
                              clinicService.loadPortalData(refresh: true),
                          child: leads.isEmpty
                              ? ListView(
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                          0.4,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.inbox_outlined,
                                              size: 48,
                                              color: AppColors.mutedText(
                                                context,
                                              ).withValues(alpha: 0.6),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              loc.tr('clinic_no_leads'),
                                              style: AppTypography.bodyMedium
                                                  .copyWith(
                                                    color: AppColors.mutedText(
                                                      context,
                                                    ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    24,
                                  ),
                                  itemCount: leads.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index >= leads.length) {
                                      return PaginationFooter(
                                        loading: clinicService
                                            .collection('leads')
                                            .isLoadingMore,
                                        hasMore: clinicService
                                            .collection('leads')
                                            .hasMore,
                                        error: clinicService
                                            .collection('leads')
                                            .error,
                                        onLoadMore: () =>
                                            clinicService.loadMore('leads'),
                                      );
                                    }

                                    final lead = leads[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: _ClinicLeadCard(
                                        lead: lead,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            LuxuryPageRoute(
                                              page: ClinicLeadDetailScreen(
                                                lead: lead,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ClinicLeadCard extends StatelessWidget {
  final AppointmentRequestModel lead;
  final VoidCallback onTap;

  const _ClinicLeadCard({required this.lead, required this.onTap});

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
          // Top Row: Patient Name, Reference & Status Chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.patientFullName,
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.silverPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${lead.patientPhone} • ${lead.referenceCode}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.mutedText(context),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
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
          const Divider(height: 16),

          // Requested Treatment & Preferred Date
          Row(
            children: [
              const Icon(
                Icons.spa_outlined,
                size: 14,
                color: AppColors.accentChampagne,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  lead.serviceNameAr,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: isDark
                        ? AppColors.silverPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: AppColors.accentChampagne,
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('yyyy/MM/dd').format(lead.createdAt),
                style: AppTypography.caption.copyWith(
                  color: AppColors.mutedText(context),
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${lead.branchNameAr}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.mutedText(context),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons: Call, WhatsApp, View Details
          Row(
            children: [
              InkWell(
                onTap: () => ContactLauncher.makePhoneCall(lead.patientPhone),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardSurfaceHover
                        : AppColors.lightCardSurfaceHover,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.border(context),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        size: 13,
                        color: AppColors.accentChampagne,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        loc.isArabic ? 'اتصال' : 'Call',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.silverPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => ContactLauncher.openWhatsApp(
                  phoneNumber: lead.patientPhone,
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 13,
                        color: Color(0xFF10B981),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'WhatsApp',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                loc.isArabic ? 'التفاصيل ←' : 'Details →',
                style: AppTypography.caption.copyWith(
                  color: AppColors.goldText(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
