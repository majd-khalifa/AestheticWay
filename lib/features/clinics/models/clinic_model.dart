import '../../../core/utils/source_text.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/utils/clinic_location.dart';
import 'package:aesthetic_way/core/utils/maps_launcher.dart';

/// Subscription tier for B2B clinic listing priority
enum SubscriptionTier {
  vipPlatinum, // 6-12 Months: Top Carousel slots 1 & 2, VIP badge
  featured, // 3-6 Months: Top Carousel slots 3+, Featured badge
  basic, // 1 Month: Standard directory listing only
}

extension SubscriptionTierApiValue on SubscriptionTier {
  String get apiValue => switch (this) {
    SubscriptionTier.vipPlatinum => 'vip',
    SubscriptionTier.featured => 'featured',
    SubscriptionTier.basic => 'basic',
  };
}

/// Clinic Branch representation
class ClinicBranch {
  final String id;
  final String nameAr;
  final String nameEn;
  final String city;
  final String areaAr;
  final String areaEn;
  final String addressAr;
  final String addressEn;
  final String phone;
  final double distanceKm;
  final double latitude;
  final double longitude;
  final String? googlePlaceId;
  final String? googleMapsUrl;
  final bool isMainBranch;
  final bool isActive;

  const ClinicBranch({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.city = '',
    required this.areaAr,
    required this.areaEn,
    required this.addressAr,
    required this.addressEn,
    required this.phone,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
    this.googlePlaceId,
    this.googleMapsUrl,
    this.isMainBranch = false,
    this.isActive = true,
  });

