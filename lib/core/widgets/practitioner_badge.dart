import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';

/// Distinct Practitioner Type Badge (Refined Luxury Medical Style & Fully Bilingual)
class PractitionerBadge extends StatelessWidget {
  final PractitionerType type;
  final bool showIcon;
  final bool hasKnownType;

  const PractitionerBadge({
    super.key,
    required this.type,
    this.showIcon = true,
    this.hasKnownType = true,
  });

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);
    Color bg;
    Color border;
    Color textColor;
    String label;
    IconData icon;

    switch (type) {
      case PractitionerType.doctor:
        bg = isDark
            ? const Color(0xFF172554).withValues(alpha: 0.75)
            : const Color(0xFFEFF6FF);
        border = isDark
            ? AppColors.medicalBlue.withValues(alpha: 0.65)
            : const Color(0xFF93C5FD);
        textColor = isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1E3A8A);
        label = loc.tr('role_doctor');
        icon = Icons.medical_services_outlined;
        break;
      case PractitionerType.nurse:
        bg = isDark
            ? const Color(0xFF042F2E).withValues(alpha: 0.75)
            : const Color(0xFFF0FDFA);
        border = isDark
            ? AppColors.nurseTeal.withValues(alpha: 0.65)
            : const Color(0xFF5EEAD4);
        textColor = isDark ? const Color(0xFF99F6E4) : const Color(0xFF115E59);
        label = loc.tr('role_nurse');
        icon = Icons.health_and_safety_outlined;
        break;
      case PractitionerType.licensedProfessional:
        bg = isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.75)
            : const Color(0xFFF1F5F9);
        border = isDark
            ? AppColors.silverBorder.withValues(alpha: 0.5)
            : const Color(0xFFCBD5E1);
        textColor = isDark ? AppColors.silverPrimary : const Color(0xFF0A0E17);
        label = loc.tr('role_specialist');
        icon = Icons.spa_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.7),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 4,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            hasKnownType ? label : (loc.isArabic ? 'ممارس' : 'Practitioner'),
            style: AppTypography.badge.copyWith(
              color: textColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
