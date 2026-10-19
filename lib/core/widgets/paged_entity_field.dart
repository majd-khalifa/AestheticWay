import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'paged_entity_picker.dart';

/// A form control backed by a searchable, paginated sheet, rather than a huge menu.
class PagedEntityField<T> extends StatelessWidget {
  const PagedEntityField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.valueLabel,
    required this.keyOf,
    required this.labelOf,
    required this.loader,
    required this.onChanged,
    this.clearLabel,
    this.validator,
  });
  final String label, hint, valueLabel;
  final String? value, clearLabel;
  final String Function(T) keyOf, labelOf;
  final Future<List<T>> Function(int, String) loader;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<String>? validator;
  @override
  Widget build(BuildContext context) => FormField<String>(
    key: ValueKey(value),
    initialValue: value,
    validator: validator,
    builder: (field) => InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        errorText: field.errorText,
        contentPadding: const EdgeInsetsDirectional.fromSTEB(12, 4, 4, 4),
      ),
      child: TextButton(
        onPressed: () async {
          final result = await showPagedEntityPicker<T>(
            context,
            title: label,
            hint: hint,
            selectedKey: value,
            clearLabel: clearLabel,
            keyOf: keyOf,
            labelOf: labelOf,
            loader: loader,
          );
          if (result != null && field.mounted) {
            field.didChange(
              result.value == null ? null : keyOf(result.value as T),
            );
            onChanged(result.value);
          }
        },
        style: TextButton.styleFrom(
          alignment: AlignmentDirectional.centerStart,
          foregroundColor: AppColors.text(context),
          minimumSize: const Size(48, 48),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                valueLabel.isEmpty ? hint : valueLabel,
                style: const TextStyle(height: 1.5),
              ),
            ),
            const Icon(Icons.expand_more_rounded),
          ],
        ),
      ),
    ),
  );
}
