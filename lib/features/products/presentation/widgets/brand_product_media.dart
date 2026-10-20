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
          .where((value) => value.trim().isNotEmpty)
          .firstOrNull
          ?.trim() ??
      '';
}

/// Quiet studio framing: image and brand identity remain the focus.
class BrandProductMedia extends StatelessWidget {
  const BrandProductMedia({
    super.key,
    required this.product,
    this.hero = false,
  });
  final ProductModel product;
  final bool hero;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      return ColoredBox(
        color: AppColors.isDark(context)
            ? const Color(0xFF18243A)
            : const Color(0xFFF1F0EC),
        child: Padding(
          padding: EdgeInsets.all(hero ? 28 : 16),
          child: LuxuryImage(
            imageUrl: product.imageUrl,
            width: width,
            fit: BoxFit.contain,
            customPlaceholder: Center(
              child: Icon(
                Icons.spa_outlined,
                size: hero ? 56 : 32,
                color: AppColors.mutedText(context).withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      );
    },
  );
}
