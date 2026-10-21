import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/patient_design.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/widgets/patient_media_banner.dart';
import '../../models/treatment_model.dart';

class PatientTreatmentCard extends StatelessWidget {
  const PatientTreatmentCard({
    super.key,
    required this.treatment,
    required this.onTap,
  });
  final TreatmentModel treatment;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final ar = LocaleService().isArabic;
    final description = ar ? treatment.descriptionAr : treatment.descriptionEn;
    return LuxuryCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      borderRadius: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PatientMediaBanner(source: treatment.imageUrl, aspectRatio: 16 / 9),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ar ? treatment.categoryAr : treatment.categoryEn,
                    style: TextStyle(
                      color: AppColors.goldText(context),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ar ? treatment.nameAr : treatment.nameEn,
                    style: PatientDesign.heading(context, size: 21),
                  ),
                  if (description?.trim().isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        description!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.subtext(context),
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(ar ? 'اكتشف الإجراء' : 'Explore treatment'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
