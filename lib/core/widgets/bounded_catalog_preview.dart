import 'package:flutter/material.dart';
import '../data/paged_collection.dart';
import '../localization/app_locale.dart';
import '../theme/app_colors.dart';
import 'pagination_footer.dart';

/// A profile never eagerly lays out a clinic's entire catalog.
class BoundedCatalogPreview<T> extends StatelessWidget {
  const BoundedCatalogPreview({
    super.key,
    required this.items,
    required this.listenable,
    required this.itemBuilder,
    this.page,
    this.limit = 6,
  });
  final ValueGetter<List<T>> items;
  final Listenable listenable;
  final Widget Function(BuildContext, T) itemBuilder;
  final PagedCollection<dynamic>? page;
  final int limit;
  @override
  Widget build(BuildContext context) {
    final values = items();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in values.take(limit)) itemBuilder(context, item),
        if (values.length > limit || page?.hasMore == true)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.surface(context),
                builder: (_) => _CatalogSheet<T>(
                  items: items,
                  listenable: listenable,
                  itemBuilder: itemBuilder,
                  page: page,
                ),
              ),
              label: Text(LocaleService().tr('view_all')),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            ),
          ),
      ],
    );
  }
}

class _CatalogSheet<T> extends StatefulWidget {
  const _CatalogSheet({
    required this.items,
    required this.listenable,
    required this.itemBuilder,
    this.page,
  });
  final ValueGetter<List<T>> items;
  final Listenable listenable;
  final Widget Function(BuildContext, T) itemBuilder;
  final PagedCollection<dynamic>? page;
  @override
  State<_CatalogSheet<T>> createState() => _CatalogSheetState<T>();
}

class _CatalogSheetState<T> extends State<_CatalogSheet<T>> {
  int _localLimit = catalogPageSize;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.page != null && !widget.page!.isLoaded) {
        widget.page!.refresh();
      }
    });
  }

  void _more() {
    if (widget.page != null) {
      widget.page!.loadMore();
    } else if (_localLimit < widget.items().length) {
      setState(() => _localLimit += catalogPageSize);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: ListenableBuilder(
        listenable: widget.listenable,
        builder: (context, _) {
          final all = widget.items();
          final values = widget.page == null
              ? all.take(_localLimit).toList()
              : all;
          return PagedScrollBoundary(
            onLoadMore: _more,
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              itemCount: values.length + 1,
              itemBuilder: (context, index) => index < values.length
                  ? widget.itemBuilder(context, values[index])
                  : PaginationFooter(
                      loading: widget.page?.isLoadingMore ?? false,
                      hasMore:
                          widget.page?.hasMore ?? (_localLimit < all.length),
                      error: widget.page?.error,
                      onLoadMore: _more,
                    ),
            ),
          );
        },
      ),
    ),
  );
}
