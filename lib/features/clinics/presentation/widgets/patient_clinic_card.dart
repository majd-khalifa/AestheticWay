import '../../../../core/theme/patient_design.dart';
import '../../../../core/widgets/silver_button.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/clinic_location.dart';
import '../../../../core/utils/entity_id.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/widgets/luxury_image.dart';
import '../../../../core/widgets/patient_media_banner.dart';
import '../../../../core/widgets/async_action_button.dart';
import '../../models/clinic_model.dart';
import 'google_clinic_rating.dart';

class PatientClinicCard extends StatelessWidget {
  const PatientClinicCard({
    super.key,
    required this.clinic,
    required this.onTap,
    this.onRequest,
    this.onRequestAction,
    this.onContact,
    this.showCover = true,
    this.media,
    this.compact = false,
  });
  final ClinicModel clinic;
  final bool showCover, compact;
  final Widget? media;
  final VoidCallback onTap;
  final VoidCallback? onRequest, onContact;
  final AsyncPatientAction? onRequestAction;
  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final location = formatClinicLocation(
      clinic.city,
      loc.isArabic ? clinic.areaAr : clinic.areaEn,
      arabic: loc.isArabic,
    );
    final description = loc.isArabic
        ? clinic.descriptionAr
        : clinic.descriptionEn;
    return LuxuryCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      borderRadius: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showCover)
              media ??
                  PatientMediaBanner(
                    source: clinic.primaryPhotoUrl,
                    aspectRatio: 3 / 2,
                  ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: LuxuryImage(
                          imageUrl: clinic.logoUrl,
                          width: 46,
                          height: 46,
                          fit: BoxFit.contain,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.isArabic ? clinic.nameAr : clinic.nameEn,
                              style: PatientDesign.heading(
                                context,
                                size: compact ? 18 : 21,
                              ),
                            ),
                            if (location.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: AppColors.subtext(context),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        location,
                                        style: TextStyle(
                                          color: AppColors.subtext(context),
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  GoogleClinicRating(clinic: clinic),
                  if (!compact && description.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.subtext(context),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SilverButton(
                    label: loc.isArabic ? 'اكتشف العيادة' : 'Explore clinic',
                    onPressed: onTap,
                    icon: Icons.arrow_forward_rounded,
                    isFullWidth: true,
                  ),
                  if (!compact &&
                      (onRequestAction != null ||
                          onRequest != null ||
                          onContact != null))
                    Row(
                      children: [
                        if (onRequestAction != null || onRequest != null)
                          Expanded(
                            child: onRequestAction != null
                                ? AsyncActionButton(
                                    label: loc.tr('request_consultation'),
                                    onPressed: isEntityUuid(clinic.id)
                                        ? onRequestAction
                                        : null,
                                    variant: SilverButtonVariant.textOnly,
                                  )
                                : TextButton(
                                    onPressed: onRequest,
                                    child: Text(loc.tr('request_consultation')),
                                  ),
                          ),
                        if (onContact != null)
                          IconButton(
                            onPressed: onContact,
                            tooltip: loc.tr('contact_btn'),
                            icon: const Icon(Icons.phone_outlined, size: 20),
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
