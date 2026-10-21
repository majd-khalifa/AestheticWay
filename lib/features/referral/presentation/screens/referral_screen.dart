import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/auth/guest_auth_guard.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/widgets/luxury_error_view.dart';
import '../../services/referral_service.dart';

/// Personal invitation link and server-ledger progress. No redemption workflow.
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
      if (mounted && AuthState().isLoggedIn) {
        ReferralService().loadReferralStatus();
      }
    });
  }

  Future<void> _copy(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    showAppSnackBar(
      context,
      LocaleService().isArabic ? 'تم نسخ رابط الدعوة' : 'Invite link copied',
    );
  }

  Future<void> _share(String link) async {
    final message = LocaleService().isArabic
        ? 'اكتشف عيادات التجميل والجلدية مع AESTHETIC WAY\n$link'
        : 'Discover medical aesthetics with AESTHETIC WAY\n$link';
    try {
      final opened = await launchUrl(
        Uri.https('wa.me', '/', {'text': message}),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) await _copy(link);
    } catch (_) {
      await _copy(link);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService(), service = ReferralService();
    return ListenableBuilder(
      listenable: Listenable.merge([loc, service]),
      builder: (context, _) {
        final available = service.statusModel != null;
        final link = service.inviteLink;
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(title: Text(loc.tr('referral_title'))),
          body: service.isLoading && !available
              ? const Center(child: CircularProgressIndicator())
              : service.errorMessage != null && !available
              ? LuxuryErrorView(
                  onRetry: () => service.loadReferralStatus(refresh: true),
                )
              : RefreshIndicator(
                  onRefresh: () => service.loadReferralStatus(refresh: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        loc.isArabic
                            ? 'شارك الاكتشاف'
                            : 'Discovery is better shared',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.tr('referral_sub'),
                        style: TextStyle(
                          color: AppColors.subtext(context),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      LuxuryCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              loc.isArabic
                                  ? 'رابط الدعوة الشخصي'
                                  : 'Your personal invitation link',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (link.isNotEmpty)
                              SelectableText(
                                link,
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  color: AppColors.goldText(context),
                                  height: 1.5,
                                ),
                              )
                            else
                              Text(
                                loc.isArabic
                                    ? 'رابط الدعوة غير متوفر حالياً'
                                    : 'Your invitation link is currently unavailable',
                              ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: link.isEmpty
                                      ? null
                                      : () => _copy(link),
                                  icon: const Icon(Icons.copy_outlined),
                                  label: Text(
                                    loc.isArabic ? 'نسخ الرابط' : 'Copy link',
                                  ),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: link.isEmpty
                                      ? null
                                      : () => _share(link),
                                  icon: const Icon(Icons.share_outlined),
                                  label: Text(
                                    loc.isArabic
                                        ? 'مشاركة عبر واتساب'
                                        : 'Share via WhatsApp',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      LuxuryCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              loc.isArabic
                                  ? 'تقدم شبكة الدعوات'
                                  : 'Your invitation progress',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 24,
                              runSpacing: 16,
                              children: [
                                _Metric(
                                  label: loc.isArabic
                                      ? 'النقاط الحالية'
                                      : 'Current points',
                                  value: available
                                      ? '${service.currentPoints}'
                                      : '—',
                                ),
                                _Metric(
                                  label: loc.isArabic
                                      ? 'الدعوات الناجحة'
                                      : 'Successful invitations',
                                  value: available
                                      ? '${service.successfulInvites}'
                                      : '—',
                                ),
                              ],
                            ),
                            if (available) ...[
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: service.nextMilestoneProgressRatio,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                service.getMilestoneDynamicMessage(
                                  isArabic: loc.isArabic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        loc.tr('referral_milestones_title'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      for (final milestone in ReferralService.milestones)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            available &&
                                    service.isMilestoneAwarded(
                                      milestone.requiredInvites,
                                    )
                                ? Icons.check_circle_outline
                                : Icons.people_outline,
                          ),
                          title: Text(
                            loc.isArabic
                                ? milestone.titleAr
                                : milestone.titleEn,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        loc.isArabic
                            ? 'شارك رابطك. تُحتسب الدعوات المؤهلة والنقاط على الخادم، وتظهر هنا بعد تأكيدها.'
                            : 'Share your link. Eligible invitations and points appear here after the server confirms them.',
                        style: TextStyle(
                          color: AppColors.subtext(context),
                          height: 1.5,
                        ),
                      ),
                      if (service.errorMessage != null)
                        TextButton.icon(
                          onPressed: () =>
                              service.loadReferralStatus(refresh: true),
                          icon: const Icon(Icons.sync),
                          label: Text(
                            loc.isArabic
                                ? 'تعذر التحديث، حاول مجدداً'
                                : 'Could not refresh. Try again',
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

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 4),
      Text(label),
    ],
  );
}
