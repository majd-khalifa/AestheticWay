import 'admin_clinic_reviews_screen.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/widgets/tier_badge.dart';
import '../../../clinics/models/clinic_model.dart';
import '../../models/admin_clinic_model.dart';
import '../../services/admin_portal_service.dart';
import '../widgets/admin_components.dart';
import 'admin_clinic_detail_sheet.dart';
import 'admin_create_clinic_dialog.dart';

class AdminClinicsScreen extends StatefulWidget {
  const AdminClinicsScreen({super.key});
  @override
  State<AdminClinicsScreen> createState() => _AdminClinicsScreenState();
}

class _AdminClinicsScreenState extends State<AdminClinicsScreen> {
  String _search = '';
  SubscriptionTier? _tier;
  final _searchController = TextEditingController();
  final _service = AdminPortalService();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _service.loadCollection('clinics');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _query() => _service.searchCollection('clinics', {
    'search': _search,
    'tier': _tier?.apiValue,
  });
  void _selectTier(SubscriptionTier? tier) {
    setState(() => _tier = tier);
    _query();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_service, LocaleService()]),
    builder: (context, _) {
      var clinics = _service.clinics;
      if (_service.isMockMode) {
        clinics = clinics
            .where(
              (c) =>
                  (_tier == null || c.subscriptionTier == _tier) &&
                  '${c.nameEn} ${c.nameAr} ${c.slug}'.toLowerCase().contains(
                    _search.toLowerCase(),
                  ),
            )
            .toList();
      }
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        floatingActionButton: _service.canManage
            ? FloatingActionButton.extended(
                onPressed: () => AdminCreateClinicDialog.show(context),
                backgroundColor: AppColors.darkGold,
                foregroundColor: AppColors.backgroundDeep,
                icon: const Icon(Icons.add_business_rounded),
                label: Text(adminText('Add Clinic', 'إضافة عيادة')),
              )
            : null,
        body: AdminDirectory<AdminClinicModel>(
          items: clinics,
          page: _service.collection('clinics'),
          bottomPadding: 104,
          onRefresh: () => _service.loadCollection('clinics', refresh: true),
          onLoadMore: () => _service.loadMore('clinics'),
          headers: [
            AdminSectionTitle(
              adminText('Partner clinics', 'العيادات الشريكة'),
              subtitle: adminText(
                'Manage clinic identity, subscriptions and access.',
                'إدارة هوية العيادات واشتراكاتها وحالة تفعيلها.',
              ),
            ),
            OutlinedButton.icon(
              key: const ValueKey('admin-clinics-reviews'),
              onPressed: !_service.canManage
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const AdminClinicReviewsScreen(),
                      ),
                    ),
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(adminText('Clinic Reviews', 'مراجعة العيادات')),
            ),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: adminText('Search clinics', 'البحث عن عيادة'),
                hintText: LocaleService().tr('admin_clinic_search_hint'),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (v) {
                _search = v;
                _query();
              },
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: Text(adminText('All Tiers', 'جميع الباقات')),
                  selected: _tier == null,
                  onSelected: (_) => _selectTier(null),
                ),
                for (final tier in SubscriptionTier.values)
                  ChoiceChip(
                    label: Text(
                      tier == SubscriptionTier.vipPlatinum
                          ? adminText('VIP Platinum', 'بلاتيني VIP')
                          : tier == SubscriptionTier.featured
                          ? adminText('Featured', 'مميز')
                          : adminText('Basic', 'أساسي'),
                    ),
                    selected: _tier == tier,
                    onSelected: (_) => _selectTier(tier),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          itemBuilder: (context, c) => AdminClinicCard(
            key: ValueKey('admin-clinic-${c.id}'),
            clinic: c,
            onOpen: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => AdminClinicDetailSheet(clinic: c),
            ),
          ),
        ),
      );
    },
  );
}

class AdminClinicCard extends StatelessWidget {
  const AdminClinicCard({
    super.key,
    required this.clinic,
    required this.onOpen,
  });
  final AdminClinicModel clinic;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final service = AdminPortalService(), c = clinic;
    final busy = service.isPending('clinic', c.id);
    return LuxuryCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminEntityImage(
                url: c.logo,
                logo: c.coverImage,
                isLogo: true,
                mediaKey: clinicLogoCacheKey(c.id),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.localizedName(arabic: LocaleService().isArabic),
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      c.locationLabel(arabic: LocaleService().isArabic),
                      style: TextStyle(
                        color: AppColors.mutedText(context),
                        height: 1.5,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TierBadge(tier: c.subscriptionTier, showBasic: true),
              AdminStatusBadge(status: c.status),
              if (c.isFeatured)
                Text(
                  adminText(
                    'Home placement enabled',
                    'الظهور في الرئيسية مفعّل',
                  ),
                  style: TextStyle(
                    color: AppColors.goldText(context),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const Divider(height: 26),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _Count(
                c.leadsCount,
                LocaleService().tr('admin_table_leads'),
                Icons.mark_email_read_outlined,
              ),
              _Count(
                c.branchesCount,
                LocaleService().tr('admin_clinic_branches'),
                Icons.store_outlined,
              ),
              _Count(
                c.practitionersCount,
                LocaleService().tr('admin_clinic_practitioners'),
                Icons.badge_outlined,
              ),
              _Count(
                c.offersCount,
                LocaleService().tr('admin_clinic_offers'),
                Icons.local_offer_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(adminText('Clinic details', 'تفاصيل العيادة')),
                ),
              ),
              if (busy)
                const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch.adaptive(
                  value: c.isActive,
                  onChanged: !service.canManage
                      ? null
                      : (_) async {
                          if (c.isActive &&
                              !await confirmClinicSuspension(context)) {
                            return;
                          }
                          if (!context.mounted) return;
                          final saved = await service.toggleClinicStatus(c.id);
                          if (context.mounted) {
                            showAppSnackBar(
                              context,
                              saved
                                  ? adminText(
                                      'Clinic status updated.',
                                      'تم تحديث حالة العيادة.',
                                    )
                                  : service.writeError('clinic', c.id) ??
                                        adminText(
                                          'Could not update clinic.',
                                          'تعذر تحديث العيادة.',
                                        ),
                              type: saved
                                  ? AppSnackBarType.success
                                  : AppSnackBarType.error,
                            );
                          }
                        },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.value, this.label, this.icon);
  final int value;
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: Icon(icon, size: 16, color: AppColors.goldText(context)),
          ),
        ),
        TextSpan(text: '${adminNumber(value)} $label'),
      ],
    ),
    style: TextStyle(color: AppColors.text(context), fontSize: 12, height: 1.5),
  );
}
