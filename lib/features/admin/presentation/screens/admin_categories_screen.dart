import 'package:flutter/material.dart';
import '../../../../core/auth/guest_auth_guard.dart';
import '../../../../core/data/paged_collection.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../treatments/data/category_repository.dart';
import '../../../treatments/models/category_model.dart';
import '../../services/admin_portal_service.dart';
import '../widgets/admin_components.dart';

/// The inspected server exposes active treatment-category reads only.
/// Clinic write fallbacks are deliberately not used by this Admin directory.
class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key, this.repository});
  final CategoryRepository? repository;
  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  late final PagedCollection<CategoryModel> _page;
  late final String _identity;
  final _search = TextEditingController();
  bool _sessionValid = true;

  @override
  void initState() {
    super.initState();
    _identity = AuthState().userPhone;
    final repository = widget.repository ?? CategoryRepository();
    _page = PagedCollection<CategoryModel>(
      keyOf: (category) => category.id,
      loader: (page, query) => repository.getCategories(
        page: page,
        search: query['search'] as String?,
      ),
    );
    AuthState().addListener(_sessionChanged);
    if (AdminPortalService().canManage) _page.refresh();
  }

  void _sessionChanged() {
    if (!AdminPortalService().canManage || AuthState().userPhone != _identity) {
      _sessionValid = false;
      _page.clear();
    }
  }

  @override
  void dispose() {
    AuthState().removeListener(_sessionChanged);
    _page.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_page, LocaleService(), AuthState()]),
    builder: (context, _) {
      final unavailable = adminText(
        'Category changes are currently unavailable.',
        'تعديل التصنيفات غير متاح حالياً.',
      );
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        appBar: AppBar(
          title: Text(adminText('Treatment Categories', 'تصنيفات العلاجات')),
        ),
        body: !_sessionValid || !AdminPortalService().canManage
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
                    adminText(
                      'Active treatment categories',
                      'تصنيفات العلاجات النشطة',
                    ),
                    subtitle: adminText(
                      'Shared treatment discovery categories across the platform.',
                      'تصنيفات مشتركة لاكتشاف العلاجات على مستوى المنصة.',
                    ),
                  ),
                  AdminNotice(message: unavailable),
                  Tooltip(
                    message: unavailable,
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.add),
                      label: Text(adminText('Add Category', 'إضافة تصنيف')),
                    ),
                  ),
                  TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      labelText: adminText(
                        'Search treatment categories',
                        'البحث في تصنيفات العلاجات',
                      ),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) =>
                        _page.search({'search': value.trim()}),
                  ),
                  AdminNotice(
                    message: adminText(
                      'Cosmetic brand-product categories are separate and are not available yet.',
                      'تصنيفات منتجات العلامات التجميلية منفصلة وغير متاحة بعد.',
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
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final (icon, label) in [
                            (Icons.edit_outlined, adminText('Edit', 'تعديل')),
                            (Icons.delete_outline, adminText('Delete', 'حذف')),
                          ])
                            Tooltip(
                              message: unavailable,
                              child: TextButton.icon(
                                onPressed: null,
                                icon: Icon(icon),
                                label: Text(label),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      );
    },
  );
}
