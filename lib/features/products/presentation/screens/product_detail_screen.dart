import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/features/clinics/data/clinics_repository.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinic_profile_screen.dart';

/// Product Detail Screen for Aesthetic & Medical Skincare (Brand Showcase Advertisement Only)
/// Strictly NO price display, NO cart, NO checkout, NO in-app payments.
class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;
  final ClinicsRepository? clinicsRepository;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.clinicsRepository,
  });

  Future<ClinicModel> _resolveClinic() async {
    if (product.clinicId.trim().isNotEmpty) {
      try {
        final repo = clinicsRepository ?? ClinicsRepository();
        final detail = await repo.getClinicDetail(product.clinicId);
        if (detail.id.isNotEmpty) {
          return detail;
        }
      } catch (_) {}
    }

    return ClinicModel(
      id: product.clinicId.isNotEmpty ? product.clinicId : 'clinic-id',
      nameAr: product.clinicNameAr.isNotEmpty
          ? product.clinicNameAr
          : (product.clinicNameEn ?? 'العيادة الطبية'),
      nameEn: product.clinicNameEn?.isNotEmpty == true
          ? product.clinicNameEn!
          : (product.clinicNameAr.isNotEmpty ? product.clinicNameAr : 'Medical Clinic'),
      descriptionAr: '',
      descriptionEn: '',
      coverImageUrl: product.imageUrl,
      galleryImages: const [],
      logoUrl: product.imageUrl,
      rating: 4.9,
      reviewCount: 0,
      subscriptionTier: SubscriptionTier.basic,
      licenseAuthority: '',
      licenseNumber: '',
      city: 'Dubai',
      areaAr: 'دبي',
      areaEn: 'Dubai',
      addressAr: 'دبي',
      addressEn: 'Dubai',
      distanceKm: 0,
      mainPhone: '',
      receptionPhone: '',
      whatsapp: '',
      latitude: 25.2048,
      longitude: 55.2708,
      workingHoursAr: '',
      workingHoursEn: '',
      branches: const [],
      practitionerIds: const [],
      treatmentIds: const [],
      featuredOffers: const [],
    );
  }

  Future<void> _handleOpenClinic(BuildContext context) async {
    final clinic = await _resolveClinic();
    if (context.mounted) {
      Navigator.push(
        context,
        LuxuryPageRoute(page: ClinicProfileScreen(clinic: clinic)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);
    final categoryLabel = loc.isArabic ? product.categoryAr : product.categoryEn;
    final brandTitle = loc.isArabic
        ? (product.brandNameAr?.isNotEmpty == true
            ? product.brandNameAr!
            : (product.brandNameEn?.isNotEmpty == true
                ? product.brandNameEn!
                : product.clinicNameAr))
        : (product.brandNameEn?.isNotEmpty == true
            ? product.brandNameEn!
            : (product.brandNameAr?.isNotEmpty == true
                ? product.brandNameAr!
                : (product.clinicNameEn ?? product.clinicNameAr)));
    final sponsorTitle = product.sponsorCompany?.trim();
    final hasClinicInfo = product.clinicNameAr.isNotEmpty || (product.clinicNameEn?.isNotEmpty ?? false);
    final hasBrandOrClinicInfo = hasClinicInfo || brandTitle.isNotEmpty || (sponsorTitle?.isNotEmpty == true);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        title: Text(
          loc.isArabic ? product.nameAr : product.nameEn,
          style: AppTypography.screenTitle.copyWith(
            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
            fontSize: 15.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Product Hero Image
          LuxuryImage(
            imageUrl: product.imageUrl,
            fallbackLogoUrl: product.clinicLogoUrl,
            height: 220,
            width: double.infinity,
            borderRadius: BorderRadius.circular(18),
            placeholderIcon: Icons.shopping_bag_outlined,
            iconSize: 48,
          ),
          const SizedBox(height: 16),

          // Main Info Card
          LuxuryCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (categoryLabel.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.15 : 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          categoryLabel,
                          style: const TextStyle(
                            color: AppColors.accentChampagne,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: product.isAvailable
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.isAvailable ? loc.tr('product_available') : loc.tr('product_out_of_stock'),
                        style: TextStyle(
                          color: product.isAvailable ? const Color(0xFF10B981) : Colors.redAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                if (brandTitle.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    brandTitle,
                    style: const TextStyle(
                      color: AppColors.accentChampagne,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  loc.isArabic ? product.nameAr : product.nameEn,
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  loc.isArabic ? product.descriptionAr : product.descriptionEn,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 13,
                    color: AppColors.subtext(context),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Providing Clinic / Brand Showcase Card
          if (hasBrandOrClinicInfo)
            LuxuryCard(
              onTap: hasClinicInfo ? () => _handleOpenClinic(context) : null,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: AppColors.accentChampagne, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.isArabic ? 'العلامة / الجهة الراعية' : 'Brand / Sponsor',
                          style: TextStyle(color: AppColors.mutedText(context), fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sponsorTitle != null && sponsorTitle.isNotEmpty
                              ? (brandTitle.isNotEmpty ? '$brandTitle • $sponsorTitle' : sponsorTitle)
                              : (brandTitle.isNotEmpty
                                  ? brandTitle
                                  : (loc.isArabic
                                      ? product.clinicNameAr
                                      : (product.clinicNameEn ?? product.clinicNameAr))),
                          style: TextStyle(
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasClinicInfo)
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.accentChampagne),
                ],
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
