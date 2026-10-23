import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_locale.dart';
import '../network/api_config.dart';
import '../auth/guest_auth_guard.dart';
import '../../features/auth/presentation/screens/account_deletion_screen.dart';
import 'app_snackbar.dart';

/// Public legal routes and authenticated purpose-bound account deletion.
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
    try {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const AccountDeletionScreen()),
      );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
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
    listenable: Listenable.merge([LocaleService(), AuthState()]),
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
          if (widget.includeDeletion && AuthState().isLoggedIn)
            _link(
              'deletion',
              ar ? 'حذف الحساب' : 'Delete account',
              _requestDeletion,
            ),
        ],
      );
    },
  );
}
