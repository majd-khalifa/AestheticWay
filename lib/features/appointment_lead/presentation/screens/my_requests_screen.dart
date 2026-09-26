import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/widgets/luxury_shimmer.dart';
import 'package:aesthetic_way/core/widgets/practitioner_badge.dart';
import 'package:aesthetic_way/core/utils/contact_launcher.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';
import 'package:aesthetic_way/features/appointment_lead/data/leads_repository.dart';

/// Screen 18: My Appointment Requests Screen (Lead status tracking without calendar)
class MyRequestsScreen extends StatefulWidget {
  final LeadsRepository? leadsRepository;

  const MyRequestsScreen({
    super.key,
    this.leadsRepository,
  });

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  late final LeadsRepository _leadsRepository;
  int _selectedFilterIndex = 0; // 0: All, 1: Sent, 2: Contacted, 3: Closed
  bool _isLoading = true;
  String? _errorMessage;
  List<AppointmentRequestModel> _allRequests = [];

  @override
  void initState() {
    super.initState();
    _leadsRepository = widget.leadsRepository ?? LeadsRepository();
    _fetchRequests();
  }

  Future<void> _fetchRequests({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final requests = await _leadsRepository.getMyLeads();
      if (!mounted) return;
      setState(() {
        _allRequests = requests;
        _isLoading = false;
        _errorMessage = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    return ListenableBuilder(
      listenable: loc,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Text(
              loc.tr('my_requests_title'),
              style: AppTypography.screenTitle.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          body: _buildBody(context, loc, isDark),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, LocaleService loc, bool isDark) {
    if (_isLoading && _allRequests.isEmpty) {
      return _buildShimmerSkeleton(context);
    }

    if (_errorMessage != null && _allRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.accentChampagne,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _fetchRequests(),
                icon: const Icon(Icons.refresh),
                label: Text(loc.isArabic ? 'إعادة المحاولة' : 'Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.silverPrimary : AppColors.primarySoftNavy,
                  foregroundColor: isDark ? AppColors.backgroundDeep : Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredRequests = _allRequests.where((req) {
      if (_selectedFilterIndex == 1) return req.status == AppointmentLeadStatus.sent;
      if (_selectedFilterIndex == 2) return req.status == AppointmentLeadStatus.contacted;
      if (_selectedFilterIndex == 3) return req.status == AppointmentLeadStatus.closed;
      return true;
    }).toList();

    return Column(
      children: [
        // Filter Chips Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _FilterChip(
                label: '${loc.tr("status_all")} (${_allRequests.length})',
                isSelected: _selectedFilterIndex == 0,
                onTap: () => setState(() => _selectedFilterIndex = 0),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: loc.tr("status_sent"),
                isSelected: _selectedFilterIndex == 1,
                onTap: () => setState(() => _selectedFilterIndex = 1),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: loc.tr("status_contacted"),
                isSelected: _selectedFilterIndex == 2,
                onTap: () => setState(() => _selectedFilterIndex = 2),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: loc.tr("status_closed"),
                isSelected: _selectedFilterIndex == 3,
                onTap: () => setState(() => _selectedFilterIndex = 3),
              ),
            ],
          ),
        ),

        // Request Cards List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _fetchRequests(isRefresh: true),
            color: AppColors.accentChampagne,
            child: filteredRequests.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface(context),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.border(context)),
                                ),
                                child: Icon(
                                  Icons.assignment_outlined,
                                  size: 38,
                                  color: AppColors.mutedText(context),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                loc.tr('no_requests'),
                                style: AppTypography.cardTitle.copyWith(
                                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                loc.tr('no_requests_sub'),
                                style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filteredRequests.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final req = filteredRequests[index];
                      return StaggeredEntrance(
                        index: index,
                        child: _LeadRequestCard(request: req, loc: loc),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerSkeleton(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const LuxuryShimmer(
        width: double.infinity,
        height: 150,
        borderRadius: 18,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentChampagne.withValues(alpha: isDark ? 0.2 : 0.16)
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accentChampagne : AppColors.border(context),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected
                ? AppColors.accentChampagne
                : (isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }
}

class _LeadRequestCard extends StatelessWidget {
  final AppointmentRequestModel request;
  final LocaleService loc;

  const _LeadRequestCard({
    required this.request,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    Color statusBg;
    Color statusBorder;
    Color statusColor;
    String statusText;

    switch (request.status) {
      case AppointmentLeadStatus.sent:
        statusBg = const Color(0xFF594514).withValues(alpha: isDark ? 0.35 : 0.15);
        statusBorder = const Color(0xFFFFC107);
        statusColor = isDark ? const Color(0xFFFFDF7A) : const Color(0xFFB45309);
        statusText = loc.tr('status_sent_label');
        break;
      case AppointmentLeadStatus.contacted:
        statusBg = AppColors.medicalBlue.withValues(alpha: isDark ? 0.25 : 0.12);
        statusBorder = AppColors.medicalBlue;
        statusColor = isDark ? AppColors.silverLight : AppColors.medicalBlue;
        statusText = loc.tr('status_contacted_label');
        break;
      case AppointmentLeadStatus.closed:
        statusBg = isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover;
        statusBorder = AppColors.border(context);
        statusColor = AppColors.mutedText(context);
        statusText = loc.tr('status_closed_label');
        break;
    }

    final clinicName = loc.isArabic
        ? request.clinicNameAr
        : (request.clinicNameEn ?? request.clinicNameAr);
    final branchName = loc.isArabic
        ? request.branchNameAr
        : (request.branchNameEn ?? request.branchNameAr);
    final serviceName = loc.isArabic
        ? request.serviceNameAr
        : (request.serviceNameEn ?? request.serviceNameAr);
    final practitionerName = loc.isArabic
        ? request.practitionerNameAr
        : (request.practitionerNameEn ?? request.practitionerNameAr);
    final timeWindowLabel = loc.isArabic
        ? request.preferredTimeWindow.labelAr
        : request.preferredTimeWindow.labelEn;

    final effectivePhone = request.clinicPhone?.trim() ?? '';
    final effectiveWhatsapp = request.clinicWhatsapp?.trim() ?? '';

    return LuxuryCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Ref and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                request.referenceCode,
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentChampagne,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusBorder, width: 0.7),
                ),
                child: Text(
                  statusText,
                  style: AppTypography.badge.copyWith(
                    color: statusColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            clinicName,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$branchName • $serviceName',
            style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
          ),
          if (practitionerName != null) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  '${loc.tr("practitioner_label")} $practitionerName',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                if (request.practitionerType != null) ...[
                  const SizedBox(width: 6),
                  PractitionerBadge(type: request.practitionerType!, showIcon: false),
                ],
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 13, color: AppColors.mutedText(context)),
              const SizedBox(width: 4),
              Text(
                '${loc.tr("date_label")} ${DateFormat('yyyy/MM/dd').format(request.preferredDate)} ($timeWindowLabel)',
                style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 11),
              ),
            ],
          ),

          // Actions
          if (effectiveWhatsapp.isNotEmpty || effectivePhone.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (effectiveWhatsapp.isNotEmpty) ...[
                  OutlinedButton.icon(
                    onPressed: () => ContactLauncher.openWhatsApp(phoneNumber: effectiveWhatsapp),
                    icon: const Icon(Icons.chat_bubble_outline, size: 13, color: Color(0xFF10B981)),
                    label: Text(
                      loc.tr('whatsapp_btn'),
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 11.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: Color(0xFF10B981), width: 0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (effectivePhone.isNotEmpty) ...[
                  ElevatedButton.icon(
                    onPressed: () => ContactLauncher.makePhoneCall(effectivePhone),
                    icon: Icon(
                      Icons.phone_outlined,
                      size: 13,
                      color: isDark ? AppColors.backgroundDeep : Colors.white,
                    ),
                    label: Text(
                      loc.tr('contact_btn'),
                      style: TextStyle(
                        color: isDark ? AppColors.backgroundDeep : Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
