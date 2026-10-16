import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';

/// Editorial Section Header with vertical 3px champagne accent bar and refined typography
class LuxurySectionHeader extends StatelessWidget {
  final String title;
  final Widget? leadingIcon;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const LuxurySectionHeader({
    super.key,
    required this.title,
    this.leadingIcon,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.accentChampagne,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                if (leadingIcon != null) ...[
                  leadingIcon!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.25,
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
