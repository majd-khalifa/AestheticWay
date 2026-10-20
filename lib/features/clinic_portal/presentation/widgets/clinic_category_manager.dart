import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pagination_footer.dart';
import '../../../treatments/models/category_model.dart';
import '../../services/clinic_portal_service.dart';

Future<CategoryModel?> showClinicCategoryEditor(
  BuildContext context, {
  CategoryModel? existing,
}) => showDialog<CategoryModel>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _CategoryEditor(existing: existing),
);

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({this.existing});
  final CategoryModel? existing;
  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  late final TextEditingController en, ar;
  final form = GlobalKey<FormState>();
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    en = TextEditingController(text: widget.existing?.nameEn);
    ar = TextEditingController(text: widget.existing?.nameAr);
  }

  @override
  void dispose() {
    en.dispose();
    ar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        scrollable: true,
        title: Text(
          widget.existing == null
              ? (loc.isArabic ? 'إضافة تصنيف' : 'Add Category')
              : (loc.isArabic ? 'تعديل التصنيف' : 'Edit Category'),
        ),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: en,
                textDirection: TextDirection.ltr,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Category Name (English)',
                  hintText: 'e.g. Skin rejuvenation',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? loc.tr('clinic_validation_required')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ar,
                textDirection: TextDirection.rtl,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'اسم التصنيف (العربية)',
                  hintText: 'مثال: تجديد البشرة',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? loc.tr('clinic_validation_required')
                    : null,
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: AppColors.isDark(context)
                          ? const Color(0xFFFDA4AF)
                          : const Color(0xFF9F1239),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: Text(loc.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    if (!form.currentState!.validate()) return;
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      final service = ClinicPortalService();
                      final category = widget.existing == null
                          ? await service.createCategory(
                              nameEn: en.text.trim(),
                              nameAr: ar.text.trim(),
                            )
                          : await service.updateCategory(
                              widget.existing!.id,
                              nameEn: en.text.trim(),
                              nameAr: ar.text.trim(),
                            );
                      if (context.mounted) Navigator.pop(context, category);
                    } catch (e) {
                      if (context.mounted) {
                        setState(() {
                          busy = false;
                          error = e is ApiException
                              ? e.message
                              : (loc.isArabic
                                    ? 'تعذر حفظ التصنيف. حاول مجدداً.'
                                    : 'Could not save category. Please try again.');
                        });
                      }
                    }
                  },
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(loc.isArabic ? 'حفظ التصنيف' : 'Save Category'),
          ),
        ],
      ),
    );
  }
}

Future<void> showClinicCategoryManager(
  BuildContext context, {
  ValueChanged<CategoryModel>? onUpdated,
  ValueChanged<String>? onDeleted,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppColors.surface(context),
  builder: (_) => _CategoryManager(onUpdated: onUpdated, onDeleted: onDeleted),
);

class _CategoryManager extends StatefulWidget {
  const _CategoryManager({this.onUpdated, this.onDeleted});
  final ValueChanged<CategoryModel>? onUpdated;
  final ValueChanged<String>? onDeleted;
  @override
  State<_CategoryManager> createState() => _CategoryManagerState();
}

class _CategoryManagerState extends State<_CategoryManager> {
  final _service = ClinicPortalService();
  String? _error, _deleting;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _service.getOrFetchCategories();
    });
  }

  Future<void> _delete(CategoryModel category) async {
    final loc = LocaleService();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.isArabic ? 'حذف التصنيف؟' : 'Delete Category?'),
        content: Text(
          loc.isArabic
              ? 'لا يمكن حذف تصنيف مرتبط بعلاجات.'
              : 'Categories used by treatments cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.isArabic ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _deleting = category.id;
      _error = null;
    });
    try {
      await _service.deleteCategory(category.id);
      widget.onDeleted?.call(category.id);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException
              ? e.message
              : (loc.isArabic
                    ? 'تعذر حذف التصنيف'
                    : 'Could not delete category'),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .85,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.isArabic ? 'إدارة التصنيفات' : 'Manage Categories',
              style: TextStyle(
                color: AppColors.text(context),
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await showClinicCategoryEditor(context);
                    if (result != null) widget.onUpdated?.call(result);
                  },
                  icon: const Icon(Icons.add),
                  label: Text(
                    loc.isArabic ? 'إضافة تصنيف جديد' : 'Add New Category',
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.isArabic ? 'إغلاق' : 'Close'),
                ),
              ],
            ),
            TextField(
              decoration: InputDecoration(
                hintText: loc.isArabic ? 'ابحث عن تصنيف' : 'Search categories',
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => _service.searchCollection('categories', {
                'search': value.trim(),
              }),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: AppColors.isDark(context)
                        ? const Color(0xFFFDA4AF)
                        : const Color(0xFF9F1239),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: ListenableBuilder(
                listenable: _service,
                builder: (context, _) => ListView.builder(
                  itemCount: _service.categories.length + 1,
                  itemBuilder: (ctx, index) {
                    if (index >= _service.categories.length) {
                      return PaginationFooter(
                        loading:
                            _service.collection('categories').isLoading ||
                            _service.collection('categories').isLoadingMore,
                        hasMore: _service.collection('categories').hasMore,
                        error: _service.collection('categories').error,
                        onLoadMore: () => _service.loadMore('categories'),
                      );
                    }
                    final category = _service.categories[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.isArabic ? category.nameAr : category.nameEn,
                              style: TextStyle(
                                color: AppColors.text(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              loc.isArabic ? category.nameEn : category.nameAr,
                              style: TextStyle(
                                color: AppColors.mutedText(context),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton.icon(
                                  onPressed: _deleting != null
                                      ? null
                                      : () async {
                                          final result =
                                              await showClinicCategoryEditor(
                                                context,
                                                existing: category,
                                              );
                                          if (result != null) {
                                            widget.onUpdated?.call(result);
                                          }
                                        },
                                  icon: const Icon(Icons.edit_outlined),
                                  label: Text(loc.isArabic ? 'تعديل' : 'Edit'),
                                ),
                                TextButton.icon(
                                  onPressed: _deleting != null
                                      ? null
                                      : () => _delete(category),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.isDark(context)
                                        ? const Color(0xFFFDA4AF)
                                        : const Color(0xFF9F1239),
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                  label: Text(
                                    _deleting == category.id
                                        ? (loc.isArabic
                                              ? 'جارٍ الحذف'
                                              : 'Deleting…')
                                        : (loc.isArabic ? 'حذف' : 'Delete'),
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
            ),
          ],
        ),
      ),
    );
  }
}
