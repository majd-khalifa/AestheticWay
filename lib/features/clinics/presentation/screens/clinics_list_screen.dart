import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/rating_chip.dart';
import 'package:aesthetic_way/core/widgets/distance_chip.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/widgets/luxury_shimmer.dart';
import 'package:aesthetic_way/core/widgets/luxury_error_view.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/clinics/data/clinics_repository.dart';
import 'package:aesthetic_way/features/clinics/presentation/widgets/contact_options_sheet.dart';
import 'package:aesthetic_way/features/clinics/presentation/widgets/filter_bottom_sheet.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinic_profile_screen.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';

/// Screen 6: Clinics Directory Screen with Live API Data, Filtering, Sorting & Search
class ClinicsListScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialCity;

  const ClinicsListScreen({
    super.key,
    this.initialCategory,
    this.initialCity,
  });

  @override
  State<ClinicsListScreen> createState() => _ClinicsListScreenState();
}

class _ClinicsListScreenState extends State<ClinicsListScreen> {
  final ClinicsRepository _clinicsRepository = ClinicsRepository();

  late ClinicFilterOptions _filterOptions;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<ClinicModel>? _clinics;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _filterOptions = ClinicFilterOptions(
      selectedCity: widget.initialCity ?? 'الكل',
      selectedSpecialtyId: widget.initialCategory == 'all' || widget.initialCategory == 'clinics' ? null : widget.initialCategory,
    );
    _loadClinics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClinics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _clinicsRepository.getClinics(
        city: _filterOptions.selectedCity,
        search: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _clinics = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _openFilters() {
    FilterBottomSheet.show(
      context: context,
      currentFilters: _filterOptions,
      onApply: (updated) {
        setState(() {
          _filterOptions = updated;
        });
        _loadClinics();
      },
    );
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
              loc.isArabic ? 'دليل عيادات التجميل والجلدية' : 'Aesthetic & Derma Clinics',
              style: AppTypography.screenTitle.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
              ),
            ),
            automaticallyImplyLeading: Navigator.canPop(context),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppColors.accentChampagne),
                tooltip: loc.tr('filter_button'),
                onPressed: _openFilters,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadClinics,
            color: AppColors.accentChampagne,
            backgroundColor: AppColors.surface(context),
            child: _buildBody(context, loc, isDark),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, LocaleService loc, bool isDark) {
    final hasActiveFilters = _filterOptions.selectedCity != 'الكل' && _filterOptions.selectedCity != 'All' ||
        _filterOptions.selectedSpecialtyId != null ||
        _filterOptions.selectedPractitionerType != null;

    // Filter & Sort loaded clinics
    List<ClinicModel> clinicList = [];
    if (_clinics != null) {
      clinicList = _clinics!.where((c) {
        // City filter
        final cityVal = _filterOptions.selectedCity.toLowerCase();
        final matchesCity = cityVal == 'الكل' || cityVal == 'all' ||
            (cityVal.contains('دبي') || cityVal.contains('dubai') ? c.city.toLowerCase() == 'dubai' : true) &&
            (cityVal.contains('أبوظبي') || cityVal.contains('abu dhabi') ? c.city.toLowerCase() == 'abu dhabi' : true);

        // Search query
        final q = _searchQuery.toLowerCase();
        final matchesQuery = q.isEmpty ||
            c.nameAr.toLowerCase().contains(q) ||
            c.nameEn.toLowerCase().contains(q) ||
            c.areaAr.toLowerCase().contains(q) ||
            c.addressAr.toLowerCase().contains(q);

        return matchesCity && matchesQuery;
      }).toList();

      // Apply Sorting
      switch (_filterOptions.sortOption) {
        case ClinicSortOption.featuredFirst:
          clinicList.sort((a, b) {
            final rankA = a.subscriptionTier == SubscriptionTier.vipPlatinum ? 0 : (a.subscriptionTier == SubscriptionTier.featured ? 1 : 2);
            final rankB = b.subscriptionTier == SubscriptionTier.vipPlatinum ? 0 : (b.subscriptionTier == SubscriptionTier.featured ? 1 : 2);
            return rankA.compareTo(rankB);
          });
          break;
        case ClinicSortOption.highestRating:
          clinicList.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case ClinicSortOption.nearestDistance:
          clinicList.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
          break;
      }
    }

    return Column(
      children: [
        // Search & Quick Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border(context),
                      width: 0.8,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: AppColors.text(context), fontSize: 13.5),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim());
                    },
                    onSubmitted: (_) => _loadClinics(),
                    decoration: InputDecoration(
                      hintText: loc.tr('search_hint'),
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.mutedText(context),
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(Icons.search, color: AppColors.subtext(context), size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 16, color: AppColors.mutedText(context)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _loadClinics();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filter Trigger Button
              InkWell(
                onTap: _openFilters,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: hasActiveFilters
                        ? AppColors.accentChampagne.withValues(alpha: isDark ? 0.15 : 0.12)
                        : AppColors.surface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: hasActiveFilters ? AppColors.accentChampagne : AppColors.border(context),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: hasActiveFilters ? AppColors.accentChampagne : AppColors.subtext(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        loc.tr('filter_button'),
                        style: AppTypography.caption.copyWith(
                          color: hasActiveFilters
                              ? AppColors.accentChampagne
                              : (isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Active Filter Summary / City Pills Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _QuickCityChip(
                label: loc.isArabic ? 'الكل' : 'All',
                isSelected: _filterOptions.selectedCity == 'الكل' || _filterOptions.selectedCity == 'All',
                onTap: () {
                  setState(() => _filterOptions.selectedCity = 'الكل');
                  _loadClinics();
                },
              ),
              const SizedBox(width: 6),
              _QuickCityChip(
                label: loc.isArabic ? "دبي" : "Dubai",
                isSelected: _filterOptions.selectedCity == 'دبي' || _filterOptions.selectedCity == 'Dubai',
                onTap: () {
                  setState(() => _filterOptions.selectedCity = 'دبي');
                  _loadClinics();
                },
              ),
              const SizedBox(width: 6),
              _QuickCityChip(
                label: loc.isArabic ? "أبوظبي" : "Abu Dhabi",
                isSelected: _filterOptions.selectedCity == 'أبوظبي' || _filterOptions.selectedCity == 'Abu Dhabi',
                onTap: () {
                  setState(() => _filterOptions.selectedCity = 'أبوظبي');
                  _loadClinics();
                },
              ),
              if (_filterOptions.selectedSpecialtyId != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.15 : 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accentChampagne, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.tr('cat_${_filterOptions.selectedSpecialtyId}'),
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() => _filterOptions.selectedSpecialtyId = null);
                          _loadClinics();
                        },
                        child: Icon(Icons.close, size: 13, color: AppColors.mutedText(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Results Count Indicator
        if (!_isLoading && _errorMessage == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.isArabic
                      ? '${clinicList.length} عيادة معتمدة'
                      : '${clinicList.length} Verified Clinics',
                  style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                ),
              ],
            ),
          ),

        // Content Area: Loading / Error / Empty / List
        Expanded(
          child: _isLoading && _clinics == null
              ? ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: 4,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) => const LuxuryShimmer(
                    width: double.infinity,
                    height: 130,
                    borderRadius: 18,
                  ),
                )
              : _errorMessage != null && _clinics == null
                  ? LuxuryErrorView(
                      message: _errorMessage,
                      onRetry: _loadClinics,
                    )
                  : clinicList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded, size: 40, color: AppColors.mutedText(context)),
                              const SizedBox(height: 10),
                              Text(
                                loc.isArabic ? 'لا توجد عيادات مطابقة للبحث' : 'No clinics match your search',
                                style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedText(context)),
                              ),
                              if (hasActiveFilters) ...[
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _filterOptions.selectedCity = 'الكل';
                                      _filterOptions.selectedSpecialtyId = null;
                                      _searchQuery = '';
                                      _searchController.clear();
                                    });
                                    _loadClinics();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppColors.accentChampagne.withValues(alpha: 0.6)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text(
                                    loc.isArabic ? 'إعادة تعيين الفلاتر' : 'Reset Filters',
                                    style: AppTypography.caption.copyWith(color: AppColors.accentChampagne),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: clinicList.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final clinic = clinicList[index];
                            return StaggeredEntrance(
                              index: index,
                              child: LuxuryCard(
                                isVip: clinic.subscriptionTier == SubscriptionTier.vipPlatinum,
                                borderRadius: 18,
                                padding: const EdgeInsets.all(14),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    LuxuryPageRoute(
                                      page: ClinicProfileScreen(clinic: clinic),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        LuxuryImage(
                                          imageUrl: clinic.coverImageUrl,
                                          width: 78,
                                          height: 78,
                                          borderRadius: BorderRadius.circular(14),
                                          fit: BoxFit.cover,
                                          placeholderIcon: Icons.local_hospital_outlined,
                                          iconSize: 32,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      loc.isArabic ? clinic.nameAr : clinic.nameEn,
                                                      style: AppTypography.cardTitle.copyWith(
                                                        fontSize: 14.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                loc.isArabic ? clinic.addressAr : clinic.addressEn,
                                                style: AppTypography.caption.copyWith(
                                                  color: isDark ? AppColors.silverMuted : AppColors.lightTextMuted,
                                                  fontSize: 11.5,
                                                ),
                                                maxLines: 1,
                                              ),
                                              const SizedBox(height: 7),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 5,
                                                children: [
                                                  RatingChip(
                                                    rating: clinic.rating,
                                                    reviewCount: clinic.reviewCount,
                                                    isCompact: true,
                                                    showGoogleSource: true,
                                                  ),
                                                  DistanceChip(
                                                    distanceKm: clinic.distanceKm,
                                                    areaName: loc.isArabic ? clinic.areaAr : clinic.areaEn,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () => ContactOptionsSheet.show(context, clinic),
                                          style: OutlinedButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                            side: BorderSide(
                                              color: AppColors.border(context),
                                              width: 0.8,
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: Text(
                                            loc.tr('contact_btn'),
                                            style: AppTypography.caption.copyWith(
                                              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final auth = await GuestAuthGuard.requireAuth(
                                              context,
                                              reasonTitle: loc.tr('request_consultation'),
                                              reasonSubtitle: loc.isArabic ? 'سجل دخولك برقم الهاتف لإرسال طلبك للعيادة' : 'Login with phone number to submit your lead',
                                            );
                                            if (auth && context.mounted) {
                                              Navigator.push(
                                                context,
                                                LuxuryPageRoute(
                                                  page: AppointmentRequestScreen(clinic: clinic),
                                                ),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: Text(
                                            loc.tr('request_appointment'),
                                            style: AppTypography.caption.copyWith(
                                              color: isDark ? AppColors.backgroundDeep : Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
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
      ],
    );
  }
}

class _QuickCityChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickCityChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentChampagne.withValues(alpha: isDark ? 0.15 : 0.14)
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accentChampagne : AppColors.border(context),
            width: isSelected ? 1.1 : 0.75,
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
