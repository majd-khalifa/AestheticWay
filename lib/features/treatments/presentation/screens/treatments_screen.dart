import 'package:aesthetic_way/core/widgets/patient_image.dart';
import 'package:aesthetic_way/core/theme/patient_design.dart';
import '../../../../core/widgets/luxury_empty_state.dart';
import 'package:aesthetic_way/core/widgets/paged_entity_picker.dart';
import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/core/widgets/pagination_footer.dart';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/features/treatments/data/treatments_repository.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';
import 'package:aesthetic_way/features/treatments/presentation/screens/treatment_detail_screen.dart';

/// Screen 2 & 5: Treatments & Plastic Surgery Directory
class TreatmentsScreen extends StatefulWidget {
  final String? initialCategory;
  final TreatmentsRepository? repository;

  const TreatmentsScreen({super.key, this.initialCategory, this.repository});

  @override
  State<TreatmentsScreen> createState() => _TreatmentsScreenState();
}

class _TreatmentsScreenState extends State<TreatmentsScreen> {
  late final TreatmentsRepository _repository =
      widget.repository ?? TreatmentsRepository();
  late String _selectedCategory;
  String _searchQuery = '';
  late final PagedCollection<TreatmentModel> _paging;
  List<TreatmentModel> get _treatments => _paging.items;
  bool get _isLoading => _paging.isLoading && _paging.items.isEmpty;
  String? get _error => _paging.items.isEmpty ? _paging.error : null;
  void _pageChanged() {
    if (mounted) setState(() {});
  }

