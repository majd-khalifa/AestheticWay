import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';

/// Licensing Verification Badge displaying compliant platform license without regulatory body naming
class LicenseBadge extends StatelessWidget {
  final String? authority;
  final String? licenseNumber;
  final bool isCompact;

  const LicenseBadge({
    super.key,
    this.authority,
    this.licenseNumber,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final loc = LocaleService();

    final numStr = (licenseNumber != null && licenseNumber!.isNotEmpty)
        ? licenseNumber!
        : '[LICENSE_PLACEHOLDER]';

    final displayText = loc.isArabic
        ? 'ترخيص معتمد: $numStr'
        : 'Verified: $numStr';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 3.5,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.85)
            : const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? AppColors.accentIceBlue.withValues(alpha: 0.35)
              : const Color(0xFFBFDBFE),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_outlined,
            size: isCompact ? 11 : 12.5,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              displayText,
              style: AppTypography.caption.copyWith(
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E3A8A),
                fontSize: isCompact ? 9.5 : 10.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
