import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/app_brand_logo.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/navigation/main_nav_screen.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/register_screen.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/forgot_password_screen.dart';

/// Screen 2: Luxury Login Screen for Patient Authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(text: '501234567');
  final _passwordController = TextEditingController(text: '123456');
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    final input = _identifierController.text.trim();
    final isEmail = input.contains('@');

    AuthState().login(
      name: 'مجد خليفة',
      phone: isEmail ? '+971 50 123 4567' : (input.startsWith('+971') ? input : '+971 $input'),
      email: isEmail ? input : 'majd@example.com',
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainNavScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _continueAsGuest() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainNavScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
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
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Official Logo
                      const Center(
                        child: AppBrandLogo.header(height: 38),
                      ),
                      const SizedBox(height: 24),

                      // Welcome Headers
                      Center(
                        child: Text(
                          loc.tr('login_title'),
                          style: AppTypography.heroTitle.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
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

                      // Input Fields Card
                      LuxuryCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Identifier (Phone or Email)
                            TextFormField(
                              controller: _identifierController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(
                                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                labelText: loc.tr('identifier_label'),
                                hintText: loc.tr('identifier_hint'),
                                labelStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12.5),
                                prefixIcon: Icon(Icons.person_outline, color: AppColors.mutedText(context), size: 19),
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
                                  return loc.tr('val_identifier_required');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Password Field
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
                            const SizedBox(height: 8),

                            // Forgot Password Link
                            Align(
                              alignment: loc.isArabic ? Alignment.centerLeft : Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    LuxuryPageRoute(page: const ForgotPasswordScreen()),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  loc.tr('forgot_password_link'),
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.accentChampagne,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            loc.tr('dont_have_account'),
                            style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
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
                                color: AppColors.accentChampagne,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Continue as Guest Option
                      Center(
                        child: TextButton.icon(
                          onPressed: _continueAsGuest,
                          icon: Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: AppColors.mutedText(context),
                          ),
                          label: Text(
                            loc.tr('continue_as_guest'),
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
          ),
        );
      },
    );
  }
}
