import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/core/widgets/paged_entity_field.dart';
import '../../../treatments/models/category_model.dart';
import '../../../treatments/data/treatments_repository.dart';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';

enum ClinicSortOption { featuredFirst, highestRating, nearestDistance }

class ClinicFilterOptions {
  String
  selectedCity; // 'الكل' / 'دبي' / 'أبوظبي' or 'All' / 'Dubai' / 'Abu Dhabi'
  String? selectedSpecialtyId;
  PractitionerType? selectedPractitionerType;
  ClinicSortOption sortOption;

  ClinicFilterOptions({
    this.selectedCity = 'الكل',
    this.selectedSpecialtyId,
    this.selectedPractitionerType,
    this.sortOption = ClinicSortOption.featuredFirst,
  });

  ClinicFilterOptions copyWith({
    String? selectedCity,
    String? selectedSpecialtyId,
    PractitionerType? selectedPractitionerType,
    ClinicSortOption? sortOption,
  }) {
    return ClinicFilterOptions(
      selectedCity: selectedCity ?? this.selectedCity,
      selectedSpecialtyId: selectedSpecialtyId ?? this.selectedSpecialtyId,
      selectedPractitionerType:
          selectedPractitionerType ?? this.selectedPractitionerType,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  void reset() {
    selectedCity = 'الكل';
    selectedSpecialtyId = null;
    selectedPractitionerType = null;
    sortOption = ClinicSortOption.featuredFirst;
  }
}

/// Comprehensive, fully functional Filter Bottom Sheet adapting to Dark & Light Themes
class FilterBottomSheet extends StatefulWidget {
  final ClinicFilterOptions initialFilters;
  final ValueChanged<ClinicFilterOptions> onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required ClinicFilterOptions currentFilters,
    required ValueChanged<ClinicFilterOptions> onApply,
  }) {
    final isDark = AppColors.isDark(context);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark
          ? AppColors.backgroundBase
          : AppColors.lightCardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          FilterBottomSheet(initialFilters: currentFilters, onApply: onApply),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late ClinicFilterOptions _filters;
  String? _categoryLabel;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters.copyWith();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: AppColors.accentChampagne,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.tr('filter_title'),
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.silverPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _filters.reset();
                    _categoryLabel = null;
                  });
                },
                child: Text(
                  loc.tr('reset_filters'),
                  style: TextStyle(
                    color: AppColors.mutedText(context),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // 1. City Filter
                  Text(
                    loc.tr('filter_city'),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.silverPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChipWidget(
                        label: loc.tr('city_all'),
                        isSelected:
                            _filters.selectedCity == 'الكل' ||
                            _filters.selectedCity == 'All',
                        onTap: () =>
                            setState(() => _filters.selectedCity = 'الكل'),
                      ),
                      _FilterChipWidget(
                        label: loc.tr('city_dubai'),
                        isSelected:
                            _filters.selectedCity == 'دبي' ||
                            _filters.selectedCity == 'Dubai',
                        onTap: () =>
                            setState(() => _filters.selectedCity = 'دبي'),
                      ),
                      _FilterChipWidget(
                        label: loc.tr('city_abudhabi'),
                        isSelected:
                            _filters.selectedCity == 'أبوظبي' ||
                            _filters.selectedCity == 'Abu Dhabi',
                        onTap: () =>
                            setState(() => _filters.selectedCity = 'أبوظبي'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  // 2. Specialty Filter
                  Text(
                    loc.tr('filter_specialty'),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.silverPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PagedEntityField<CategoryModel>(
                    label: loc.tr('filter_specialty'),
                    hint: loc.isArabic
                        ? 'ابحث عن التصنيف الطبي'
                        : 'Search medical categories',
                    value: _filters.selectedSpecialtyId,
                    valueLabel: _categoryLabel ?? '',
                    clearLabel: loc.tr('treatment_category_all'),
                    keyOf: (c) => c.id,
                    labelOf: (c) => loc.isArabic ? c.nameAr : c.nameEn,
                    loader: (page, search) async {
                      final values = await TreatmentsRepository().getCategories(
                        page: page,
                        search: search,
                      );
                      return PageItems<CategoryModel>(
                        values.map(CategoryModel.fromJson),
                        hasMore: values is PageItems<Map<String, dynamic>>
                            ? values.hasMore
                            : values.length == 20,
                      );
                    },
                    onChanged: (c) => setState(() {
                      _filters.selectedSpecialtyId = c?.id;
                      _categoryLabel = c == null
                          ? null
                          : (loc.isArabic ? c.nameAr : c.nameEn);
                    }),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Apply Button
          SilverButton(
            label: loc.tr('apply_filters'),
            icon: Icons.check_circle_outline,
            isFullWidth: true,
            onPressed: () {
              widget.onApply(_filters);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipWidget({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.goldText(
                  context,
                ).withValues(alpha: isDark ? 0.2 : 0.16)
              : (isDark
                    ? AppColors.cardSurfaceHover
                    : AppColors.lightCardSurfaceHover),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.goldText(context)
                : AppColors.border(context),
            width: isSelected ? 1.2 : 0.8,
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
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
