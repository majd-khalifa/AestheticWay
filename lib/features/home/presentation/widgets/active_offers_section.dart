import 'package:flutter/material.dart';
import '../../../../core/widgets/async_action_button.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../offers/presentation/widgets/patient_offer_card.dart';

import '../../../offers/models/offer_model.dart';

class ActiveOffersSection extends StatelessWidget {
  const ActiveOffersSection({
    super.key,
    required this.offers,
    this.onOfferTap,
    this.onOfferAction,
  });
  final Future<void> Function(OfferModel, AsyncActionScope)? onOfferAction;
  final List<OfferModel> offers;
  final ValueChanged<OfferModel>? onOfferTap;
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
            style: TextStyle(
              fontSize: 22,
              fontFamily: loc.isArabic ? null : 'serif',
              fontWeight: FontWeight.w500,
              color: AppColors.text(context),
            ),
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
                    child: PatientOfferCard(
                      offer: offer,
                      compact: true,
                      onInquiry: onOfferTap == null
                          ? null
                          : () => onOfferTap!(offer),
                      onInquiryAction: onOfferAction == null
                          ? null
                          : (action) => onOfferAction!(offer, action),
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
