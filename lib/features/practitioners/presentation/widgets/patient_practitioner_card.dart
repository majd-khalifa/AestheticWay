import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/widgets/luxury_image.dart';
import '../../../../core/widgets/practitioner_badge.dart';
import '../../models/practitioner_model.dart';

class PatientPractitionerCard extends StatelessWidget {
  const PatientPractitionerCard({
    super.key,
    required this.practitioner,
    required this.onTap,
    this.onInquiry,
  });
  final PractitionerModel practitioner;
  final VoidCallback onTap;
  final VoidCallback? onInquiry;
  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final p = practitioner;
    final clinic = loc.isArabic
        ? p.clinicNameAr
        : (p.clinicNameEn ?? p.clinicNameAr);
    final specialty = loc.isArabic ? p.specialtyAr : p.specialtyEn;
    return LuxuryCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LuxuryImage(
                imageUrl: p.avatarUrl,
                fallbackLogoUrl: p.clinicLogoUrl,
                width: 78,
                height: 102,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(14),
                placeholderIcon: Icons.person_outline,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PractitionerBadge(
                      type: p.type,
                      hasKnownType: p.hasKnownType,
                    ),
                    const SizedBox(height: 9),
                    Text(
                      loc.isArabic ? p.nameAr : p.nameEn,
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    if (specialty.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          specialty,
                          style: TextStyle(
                            color: AppColors.goldText(context),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (clinic.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                clinic,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.subtext(context),
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (onInquiry != null)
            FilledButton.icon(
              onPressed: onInquiry,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: Text(loc.tr('request_consultation')),
            )
          else
            OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                loc.isArabic ? 'الملف المهني' : 'View professional profile',
              ),
            ),
        ],
      ),
    );
  }
}
