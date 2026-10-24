import '../../locations/data/uae_location_repository.dart';
import '../../../core/data/paged_collection.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';

class ClinicsRepository {
  final ApiClient _apiClient;

  ClinicsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Fetches paginated clinics list with optional filters
  Future<List<ClinicModel>> getClinics({
    String? city,
    String? search,
    String? categoryId,
    double? latitude,
    double? longitude,
    int page = 1,
    int pageSize = 20,
  }) async {
    final Map<String, dynamic> queryParams = {};

    if (city != null && city.isNotEmpty) {
      final canonical = compatibilityUaeCatalog.legacyCityQuery(city);
      if (canonical != null) queryParams['city'] = canonical;
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

    queryParams['page'] = page;
    queryParams['page_size'] = catalogPageSize;
    final response = await _apiClient.get(
      ApiConfig.clinics,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return PageItems<ClinicModel>.fromResponse(
      response.data,
      ClinicModel.fromJson,
      page: page,
    );
  }

  /// Fetches detailed clinic profile by UUID or slug
  Future<ClinicModel> getClinicDetail(String idOrSlug) async {
    final cleanId = idOrSlug.trim();
    final endpoint = '${ApiConfig.clinics}$cleanId/';

    final response = await _apiClient.get(endpoint);
    return ClinicModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ClinicBranch>> getBranches(
    String clinicId, {
    int page = 1,
    String? search,
  }) async {
    final response = await _apiClient.get(
      '${ApiConfig.clinics}$clinicId/branches/',
      queryParameters: {
        'page': page,
        'page_size': catalogPageSize,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return PageItems<ClinicBranch>.fromResponse(
      response.data,
      ClinicBranch.fromJson,
      page: page,
    );
  }
}
