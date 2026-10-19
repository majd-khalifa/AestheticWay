import '../../../core/data/paged_collection.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';

class TreatmentsRepository {
  static final TreatmentsRepository _instance =
      TreatmentsRepository._internal();
  factory TreatmentsRepository({ApiClient? apiClient}) {
    if (apiClient != null) {
      return TreatmentsRepository._internal(apiClient: apiClient);
    }
    return _instance;
  }
  TreatmentsRepository._internal({ApiClient? apiClient})
    : _client = apiClient ?? ApiClient();

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

    queryParams['page'] = page;
    queryParams['page_size'] = catalogPageSize;
    final response = await _client.get(
      ApiConfig.treatments,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return PageItems<TreatmentModel>.fromResponse(
      response.data,
      TreatmentModel.fromJson,
      page: page,
    );
  }

  /// GET /api/v1/treatments/{uuid}/
  Future<TreatmentModel?> getTreatmentDetail(String id) async {
    final response = await _client.get(ApiConfig.treatmentDetail(id));

    final body = response.data;
    final rawData = body is Map<String, dynamic>
        ? (body['data'] ?? body)
        : body;
    if (rawData is Map<String, dynamic> && rawData['id'] != null) {
      return TreatmentModel.fromJson(rawData);
    }
    return null;
  }

  /// GET /api/v1/categories/
  Future<List<Map<String, dynamic>>> getCategories({
    int page = 1,
    String? search,
  }) async {
    final response = await _client.get(
      ApiConfig.categories,
      queryParameters: {
        'page': page,
        'page_size': catalogPageSize,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return PageItems<Map<String, dynamic>>.fromResponse(
      response.data,
      (e) => {
        'id': e['id']?.toString() ?? '',
        'name_ar': e['name_ar']?.toString() ?? e['name_en']?.toString() ?? '',
        'name_en': e['name_en']?.toString() ?? e['name_ar']?.toString() ?? '',
        'slug': e['slug']?.toString() ?? '',
      },
      page: page,
    );
  }
}
