import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
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
import 'package:aesthetic_way/features/navigation/main_nav_screen.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/register_screen.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_main_nav_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_main_nav_screen.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';

/// Screen 2: Luxury Login Screen for Patient Authentication + Clinic Partner Portal Entry
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPhoneLogin = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    final loc = LocaleService();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final input = _isPhoneLogin
        ? _phoneController.text.trim()
        : _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final authResponse = await AuthRepository().login(
        identifier: input,
        password: password,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      showAppSnackBar(
        context,
        loc.isArabic
            ? 'مرحباً بك مجدداً، ${authResponse.user.fullName}'
            : 'Welcome back, ${authResponse.user.fullName}',
        type: AppSnackBarType.success,
      );

      final role = authResponse.user.role;

      Widget targetScreen;
      if (role == 'super_admin') {
        targetScreen = const AdminMainNavScreen();
      } else if (role == 'clinic_admin' || role == 'clinic_staff') {
        targetScreen = const ClinicMainNavScreen();
      } else if (role == 'patient') {
        targetScreen = const MainNavScreen();
      } else {
        AuthState().logout();
        targetScreen = const LoginScreen();
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
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Official Logo (Prominent Auth Sizing)
                      const Center(child: AppBrandLogo.auth()),
                      const SizedBox(height: 24),

                      // Welcome Headers
                      Center(
                        child: Text(
                          loc.tr('login_title'),
                          style: AppTypography.heroTitle.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.silverPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          loc.tr('login_sub'),
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.mutedText(context),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Mode Selector Toggle (Phone vs Email)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.cardSurfaceHover
                              : AppColors.lightCardSurfaceHover,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border(
                              context,
                            ).withValues(alpha: 0.6),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _isPhoneLogin = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isPhoneLogin
                                        ? (isDark
                                              ? AppColors.silverPrimary
                                              : AppColors.primarySoftNavy)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: _isPhoneLogin
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.15,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.phone_iphone_rounded,
                                        size: 15,
                                        color: _isPhoneLogin
                                            ? (isDark
                                                  ? AppColors.backgroundDeep
                                                  : Colors.white)
                                            : AppColors.mutedText(context),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          loc.isArabic
                                              ? 'رقم الهاتف'
                                              : 'Phone Number',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: _isPhoneLogin
                                                ? (isDark
                                                      ? AppColors.backgroundDeep
                                                      : Colors.white)
                                                : AppColors.mutedText(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _isPhoneLogin = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_isPhoneLogin
                                        ? (isDark
                                              ? AppColors.silverPrimary
                                              : AppColors.primarySoftNavy)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: !_isPhoneLogin
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.15,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.email_outlined,
                                        size: 15,
                                        color: !_isPhoneLogin
                                            ? (isDark
                                                  ? AppColors.backgroundDeep
                                                  : Colors.white)
                                            : AppColors.mutedText(context),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          loc.isArabic
                                              ? 'البريد الإلكتروني'
                                              : 'Email Address',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: !_isPhoneLogin
                                                ? (isDark
                                                      ? AppColors.backgroundDeep
                                                      : Colors.white)
                                                : AppColors.mutedText(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Input Fields Card
                      LuxuryCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_isPhoneLogin)
                              LuxuryPhoneInputField(
                                controller: _phoneController,
                                isRequired: true,
                                labelText: loc.isArabic
                                    ? 'رقم الهاتف'
                                    : 'Phone Number',
                              )
                            else
                              TextFormField(
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
                                decoration: InputDecoration(
                                  labelText: loc.isArabic
                                      ? 'البريد الإلكتروني'
                                      : 'Email Address',
                                  hintText: 'name@example.com',
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
                                  if (val == null || val.trim().isEmpty) {
                                    return loc.isArabic
                                        ? 'يرجى إدخال البريد الإلكتروني'
                                        : 'Email is required';
                                  }
                                  if (!val.contains('@') ||
                                      !val.contains('.')) {
                                    return loc.isArabic
                                        ? 'صيغة بريد غير صحيحة'
                                        : 'Invalid email format';
                                  }
                                  return null;
                                },
                              ),
                            const SizedBox(height: 14),

                            // Password Field
                            TextFormField(
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
                              decoration: InputDecoration(
                                labelText: loc.tr('password_label'),
                                hintText: loc.tr('password_hint'),
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
                                if (val == null || val.trim().length < 6) {
                                  return loc.tr('val_password_short');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),

                            // Forgot Password Link
                            Align(
                              alignment: loc.isArabic
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    LuxuryPageRoute(
                                      page: const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  loc.tr('forgot_password_link'),
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.goldText(context),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sign In Button
                      SilverButton(
                        label: loc.tr('login_title'),
                        icon: Icons.login_rounded,
                        isFullWidth: true,
                        height: 48,
                        isLoading: _isLoading,
                        onPressed: _onLogin,
                      ),
                      const SizedBox(height: 14),

                      // Register Link
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            loc.tr('dont_have_account'),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.mutedText(context),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                LuxuryPageRoute(page: const RegisterScreen()),
                              );
                            },
                            child: Text(
                              loc.tr('create_account_link'),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.goldText(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