  List<Map<String, dynamic>> _apiCategories = [];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'all';
    _paging = PagedCollection<TreatmentModel>(
      loader: (page, q) => _repository.getTreatments(
        category: q['category'] as String?,
        search: q['search'] as String?,
        page: page,
        pageSize: 20,
      ),
      keyOf: (item) => item.id,
    )..addListener(_pageChanged);
    _loadData();
  }

  Future<void> _loadData() async {
    if (_apiCategories.isEmpty) {
      try {
        var categories = await _repository.getCategories();
        if (!mounted) return;
        if (_selectedCategory != 'all' && _categoryUuid == null) {
          var match = categories
              .where(
                (c) =>
                    c['slug'] == _selectedCategory ||
                    '${c['name_en']}'.toLowerCase() ==
                        _selectedCategory.toLowerCase(),
              )
              .firstOrNull;
          if (match == null) {
            final matches = await _repository.getCategories(
              search: _selectedCategory.replaceAll('-', ' '),
            );
            match = matches
                .where(
                  (c) =>
                      c['slug'] == _selectedCategory ||
                      '${c['name_en']}'.toLowerCase() ==
                          _selectedCategory.toLowerCase(),
                )
                .firstOrNull;
            categories = [
              ...categories,
              ...matches.where(
                (m) => !categories.any((c) => c['id'] == m['id']),
              ),
            ].take(20).toList();
          }
          _selectedCategory = match?['id']?.toString() ?? 'all';
        }
        setState(() => _apiCategories = categories);
      } catch (_) {
        if (_categoryUuid == null) _selectedCategory = 'all';
      }
    }
    if (mounted) {
      await _paging.refresh(
        query: {'search': _searchQuery, 'category': _categoryUuid},
      );
    }
  }

  void _onSearchChanged(String value) {
    _searchQuery = value.trim();
    _paging.search({'search': _searchQuery, 'category': _categoryUuid});
  }

  @override
  void dispose() {
    _paging.dispose();
    super.dispose();
  }

  String? get _categoryUuid =>
      RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(_selectedCategory)
      ? _selectedCategory
      : null;

  @override
  Widget build(BuildContext context) => PatientDesign(builder: _buildPatient);

  Widget _buildPatient(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    final isPlasticSurgeryOnly =
        widget.initialCategory != null &&
        (widget.initialCategory!.toLowerCase().contains('surgery') ||
            widget.initialCategory!.contains('جراحة'));

    final screenTitle = isPlasticSurgeryOnly
        ? loc.tr('category_plastic_surgery_title')
        : loc.tr('category_treatments_title');

    final categories = [
      {'id': 'all', 'label': loc.tr('treatment_category_all')},
      ..._apiCategories.map(
        (c) => {
          'id': c['id']?.toString() ?? '',
          'label':
              (loc.isArabic ? c['name_ar'] : c['name_en'])?.toString() ?? '',
        },
      ),
    ];
    final filteredTreatments = _treatments;

    return ListenableBuilder(
      listenable: loc,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Text(
              screenTitle,
              style: AppTypography.screenTitle.copyWith(
                color: isDark
                    ? AppColors.silverPrimary
                    : AppColors.lightTextPrimary,
                fontSize: 16,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark
                    ? AppColors.silverPrimary
                    : AppColors.lightTextPrimary,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: PagedScrollBoundary(
            onLoadMore: _paging.loadMore,
            child: Column(
              children: [
                // Search Box
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.border(context),
                        width: 0.8,
                      ),
                    ),
                    child: TextField(
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 13.5,
                      ),
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: loc.tr('treatments_search_hint'),
                        hintStyle: TextStyle(
                          color: AppColors.text(context),
                          fontSize: 12,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.mutedText(context),
                          size: 18,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),

                // Category Tabs (Only if not exclusively plastic surgery)
                TextButton.icon(
                  onPressed: () async {
                    final result =
                        await showPagedEntityPicker<Map<String, dynamic>>(
                          context,
                          title: loc.tr('filter_specialty'),
                          hint: loc.tr('treatments_search_hint'),
                          selectedKey: _categoryUuid,
                          clearLabel: loc.tr('treatment_category_all'),
                          keyOf: (c) => c['id'].toString(),
                          labelOf: (c) =>
                              (loc.isArabic ? c['name_ar'] : c['name_en'])
                                  .toString(),
                          loader: (page, search) => _repository.getCategories(
                            page: page,
                            search: search,
                          ),
                        );
                    if (mounted && result != null) {
                      setState(() {
                        _selectedCategory =
                            result.value?['id']?.toString() ?? 'all';
                        if (result.value != null &&
                            !_apiCategories.any(
                              (c) => c['id'] == result.value!['id'],
                            )) {
                          _apiCategories = [
                            ..._apiCategories.take(19),
                            result.value!,
                          ];
                        }
                      });
                      _paging.search({
                        'search': _searchQuery,
                        'category': _categoryUuid,
                      });
                    }
                  },
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: Text(loc.tr('filter_specialty')),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            cat['label']!,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppColors.backgroundDeep
                                  : AppColors.text(context),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.accentChampagne,
                          backgroundColor: isDark
                              ? AppColors.cardSurface
                              : AppColors.lightCardSurface,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.accentChampagne
                                : AppColors.border(context),
                            width: 0.8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = cat['id']!;
                            });
                            _paging.search({
                              'search': _searchQuery,
                              'category': _categoryUuid,
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),

                // Treatments List
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentChampagne,
                          ),
                        )
                      : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: AppColors.mutedText(context),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _loadData,
                                child: Text(
                                  loc.isArabic ? 'إعادة المحاولة' : 'Retry',
                                ),
                              ),
                            ],
                          ),
                        )
                      : filteredTreatments.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              LuxuryEmptyState(
                                icon: Icons.medical_services_outlined,
                                title: loc.isArabic
                                    ? 'لا توجد إجراءات منشورة'
                                    : 'No treatments published',
                                subtitle: loc.isArabic
                                    ? 'جرّب تصنيفاً آخر أو استفسر من العيادات عن الخدمات المتاحة.'
                                    : 'Try another category or ask a clinic about available services.',
                                actionLabel: loc.isArabic
                                    ? 'إعادة تحميل الدليل'
                                    : 'Reload directory',
                                onAction: _loadData,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.accentChampagne,
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: filteredTreatments.length + 1,
                            itemBuilder: (context, index) {
                              if (index >= filteredTreatments.length) {
                                return PaginationFooter(
                                  loading: _paging.isLoadingMore,
                                  hasMore: _paging.hasMore,
                                  error: _paging.error,
                                  onLoadMore: _paging.loadMore,
                                );
                              }

                              final treatment = filteredTreatments[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: LuxuryCard(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      LuxuryPageRoute(
                                        page: TreatmentDetailScreen(
                                          treatment: treatment,
                                        ),
                                      ),
                                    );
                                  },
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      PatientImage(
                                        category:
                                            PatientMediaCategory.treatment,
                                        imageUrl: treatment.imageUrl,
                                        width: 80,
                                        height: 80,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.accentChampagne
                                                    .withValues(
                                                      alpha: isDark
                                                          ? 0.12
                                                          : 0.18,
                                                    ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                loc.isArabic
                                                    ? treatment.categoryAr
                                                    : treatment.categoryEn,
                                                style: TextStyle(
                                                  color: AppColors.goldText(
                                                    context,
                                                  ),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              loc.isArabic
                                                  ? treatment.nameAr
                                                  : treatment.nameEn,
                                              style: TextStyle(
                                                color: isDark
                                                    ? AppColors.silverPrimary
                                                    : AppColors
                                                          .lightTextPrimary,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (treatment
                                                .formattedDuration(loc.isArabic)
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                '${loc.tr("duration_label")}: ${treatment.formattedDuration(loc.isArabic)}',
                                                style: TextStyle(
                                                  color: AppColors.subtext(
                                                    context,
                                                  ),
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ] else if ((loc.isArabic
                                                        ? treatment.clinicNameAr
                                                        : treatment
                                                              .clinicNameEn)
                                                    ?.isNotEmpty ==
                                                true) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                (loc.isArabic
                                                    ? treatment.clinicNameAr
                                                    : treatment.clinicNameEn)!,
                                                style: TextStyle(
                                                  color: AppColors.subtext(
                                                    context,
                                                  ),
                                                  fontSize: 11.5,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: AppColors.accentChampagne,
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
          ),
        );
      },
    );
  }
}
