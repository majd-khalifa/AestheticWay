/// Subscription tier for B2B clinic listing priority
enum SubscriptionTier {
  vipPlatinum, // 6-12 Months: Top Carousel slots 1 & 2, VIP badge
  featured, // 3-6 Months: Top Carousel slots 3+, Featured badge
  basic, // 1 Month: Standard directory listing only
}

/// Clinic Branch representation
class ClinicBranch {
  final String id;
  final String nameAr;
  final String nameEn;
  final String areaAr;
  final String areaEn;
  final String addressAr;
  final String addressEn;
  final String phone;
  final double distanceKm;
  final double latitude;
  final double longitude;
  final String? googlePlaceId;

  const ClinicBranch({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.areaAr,
    required this.areaEn,
    required this.addressAr,
    required this.addressEn,
    required this.phone,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
    this.googlePlaceId,
  });
}

/// Clinic Entity
class ClinicModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String coverImageUrl;
  final List<String> galleryImages;
  final String logoUrl;
  final double rating;
  final int reviewCount;
  final SubscriptionTier subscriptionTier;
  final String licenseAuthority; // DHA, DOH, MOHAP
  final String licenseNumber;
  final String city; // Dubai, Abu Dhabi
  final String areaAr;
  final String areaEn;
  final String addressAr;
  final String addressEn;
  final double distanceKm;
  final String mainPhone;
  final String receptionPhone;
  final String whatsapp;
  final String? googlePlaceId;
  final double latitude;
  final double longitude;
  final String workingHoursAr;
  final String workingHoursEn;
  final List<ClinicBranch> branches;
  final List<String> practitionerIds;
  final List<String> treatmentIds;
  final List<String> featuredOffers;
  final bool isVerified;

  const ClinicModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.coverImageUrl,
    required this.galleryImages,
    required this.logoUrl,
    required this.rating,
    required this.reviewCount,
    required this.subscriptionTier,
    required this.licenseAuthority,
    required this.licenseNumber,
    required this.city,
    required this.areaAr,
    required this.areaEn,
    required this.addressAr,
    required this.addressEn,
    required this.distanceKm,
    required this.mainPhone,
    required this.receptionPhone,
    required this.whatsapp,
    this.googlePlaceId,
    required this.latitude,
    required this.longitude,
    required this.workingHoursAr,
    this.workingHoursEn = 'Mon - Sat: 9:00 AM - 9:00 PM',
    required this.branches,
    this.practitionerIds = const [],
    this.treatmentIds = const [],
    this.featuredOffers = const [],
    this.isVerified = true,
  });

  bool get isEligibleForTopCarousel =>
      subscriptionTier == SubscriptionTier.vipPlatinum ||
      subscriptionTier == SubscriptionTier.featured;
}
