class OfferModel {
  final String id;
  final String titleAr;
  final String titleEn;
  final String clinicId;
  final String clinicNameAr;
  final String? clinicNameEn;
  final double originalPrice;
  final double offerPrice;
  final int discountPercentage;
  final String validUntilText;
  final String? validUntilTextEn;
  final int daysRemaining;
  final String termsAr;
  final String? termsEn;
  final String imageUrl;

  const OfferModel({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.clinicId,
    required this.clinicNameAr,
    this.clinicNameEn,
    required this.originalPrice,
    required this.offerPrice,
    required this.discountPercentage,
    required this.validUntilText,
    this.validUntilTextEn,
    required this.daysRemaining,
    required this.termsAr,
    this.termsEn,
    required this.imageUrl,
  });
}
