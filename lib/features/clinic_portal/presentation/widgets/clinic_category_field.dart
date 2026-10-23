import 'clinic_category_manager.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../treatments/models/category_model.dart';

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
          onPressed: () => showClinicCategoryManager(
            context,
            selectedId: value,
            onSelected: (category) {
              if (context.mounted) onChanged(category);
            },
          ),
        ),
      ],
    );
  }
}
