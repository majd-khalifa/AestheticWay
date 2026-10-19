import 'package:flutter/material.dart';
import '../localization/app_locale.dart';
import '../theme/app_colors.dart';

class PaginationFooter extends StatelessWidget {
  const PaginationFooter({
    super.key,
    required this.loading,
    required this.hasMore,
    required this.onLoadMore,
    this.error,
  });
  final bool loading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final String? error;
  @override
  Widget build(BuildContext context) {
    if (!hasMore && error == null) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: loading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.expand_more_rounded, size: 18),
                label: Text(
                  error != null
                      ? LocaleService().tr('retry')
                      : LocaleService().tr('load_more'),
                  style: TextStyle(color: AppColors.text(context)),
                ),
              ),
      ),
    );
  }
}

/// Works for vertical lists/grids and nested slivers, including a short first page.
class PagedScrollBoundary extends StatelessWidget {
  const PagedScrollBoundary({
    super.key,
    required this.onLoadMore,
    required this.child,
  });
  final VoidCallback onLoadMore;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0 &&
              notification.metrics.axis == Axis.vertical &&
              notification.metrics.extentAfter < 320) {
            onLoadMore();
          }
          return false;
        },
        child: child,
      );
}
