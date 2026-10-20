import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bounded_catalog_preview.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/widgets/tier_badge.dart';
import '../../models/admin_analytics_model.dart';
import '../../services/admin_portal_service.dart';
import '../widgets/admin_components.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});
  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final _service = AdminPortalService();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load({bool refresh = false}) async {
    await Future.wait([
      _service.loadAnalytics(refresh: refresh),
      _service.loadReferralAnalytics(refresh: refresh),
    ]);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_service, LocaleService()]),
    builder: (context, _) {
      final a = _service.analytics, referrals = _service.referralAnalytics;
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        body: RefreshIndicator(
          onRefresh: () => _load(refresh: true),
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
                LocaleService().tr('admin_analytics_title'),
                subtitle: LocaleService().tr('admin_analytics_sub'),
              ),
              if (a.dateFrom != null && a.dateTo != null)
                Text(
                  '${a.dateFrom} — ${a.dateTo}',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: AppColors.mutedText(context),
                    fontSize: 12,
                  ),
                ),
              if (_service.analyticsLoading) const LinearProgressIndicator(),
              if (_service.analyticsError != null)
                AdminNotice(
                  message: _service.analyticsError!,
                  error: true,
                  onRetry: () => _service.loadAnalytics(refresh: true),
                ),
              if (_service.analyticsLoaded) ...[
                const SizedBox(height: 12),
                AdminMetricGrid(
                  children: [
                    AdminMetricCard(
                      label: LocaleService().tr('admin_total_events'),
                      value: adminNumber(a.totalEvents),
                      icon: Icons.insights_outlined,
                    ),
                    AdminMetricCard(
                      label: LocaleService().tr('admin_total_app_opens'),
                      value: adminNumber(a.appOpens),
                      icon: Icons.smartphone_outlined,
                    ),
                    AdminMetricCard(
                      label: LocaleService().tr('admin_clinic_views'),
                      value: adminNumber(a.clinicViews),
                      icon: Icons.visibility_outlined,
                    ),
                    AdminMetricCard(
                      label: LocaleService().tr('admin_table_whatsapp'),
                      value: adminNumber(a.whatsappTaps),
                      icon: Icons.chat_bubble_outline,
                    ),
                    AdminMetricCard(
                      label: LocaleService().tr('admin_table_calls'),
                      value: adminNumber(a.callTaps),
                      icon: Icons.phone_outlined,
                    ),
                    AdminMetricCard(
                      label: LocaleService().tr('admin_maps_taps'),
                      value: adminNumber(a.mapsTaps),
                      icon: Icons.map_outlined,
                    ),
                    AdminMetricCard(
                      label: LocaleService().tr('admin_lead_submissions'),
                      value: adminNumber(a.leadSubmissions),
                      icon: Icons.mark_email_read_outlined,
                    ),
                  ],
                ),
                AdminSectionTitle(
                  adminText(
                    'Top clinics by tracked events',
                    'أبرز العيادات حسب الأحداث المسجلة',
                  ),
                  subtitle: adminText(
                    'Up to 10 clinics returned for this reporting period.',
                    'حتى 10 عيادات حسب بيانات الفترة المحددة.',
                  ),
                ),
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
                            '${adminNumber(item.eventsCount)} ${LocaleService().tr('admin_events_count')}',
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
              AdminSectionTitle(
                LocaleService().tr('referral_title'),
                subtitle: adminText(
                  'Invite links and awarded points across the platform.',
                  'روابط الدعوة والنقاط الممنوحة على مستوى المنصة.',
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
                AdminMetricGrid(
                  children: [
                    AdminMetricCard(
                      label: adminText('Successful Invites', 'الدعوات الناجحة'),
                      value: adminNumber(referrals.successfulInvites),
                      icon: Icons.person_add_alt_outlined,
                    ),
                    AdminMetricCard(
                      label: adminText('Points Awarded', 'النقاط الممنوحة'),
                      value: adminNumber(referrals.pointsAwarded),
                      icon: Icons.auto_awesome_outlined,
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
