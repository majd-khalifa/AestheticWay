import '../widgets/product_inquiry_bottom_sheet.dart';
import '../../../../core/widgets/silver_button.dart';
import '../../../../core/utils/entity_id.dart';
import '../widgets/brand_product_media.dart';
import '../../../../core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
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

  Future<ClinicModel?> _resolveClinic() async {
    if (product.clinicId.trim().isNotEmpty) {
      try {
        final repo = clinicsRepository ?? ClinicsRepository();
        final detail = await repo.getClinicDetail(product.clinicId);
        if (detail.id.isNotEmpty) {
          return detail;
        }
      } catch (_) {}
    }

    return null;
  }

  Future<void> _handleOpenClinic(BuildContext context) async {
    final clinic = await _resolveClinic();
    if (!context.mounted) return;
    if (clinic == null) {
      showAppSnackBar(
        context,
        LocaleService().isArabic
            ? 'تعذر تحميل بيانات العيادة حالياً'
            : 'Clinic details are unavailable right now.',
        type: AppSnackBarType.error,
      );
      return;
    }
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
    final brandTitle = productBrandLabel(product, loc);
    final sponsorTitle = product.sponsorCompany?.trim();
    final hasClinicInfo =
        product.clinicNameAr.isNotEmpty ||
        (product.clinicNameEn?.isNotEmpty ?? false);
    final hasBrandOrClinicInfo =
        brandTitle.isNotEmpty || (sponsorTitle?.isNotEmpty == true);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        title: Text(
          loc.isArabic ? 'عرض العلامة التجارية' : 'Brand showcase',
          style: AppTypography.screenTitle.copyWith(
            color: isDark
                ? AppColors.silverPrimary
                : AppColors.lightTextPrimary,
            fontSize: 15.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark
                ? AppColors.silverPrimary
                : AppColors.lightTextPrimary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          AspectRatio(
            aspectRatio: 1.05,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BrandProductMedia(product: product, hero: true),
            ),
          ),
          const SizedBox(height: 28),
          if (brandTitle.isNotEmpty)
            Text(
              brandTitle,
              style: TextStyle(
                color: AppColors.goldText(context),
                fontSize: 11.5,
                letterSpacing: loc.isArabic ? 0 : 1.2,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 10),
          Text(
            loc.isArabic ? product.nameAr : product.nameEn,
            style: TextStyle(
              fontFamily: loc.isArabic ? null : 'serif',
              fontSize: 28,
              height: 1.4,
              color: AppColors.text(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Divider(height: 1, thickness: 0.7, color: AppColors.border(context)),
          const SizedBox(height: 24),
          Text(
            loc.isArabic ? product.descriptionAr : product.descriptionEn,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.subtext(context),
              height: 1.8,
            ),
          ),
          const SizedBox(height: 28),

          // Providing Clinic / Brand Showcase Card
          if (hasBrandOrClinicInfo)
            LuxuryCard(
              onTap: null,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(
                    Icons.business_outlined,
                    color: AppColors.accentChampagne,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.isArabic
                              ? 'العلامة / الجهة الراعية'
                              : 'Brand / Sponsor',
                          style: TextStyle(
                            color: AppColors.mutedText(context),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sponsorTitle != null && sponsorTitle.isNotEmpty
                              ? (brandTitle.isNotEmpty
                                    ? '$brandTitle • $sponsorTitle'
                                    : sponsorTitle)
                              : brandTitle,

                          style: TextStyle(
                            color: isDark
                                ? AppColors.silverPrimary
                                : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (hasClinicInfo)
            TextButton(
              onPressed: () => _handleOpenClinic(context),
              child: Text(
                loc.isArabic ? 'العيادة المعلنة' : 'Advertising clinic',
              ),
            ),
          const SizedBox(height: 24),
          SilverButton(
            label: loc.tr('product_inquiry_btn'),
            icon: Icons.chat_bubble_outline,
            onPressed: isEntityUuid(product.id)
                ? () =>
                      ProductInquiryBottomSheet.show(context, product: product)
                : null,
          ),
        ],
      ),
    );
  }
}
