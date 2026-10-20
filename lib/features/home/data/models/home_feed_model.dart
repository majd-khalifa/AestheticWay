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
      ['vip', 'featured'].contains(subscriptionTier.toLowerCase());

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

class HomeFeedModel {
  final List<FeaturedAdApiModel> featuredAds;
  final List<CategoryApiModel> categories;
  final List<OfferModel> activeOffers;
  final List<ClinicModel> nearbyClinics;

  const HomeFeedModel({
    required this.featuredAds,
    required this.categories,
    required this.activeOffers,
    required this.nearbyClinics,
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
