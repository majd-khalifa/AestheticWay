import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/clinic_location.dart';
import '../../../../core/utils/entity_id.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/widgets/luxury_image.dart';
import '../../models/clinic_model.dart';
import 'google_clinic_rating.dart';

/// One compact, content-sized clinic presentation shared by discovery surfaces.
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
    final hasLocation = clinic.city.trim().isNotEmpty || area.trim().isNotEmpty;
    return LuxuryCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showCover && clinic.coverImageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LuxuryImage(
                imageUrl: clinic.coverImageUrl,
                fallbackLogoUrl: clinic.logoUrl,
                height: 112,
                width: double.infinity,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LuxuryImage(
                imageUrl: clinic.logoUrl,
                width: 64,
                height: 64,
                fit: BoxFit.contain,
                borderRadius: BorderRadius.circular(12),
                placeholderIcon: Icons.local_hospital_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.isArabic ? clinic.nameAr : clinic.nameEn,
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    if (hasLocation)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          formatClinicLocation(
                            clinic.city,
                            area,
                            arabic: loc.isArabic,
                          ),
                          style: TextStyle(
                            color: AppColors.subtext(context),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (clinic.hasGoogleRating)
                      GoogleClinicRating(clinic: clinic),
                  ],
                ),
              ),
            ],
          ),
          if (clinic.isEligibleForTopCarousel)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                clinic.subscriptionTier == SubscriptionTier.vipPlatinum
                    ? (loc.isArabic ? 'شريك VIP' : 'VIP partner')
                    : (loc.isArabic ? 'شريك مميز' : 'Featured partner'),
                style: TextStyle(
                  color: AppColors.goldText(context),
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                onPressed: onTap,
                child: Text(loc.isArabic ? 'عرض العيادة' : 'View clinic'),
              ),
              if (onRequest != null)
                FilledButton.tonalIcon(
                  onPressed: isEntityUuid(clinic.id) ? onRequest : null,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text(loc.tr('request_consultation')),
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
    );
  }
}
