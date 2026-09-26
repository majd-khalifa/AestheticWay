import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/tier_badge.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_clinic_detail_sheet.dart';

/// Super Admin Tab 2: Partner Clinics Directory, Tiers & Active/Suspended Controls
class AdminClinicsScreen extends StatefulWidget {
  const AdminClinicsScreen({super.key});

  @override
  State<AdminClinicsScreen> createState() => _AdminClinicsScreenState();
}

class _AdminClinicsScreenState extends State<AdminClinicsScreen> {
  String _searchQuery = '';
  SubscriptionTier? _selectedTierFilter;

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final adminService = AdminPortalService();
    final isDark = AppColors.isDark(context);

    return ListenableBuilder(
      listenable: Listenable.merge([loc, adminService]),
      builder: (context, _) {
        var clinics = adminService.clinics;

        // Filter by Tier
        if (_selectedTierFilter != null) {
          clinics = clinics.where((c) => c.subscriptionTier == _selectedTierFilter).toList();
        }

        // Search Filter
        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          clinics = clinics.where((c) =>
              c.nameAr.toLowerCase().contains(q) ||
              c.nameEn.toLowerCase().contains(q) ||
              c.city.toLowerCase().contains(q)).toList();
        }

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          body: Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: loc.isArabic ? 'بحث باسم العيادة أو المدينة...' : 'Search clinic by name or city...',
                    hintStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.mutedText(context)),
                    filled: true,
                    fillColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context), width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accentChampagne, width: 1.4),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),

              // Tier Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _FilterChipItem(
                      label: loc.isArabic ? 'جميع الباقات' : 'All Tiers',
                      isSelected: _selectedTierFilter == null,
                      onTap: () => setState(() => _selectedTierFilter = null),
                    ),
                    const SizedBox(width: 6),
                    _FilterChipItem(
                      label: 'VIP Platinum',
                      isSelected: _selectedTierFilter == SubscriptionTier.vipPlatinum,
                      onTap: () => setState(() => _selectedTierFilter = SubscriptionTier.vipPlatinum),
                    ),
                    const SizedBox(width: 6),
                    _FilterChipItem(
                      label: 'Featured',
                      isSelected: _selectedTierFilter == SubscriptionTier.featured,
                      onTap: () => setState(() => _selectedTierFilter = SubscriptionTier.featured),
                    ),
                    const SizedBox(width: 6),
                    _FilterChipItem(
                      label: 'Basic',
                      isSelected: _selectedTierFilter == SubscriptionTier.basic,
                      onTap: () => setState(() => _selectedTierFilter = SubscriptionTier.basic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Clinics List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => adminService.loadClinics(),
                  color: AppColors.accentChampagne,
                  backgroundColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: clinics.length,
                    itemBuilder: (context, index) {
                      final clinic = clinics[index];
                      final metric = adminService.getMetricForClinic(clinic.id);
                      final isActive = metric?.isActive ?? clinic.isActive;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LuxuryCard(
                          padding: const EdgeInsets.all(14),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => AdminClinicDetailSheet(clinic: clinic),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Avatar, Name, Tier, Switch
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      clinic.coverImageUrl,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        width: 48,
                                        height: 48,
                                        color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                                        child: const Icon(Icons.apartment_rounded, color: AppColors.accentChampagne),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          loc.isArabic ? clinic.nameAr : clinic.nameEn,
                                          style: AppTypography.cardTitle.copyWith(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              '${clinic.city} • ${loc.isArabic ? clinic.areaAr : clinic.areaEn}',
                                              style: AppTypography.caption.copyWith(
                                                color: AppColors.mutedText(context),
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            TierBadge(tier: clinic.subscriptionTier),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: isActive,
                                    activeThumbColor: AppColors.accentChampagne,
                                    onChanged: (val) async {
                                      final success = await adminService.toggleClinicStatus(clinic.id);
                                      if (!success && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(adminService.errorMessage ?? 'Error updating clinic')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const Divider(height: 16),

                              // Clinic Catalog & Leads Counts (strictly from backend AdminClinicModel)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _PillMetric(
                                    icon: Icons.mark_email_read_outlined,
                                    label: '${clinic.leadsCount} ${loc.tr('admin_table_leads')}',
                                    isGold: true,
                                  ),
                                  _PillMetric(
                                    icon: Icons.store_outlined,
                                    label: '${clinic.branchesCount} ${loc.tr('admin_clinic_branches')}',
                                  ),
                                  _PillMetric(
                                    icon: Icons.badge_outlined,
                                    label: '${clinic.practitionersCount} ${loc.tr('admin_clinic_practitioners')}',
                                  ),
                                  _PillMetric(
                                    icon: Icons.local_offer_outlined,
                                    label: '${clinic.offersCount} ${loc.tr('admin_clinic_offers')}',
                                    iconColor: const Color(0xFF10B981),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentChampagne : (isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accentChampagne : AppColors.border(context),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? AppColors.backgroundDeep : AppColors.mutedText(context),
          ),
        ),
      ),
    );
  }
}

class _PillMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isGold;
  final Color? iconColor;

  const _PillMetric({
    required this.icon,
    required this.label,
    this.isGold = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border(context), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor ?? (isGold ? AppColors.accentChampagne : AppColors.mutedText(context))),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isGold ? AppColors.accentChampagne : (isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
