import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';

/// Distinct Practitioner Type Badge (Refined Luxury Medical Style & Fully Bilingual)
class PractitionerBadge extends StatelessWidget {
  final PractitionerType type;
  final bool showIcon;

  const PractitionerBadge({
    super.key,
    required this.type,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    Color bg;
    Color border;
    Color textColor;
    String label;
    String icon;

    switch (type) {
      case PractitionerType.doctor:
        bg = const Color(0xFF172554).withValues(alpha: 0.6);
        border = AppColors.medicalBlue.withValues(alpha: 0.6);
        textColor = const Color(0xFFBFDBFE);
        label = loc.tr('role_doctor');
        icon = '👨‍⚕️';
        break;
      case PractitionerType.nurse:
        bg = const Color(0xFF042F2E).withValues(alpha: 0.6);
        border = AppColors.nurseTeal.withValues(alpha: 0.6);
        textColor = const Color(0xFF99F6E4);
        label = loc.tr('role_nurse');
        icon = '👩‍⚕️';
        break;
      case PractitionerType.licensedProfessional:
        bg = const Color(0xFF1E293B).withValues(alpha: 0.6);
        border = AppColors.silverBorder.withValues(alpha: 0.4);
        textColor = AppColors.silverPrimary;
        label = loc.tr('role_specialist');
        icon = '🔬';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Text(icon, style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
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
