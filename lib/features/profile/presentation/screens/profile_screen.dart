import 'package:aesthetic_way/core/theme/patient_design.dart';
import 'package:aesthetic_way/core/widgets/luxury_phone_input_field.dart';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/theme/theme_service.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/ltr_text_field.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/utils/contact_launcher.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/login_screen.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';
import 'package:aesthetic_way/features/auth/data/models/auth_models.dart';
import 'package:aesthetic_way/features/referral/presentation/screens/referral_screen.dart';
import 'package:aesthetic_way/core/services/support_service.dart';

/// Screen 25: Patient Profile & Settings — Live API (/api/v1/auth/me/)
class ProfileScreen extends StatefulWidget {
  final VoidCallback onNavigateToRequests;
  final AuthRepository? authRepository;

  const ProfileScreen({
    super.key,
    required this.onNavigateToRequests,
    this.authRepository,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthRepository _authRepo;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  UserModel? _user;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _profileFlight = false;
  bool _isEditing = false;
  String? _errorMessage;
  String? _profileEditErrorMessage;

  @override
  void initState() {
    super.initState();
    _authRepo = widget.authRepository ?? AuthRepository();
    final auth = AuthState();
    _nameController = TextEditingController(text: auth.userName);
    _phoneController = TextEditingController(text: auth.userPhone);
    _emailController = TextEditingController(text: auth.userEmail);
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (_profileFlight) return;
    _profileFlight = true;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authRepo.getMe();
      if (!mounted) return;
      setState(() {
        _user = user;
        _nameController.text = user.fullName;
        _phoneController.text = user.phone;
        _emailController.text = user.email ?? '';
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = LocaleService().isArabic
            ? 'تعذر تحميل بيانات الملف الشخصي من الخادم.'
            : 'Unable to load profile data from server.';
        _isLoading = false;
      });
    } finally {
      _profileFlight = false;
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final loc = LocaleService();
    setState(() {
      _isSaving = true;
      _profileEditErrorMessage = null;
    });

    try {
      final updated = await _authRepo.updateMe(
        fullName: _nameController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _user = updated;
        _nameController.text = updated.fullName;
        _phoneController.text = updated.phone;
        _emailController.text = updated.email ?? '';
        _isSaving = false;
        _isEditing = false;
        _errorMessage = null;
        _profileEditErrorMessage = null;
      });
      showAppSnackBar(
        context,
        loc.isArabic
            ? 'تم تحديث الملف الشخصي بنجاح'
            : 'Profile updated successfully',
        type: AppSnackBarType.success,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _profileEditErrorMessage = e.message;
      });
      showAppSnackBar(context, e.message, type: AppSnackBarType.error);
    } catch (e) {
      if (!mounted) return;
      final msg = loc.isArabic
          ? 'فشل حفظ التعديلات، يرجى المحاولة مرة أخرى'
          : 'Failed to save changes, please try again';
      setState(() {
        _isSaving = false;
        _profileEditErrorMessage = msg;
      });
      showAppSnackBar(context, msg, type: AppSnackBarType.error);
    }
  }

