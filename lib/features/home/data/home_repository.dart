import '../../clinics/data/clinics_repository.dart';
import '../../clinics/models/clinic_model.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/features/home/data/models/home_feed_model.dart';

class HomeRepository {
  final ApiClient _apiClient;

  HomeRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Fetches the discovery home feed from the backend.
  /// Supports optional geo coordinates [latitude], [longitude] or [city] filter.
  Future<HomeFeedModel> getHomeFeed({
    String? city,
    double? latitude,
    double? longitude,
  }) async {
    final Map<String, dynamic> queryParams = {};

    if (latitude != null && longitude != null) {
      queryParams['latitude'] = latitude;
      queryParams['longitude'] = longitude;
    } else if (city != null && city.isNotEmpty) {
      final normalizedCity = city.trim().toLowerCase();
      if (normalizedCity != 'all' && normalizedCity != 'الكل') {
        if (normalizedCity.contains('dubai') ||
            normalizedCity.contains('دبي')) {
          queryParams['city'] = 'dubai';
        } else if (normalizedCity.contains('abu dhabi') ||
            normalizedCity.contains('أبوظبي') ||
            normalizedCity.contains('ابوظبي')) {
          queryParams['city'] = 'abu dhabi';
        } else {
          queryParams['city'] = city.trim();
        }
      }
    }

    // Independent bounded reads start together. Attach the error handler now so
    // a failed optional directory never becomes an unhandled async error while
    // the primary feed is still loading.
    final feedRequest = _apiClient.get(
      ApiConfig.homeFeed,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final directory = ClinicsRepository(apiClient: _apiClient)
        .getClinics(city: city, latitude: latitude, longitude: longitude)
        .then<List<ClinicModel>?>(
          (items) => items,
          onError: (Object _, StackTrace _) => null,
        );
    final response = await feedRequest;

    final feed = HomeFeedModel.fromJson(response.data as Map<String, dynamic>);
    // The Home serializer omits clinic subscription/media metadata. The existing
    // public directory is active-only and tier ordered. One bounded page restores
    // supported subscription visibility without inventing ads or using is_featured.
    // Its failure must not discard genuine ad records from a successful feed.
    try {
      final clinics = await directory;
      if (clinics == null) throw const _DirectoryUnavailable();
      final byId = {for (final clinic in clinics) clinic.id: clinic};
      return HomeFeedModel(
        featuredAds: [
          for (final ad in feed.featuredAds)
            FeaturedAdApiModel(
              id: ad.id,
              image: ad.image,
              link: ad.link,
              clinic: byId[ad.clinic?.id] ?? ad.clinic,
              subscriptionTier: ad.subscriptionTier,
              videoUrl: ad.videoUrl,
            ),
        ],
        categories: feed.categories,
        activeOffers: feed.activeOffers,
        nearbyClinics: [
          for (final clinic in feed.nearbyClinics) byId[clinic.id] ?? clinic,
        ],
        partnerClinics: clinics,
      );
    } catch (_) {
      return HomeFeedModel(
        featuredAds: feed.featuredAds,
        categories: feed.categories,
        activeOffers: feed.activeOffers,
        nearbyClinics: feed.nearbyClinics,
        partnerDirectoryUnavailable: true,
      );
    }
  }
}

class _DirectoryUnavailable implements Exception {
  const _DirectoryUnavailable();
}
