import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';

class ClinicsRepository {
  final ApiClient _apiClient;

  ClinicsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetches paginated clinics list with optional filters
  Future<List<ClinicModel>> getClinics({
    String? city,
    String? search,
    String? categoryId,
    double? latitude,
    double? longitude,
    int page = 1,
  }) async {
    final Map<String, dynamic> queryParams = {};

    if (city != null && city.isNotEmpty) {
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

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    if (categoryId != null && categoryId.trim().isNotEmpty) {
      queryParams['category'] = categoryId.trim();
    }

    if (latitude != null && longitude != null) {
      queryParams['latitude'] = latitude;
      queryParams['longitude'] = longitude;
    }

    if (page > 1) {
      queryParams['page'] = page;
    }

    final response = await _apiClient.get(
      ApiConfig.clinics,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final data = response.data;
    List<dynamic> list;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      list = data['results'] as List<dynamic>? ?? [];
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map((m) => ClinicModel.fromJson(m))
        .toList();
  }

  /// Fetches detailed clinic profile by UUID or slug
  Future<ClinicModel> getClinicDetail(String idOrSlug) async {
    final cleanId = idOrSlug.trim();
    final endpoint = '${ApiConfig.clinics}$cleanId/';

    final response = await _apiClient.get(endpoint);
    return ClinicModel.fromJson(response.data as Map<String, dynamic>);
  }
}
