import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/theme/theme_service.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/login_screen.dart';

/// Super Admin Settings Screen with Platform Licensing, Theme & Language Controls, and Sign Out
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final themeService = ThemeService();
    final isDark = AppColors.isDark(context);

    return ListenableBuilder(
      listenable: Listenable.merge([loc, themeService]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Text(
              loc.tr('admin_settings_title'),
              style: AppTypography.screenTitle.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                fontSize: 16,
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
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // Super Admin Profile Banner
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                      child: const Icon(Icons.security_rounded, color: AppColors.accentChampagne, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.isArabic ? 'مدير المنصة العام (Super Admin)' : 'Super Administrator',
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'admin@aestheticway.ae',
                            style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Theme Switcher Tile
              LuxuryCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      themeService.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                      color: AppColors.accentChampagne,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.tr('theme_title'),
                        style: TextStyle(
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DropdownButton<ThemeMode>(
                      value: themeService.themeMode,
                      dropdownColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text(loc.tr('theme_dark'), style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text(loc.tr('theme_light'), style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text(loc.tr('theme_system'), style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) themeService.setThemeMode(mode);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Language Switcher Tile
              LuxuryCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.language_rounded, color: AppColors.accentChampagne),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.tr('app_language'),
                        style: TextStyle(
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => loc.toggleLanguage(),
                      child: Text(
                        loc.tr('switch_language'),
                        style: const TextStyle(color: AppColors.accentChampagne, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Platform Legal & Licensing Card
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_outlined, color: AppColors.accentChampagne, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          loc.tr('admin_license_info'),
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.tr('privacy_sheet_text'),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.mutedText(context),
                        fontSize: 11.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Logout Button
              SilverButton(
                label: loc.tr('admin_logout'),
                icon: Icons.logout_rounded,
                isFullWidth: true,
                height: 46,
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}
