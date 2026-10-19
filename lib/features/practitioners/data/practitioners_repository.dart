import '../../../core/data/paged_collection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../models/practitioner_model.dart';

/// Repository for Patient Discovery of Medical Practitioners (Doctors & Licensed Specialists)
/// Powered by GET /api/v1/practitioners/ and GET /api/v1/practitioners/{uuid}/
class PractitionersRepository {
  final ApiClient _api;

  PractitionersRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  /// Fetch public active practitioners list
  Future<List<PractitionerModel>> getPractitioners({
    int page = 1,
    int pageSize = 20,
    String? type,
    String? types,
    String? clinicId,
    String? city,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (types != null && types.isNotEmpty) queryParams['types'] = types;
    if (type != null && type.trim().isNotEmpty) {
      queryParams['type'] = type.trim();
    }
    if (clinicId != null && clinicId.trim().isNotEmpty) {
      queryParams['clinic'] = clinicId.trim();
    }
    if (city != null &&
        city.trim().isNotEmpty &&
        city != 'الكل' &&
        city != 'All') {
      queryParams['city'] = city.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    queryParams['page'] = page;
    queryParams['page_size'] = catalogPageSize;
    final response = await _api.get(
      ApiConfig.practitioners,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return PageItems<PractitionerModel>.fromResponse(
      response.data,
      PractitionerModel.fromJson,
      page: page,
    );
  }

  /// Fetch full practitioner profile detail including performed treatments
  Future<PractitionerModel> getPractitionerDetail(String id) async {
    final response = await _api.get(ApiConfig.practitionerDetail(id));
    final data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    return PractitionerModel.fromJson(data);
  }
}
