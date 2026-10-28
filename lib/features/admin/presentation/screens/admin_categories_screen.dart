import 'package:flutter/material.dart';
import '../../../../core/auth/guest_auth_guard.dart';
import '../../../../core/auth/session_snapshot.dart';
import '../../../../core/data/paged_collection.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../treatments/data/category_repository.dart';
import '../../../treatments/models/category_model.dart';
import '../../../treatments/presentation/category_editor.dart';
import '../../../treatments/presentation/category_requests_screen.dart';
import '../widgets/admin_components.dart';

/// Global treatment taxonomy; independent cosmetic-brand categories stay separate.
class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key, this.repository});
  final CategoryRepository? repository;
  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final _session = SessionSnapshot();
  late final _repository = widget.repository ?? CategoryRepository();
  late final _page = PagedCollection<CategoryModel>(
    keyOf: (category) => category.id,
    loader: (page, _) => _repository.getAdminCategories(page: page),
  );
  bool _busy = false;
  String? _error;
  bool get _allowed =>
      _session.isCurrent && AuthState().isLoggedIn && AuthState().isSuperAdmin;
  @override
  void initState() {
    super.initState();
    AuthState().addListener(_changed);
    if (_allowed) _page.refresh();
  }

  void _changed() {
    if (!_allowed) _page.clear();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AuthState().removeListener(_changed);
    _page.dispose();
    super.dispose();
  }

  Future<void> _edit([CategoryModel? category]) async {
    if (_busy || !_allowed) return;
    setState(() => _busy = true);
    try {
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CategoryEditor(
          existing: category,
          onSave: (en, ar, order, active) async {
            await _repository.saveAdminCategory(
              id: category?.id,
              nameEn: en,
              nameAr: ar,
              displayOrder: order,
              isActive: active,
            );
          },
        ),
      );
      if (saved == true && mounted && _allowed) await _page.refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(CategoryModel category) async {
    if (_busy || !_allowed) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            adminText('Delete unused category?', 'حذف التصنيف غير المستخدم؟'),
          ),
          content: Text(
            adminText(
              'Only unused categories can be deleted. Archive a category to keep its existing treatments.',
              'يمكن حذف التصنيفات غير المستخدمة فقط. أرشف التصنيف للاحتفاظ بعلاجاته الحالية.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(adminText('Cancel', 'إلغاء')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(adminText('Delete', 'حذف')),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted || !_allowed) return;
      await _repository.deleteAdminCategory(category.id);
      if (mounted && _allowed) await _page.refresh();
    } catch (e) {
      if (mounted && _allowed) {
        setState(
          () => _error = e is ApiException
              ? e.message
              : adminText(
                  'Unable to delete. Try again.',
                  'تعذر الحذف. حاول مجدداً.',
                ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requests() async {
    if (_busy || !_allowed) return;
    setState(() => _busy = true);
    try {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const CategoryRequestsScreen(admin: true),
        ),
      );
      if (mounted && _allowed) await _page.refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_page, LocaleService(), AuthState()]),
    builder: (context, _) => Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(adminText('Treatment Categories', 'تصنيفات العلاجات')),
      ),
      body: !_allowed
          ? Center(
              child: AdminNotice(
                message: adminText(
                  'Super Admin access is required.',
                  'يتطلب الوصول حساب مشرف عام.',
                ),
              ),
            )
          : AdminDirectory<CategoryModel>(
              items: _page.items,
              page: _page,
              onRefresh: () => _page.refresh(),
              onLoadMore: _page.loadMore,
              headers: [
                AdminSectionTitle(
                  adminText('Treatment categories', 'تصنيفات العلاجات'),
                  subtitle: adminText(
                    'Shared treatment discovery categories across the platform. Archive categories to preserve existing treatments.',
                    'تصنيفات مشتركة لاكتشاف العلاجات على مستوى المنصة. الأرشفة تحافظ على العلاجات الحالية.',
                  ),
                ),
                Wrap(
                  spacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _edit(),
                      icon: const Icon(Icons.add),
                      label: Text(adminText('Add Category', 'إضافة تصنيف')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _requests,
                      icon: const Icon(Icons.inbox_outlined),
                      label: Text(
                        adminText('Category requests', 'طلبات التصنيفات'),
                      ),
                    ),
                  ],
                ),
                if (_error != null) AdminNotice(message: _error!, error: true),
                AdminNotice(
                  message: adminText(
                    'Cosmetic brand-product categories are separate from treatment categories.',
                    'تصنيفات منتجات العلامات التجميلية منفصلة عن تصنيفات العلاجات.',
                  ),
                ),
              ],
              itemBuilder: (context, category) => LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adminName(category.nameEn, category.nameAr),
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      LocaleService().isArabic
                          ? category.nameEn
                          : category.nameAr,
                      style: TextStyle(color: AppColors.mutedText(context)),
                    ),
                    Text(
                      adminText(
                        category.isActive ? 'Active' : 'Archived',
                        category.isActive ? 'نشط' : 'مؤرشف',
                      ),
                    ),
                    Text(
                      '${adminText('Display order', 'ترتيب العرض')}: ${category.displayOrder}',
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: _busy ? null : () => _edit(category),
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(adminText('Edit', 'تعديل')),
                        ),
                        TextButton.icon(
                          onPressed: _busy ? null : () => _delete(category),
                          icon: const Icon(Icons.delete_outline),
                          label: Text(adminText('Delete', 'حذف')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    ),
  );
}
