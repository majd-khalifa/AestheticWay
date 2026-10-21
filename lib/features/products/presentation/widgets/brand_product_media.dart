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
    this.showIdentity = true,
  });
  final ProductModel product;
  final bool hero;
  final bool showIdentity;
  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    Widget identity() => Container(
      height: hero ? 64 : 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.surfaceSubtle(context),
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        children: [
          Icon(
            Icons.spa_outlined,
            color: AppColors.goldText(context),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              showIdentity && productBrandLabel(product, loc).isNotEmpty
                  ? productBrandLabel(product, loc)
                  : (loc.isArabic
                        ? 'عناية من عالم التجميل'
                        : 'Cosmetic brand showcase'),
              style: TextStyle(color: AppColors.subtext(context), fontSize: 11),
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
        builder: (context, constraints) {
          final width = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final height = (width * (hero ? 1.5 : 5 / 4)).clamp(
            0.0,
            hero ? 440.0 : 360.0,
          );
          return Image(
            key: ValueKey(provider),
            image: boundedImageDecode(
              computeSafeCacheWidth(context, width, height),
              provider,
              maxHeight: (height * MediaQuery.devicePixelRatioOf(context))
                  .round()
                  .clamp(100, 1440),
            ),
            height: height,
            width: double.infinity,
            fit: BoxFit.contain,
            semanticLabel: loc.isArabic ? product.nameAr : product.nameEn,
            errorBuilder: (_, _, _) => identity(),
          );
        },
      ),
    );
  }
}
