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

/// Photo, identity and actions form one composition. Compact placements retain
/// photography and identity without repeating every directory action.
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
    final hasPhoto =
        showCover &&
        (media != null || resolveImageProvider(clinic.primaryPhotoUrl) != null);
    Widget identity() => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            border: Border.all(color: AppColors.border(context)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: LuxuryImage(
            imageUrl: clinic.logoUrl,
            width: compact ? 38 : 48,
            height: compact ? 38 : 48,
            fit: BoxFit.contain,
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.isArabic ? clinic.nameAr : clinic.nameEn,
                style: PatientDesign.heading(context, size: compact ? 17 : 21),
              ),
              if (location.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    location,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: AppColors.subtext(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (compact)
          IconButton(
            onPressed: onTap,
            tooltip: loc.isArabic ? 'اكتشف العيادة' : 'Explore clinic',
            icon: Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: AppColors.goldText(context),
            ),
          ),
      ],
    );
    return LuxuryCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      borderRadius: 18,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasPhoto)
              media ??
                  PatientMediaBanner(
                    source: clinic.primaryPhotoUrl,
                    aspectRatio: 3 / 2,
                  ),
            if (showCover && !hasPhoto) const PatientMediaBanner(source: null),
            // The fine champagne rule joins a photograph to its identity panel.
            Container(
              height: 2,
              color: AppColors.goldText(context).withValues(alpha: .35),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 12 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  identity(),
                  GoogleClinicRating(clinic: clinic),
                  if (!compact && description.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: AppColors.subtext(context),
                        ),
                      ),
                    ),
                  if (!compact) ...[
                    const SizedBox(height: 12),
                    if (onRequestAction != null || onRequest != null)
                      onRequestAction != null
                          ? AsyncActionButton(
                              label: loc.tr('request_consultation'),
                              onPressed: isEntityUuid(clinic.id)
                                  ? onRequestAction
                                  : null,
                              icon: Icons.chat_bubble_outline,
                            )
                          : SilverButton(
                              label: loc.tr('request_consultation'),
                              onPressed: onRequest,
                            ),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: onTap,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 17,
                            ),
                            label: Text(
                              loc.isArabic ? 'اكتشف العيادة' : 'Explore clinic',
                            ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
