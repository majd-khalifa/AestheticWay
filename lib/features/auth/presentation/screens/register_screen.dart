import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/app_brand_logo.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/otp_screen.dart';

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
    final loc = LocaleService();
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.tr('val_terms_required')),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    final phone = _phoneController.text.trim();
    final formattedPhone = phone.startsWith('+971') ? phone : '+971 $phone';

    Navigator.push(
      context,
      LuxuryPageRoute(
        page: OtpScreen(
          purpose: OtpPurpose.registration,
          targetContact: formattedPhone,
          userName: _nameController.text.trim(),
          userEmail: _emailController.text.trim(),
        ),
      ),
    );
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Logo
                    const Center(
                      child: AppBrandLogo.header(height: 32),
                    ),
                    const SizedBox(height: 16),

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
                              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: loc.tr('full_name'),
                              hintText: loc.tr('name_hint'),
                              labelStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12.5),
                              prefixIcon: Icon(Icons.badge_outlined, color: AppColors.mutedText(context), size: 19),
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
                              if (val == null || val.trim().isEmpty) {
                                return loc.tr('val_name_required');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // 2. Phone Number (+971)
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: loc.tr('phone_uae'),
                              hintText: loc.tr('phone_hint'),
                              labelStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12.5),
                              prefixText: '+971  ',
                              prefixStyle: TextStyle(
                                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.mutedText(context), size: 19),
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
                                return loc.tr('val_phone_required');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // 3. Email Address
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: loc.tr('email_address'),
                              hintText: loc.tr('email_hint'),
                              labelStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12.5),
                              prefixIcon: Icon(Icons.email_outlined, color: AppColors.mutedText(context), size: 19),
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
                              if (val == null || val.trim().isEmpty || !val.contains('@')) {
                                return loc.tr('val_email_invalid');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // 4. Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(
                              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: loc.tr('password_label'),
                              hintText: loc.tr('password_hint'),
                              labelStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12.5),
                              prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.mutedText(context), size: 19),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
                              if (val == null || val.trim().length < 6) {
                                return loc.tr('val_password_short');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // 5. Confirm Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            style: TextStyle(
                              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: loc.tr('confirm_password_label'),
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
                              if (val != _passwordController.text) {
                                return loc.tr('val_password_mismatch');
                              }
                              return null;
                            },
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
                            checkColor: isDark ? AppColors.backgroundDeep : Colors.white,
                            side: BorderSide(color: AppColors.border(context), width: 1.2),
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
                    const SizedBox(height: 16),

                    // Already Have Account Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          loc.tr('already_have_account'),
                          style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            loc.tr('sign_in_link'),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.accentChampagne,
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
