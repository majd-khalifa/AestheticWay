import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';

class TreatmentsRepository {
  static final TreatmentsRepository _instance = TreatmentsRepository._internal();
  factory TreatmentsRepository({ApiClient? apiClient}) {
    if (apiClient != null) {
      return TreatmentsRepository._internal(apiClient: apiClient);
    }
    return _instance;
  }
  TreatmentsRepository._internal({ApiClient? apiClient}) : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  /// GET /api/v1/treatments/
  Future<List<TreatmentModel>> getTreatments({
    String? search,
    String? category,
    String? clinic,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (category != null && category.trim().isNotEmpty && category != 'all') {
      queryParams['category'] = category.trim();
    }
    if (clinic != null && clinic.trim().isNotEmpty) {
      queryParams['clinic'] = clinic.trim();
    }
    if (page >= 1) {
      queryParams['page'] = page;
    }
    if (pageSize > 0) {
      queryParams['page_size'] = pageSize;
    }

    final response = await _client.get(
      ApiConfig.treatments,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final body = response.data;
    final rawData = body is Map<String, dynamic>
        ? (body['data'] ?? body['results'] ?? body)
        : body;
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map((e) => TreatmentModel.fromJson(e))
          .toList();
    }
    return [];
  }

  /// GET /api/v1/treatments/{uuid}/
  Future<TreatmentModel?> getTreatmentDetail(String id) async {
    final response = await _client.get(
      ApiConfig.treatmentDetail(id),
    );

    final body = response.data;
    final rawData = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
    if (rawData is Map<String, dynamic> && rawData['id'] != null) {
      return TreatmentModel.fromJson(rawData);
    }
    return null;
  }

  /// GET /api/v1/categories/
  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _client.get(
      ApiConfig.categories,
    );

    final body = response.data;
    final rawData = body is Map<String, dynamic>
        ? (body['data'] ?? body['results'] ?? body)
        : body;
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map((e) => {
                'id': e['id']?.toString() ?? '',
                'name_ar': e['name_ar']?.toString() ?? e['name_en']?.toString() ?? '',
                'name_en': e['name_en']?.toString() ?? e['name_ar']?.toString() ?? '',
                'slug': e['slug']?.toString() ?? '',
              })
          .toList();
    }
    return [];
  }
}
