import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/luxury_card.dart';
import '../widgets/silver_button.dart';
import '../widgets/luxury_animations.dart';
import '../localization/app_locale.dart';
import '../../features/auth/presentation/screens/login_screen.dart';

/// User Authentication State Handler
class AuthState extends ChangeNotifier {
  static final AuthState _instance = AuthState._internal();
  factory AuthState() => _instance;
  AuthState._internal();

  bool _isLoggedIn = false;
  String _userName = 'مجد خليفة';
  String _userPhone = '+971 50 123 4567';
  String _userEmail = 'majd@example.com';
  final Set<String> _favoriteClinicIds = {'kaya-jumeirah', 'elegance-downtown'};

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userPhone => _userPhone;
  String get userEmail => _userEmail;
  Set<String> get favoriteClinicIds => _favoriteClinicIds;

  void login({required String name, required String phone, String email = ''}) {
    _isLoggedIn = true;
    _userName = name;
    _userPhone = phone;
    _userEmail = email;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  bool isFavorite(String clinicId) => _favoriteClinicIds.contains(clinicId);

  void toggleFavorite(String clinicId) {
    if (_favoriteClinicIds.contains(clinicId)) {
      _favoriteClinicIds.remove(clinicId);
    } else {
      _favoriteClinicIds.add(clinicId);
    }
    notifyListeners();
  }
}

/// Guard to prompt auth bottom sheet when guest tries to perform restricted actions
class GuestAuthGuard {
  static Future<bool> requireAuth(
    BuildContext context, {
    required String reasonTitle,
    required String reasonSubtitle,
  }) async {
    if (AuthState().isLoggedIn) {
      return true;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AuthPromptSheet(
        reasonTitle: reasonTitle,
        reasonSubtitle: reasonSubtitle,
      ),
    );

    return result ?? false;
  }
}

class _AuthPromptSheet extends StatefulWidget {
  final String reasonTitle;
  final String reasonSubtitle;

  const _AuthPromptSheet({
    required this.reasonTitle,
    required this.reasonSubtitle,
  });

  @override
  State<_AuthPromptSheet> createState() => _AuthPromptSheetState();
}

class _AuthPromptSheetState extends State<_AuthPromptSheet> {
  final _nameController = TextEditingController(text: 'مجد خليفة');
  final _phoneController = TextEditingController(text: '501234567');
  final _emailController = TextEditingController(text: 'majd@example.com');
  bool _showOtp = false;
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _onSendOtp() {
    if (_phoneController.text.trim().isEmpty) return;
    setState(() {
      _showOtp = true;
    });
  }

  void _onConfirmLogin() {
    AuthState().login(
      name: _nameController.text.trim().isEmpty
          ? 'ضيف متميز'
          : _nameController.text.trim(),
      phone: '+971 ${_phoneController.text.trim()}',
      email: _emailController.text.trim(),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final loc = LocaleService();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDeep : AppColors.lightCardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.border(context), width: 0.85),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mutedText(context).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.reasonTitle,
                      style: AppTypography.cardTitle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      widget.reasonSubtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.mutedText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!_showOtp) ...[
            LuxuryCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    style: TextStyle(
                      color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: loc.tr('full_name'),
                      labelStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12.5),
                      floatingLabelStyle: TextStyle(
                        color: isDark ? AppColors.silverPrimary : AppColors.primarySoftNavy,
                        fontWeight: FontWeight.w600,
                      ),
                      prefixIcon: Icon(
                        Icons.badge_outlined,
                        color: AppColors.mutedText(context),
                        size: 20,
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
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(
                      color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: loc.tr('phone_uae'),
                      labelStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12.5),
                      floatingLabelStyle: TextStyle(
                        color: isDark ? AppColors.silverPrimary : AppColors.primarySoftNavy,
                        fontWeight: FontWeight.w600,
                      ),
                      prefixText: '+971  ',
                      prefixStyle: TextStyle(
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: AppColors.mutedText(context),
                        size: 20,
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
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: loc.tr('email_address'),
                      labelStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12.5),
                      floatingLabelStyle: TextStyle(
                        color: isDark ? AppColors.silverPrimary : AppColors.primarySoftNavy,
                        fontWeight: FontWeight.w600,
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: AppColors.mutedText(context),
                        size: 20,
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SilverButton(
              label: loc.isArabic ? 'متابعة التحقق عبر SMS' : 'Continue with SMS OTP',
              icon: Icons.send_rounded,
              isFullWidth: true,
              onPressed: _onSendOtp,
            ),
          ] else ...[
            LuxuryCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    loc.isArabic
                        ? 'أدخل رمز التحقق (OTP) المرسل إلى +971 ${_phoneController.text}'
                        : 'Enter OTP sent to +971 ${_phoneController.text}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '••••',
                      hintStyle: TextStyle(
                        color: AppColors.mutedText(context),
                        letterSpacing: 8,
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SilverButton(
              label: loc.isArabic ? 'تأكيد ودخول' : 'Confirm & Login',
              icon: Icons.check_circle_outline,
              isFullWidth: true,
              onPressed: _onConfirmLogin,
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(false);
              Navigator.of(context).push(
                LuxuryPageRoute(page: const LoginScreen()),
              );
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.accentChampagne),
            label: Text(
              loc.tr('open_full_login'),
              style: const TextStyle(
                color: AppColors.accentChampagne,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: BorderSide(color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.45 : 0.6), width: 0.85),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              loc.isArabic ? 'إلغاء والمتابعة كزائر' : 'Cancel & Continue as Guest',
              style: AppTypography.caption.copyWith(
                color: AppColors.mutedText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
