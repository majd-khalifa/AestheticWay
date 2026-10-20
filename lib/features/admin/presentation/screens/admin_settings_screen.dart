import 'package:flutter/material.dart';
import '../../../../core/auth/guest_auth_guard.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_service.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../widgets/admin_components.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      LocaleService(),
      ThemeService(),
      AuthState(),
    ]),
    builder: (context, _) {
      final auth = AuthState(),
          theme = ThemeService(),
          locale = LocaleService();
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        appBar: AppBar(title: Text(locale.tr('admin_settings_title'))),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            LuxuryCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.admin_panel_settings_outlined,
                    color: AppColors.goldText(context),
                    size: 28,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auth.userName.isEmpty
                        ? adminText('Super Administrator', 'مدير المنصة العام')
                        : auth.userName,
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  if (auth.userEmail.isNotEmpty || auth.userPhone.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        auth.userEmail.isNotEmpty
                            ? auth.userEmail
                            : auth.userPhone,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: AppColors.mutedText(context)),
                      ),
                    ),
                ],
              ),
            ),
            AdminSectionTitle(locale.tr('theme_title')),
            DropdownButtonFormField<ThemeMode>(
              initialValue: theme.themeMode,
              isExpanded: true,
              decoration: InputDecoration(labelText: locale.tr('theme_title')),
              items: [
                for (final (mode, label) in [
                  (ThemeMode.light, locale.tr('theme_light')),
                  (ThemeMode.dark, locale.tr('theme_dark')),
                  (ThemeMode.system, locale.tr('theme_system')),
                ])
                  DropdownMenuItem(value: mode, child: Text(label)),
              ],
              onChanged: (mode) {
                if (mode != null) theme.setThemeMode(mode);
              },
            ),
            AdminSectionTitle(locale.tr('app_language')),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                for (final language in AppLanguage.values)
                  ChoiceChip(
                    label: Text(language.label),
                    selected: locale.currentLanguage == language,
                    onSelected: (_) => locale.setLanguage(language),
                  ),
              ],
            ),
            AdminSectionTitle(
              adminText('Privacy & supervision', 'الخصوصية والمتابعة'),
            ),
            AdminNotice(message: locale.tr('admin_lead_monitoring_note')),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () async {
                await AuthRepository().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(locale.tr('admin_logout')),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dangerText(context),
              ),
            ),
          ],
        ),
      );
    },
  );
}
