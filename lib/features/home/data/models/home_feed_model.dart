import '../../../../core/network/api_config.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';

class CategoryApiModel {
  final String id;
  final String nameEn;
  final String nameAr;
  final String slug;
  final String icon;

  const CategoryApiModel({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.slug,
    required this.icon,
  });

  factory CategoryApiModel.fromJson(Map<String, dynamic> json) {
    return CategoryApiModel(
      id: json['id']?.toString() ?? '',
      nameEn: json['name_en'] as String? ?? '',
      nameAr: json['name_ar'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
    );
  }
}

class FeaturedAdApiModel {
  final String id;
  final String image;
  final String link;
  final ClinicModel? clinic;
  final String subscriptionTier;
  final String videoUrl;
  bool get isSponsored =>
      ['vip', 'featured'].contains(subscriptionTier.trim().toLowerCase());

  const FeaturedAdApiModel({
    required this.id,
    required this.image,
    required this.link,
    this.clinic,
    this.subscriptionTier = 'basic',
    this.videoUrl = '',
  });

  factory FeaturedAdApiModel.fromJson(Map<String, dynamic> json) {
    return FeaturedAdApiModel(
      id: json['id']?.toString() ?? '',
      image: ApiConfig.firstMediaUrl([json['image_url'], json['image']]),
      link: json['link'] as String? ?? '',
      clinic: json['clinic'] is Map<String, dynamic>
          ? ClinicModel.fromJson(json['clinic'] as Map<String, dynamic>)
          : null,
      subscriptionTier: json['subscription_tier']?.toString() ?? 'basic',
      videoUrl: ApiConfig.firstMediaUrl([json['video_url']]),
    );
  }
}

/// A genuine paid placement or a publicly listed premium subscription clinic.
/// A subscription partner never becomes a fabricated advertisement record.
class HomePartner {
  const HomePartner({required this.clinic, this.placement});
  final ClinicModel clinic;
  final FeaturedAdApiModel? placement;
  bool get isAdvertisement => placement != null;
  bool get isVip => placement != null
      ? placement!.subscriptionTier.trim().toLowerCase() == 'vip'
      : clinic.subscriptionTier == SubscriptionTier.vipPlatinum;
}

class HomeFeedModel {
  final List<FeaturedAdApiModel> featuredAds;
  final List<CategoryApiModel> categories;
  final List<OfferModel> activeOffers;
  final List<ClinicModel> nearbyClinics;
  final List<ClinicModel> partnerClinics;
  final bool partnerDirectoryUnavailable;

  List<HomePartner> get premiumPartners {
    final partners = <HomePartner>[
      for (final ad in featuredAds)
        if (ad.isSponsored && ad.clinic != null)
          HomePartner(clinic: ad.clinic!, placement: ad),
    ];
    final advertised = partners.map((p) => p.clinic.id).toSet();
    for (final clinic in [...partnerClinics, ...nearbyClinics]) {
      if (clinic.isEligibleForTopCarousel && advertised.add(clinic.id)) {
        partners.add(HomePartner(clinic: clinic));
      }
    }
    // Stable priority: preserve server display order within each tier.
    return [
      ...partners.where((p) => p.isVip),
      ...partners.where((p) => !p.isVip),
    ];
  }

  const HomeFeedModel({
    required this.featuredAds,
    required this.categories,
    required this.activeOffers,
    required this.nearbyClinics,
    this.partnerClinics = const [],
    this.partnerDirectoryUnavailable = false,
  });

  factory HomeFeedModel.fromJson(Map<String, dynamic> json) {
    final adsRaw = json['featured_ads'] as List? ?? [];
    final catsRaw = json['categories'] as List? ?? [];
    final offersRaw = json['active_offers'] as List? ?? [];
    final clinicsRaw = json['nearby_clinics'] as List? ?? [];

    return HomeFeedModel(
      featuredAds: adsRaw
          .take(10)
          .whereType<Map<String, dynamic>>()
          .map((m) => FeaturedAdApiModel.fromJson(m))
          .toList(),
      categories: catsRaw
          .take(8)
          .whereType<Map<String, dynamic>>()
          .map((m) => CategoryApiModel.fromJson(m))
          .toList(),
      activeOffers: offersRaw
          .take(10)
          .whereType<Map<String, dynamic>>()
          .map((m) => OfferModel.fromJson(m))
          .toList(),
      nearbyClinics: clinicsRaw
          .take(10)
          .whereType<Map<String, dynamic>>()
          .map((m) => ClinicModel.fromJson(m))
          .toList(),
    );
  }
}
