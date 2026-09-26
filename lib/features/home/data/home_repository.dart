import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/features/home/data/models/home_feed_model.dart';

class HomeRepository {
  final ApiClient _apiClient;

  HomeRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

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
        if (normalizedCity.contains('dubai') || normalizedCity.contains('دبي')) {
          queryParams['city'] = 'dubai';
        } else if (normalizedCity.contains('abu dhabi') || normalizedCity.contains('أبوظبي') || normalizedCity.contains('ابوظبي')) {
          queryParams['city'] = 'abu dhabi';
        } else {
          queryParams['city'] = city.trim();
        }
      }
    }

    final response = await _apiClient.get(
      ApiConfig.homeFeed,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return HomeFeedModel.fromJson(response.data as Map<String, dynamic>);
  }
}
