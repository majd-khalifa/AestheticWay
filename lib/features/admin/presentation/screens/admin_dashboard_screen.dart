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

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _service = AdminPortalService();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _service.loadOverview();
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_service, LocaleService()]),
    builder: (context, _) {
      final d = _service.dashboard;
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        body: RefreshIndicator(
          onRefresh: () => _service.loadOverview(refresh: true),
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
                  'AESTHETIC WAY · Platform supervision',
                  'AESTHETIC WAY · متابعة أداء المنصة',
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
              if (_service.overviewLoaded)
                AdminMetricGrid(
                  children: [
                    AdminMetricCard(
                      label: LocaleService().tr('admin_total_events'),
                      value: adminNumber(d.totalAnalyticsEvents),
                      icon: Icons.insights_outlined,
                    ),
                    AdminMetricCard(
                      label: LocaleService().tr('admin_active_clinics'),
                      value: adminNumber(d.activeClinics),
                      caption: adminText(
                        '${adminNumber(d.totalClinics)} clinics registered',
                        '${adminNumber(d.totalClinics)} عيادة مسجلة',
                      ),
                      icon: Icons.apartment_outlined,
                    ),
                    AdminMetricCard(
                      label: LocaleService().tr('admin_total_leads'),
                      value: adminNumber(d.totalLeads),
                      caption: adminText(
                        '${d.closureRate.toStringAsFixed(1)}% closed',
                        '${d.closureRate.toStringAsFixed(1)}٪ طلبات مغلقة',
                      ),
                      icon: Icons.mark_email_read_outlined,
                    ),
                    AdminMetricCard(
                      label: LocaleService().tr('admin_contacted_leads'),
                      value: adminNumber(d.contactedLeads),
                      icon: Icons.support_agent_outlined,
                    ),
                    AdminMetricCard(
                      label: LocaleService().tr('admin_registered_patients'),
                      value: adminNumber(d.totalPatients),
                      icon: Icons.people_outline,
                    ),
                    AdminMetricCard(
                      label: adminText('Total Offers', 'إجمالي العروض'),
                      value: adminNumber(d.totalOffers),
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
