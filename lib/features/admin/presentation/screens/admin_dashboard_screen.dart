import '../../services/admin_review_service.dart';
import '../../../treatments/presentation/category_requests_screen.dart';
import 'admin_clinic_reviews_screen.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../services/admin_portal_service.dart';
import '../widgets/admin_components.dart';
import 'admin_lead_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.onNavigateToClinics,
    required this.onNavigateToLeads,
    required this.onNavigateToAnalytics,
  });
  final VoidCallback onNavigateToClinics,
      onNavigateToLeads,
      onNavigateToAnalytics;
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with WidgetsBindingObserver {
  final _service = AdminPortalService();
  final _reviews = AdminReviewService();
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reviews.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reviews.refresh();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _service.loadOverview();
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_service, _reviews, LocaleService()]),
    builder: (context, _) {
      final d = _service.dashboard;
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        body: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              _service.loadOverview(refresh: true),
              _reviews.refresh(),
            ]);
          },
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
                adminText(
                  'Platform Operations & Metrics',
                  'لوحة القيادة والمتابعة المركزية',
                ),
                subtitle: adminText(
                  'All-time operational totals · account counts are not active usage',
                  'إجماليات التشغيل طوال المدة · أعداد الحسابات ليست استخداماً نشطاً',
                ),
              ),
              if (_service.isLoading && !_service.overviewLoaded)
                const LinearProgressIndicator(),
              if (_service.overviewError != null)
                AdminNotice(
                  message: _service.overviewError!,
                  error: true,
                  onRetry: () => _service.loadOverview(refresh: true),
                ),
              AdminSectionTitle(adminText('Review inboxes', 'صناديق المراجعة')),
              Card(
                child: ListTile(
                  key: const ValueKey('admin-category-requests-quick-action'),
                  leading: const Icon(Icons.playlist_add_check),
                  title: Text(
                    adminText('Category Requests', 'طلبات التصنيفات'),
                  ),
                  subtitle: Text(
                    _reviews.loading
                        ? adminText(
                            'Loading pending requests…',
                            'جارٍ تحميل الطلبات المعلقة…',
                          )
                        : _reviews.error ??
                              (_reviews.pendingCategories == null
                                  ? adminText(
                                      'Pending count unavailable',
                                      'عدد الطلبات المعلقة غير متاح',
                                    )
                                  : adminText(
                                      'Pending: ${_reviews.pendingCategories}',
                                      'قيد الانتظار: ${_reviews.pendingCategories}',
                                    )),
                  ),
                  trailing: _reviews.loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: !_service.canManage
                      ? null
                      : () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const CategoryRequestsScreen(admin: true),
                            ),
                          );
                          if (mounted) _reviews.refresh();
                        },
                ),
              ),
              if (_reviews.error != null)
                TextButton(
                  onPressed: _reviews.loading ? null : _reviews.refresh,
                  child: Text(adminText('Retry count', 'إعادة تحميل العدد')),
                ),
              Card(
                child: ListTile(
                  key: const ValueKey('admin-clinic-reviews-quick-action'),
                  leading: const Icon(Icons.fact_check_outlined),
                  title: Text(adminText('Clinic Reviews', 'مراجعة العيادات')),
                  subtitle: Text(
                    _reviews.loading
                        ? adminText(
                            'Loading submitted profiles…',
                            'جارٍ تحميل الملفات المرسلة…',
                          )
                        : _reviews.clinicCountError ??
                              (_reviews.submittedClinics == null
                                  ? adminText(
                                      'Submitted count unavailable',
                                      'عدد الملفات المرسلة غير متاح',
                                    )
                                  : adminText(
                                      'Submitted profiles: ${_reviews.submittedClinics}',
                                      'الملفات المرسلة: ${_reviews.submittedClinics}',
                                    )),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: !_service.canManage
                      ? null
                      : () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const AdminClinicReviewsScreen(),
                            ),
                          );
                          if (mounted) await _reviews.refresh();
                        },
                ),
              ),
              if (_service.overviewLoaded)
                AdminMetricGrid(
                  children: [
                    AdminMetricCard(
                      label: LocaleService().tr('admin_total_events'),
                      value: d.hasMetric('total_analytics_events')
                          ? adminNumber(d.totalAnalyticsEvents)
                          : '—',
                      icon: Icons.insights_outlined,
                    ),
                    AdminMetricCard(
                      label: LocaleService().tr('admin_active_clinics'),
                      value: d.hasMetric('active_clinics')
                          ? adminNumber(d.activeClinics)
                          : '—',
                      caption: adminText(
                        '${d.hasMetric('total_clinics') ? adminNumber(d.totalClinics) : '—'} clinic accounts registered',
                        '${d.hasMetric('total_clinics') ? adminNumber(d.totalClinics) : '—'} حساب عيادة مسجل',
                      ),
                      icon: Icons.apartment_outlined,
                    ),
                    AdminMetricCard(
                      label: LocaleService().tr('admin_total_leads'),
                      value: d.hasMetric('total_leads')
                          ? adminNumber(d.totalLeads)
                          : '—',
                      caption:
                          !d.hasMetric('total_leads') ||
                              !d.leadsByStatus.containsKey('closed')
                          ? null
                          : adminText(
                              '${d.closureRate.toStringAsFixed(1)}% closed',
                              '${d.closureRate.toStringAsFixed(1)}٪ طلبات مغلقة',
                            ),
                      icon: Icons.mark_email_read_outlined,
                    ),
                    AdminMetricCard(
                      label: LocaleService().tr('admin_contacted_leads'),
                      value: d.leadsByStatus.containsKey('contacted')
                          ? adminNumber(d.contactedLeads)
                          : '—',
                      icon: Icons.support_agent_outlined,
                    ),
                    AdminMetricCard(
                      label: adminText(
                        'Active patient accounts',
                        'حسابات المرضى المفعلة',
                      ),
                      value: d.hasMetric('total_patients')
                          ? adminNumber(d.totalPatients)
                          : '—',
                      icon: Icons.people_outline,
                    ),
                    AdminMetricCard(
                      label: adminText('Total Offers', 'إجمالي العروض'),
                      value: d.hasMetric('total_offers')
                          ? adminNumber(d.totalOffers)
                          : '—',
                      icon: Icons.local_offer_outlined,
                    ),
                  ],
                ),
              AdminSectionTitle(LocaleService().tr('clinic_quick_actions')),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onNavigateToClinics,
                    icon: const Icon(Icons.apartment_outlined),
                    label: Text(LocaleService().tr('admin_nav_clinics')),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.onNavigateToLeads,
                    icon: const Icon(Icons.mark_email_read_outlined),
                    label: Text(LocaleService().tr('admin_nav_leads')),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.onNavigateToAnalytics,
                    icon: const Icon(Icons.analytics_outlined),
                    label: Text(LocaleService().tr('admin_nav_analytics')),
                  ),
                ],
              ),
              AdminSectionTitle(
                LocaleService().tr('admin_recent_activity'),
                action: TextButton(
                  onPressed: widget.onNavigateToLeads,
                  child: Text(adminText('View All', 'عرض الكل')),
                ),
              ),
              if (_service.recentLeadsLoading) const LinearProgressIndicator(),
              if (_service.recentLeadsError != null)
                AdminNotice(
                  message: _service.recentLeadsError!,
                  error: true,
                  onRetry: () => _service.loadOverview(refresh: true),
                ),
              if (_service.recentLeads.isEmpty &&
                  _service.recentLeadsError == null &&
                  !_service.recentLeadsLoading)
                Text(
                  adminText('No requests to display.', 'لا توجد طلبات لعرضها.'),
                  style: TextStyle(color: AppColors.mutedText(context)),
                ),
              for (final lead in _service.recentLeads)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AdminLeadCard(
                    lead: lead,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminLeadDetailScreen(lead: lead),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              AdminNotice(
                key: const ValueKey('admin-supervision-notice'),
                message: LocaleService().tr('admin_lead_monitoring_note'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
