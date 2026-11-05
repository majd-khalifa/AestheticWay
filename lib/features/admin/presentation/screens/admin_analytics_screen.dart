import '../../../../core/widgets/lazy_tab_stack.dart';
import 'package:flutter/material.dart';
import '../../../../core/auth/session_snapshot.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bounded_catalog_preview.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/widgets/tier_badge.dart';
import '../../../../core/widgets/paged_entity_picker.dart';
import '../../models/admin_clinic_model.dart';
import '../../models/admin_reporting_period.dart';
import 'admin_clinic_detail_sheet.dart';
import 'admin_leads_screen.dart';
import '../../models/admin_analytics_model.dart';
import '../../services/admin_portal_service.dart';
import '../widgets/admin_components.dart';
import '../widgets/analytics_v2_panel.dart';
import '../widgets/analytics_presentation.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key, this.initialTab = 0});
  final int initialTab;
  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final _service = AdminPortalService();
  String? _from, _to;
  AdminClinicModel? _clinic;
  SessionSnapshot? _clinicSession;
  bool _choosingClinic = false;
  late bool _legacy;
  @override
  void initState() {
    super.initState();
    _legacy = widget.initialTab == 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _legacy) _load();
    });
  }

  Future<void> _load({bool refresh = false}) async {
    if (!_service.canManage) return;
    await Future.wait([
      _service.loadAnalytics(dateFrom: _from, dateTo: _to, refresh: refresh),
      _service.loadReferralAnalytics(refresh: refresh),
    ]);
  }

  Future<void> _chooseDates() async {
    final today = AdminReportingPeriod.dubaiToday();
    final a = _service.analytics;
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today,
      currentDate: today,
      helpText: adminText(
        'Reporting dates · Dubai time',
        'فترة التقرير · توقيت دبي',
      ),
      initialDateRange: DateTimeRange(
        start: AdminReportingPeriod.parse(
          _from ??
              a.dateFrom ??
              AdminReportingPeriod.format(
                today.subtract(const Duration(days: 30)),
              ),
        ),
        end: AdminReportingPeriod.parse(
          _to ?? a.dateTo ?? AdminReportingPeriod.format(today),
        ),
      ),
    );
    if (!mounted || result == null || !_service.canManage) return;
    setState(() {
      _from = AdminReportingPeriod.format(result.start);
      _to = AdminReportingPeriod.format(result.end);
    });
    await _load(refresh: true);
  }

  Future<void> _chooseClinic() async {
    if (_choosingClinic || !_service.canManage) return;
    final session = SessionSnapshot();
    setState(() => _choosingClinic = true);
    try {
      final result = await showPagedEntityPicker<AdminClinicModel>(
        context,
        title: adminText('Select any clinic', 'اختر أي عيادة'),
        hint: LocaleService().tr('admin_clinic_search_hint'),
        clearLabel: adminText('Clear selection', 'إلغاء الاختيار'),
        selectedKey: _clinic?.id,
        keyOf: (c) => c.id,
        labelOf: (c) => c.localizedName(arabic: LocaleService().isArabic),
        loader: (page, search) => _service.getClinicRecordsPage(page, search),
      );
      if (!mounted ||
          result == null ||
          !session.isCurrent ||
          !_service.canManage) {
        return;
      }
      setState(() {
        _clinic = result.value;
        _clinicSession = session;
      });
      if (result.value != null) {
        await _service.loadClinicDetail(result.value!.id, refresh: true);
      }
    } finally {
      if (mounted) setState(() => _choosingClinic = false);
    }
  }

  AnalyticsMetricTile _metric(
    AdminAnalyticsModel a,
    String key,
    String label,
    IconData _,
  ) => AnalyticsMetricTile(
    label: label,
    value: a.recordedCount(key) == null
        ? '—'
        : adminNumber(a.recordedCount(key)!),
    caption: key == 'lead_submissions'
        ? adminText('Saved Lead records', 'سجلات طلبات محفوظة')
        : adminText('Recorded · unverified', 'مسجل · غير متحقق'),
  );

  Widget _clinicRecords() {
    final selected = _clinicSession?.isCurrent == true ? _clinic : null;
    final detail = selected == null ? null : _service.clinicDetail(selected.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionTitle(
          adminText('Inspect any clinic', 'فحص أي عيادة'),
          subtitle: adminText(
            'Operational records · non-archived clinics',
            'السجلات التشغيلية · العيادات غير المؤرشفة',
          ),
        ),
        OutlinedButton.icon(
          onPressed: _choosingClinic ? null : _chooseClinic,
          icon: const Icon(Icons.search),
          label: Text(
            selected?.localizedName(arabic: LocaleService().isArabic) ??
                adminText('Select any clinic', 'اختر أي عيادة'),
          ),
        ),
        if (selected != null) ...[
          if (_service.clinicDetailLoading(selected.id))
            const LinearProgressIndicator(),
          if (_service.clinicDetailError(selected.id) != null)
            AdminNotice(
              message: _service.clinicDetailError(selected.id)!,
              error: true,
              onRetry: () =>
                  _service.loadClinicDetail(selected.id, refresh: true),
            ),
          if (detail != null &&
              _service.clinicDetailError(selected.id) == null) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                adminText(
                  'All-time saved consultations',
                  'طلبات الاستشارة المحفوظة طوال المدة',
                ),
              ),
              trailing: Text(
                detail.hasLeadCount ? adminNumber(detail.leadsCount) : '—',
              ),
            ),
            AdminNotice(
              message: adminText(
                'Period-specific views and contact taps are in V2. This all-time count is not date-filtered.',
                'مشاهدات الفترة ونقرات التواصل في V2. العدد أعلاه يشمل كامل المدة ولا يتأثر بمرشح التاريخ.',
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AdminClinicDetailSheet(clinic: detail),
                  ),
                  child: Text(
                    adminText('Inspect clinic record', 'فحص سجل العيادة'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => AdminLeadsScreen(
                        initialClinic: detail,
                        dateFrom: _from ?? _service.analytics.dateFrom,
                        dateTo: _to ?? _service.analytics.dateTo,
                      ),
                    ),
                  ),
                  child: Text(
                    adminText(
                      'View requests in this period',
                      'عرض طلبات هذه الفترة',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_service, LocaleService()]),
    builder: (context, _) {
      if (!_service.canManage) return _legacyBuild(context);
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SegmentedButton<bool>(
                style: ButtonStyle(
                  minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  textStyle: WidgetStatePropertyAll(
                    Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(adminText('V2 reports', 'تقارير V2')),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(adminText('Legacy records', 'السجلات القديمة')),
                  ),
                ],
                selected: {_legacy},
                onSelectionChanged: (selection) {
                  setState(() => _legacy = selection.single);
                  if (_legacy) _load();
                },
              ),
            ),
            Expanded(
              child: LazyTabStack(
                index: _legacy ? 1 : 0,
                builders: [
                  (_) => const AnalyticsV2Panel(),
                  (_) => _legacyBuild(context),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _legacyBuild(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_service, LocaleService()]),
    builder: (context, _) {
      final a = _service.analytics, referrals = _service.referralAnalytics;
      if (!_service.canManage) {
        return Scaffold(
          body: Center(
            child: AdminNotice(
              message: adminText(
                'Super Admin access is required.',
                'يتطلب الوصول حساب مشرف عام.',
              ),
            ),
          ),
        );
      }
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        body: RefreshIndicator(
          onRefresh: () => _load(refresh: true),
          child: AnalyticsPage(
            children: [
              AnalyticsPeriod(
                title: adminText(
                  'Platform activity records',
                  'سجلات نشاط المنصة',
                ),
                period: '${a.dateFrom ?? '—'} — ${a.dateTo ?? '—'}',
                onChoose: _service.analyticsLoading ? null : _chooseDates,
                busy: _service.analyticsLoading,
              ),
              if (_from != null || _to != null)
                TextButton(
                  onPressed: _service.analyticsLoading
                      ? null
                      : () {
                          setState(() {
                            _from = null;
                            _to = null;
                          });
                          _load(refresh: true);
                        },
                  child: Text(adminText('Default period', 'الفترة الافتراضية')),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  adminText(
                    'Legacy records do not attest collection coverage.',
                    'السجلات القديمة لا تثبت اكتمال تغطية الجمع.',
                  ),
                  style: TextStyle(
                    color: AppColors.mutedText(context),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              AnalyticsHelp(),
              if (_service.analyticsLoading) const LinearProgressIndicator(),
              if (_service.analyticsError != null)
                AdminNotice(
                  message: _service.analyticsError!,
                  error: true,
                  onRetry: () => _service.loadAnalytics(
                    dateFrom: _from,
                    dateTo: _to,
                    refresh: true,
                  ),
                ),
              if (_service.analyticsLoaded &&
                  !_service.analyticsLoading &&
                  _service.analyticsError == null) ...[
                const SizedBox(height: 12),
                AnalyticsKpiGrid(
                  children: [
                    _metric(
                      a,
                      'total_events',
                      LocaleService().tr('admin_total_events'),
                      Icons.insights_outlined,
                    ),
                    _metric(
                      a,
                      'app_opens',
                      LocaleService().tr('admin_total_app_opens'),
                      Icons.smartphone_outlined,
                    ),
                    _metric(
                      a,
                      'clinic_views',
                      LocaleService().tr('admin_clinic_views'),
                      Icons.visibility_outlined,
                    ),
                    _metric(
                      a,
                      'whatsapp_taps',
                      LocaleService().tr('admin_table_whatsapp'),
                      Icons.chat_bubble_outline,
                    ),
                    _metric(
                      a,
                      'call_taps',
                      LocaleService().tr('admin_table_calls'),
                      Icons.phone_outlined,
                    ),
                    _metric(
                      a,
                      'maps_taps',
                      LocaleService().tr('admin_maps_taps'),
                      Icons.map_outlined,
                    ),
                    _metric(
                      a,
                      'lead_submissions',
                      LocaleService().tr('admin_lead_submissions'),
                      Icons.mark_email_read_outlined,
                    ),
                  ],
                ),
              ],
              _clinicRecords(),
              if (_service.analyticsLoaded &&
                  !_service.analyticsLoading &&
                  _service.analyticsError == null) ...[
                const SizedBox(height: 12),
                AnalyticsDisclosure(
                  title: adminText(
                    'Recorded daily event totals',
                    'إجمالي الأحداث اليومية المسجلة',
                  ),
                  subtitle: adminText(
                    'Server-returned dates only',
                    'التواريخ التي أعادها الخادم فقط',
                  ),
                  children: [
                    if (a.dailyTrends.isEmpty)
                      Text(
                        adminText(
                          'Daily series unavailable or empty.',
                          'السلسلة اليومية غير متاحة أو فارغة.',
                        ),
                      ),
                    BoundedCatalogPreview<AdminDailyEventCount>(
                      items: () => a.dailyTrends,
                      listenable: _service,
                      itemBuilder: (context, day) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(day.date, textDirection: TextDirection.ltr),
                        trailing: Text(
                          day.count == null ? '—' : adminNumber(day.count!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnalyticsDisclosure(
                  title: adminText(
                    'Top clinics by tracked events',
                    'أبرز العيادات حسب الأحداث المسجلة',
                  ),
                  subtitle: adminText(
                    'Up to 10 clinics for this period',
                    'حتى 10 عيادات لهذه الفترة',
                  ),
                  children: [
                    if (_service.analyticsTable.isEmpty)
                      Text(
                        adminText(
                          'No clinic events in this period.',
                          'لا توجد أحداث للعيادات خلال هذه الفترة.',
                        ),
                        style: TextStyle(color: AppColors.mutedText(context)),
                      ),
                    BoundedCatalogPreview<AdminClinicEngagementEntry>(
                      items: () => _service.analyticsTable,
                      listenable: _service,
                      itemBuilder: (context, item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LuxuryCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocaleService().isArabic
                                    ? item.clinicNameAr
                                    : item.clinicNameEn,
                                style: TextStyle(
                                  color: AppColors.text(context),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5,
                                ),
                              ),
                              if (item.hasTier)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: TierBadge(
                                    tier: item.tier,
                                    showBasic: true,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                '${item.hasEventCount ? adminNumber(item.eventsCount) : '—'} ${LocaleService().tr('admin_events_count')}',
                                style: TextStyle(
                                  color: AppColors.goldText(context),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              AdminSectionTitle(
                LocaleService().tr('referral_title'),
                subtitle: adminText(
                  'Lifetime invite links and awarded points; independent of the date filter.',
                  'روابط الدعوة والنقاط طوال المدة، مستقلة عن مرشح التاريخ.',
                ),
              ),
              if (_service.referralsLoading) const LinearProgressIndicator(),
              if (_service.referralsError != null)
                AdminNotice(
                  message: _service.referralsError!,
                  error: true,
                  onRetry: () => _service.loadReferralAnalytics(refresh: true),
                ),
              if (referrals != null)
                AnalyticsKpiGrid(
                  children: [
                    AnalyticsMetricTile(
                      label: adminText('Successful Invites', 'الدعوات الناجحة'),
                      value: adminNumber(referrals.successfulInvites),
                    ),
                    AnalyticsMetricTile(
                      label: adminText('Points Awarded', 'النقاط الممنوحة'),
                      value: adminNumber(referrals.pointsAwarded),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    },
  );
}
