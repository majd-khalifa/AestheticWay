import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import '../../services/referral_service.dart';

/// Luxury Patient Referral & Rewards Hub connected to Live Backend API
class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthState().isLoggedIn) {
        ReferralService().loadReferralStatus();
      }
    });
  }

  void _copyInviteLink(String inviteUrl) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: inviteUrl));
    if (!mounted) return;
    final loc = LocaleService();
    showAppSnackBar(
      context,
      loc.isArabic ? 'تم نسخ رابط الدعوة الخاص بك بنجاح' : 'Your invite link has been copied to clipboard',
      type: AppSnackBarType.success,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _shareInvite(String inviteUrlOrCode) async {
    HapticFeedback.mediumImpact();
    final loc = LocaleService();
    final inviteUrl = inviteUrlOrCode.startsWith('http')
        ? inviteUrlOrCode
        : 'https://aestheticway.ae/invite/$inviteUrlOrCode';
    final message = loc.isArabic
        ? 'انضم إلى تطبيق AESTHETIC WAY — المنصة الفاخرة لاكتشاف أفضل عيادات وأطباء التجميل المعتمدين في الإمارات! 🌟\n\nسجل عبر رابط دعوتي الحصري:\n$inviteUrl'
        : 'Join me on AESTHETIC WAY — the premier luxury platform to discover certified aesthetic & dermatology clinics in the UAE! 🌟\n\nRegister using my exclusive invite link:\n$inviteUrl';

    // Copy to clipboard first
    Clipboard.setData(ClipboardData(text: message));
    if (mounted) {
      showAppSnackBar(
        context,
        loc.isArabic ? 'تم نسخ نص ورابط الدعوة للمشاركة' : 'Invite link and message copied to clipboard',
        type: AppSnackBarType.success,
        duration: const Duration(seconds: 2),
      );
    }

    // Also attempt WhatsApp share
    final whatsappUrl = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Widget _buildHowItWorksStep({
    required IconData icon,
    required String title,
    required String desc,
    required BuildContext context,
  }) {
    final isDark = AppColors.isDark(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.15 : 0.22),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accentChampagne.withValues(alpha: 0.6),
              width: 1.0,
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.accentChampagne,
            size: 15,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTypography.caption.copyWith(
                  color: AppColors.mutedText(context),
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);
    final referralService = ReferralService();

    return ListenableBuilder(
      listenable: Listenable.merge([loc, referralService, AuthState()]),
      builder: (context, _) {
        final currentPoints = referralService.currentPoints;
        final invitesCount = referralService.successfulInvites;
        final progressRatio = referralService.nextMilestoneProgressRatio;
        final inviteUrl = referralService.inviteLink;

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
          body: referralService.isLoading && referralService.statusModel == null
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentChampagne,
                    strokeWidth: 2.5,
                  ),
                )
              : referralService.errorMessage != null && referralService.statusModel == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.amber, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              loc.isArabic ? 'تعذر جلب بيانات برنامج المكافآت' : 'Failed to load referral data',
                              style: AppTypography.cardTitle.copyWith(
                                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              referralService.errorMessage!,
                              style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => referralService.loadReferralStatus(refresh: true),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text(loc.isArabic ? 'إعادة المحاولة' : 'Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentChampagne,
                                foregroundColor: AppColors.backgroundDeep,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.accentChampagne,
                      backgroundColor: isDark ? AppColors.cardSurface : Colors.white,
                      onRefresh: () async {
                        await referralService.loadReferralStatus(refresh: true);
                      },
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                        children: [

                          // Unified Referral & Invite Link Hero Card
                          LuxuryCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.15 : 0.20),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.accentChampagne.withValues(alpha: 0.5),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.share_rounded,
                                        color: AppColors.accentChampagne,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            loc.tr('referral_title'),
                                            style: AppTypography.cardTitle.copyWith(
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            loc.tr('referral_sub'),
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.mutedText(context),
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Unified Link Box
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.accentChampagne.withValues(alpha: 0.45),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.link_rounded,
                                        color: AppColors.accentChampagne,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          inviteUrl,
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.goldText(context),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            letterSpacing: 0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () => _copyInviteLink(inviteUrl),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentChampagne.withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.copy_rounded, size: 13, color: AppColors.accentChampagne),
                                              const SizedBox(width: 4),
                                              Text(
                                                loc.isArabic ? 'نسخ الرابط' : 'Copy Link',
                                                style: AppTypography.caption.copyWith(
                                                  color: AppColors.goldText(context),
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Share via WhatsApp (Full Width)
                                SilverButton(
                                  label: loc.isArabic ? 'مشاركة رابط الدعوة عبر واتساب' : 'Share Invite Link via WhatsApp',
                                  icon: Icons.send_rounded,
                                  isFullWidth: true,
                                  variant: SilverButtonVariant.primary,
                                  onPressed: () => _shareInvite(inviteUrl),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // How It Works Card
                          LuxuryCard(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.isArabic ? 'كيف يعمل برنامج الدعوة؟' : 'How It Works',
                                  style: AppTypography.cardTitle.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _buildHowItWorksStep(
                                  icon: Icons.send_rounded,
                                  title: loc.isArabic ? 'شارك رابط الدعوة' : 'Share Your Link',
                                  desc: loc.isArabic
                                      ? 'أرسل رابطك الشخصي لأصدقائك عبر واتساب أو شبكات التواصل'
                                      : 'Send your personalized invite link via WhatsApp or socials',
                                  context: context,
                                ),
                                const SizedBox(height: 10),
                                _buildHowItWorksStep(
                                  icon: Icons.person_add_alt_1_rounded,
                                  title: loc.isArabic ? 'انضمام الصديق وطلب الموعد' : 'Friend Signs Up & Inquires',
                                  desc: loc.isArabic
                                      ? 'يسجل صديقك حسابه ويطلب موعد استشارته الأولى مع العيادة'
                                      : 'Your friend registers and submits their first clinic consultation lead',
                                  context: context,
                                ),
                                const SizedBox(height: 10),
                                _buildHowItWorksStep(
                                  icon: Icons.card_giftcard_rounded,
                                  title: loc.isArabic ? 'مكافآت ونقاط فورية' : 'Earn Exclusive Rewards',
                                  desc: loc.isArabic
                                      ? 'تكسب رصيد نقاط يُستبدل بخصومات حصرية 15% في أرقى العيادات'
                                      : 'Earn reward points redeemable for exclusive 15% vouchers at premier clinics',
                                  context: context,
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
                                  children: [
                                    // 1) Successful Invites
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            loc.tr('invites_count'),
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.mutedText(context),
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$invitesCount',
                                            style: AppTypography.screenTitle.copyWith(
                                              fontSize: 19,
                                              fontWeight: FontWeight.w900,
                                              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 34,
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      color: AppColors.border(context),
                                    ),
                                    // 2) Current Points
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            loc.tr('current_points'),
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.mutedText(context),
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.baseline,
                                            textBaseline: TextBaseline.alphabetic,
                                            children: [
                                              Text(
                                                '$currentPoints',
                                                style: AppTypography.screenTitle.copyWith(
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w900,
                                                  color: AppColors.goldText(context),
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                loc.tr('pts_suffix'),
                                                style: AppTypography.caption.copyWith(
                                                  color: AppColors.mutedText(context),
                                                  fontSize: 10.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 34,
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      color: AppColors.border(context),
                                    ),
                                    // 3) Next Milestone
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            loc.tr('next_milestone'),
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.mutedText(context),
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.baseline,
                                            textBaseline: TextBaseline.alphabetic,
                                            children: [
                                              Text(
                                                referralService.hasCompletedAllMilestones
                                                    ? '50'
                                                    : '${referralService.nextMilestoneThreshold}',
                                                style: AppTypography.screenTitle.copyWith(
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w900,
                                                  color: referralService.hasCompletedAllMilestones
                                                      ? const Color(0xFF10B981)
                                                      : (isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary),
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                referralService.hasCompletedAllMilestones
                                                    ? (loc.isArabic ? '✓ مكتمل' : '✓ Done')
                                                    : loc.tr('invites_suffix'),
                                                style: AppTypography.caption.copyWith(
                                                  color: referralService.hasCompletedAllMilestones
                                                      ? const Color(0xFF10B981)
                                                      : AppColors.mutedText(context),
                                                  fontSize: 10.5,
                                                  fontWeight: referralService.hasCompletedAllMilestones
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Dynamic Explanatory Status Banner
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.08 : 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.accentChampagne.withValues(alpha: 0.35),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        referralService.hasCompletedAllMilestones
                                            ? Icons.check_circle_outline_rounded
                                            : Icons.auto_awesome_outlined,
                                        size: 16,
                                        color: AppColors.accentChampagne,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          referralService.getMilestoneDynamicMessage(isArabic: loc.isArabic),
                                          style: AppTypography.caption.copyWith(
                                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11.5,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Progress Bar toward next milestone (count / nextMilestone)
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        loc.isArabic
                                            ? (referralService.hasCompletedAllMilestones
                                                ? 'أكملت جميع العتبات ($invitesCount / 50 دعوة)'
                                                : 'التقدم نحو العتبة التالية ($invitesCount / ${referralService.nextMilestoneThreshold} دعوة)')
                                            : (referralService.hasCompletedAllMilestones
                                                ? 'All milestones reached ($invitesCount / 50 invites)'
                                                : 'Progress to next milestone ($invitesCount / ${referralService.nextMilestoneThreshold} invites)'),
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.mutedText(context),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(progressRatio * 100).toInt()}%',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.goldText(context),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
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

                                // Milestones List (20, 35, 50)
                                ...ReferralService.milestones.map((m) {
                                  final isReached = referralService.isMilestoneAwarded(m.requiredInvites);
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
                    ),
        );
      },
    );
  }
}
