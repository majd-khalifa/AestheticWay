import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import '../../models/referral_model.dart';
import '../../services/referral_service.dart';

/// Luxury Patient Referral & Rewards Hub
class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surface(context),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);
    final referralService = ReferralService();

    return ListenableBuilder(
      listenable: Listenable.merge([loc, referralService]),
      builder: (context, _) {
        final currentPoints = referralService.currentPoints;
        final invitesCount = referralService.successfulInvites;
        final progressRatio = (currentPoints / 500.0).clamp(0.0, 1.0);
        final userCodes = referralService.userCodes;

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Text(
              loc.tr('referral_title'),
              style: AppTypography.screenTitle.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                fontSize: 16,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              // Referral Hero Card
              LuxuryCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.15 : 0.20),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accentChampagne.withValues(alpha: 0.5),
                              width: 1.0,
                            ),
                          ),
                          child: const Icon(
                            Icons.card_giftcard_rounded,
                            color: AppColors.accentChampagne,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            loc.tr('referral_title'),
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loc.tr('referral_sub'),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.mutedText(context),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // User Referral Code Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.accentChampagne.withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.tr('your_referral_code'),
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.mutedText(context),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                referralService.userReferralCode,
                                style: AppTypography.heroTitle.copyWith(
                                  color: AppColors.accentChampagne,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _copyToClipboard(
                              context,
                              referralService.userReferralCode,
                              loc.tr('code_copied'),
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 15, color: AppColors.accentChampagne),
                            label: Text(
                              loc.tr('copy_code'),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.accentChampagne,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.accentChampagne.withValues(alpha: 0.12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Points & Milestones Progress Card
              LuxuryCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.tr('invites_count'),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.mutedText(context),
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$invitesCount',
                              style: AppTypography.screenTitle.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: AppColors.border(context),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.tr('current_points'),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.mutedText(context),
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '$currentPoints',
                                  style: AppTypography.screenTitle.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.accentChampagne,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '/ 500',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.mutedText(context),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progressRatio,
                        minHeight: 8,
                        backgroundColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentChampagne),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      loc.tr('referral_milestones_title'),
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Milestones List
                    ...ReferralService.milestones.map((m) {
                      final isReached = invitesCount >= m.requiredInvites;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Icon(
                              isReached ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              size: 16,
                              color: isReached ? AppColors.accentChampagne : AppColors.mutedText(context),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                loc.isArabic ? m.titleAr : m.titleEn,
                                style: AppTypography.caption.copyWith(
                                  color: isReached
                                      ? (isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary)
                                      : AppColors.mutedText(context),
                                  fontWeight: isReached ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Collect Button & Demo Accelerator
                    SilverButton(
                      label: loc.tr('collect_discount_btn'),
                      icon: Icons.redeem_rounded,
                      isFullWidth: true,
                      variant: referralService.canCollectDiscountCode
                          ? SilverButtonVariant.primary
                          : SilverButtonVariant.secondary,
                      onPressed: referralService.canCollectDiscountCode
                          ? () {
                              final newCode = referralService.collectDiscountCode();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${loc.tr('code_generated_success')}\n${newCode.code}'),
                                  backgroundColor: AppColors.surface(context),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          : () {
                              // If not yet 500, offer demo fast-track
                              referralService.addDemoPoints(500);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(loc.isArabic
                                      ? 'تمت إضافة 500 نقطة تجريبية! اضغط على زر الاستبدال الآن.'
                                      : 'Added 500 demo points! Tap Collect now.'),
                                  backgroundColor: AppColors.surface(context),
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Issued 15% Discount Codes Section
              LuxuryCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.confirmation_number_outlined, color: AppColors.accentChampagne, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          loc.tr('discount_codes_title'),
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (userCodes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          loc.tr('no_discount_codes'),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.mutedText(context),
                            fontSize: 12.5,
                          ),
                        ),
                      )
                    else
                      ...userCodes.map((c) {
                        final isAvailable = c.status == ReferralCodeStatus.available;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isAvailable
                                  ? AppColors.accentChampagne.withValues(alpha: 0.5)
                                  : AppColors.border(context),
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    c.code,
                                    style: AppTypography.cardTitle.copyWith(
                                      color: AppColors.accentChampagne,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15.5,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isAvailable
                                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                          : AppColors.border(context),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isAvailable ? loc.tr('code_status_available') : loc.tr('code_status_used'),
                                      style: AppTypography.caption.copyWith(
                                        color: isAvailable ? const Color(0xFF10B981) : AppColors.mutedText(context),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      loc.isArabic ? 'خصم 15% على الإجراءات خارج العروض' : '15% off non-offer procedures',
                                      style: AppTypography.caption.copyWith(
                                        color: isDark ? AppColors.silverMuted : AppColors.lightTextMuted,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isAvailable)
                                    InkWell(
                                      onTap: () => _copyToClipboard(
                                        context,
                                        c.code,
                                        loc.tr('code_copied'),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.copy_rounded, size: 13, color: AppColors.accentChampagne),
                                          const SizedBox(width: 4),
                                          Text(
                                            loc.tr('copy_code'),
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.accentChampagne,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Legal Terms Note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border(context),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.accentChampagne),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        loc.tr('referral_rule_note'),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.mutedText(context),
                          fontSize: 11.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
