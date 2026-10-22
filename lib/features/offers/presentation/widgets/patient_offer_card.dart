import 'package:aesthetic_way/core/widgets/patient_image.dart';
import '../../../../core/theme/patient_design.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/widgets/async_action_button.dart';
import '../../../../core/widgets/silver_button.dart';
import '../../models/offer_model.dart';

class PatientOfferCard extends StatelessWidget {
  const PatientOfferCard({
    super.key,
    required this.offer,
    this.onInquiry,
    this.onInquiryAction,
    this.onClinicAction,
    this.onClinicTap,
    this.compact = false,
  });
  final OfferModel offer;
  final VoidCallback? onInquiry;
  final AsyncPatientAction? onInquiryAction, onClinicAction;
  final VoidCallback? onClinicTap;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final clinic = loc.isArabic
        ? offer.clinicNameAr
        : (offer.clinicNameEn ?? offer.clinicNameAr);
    final description = loc.isArabic ? offer.termsAr : offer.termsEn;
    final copy = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (clinic.isNotEmpty && onClinicAction != null)
            AsyncActionButton(
              label: clinic,
              loadingLabel: loc.isArabic
                  ? 'جارٍ تحميل العيادة'
                  : 'Loading clinic',
              errorLabel: loc.isArabic
                  ? 'تعذر تحميل العيادة. حاول مجدداً.'
                  : 'Clinic unavailable. Please try again.',
              onPressed: onClinicAction,
              variant: SilverButtonVariant.textOnly,
            )
          else if (clinic.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: InkWell(
                onTap: onClinicTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    clinic,
                    style: TextStyle(
                      color: AppColors.goldText(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          Text(
            loc.isArabic ? offer.titleAr : offer.titleEn,
            style: PatientDesign.heading(context, size: compact ? 18 : 21),
          ),
          if (description?.trim().isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                description!,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.subtext(context),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (offer.offerPrice > 0)
                Text(
                  '${offer.offerPrice.toStringAsFixed(0)} ${loc.tr('currency_aed')}',
                  style: TextStyle(
                    color: AppColors.text(context),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (offer.originalPrice > offer.offerPrice &&
                  offer.offerPrice > 0)
                Text(
                  '${offer.originalPrice.toStringAsFixed(0)} ${loc.tr('currency_aed')}',
                  style: TextStyle(
                    color: AppColors.subtext(context),
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              if (offer.discountPercentage > 0)
                Text(
                  '${loc.tr('save_prefix')} ${offer.discountPercentage}%',
                  style: TextStyle(
                    color: AppColors.goldText(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (offer.endsAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                loc.isArabic
                    ? offer.validUntilText
                    : (offer.validUntilTextEn ?? ''),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.subtext(context),
                ),
              ),
            ),
          const SizedBox(height: 10),
          if (onInquiryAction != null)
            AsyncActionButton(
              label: loc.isArabic ? 'استفسر عن العرض' : 'Inquire about offer',
              loadingLabel: loc.isArabic
                  ? 'جارٍ تحميل العيادة'
                  : 'Loading clinic',
              errorLabel: loc.isArabic
                  ? 'تعذر تحميل العيادة. حاول مجدداً.'
                  : 'Clinic unavailable. Please try again.',
              onPressed: onInquiryAction,
              icon: Icons.chat_bubble_outline,
            )
          else
            FilledButton.icon(
              onPressed: onInquiry,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: Text(loc.tr('offer_claim')),
            ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final split =
            constraints.maxWidth >= 290 &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.3;
        return LuxuryCard(
          padding: EdgeInsets.zero,
          borderRadius: 18,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: split
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: constraints.maxWidth * .38,
                          child: PatientImage(
                            category: PatientMediaCategory.offer,
                            imageUrl: offer.imageUrl,
                            height: compact ? 150 : 190,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Expanded(child: copy),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PatientImage(
                        category: PatientMediaCategory.offer,
                        imageUrl: offer.imageUrl,
                        height: compact ? 150 : 190,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      copy,
                    ],
                  ),
          ),
        );
      },
    );
  }
}
