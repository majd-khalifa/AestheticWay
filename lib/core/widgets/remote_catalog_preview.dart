import 'package:flutter/material.dart';
import '../auth/guest_auth_guard.dart';
import '../data/paged_collection.dart';
import 'bounded_catalog_preview.dart';
import 'pagination_footer.dart';

/// A separately scoped embedded directory owns its requests and session lifetime.
class RemoteCatalogPreview<T> extends StatefulWidget {
  const RemoteCatalogPreview({
    super.key,
    required this.loader,
    required this.keyOf,
    required this.itemBuilder,
    this.emptyState,
  });
  final Widget? emptyState;
  final Future<List<T>> Function(int page) loader;
  final String Function(T) keyOf;
  final Widget Function(BuildContext context, T item) itemBuilder;
  @override
  State<RemoteCatalogPreview<T>> createState() =>
      _RemoteCatalogPreviewState<T>();
}

class _RemoteCatalogPreviewState<T> extends State<RemoteCatalogPreview<T>> {
  late final PagedCollection<T> _page;
  late final String _identity;
  bool _sessionValid = true;
  @override
  void initState() {
    super.initState();
    _identity = AuthState().userPhone;
    _page = PagedCollection<T>(
      loader: (page, _) async {
        if (!_sessionValid) return <T>[];
        final result = await widget.loader(page);
        return _sessionValid ? result : <T>[];
      },
      keyOf: widget.keyOf,
    );
    AuthState().addListener(_sessionChanged);
    _page.refresh();
  }

  void _sessionChanged() {
    if (_identity != AuthState().userPhone) {
      _sessionValid = false;
      _page.clear();
    }
  }

  @override
  void dispose() {
    AuthState().removeListener(_sessionChanged);
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _page,
    builder: (context, _) {
      if (_page.isLoading && _page.items.isEmpty) {
        return const LinearProgressIndicator(minHeight: 2);
      }
      if (_page.error != null && _page.items.isEmpty) {
        return PaginationFooter(
          loading: false,
          hasMore: true,
          error: _page.error,
          onLoadMore: _page.refresh,
        );
      }
      if (_page.isLoaded && _page.items.isEmpty && widget.emptyState != null) {
        return widget.emptyState!;
      }
      return BoundedCatalogPreview<T>(
        items: () => _page.items,
        listenable: _page,
        page: _page,
        itemBuilder: widget.itemBuilder,
      );
    },
  );
}
