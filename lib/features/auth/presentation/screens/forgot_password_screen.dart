import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/app_brand_logo.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/widgets/luxury_phone_input_field.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/otp_screen.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';

/// Screen 5: Luxury Forgot Password Screen
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  void _onSendResetCode() async {
    if (_isLoading) return;
    final loc = LocaleService();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final input = _identifierController.text.trim();
    final normalizedPhone = AuthRepository.normalizePhone(input);

    try {
      final response = await AuthRepository().forgotPassword(
        phone: normalizedPhone,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      showAppSnackBar(
        context,
        response['message']?.toString() ??
            (loc.isArabic
                ? 'تم إرسال كود التحقق إلى هاتفك'
                : 'Verification code sent to your phone'),
        type: AppSnackBarType.info,
      );

      Navigator.push(
        context,
        LuxuryPageRoute(
          page: OtpScreen(
            purpose: OtpPurpose.passwordReset,
            targetContact: normalizedPhone,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showAppSnackBar(context, e.message, type: AppSnackBarType.error);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showAppSnackBar(context, e.toString(), type: AppSnackBarType.error);
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
              loc.tr('forgot_title'),
              style: AppTypography.screenTitle.copyWith(
                color: isDark
                    ? AppColors.silverPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark
                    ? AppColors.silverPrimary
                    : AppColors.lightTextPrimary,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
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
                    // Official Brand Logo (Prominent Auth Sizing)
                    const Center(child: AppBrandLogo.auth()),
                    const SizedBox(height: 20),

                    // Header Info
                    Center(
                      child: Text(
                        loc.isArabic
                            ? 'أدخل رقم هاتفك المسجل وسنرسل لك رمز تحقق (OTP) عبر رسالة نصية أو واتساب لإعادة تعيين كلمة المرور.'
                            : 'Enter your registered phone number to receive a verification code (OTP) via SMS or WhatsApp to reset your password.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.mutedText(context),
                          fontSize: 13,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Input Card
                    LuxuryCard(
                      padding: const EdgeInsets.all(16),
                      child: LuxuryPhoneInputField(
                        controller: _identifierController,
                        isRequired: true,
                        labelText: loc.isArabic
                            ? 'رقم الهاتف المسجل'
                            : 'Registered Phone Number',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Send Reset Code Button
                    SilverButton(
                      label: loc.tr('send_reset_code'),
                      icon: Icons.send_rounded,
                      isFullWidth: true,
                      height: 48,
                      isLoading: _isLoading,
                      onPressed: _onSendResetCode,
                    ),
                    const SizedBox(height: 16),

                    // Back to Login Link
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back,
                          size: 14,
                          color: AppColors.mutedText(context),
                        ),
                        label: Text(
                          loc.tr('back_to_login'),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.mutedText(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
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
