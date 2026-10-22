import 'package:aesthetic_way/core/theme/patient_design.dart';
import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/core/widgets/pagination_footer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/widgets/luxury_shimmer.dart';
import 'package:aesthetic_way/core/widgets/practitioner_badge.dart';
import 'package:aesthetic_way/core/utils/contact_launcher.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';
import 'package:aesthetic_way/features/appointment_lead/data/leads_repository.dart';

/// Screen 18: My Appointment Requests Screen (Lead status tracking without calendar)
class MyRequestsScreen extends StatefulWidget {
  final LeadsRepository? leadsRepository;

  const MyRequestsScreen({super.key, this.leadsRepository});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  late final LeadsRepository _leadsRepository;
  int _selectedFilterIndex = 0; // 0: All, 1: Sent, 2: Contacted, 3: Closed
  late final PagedCollection<AppointmentRequestModel> _paging;
  bool get _isLoading => _paging.isLoading && _paging.items.isEmpty;
  String? get _errorMessage => _paging.items.isEmpty ? _paging.error : null;
  List<AppointmentRequestModel> get _allRequests => _paging.items;
  void _pageChanged() {
    if (mounted) setState(() {});
  }

  Map<String, dynamic> get _query => {
    'status': switch (_selectedFilterIndex) {
      1 => 'new',
      2 => 'contacted',
      3 => 'closed',
      _ => null,
    },
  };
  void _setFilter(int index) {
    if (index == _selectedFilterIndex) return;
    setState(() => _selectedFilterIndex = index);
    _paging.refresh(query: _query);
  }

  @override
  void initState() {
    super.initState();
    _leadsRepository = widget.leadsRepository ?? LeadsRepository();
    _paging = PagedCollection<AppointmentRequestModel>(
      loader: (page, q) => _leadsRepository.getMyLeads(
        page: page,
        status: q['status'] as String?,
      ),
      keyOf: (item) => item.id,
    )..addListener(_pageChanged);
    LeadsRepository.refreshNotifier.addListener(_onExternalRefresh);
    _fetchRequests();
  }

  @override
  void dispose() {
    LeadsRepository.refreshNotifier.removeListener(_onExternalRefresh);
    _paging.dispose();
    super.dispose();
  }

  void _onExternalRefresh() {
    if (mounted) {
      _fetchRequests(isRefresh: true);
    }
  }

  Future<void> _fetchRequests({bool isRefresh = false}) =>
      _paging.refresh(query: _query);

  @override
  Widget build(BuildContext context) => PatientDesign(builder: _buildPatient);

