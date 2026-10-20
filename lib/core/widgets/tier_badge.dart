import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';

/// Subscription Tier Badge (VIP Platinum & Featured Ads - Fully Bilingual)
class TierBadge extends StatelessWidget {
  final SubscriptionTier tier;
  final bool isCompact;
  final bool showBasic;

  const TierBadge({
    super.key,
    required this.tier,
    this.isCompact = false,
    this.showBasic = false,
  });

  @override
  Widget build(BuildContext context) {
    if (tier == SubscriptionTier.basic && !showBasic) {
      return const SizedBox.shrink();
    }

    final loc = LocaleService();
    final isVip = tier == SubscriptionTier.vipPlatinum;
    final text = tier == SubscriptionTier.basic
        ? (loc.isArabic ? 'أساسي' : 'Basic')
        : isVip
        ? loc.tr('vip_partner')
        : loc.tr('featured_badge');
    final foreground = isVip
        ? AppColors.goldText(context)
        : AppColors.text(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3.5 : 4.5,
      ),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: foreground.withValues(alpha: .25), width: .8),
      ),
      child: Text(
        text,
        style: AppTypography.badge.copyWith(
          color: foreground,
          fontSize: isCompact ? 10 : 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
