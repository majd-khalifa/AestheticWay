import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/navigation/main_nav_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_main_nav_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_main_nav_screen.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';

enum OtpPurpose {
  registration,
  login,
  passwordReset;

  String toApiPurpose() {
    switch (this) {
      case OtpPurpose.registration:
        return 'registration';
      case OtpPurpose.login:
        return 'login';
      case OtpPurpose.passwordReset:
        return 'password_reset';
    }
  }
}

/// Screen 4: Luxury Interactive OTP Verification Screen with 6-Digit Auto-Focus Boxes
class OtpScreen extends StatefulWidget {
  final OtpPurpose purpose;
  final String targetContact;
  final String? userName;
  final String? userEmail;

  const OtpScreen({
    super.key,
    required this.purpose,
    required this.targetContact,
    this.userName,
    this.userEmail,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // 6 digits required by Django backend (apps.accounts)
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendSeconds = 60;
  Timer? _timer;
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _resendSeconds = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _verifyOtp() async {
    final loc = LocaleService();
    final code = _otpCode;

    if (code.length < 6) {
      showAppSnackBar(
        context,
        loc.isArabic ? 'يرجى إدخال كود التحقق المكون من 6 أرقام' : 'Please enter the 6-digit verification code',
        type: AppSnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.purpose == OtpPurpose.passwordReset) {
        // Verify OTP with backend to store temporary permission in cache
        await AuthRepository().verifyOtp(
          phone: widget.targetContact,
          otpCode: code,
          purpose: widget.purpose.toApiPurpose(),
        );

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        // Navigate to ResetPasswordScreen only on successful verification
        Navigator.push(
          context,
          LuxuryPageRoute(
            page: ResetPasswordScreen(
              phone: widget.targetContact,
              otpCode: code,
            ),
          ),
        );
        return;
      }

      // 2. Registration & Login Flow:
      final authResponse = await AuthRepository().verifyOtp(
        phone: widget.targetContact,
        otpCode: code,
        purpose: widget.purpose.toApiPurpose(),
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      showAppSnackBar(
        context,
        loc.isArabic ? 'تم التحقق بنجاح' : 'Verification successful',
        type: AppSnackBarType.success,
      );

        // Role-based routing
        final role = authResponse?.user.role ?? 'patient';
        Widget targetScreen;
        if (role == 'super_admin') {
          targetScreen = const AdminMainNavScreen();
        } else if (role == 'clinic_admin' || role == 'clinic_staff') {
          targetScreen = const ClinicMainNavScreen();
        } else {
          targetScreen = const MainNavScreen();
        }

        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
          (route) => false,
        );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showAppSnackBar(
        context,
        e.message,
        type: AppSnackBarType.error,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showAppSnackBar(
        context,
        e.toString(),
        type: AppSnackBarType.error,
      );
    }
  }

  void _onResendOtp() async {
    final loc = LocaleService();
    setState(() {
      _isResending = true;
    });

    try {
      await AuthRepository().resendOtp(
        phone: widget.targetContact,
        purpose: widget.purpose.toApiPurpose(),
      );

      if (!mounted) return;
      setState(() {
        _isResending = false;
      });

      _startCountdown();
      showAppSnackBar(
        context,
        loc.isArabic ? 'تم إرسال كود جديد إلى هاتفك' : 'A new code has been sent',
        type: AppSnackBarType.info,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
      });
      showAppSnackBar(
        context,
        e.message,
        type: AppSnackBarType.error,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
      });
      showAppSnackBar(
        context,
        e.toString(),
        type: AppSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    return ListenableBuilder(
      listenable: loc,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Text(
              loc.tr('otp_title'),
              style: AppTypography.screenTitle.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
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
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Verification Badge Icon
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        border: Border.all(
                          color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.35 : 0.5),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.mark_email_read_outlined,
                          size: 36,
                          color: AppColors.accentChampagne,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Subtitle & Target Phone
                  Center(
                    child: Text(
                      loc.tr('otp_sub'),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.mutedText(context),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      widget.targetContact,
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentChampagne,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 6 Digit Input Boxes Card
                  LuxuryCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                    child: Column(
                      children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(6, (index) {
                              return SizedBox(
                                width: 44,
                                height: 56,
                                child: TextFormField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    filled: true,
                                    fillColor: isDark ? AppColors.backgroundDeep : AppColors.lightBackground,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: AppColors.border(context),
                                        width: 1.0,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: AppColors.accentChampagne,
                                        width: 1.6,
                                      ),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    if (val.isNotEmpty && index < 5) {
                                      _focusNodes[index + 1].requestFocus();
                                    } else if (val.isEmpty && index > 0) {
                                      _focusNodes[index - 1].requestFocus();
                                    }
                                    // Auto-trigger verify when last box is filled
                                    if (val.isNotEmpty && index == 5 && _otpCode.length == 6) {
                                      _verifyOtp();
                                    }
                                  },
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Developer Helper Notice
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.accentChampagne.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.accentChampagne.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.terminal_rounded,
                                size: 16,
                                color: AppColors.accentChampagne,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  loc.isArabic
                                      ? 'تلميح: كود التحقق مطبوع في Terminal السيرفر (SMS_PROVIDER=console)'
                                      : 'Dev Hint: OTP code is printed in the Django server terminal',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.accentChampagne,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Resend Timer Row
                  Center(
                    child: _resendSeconds > 0
                        ? Text(
                            '${loc.tr('resend_in')} ${_resendSeconds}s',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.mutedText(context),
                              fontSize: 12.5,
                            ),
                          )
                        : TextButton.icon(
                            onPressed: _isResending ? null : _onResendOtp,
                            icon: _isResending
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentChampagne),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 16, color: AppColors.accentChampagne),
                            label: Text(
                              loc.tr('resend_code'),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.accentChampagne,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Verify Button
                  SilverButton(
                    label: loc.tr('verify_and_continue'),
                    icon: Icons.check_circle_outline,
                    isFullWidth: true,
                    height: 48,
                    isLoading: _isLoading,
                    onPressed: _verifyOtp,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