  Widget _buildPatient(BuildContext context) {
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
                color: isDark
                    ? AppColors.silverPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            automaticallyImplyLeading: true,
          ),
          body: PagedScrollBoundary(
            onLoadMore: _paging.loadMore,
            child: _buildBody(context, loc, isDark),
          ),
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
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _fetchRequests(),
                icon: const Icon(Icons.refresh),
                label: Text(loc.isArabic ? 'إعادة المحاولة' : 'Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.silverPrimary
                      : AppColors.primarySoftNavy,
                  foregroundColor: isDark
                      ? AppColors.backgroundDeep
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredRequests = _allRequests.where((req) {
      if (_selectedFilterIndex == 1) {
        return req.status == AppointmentLeadStatus.sent;
      }
      if (_selectedFilterIndex == 2) {
        return req.status == AppointmentLeadStatus.contacted;
      }
      if (_selectedFilterIndex == 3) {
        return req.status == AppointmentLeadStatus.closed;
      }
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
                label: loc.tr("status_all"),
                isSelected: _selectedFilterIndex == 0,
                onTap: () => _setFilter(0),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: loc.tr("status_sent"),
                isSelected: _selectedFilterIndex == 1,
                onTap: () => _setFilter(1),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: loc.tr("status_contacted"),
                isSelected: _selectedFilterIndex == 2,
                onTap: () => _setFilter(2),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: loc.tr("status_closed"),
                isSelected: _selectedFilterIndex == 3,
                onTap: () => _setFilter(3),
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
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface(context),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.border(context),
                                  ),
                                ),
                                child: Icon(
                                  Icons.assignment_outlined,
                                  size: 38,
                                  color: AppColors.mutedText(context),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                loc.tr(
                                  _selectedFilterIndex == 0
                                      ? 'no_requests'
                                      : 'no_requests_for_status',
                                ),
                                style: AppTypography.cardTitle.copyWith(
                                  color: isDark
                                      ? AppColors.silverPrimary
                                      : AppColors.lightTextPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                loc.tr(
                                  _selectedFilterIndex == 0
                                      ? 'no_requests_sub'
                                      : 'no_requests_for_status_sub',
                                ),
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.mutedText(context),
                                ),
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
                    itemCount: filteredRequests.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= filteredRequests.length) {
                        return Column(
                          children: [
                            if (_paging.error != null)
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  _paging.error!,
                                  style: TextStyle(
                                    color: AppColors.subtext(context),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            PaginationFooter(
                              loading: _paging.isLoadingMore,
                              hasMore: _paging.hasMore,
                              error: _paging.error,
                              onLoadMore: _paging.loadMore,
                            ),
                          ],
                        );
                      }

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

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppColors.accentChampagne.withValues(
        alpha: isDark ? .2 : .16,
      ),
      backgroundColor: AppColors.surface(context),
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.goldText(context)
            : AppColors.text(context),
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}

class _LeadRequestCard extends StatelessWidget {
  final AppointmentRequestModel request;
  final LocaleService loc;

  const _LeadRequestCard({required this.request, required this.loc});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    Color statusBg;
    Color statusBorder;
    Color statusColor;
    String statusText;

    switch (request.status) {
      case AppointmentLeadStatus.sent:
        statusBg = const Color(
          0xFF594514,
        ).withValues(alpha: isDark ? 0.35 : 0.15);
        statusBorder = const Color(0xFFFFC107);
        statusColor = isDark
            ? const Color(0xFFFFDF7A)
            : const Color(0xFFB45309);
        statusText = loc.tr('status_sent_label');
        break;
      case AppointmentLeadStatus.contacted:
        statusBg = AppColors.medicalBlue.withValues(
          alpha: isDark ? 0.25 : 0.12,
        );
        statusBorder = AppColors.medicalBlue;
        statusColor = isDark ? AppColors.silverLight : AppColors.medicalBlue;
        statusText = loc.tr('status_contacted_label');
        break;
      case AppointmentLeadStatus.closed:
        statusBg = isDark
            ? AppColors.cardSurfaceHover
            : AppColors.lightCardSurfaceHover;
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

    final effectivePhone = request.clinicPhone?.trim() ?? '';
    final effectiveWhatsapp = request.clinicWhatsapp?.trim() ?? '';

    final isProductLead = request.isProductInquiry;

    return LuxuryCard(
      onTap: () => _showLeadDetailsSheet(
        context,
        statusBg,
        statusBorder,
        statusColor,
        statusText,
      ),
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Ref and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    request.referenceCode,
                    textDirection: TextDirection.ltr,
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.goldText(context),
                    ),
                  ),
                  if (isProductLead) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentChampagne.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        loc.isArabic ? 'استفسار منتج' : 'Product',
                        style: AppTypography.badge.copyWith(
                          color: AppColors.goldText(context),
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ],
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
              color: isDark
                  ? AppColors.textPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            branchName.isNotEmpty ? '$branchName • $serviceName' : serviceName,
            style: AppTypography.caption.copyWith(
              color: AppColors.mutedText(context),
            ),
          ),
          if (!isProductLead &&
              practitionerName != null &&
              practitionerName.isNotEmpty) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${loc.tr("practitioner_label")} $practitionerName',
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.silverPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                if (request.practitionerType != null) ...[
                  const SizedBox(width: 6),
                  PractitionerBadge(
                    type: request.practitionerType!,
                    showIcon: false,
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: AppColors.mutedText(context),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${loc.isArabic ? "تاريخ الطلب:" : "Submitted:"} ${DateFormat('yyyy/MM/dd').format(request.createdAt.toLocal())}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.mutedText(context),
                    fontSize: 11,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.mutedText(context),
              ),
            ],
          ),

