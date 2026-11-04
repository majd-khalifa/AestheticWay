import 'dart:async';
import 'package:flutter/material.dart';
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
  bool _choosingDates = false;
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
    _choosingDates = true;
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
    _choosingDates = false;
    if (!mounted || range == null || !_reports.authorized) return;
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
                'Select an ordered period of at most366 days.',
                'اختر فترة مرتبة لا تتجاوز366 يوماً.',
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

  String _label(String key) => switch (key) {
    'clinic_views' => adminText('Clinic profile views', 'مشاهدات ملف العيادة'),
    'whatsapp_taps' => adminText('WhatsApp taps', 'نقرات واتساب'),
    'call_taps' => adminText('Call taps', 'نقرات الاتصال'),
    'maps_taps' => adminText('Maps taps', 'نقرات الخرائط'),
    _ => adminText('Saved consultations', 'الاستشارات المحفوظة'),
  };
  String _coverage(AnalyticsCoverage state) => switch (state) {
    AnalyticsCoverage.complete => adminText(
      'Complete coverage',
      'تغطية مكتملة',
    ),
    AnalyticsCoverage.partial => adminText('Partial coverage', 'تغطية جزئية'),
    AnalyticsCoverage.unavailable => adminText(
      'Coverage unavailable',
      'التغطية غير متاحة',
    ),
  };
  String _value(int? n) => n == null ? '—' : adminNumber(n);
  String _observation(AnalyticsMetric metric) =>
      '${_coverage(metric.coverage)} · ${adminText('Observed', 'مرصود')}: ${adminNumber(metric.recorded)} · ${adminText('Validated/saved', 'متحقق/محفوظ')}: ${adminNumber(metric.trusted)}';

  Widget _metrics(AnalyticsV2Metrics metrics) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          adminText(
            'Canonical total for this clinic',
            'الإجمالي الموثوق لهذه العيادة',
          ),
        ),
        trailing: Text(
          _value(metrics.total),
          key: const ValueKey('analytics-v2-total'),
        ),
        subtitle: Text(
          '${adminText('Observed total', 'الإجمالي المرصود')}: ${adminNumber(metrics.recordedTotal)}',
        ),
      ),
      AdminMetricGrid(
        children: [
          for (final key in analyticsMetricKeys)
            AdminMetricCard(
              label: _label(key),
              value: _value(metrics.values[key]!.count),
              icon: key == 'lead_submissions'
                  ? Icons.mark_email_read_outlined
                  : Icons.insights_outlined,
              caption: _observation(metrics.values[key]!),
            ),
        ],
      ),
      Text(
        adminText(
          'Unique accounts: unavailable',
          'الحسابات الفريدة: غير متاحة',
        ),
        style: TextStyle(color: AppColors.mutedText(context)),
      ),
    ],
  );

  Widget _details(AnalyticsV2Detail detail) {
    final q = _reports.query, clinic = detail.clinic;
    return LuxuryCard(
      key: const ValueKey('analytics-v2-detail'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionTitle(
            clinic.name(LocaleService().isArabic),
            subtitle: '${q.from} — ${q.to} · Asia/Dubai',
          ),
          _metrics(clinic.metrics),
          TextButton.icon(
            icon: const Icon(Icons.mark_email_read_outlined),
            label: Text(
              adminText('View requests in this period', 'عرض طلبات هذه الفترة'),
            ),
            onPressed: () {
              if (!_reports.authorized) return;
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
          AdminSectionTitle(
            adminText('Daily clinic records', 'سجلات العيادة اليومية'),
            subtitle: adminText(
              'Only server-returned days; no unique-user or growth estimates.',
              'الأيام التي أعادها الخادم فقط؛ بلا تقديرات للمستخدمين أو النمو.',
            ),
          ),
          for (final day in detail.days)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(day.date, textDirection: TextDirection.ltr),
              subtitle: Text(
                [
                  for (final key in analyticsMetricKeys)
                    '${_label(key)}: ${_value(day.metrics.values[key]!.count)}',
                ].join(' · '),
              ),
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
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            40 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            AdminSectionTitle(
              adminText('Clinic Analytics V2', 'تحليلات العيادات V2'),
              subtitle: adminText(
                'Canonical counts require complete attested coverage.',
                'الأعداد الموثوقة تتطلب تغطية مكتملة مثبتة.',
              ),
            ),
            Text(
              '${q.from} — ${q.to} · Asia/Dubai',
              textDirection: TextDirection.ltr,
            ),
            TextButton.icon(
              onPressed: _reports.loading ? null : _dates,
              icon: const Icon(Icons.date_range),
              label: Text(
                adminText('Reporting dates · UTC+4', 'فترة التقرير · UTC+4'),
              ),
            ),
            AdminNotice(
              message: adminText(
                '— means unavailable, not zero. Observed records can include legacy events; validated records alone do not prove complete collection. Calls, WhatsApp and Maps are tap intentions, not completed conversions. Historical records are not assumed; coverage reflects this database.',
                '— تعني غير متاح وليست صفراً. قد تشمل السجلات المرصودة أحداثاً قديمة، والسجلات المتحققة وحدها لا تثبت اكتمال الجمع. نقرات التواصل والخرائط نوايا وليست تحويلات مكتملة. لا نفترض وجود السجلات التاريخية؛ التغطية تخص هذه القاعدة.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              maxLength: 120,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                helperText: adminText(
                  'Arabic, English or UUID',
                  'عربي أو إنجليزي أو UUID',
                ),
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
            if (_reports.loading) const LinearProgressIndicator(),
            if (_reports.error != null)
              AdminNotice(
                message: _reports.error!,
                error: true,
                onRetry: () => _reports.load(),
              ),
            if (page != null) ...[
              AdminMetricCard(
                label: adminText(
                  'Platform app opens',
                  'مرات فتح التطبيق على المنصة',
                ),
                value: _value(page.metadata.appOpens.count),
                icon: Icons.smartphone_outlined,
                caption: _observation(page.metadata.appOpens),
              ),
              Text(
                adminText(
                  'No platform clinic total is supplied by this endpoint; page rows are never summed into one.',
                  'لا توفر هذه الواجهة إجمالي نشاط العيادات على المنصة؛ لا نجمع صفوف الصفحة لإنتاجه.',
                ),
              ),
              AdminSectionTitle(
                adminText('Clinic directory', 'دليل العيادات'),
                subtitle:
                    '${adminText('Server results', 'نتائج الخادم')}: ${adminNumber(page.count)} · ${adminText('Page', 'صفحة')} ${adminNumber(q.page)}',
              ),
              if (page.clinics.isEmpty)
                Text(
                  adminText(
                    'No clinic records match these filters.',
                    'لا توجد سجلات عيادات تطابق المرشحات.',
                  ),
                ),
              for (final clinic in page.clinics)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LuxuryCard(
                    child: ListTile(
                      selected: _reports.selectedId == clinic.id,
                      title: Text(clinic.name(LocaleService().isArabic)),
                      subtitle: Text(
                        '${clinic.id}\n${clinic.deleted ? adminText('Archived', 'مؤرشفة') : _status(clinic.status)} · ${_status(clinic.setupStatus)}',
                      ),
                      trailing:
                          _reports.detailLoading &&
                              _reports.selectedId == clinic.id
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: _reports.detailLoading
                          ? null
                          : () => _reports.select(clinic.id),
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
            if (_reports.detailLoading) const LinearProgressIndicator(),
            if (_reports.detailError != null)
              AdminNotice(
                message: _reports.detailError!,
                error: true,
                onRetry: () {
                  if (_reports.selectedId != null) {
                    _reports.select(_reports.selectedId!);
                  }
                },
              ),
            if (_reports.detail != null) _details(_reports.detail!),
          ],
        ),
      );
    },
  );
}
