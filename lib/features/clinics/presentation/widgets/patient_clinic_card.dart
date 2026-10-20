import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/clinic_location.dart';
import '../../../../core/utils/entity_id.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/widgets/luxury_image.dart';
import '../../../../core/widgets/patient_media_banner.dart';
import '../../models/clinic_model.dart';
import 'google_clinic_rating.dart';

class PatientClinicCard extends StatelessWidget {
  const PatientClinicCard({
    super.key,
    required this.clinic,
    required this.onTap,
    this.onRequest,
    this.onContact,
    this.showCover = true,
  });
  final ClinicModel clinic;
  final bool showCover;
  final VoidCallback onTap;
  final VoidCallback? onRequest, onContact;
  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final area = loc.isArabic ? clinic.areaAr : clinic.areaEn;
    final location = formatClinicLocation(
      clinic.city,
      area,
      arabic: loc.isArabic,
    );
    return LuxuryCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      borderRadius: 22,
      isVip: clinic.isEligibleForTopCarousel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showCover)
              PatientMediaBanner(source: clinic.coverImageUrl, height: 156),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle(context),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: LuxuryImage(
                          imageUrl: clinic.logoUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (clinic.isEligibleForTopCarousel)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  clinic.subscriptionTier ==
                                          SubscriptionTier.vipPlatinum
                                      ? 'VIP'
                                      : (loc.isArabic
                                            ? 'عيادة مميزة'
                                            : 'FEATURED CLINIC'),
                                  style: TextStyle(
                                    color: AppColors.goldText(context),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: loc.isArabic ? 0 : 1,
                                  ),
                                ),
                              ),
                            Text(
                              loc.isArabic ? clinic.nameAr : clinic.nameEn,
                              style: TextStyle(
                                color: AppColors.text(context),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                            if (clinic.city.trim().isNotEmpty ||
                                area.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 7),
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    color: AppColors.subtext(context),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            GoogleClinicRating(clinic: clinic),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (onRequest != null)
                    FilledButton.icon(
                      onPressed: isEntityUuid(clinic.id) ? onRequest : null,
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: Text(loc.tr('request_consultation')),
                    ),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        onPressed: onTap,
                        child: Text(
                          loc.isArabic ? 'اكتشف العيادة' : 'Explore clinic',
                        ),
                      ),
                      if (onContact != null &&
                          (clinic.hasPhone ||
                              clinic.hasWhatsapp ||
                              clinic.hasMapLocation))
                        TextButton(
                          onPressed: onContact,
                          child: Text(loc.tr('contact_btn')),
                        ),
                    ],
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
