import 'package:flutter/material.dart';
import '../../../../core/auth/session_snapshot.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pagination_footer.dart';
import '../../../treatments/data/category_repository.dart';
import '../../../treatments/models/category_model.dart';
import '../../services/clinic_portal_service.dart';

/// Global treatment taxonomy is read-only in the supplied Django contract.
/// Selection never grants a clinic authority to mutate shared records.
Future<void> showClinicCategoryManager(
  BuildContext context, {
  String? selectedId,
  ValueChanged<CategoryModel>? onSelected,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppColors.surface(context),
  builder: (_) =>
      _CategoryDirectory(selectedId: selectedId, onSelected: onSelected),
);

class _CategoryDirectory extends StatefulWidget {
  const _CategoryDirectory({this.selectedId, this.onSelected});
  final String? selectedId;
  final ValueChanged<CategoryModel>? onSelected;
  @override
  State<_CategoryDirectory> createState() => _CategoryDirectoryState();
}

class _CategoryDirectoryState extends State<_CategoryDirectory> {
  final _service = ClinicPortalService();
  final _session = SessionSnapshot();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _session.isCurrent) _service.getOrFetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ar = LocaleService().isArabic;
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height:
            (media.size.height - media.viewInsets.bottom - media.padding.top) *
            .88,
        child: ListenableBuilder(
          listenable: _service,
          builder: (context, _) {
            final page = _service.collection('categories');
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  sliver: SliverList.list(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ar ? 'تصنيفات العلاجات' : 'Treatment Categories',
                              style: TextStyle(
                                color: AppColors.text(context),
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            tooltip: ar ? 'إغلاق' : 'Close',
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CategoryRepository.writesUnavailable().message,
                        style: TextStyle(
                          color: AppColors.mutedText(context),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          labelText: ar
                              ? 'البحث في التصنيفات'
                              : 'Search categories',
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          if (_session.isCurrent) {
                            _service.searchCollection('categories', {
                              'search': value.trim(),
                            });
                          }
                        },
                      ),
                      if (!page.isLoading &&
                          page.error == null &&
                          _service.categories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            ar
                                ? 'لا توجد تصنيفات مطابقة. جرّب بحثاً آخر أو تواصل مع إدارة المنصة.'
                                : 'No matching categories. Try another search or contact the platform administrator.',
                          ),
                        ),
                    ],
                  ),
                ),
                SliverList.builder(
                  itemCount: _service.categories.length,
                  itemBuilder: (context, index) {
                    final c = _service.categories[index];
                    return ListTile(
                      title: Text(
                        ar
                            ? (c.nameAr.isEmpty ? c.nameEn : c.nameAr)
                            : c.nameEn,
                      ),
                      subtitle: Text(ar ? c.nameEn : c.nameAr),
                      trailing: c.id == widget.selectedId
                          ? const Icon(Icons.check_circle_outline)
                          : null,
                      onTap: widget.onSelected == null || !_session.isCurrent
                          ? null
                          : () {
                              Navigator.pop(context);
                              widget.onSelected!(c);
                            },
                    );
                  },
                ),
                SliverToBoxAdapter(
                  child: PaginationFooter(
                    loading: page.isLoading || page.isLoadingMore,
                    hasMore: page.hasMore,
                    error: page.error,
                    onLoadMore: () => _service.loadMore('categories'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
