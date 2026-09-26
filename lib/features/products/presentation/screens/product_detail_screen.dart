import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/features/clinics/data/clinics_repository.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinic_profile_screen.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';

/// Product Detail Screen for Aesthetic & Medical Skincare (Discovery & Lead Inquiry Only)
/// Strictly NO cart, NO checkout, NO in-app payments.
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
        return await repo.getClinicDetail(product.clinicId);
      } catch (_) {}
    }

    if (product.clinicNameAr.isNotEmpty || (product.clinicNameEn?.isNotEmpty ?? false)) {
      return ClinicModel(
        id: product.clinicId.isNotEmpty ? product.clinicId : 'clinic-id',
        nameAr: product.clinicNameAr.isNotEmpty
            ? product.clinicNameAr
            : (product.clinicNameEn ?? ''),
        nameEn: product.clinicNameEn ?? product.clinicNameAr,
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
        mainPhone: '+971500000000',
        receptionPhone: '+971500000000',
        whatsapp: '+971500000000',
        latitude: 25.2048,
        longitude: 55.2708,
        workingHoursAr: '10:00 ص - 9:00 م',
        workingHoursEn: '10:00 AM - 9:00 PM',
        branches: const [],
        practitionerIds: const [],
        treatmentIds: const [],
        featuredOffers: const [],
      );
    }
    return null;
  }

  Future<void> _handleOpenClinic(BuildContext context) async {
    final clinic = await _resolveClinic();
    if (clinic != null && context.mounted) {
      Navigator.push(
        context,
        LuxuryPageRoute(page: ClinicProfileScreen(clinic: clinic)),
      );
    }
  }

  Future<void> _handleInquiry(BuildContext context) async {
    final loc = LocaleService();
    final auth = await GuestAuthGuard.requireAuth(
      context,
      reasonTitle: loc.tr('product_inquiry_btn'),
      reasonSubtitle: loc.isArabic
          ? 'سجّل دخولك برقم الهاتف للاستفسار عن توفر المنتج وتفاصيله'
          : 'Login with phone number to submit your product inquiry',
    );
    if (!auth || !context.mounted) return;

    final clinic = await _resolveClinic();
    if (clinic != null && context.mounted) {
      Navigator.push(
        context,
        LuxuryPageRoute(
          page: AppointmentRequestScreen(
            clinic: clinic,
            preselectedServiceName: loc.isArabic ? product.nameAr : product.nameEn,
          ),
        ),
      );
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.accentChampagne, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.tr('product_inquiry_btn'),
                  style: AppTypography.cardTitle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تم إرسال طلبك وستتواصل العيادة معك',
                style: TextStyle(
                  color: AppColors.isDark(context) ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                loc.tr('product_inquiry_desc'),
                style: TextStyle(
                  color: AppColors.mutedText(context),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                loc.isArabic ? 'تم' : 'Done',
                style: const TextStyle(color: AppColors.accentChampagne, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);
    final categoryLabel = loc.isArabic ? product.categoryAr : product.categoryEn;
    final hasClinicInfo = product.clinicNameAr.isNotEmpty || (product.clinicNameEn?.isNotEmpty ?? false);

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
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              product.imageUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 220,
                color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                child: const Center(
                  child: Icon(Icons.shopping_bag_outlined, color: AppColors.accentChampagne, size: 48),
                ),
              ),
            ),
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
                const SizedBox(height: 12),
                Text(
                  loc.isArabic ? product.nameAr : product.nameEn,
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${product.price.toInt()} ${loc.tr("currency_aed")}',
                      style: TextStyle(
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (product.originalPrice != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        '${product.originalPrice!.toInt()} ${loc.tr("currency_aed")}',
                        style: TextStyle(
                          color: AppColors.mutedText(context),
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const Divider(height: 24),
                Text(
                  loc.isArabic ? product.descriptionAr : product.descriptionEn,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 13,
                    color: AppColors.mutedText(context),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Providing Clinic Card
          if (hasClinicInfo)
            LuxuryCard(
              onTap: () => _handleOpenClinic(context),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded, color: AppColors.accentChampagne, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('product_provided_by'),
                          style: TextStyle(color: AppColors.mutedText(context), fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.isArabic
                              ? product.clinicNameAr
                              : (product.clinicNameEn ?? product.clinicNameAr),
                          style: TextStyle(
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.accentChampagne),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Inquiry Action Button (Strictly No Checkout/Payment)
          SilverButton(
            label: loc.tr('product_inquiry_btn'),
            icon: Icons.send_rounded,
            isFullWidth: true,
            height: 48,
            onPressed: () => _handleInquiry(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