          // Actions
          if (!isProductLead &&
              (effectiveWhatsapp.isNotEmpty || effectivePhone.isNotEmpty)) ...[
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (effectiveWhatsapp.isNotEmpty) ...[
                  OutlinedButton.icon(
                    onPressed: () => ContactLauncher.openWhatsApp(
                      phoneNumber: effectiveWhatsapp,
                    ),
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      size: 13,
                      color: Color(0xFF10B981),
                    ),
                    label: Text(
                      loc.tr('whatsapp_btn'),
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(
                        color: Color(0xFF10B981),
                        width: 0.8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (effectivePhone.isNotEmpty) ...[
                  ElevatedButton.icon(
                    onPressed: () =>
                        ContactLauncher.makePhoneCall(effectivePhone),
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
                      backgroundColor: isDark
                          ? AppColors.silverPrimary
                          : AppColors.lightTextPrimary,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  void _showLeadDetailsSheet(
    BuildContext context,
    Color statusBg,
    Color statusBorder,
    Color statusColor,
    String statusText,
  ) {
    final isDark = AppColors.isDark(context);
    final isProductLead = request.isProductInquiry;
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
    final effectivePhone = request.clinicPhone?.trim() ?? '';
    final effectiveWhatsapp = request.clinicWhatsapp?.trim() ?? '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Directionality(
          textDirection: loc.textDirection,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: BoxDecoration(
              color: AppColors.surface(sheetCtx),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: AppColors.border(sheetCtx)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.mutedText(
                          sheetCtx,
                        ).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.isArabic ? 'تفاصيل الطلب' : 'Request Details',
                              style: AppTypography.screenTitle.copyWith(
                                color: isDark
                                    ? AppColors.textPrimary
                                    : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              request.referenceCode,
                              textDirection: TextDirection.ltr,
                              style: AppTypography.cardTitle.copyWith(
                                color: AppColors.goldText(context),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: statusBorder, width: 0.8),
                        ),
                        child: Text(
                          statusText,
                          style: AppTypography.badge.copyWith(
                            color: statusColor,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  _DetailModalRow(
                    label: loc.isArabic ? 'العيادة' : 'Clinic',
                    value: clinicName,
                  ),
                  if (!isProductLead && branchName.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _DetailModalRow(
                      label: loc.isArabic ? 'الفرع' : 'Branch',
                      value: branchName,
                    ),
                  ],
                  const SizedBox(height: 10),
                  _DetailModalRow(
                    label: isProductLead
                        ? (loc.isArabic ? 'المنتج' : 'Product')
                        : (loc.isArabic
                              ? 'الخدمة / الإجراء'
                              : 'Service / Treatment'),
                    value: serviceName,
                  ),
                  if (!isProductLead &&
                      practitionerName != null &&
                      practitionerName.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _DetailModalRow(
                      label: loc.isArabic ? 'الممارس الصحي' : 'Practitioner',
                      value: practitionerName,
                    ),
                  ],
                  const SizedBox(height: 10),
                  _DetailModalRow(
                    label: loc.isArabic ? 'تاريخ الإرسال' : 'Created Date',
                    value: DateFormat(
                      'yyyy/MM/dd • hh:mm a',
                    ).format(request.createdAt.toLocal()),
                  ),
                  if (request.notes != null &&
                      request.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _DetailModalRow(
                      label: loc.isArabic
                          ? 'الاستفسار / الملاحظات'
                          : 'Inquiry / Notes',
                      value: request.notes!.trim(),
                    ),
                  ],
                  if (!isProductLead &&
                      (effectiveWhatsapp.isNotEmpty ||
                          effectivePhone.isNotEmpty)) ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        if (effectiveWhatsapp.isNotEmpty)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => ContactLauncher.openWhatsApp(
                                phoneNumber: effectiveWhatsapp,
                              ),
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                                size: 16,
                                color: Color(0xFF10B981),
                              ),
                              label: Text(
                                loc.tr('whatsapp_btn'),
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF10B981),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        if (effectiveWhatsapp.isNotEmpty &&
                            effectivePhone.isNotEmpty)
                          const SizedBox(width: 10),
                        if (effectivePhone.isNotEmpty)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  ContactLauncher.makePhoneCall(effectivePhone),
                              icon: Icon(
                                Icons.phone_outlined,
                                size: 16,
                                color: isDark
                                    ? AppColors.backgroundDeep
                                    : Colors.white,
                              ),
                              label: Text(
                                loc.tr('contact_btn'),
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.backgroundDeep
                                      : Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? AppColors.silverPrimary
                                    : AppColors.lightTextPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailModalRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailModalRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.mutedText(context),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
