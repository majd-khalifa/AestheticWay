import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/utils/contact_launcher.dart';
import 'package:aesthetic_way/core/utils/maps_launcher.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';

/// Contact Options Sheet (Bottom Modal) adapting to Dark & Light Themes
class ContactOptionsSheet extends StatelessWidget {
  final ClinicModel clinic;

  const ContactOptionsSheet({super.key, required this.clinic});

  static Future<void> show(BuildContext context, ClinicModel clinic) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ContactOptionsSheet(clinic: clinic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundBase : AppColors.lightCardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.border(context), width: 0.8),
        ),
      ),
      child: SafeArea(
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
            const SizedBox(height: 16),
            Text(
              loc.isArabic
                  ? 'تواصل مباشر مع ${clinic.nameAr}'
                  : 'Direct Contact with ${clinic.nameEn}',
              style: AppTypography.cardTitle.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.isArabic
                  ? 'اختر وسيلة التواصل للتنسيق مع استقبال العيادة مباشرة'
                  : 'Choose your preferred channel to reach clinic reception directly',
              style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
            ),
            const SizedBox(height: 18),
            _ContactOptionTile(
              icon: Icons.phone_forwarded,
              title: loc.isArabic ? 'اتصال فوري بالاستقبال' : 'Call Reception',
              subtitle: clinic.receptionPhone,
              iconBgColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
              iconColor: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
              onTap: () {
                Navigator.pop(context);
                ContactLauncher.makePhoneCall(clinic.receptionPhone);
              },
            ),
            const SizedBox(height: 10),
            _ContactOptionTile(
              icon: Icons.chat_bubble_outline,
              title: loc.isArabic ? 'محادثة واتساب' : 'Chat on WhatsApp',
              subtitle: loc.isArabic ? 'رد مباشر من المنسق الطبي' : 'Direct response from coordinator',
              iconBgColor: const Color(0xFF064E3B).withValues(alpha: isDark ? 0.4 : 0.15),
              iconColor: const Color(0xFF10B981),
              onTap: () {
                Navigator.pop(context);
                ContactLauncher.openWhatsApp(phoneNumber: clinic.whatsapp);
              },
            ),
            const SizedBox(height: 10),
            _ContactOptionTile(
              icon: Icons.map_outlined,
              title: loc.tr('open_in_maps'),
              subtitle: '${loc.isArabic ? clinic.areaAr : clinic.areaEn} (${clinic.distanceKm} km)',
              iconBgColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
              iconColor: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
              onTap: () {
                Navigator.pop(context);
                MapsLauncher.openMapLocation(
                  latitude: clinic.latitude,
                  longitude: clinic.longitude,
                  placeId: clinic.googlePlaceId,
                  placeName: loc.isArabic ? clinic.nameAr : clinic.nameEn,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ContactOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardSurface : AppColors.lightCardSurfaceHover,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context), width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.mutedText(context)),
          ],
        ),
      ),
    );
  }
}
