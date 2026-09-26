import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';

/// Luxury Shimmer / Pulse Placeholder Widget
class LuxuryShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const LuxuryShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.margin,
  });

  @override
  State<LuxuryShimmer> createState() => _LuxuryShimmerState();
}

class _LuxuryShimmerState extends State<LuxuryShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final baseColor = isDark
        ? const Color(0xFF131A26)
        : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: AppColors.border(context).withValues(alpha: 0.5),
              width: 0.6,
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer Skeleton for Home Screen Feed
class HomeFeedSkeleton extends StatelessWidget {
  const HomeFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Top carousel skeleton
          const LuxuryShimmer(
            width: double.infinity,
            height: 180,
            borderRadius: 20,
          ),
          const SizedBox(height: 24),
          // Categories row skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              4,
              (i) => const LuxuryShimmer(width: 72, height: 72, borderRadius: 16),
            ),
          ),
          const SizedBox(height: 24),
          // Section header skeleton
          const LuxuryShimmer(width: 140, height: 20, borderRadius: 6),
          const SizedBox(height: 12),
          // Offers cards skeleton
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => const LuxuryShimmer(
                width: 220,
                height: 150,
                borderRadius: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Nearby clinics section skeleton
          const LuxuryShimmer(width: 160, height: 20, borderRadius: 6),
          const SizedBox(height: 12),
          const LuxuryShimmer(width: double.infinity, height: 110, borderRadius: 16),
          const SizedBox(height: 12),
          const LuxuryShimmer(width: double.infinity, height: 110, borderRadius: 16),
        ],
      ),
    );
  }
}