  factory ClinicBranch.fromJson(Map<String, dynamic> json) {
    return ClinicBranch(
      id: json['id']?.toString() ?? '',
      nameAr: firstSourceText([json['name_ar'], json['name_en']]),
      nameEn: firstSourceText([json['name_en'], json['name_ar']]),
      city: json['city']?.toString() ?? '',
      areaAr: firstSourceText([json['address_ar'], json['address_en']]),
      areaEn: firstSourceText([json['address_en'], json['address_ar']]),
      addressAr: firstSourceText([json['address_ar'], json['address_en']]),
      addressEn: firstSourceText([json['address_en'], json['address_ar']]),
      phone: json['phone']?.toString() ?? '',
      distanceKm: 0.0,
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      googlePlaceId: json['google_place_id']?.toString(),
      googleMapsUrl: json['google_maps_url']?.toString(),
      isMainBranch: json['is_main_branch'] == true,
      isActive: json['is_active'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name_ar': nameAr,
      'name_en': nameEn,
      'city': city,
      'address_ar': addressAr,
      'address_en': addressEn,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      if (googlePlaceId != null && googlePlaceId!.isNotEmpty)
        'google_place_id': googlePlaceId,
      if (googleMapsUrl != null && googleMapsUrl!.isNotEmpty)
        'google_maps_url': googleMapsUrl,
      'is_main_branch': isMainBranch,
      'is_active': isActive,
    };
  }
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

  /// Photography only: a logo must never masquerade as a clinic cover.
  String get primaryPhotoUrl => coverImageUrl.trim().isNotEmpty
      ? coverImageUrl
      : galleryImages.where((url) => url.trim().isNotEmpty).firstOrNull ?? '';
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
  final String? slug;
  final String? googleMapsUrl;
  final String? videoUrl;
  final String mediaType; // 'image' | 'video'
  final String setupStatus; // 'draft' | 'submitted' | 'approved' | 'rejected'
  final bool hasBranchDirectory;
  final List<dynamic>? rawPractitioners;
  final List<dynamic>? rawTreatments;

  double get googleRating => rating;
  int get googleReviewsCount => reviewCount;

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
    this.licenseAuthority = 'DHA',
    this.licenseNumber = '',
    required this.city,
    required this.areaAr,
    this.areaEn = '',
    required this.addressAr,
    this.addressEn = '',
    this.distanceKm = 0.0,
    this.mainPhone = '',
    this.receptionPhone = '',
    this.whatsapp = '',
    this.googlePlaceId,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.workingHoursAr = '',
    this.workingHoursEn = '',
    this.branches = const [],
    this.practitionerIds = const [],
    this.treatmentIds = const [],
    this.featuredOffers = const [],
    this.isVerified = false,
    this.slug,
    this.googleMapsUrl,
    this.videoUrl,
    this.mediaType = 'image',
    this.setupStatus = 'approved',
    this.hasBranchDirectory = false,
    this.rawPractitioners,
    this.rawTreatments,
  });

  factory ClinicModel.fromJson(Map<String, dynamic> json) {
    final tier = json['subscription_tier']?.toString().toLowerCase();
    final googleRating = double.tryParse('${json['google_rating']}');
    final googleCount = int.tryParse('${json['google_reviews_count']}');
    final validRating =
        googleRating != null &&
        googleRating.isFinite &&
        googleRating >= 1 &&
        googleRating <= 5 &&
        (json['google_reviews_count'] == null ||
            (googleCount != null && googleCount > 0));
    final branchesRaw = json['branches'] as List<dynamic>?;
    final branchesList = branchesRaw != null
        ? branchesRaw
              .map((b) => ClinicBranch.fromJson(b as Map<String, dynamic>))
              .toList()
        : <ClinicBranch>[];

    final cover = ApiConfig.firstMediaUrl([
      json['cover_image'],
      json['cover_image_url'],
    ]);
    final logo = ApiConfig.firstMediaUrl([json['logo'], json['logo_url']]);
    final rawGallery = json['gallery_images'] as List<dynamic>?;
    final gallery = rawGallery != null && rawGallery.isNotEmpty
        ? rawGallery
              .map((e) => ApiConfig.firstMediaUrl([e]))
              .where((e) => e.isNotEmpty)
              .toList()
        : (cover.isNotEmpty ? [cover] : <String>[]);

    final practitionersRaw = (json['practitioners'] as List<dynamic>?)
        ?.take(6)
        .toList();
    final practitionerIds = practitionersRaw != null
        ? practitionersRaw
              .map((p) => (p is Map ? p['id']?.toString() ?? '' : p.toString()))
              .where((id) => id.isNotEmpty)
              .toList()
        : <String>[];

    final treatmentsRaw = (json['treatments'] as List<dynamic>?)
        ?.take(6)
        .toList();
    final treatmentIds = treatmentsRaw != null
        ? treatmentsRaw
              .map((t) => (t is Map ? t['id']?.toString() ?? '' : t.toString()))
              .where((id) => id.isNotEmpty)
              .toList()
        : <String>[];

    final video = ApiConfig.firstMediaUrl([
      json['video_ad_file'],
      json['video_url'],
      json['promo_video_url'],
      json['featured_video_url'],
      json['ad_video_url'],
    ]);
    final resolvedVideoUrl = video.isEmpty ? null : video;
    final hasVideoUrl = resolvedVideoUrl != null && resolvedVideoUrl.isNotEmpty;
    final rawMediaType = json['media_type']?.toString().trim().toLowerCase();
    final resolvedMediaType = (rawMediaType == 'video' || hasVideoUrl)
        ? 'video'
        : 'image';

    return ClinicModel(
      id: json['id']?.toString() ?? '',
      nameAr: firstSourceText([json['name_ar'], json['name_en']]),
      nameEn: firstSourceText([json['name_en'], json['name_ar']]),
      descriptionAr: firstSourceText([
        json['description_ar'],
        json['description_en'],
      ]),
      descriptionEn: firstSourceText([
        json['description_en'],
        json['description_ar'],
      ]),
      coverImageUrl: cover,
      galleryImages: gallery,
      logoUrl: logo,
      rating: validRating ? googleRating : 0,
      reviewCount: validRating && googleCount != null ? googleCount : 0,
      subscriptionTier: switch (tier) {
        'vip' || 'vip_platinum' => SubscriptionTier.vipPlatinum,
        'featured' => SubscriptionTier.featured,
        _ => SubscriptionTier.basic,
      },
      isVerified: json['is_verified'] == true,
      licenseAuthority: json['license_authority']?.toString() ?? 'DHA',
      licenseNumber: json['license_number']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      areaAr: json['area_ar'] ?? '',
      areaEn: json['area_en'] ?? '',
      addressAr: firstSourceText([json['address_ar'], json['address_en']]),
      addressEn: firstSourceText([json['address_en'], json['address_ar']]),
      distanceKm: double.tryParse(json['distance']?.toString() ?? '') ?? 0.0,
      mainPhone: json['phone']?.toString() ?? '',
      receptionPhone: json['phone']?.toString() ?? '',
      whatsapp: json['whatsapp']?.toString() ?? '',
      googlePlaceId: json['google_place_id']?.toString(),
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      workingHoursAr: json['working_hours_ar'] ?? '',
      workingHoursEn: json['working_hours_en'] ?? '',
      branches: branchesList,
      practitionerIds: practitionerIds,
      treatmentIds: treatmentIds,
      slug: json['slug']?.toString(),
      googleMapsUrl: json['google_maps_url']?.toString(),
      videoUrl: hasVideoUrl ? resolvedVideoUrl : null,
      mediaType: resolvedMediaType,
      setupStatus: json['setup_status']?.toString() ?? 'unknown',
      hasBranchDirectory: json['branches_directory_url'] != null,
      rawPractitioners: practitionersRaw,
      rawTreatments: treatmentsRaw,
    );
  }

  bool get isEligibleForTopCarousel =>
      subscriptionTier == SubscriptionTier.vipPlatinum ||
      subscriptionTier == SubscriptionTier.featured;

  /// Returns true when backend provides a valid video URL for Featured/VIP carousel
  bool get hasVideoAd =>
      videoUrl != null &&
      videoUrl!.trim().isNotEmpty &&
      (mediaType.toLowerCase() == 'video' || videoUrl!.trim().isNotEmpty);

  String get effectivePhone => receptionPhone.trim().isNotEmpty
      ? receptionPhone.trim()
      : mainPhone.trim();

  bool get hasPhone =>
      RegExp(r'^\+?[0-9][0-9 ()-]{6,20}$').hasMatch(effectivePhone);

  bool get hasWhatsapp {
    final clean = whatsapp.trim().replaceAll(RegExp(r'[^0-9]'), '');
    return clean.length >= 7;
  }

  Uri? get mapsUri => MapsLauncher.verifiedPlaceUri(
    latitude: latitude,
    longitude: longitude,
    googleMapsUrl: googleMapsUrl,
    placeId: googlePlaceId,
  );
  bool get hasMapLocation => mapsUri != null;
  bool get hasGoogleRating =>
      googlePlaceId != null &&
      googlePlaceId!.trim().isNotEmpty &&
      rating.isFinite &&
      rating >= 1 &&
      rating <= 5;
  ClinicCoordinates? get coordinates =>
      ClinicCoordinates.parse(latitude, longitude);

  ClinicModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? descriptionAr,
    String? descriptionEn,
    String? coverImageUrl,
    List<String>? galleryImages,
    String? logoUrl,
    double? rating,
    int? reviewCount,
    SubscriptionTier? subscriptionTier,
    String? licenseAuthority,
    String? licenseNumber,
    String? city,
    String? areaAr,
    String? areaEn,
    String? addressAr,
    String? addressEn,
    double? distanceKm,
    String? mainPhone,
    String? receptionPhone,
    String? whatsapp,
    String? googlePlaceId,
    double? latitude,
    double? longitude,
    String? workingHoursAr,
    String? workingHoursEn,
    List<ClinicBranch>? branches,
    List<String>? practitionerIds,
    List<String>? treatmentIds,
    List<String>? featuredOffers,
    bool? isVerified,
    String? slug,
    String? googleMapsUrl,
    String? videoUrl,
    String? mediaType,
    String? setupStatus,
    bool? hasBranchDirectory,
    List<dynamic>? rawPractitioners,
    List<dynamic>? rawTreatments,
  }) {
    return ClinicModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      logoUrl: logoUrl ?? this.logoUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      licenseAuthority: licenseAuthority ?? this.licenseAuthority,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      city: city ?? this.city,
      areaAr: areaAr ?? this.areaAr,
      areaEn: areaEn ?? this.areaEn,
      addressAr: addressAr ?? this.addressAr,
      addressEn: addressEn ?? this.addressEn,
      distanceKm: distanceKm ?? this.distanceKm,
      mainPhone: mainPhone ?? this.mainPhone,
      receptionPhone: receptionPhone ?? this.receptionPhone,
      whatsapp: whatsapp ?? this.whatsapp,
      googlePlaceId: googlePlaceId ?? this.googlePlaceId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      workingHoursAr: workingHoursAr ?? this.workingHoursAr,
      workingHoursEn: workingHoursEn ?? this.workingHoursEn,
      branches: branches ?? this.branches,
      practitionerIds: practitionerIds ?? this.practitionerIds,
      treatmentIds: treatmentIds ?? this.treatmentIds,
      featuredOffers: featuredOffers ?? this.featuredOffers,
      isVerified: isVerified ?? this.isVerified,
      slug: slug ?? this.slug,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      mediaType: mediaType ?? this.mediaType,
      setupStatus: setupStatus ?? this.setupStatus,
      hasBranchDirectory: hasBranchDirectory ?? this.hasBranchDirectory,
      rawPractitioners: rawPractitioners ?? this.rawPractitioners,
      rawTreatments: rawTreatments ?? this.rawTreatments,
    );
  }
}
