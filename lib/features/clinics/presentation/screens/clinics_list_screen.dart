import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/core/widgets/pagination_footer.dart';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/rating_chip.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/widgets/luxury_error_view.dart';
import 'package:aesthetic_way/core/widgets/luxury_loading_skeleton.dart';
import 'package:aesthetic_way/core/widgets/luxury_empty_state.dart';
import 'package:flutter/services.dart';
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

  const ClinicsListScreen({super.key, this.initialCategory, this.initialCity});

  @override
  State<ClinicsListScreen> createState() => _ClinicsListScreenState();
}

class _ClinicsListScreenState extends State<ClinicsListScreen> {
  final ClinicsRepository _clinicsRepository = ClinicsRepository();

  late ClinicFilterOptions _filterOptions;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  late final PagedCollection<ClinicModel> _paging;
  List<ClinicModel>? get _clinics => _paging.items;
  bool get _isLoading => _paging.isLoading;
  String? get _errorMessage => _paging.items.isEmpty ? _paging.error : null;
  void _pageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _paging = PagedCollection<ClinicModel>(
      loader: (page, q) => _clinicsRepository.getClinics(
        city: q['city'] as String?,
        search: q['search'] as String?,
        categoryId: q['category'] as String?,
        page: page,
        pageSize: 20,
      ),
      keyOf: (item) => item.id,
    )..addListener(_pageChanged);
    _scrollController.addListener(_onScroll);
    _filterOptions = ClinicFilterOptions(
      selectedCity: widget.initialCity ?? 'الكل',
      selectedSpecialtyId:
          widget.initialCategory == 'all' || widget.initialCategory == 'clinics'
          ? null
          : widget.initialCategory,
    );
    _loadClinics();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _paging.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 250) {
      _loadMoreClinics();
    }
  }

  Future<void> _loadClinics() => _paging.refresh(
    query: {
      'search': _searchQuery,
      'city': _filterOptions.selectedCity,
      'category': _categoryUuid,
    },
  );

  Future<void> _loadMoreClinics() => _paging.loadMore();

  String? get _categoryUuid {
    final value = _filterOptions.selectedSpecialtyId;
    return value != null && RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(value)
        ? value
        : null;
  }

  void _openFilters() {
    FilterBottomSheet.show(
      context: context,
      currentFilters: _filterOptions,
      onApply: (updated) {
        setState(() {
          _filterOptions = updated;
        });
        _paging.search({
          'search': _searchQuery,
          'city': _filterOptions.selectedCity,
          'category': _categoryUuid,
        });
      },
    );
  }

  void _onSearchChanged(String value) {
    _searchQuery = value.trim();
    _paging.search({
      'search': _searchQuery,
      'city': _filterOptions.selectedCity,
      'category': _categoryUuid,
    });
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
              loc.isArabic
                  ? 'دليل عيادات التجميل والجلدية'
                  : 'Aesthetic & Derma Clinics',
              style: AppTypography.screenTitle.copyWith(
                color: isDark
                    ? AppColors.silverPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            automaticallyImplyLeading: Navigator.canPop(context),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.accentChampagne,
                ),
                tooltip: loc.tr('filter_button'),
                onPressed: _openFilters,
              ),
            ],
          ),
          body: PagedScrollBoundary(
            onLoadMore: _paging.loadMore,
            child: LuxuryRefreshIndicator(
              onRefresh: _loadClinics,
              child: _buildBody(context, loc, isDark),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, LocaleService loc, bool isDark) {
    final hasActiveFilters =
        _filterOptions.selectedCity != 'الكل' &&
            _filterOptions.selectedCity != 'All' ||
        _filterOptions.selectedSpecialtyId != null ||
        _filterOptions.selectedPractitionerType != null;

    // Keep canonical ordering and server-wide matching across page boundaries.
    final clinicList = List<ClinicModel>.of(_paging.items);

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
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 13.5,
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: (_) => _loadClinics(),
                    decoration: InputDecoration(
                      hintText: loc.tr('search_hint'),
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.text(context),
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.subtext(context),
                        size: 18,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: 16,
                                color: AppColors.mutedText(context),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _paging.search({
                                  'search': _searchQuery,
                                  'city': _filterOptions.selectedCity,
                                  'category': _categoryUuid,
                                });
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
                        ? AppColors.accentChampagne.withValues(
                            alpha: isDark ? 0.15 : 0.12,
                          )
                        : AppColors.surface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: hasActiveFilters
                          ? AppColors.accentChampagne
                          : AppColors.border(context),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: hasActiveFilters
                            ? AppColors.accentChampagne
                            : AppColors.subtext(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        loc.tr('filter_button'),
                        style: AppTypography.caption.copyWith(
                          color: hasActiveFilters
                              ? AppColors.goldText(context)
                              : (isDark
                                    ? AppColors.silverPrimary
                                    : AppColors.lightTextPrimary),
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
                isSelected:
                    _filterOptions.selectedCity == 'الكل' ||
                    _filterOptions.selectedCity == 'All',
                onTap: () {
                  setState(() => _filterOptions.selectedCity = 'الكل');
                  _paging.search({
                    'search': _searchQuery,
                    'city': _filterOptions.selectedCity,
                    'category': _categoryUuid,
                  });
                },
              ),
              const SizedBox(width: 6),
              _QuickCityChip(
                label: loc.isArabic ? "دبي" : "Dubai",
                isSelected:
                    _filterOptions.selectedCity == 'دبي' ||
                    _filterOptions.selectedCity == 'Dubai',
                onTap: () {
                  setState(() => _filterOptions.selectedCity = 'دبي');
                  _paging.search({
                    'search': _searchQuery,
                    'city': _filterOptions.selectedCity,
                    'category': _categoryUuid,
                  });
                },
              ),
              const SizedBox(width: 6),
              _QuickCityChip(
                label: loc.isArabic ? "أبوظبي" : "Abu Dhabi",
                isSelected:
                    _filterOptions.selectedCity == 'أبوظبي' ||
                    _filterOptions.selectedCity == 'Abu Dhabi',
                onTap: () {
                  setState(() => _filterOptions.selectedCity = 'أبوظبي');
                  _paging.search({
                    'search': _searchQuery,
                    'city': _filterOptions.selectedCity,
                    'category': _categoryUuid,
                  });
                },
              ),
              if (_filterOptions.selectedSpecialtyId != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentChampagne.withValues(
                      alpha: isDark ? 0.15 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.accentChampagne,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.tr('cat_${_filterOptions.selectedSpecialtyId}'),
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.silverPrimary
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          setState(
                            () => _filterOptions.selectedSpecialtyId = null,
                          );
                          _paging.search({
                            'search': _searchQuery,
                            'city': _filterOptions.selectedCity,
                            'category': _categoryUuid,
                          });
                        },
                        child: Icon(
                          Icons.close,
                          size: 13,
                          color: AppColors.mutedText(context),
                        ),
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
                  style: AppTypography.caption.copyWith(
                    color: AppColors.mutedText(context),
                  ),
                ),
              ],
            ),
          ),

        // Content Area: Loading / Error / Empty / List
        Expanded(
          child: _isLoading && (_clinics?.isEmpty ?? true)
              ? const LuxuryListSkeleton(itemCount: 4, cardHeight: 130)
              : _errorMessage != null && (_clinics?.isEmpty ?? true)
              ? LuxuryErrorView(message: _errorMessage, onRetry: _loadClinics)
              : clinicList.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                    LuxuryEmptyState(
                      icon: hasActiveFilters || _searchQuery.isNotEmpty
                          ? Icons.search_off_rounded
                          : Icons.local_hospital_outlined,
                      title: hasActiveFilters || _searchQuery.isNotEmpty
                          ? (loc.isArabic
                                ? 'لا توجد عيادات مطابقة للبحث'
                                : 'No clinics match your search')
                          : (loc.isArabic
                                ? 'لا توجد عيادات متاحة حالياً'
                                : 'No clinics available'),
                      subtitle: hasActiveFilters || _searchQuery.isNotEmpty
                          ? (loc.isArabic
                                ? 'يرجى تجربة كلمات بحث أو فلاتر أخرى'
                                : 'Try adjusting your filters or search keywords')
                          : (loc.isArabic
                                ? 'سيتم إضافة عيادات ومراكز تجميلية موثقة قريباً'
                                : 'Verified medical clinics and aesthetic centers will be listed soon'),
                      actionLabel: hasActiveFilters || _searchQuery.isNotEmpty
                          ? (loc.isArabic
                                ? 'إعادة تعيين الفلاتر'
                                : 'Reset Filters')
                          : (loc.isArabic ? 'تحديث' : 'Refresh'),
                      onAction: hasActiveFilters || _searchQuery.isNotEmpty
                          ? () {
                              setState(() {
                                _filterOptions.selectedCity = 'الكل';
                                _filterOptions.selectedSpecialtyId = null;
                                _searchQuery = '';
                                _searchController.clear();
                              });
                              _paging.search({
                                'search': _searchQuery,
                                'city': _filterOptions.selectedCity,
                                'category': _categoryUuid,
                              });
                            }
                          : _loadClinics,
                    ),
                  ],
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: clinicList.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    if (index >= clinicList.length) {
                      return PaginationFooter(
                        loading: _paging.isLoadingMore,
                        hasMore: _paging.hasMore,
                        error: _paging.error,
                        onLoadMore: _paging.loadMore,
                      );
                    }
                    final clinic = clinicList[index];
                    return StaggeredEntrance(
                      index: index,
                      child: LuxuryCard(
                        isVip:
                            clinic.subscriptionTier ==
                            SubscriptionTier.vipPlatinum,
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
                                  fallbackLogoUrl: clinic.logoUrl,
                                  width: 78,
                                  height: 78,
                                  borderRadius: BorderRadius.circular(14),
                                  fit: BoxFit.cover,
                                  placeholderIcon:
                                      Icons.local_hospital_outlined,
                                  iconSize: 32,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              loc.isArabic
                                                  ? clinic.nameAr
                                                  : clinic.nameEn,
                                              style: AppTypography.cardTitle
                                                  .copyWith(
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark
                                                        ? AppColors.textPrimary
                                                        : AppColors
                                                              .lightTextPrimary,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        loc.isArabic
                                            ? clinic.addressAr
                                            : clinic.addressEn,
                                        style: AppTypography.caption.copyWith(
                                          color: isDark
                                              ? AppColors.silverMuted
                                              : AppColors.lightTextMuted,
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
                                  onPressed: () =>
                                      ContactOptionsSheet.show(context, clinic),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    side: BorderSide(
                                      color: AppColors.border(context),
                                      width: 0.8,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    loc.tr('contact_btn'),
                                    style: AppTypography.caption.copyWith(
                                      color: isDark
                                          ? AppColors.silverPrimary
                                          : AppColors.lightTextPrimary,
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
                                      reasonTitle: loc.tr(
                                        'request_consultation',
                                      ),
                                      reasonSubtitle: loc.isArabic
                                          ? 'سجل دخولك برقم الهاتف لإرسال طلبك للعيادة'
                                          : 'Login with phone number to submit your lead',
                                    );
                                    if (auth && context.mounted) {
                                      Navigator.push(
                                        context,
                                        LuxuryPageRoute(
                                          page: AppointmentRequestScreen(
                                            clinic: clinic,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? AppColors.silverPrimary
                                        : AppColors.lightTextPrimary,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    loc.tr('request_appointment'),
                                    style: AppTypography.caption.copyWith(
                                      color: isDark
                                          ? AppColors.backgroundDeep
                                          : Colors.white,
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
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentChampagne.withValues(
                  alpha: isDark ? 0.15 : 0.14,
                )
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.accentChampagne
                : AppColors.border(context),
            width: isSelected ? 1.1 : 0.75,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected
                ? AppColors.goldText(context)
                : (isDark
                      ? AppColors.silverPrimary
                      : AppColors.lightTextPrimary),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }
}
