import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';

enum ClinicSortOption {
  featuredFirst,
  highestRating,
  nearestDistance,
}

class ClinicFilterOptions {
  String selectedCity; // 'الكل' / 'دبي' / 'أبوظبي' or 'All' / 'Dubai' / 'Abu Dhabi'
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
      selectedPractitionerType: selectedPractitionerType ?? this.selectedPractitionerType,
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
      backgroundColor: isDark ? AppColors.backgroundBase : AppColors.lightCardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FilterBottomSheet(
        initialFilters: currentFilters,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late ClinicFilterOptions _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters.copyWith();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    final specialties = [
      {'id': null, 'labelAr': 'جميع الخدمات', 'labelEn': 'All Services'},
      {'id': 'offers', 'labelAr': 'العروض', 'labelEn': 'Offers'},
      {'id': 'treatments', 'labelAr': 'العلاجات', 'labelEn': 'Treatments'},
      {'id': 'doctors', 'labelAr': 'الأطباء', 'labelEn': 'Doctors'},
      {'id': 'skin_experts', 'labelAr': 'خبيرات البشرة', 'labelEn': 'Skin Experts'},
      {'id': 'surgery', 'labelAr': 'الجراحة التجميلية', 'labelEn': 'Plastic Surgery'},
      {'id': 'products', 'labelAr': 'المنتجات', 'labelEn': 'Products'},
      {'id': 'clinics', 'labelAr': 'العيادات', 'labelEn': 'Clinics'},
    ];

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
                  const Icon(Icons.tune_rounded, size: 20, color: AppColors.accentChampagne),
                  const SizedBox(width: 8),
                  Text(
                    loc.tr('filter_title'),
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _filters.reset();
                  });
                },
                child: Text(
                  loc.tr('reset_filters'),
                  style: TextStyle(color: AppColors.mutedText(context), fontSize: 13),
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
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChipWidget(
                        label: loc.tr('city_all'),
                        isSelected: _filters.selectedCity == 'الكل' || _filters.selectedCity == 'All',
                        onTap: () => setState(() => _filters.selectedCity = 'الكل'),
                      ),
                      _FilterChipWidget(
                        label: loc.tr('city_dubai'),
                        isSelected: _filters.selectedCity == 'دبي' || _filters.selectedCity == 'Dubai',
                        onTap: () => setState(() => _filters.selectedCity = 'دبي'),
                      ),
                      _FilterChipWidget(
                        label: loc.tr('city_abudhabi'),
                        isSelected: _filters.selectedCity == 'أبوظبي' || _filters.selectedCity == 'Abu Dhabi',
                        onTap: () => setState(() => _filters.selectedCity = 'أبوظبي'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  // 2. Specialty Filter
                  Text(
                    loc.tr('filter_specialty'),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: specialties.map((s) {
                      final id = s['id'];
                      final label = loc.isArabic ? s['labelAr']! : s['labelEn']!;
                      final isSelected = _filters.selectedSpecialtyId == id;
                      return _FilterChipWidget(
                        label: label,
                        isSelected: isSelected,
                        onTap: () => setState(() => _filters.selectedSpecialtyId = id),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),
                  // 3. Sort Options
                  Text(
                    loc.tr('filter_sort'),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChipWidget(
                        label: loc.tr('sort_featured'),
                        isSelected: _filters.sortOption == ClinicSortOption.featuredFirst,
                        onTap: () => setState(() => _filters.sortOption = ClinicSortOption.featuredFirst),
                      ),
                      _FilterChipWidget(
                        label: loc.tr('sort_rating'),
                        isSelected: _filters.sortOption == ClinicSortOption.highestRating,
                        onTap: () => setState(() => _filters.sortOption = ClinicSortOption.highestRating),
                      ),
                      _FilterChipWidget(
                        label: loc.tr('sort_distance'),
                        isSelected: _filters.sortOption == ClinicSortOption.nearestDistance,
                        onTap: () => setState(() => _filters.sortOption = ClinicSortOption.nearestDistance),
                      ),
                    ],
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
              ? AppColors.accentChampagne.withValues(alpha: isDark ? 0.2 : 0.16)
              : (isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.accentChampagne
                : AppColors.border(context),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected
                ? AppColors.accentChampagne
                : (isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
