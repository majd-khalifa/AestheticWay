import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_locale.dart';
import '../network/api_config.dart';
import '../services/support_service.dart';
import 'app_snackbar.dart';

/// Public legal routes verified in Django. This support-assisted request does
/// not pretend that an email composer performs server-side account deletion.
class AccountPrivacyActions extends StatefulWidget {
  const AccountPrivacyActions({super.key, this.includeDeletion = true});
  final bool includeDeletion;

  @override
  State<AccountPrivacyActions> createState() => _AccountPrivacyActionsState();
}

class _AccountPrivacyActionsState extends State<AccountPrivacyActions> {
  String? _opening;
  bool _confirming = false;
  bool get _busy => _opening != null || _confirming;

  Future<void> _open(String action, Uri uri) async {
    if (_busy) return;
    setState(() => _opening = action);
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Native launch errors never contain account data in a user-facing error.
    } finally {
      if (mounted) setState(() => _opening = null);
    }
    if (!mounted || opened) return;
    showAppSnackBar(
      context,
      LocaleService().isArabic
          ? 'تعذّر فتح الرابط. يرجى التحقق من وجود تطبيق مناسب والمحاولة مجدداً.'
          : 'Could not open the link. Check that a suitable app is installed and try again.',
      type: AppSnackBarType.error,
    );
  }

  Future<void> _requestDeletion() async {
    if (_busy) return;
    setState(() => _confirming = true);
    final ar = LocaleService().isArabic;
    bool? confirmed;
    try {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(ar ? 'طلب حذف الحساب' : 'Request account deletion'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ar
                      ? 'أرسل طلباً لحذف حسابك والبيانات المرتبطة به إلى الدعم. فتح البريد لا يرسل الطلب ولا يحذف الحساب. قد يلزم التحقق من الهوية. لا ترسل كلمة المرور أو رموز التحقق.'
                      : 'Email support to request deletion of your account and associated data. Opening email does not send the request or delete your account. Identity verification may be required. Do not send passwords or verification codes.',
                ),
                const SizedBox(height: 12),
                SelectableText(
                  SupportService().info.email,
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(ar ? 'إلغاء' : 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(ar ? 'فتح البريد' : 'Open email'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
    if (!mounted || confirmed != true) return;
    await _open(
      'deletion',
      Uri(
        scheme: 'mailto',
        path: SupportService().info.email,
        queryParameters: {
          'subject': ar
              ? 'طلب حذف الحساب والبيانات'
              : 'Account and data deletion request',
          'body': ar
              ? 'أطلب حذف حسابي في Aesthetic Way وبياناتي المرتبطة به. يرجى توضيح خطوات التحقق الآمن، وأي بيانات يجب الاحتفاظ بها ومدة الاحتفاظ بها.'
              : 'I request deletion of my Aesthetic Way account and associated data. Please explain secure identity verification, any data that must be retained, and the retention period.',
        },
      ),
    );
  }

  Widget _link(String action, String label, VoidCallback onPressed) =>
      Semantics(
        link: true,
        child: TextButton.icon(
          key: ValueKey('account-privacy-$action'),
          onPressed: _busy ? null : onPressed,
          icon: _opening == action
              ? const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.open_in_new, size: 16),
          label: Text(
            _opening == action
                ? (LocaleService().isArabic ? 'جارٍ الفتح…' : 'Opening…')
                : label,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: LocaleService(),
    builder: (context, _) {
      final ar = LocaleService().isArabic;
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          _link(
            'privacy',
            ar ? 'سياسة الخصوصية' : 'Privacy Policy',
            () =>
                _open('privacy', Uri.parse('${ApiConfig.siteOrigin}/privacy/')),
          ),
          _link(
            'terms',
            ar ? 'شروط الاستخدام' : 'Terms of Use',
            () => _open('terms', Uri.parse('${ApiConfig.siteOrigin}/terms/')),
          ),
          if (widget.includeDeletion)
            _link(
              'deletion',
              ar ? 'طلب حذف الحساب' : 'Request account deletion',
              _requestDeletion,
            ),
        ],
      );
    },
  );
}
