import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';

/// Active Medical Offers Section (Refined Luxury Aesthetic & Dual-Theme Bilingual)
class ActiveOffersSection extends StatelessWidget {
  final List<OfferModel> offers;
  final ValueChanged<OfferModel> onOfferTap;

  const ActiveOffersSection({
    super.key,
    required this.offers,
    required this.onOfferTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    if (offers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.12 : 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accentChampagne.withValues(alpha: 0.4),
                    width: 0.7,
                  ),
                ),
                child: const Icon(
                  Icons.local_offer_outlined,
                  size: 15,
                  color: AppColors.accentChampagne,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                loc.tr('active_offers'),
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 172,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: offers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final offer = offers[index];
                return _OfferCard(
                  offer: offer,
                  loc: loc,
                  onTap: () => onOfferTap(offer),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final OfferModel offer;
  final LocaleService loc;
  final VoidCallback onTap;

  const _OfferCard({
    required this.offer,
    required this.loc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return SizedBox(
      width: 254,
      child: LuxuryCard(
        padding: EdgeInsets.zero,
        borderRadius: 18,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Image & Expiry Tag
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    offer.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          (isDark ? AppColors.cardSurface : AppColors.lightCardSurface).withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${loc.isArabic ? "خصم" : "SAVE"} ${offer.discountPercentage}%',
                        style: AppTypography.badge.copyWith(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 7,
                    left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, size: 10, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            loc.isArabic
                                ? '${offer.daysRemaining} أيام متبقية'
                                : '${offer.daysRemaining} days left',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.isArabic ? offer.titleAr : offer.titleEn,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                            fontSize: 12.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          loc.isArabic ? offer.clinicNameAr : (offer.clinicNameEn ?? offer.clinicNameAr),
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.silverMuted : AppColors.lightTextMuted,
                            fontSize: 10.5,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${offer.offerPrice.toInt()} ${loc.isArabic ? "د.إ" : "AED"}',
                              style: AppTypography.cardTitle.copyWith(
                                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${offer.originalPrice.toInt()} ${loc.isArabic ? "د.إ" : "AED"}',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.silverMuted : AppColors.lightTextMuted,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: isDark ? AppColors.silverSecondary : AppColors.lightTextSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
