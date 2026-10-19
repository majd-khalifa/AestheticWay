import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/login_screen.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';

/// Screen 6: Luxury Reset Password Screen
class ResetPasswordScreen extends StatefulWidget {
  final String? phone;
  final String? otpCode;

  const ResetPasswordScreen({
    super.key,
    this.phone,
    this.otpCode,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  Map<String, String> _serverFieldErrors = {};
  String? _serverErrorMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSaveNewPassword() async {
    final loc = LocaleService();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _serverErrorMessage = null;
      _serverFieldErrors = {};
    });

    final phone = widget.phone ?? '';
    final otpCode = widget.otpCode;

    if (phone.isEmpty) {
      setState(() {
        _isLoading = false;
        _serverErrorMessage = loc.isArabic
            ? 'بيانات التحقق غير مكتملة، يرجى العودة لطلب رمز جديد'
            : 'Verification data missing. Please request a new OTP code.';
      });
      showAppSnackBar(
        context,
        _serverErrorMessage!,
        type: AppSnackBarType.error,
      );
      return;
    }

    try {
      await AuthRepository().resetPassword(
        phone: phone,
        otpCode: otpCode,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      showAppSnackBar(
        context,
        loc.tr('password_reset_success'),
        type: AppSnackBarType.success,
        duration: const Duration(seconds: 3),
      );

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
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
        _serverErrorMessage = e.message;
        if (e.fieldErrors != null) {
          _serverFieldErrors = e.fieldErrors!.map(
            (k, v) => MapEntry(k, v.isNotEmpty ? v.first : ''),
          );
        }
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
        _serverErrorMessage = e.toString();
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
              loc.tr('reset_title'),
              style: AppTypography.screenTitle.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Lock Key Icon
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
                            Icons.key_rounded,
                            size: 36,
                            color: AppColors.accentChampagne,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header Info
                    Center(
                      child: Text(
                        loc.tr('reset_sub'),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.mutedText(context),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Server Error Banner
                    if (_serverErrorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _serverErrorMessage!,
                                style: const TextStyle(
                                  color: AppColors.errorRed,
                                  fontSize: 12.5,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Navigation helper if OTP is expired or invalid
                      if (_serverErrorMessage!.contains('رمز') ||
                          _serverErrorMessage!.contains('تحقق') ||
                          _serverErrorMessage!.contains('OTP') ||
                          _serverErrorMessage!.contains('otp'))
                        Align(
                          alignment: loc.isArabic ? Alignment.centerRight : Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, size: 15, color: AppColors.accentChampagne),
                            label: Text(
                              loc.isArabic ? 'العودة لتعديل أو إعادة إرسال رمز التحقق' : 'Return to edit or resend verification code',
                              style: TextStyle(
                                color: AppColors.goldText(context),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                    ],

                    // Input Card
                    LuxuryCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // 1. New Password
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: _obscureNewPassword,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: loc.tr('new_password_label'),
                              hintText: loc.tr('password_hint'),
                              labelStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12.5),
                              prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.mutedText(context), size: 19),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppColors.mutedText(context),
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureNewPassword = !_obscureNewPassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border(context), width: 0.8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.silverPrimary : AppColors.primarySoftNavy,
                                  width: 1.4,
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().length < 8) {
                                return loc.tr('val_password_short');
                              }
                              if (_serverFieldErrors.containsKey('new_password')) {
                                return _serverFieldErrors['new_password'];
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // 2. Confirm New Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: loc.tr('confirm_new_password_label'),
                              hintText: loc.tr('password_hint'),
                              labelStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12.5),
                              prefixIcon: Icon(Icons.lock_reset_rounded, color: AppColors.mutedText(context), size: 19),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppColors.mutedText(context),
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border(context), width: 0.8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.silverPrimary : AppColors.primarySoftNavy,
                                  width: 1.4,
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (val != _newPasswordController.text) {
                                return loc.tr('val_password_mismatch');
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Password Button
                    SilverButton(
                      label: loc.tr('save_password_btn'),
                      icon: Icons.check_circle_outline,
                      isFullWidth: true,
                      height: 48,
                      isLoading: _isLoading,
                      onPressed: _onSaveNewPassword,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
