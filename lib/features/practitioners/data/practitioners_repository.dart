import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../models/practitioner_model.dart';

/// Repository for Patient Discovery of Medical Practitioners (Doctors & Licensed Specialists)
/// Powered by GET /api/v1/practitioners/ and GET /api/v1/practitioners/{uuid}/
class PractitionersRepository {
  final ApiClient _api;

  PractitionersRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) {
      if (data['results'] is List) {
        return (data['results'] as List).whereType<Map<String, dynamic>>().toList();
      }
      if (data['data'] is List) {
        return (data['data'] as List).whereType<Map<String, dynamic>>().toList();
      }
    }
    return const [];
  }

  /// Fetch public active practitioners list
  Future<List<PractitionerModel>> getPractitioners({
    String? type,
    String? clinicId,
    String? city,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (type != null && type.trim().isNotEmpty) {
      queryParams['type'] = type.trim();
    }
    if (clinicId != null && clinicId.trim().isNotEmpty) {
      queryParams['clinic'] = clinicId.trim();
    }
    if (city != null && city.trim().isNotEmpty && city != 'الكل' && city != 'All') {
      queryParams['city'] = city.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _api.get(
      ApiConfig.practitioners,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final rawList = _extractList(response.data);
    return rawList.map((json) => PractitionerModel.fromJson(json)).toList();
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
