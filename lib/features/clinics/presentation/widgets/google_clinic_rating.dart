import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/widgets/rating_chip.dart';
import '../../models/clinic_model.dart';

/// Only ClinicModel's validated Google fields can enter this patient badge.
class GoogleClinicRating extends StatelessWidget {
  const GoogleClinicRating({super.key, required this.clinic});
  final ClinicModel clinic;
  @override
  Widget build(BuildContext context) {
    if (!clinic.hasGoogleRating) return const SizedBox.shrink();
    final uri = clinic.mapsUri;
    final badge = RatingChip(
      rating: clinic.googleRating,
      reviewCount: clinic.googleReviewsCount,
      showGoogleSource: true,
    );
    if (uri == null) return badge;
    return Semantics(
      button: true,
      label: LocaleService().isArabic
          ? 'تقييم Google، افتح الخرائط'
          : 'Google rating, open Maps',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            /* OS has no handler. */
          }
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            child: badge,
          ),
        ),
      ),
    );
  }
}
