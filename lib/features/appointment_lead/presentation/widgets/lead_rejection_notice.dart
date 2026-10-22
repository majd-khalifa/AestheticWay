import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';

/// One rejection, one explanation. A rejected attempt is never a saved lead.
class LeadRejectionNotice extends StatelessWidget {
  const LeadRejectionNotice({
    super.key,
    required this.error,
    required this.onViewRequests,
  });
  final ApiException error;
  final VoidCallback? onViewRequests;

  @override
  Widget build(BuildContext context) {
    final ar = LocaleService().isArabic;
    final duplicate = error.errorCode == 'DUPLICATE_LEAD';
    final wait = error.retryAfter;
    final seconds =
        !error.isLocalBackpressure && wait != null && wait > Duration.zero
        ? (wait.inMilliseconds / 1000).ceil()
        : null;
    final explanation = duplicate
        ? (ar
              ? 'لم يُرسل هذا الطلب لأن النظام رصده كتكرار محتمل. يمكنك مراجعة طلباتك والمحاولة لاحقاً.'
              : 'This request was not sent because it may repeat a recent inquiry. You can review My Requests and try again later.')
        : (ar
              ? 'لم يُرسل هذا الطلب حالياً. يرجى الانتظار قبل المحاولة مجدداً؛ بياناتك محفوظة في النموذج.'
              : 'This request could not be sent right now. Please wait before trying again; your form is unchanged.');
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle(context),
          border: Border.all(color: AppColors.border(context)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(explanation, style: TextStyle(color: AppColors.text(context))),
            if (seconds != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  ar
                      ? 'يرجى الانتظار $seconds ثانية على الأقل قبل إعادة المحاولة.'
                      : 'Please wait at least $seconds seconds before trying again.',
                  style: TextStyle(
                    color: AppColors.subtext(context),
                    fontSize: 12,
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: onViewRequests,
              icon: const Icon(Icons.assignment_outlined, size: 18),
              label: Text(ar ? 'عرض طلباتي' : 'View My Requests'),
            ),
          ],
        ),
      ),
    );
  }
}
