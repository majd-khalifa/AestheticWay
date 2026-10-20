import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/luxury_image.dart';
import '../../models/product_model.dart';

String productBrandLabel(ProductModel product, LocaleService locale) {
  final labels = locale.isArabic
      ? [product.brandNameAr, product.brandNameEn, product.sponsorCompany]
      : [product.brandNameEn, product.brandNameAr, product.sponsorCompany];
  return labels
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .firstOrNull
          ?.trim() ??
      '';
}

/// Genuine product media is contained, never cropped. Without a photograph the
/// supplied brand becomes the identity, rather than an empty grey photo panel.
class BrandProductMedia extends StatelessWidget {
  const BrandProductMedia({
    super.key,
    required this.product,
    this.hero = false,
  });
  final ProductModel product;
  final bool hero;
  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final brand = productBrandLabel(product, loc);
    Widget identity() => Container(
      padding: EdgeInsets.all(hero ? 28 : 20),
      decoration: BoxDecoration(
        gradient: AppColors.isDark(context)
            ? AppColors.vipCardGradient
            : AppColors.vipCardGradientLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 28, height: 2, color: AppColors.goldText(context)),
          const SizedBox(height: 16),
          Text(
            brand.isEmpty
                ? (loc.isArabic ? 'عرض علامة تجميل' : 'Brand showcase')
                : brand,
            style: TextStyle(
              fontFamily: loc.isArabic ? null : 'serif',
              fontSize: hero ? 30 : 23,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: AppColors.text(context),
            ),
          ),
        ],
      ),
    );
    final provider = resolveImageProvider(product.imageUrl);
    if (provider == null) return identity();
    return ColoredBox(
      color: AppColors.isDark(context)
          ? AppColors.cardSurfaceLight
          : const Color(0xFFFAF8F3),
      child: LayoutBuilder(
        builder: (context, constraints) => Image(
          key: ValueKey(provider),
          image: boundedImageDecode(
            computeSafeCacheWidth(
              context,
              constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width,
              hero ? 260 : 180,
            ),
            provider,
            maxHeight:
                ((hero ? 260 : 180) * MediaQuery.devicePixelRatioOf(context))
                    .round()
                    .clamp(100, 1440),
          ),
          height: hero ? 260 : 180,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => identity(),
        ),
      ),
    );
  }
}
