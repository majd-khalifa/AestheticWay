import '../../../locations/presentation/uae_location_picker.dart';
import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/core/widgets/paged_entity_field.dart';
import '../../../treatments/models/category_model.dart';
import '../../../treatments/data/treatments_repository.dart';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';

class ClinicFilterOptions {
  String selectedCity;
  String? selectedAreaCode;
  String? selectedSpecialtyId;
  String? specialtyNameAr, specialtyNameEn;

  ClinicFilterOptions({
    this.selectedCity = 'الكل',
    this.selectedAreaCode,
    this.selectedSpecialtyId,
    this.specialtyNameAr,
    this.specialtyNameEn,
  });

  ClinicFilterOptions copyWith({
    String? selectedCity,
    String? selectedSpecialtyId,
  }) {
    return ClinicFilterOptions(
      selectedCity: selectedCity ?? this.selectedCity,
      selectedAreaCode: selectedCity == null ? selectedAreaCode : null,
      selectedSpecialtyId: selectedSpecialtyId ?? this.selectedSpecialtyId,
      specialtyNameAr: specialtyNameAr,
      specialtyNameEn: specialtyNameEn,
    );
  }

  void reset() {
    selectedCity = 'الكل';
    selectedAreaCode = null;
    selectedSpecialtyId = null;
    specialtyNameAr = null;
    specialtyNameEn = null;
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
    _categoryLabel = LocaleService().isArabic
        ? _filters.specialtyNameAr
        : _filters.specialtyNameEn;
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
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

          Flexible(
            fit: FlexFit.loose,
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
                  UaeLocationField(
                    value: _filters.selectedCity,
                    areaCode: _filters.selectedAreaCode,
                    onLocalityChanged: (value) => setState(() {
                      _filters.selectedCity = value.city.nameEn;
                      _filters.selectedAreaCode = value.area?.code;
                    }),
                    onChanged: (city) => setState(() {
                      _filters.selectedCity = city;
                      _filters.selectedAreaCode = null;
                    }),
                  ),

                  if (_filters.selectedAreaCode != null)
                    Text(
                      loc.isArabic
                          ? 'ستُعرض نتائج المدينة؛ ترشيح المنطقة غير متاح بعد.'
                          : 'Showing city results; area filtering is not available yet.',
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
                      _filters.specialtyNameAr = c?.nameAr;
                      _filters.specialtyNameEn = c?.nameEn;
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
