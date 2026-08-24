import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/theme/theme_service.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/utils/contact_launcher.dart';

/// Screen 25: Patient Profile with Dynamic Theme & Language Switchers and Compliant Privacy Copy
class ProfileScreen extends StatelessWidget {
  final VoidCallback onNavigateToRequests;

  const ProfileScreen({super.key, required this.onNavigateToRequests});

  void _showPrivacyTermsSheet(BuildContext context, LocaleService loc) {
    final isDark = AppColors.isDark(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
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
                      color: AppColors.mutedText(context).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.security_outlined, color: AppColors.accentChampagne, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.tr('privacy_sheet_title'),
                        style: AppTypography.cardTitle.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  loc.tr('privacy_sheet_text'),
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.silverSecondary : AppColors.lightTextSecondary,
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

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
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
                      color: AppColors.mutedText(context).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.headset_mic_outlined, color: AppColors.accentChampagne, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.tr('concierge_title'),
                        style: AppTypography.cardTitle.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
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
                const SizedBox(height: 16),
                ListTile(
                  tileColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.border(context), width: 0.8),
                  ),
                  leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF34D399)),
                  title: Text(
                    loc.tr('whatsapp_concierge'),
                    style: TextStyle(
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '+971 50 888 9900 (UAE Concierge)',
                    style: TextStyle(color: AppColors.mutedText(context), fontSize: 11.5),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.mutedText(context)),
                  onTap: () {
                    Navigator.pop(ctx);
                    ContactLauncher.openWhatsApp(phoneNumber: '+971508889900');
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  tileColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.border(context), width: 0.8),
                  ),
                  leading: const Icon(Icons.phone_outlined, color: AppColors.accentChampagne),
                  title: Text(
                    loc.tr('call_concierge'),
                    style: TextStyle(
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '800-AESTHETIC (Toll-Free UAE)',
                    style: TextStyle(color: AppColors.mutedText(context), fontSize: 11.5),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.mutedText(context)),
                  onTap: () {
                    Navigator.pop(ctx);
                    ContactLauncher.makePhoneCall('+971800237843');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthState();
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
              loc.tr('profile_title'),
              style: AppTypography.screenTitle.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          body: ListenableBuilder(
            listenable: auth,
            builder: (context, _) {
              if (!auth.isLoggedIn) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    // Guest Banner Card
                    LuxuryCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            child: Icon(
                              Icons.person_outline_rounded,
                              size: 44,
                              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            loc.tr('guest_status'),
                            style: AppTypography.heroTitle.copyWith(
                              fontSize: 18,
                              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
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
                              GuestAuthGuard.requireAuth(
                                context,
                                reasonTitle: loc.tr('login_btn'),
                                reasonSubtitle: loc.isArabic
                                    ? 'أدخل بياناتك لتسجيل الدخول ومتابعة طلباتك'
                                    : 'Enter your details to login and track requests',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Theme Switcher Tile
                    _ThemeSwitchTile(loc: loc),
                    const SizedBox(height: 10),

                    // App Language Switcher Tile
                    _LanguageSwitchTile(loc: loc),
                    const SizedBox(height: 10),

                    _ProfileMenuTile(
                      icon: Icons.security_outlined,
                      title: loc.tr('privacy_terms'),
                      subtitle: loc.isArabic
                          ? 'منصة Aesthetic Way — رقم الترخيص: [LICENSE_PLACEHOLDER]'
                          : 'Aesthetic Way Platform — License: [LICENSE_PLACEHOLDER]',
                      onTap: () => _showPrivacyTermsSheet(context, loc),
                    ),
                    const SizedBox(height: 10),
                    _ProfileMenuTile(
                      icon: Icons.headset_mic_outlined,
                      title: loc.tr('support_help'),
                      subtitle: loc.isArabic
                          ? 'تواصل مع فريق الدعم والكونسيرج الموحد'
                          : 'Contact Aesthetic Way concierge support',
                      onTap: () => _showSupportSheet(context, loc),
                    ),
                  ],
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  // Logged-in User Profile Card
                  LuxuryCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                          child: Icon(
                            Icons.person,
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.userName,
                                style: AppTypography.cardTitle.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                auth.userPhone,
                                style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentChampagne.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.accentChampagne.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  loc.isArabic ? '👑 مستخدم موثق' : '👑 Verified Member',
                                  style: AppTypography.badge.copyWith(
                                    color: AppColors.accentChampagne,
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
                  const SizedBox(height: 16),

                  // Menu Items
                  _ProfileMenuTile(
                    icon: Icons.assignment_outlined,
                    title: loc.tr('my_requests_title'),
                    subtitle: loc.isArabic
                        ? 'متابعة حالة الطلبات والتواصل مع العيادات'
                        : 'Track lead status and clinic responses',
                    onTap: onNavigateToRequests,
                  ),
                  const SizedBox(height: 10),
                  _ProfileMenuTile(
                    icon: Icons.favorite_border_rounded,
                    title: loc.tr('my_favs'),
                    subtitle: '${auth.favoriteClinicIds.length} ${loc.isArabic ? "عيادات محفوظة" : "saved clinics"}',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.isArabic ? 'قائمة المفضلة مفعلة وجاهزة' : 'Favorites list is active'),
                          backgroundColor: AppColors.surface(context),
                        ),
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
                        ? 'منصة Aesthetic Way — رقم الترخيص: [LICENSE_PLACEHOLDER]'
                        : 'Aesthetic Way Platform — License: [LICENSE_PLACEHOLDER]',
                    onTap: () => _showPrivacyTermsSheet(context, loc),
                  ),
                  const SizedBox(height: 10),
                  _ProfileMenuTile(
                    icon: Icons.headset_mic_outlined,
                    title: loc.tr('support_help'),
                    subtitle: loc.isArabic
                        ? 'تواصل مع فريق الدعم والكونسيرج الموحد'
                        : 'Contact Aesthetic Way concierge support',
                    onTap: () => _showSupportSheet(context, loc),
                  ),
                  const SizedBox(height: 20),

                  SilverButton(
                    label: loc.tr('logout_btn'),
                    variant: SilverButtonVariant.secondary,
                    icon: Icons.logout_rounded,
                    isFullWidth: true,
                    onPressed: () {
                      auth.logout();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.isArabic ? 'تم تسجيل الخروج بنجاح' : 'Logged out successfully'),
                          backgroundColor: AppColors.surface(context),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
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
                      color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.15 : 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.palette_outlined, color: AppColors.accentChampagne, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loc.tr('theme_title'),
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
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
                    label: loc.isArabic ? '🌙 داكن' : '🌙 Dark',
                    isSelected: currentMode == ThemeMode.dark,
                    onTap: () => themeService.setThemeMode(ThemeMode.dark),
                  ),
                  const SizedBox(width: 8),
                  _ThemePill(
                    label: loc.isArabic ? '☀️ فاتح فاخر' : '☀️ Light',
                    isSelected: currentMode == ThemeMode.light,
                    onTap: () => themeService.setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(width: 8),
                  _ThemePill(
                    label: loc.isArabic ? '📱 تلقائي' : '📱 System',
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
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary)
                : (isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.accentChampagne
                  : AppColors.border(context),
              width: isSelected ? 1.0 : 0.7,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isSelected
                    ? (isDark ? AppColors.backgroundDeep : Colors.white)
                    : (isDark ? AppColors.silverSecondary : AppColors.lightTextSecondary),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11.5,
              ),
            ),
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
              color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.15 : 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.language_rounded, color: AppColors.accentChampagne, size: 18),
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
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  loc.isArabic ? 'العربية (Arabic - RTL)' : 'English (LTR)',
                  style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border(context), width: 0.8),
            ),
            child: Text(
              loc.tr('switch_language'),
              style: AppTypography.caption.copyWith(
                color: AppColors.accentChampagne,
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
              color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border(context), width: 0.8),
            ),
            child: Icon(icon, color: isDark ? AppColors.silverSecondary : AppColors.lightTextPrimary, size: 18),
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
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.mutedText(context)),
        ],
      ),
    );
  }
}
