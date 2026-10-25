import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/auth/guest_auth_guard.dart';
import '../../../../core/auth/session_snapshot.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/auth_repository.dart';

/// Verifies only the current account's existing email. This purpose-bound code
/// never authorizes deletion; that flow must request its own fresh challenge.
class VerifyRegisteredEmailScreen extends StatefulWidget {
  const VerifyRegisteredEmailScreen({super.key, this.repository});
  final AuthRepository? repository;
  @override
  State<VerifyRegisteredEmailScreen> createState() =>
      _VerifyRegisteredEmailScreenState();
}

class _VerifyRegisteredEmailScreenState
    extends State<VerifyRegisteredEmailScreen> {
  late final _repository = widget.repository ?? AuthRepository();
  final _session = SessionSnapshot();
  final _code = TextEditingController();
  Timer? _timer;
  DateTime? _resendAt;
  String? _email, _error;
  bool _busy = false, _requested = false;
  bool get _allowed => AuthState().isLoggedIn && _session.isCurrent;
  int get _remaining =>
      (_resendAt?.difference(DateTime.now()).inSeconds ?? 0).clamp(0, 3600);
  String t(String en, String ar) => LocaleService().isArabic ? ar : en;
  @override
  void initState() {
    super.initState();
    AuthState().addListener(_changed);
  }

  void _changed() {
    if (!_allowed) {
      _timer?.cancel();
      _email = null;
      _code.clear();
      _requested = false;
    }
    if (mounted) setState(() {});
  }

  void _countdown(Duration duration) {
    _resendAt = DateTime.now().add(duration);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _act({bool confirm = false}) async {
    if (_busy || !_allowed || (!confirm && _remaining > 0)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (confirm) {
        if (_email == null || _code.text.length != 6) {
          throw ApiException(
            message: t(
              'Enter the six-digit email code.',
              'أدخل رمز البريد المكون من ستة أرقام.',
            ),
          );
        }
        final result = await _repository.confirmEmailChange(
          newEmail: _email!,
          code: _code.text,
        );
        _session.ensureCurrent();
        if (result['success'] != true) {
          throw ApiException(
            message: t(
              'Email verification was not acknowledged.',
              'لم يؤكد الخادم توثيق البريد.',
            ),
          );
        }
        // Never infer durable verification from OTP acknowledgment alone.
        final fresh = await _repository.getMe();
        _session.ensureCurrent();
        if (fresh.email?.trim().toLowerCase() != _email ||
            !fresh.isEmailVerified) {
          throw ApiException(
            message: t(
              'Email verification was not confirmed. Refresh before continuing.',
              'لم يتم تأكيد توثيق البريد. حدّث البيانات قبل المتابعة.',
            ),
          );
        }
        if (mounted) Navigator.pop(context, true);
      } else {
        final current = await _repository.getMe();
        _session.ensureCurrent();
        if (current.isEmailVerified) {
          if (mounted) Navigator.pop(context, true);
          return;
        }
        final email = current.email?.trim().toLowerCase() ?? '';
        if (email.isEmpty) {
          throw ApiException(
            message: t(
              'No registered email is available. Contact platform support.',
              'لا يوجد بريد مسجل. تواصل مع دعم المنصة.',
            ),
          );
        }
        final result = await _repository.requestEmailChange(email);
        _session.ensureCurrent();
        if (result['success'] != true) {
          throw ApiException(
            message: t(
              'Email code request was not acknowledged.',
              'لم يؤكد الخادم طلب رمز البريد.',
            ),
          );
        }
        _email = email;
        _requested = true;
        _code.clear();
        _countdown(
          Duration(
            seconds: (int.tryParse('${result['resend_cooldown']}') ?? 60).clamp(
              0,
              3600,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted && _allowed) {
        if (e is ApiException && e.retryAfter != null) {
          _countdown(e.retryAfter!);
        }
        _error = e is ApiException
            ? e.message
            : t(
                'Verification was not confirmed. Please try again.',
                'لم يتم تأكيد التوثيق. حاول مجدداً.',
              );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    AuthState().removeListener(_changed);
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(t('Verify registered email', 'توثيق البريد المسجل')),
      ),
      body: !_allowed
          ? Center(
              child: Text(
                t(
                  'Your session changed. Sign in again.',
                  'تغيرت جلستك. سجل الدخول مجدداً.',
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  t(
                    'Verify the email already registered to your account. This does not delete your account or replace the separate deletion code.',
                    'وثّق البريد المسجل لحسابك. لا يؤدي ذلك إلى حذف الحساب ولا يستبدل رمز الحذف المنفصل.',
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                OutlinedButton(
                  key: const ValueKey('email-verification-request'),
                  onPressed: _busy || _remaining > 0 ? null : () => _act(),
                  child: Text(
                    _remaining > 0
                        ? t(
                            'Resend in $_remaining s',
                            'إعادة الإرسال بعد $_remaining ث',
                          )
                        : t(
                            'Request email verification code',
                            'طلب رمز توثيق البريد',
                          ),
                  ),
                ),
                if (_requested) ...[
                  Text(
                    t(
                      'Email code request accepted. Delivery is not confirmed; enter only a code you receive.',
                      'قُبل طلب رمز البريد. لم يُؤكد الوصول؛ أدخل الرمز الذي تستلمه فقط.',
                    ),
                  ),
                  TextField(
                    key: const ValueKey('email-verification-code'),
                    controller: _code,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: t(
                        'Email verification code',
                        'رمز توثيق البريد',
                      ),
                    ),
                  ),
                  FilledButton(
                    key: const ValueKey('email-verification-confirm'),
                    onPressed: _busy ? null : () => _act(confirm: true),
                    child: Text(
                      t('Confirm email verification', 'تأكيد توثيق البريد'),
                    ),
                  ),
                ],
                if (_busy)
                  Semantics(
                    label: t('Verifying…', 'جارٍ التحقق…'),
                    liveRegion: true,
                    child: const LinearProgressIndicator(),
                  ),
              ],
            ),
    ),
  );
}