  void _showPrivacyTermsSheet(BuildContext context, LocaleService loc) {
    final isDark = AppColors.isDark(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? AppColors.cardSurface
          : AppColors.lightCardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.mutedText(
                        context,
                      ).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.security_outlined,
                      color: AppColors.accentChampagne,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.tr('privacy_sheet_title'),
                        style: AppTypography.cardTitle.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.silverPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  loc.tr('privacy_sheet_text'),
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.silverSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.6,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                SilverButton(
                  label: loc.isArabic ? 'حسناً، فهمت' : 'Understood',
                  isFullWidth: true,
                  height: 42,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSupportSheet(BuildContext context, LocaleService loc) {
    final isDark = AppColors.isDark(context);
    final supportService = SupportService();
    supportService.fetchSupportInfo(); // Trigger async refresh in background

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? AppColors.cardSurface
          : AppColors.lightCardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final info = supportService.info;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.mutedText(
                        context,
                      ).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.headset_mic_outlined,
                      color: AppColors.accentChampagne,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.tr('concierge_title'),
                        style: AppTypography.cardTitle.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.silverPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  loc.tr('concierge_desc'),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.mutedText(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.isArabic ? info.workingHoursAr : info.workingHoursEn,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.goldText(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  tileColor: isDark
                      ? AppColors.cardSurfaceHover
                      : AppColors.lightCardSurfaceHover,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppColors.border(context),
                      width: 0.8,
                    ),
                  ),
                  leading: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFF34D399),
                  ),
                  title: Text(
                    loc.tr('whatsapp_concierge'),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.silverPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${info.phoneDisplay} (WhatsApp)',
                    style: TextStyle(
                      color: AppColors.mutedText(context),
                      fontSize: 11.5,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 13,
                    color: AppColors.mutedText(context),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ContactLauncher.openWhatsApp(
                      phoneNumber: info.whatsapp,
                      message: loc.isArabic
                          ? 'مرحباً، أود التواصل مع خدمة عملاء منصة AESTHETIC WAY.'
                          : 'Hello, I would like to contact Aesthetic Way platform support.',
                    );
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  tileColor: isDark
                      ? AppColors.cardSurfaceHover
                      : AppColors.lightCardSurfaceHover,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppColors.border(context),
                      width: 0.8,
                    ),
                  ),
                  leading: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.accentChampagne,
                  ),
                  title: Text(
                    loc.tr('call_concierge'),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.silverPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    info.phoneDisplay,
                    style: TextStyle(
                      color: AppColors.mutedText(context),
                      fontSize: 11.5,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 13,
                    color: AppColors.mutedText(context),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ContactLauncher.makePhoneCall(info.phone);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditProfileSection(
    BuildContext context,
    LocaleService loc,
    bool isDark,
  ) {
    return LuxuryCard(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.accentChampagne,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.isArabic
                        ? 'تعديل البيانات الشخصية'
                        : 'Edit Personal Profile',
                    style: AppTypography.cardTitle.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: isDark
                          ? AppColors.silverPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.mutedText(context),
                    ),
                    tooltip: loc.isArabic ? 'إغلاق' : 'Close',
                    onPressed: _isSaving
                        ? null
                        : () {
                            setState(() {
                              _isEditing = false;
                              _nameController.text =
                                  _user?.fullName ?? AuthState().userName;
                              _phoneController.text =
                                  _user?.phone ?? AuthState().userPhone;
                              _emailController.text =
                                  _user?.email ?? AuthState().userEmail;
                            });
                          },
                  ),
              ],
            ),
            if (_profileEditErrorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _profileEditErrorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      onPressed: () {
                        setState(() => _profileEditErrorMessage = null);
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('profile_full_name_field'),
              controller: _nameController,
              enabled: !_isSaving,
              style: TextStyle(
                color: isDark
                    ? AppColors.textPrimary
                    : AppColors.lightTextPrimary,
                fontSize: 13.5,
              ),
              decoration: InputDecoration(
                labelText: loc.tr('full_name'),
                hintText: loc.isArabic
                    ? 'مثال: سارة المنصوري'
                    : 'e.g. Sarah Al Mansoori',
                hintStyle: TextStyle(
                  color: AppColors.text(context).withValues(alpha: 0.68),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.person_outline,
                  size: 19,
                  color: AppColors.mutedText(context),
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.cardSurfaceHover
                    : AppColors.lightCardSurfaceHover,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return loc.isArabic
                      ? 'الاسم الكامل مطلوب'
                      : 'Full name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            LuxuryPhoneInputField(
              key: const Key('profile_phone_field'),
              fieldKey: const Key('profile_phone_field_input'),
              controller: _phoneController,
              readOnly: true,
              enabled: true,
            ),
            const SizedBox(height: 12),
            LtrTextFormField(
              key: const Key('profile_email_field'),
              controller: _emailController,
              readOnly: true,
              enabled: true,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(
                color: AppColors.mutedText(context),
                fontSize: 13.5,
              ),
              decoration: InputDecoration(
                labelText: loc.tr('email_address'),
                hintText: 'name@example.com',
                hintStyle: TextStyle(
                  color: AppColors.text(context).withValues(alpha: 0.68),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  size: 19,
                  color: AppColors.mutedText(context),
                ),
                suffixIcon: Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: AppColors.mutedText(context),
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.cardSurface
                    : AppColors.lightBackgroundAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              key: const Key('profile_contact_readonly_note'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentChampagne.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.accentChampagne.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 16,
                    color: AppColors.accentChampagne,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.isArabic
                          ? 'لحماية حسابك، يرجى التواصل مع خدمة العملاء لتغيير رقم الهاتف أو البريد الإلكتروني الموثق'
                          : 'For your security, please contact customer support to change your verified phone or email',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondaryText(context),
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SilverButton(
              label: _isSaving
                  ? (loc.isArabic ? 'جاري الحفظ...' : 'Saving...')
                  : (loc.isArabic ? 'حفظ التعديلات' : 'Save Changes'),
              icon: Icons.check_circle_outline_rounded,
              isFullWidth: true,
              onPressed: _isSaving ? null : _saveProfile,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PatientDesign(builder: _buildPatient);

  Widget _buildPatient(BuildContext context) {
    final auth = AuthState();
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    return ListenableBuilder(
      listenable: Listenable.merge([loc, auth]),
      builder: (context, _) {
        final displayName = (_user?.fullName.isNotEmpty == true)
            ? _user!.fullName
            : auth.userName;
        final displayPhone = (_user?.phone.isNotEmpty == true)
            ? _user!.phone
            : auth.userPhone;
        final displayEmail = (_user?.email != null && _user!.email!.isNotEmpty)
            ? _user!.email!
            : auth.userEmail;
        final isVerified = _user?.isVerified ?? auth.isVerified;
        final hasAuthenticatedUser = auth.isLoggedIn || _user != null;

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Text(
              loc.tr('profile_title'),
              style: PatientDesign.heading(context, size: 23).copyWith(
                color: isDark
                    ? AppColors.silverPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            automaticallyImplyLeading: false,
            actions: [
              if (hasAuthenticatedUser)
                IconButton(
                  tooltip: loc.isArabic ? 'تحديث البيانات' : 'Refresh Profile',
                  icon: _isLoading
                      ? SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            semanticsLabel: loc.isArabic
                                ? 'جارٍ تحديث الملف الشخصي'
                                : 'Updating profile',
                          ),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          color: isDark
                              ? AppColors.silverSecondary
                              : AppColors.lightTextPrimary,
                        ),
                  onPressed: _isLoading ? null : _loadProfile,
                ),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.accentChampagne,
            onRefresh: _loadProfile,
            child: _isLoading && _user == null && !auth.isLoggedIn
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentChampagne,
                    ),
                  )
                : !hasAuthenticatedUser
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      if (_errorMessage != null) ...[
                        LuxuryCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _loadProfile,
                                child: Text(
                                  loc.isArabic ? 'إعادة المحاولة' : 'Retry',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      LuxuryCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.cardSurfaceHover
                                    : AppColors.lightCardSurfaceHover,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.border(context),
                                ),
                              ),
                              child: Icon(
                                Icons.lock_outline_rounded,
                                size: 44,
                                color: isDark
                                    ? AppColors.silverPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              loc.tr('login_title'),
                              style: PatientDesign.heading(context, size: 26)
                                  .copyWith(
                                    fontSize: 18,
                                    color: isDark
                                        ? AppColors.silverPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              loc.tr('login_prompt'),
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.mutedText(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            SilverButton(
                              label: loc.tr('login_btn'),
                              icon: Icons.login_rounded,
                              isFullWidth: true,
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  LuxuryPageRoute(page: const LoginScreen()),
                                  (route) => false,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ThemeSwitchTile(loc: loc),
                      const SizedBox(height: 10),
                      _LanguageSwitchTile(loc: loc),
                      const SizedBox(height: 10),
                      _ProfileMenuTile(
                        icon: Icons.security_outlined,
                        title: loc.tr('privacy_terms'),
                        subtitle: loc.isArabic
                            ? 'دليل واكتشاف العيادات الطبية والتجميلية في الإمارات'
                            : 'Aesthetic and medical discovery platform in the UAE',
                        onTap: () => _showPrivacyTermsSheet(context, loc),
                      ),
                      const SizedBox(height: 10),
                      _ProfileMenuTile(
                        icon: Icons.headset_mic_outlined,
                        title: loc.tr('support_help'),
                        subtitle: loc.isArabic
                            ? 'تواصل مع فريق خدمة العملاء والدعم'
                            : 'Contact Aesthetic Way customer support',
                        onTap: () => _showSupportSheet(context, loc),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: LinearProgressIndicator(
                            color: AppColors.accentChampagne,
                            minHeight: 2,
                          ),
                        ),
                      if (_errorMessage != null) ...[
                        LuxuryCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orangeAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AppTypography.caption.copyWith(
                                    color: isDark
                                        ? AppColors.silverSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _loadProfile,
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                  color: AppColors.accentChampagne,
                                ),
                                label: Text(
                                  loc.isArabic ? 'إعادة المحاولة' : 'Retry',
                                  style: TextStyle(
                                    color: AppColors.goldText(context),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Logged-in User Profile Summary Card
                      LuxuryCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: isDark
                                  ? AppColors.cardSurfaceHover
                                  : AppColors.lightCardSurfaceHover,
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName.characters.first.toUpperCase()
                                    : 'U',
                                style: PatientDesign.heading(context, size: 26)
                                    .copyWith(
                                      fontSize: 22,
                                      color: AppColors.goldText(context),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: AppTypography.cardTitle.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.silverPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  if (displayPhone.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Text(
                                        displayPhone,
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.mutedText(context),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (displayEmail.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Text(
                                        displayEmail,
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.mutedText(context),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentChampagne
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.accentChampagne
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isVerified
                                              ? Icons.verified_outlined
                                              : Icons.info_outline,
                                          size: 12,
                                          color: AppColors.accentChampagne,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            isVerified
                                                ? (loc.isArabic
                                                      ? 'مستخدم موثق'
                                                      : 'Verified Member')
                                                : (loc.isArabic
                                                      ? 'حساب مسجل'
                                                      : 'Registered Account'),
                                            style: AppTypography.badge.copyWith(
                                              color: AppColors.goldText(
                                                context,
                                              ),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              key: const Key('toggle_edit_profile_btn'),
                              tooltip: loc.isArabic
                                  ? 'تعديل الملف الشخصي'
                                  : 'Edit Profile',
                              icon: Icon(
                                _isEditing
                                    ? Icons.expand_less_rounded
                                    : Icons.edit_outlined,
                                color: AppColors.accentChampagne,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isEditing = !_isEditing;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Live Profile Edit Form (always accessible via edit button or expanded)
                      if (_isEditing) ...[
                        _buildEditProfileSection(context, loc, isDark),
                        const SizedBox(height: 16),
                      ],

                      // Menu Items
                      _ProfileMenuTile(
                        icon: Icons.assignment_outlined,
                        title: loc.tr('my_requests_title'),
                        subtitle: loc.isArabic
                            ? 'متابعة حالة الطلبات والتواصل مع العيادات'
                            : 'Track lead status and clinic responses',
                        onTap: widget.onNavigateToRequests,
                      ),
                      const SizedBox(height: 10),

                      // Referral & Rewards Tile
                      _ProfileMenuTile(
                        icon: Icons.card_giftcard_rounded,
                        title: loc.tr('referral_nav_title'),
                        subtitle: loc.isArabic
                            ? 'شارك رابط دعوتك وتابع النقاط ومراحل التقدم'
                            : 'Share your invite link and track points and milestones',
                        onTap: () {
                          Navigator.push(
                            context,
                            LuxuryPageRoute(page: const ReferralScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      // Theme Switcher Tile
                      _ThemeSwitchTile(loc: loc),
                      const SizedBox(height: 10),

                      // Language Switcher Tile
                      _LanguageSwitchTile(loc: loc),
                      const SizedBox(height: 10),

                      _ProfileMenuTile(
                        icon: Icons.security_outlined,
                        title: loc.tr('privacy_terms'),
                        subtitle: loc.isArabic
                            ? 'دليل واكتشاف العيادات الطبية والتجميلية في الإمارات'
                            : 'Aesthetic and medical discovery platform in the UAE',
                        onTap: () => _showPrivacyTermsSheet(context, loc),
                      ),
                      const SizedBox(height: 10),
                      _ProfileMenuTile(
                        icon: Icons.headset_mic_outlined,
                        title: loc.tr('support_help'),
                        subtitle: loc.isArabic
                            ? 'تواصل مع فريق خدمة العملاء والدعم'
                            : 'Contact Aesthetic Way customer support',
                        onTap: () => _showSupportSheet(context, loc),
                      ),
                      const SizedBox(height: 20),

                      SilverButton(
                        label: loc.tr('logout_btn'),
                        variant: SilverButtonVariant.secondary,
                        icon: Icons.logout_rounded,
                        isFullWidth: true,
                        onPressed: () async {
                          await _authRepo.logout();
                          if (!context.mounted) return;
                          showAppSnackBar(
                            context,
                            loc.isArabic
                                ? 'تم تسجيل الخروج بنجاح'
                                : 'Logged out successfully',
                            type: AppSnackBarType.info,
                          );
                          Navigator.of(context).pushAndRemoveUntil(
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const LoginScreen(),
                              transitionDuration: const Duration(
                                milliseconds: 400,
                              ),
                              transitionsBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                            ),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _ThemeSwitchTile extends StatelessWidget {
  final LocaleService loc;

  const _ThemeSwitchTile({required this.loc});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    final isDark = AppColors.isDark(context);

    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        final currentMode = themeService.themeMode;

        return LuxuryCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.accentChampagne.withValues(
                        alpha: isDark ? 0.15 : 0.2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.palette_outlined,
                      color: AppColors.accentChampagne,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loc.tr('theme_title'),
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.silverPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Segmented theme pills: Dark / Light / System
              Row(
                children: [
                  _ThemePill(
                    icon: Icons.dark_mode_outlined,
                    label: loc.isArabic ? 'داكن' : 'Dark',
                    isSelected: currentMode == ThemeMode.dark,
                    onTap: () => themeService.setThemeMode(ThemeMode.dark),
                  ),
                  const SizedBox(width: 8),
                  _ThemePill(
                    icon: Icons.light_mode_outlined,
                    label: loc.isArabic ? 'فاتح فاخر' : 'Light',
                    isSelected: currentMode == ThemeMode.light,
                    onTap: () => themeService.setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(width: 8),
                  _ThemePill(
                    icon: Icons.phone_android_rounded,
                    label: loc.isArabic ? 'تلقائي' : 'System',
                    isSelected: currentMode == ThemeMode.system,
                    onTap: () => themeService.setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemePill({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final activeTextColor = isDark ? AppColors.backgroundDeep : Colors.white;
    final inactiveTextColor = isDark
        ? AppColors.silverSecondary
        : AppColors.lightTextSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? AppColors.silverPrimary
                      : AppColors.lightTextPrimary)
                : (isDark
                      ? AppColors.cardSurfaceHover
                      : AppColors.lightCardSurfaceHover),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.accentChampagne
                  : AppColors.border(context),
              width: isSelected ? 1.0 : 0.7,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? activeTextColor : inactiveTextColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: isSelected ? activeTextColor : inactiveTextColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSwitchTile extends StatelessWidget {
  final LocaleService loc;

  const _LanguageSwitchTile({required this.loc});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return LuxuryCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: loc.toggleLanguage,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.accentChampagne.withValues(
                alpha: isDark ? 0.15 : 0.2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.language_rounded,
              color: AppColors.accentChampagne,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.tr('app_language'),
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.silverPrimary
                        : AppColors.lightTextPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  loc.isArabic ? 'العربية (Arabic - RTL)' : 'English (LTR)',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.mutedText(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardSurfaceHover
                  : AppColors.lightCardSurfaceHover,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border(context), width: 0.8),
            ),
            child: Text(
              loc.tr('switch_language'),
              style: AppTypography.caption.copyWith(
                color: AppColors.goldText(context),
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return LuxuryCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardSurfaceHover
                  : AppColors.lightCardSurfaceHover,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border(context), width: 0.8),
            ),
            child: Icon(
              icon,
              color: isDark
                  ? AppColors.silverSecondary
                  : AppColors.lightTextPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.silverPrimary
                        : AppColors.lightTextPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.mutedText(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 13,
            color: AppColors.mutedText(context),
          ),
        ],
      ),
    );
  }
}
