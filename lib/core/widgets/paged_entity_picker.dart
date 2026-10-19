import 'package:flutter/material.dart';
import '../auth/guest_auth_guard.dart';
import '../data/paged_collection.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'pagination_footer.dart';

class EntitySelection<T> {
  const EntitySelection(this.value);
  final T? value;
}

Future<EntitySelection<T>?> showPagedEntityPicker<T>(
  BuildContext context, {
  required String title,
  required String hint,
  required String Function(T) keyOf,
  required String Function(T) labelOf,
  required Future<List<T>> Function(int, String) loader,
  String? selectedKey,
  String? clearLabel,
}) => showModalBottomSheet<EntitySelection<T>>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.surface(context),
  builder: (_) => _Picker<T>(
    title: title,
    hint: hint,
    keyOf: keyOf,
    labelOf: labelOf,
    loader: loader,
    selectedKey: selectedKey,
    clearLabel: clearLabel,
  ),
);

class _Picker<T> extends StatefulWidget {
  const _Picker({
    required this.title,
    required this.hint,
    required this.keyOf,
    required this.labelOf,
    required this.loader,
    this.selectedKey,
    this.clearLabel,
  });
  final String title, hint;
  final String Function(T) keyOf, labelOf;
  final Future<List<T>> Function(int, String) loader;
  final String? selectedKey, clearLabel;
  @override
  State<_Picker<T>> createState() => _PickerState<T>();
}

class _PickerState<T> extends State<_Picker<T>> {
  late final PagedCollection<T> _page;
  late final String _identity;
  @override
  void initState() {
    super.initState();
    _identity = AuthState().userPhone;
    AuthState().addListener(_identityChanged);
    _page = PagedCollection<T>(
      loader: (page, query) =>
          widget.loader(page, query['search']?.toString() ?? ''),
      keyOf: widget.keyOf,
    )..refresh();
  }

  void _identityChanged() {
    if (AuthState().userPhone != _identity) _page.clear();
  }

  @override
  void dispose() {
    AuthState().removeListener(_identityChanged);
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height:
            (media.size.height - media.viewInsets.bottom - media.padding.top) *
            0.86,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 6, 20, 12),
              child: Text(
                widget.title,
                style: AppTypography.cardTitle.copyWith(
                  color: AppColors.text(context),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
                onChanged: (text) => _page.search({'search': text.trim()}),
              ),
            ),
            if (widget.clearLabel != null)
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, EntitySelection<T>(null)),
                child: Text(widget.clearLabel!),
              ),
            Expanded(
              child: ListenableBuilder(
                listenable: _page,
                builder: (context, _) {
                  if (_page.isLoading && _page.items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return PagedScrollBoundary(
                    onLoadMore: _page.loadMore,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _page.items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _page.items.length) {
                          return PaginationFooter(
                            loading: _page.isLoadingMore,
                            hasMore: _page.hasMore,
                            error: _page.error,
                            onLoadMore: () => _page.isLoaded
                                ? _page.loadMore()
                                : _page.refresh(),
                          );
                        }
                        final item = _page.items[index];
                        return ListTile(
                          title: Text(widget.labelOf(item)),
                          trailing: widget.keyOf(item) == widget.selectedKey
                              ? const Icon(Icons.check_rounded)
                              : null,
                          onTap: () =>
                              Navigator.pop(context, EntitySelection(item)),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
