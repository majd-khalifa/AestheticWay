import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';

/// Clinic Tab 3: Clinic Offers & Treatment Packages Manager
class ClinicOffersScreen extends StatelessWidget {
  const ClinicOffersScreen({super.key});

  void _showAddOfferDialog(BuildContext context, LocaleService loc) {
    final titleController = TextEditingController();
    final originalPriceController = TextEditingController();
    final offerPriceController = TextEditingController();
    final validityController = TextEditingController(text: 'صالح حتى نهاية الشهر');
    final termsController = TextEditingController();
    final isDark = AppColors.isDark(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDeep : AppColors.lightCardSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.border(ctx), width: 0.8)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.mutedText(ctx).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.tr('clinic_add_offer_title'),
                  style: AppTypography.cardTitle.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                TextField(
                  controller: titleController,
                  style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: loc.tr('clinic_offer_title_field'),
                    labelStyle: TextStyle(color: AppColors.mutedText(ctx), fontSize: 12),
                    filled: true,
                    fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accentChampagne, width: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Prices Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: originalPriceController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: loc.tr('clinic_offer_original_price'),
                          labelStyle: TextStyle(color: AppColors.mutedText(ctx), fontSize: 12),
                          filled: true,
                          fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.accentChampagne, width: 1.4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: offerPriceController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: loc.tr('clinic_offer_discount_price'),
                          labelStyle: TextStyle(color: AppColors.mutedText(ctx), fontSize: 12),
                          filled: true,
                          fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.accentChampagne, width: 1.4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Expiry Date Text
                TextField(
                  controller: validityController,
                  style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: loc.tr('clinic_offer_validity'),
                    labelStyle: TextStyle(color: AppColors.mutedText(ctx), fontSize: 12),
                    filled: true,
                    fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accentChampagne, width: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Terms / Description
                TextField(
                  controller: termsController,
                  maxLines: 2,
                  style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: loc.tr('clinic_offer_desc_field'),
                    labelStyle: TextStyle(color: AppColors.mutedText(ctx), fontSize: 12),
                    filled: true,
                    fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accentChampagne, width: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                SilverButton(
                  label: loc.tr('clinic_offer_save'),
                  icon: Icons.check_circle_outline,
                  isFullWidth: true,
                  height: 46,
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;
                    final origPrice = double.tryParse(originalPriceController.text) ?? 1500;
                    final offPrice = double.tryParse(offerPriceController.text) ?? 999;
                    final discount = origPrice > 0 ? (((origPrice - offPrice) / origPrice) * 100).round() : 25;

                    final newOffer = OfferModel(
                      id: 'off-${DateTime.now().millisecondsSinceEpoch}',
                      titleAr: titleController.text.trim(),
                      titleEn: titleController.text.trim(),
                      clinicId: ClinicPortalService().activeClinic.id,
                      clinicNameAr: ClinicPortalService().activeClinic.nameAr,
                      clinicNameEn: ClinicPortalService().activeClinic.nameEn,
                      originalPrice: origPrice,
                      offerPrice: offPrice,
                      discountPercentage: discount > 0 ? discount : 20,
                      validUntilText: validityController.text.trim(),
                      validUntilTextEn: validityController.text.trim(),
                      daysRemaining: 30,
                      termsAr: termsController.text.trim().isEmpty ? 'يشمل الفحص والاستشارة المجانية.' : termsController.text.trim(),
                      termsEn: termsController.text.trim().isEmpty ? 'Includes free initial consultation.' : termsController.text.trim(),
                      imageUrl: 'https://images.unsplash.com/photo-1512290900672-1f02e604ec22?auto=format&fit=crop&w=600&q=80',
                    );

                    ClinicPortalService().addOffer(newOffer);
                    Navigator.pop(ctx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.tr('clinic_offer_saved_success')),
                        backgroundColor: AppColors.accentChampagne,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final clinicService = ClinicPortalService();
    final isDark = AppColors.isDark(context);

    return ListenableBuilder(
      listenable: Listenable.merge([loc, clinicService]),
      builder: (context, _) {
        final offers = clinicService.clinicOffers;

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Text(
              loc.tr('clinic_nav_offers'),
              style: AppTypography.screenTitle.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
              ),
            ),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentChampagne),
                tooltip: loc.tr('clinic_btn_add_offer'),
                onPressed: () => _showAddOfferDialog(context, loc),
              ),
            ],
          ),
          body: offers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_offer_outlined, size: 48, color: AppColors.mutedText(context)),
                      const SizedBox(height: 12),
                      Text(
                        loc.tr('clinic_no_offers'),
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedText(context)),
                      ),
                      const SizedBox(height: 16),
                      SilverButton(
                        label: loc.tr('clinic_btn_add_offer'),
                        icon: Icons.add,
                        height: 40,
                        onPressed: () => _showAddOfferDialog(context, loc),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LuxuryCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    offer.imageUrl,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 64,
                                      height: 64,
                                      color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                                      child: const Icon(Icons.local_offer, color: AppColors.accentChampagne),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.isArabic ? offer.titleAr : offer.titleEn,
                                        style: AppTypography.cardTitle.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '${offer.offerPrice.toInt()} ${loc.tr('currency_aed')}',
                                            style: AppTypography.cardTitle.copyWith(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.accentChampagne,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${offer.originalPrice.toInt()} ${loc.tr('currency_aed')}',
                                            style: AppTypography.caption.copyWith(
                                              decoration: TextDecoration.lineThrough,
                                              color: AppColors.mutedText(context),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentChampagne.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '-${offer.discountPercentage}%',
                                              style: AppTypography.badge.copyWith(
                                                color: AppColors.accentChampagne,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.accentChampagne),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    loc.isArabic ? offer.validUntilText : (offer.validUntilTextEn ?? offer.validUntilText),
                                    style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 11.5),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.errorRed),
                                  tooltip: 'Delete',
                                  onPressed: () {
                                    clinicService.deleteOffer(offer.id);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddOfferDialog(context, loc),
            backgroundColor: AppColors.accentChampagne,
            foregroundColor: AppColors.backgroundDeep,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              loc.tr('clinic_btn_add_offer'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ),
        );
      },
    );
  }
}
