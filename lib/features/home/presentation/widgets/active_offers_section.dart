import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/widgets/luxury_image.dart';
import '../../../offers/models/offer_model.dart';

class ActiveOffersSection extends StatelessWidget {
  const ActiveOffersSection({
    super.key,
    required this.offers,
    required this.onOfferTap,
  });
  final List<OfferModel> offers;
  final ValueChanged<OfferModel> onOfferTap;
  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return const SizedBox.shrink();
    final loc = LocaleService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            loc.tr('active_offers'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final offer in offers)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: SizedBox(
                    width: (MediaQuery.sizeOf(context).width - 48).clamp(
                      240,
                      320,
                    ),
                    child: LuxuryCard(
                      onTap: () => onOfferTap(offer),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (offer.imageUrl.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: LuxuryImage(
                                imageUrl: offer.imageUrl,
                                fallbackLogoUrl: offer.clinicLogoUrl,
                                height: 100,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          Text(
                            loc.isArabic ? offer.titleAr : offer.titleEn,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            loc.isArabic
                                ? offer.clinicNameAr
                                : (offer.clinicNameEn ?? offer.clinicNameAr),
                            style: TextStyle(color: AppColors.subtext(context)),
                          ),
                          if (offer.offerPrice > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                '${offer.offerPrice.toStringAsFixed(0)} ${loc.tr('currency_aed')}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          if (offer.endsAt != null)
                            Text(
                              loc.isArabic
                                  ? offer.validUntilText
                                  : (offer.validUntilTextEn ?? ''),
                              style: TextStyle(
                                color: AppColors.subtext(context),
                              ),
                            ),
                          TextButton.icon(
                            onPressed: () => onOfferTap(offer),
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              size: 18,
                            ),
                            label: Text(loc.tr('offer_claim')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
