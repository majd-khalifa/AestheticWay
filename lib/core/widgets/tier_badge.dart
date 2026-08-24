import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';

/// Subscription Tier Badge (VIP Platinum & Featured Ads - Fully Bilingual)
class TierBadge extends StatelessWidget {
  final SubscriptionTier tier;
  final bool isCompact;

  const TierBadge({
    super.key,
    required this.tier,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (tier == SubscriptionTier.basic) {
      return const SizedBox.shrink();
    }

    final loc = LocaleService();
    final isVip = tier == SubscriptionTier.vipPlatinum;
    final text = isVip ? loc.tr('vip_partner') : loc.tr('featured_badge');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3.5 : 4.5,
      ),
      decoration: BoxDecoration(
        color: isVip
            ? const Color(0xFF241A0B).withValues(alpha: 0.9)
            : const Color(0xFF131D2D).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVip
              ? AppColors.vipChampagneGold.withValues(alpha: 0.8)
              : AppColors.silverPrimary.withValues(alpha: 0.6),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: AppTypography.badge.copyWith(
          color: isVip ? const Color(0xFFFFE082) : AppColors.silverPrimary,
          fontSize: isCompact ? 10 : 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
