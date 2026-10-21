import '../../../../core/theme/patient_design.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/widgets/luxury_image.dart';
import '../../../../core/widgets/practitioner_badge.dart';
import '../../../../core/widgets/async_action_button.dart';
import '../../models/practitioner_model.dart';

class PatientPractitionerCard extends StatelessWidget {
  const PatientPractitionerCard({
    super.key,
    required this.practitioner,
    required this.onTap,
    this.onInquiry,
    this.onInquiryAction,
  });
  final PractitionerModel practitioner;
  final VoidCallback onTap;
  final VoidCallback? onInquiry;
  final AsyncPatientAction? onInquiryAction;
  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final p = practitioner;
    final clinic = loc.isArabic
        ? p.clinicNameAr
        : (p.clinicNameEn ?? p.clinicNameAr);
    final specialty = loc.isArabic ? p.specialtyAr : p.specialtyEn;
    return LayoutBuilder(
      builder: (context, constraints) {
        final portraitWidth = (constraints.maxWidth * .36).clamp(90.0, 170.0);
        return LuxuryCard(
          onTap: onTap,
          padding: const EdgeInsets.all(12),
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LuxuryImage(
                    imageUrl: p.avatarUrl,
                    fallbackLogoUrl: p.clinicLogoUrl,
                    width: resolveImageProvider(p.avatarUrl) == null
                        ? 48
                        : portraitWidth,
                    height: resolveImageProvider(p.avatarUrl) == null
                        ? 48
                        : portraitWidth * 1.35,
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
                          style: PatientDesign.heading(context, size: 22),
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
              if (onInquiryAction != null)
                AsyncActionButton(
                  label: loc.tr('request_consultation'),
                  loadingLabel: loc.isArabic
                      ? 'جارٍ فتح الاستشارة'
                      : 'Opening consultation',
                  onPressed: onInquiryAction,
                  icon: Icons.chat_bubble_outline,
                )
              else if (onInquiry != null)
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
      },
    );
  }
}
