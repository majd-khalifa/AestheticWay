import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/login_screen.dart';
import '../../models/referral_model.dart';
import '../../services/referral_service.dart';

/// Luxury Patient Referral & Rewards Hub connected to Live Backend API
class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  bool _isCollecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthState().isLoggedIn) {
        ReferralService().loadReferralStatus();
      }
    });
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showAppSnackBar(
      context,
      message,
      type: AppSnackBarType.success,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _shareInvite(String code) async {
    final loc = LocaleService();
    final message = loc.isArabic
        ? 'حمّل تطبيق AESTHETIC WAY لاكتشاف وتحديد مواعيد أفضل عيادات وأطباء التجميل في الإمارات!\nاستخدم كود الدعوة الخاص بي: $code'
        : 'Download AESTHETIC WAY app to discover and request leads with certified medical aesthetic clinics in the UAE!\nUse my referral code: $code';

    // Copy to clipboard first
    Clipboard.setData(ClipboardData(text: message));
    if (mounted) {
      showAppSnackBar(
        context,
        loc.isArabic ? 'تم نسخ نص الدعوة ورابط الكود للمشاركة' : 'Invite text and code copied to clipboard',
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

  Future<void> _handleCollectCode() async {
    final loc = LocaleService();
    final referralService = ReferralService();

    if (!referralService.canCollectDiscountCode || _isCollecting) return;

    setState(() => _isCollecting = true);

    try {
      final code = await referralService.collectDiscountCode();
      if (!mounted) return;

      _showSuccessCodeModal(code);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        loc.isArabic
            ? 'تعذر استبدال النقاط حالياً: ${e.toString()}'
            : 'Could not redeem points: ${e.toString()}',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isCollecting = false);
      }
    }
  }

  void _showSuccessCodeModal(ReferralDiscountCode code) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppColors.accentChampagne.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.15 : 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accentChampagne.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.accentChampagne,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                loc.isArabic ? 'تم استبدال 500 نقطة بنجاح!' : '500 Points Successfully Redeemed!',
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                loc.isArabic
                    ? 'كود الخصم الحصري الخاص بك (15%) للاستخدام في العيادة'
                    : 'Your exclusive 15% discount code for clinic use',
                style: AppTypography.caption.copyWith(
                  color: AppColors.mutedText(context),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Code Display Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accentChampagne,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      code.code,
                      style: AppTypography.heroTitle.copyWith(
                        color: AppColors.accentChampagne,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc.isArabic
                          ? 'خصم 15% على الإجراءات خارج العروض'
                          : '15% off original non-offer procedures',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.silverMuted : AppColors.lightTextMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                loc.isArabic
                    ? 'الخصم يُطبَّق في العيادة مباشرة على الإجراءات خارج باقات العروض (ليس سعر العرض المخفّض).'
                    : 'The discount applies in-clinic on non-offer procedures (not on already discounted offer prices).',
                style: AppTypography.caption.copyWith(
                  color: AppColors.mutedText(context),
                  fontSize: 11.5,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(modalContext),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text(loc.isArabic ? 'إغلاق' : 'Close'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                        side: BorderSide(color: AppColors.border(context)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SilverButton(
                      label: loc.tr('copy_code'),
                      icon: Icons.copy_rounded,
                      variant: SilverButtonVariant.primary,
                      onPressed: () {
                        Navigator.pop(modalContext);
                        _copyToClipboard(code.code, loc.tr('code_copied'));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);
    final referralService = ReferralService();
    final isLoggedIn = AuthState().isLoggedIn;

    return ListenableBuilder(
      listenable: Listenable.merge([loc, referralService, AuthState()]),
      builder: (context, _) {
        final currentPoints = referralService.currentPoints;
        final invitesCount = referralService.successfulInvites;
        final progressRatio = referralService.nextMilestoneProgressRatio;
        final userCodes = referralService.userCodes;
        final referralCode = referralService.userReferralCode;

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
              : referralService.errorMessage != null && referralService.statusModel == null && isLoggedIn
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
                        if (isLoggedIn) {
                          await referralService.loadReferralStatus(refresh: true);
                        }
                      },
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                        children: [
                          // Guest Notice Banner (If not logged in)
                          if (!isLoggedIn) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.12 : 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.accentChampagne.withValues(alpha: 0.4),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.account_circle_outlined, color: AppColors.accentChampagne, size: 28),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          loc.isArabic ? 'سجّل دخولك لبدء جمع النقاط' : 'Sign in to start earning points',
                                          style: AppTypography.cardTitle.copyWith(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          loc.isArabic
                                              ? 'احصل على كود دعوة خاص بك وتابع دعواتك الناجحة للحصول على خصم 15%'
                                              : 'Get your personal invite code and track successful invites for 15% off',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.mutedText(context),
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        LuxuryPageRoute(page: const LoginScreen()),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentChampagne,
                                      foregroundColor: AppColors.backgroundDeep,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      textStyle: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    child: Text(loc.isArabic ? 'دخول' : 'Login'),
                                  ),
                                ],
                              ),
                            ),
                          ],

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
                                  child: Column(
                                    children: [
                                      Row(
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
                                                referralCode,
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
                                              referralCode,
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
                                      const SizedBox(height: 10),
                                      const Divider(height: 1, thickness: 0.8),
                                      const SizedBox(height: 10),

                                      // Share Invite Action
                                      InkWell(
                                        onTap: () => _shareInvite(referralCode),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.share_rounded, size: 16, color: AppColors.accentChampagne),
                                              const SizedBox(width: 8),
                                              Text(
                                                loc.tr('share_invite'),
                                                style: AppTypography.caption.copyWith(
                                                  color: AppColors.accentChampagne,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ],
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
                                                  color: AppColors.accentChampagne,
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
                                        color: AppColors.accentChampagne,
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
                                const SizedBox(height: 18),

                                // Collect Button (Active ONLY at >= 500 points)
                                SilverButton(
                                  label: _isCollecting
                                      ? (loc.isArabic ? 'جاري التوليد...' : 'Generating Code...')
                                      : loc.tr('collect_discount_btn'),
                                  icon: Icons.redeem_rounded,
                                  isFullWidth: true,
                                  variant: referralService.canCollectDiscountCode && !_isCollecting
                                      ? SilverButtonVariant.primary
                                      : SilverButtonVariant.secondary,
                                  onPressed: referralService.canCollectDiscountCode && !_isCollecting
                                      ? _handleCollectCode
                                      : null,
                                ),

                                if (!referralService.canCollectDiscountCode) ...[
                                  const SizedBox(height: 8),
                                  Center(
                                    child: Text(
                                      loc.isArabic
                                          ? 'اجمع 500 نقطة على الأقل عبر دعوة أصدقائك لتفعيل زر الاستبدال (النقاط الحالية: $currentPoints / 500)'
                                          : 'Accumulate at least 500 points to unlock (You have: $currentPoints / 500)',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.mutedText(context),
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
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
                                    final isUsed = c.status == ReferralCodeStatus.used;
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
                                                      : isUsed
                                                          ? AppColors.border(context)
                                                          : Colors.amber.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isAvailable
                                                      ? loc.tr('code_status_available')
                                                      : isUsed
                                                          ? loc.tr('code_status_used')
                                                          : loc.tr('code_status_expired'),
                                                  style: AppTypography.caption.copyWith(
                                                    color: isAvailable
                                                        ? const Color(0xFF10B981)
                                                        : isUsed
                                                            ? AppColors.mutedText(context)
                                                            : Colors.amber,
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
                                                  loc.isArabic
                                                      ? 'خصم 15% على الإجراءات خارج العروض'
                                                      : '15% off non-offer procedures',
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
                    ),
        );
      },
    );
  }
}
