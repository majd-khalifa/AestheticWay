import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/widgets/luxury_shimmer.dart';

/// Bespoke Luxury Refresh Indicator with tactile haptic response & platinum/champagne styling
class LuxuryRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final double displacement;

  const LuxuryRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.displacement = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return RefreshIndicator(
      displacement: displacement,
      strokeWidth: 2.2,
      color: AppColors.accentChampagne,
      backgroundColor: isDark ? const Color(0xFF111B38) : Colors.white,
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await onRefresh();
      },
      child: child,
    );
  }
}

/// Architectural Shimmer Skeleton Card with simulated media thumbnail and content lines
class LuxuryCardShimmerSkeleton extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry margin;

  const LuxuryCardShimmerSkeleton({
    super.key,
    this.height = 130.0,
    this.margin = const EdgeInsets.only(bottom: 12.0),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final thumbSize = (height - 28.0).clamp(60.0, 110.0);

    return Container(
      height: height,
      margin: margin,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(context).withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LuxuryShimmer(
            width: thumbSize,
            height: thumbSize,
            borderRadius: 12,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                LuxuryShimmer(width: double.infinity, height: 16, borderRadius: 4),
                LuxuryShimmer(width: 130, height: 12, borderRadius: 4),
                Row(
                  children: [
                    LuxuryShimmer(width: 65, height: 20, borderRadius: 6),
                    SizedBox(width: 8),
                    LuxuryShimmer(width: 50, height: 20, borderRadius: 6),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// List of Skeleton Cards for full-page loading replacement
class LuxuryListSkeleton extends StatelessWidget {
  final int itemCount;
  final double cardHeight;
  final EdgeInsetsGeometry padding;

  const LuxuryListSkeleton({
    super.key,
    this.itemCount = 4,
    this.cardHeight = 130.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (_, _) => LuxuryCardShimmerSkeleton(height: cardHeight),
    );
  }
}
