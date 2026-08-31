import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/data/mock_data.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinic_profile_screen.dart';

/// Screen 1/8: Exclusive Aesthetic Offers & Packages
class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  String _searchQuery = '';

  Future<void> _handleClaimOffer(OfferModel offer) async {
    final mockData = MockDataService();
    final clinic = mockData.getClinicById(offer.clinicId);
    if (clinic == null) return;

    final auth = await GuestAuthGuard.requireAuth(
      context,
      reasonTitle: LocaleService().tr('offer_claim'),
      reasonSubtitle: LocaleService().isArabic
          ? 'سجّل دخولك برقم الهاتف للاستفادة من باقة العرض'
          : 'Login with phone number to claim this offer lead',
    );
    if (!auth || !mounted) return;

    Navigator.push(
      context,
      LuxuryPageRoute(
        page: AppointmentRequestScreen(
          clinic: clinic,
          selectedOfferTitle: LocaleService().isArabic ? offer.titleAr : offer.titleEn,
          selectedOfferId: offer.id,
        ),
      ),
    );
  }

  void _navigateToClinic(String clinicId) {
    final mockData = MockDataService();
    final clinic = mockData.getClinicById(clinicId);
    if (clinic != null) {
      Navigator.push(
        context,
        LuxuryPageRoute(page: ClinicProfileScreen(clinic: clinic)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final mockData = MockDataService();
    final isDark = AppColors.isDark(context);

    final filteredOffers = mockData.offers.where((o) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return o.titleAr.toLowerCase().contains(q) ||
          o.titleEn.toLowerCase().contains(q) ||
          o.clinicNameAr.toLowerCase().contains(q) ||
          (o.clinicNameEn != null && o.clinicNameEn!.toLowerCase().contains(q));
    }).toList();

    return ListenableBuilder(
      listenable: Listenable.merge([loc, mockData]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Text(
              loc.tr('category_offers_title'),
              style: AppTypography.screenTitle.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                fontSize: 16,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              // Search Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border(context), width: 0.8),
                  ),
                  child: TextField(
                    style: TextStyle(color: AppColors.text(context), fontSize: 13.5),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: loc.isArabic ? 'ابحث في العروض التجميلية والعيادات...' : 'Search offers & clinics...',
                      hintStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.mutedText(context), size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              // Offers List
              Expanded(
                child: filteredOffers.isEmpty
                    ? Center(
                        child: Text(
                          loc.isArabic ? 'لا توجد عروض متاحة حالياً' : 'No offers currently available',
                          style: TextStyle(color: AppColors.mutedText(context)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filteredOffers.length,
                        itemBuilder: (context, index) {
                          final offer = filteredOffers[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: LuxuryCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Offer Image & Discount Badge
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        child: Image.network(
                                          offer.imageUrl,
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            height: 160,
                                            color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                                            child: const Center(
                                              child: Icon(Icons.local_offer_rounded, color: AppColors.accentChampagne, size: 36),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 12,
                                        right: loc.isArabic ? 12 : null,
                                        left: loc.isArabic ? null : 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentChampagne,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.3),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            '${loc.tr("save_prefix")} ${offer.discountPercentage}%',
                                            style: const TextStyle(
                                              color: AppColors.backgroundDeep,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Details Body
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Clinic Name Clickable Link
                                        GestureDetector(
                                          onTap: () => _navigateToClinic(offer.clinicId),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.apartment_rounded, size: 14, color: AppColors.accentChampagne),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  loc.isArabic ? offer.clinicNameAr : (offer.clinicNameEn ?? offer.clinicNameAr),
                                                  style: TextStyle(
                                                    color: AppColors.accentChampagne,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),

                                        // Title
                                        Text(
                                          loc.isArabic ? offer.titleAr : offer.titleEn,
                                          style: AppTypography.cardTitle.copyWith(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Terms / Description
                                        Text(
                                          (loc.isArabic ? offer.termsAr : offer.termsEn) ?? '',
                                          style: AppTypography.bodyMedium.copyWith(
                                            fontSize: 12,
                                            color: AppColors.mutedText(context),
                                            height: 1.45,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),

                                        // Price & Action Row
                                        Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      '${offer.offerPrice.toInt()} ${loc.tr("currency_aed")}',
                                                      style: TextStyle(
                                                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w900,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '${offer.originalPrice.toInt()} ${loc.tr("currency_aed")}',
                                                      style: TextStyle(
                                                        color: AppColors.mutedText(context),
                                                        fontSize: 12,
                                                        decoration: TextDecoration.lineThrough,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  (loc.isArabic ? offer.validUntilText : (offer.validUntilTextEn ?? offer.validUntilText)),
                                                  style: const TextStyle(
                                                    color: AppColors.accentChampagne,
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Spacer(),
                                            SilverButton(
                                              label: loc.tr('offer_claim'),
                                              icon: Icons.send_rounded,
                                              height: 38,
                                              onPressed: () => _handleClaimOffer(offer),
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
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
