import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/auth/guest_auth_guard.dart';
import '../../../../core/auth/session_snapshot.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/auth_repository.dart';
import 'login_screen.dart';

/// Purpose-bound OTP confirmation. No support email or optimistic deletion.
class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({super.key, this.repository});
  final AuthRepository? repository;
  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  final _session = SessionSnapshot();
  final _code = TextEditingController();
  late final _repository = widget.repository ?? AuthRepository();
  Timer? _timer;
  DateTime? _resendAt, _expiresAt;
  bool _busy = false, _requested = false, _consent = false;
  String? _error;
  bool _soleClinicAdmin = false;
  String _text(String en, String ar) => LocaleService().isArabic ? ar : en;
  bool get _allowed => _session.isCurrent && AuthState().isLoggedIn;
  int get _remaining =>
      (_resendAt?.difference(DateTime.now()).inSeconds ?? 0).clamp(0, 3600);
  bool get _expired =>
      _expiresAt != null && !DateTime.now().isBefore(_expiresAt!);
  @override
  void initState() {
    super.initState();
    AuthState().addListener(_changed);
  }

  void _changed() {
    if (!_allowed) {
      _timer?.cancel();
      _code.clear();
      _consent = false;
      _requested = false;
      _expiresAt = null;
      _resendAt = null;
      _soleClinicAdmin = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AuthState().removeListener(_changed);
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    if (_busy || !_allowed || _remaining > 0) return;
    setState(() {
      _busy = true;
      _error = null;
      _soleClinicAdmin = false;
    });
    try {
      final result = await _repository.requestAccountDeletion();
      if (!mounted || !_allowed) return;
      final cooldown = int.tryParse('${result['resend_cooldown']}') ?? 60;
      final expiry = int.tryParse('${result['expires_in']}') ?? 600;
      setState(() {
        _requested = true;
        _consent = false;
        _resendAt = DateTime.now().add(
          Duration(seconds: cooldown.clamp(0, 3600)),
        );
        _expiresAt = DateTime.now().add(
          Duration(seconds: expiry.clamp(0, 3600)),
        );
        _code.clear();
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } catch (e) {
      if (mounted && _allowed) {
        _soleClinicAdmin =
            e is ApiException && e.errorCode == 'SOLE_CLINIC_ADMIN';
        if (e is ApiException && e.retryAfter != null) {
          _resendAt = DateTime.now().add(e.retryAfter!);
          _timer?.cancel();
          _timer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (mounted) setState(() {});
          });
        }
        setState(
          () => _error = e is ApiException
              ? e.message
              : _text(
                  'Unable to send a code. Your account has not been deleted.',
                  'تعذر إرسال الرمز. لم يُحذف حسابك.',
                ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    if (_busy ||
        !_allowed ||
        !_requested ||
        !_consent ||
        _expired ||
        !RegExp(r'^\d{6}$').hasMatch(_code.text)) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repository.confirmAccountDeletion(_code.text);
      // A different account may have signed in while secure storage completed.
      if (mounted && !AuthState().isLoggedIn) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted && _allowed) {
        setState(
          () => _error = e is ApiException
              ? e.message
              : _text(
                  'Deletion was not confirmed. Your inputs are preserved; check the connection before retrying.',
                  'لم يتم تأكيد الحذف. تم الاحتفاظ بالمدخلات؛ تحقّق من الاتصال قبل إعادة المحاولة.',
                ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: Text(_text('Delete account', 'حذف الحساب'))),
      body: !_allowed
          ? Center(
              child: _busy
                  ? Semantics(
                      label: _text(
                        'Finishing securely…',
                        'جارٍ الإنهاء بأمان…',
                      ),
                      child: const CircularProgressIndicator(),
                    )
                  : Text(
                      _text(
                        'Your session changed. Please sign in again.',
                        'تغيّرت جلستك. يرجى تسجيل الدخول مجدداً.',
                      ),
                    ),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  _text('Account deletion is permanent', 'حذف الحساب نهائي'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  _text(
                    'This disables your account and removes or anonymizes supported identity and contact data. Shared clinic records remain. Some historical records may be retained; see the Privacy Policy for retention details. You will be signed out after the server confirms deletion.',
                    'سيتم تعطيل الحساب وإزالة بيانات الهوية والتواصل المدعومة أو إخفاء هويتها. تبقى سجلات العيادة المشتركة. قد تُحتفظ ببعض السجلات السابقة؛ راجع سياسة الخصوصية لتفاصيل الاحتفاظ. سيتم تسجيل خروجك بعد تأكيد الخادم للحذف.',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _text(
                    'We will send a verification code to your registered communication channel. Keep the code private. Administrators may need to appoint another administrator first.',
                    'سنرسل رمز تحقق إلى وسيلة التواصل المسجلة. حافظ على سرية الرمز. قد يحتاج المشرفون إلى تعيين مشرف آخر أولاً.',
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  key: const ValueKey('deletion-request-code'),
                  onPressed: _busy || _remaining > 0 ? null : _request,
                  child: Text(
                    _remaining > 0
                        ? _text(
                            'Resend in $_remaining s',
                            'إعادة الإرسال بعد $_remaining ث',
                          )
                        : _requested
                        ? _text('Send a new code', 'إرسال رمز جديد')
                        : _text('Send verification code', 'إرسال رمز التحقق'),
                  ),
                ),
                if (_requested) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _expired
                          ? _text(
                              'The code has expired. Request a new code.',
                              'انتهت صلاحية الرمز. اطلب رمزاً جديداً.',
                            )
                          : _text(
                              'The server accepted the code request but did not identify its delivery channel or masked destination. Check your registered messages. Enter a received six-digit code; delivery is not verified here.',
                              'قبل الخادم طلب الرمز لكنه لم يحدد قناة الإرسال أو وجهة مخفية. تحقق من رسائلك المسجلة وأدخل الرمز المستلم المكون من ستة أرقام؛ لم يتم التحقق من وصوله هنا.',
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('deletion-code'),
                    controller: _code,
                    enabled: !_busy,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    decoration: InputDecoration(
                      labelText: _text('Verification code', 'رمز التحقق'),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  CheckboxListTile(
                    key: const ValueKey('deletion-consent'),
                    contentPadding: EdgeInsets.zero,
                    value: _consent,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _consent = v ?? false),
                    title: Text(
                      _text(
                        'I understand and want to permanently delete my account.',
                        'أفهم العواقب وأرغب بحذف حسابي نهائياً.',
                      ),
                    ),
                  ),
                  FilledButton(
                    key: const ValueKey('deletion-confirm'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed:
                        _busy ||
                            !_consent ||
                            _expired ||
                            !RegExp(r'^\d{6}$').hasMatch(_code.text)
                        ? null
                        : _confirm,
                    child: Text(
                      _text('Permanently delete account', 'حذف الحساب نهائياً'),
                    ),
                  ),
                ],
                if (_busy)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(_text('Please wait…', 'يرجى الانتظار…')),
                      ],
                    ),
                  ),
                if (_soleClinicAdmin) ...[
                  Text(
                    _text(
                      'This account is the only active clinic administrator. Ask platform management to arrange an authorized replacement administrator or reviewed clinic closure, then request deletion again. No code was requested.',
                      'هذا الحساب هو المشرف النشط الوحيد للعيادة. اطلب من إدارة المنصة تعيين مشرف بديل مخوّل أو مراجعة إغلاق العيادة ثم اطلب الحذف مجدداً. لم يُطلب رمز.',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: Text(
                      _text('Return to your portal', 'العودة إلى بوابتك'),
                    ),
                  ),
                ],
                if (_error != null)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    ),
  );
}
