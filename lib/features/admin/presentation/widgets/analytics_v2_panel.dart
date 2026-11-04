import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/auth/session_snapshot.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../data/analytics_v2_repository.dart';
import '../../models/analytics_v2.dart';
import '../../models/admin_clinic_model.dart';
import '../../models/admin_reporting_period.dart';
import '../../services/analytics_v2_controller.dart';
import '../screens/admin_leads_screen.dart';
import 'admin_components.dart';
import 'analytics_presentation.dart';

class AnalyticsV2Panel extends StatefulWidget {
  const AnalyticsV2Panel({super.key, this.repository, this.initialQuery});
  final AnalyticsV2Repository? repository;
  final AnalyticsV2Query? initialQuery;
  @override
  State<AnalyticsV2Panel> createState() => _AnalyticsV2PanelState();
}

class _AnalyticsV2PanelState extends State<AnalyticsV2Panel> {
  late final AnalyticsV2Controller _reports;
  final _search = TextEditingController();
  Timer? _debounce;
  bool _choosingDates = false, _reportOpen = false, _dailyOpen = false;
  @override
  void initState() {
    super.initState();
    _reports = AnalyticsV2Controller(
      repository: widget.repository,
      initialQuery: widget.initialQuery,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reports.load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _reports.dispose();
    super.dispose();
  }

  Future<void> _dates() async {
    if (_choosingDates || _reports.loading) return;
    setState(() => _choosingDates = true);
    _debounce?.cancel();
    final q = _reports.query;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: AdminReportingPeriod.dubaiToday(),
      helpText: adminText(
        'Reporting dates · Dubai time',
        'فترة التقرير · توقيت دبي',
      ),
      initialDateRange: DateTimeRange(
        start: AdminReportingPeriod.parse(q.from),
        end: AdminReportingPeriod.parse(q.to),
      ),
    );
    if (!mounted) return;
    setState(() => _choosingDates = false);
    if (range == null || !_reports.authorized) return;
    try {
      await _reports.load(
        filters: q.copyWith(
          from: AdminReportingPeriod.format(range.start),
          to: AdminReportingPeriod.format(range.end),
          page: 1,
          search: _search.text.trim(),
        ),
      );
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              adminText(
                'Select an ordered period of at most 366 days.',
                'اختر فترة مرتبة لا تتجاوز 366 يوماً.',
              ),
            ),
          ),
        );
      }
    }
  }

  String _status(String key) => switch (key) {
    'active' => adminText('Active', 'نشطة'),
    'pending' => adminText('Pending', 'قيد الانتظار'),
    'suspended' => adminText('Suspended', 'موقوفة'),
    'rejected' => adminText('Rejected', 'مرفوضة'),
    'approved' => adminText('Approved', 'معتمدة'),
    'draft' => adminText('Draft', 'مسودة'),
    'submitted' => adminText('Submitted', 'مقدمة للمراجعة'),
    _ => '—',
  };

  Future<void> _openReport(AnalyticsV2Clinic clinic) async {
    if (_reportOpen || !_reports.authorized) return;
    _reportOpen = true;
    _dailyOpen = false;
    final session = SessionSnapshot();
    unawaited(_reports.select(clinic.id));
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: AppColors.bg(context),
        constraints: const BoxConstraints(maxWidth: 1100),
        builder: (sheet) => FractionallySizedBox(
          heightFactor: .94,
          child: ListenableBuilder(
            listenable: Listenable.merge([_reports, LocaleService()]),
            builder: (context, _) {
              if (!_reports.authorized || !session.isCurrent) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        adminText(
                          'This report is no longer available.',
                          'لم يعد هذا التقرير متاحاً.',
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(sheet),
                        child: Text(adminText('Close', 'إغلاق')),
                      ),
                    ],
                  ),
                );
              }
              final detail = _reports.detail;
              final q = _reports.query;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            clinic.name(LocaleService().isArabic),
                            style: TextStyle(
                              color: AppColors.text(context),
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: adminText(
                            'Close clinic report',
                            'إغلاق تقرير العيادة',
                          ),
                          onPressed: () => Navigator.pop(sheet),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${q.from} — ${q.to} · UTC+4',
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.mutedText(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnalyticsPage(
                      children: [
                        if (_reports.detailLoading) ...[
                          const LinearProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            adminText(
                              'Loading clinic report…',
                              'جارٍ تحميل تقرير العيادة…',
                            ),
                            semanticsLabel: adminText(
                              'Loading clinic report',
                              'جارٍ تحميل تقرير العيادة',
                            ),
                          ),
                        ],
                        if (_reports.detailError != null)
                          AdminNotice(
                            message: _reports.detailError!,
                            error: true,
                            onRetry: () => _reports.select(clinic.id),
                          ),
                        if (detail != null) _details(detail, session),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    } finally {
      _reportOpen = false;
    }
  }

  Widget _details(AnalyticsV2Detail detail, SessionSnapshot session) {
    final q = _reports.query, clinic = detail.clinic;
    return Column(
      key: const ValueKey('analytics-v2-detail'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LuxuryCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      adminText('Canonical total', 'الإجمالي المعتمد'),
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    analyticsValue(clinic.metrics.total),
                    key: const ValueKey('analytics-v2-total'),
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                '${adminText('Observed total', 'الإجمالي المرصود')} ${adminNumber(clinic.metrics.recordedTotal)}',
                style: TextStyle(
                  color: AppColors.mutedText(context),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnalyticsKpiGrid(
          children: [
            for (final key in analyticsMetricKeys)
              AnalyticsMetricTile(
                label: analyticsLabel(key),
                value: analyticsValue(clinic.metrics.values[key]!.count),
                metric: clinic.metrics.values[key],
                valueKey: ValueKey('clinic-$key-canonical'),
                trustedLabel: key == 'lead_submissions'
                    ? adminText('Saved', 'محفوظ')
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.mark_email_read_outlined, size: 18),
          label: Text(
            adminText('View requests in this period', 'عرض طلبات هذه الفترة'),
          ),
          onPressed: () {
            if (!_reports.authorized || !session.isCurrent) return;
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminLeadsScreen(
                  initialClinic: AdminClinicModel.fromJson({
                    'id': clinic.id,
                    'name_en': clinic.nameEn,
                    'name_ar': clinic.nameAr,
                  }),
                  dateFrom: q.from,
                  dateTo: q.to,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        AnalyticsDisclosure(
          key: ValueKey(
            'daily-${clinic.id}-${q.from}-${q.to}-${detail.seriesPage}',
          ),
          title: adminText('Daily clinic records', 'سجلات العيادة اليومية'),
          subtitle:
              '${adminText('Reported days', 'الأيام الواردة')}: ${adminNumber(detail.dayCount)} · ${adminText('Page', 'صفحة')} ${adminNumber(detail.seriesPage)}',
          initiallyExpanded: _dailyOpen,
          onExpansionChanged: (value) => _dailyOpen = value,
          children: [
            _DailyReport(
              key: ValueKey('dates-${clinic.id}-${detail.seriesPage}'),
              detail: detail,
            ),
            Wrap(
              spacing: 12,
              children: [
                TextButton(
                  onPressed: detail.seriesPage > 1 && !_reports.detailLoading
                      ? () => _reports.select(
                          clinic.id,
                          seriesPage: detail.seriesPage - 1,
                        )
                      : null,
                  child: Text(adminText('Previous days', 'الأيام السابقة')),
                ),
                TextButton(
                  onPressed: detail.hasMoreDays && !_reports.detailLoading
                      ? () => _reports.select(
                          clinic.id,
                          seriesPage: detail.seriesPage + 1,
                        )
                      : null,
                  child: Text(adminText('Next days', 'الأيام التالية')),
                ),
              ],
            ),
          ],
        ),
        AnalyticsHelp(),
        AnalyticsDisclosure(
          title: adminText('Clinic record details', 'تفاصيل سجل العيادة'),
          children: [
            Text('${_status(clinic.status)} · ${_status(clinic.setupStatus)}'),
            if (clinic.deleted) Text(adminText('Archived', 'مؤرشفة')),
            SelectableText(clinic.id, textDirection: TextDirection.ltr),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_reports, LocaleService()]),
    builder: (context, _) {
      if (!_reports.authorized) {
        return Center(
          child: Text(
            adminText(
              'Super Admin access is required.',
              'يتطلب الوصول حساب مشرف عام.',
            ),
          ),
        );
      }
      final page = _reports.page, q = _reports.query;
      return RefreshIndicator(
        onRefresh: () => _reports.load(),
        child: AnalyticsPage(
          children: [
            AnalyticsPeriod(
              title: adminText('Clinic Analytics V2', 'تحليلات العيادات V2'),
              period: '${q.from} — ${q.to}',
              onChoose: _reports.loading ? null : _dates,
              busy: _choosingDates,
            ),
            const SizedBox(height: 12),
            LuxuryCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                children: [
                  TextField(
                    controller: _search,
                    maxLength: 120,
                    decoration: InputDecoration(
                      counterText: '',
                      prefixIcon: const Icon(Icons.search),
                      labelText: adminText('Search clinics', 'بحث العيادات'),
                    ),
                    onChanged: (value) {
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 350), () {
                        if (mounted) {
                          _reports.load(
                            filters: _reports.query.copyWith(
                              search: value.trim(),
                              page: 1,
                            ),
                          );
                        }
                      });
                    },
                  ),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      adminText('Filters', 'المرشحات'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: q.includeDeleted
                        ? Text(
                            adminText(
                              'Archived clinics included',
                              'تشمل العيادات المؤرشفة',
                            ),
                          )
                        : null,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: q.includeDeleted,
                        title: Text(
                          adminText(
                            'Include archived clinics',
                            'تضمين العيادات المؤرشفة',
                          ),
                        ),
                        onChanged: (value) {
                          _debounce?.cancel();
                          _reports.load(
                            filters: q.copyWith(
                              includeDeleted: value,
                              search: _search.text.trim(),
                              page: 1,
                            ),
                          );
                        },
                      ),
                      Text(
                        adminText(
                          'Search Arabic, English or an exact clinic UUID.',
                          'ابحث بالعربية أو الإنجليزية أو بمعرّف العيادة الكامل.',
                        ),
                        style: TextStyle(
                          color: AppColors.mutedText(context),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AnalyticsHelp(),
            if (_reports.loading) const LinearProgressIndicator(),
            if (_reports.error != null)
              AdminNotice(
                message: _reports.error!,
                error: true,
                onRetry: () => _reports.load(),
              ),
            if (page != null) ...[
              AnalyticsMetricTile(
                label: adminText(
                  'Platform app opens',
                  'مرات فتح التطبيق على المنصة',
                ),
                value: analyticsValue(page.metadata.appOpens.count),
                metric: page.metadata.appOpens,
                valueKey: const ValueKey('analytics-platform-app-opens'),
              ),
              AdminSectionTitle(
                adminText('Clinic directory', 'دليل العيادات'),
                subtitle:
                    '${adminText('Server results', 'نتائج الخادم')}: ${adminNumber(page.count)} · ${adminText('Page', 'صفحة')} ${adminNumber(q.page)}',
              ),
              if (page.clinics.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    adminText(
                      'No clinic records match these filters.',
                      'لا توجد سجلات عيادات تطابق المرشحات.',
                    ),
                  ),
                ),
              for (final clinic in page.clinics)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LuxuryCard(
                    padding: EdgeInsets.zero,
                    customBorder: Border.all(
                      color: _reports.selectedId == clinic.id
                          ? AppColors.goldText(context)
                          : AppColors.border(context),
                      width: .8,
                    ),
                    child: ListTile(
                      key: ValueKey('analytics-clinic-${clinic.id}'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      title: Text(
                        clinic.name(LocaleService().isArabic),
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      subtitle: Text(
                        '${clinic.deleted ? adminText('Archived', 'مؤرشفة') : _status(clinic.status)} · ${_status(clinic.setupStatus)}',
                        style: TextStyle(
                          color: AppColors.mutedText(context),
                          fontSize: 11.5,
                        ),
                      ),
                      trailing: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_left
                            : Icons.chevron_right,
                        size: 20,
                      ),
                      onTap: () => _openReport(clinic),
                    ),
                  ),
                ),
              Wrap(
                spacing: 12,
                children: [
                  TextButton(
                    onPressed: q.page > 1 && !_reports.loading
                        ? () => _reports.load(
                            filters: q.copyWith(page: q.page - 1),
                          )
                        : null,
                    child: Text(adminText('Previous page', 'الصفحة السابقة')),
                  ),
                  TextButton(
                    onPressed: page.hasNext && !_reports.loading
                        ? () => _reports.load(
                            filters: q.copyWith(page: q.page + 1),
                          )
                        : null,
                    child: Text(adminText('Next page', 'الصفحة التالية')),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _DailyReport extends StatefulWidget {
  const _DailyReport({super.key, required this.detail});
  final AnalyticsV2Detail detail;
  @override
  State<_DailyReport> createState() => _DailyReportState();
}

class _DailyReportState extends State<_DailyReport> {
  late String? _date = widget.detail.days.firstOrNull?.date;
  @override
  Widget build(BuildContext context) {
    final days = widget.detail.days;
    if (days.isEmpty) {
      return Text(
        adminText(
          'No reported dates on this page.',
          'لا توجد تواريخ واردة في هذه الصفحة.',
        ),
      );
    }
    final selected = days.firstWhere((day) => day.date == _date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: const ValueKey('analytics-reported-date'),
          initialValue: _date,
          isExpanded: true,
          itemHeight: null,
          menuMaxHeight: 320,
          decoration: InputDecoration(
            labelText: adminText('Reported date', 'التاريخ الوارد'),
          ),
          items: [
            for (final day in days)
              DropdownMenuItem(
                value: day.date,
                child: Text(
                  '${day.date} · ${adminText('Observed', 'مرصود')} ${adminNumber(day.metrics.recordedTotal)}',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _date = value);
          },
        ),
        const SizedBox(height: 12),
        Text(
          adminText('Canonical counts', 'الأعداد المعتمدة'),
          style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
        ),
        AnalyticsDailyMetrics(metrics: selected.metrics),
      ],
    );
  }
}
