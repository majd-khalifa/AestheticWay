import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/app_brand_logo.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/widgets/luxury_phone_input_field.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/otp_screen.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';

/// Screen 3: Luxury Registration Screen with Full Name, Phone, Email, Password & Terms
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  Map<String, String> _serverFieldErrors = {};
  String? _serverErrorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    if (_isLoading) return;
    final loc = LocaleService();
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      showAppSnackBar(
        context,
        loc.tr('val_terms_required'),
        type: AppSnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _serverFieldErrors = {};
      _serverErrorMessage = null;
    });

    final fullName = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final response = await AuthRepository().register(
        fullName: fullName,
        phone: phone,
        password: password,
        email: email.isNotEmpty ? email : null,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      showAppSnackBar(
        context,
        response.message.isNotEmpty
            ? response.message
            : (loc.isArabic
                  ? 'تم إنشاء الحساب، يرجى تأكيد رمز التحقق'
                  : 'Account created, please verify OTP'),
        type: AppSnackBarType.success,
      );

      final normalizedPhone = AuthRepository.normalizePhone(phone);

      Navigator.push(
        context,
        LuxuryPageRoute(
          page: OtpScreen(
            purpose: OtpPurpose.registration,
            targetContact: normalizedPhone,
            userName: fullName,
            userEmail: email,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _serverErrorMessage = e.message;
        if (e.fieldErrors != null) {
          _serverFieldErrors = e.fieldErrors!.map(
            (key, val) => MapEntry(key, val.join(' - ')),
          );
        } else {
          _serverFieldErrors.clear();
        }
      });
      showAppSnackBar(context, e.message, type: AppSnackBarType.error);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _serverErrorMessage = e.toString();
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
              loc.tr('register_title'),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Logo (Prominent Auth Sizing)
                    const Center(child: AppBrandLogo.auth()),
                    const SizedBox(height: 20),

                    // Subtitle
                    Center(
                      child: Text(
                        loc.tr('register_sub'),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.mutedText(context),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form Fields Card
                    LuxuryCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // 1. Full Name
                          TextFormField(
                            controller: _nameController,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.lightTextPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                            onChanged: (_) {
                              if (_serverFieldErrors.containsKey('full_name')) {
                                setState(
                                  () => _serverFieldErrors.remove('full_name'),
                                );
                              }
                            },
                            decoration: InputDecoration(
                              labelText: loc.tr('full_name'),
                              hintText: loc.tr('name_hint'),
                              hintStyle: TextStyle(
                                color: AppColors.text(
                                  context,
                                ).withValues(alpha: 0.68),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                              labelStyle: TextStyle(
                                color: AppColors.mutedText(context),
                                fontSize: 12.5,
                              ),
                              prefixIcon: Icon(
                                Icons.badge_outlined,
                                color: AppColors.mutedText(context),
                                size: 19,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.cardSurfaceHover
                                  : AppColors.lightCardSurfaceHover,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color:
                                      _serverFieldErrors.containsKey(
                                        'full_name',
                                      )
                                      ? AppColors.errorRed
                                      : AppColors.border(context),
                                  width: 0.8,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color:
                                      _serverFieldErrors.containsKey(
                                        'full_name',
                                      )
                                      ? AppColors.errorRed
                                      : (isDark
                                            ? AppColors.silverPrimary
                                            : AppColors.primarySoftNavy),
                                  width: 1.4,
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return loc.tr('val_name_required');
                              }
                              return null;
                            },
                          ),
                          if (_serverFieldErrors.containsKey('full_name'))
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4,
                                right: 6,
                                left: 6,
                              ),
                              child: Text(
                                _serverFieldErrors['full_name']!,
                                style: const TextStyle(
                                  color: AppColors.errorRed,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          const SizedBox(height: 14),

                          // 2. UAE & International Phone with LuxuryPhoneInputField
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LuxuryPhoneInputField(
                                controller: _phoneController,
                                isRequired: true,
                                onChanged: (_) {
                                  if (_serverFieldErrors.containsKey('phone')) {
                                    setState(
                                      () => _serverFieldErrors.remove('phone'),
                                    );
                                  }
                                },
                              ),
                              if (_serverFieldErrors.containsKey('phone'))
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    right: 6,
                                    left: 6,
                                  ),
                                  child: Text(
                                    _serverFieldErrors['phone']!,
                                    style: const TextStyle(
                                      color: AppColors.errorRed,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 3. Email Address (LTR)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.textPrimary
                                        : AppColors.lightTextPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  onChanged: (_) {
                                    if (_serverFieldErrors.containsKey(
                                      'email',
                                    )) {
                                      setState(
                                        () =>
                                            _serverFieldErrors.remove('email'),
                                      );
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: loc.tr('email_address'),
                                    hintText: 'name@example.com',
                                    hintStyle: TextStyle(
                                      color: AppColors.text(
                                        context,
                                      ).withValues(alpha: 0.5),
                                      fontSize: 13,
                                    ),
                                    labelStyle: TextStyle(
                                      color: AppColors.mutedText(context),
                                      fontSize: 12.5,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: AppColors.mutedText(context),
                                      size: 19,
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? AppColors.cardSurfaceHover
                                        : AppColors.lightCardSurfaceHover,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color:
                                            _serverFieldErrors.containsKey(
                                              'email',
                                            )
                                            ? AppColors.errorRed
                                            : AppColors.border(context),
                                        width: 0.8,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color:
                                            _serverFieldErrors.containsKey(
                                              'email',
                                            )
                                            ? AppColors.errorRed
                                            : (isDark
                                                  ? AppColors.silverPrimary
                                                  : AppColors.primarySoftNavy),
                                        width: 1.4,
                                      ),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return null; // email optional in backend
                                    }
                                    if (!val.contains('@') ||
                                        !val.contains('.')) {
                                      return loc.tr('val_email_invalid');
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              if (_serverFieldErrors.containsKey('email'))
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    right: 6,
                                    left: 6,
                                  ),
                                  child: Text(
                                    _serverFieldErrors['email']!,
                                    style: const TextStyle(
                                      color: AppColors.errorRed,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 4. Password (Min 8 chars, LTR)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.textPrimary
                                        : AppColors.lightTextPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  onChanged: (_) {
                                    if (_serverFieldErrors.containsKey(
                                      'password',
                                    )) {
                                      setState(
                                        () => _serverFieldErrors.remove(
                                          'password',
                                        ),
                                      );
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: loc.tr('password_label'),
                                    hintText: loc.isArabic
                                        ? 'أدخل كلمة المرور (8 أحرف على الأقل)'
                                        : 'At least 8 characters',
                                    hintStyle: TextStyle(
                                      color: AppColors.text(
                                        context,
                                      ).withValues(alpha: 0.68),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    labelStyle: TextStyle(
                                      color: AppColors.mutedText(context),
                                      fontSize: 12.5,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline_rounded,
                                      color: AppColors.mutedText(context),
                                      size: 19,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppColors.mutedText(context),
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? AppColors.cardSurfaceHover
                                        : AppColors.lightCardSurfaceHover,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color:
                                            _serverFieldErrors.containsKey(
                                              'password',
                                            )
                                            ? AppColors.errorRed
                                            : AppColors.border(context),
                                        width: 0.8,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color:
                                            _serverFieldErrors.containsKey(
                                              'password',
                                            )
                                            ? AppColors.errorRed
                                            : (isDark
                                                  ? AppColors.silverPrimary
                                                  : AppColors.primarySoftNavy),
                                        width: 1.4,
                                      ),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return loc.isArabic
                                          ? 'كلمة المرور مطلوبة'
                                          : 'Password is required';
                                    }
                                    if (val.length < 8) {
                                      return loc.tr('val_password_short');
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              if (_serverFieldErrors.containsKey('password'))
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    right: 6,
                                    left: 6,
                                  ),
                                  child: Text(
                                    _serverFieldErrors['password']!,
                                    style: const TextStyle(
                                      color: AppColors.errorRed,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 5. Confirm Password (LTR)
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textPrimary
                                    : AppColors.lightTextPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                labelText: loc.tr('confirm_password_label'),
                                hintText: '••••••••',
                                hintStyle: TextStyle(
                                  color: AppColors.text(
                                    context,
                                  ).withValues(alpha: 0.68),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                ),
                                labelStyle: TextStyle(
                                  color: AppColors.mutedText(context),
                                  fontSize: 12.5,
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_reset_rounded,
                                  color: AppColors.mutedText(context),
                                  size: 19,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.mutedText(context),
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.cardSurfaceHover
                                    : AppColors.lightCardSurfaceHover,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.border(context),
                                    width: 0.8,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.silverPrimary
                                        : AppColors.primarySoftNavy,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return loc.isArabic
                                      ? 'يرجى تأكيد كلمة المرور'
                                      : 'Please confirm password';
                                }
                                if (val != _passwordController.text) {
                                  return loc.tr('val_password_mismatch');
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Terms Checkbox
                    InkWell(
                      onTap: () {
                        setState(() {
                          _agreedToTerms = !_agreedToTerms;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            activeColor: AppColors.accentChampagne,
                            checkColor: isDark
                                ? AppColors.backgroundDeep
                                : Colors.white,
                            side: BorderSide(
                              color: AppColors.border(context),
                              width: 1.2,
                            ),
                            onChanged: (val) {
                              setState(() {
                                _agreedToTerms = val ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                loc.tr('terms_agreement'),
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.mutedText(context),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Registration Button
                    SilverButton(
                      label: loc.tr('register_title'),
                      icon: Icons.person_add_alt_1_rounded,
                      isFullWidth: true,
                      height: 48,
                      isLoading: _isLoading,
                      onPressed: _onRegister,
                    ),

                    // Server Error Alert Banner
                    if (_serverErrorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.errorRed.withValues(alpha: 0.45),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.errorRed,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _serverErrorMessage!,
                                style: const TextStyle(
                                  color: AppColors.errorRed,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Already Have Account Link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          loc.tr('already_have_account'),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.mutedText(context),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            loc.tr('sign_in_link'),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.goldText(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
