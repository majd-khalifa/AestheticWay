import '../../../../core/widgets/patient_media_placeholder.dart';
import '../../../../core/widgets/patient_image.dart' show isKnownVideoSource;
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

/// Genuine product media stays contained; absent media keeps the same frame.
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
    final video = isKnownVideoSource(product.imageUrl);
    final provider = video ? null : resolveImageProvider(product.imageUrl);
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
          if (provider == null) {
            return PatientMediaPlaceholder(
              category: PatientMediaCategory.product,
              reason: video
                  ? PatientMediaFallbackReason.unsupportedSource
                  : PatientMediaFallbackReason.missing,
              height: height,
              width: double.infinity,
            );
          }
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
            errorBuilder: (_, _, _) => PatientMediaPlaceholder(
              category: PatientMediaCategory.product,
              reason: PatientMediaFallbackReason.loadFailed,
              height: height,
              width: double.infinity,
            ),
          );
        },
      ),
    );
  }
}
