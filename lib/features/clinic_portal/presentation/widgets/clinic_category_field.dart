import 'clinic_category_manager.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/widgets/paged_entity_picker.dart';
import '../../../treatments/models/category_model.dart';
import '../../data/clinic_catalog_repository.dart';

/// A bounded dropdown for loaded categories, with paged access to the full directory.
class ClinicCategoryField extends StatelessWidget {
  const ClinicCategoryField({
    super.key,
    required this.categories,
    required this.value,
    required this.valueLabel,
    required this.onChanged,
  });
  final List<CategoryModel> categories;
  final String? value, valueLabel;
  final ValueChanged<CategoryModel?> onChanged;
  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final options = {
      for (final category in categories.take(50)) category.id: category,
    };
    final selected = categories.where((c) => c.id == value).firstOrNull;
    if (selected != null) options[selected.id] = selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final category = await showClinicCategoryEditor(context);
                if (context.mounted && category != null) onChanged(category);
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(loc.isArabic ? 'إضافة تصنيف' : 'Add Category'),
            ),
            TextButton.icon(
              onPressed: () => showClinicCategoryManager(
                context,
                onUpdated: (category) {
                  if (category.id == value) onChanged(category);
                },
                onDeleted: (id) {
                  if (id == value) onChanged(null);
                },
              ),
              icon: const Icon(Icons.tune, size: 18),
              label: Text(
                loc.isArabic ? 'إدارة التصنيفات' : 'Manage Categories',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey(value),
          initialValue: value,
          isExpanded: true,
          menuMaxHeight: 300,
          decoration: InputDecoration(
            labelText: loc.isArabic ? 'التصنيف الطبي *' : 'Category *',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          hint: Text(
            loc.isArabic ? 'اختر التصنيف الطبي' : 'Select a medical category',
          ),
          items: [
            if (value != null && !options.containsKey(value))
              DropdownMenuItem(
                value: value,
                child: Text(
                  valueLabel ??
                      (loc.isArabic ? 'التصنيف المحدد' : 'Selected category'),
                ),
              ),
            ...options.values.map(
              (c) => DropdownMenuItem(
                value: c.id,
                child: Text(
                  loc.isArabic ? c.nameAr : c.nameEn,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          validator: (v) =>
              v == null ? loc.tr('clinic_validation_required') : null,
          onChanged: (id) {
            final category = options[id];
            if (category != null) onChanged(category);
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.search, size: 18),
          label: Text(
            loc.isArabic ? 'تصفح جميع التصنيفات' : 'Browse all categories',
          ),
          onPressed: () async {
            final result = await showPagedEntityPicker<CategoryModel>(
              context,
              title: loc.isArabic ? 'التصنيف الطبي' : 'Medical Category',
              hint: loc.isArabic ? 'ابحث عن تصنيف' : 'Search categories',
              selectedKey: value,
              keyOf: (c) => c.id,
              labelOf: (c) => loc.isArabic ? c.nameAr : c.nameEn,
              loader: (page, search) => ClinicCatalogRepository().getCategories(
                page: page,
                search: search,
              ),
            );
            if (context.mounted && result != null) onChanged(result.value);
          },
        ),
      ],
    );
  }
}
