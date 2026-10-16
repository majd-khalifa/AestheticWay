import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/clinics/models/review_model.dart';

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
    int pageSize = 20,
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

    if (page >= 1) {
      queryParams['page'] = page;
    }

    if (pageSize > 0) {
      queryParams['page_size'] = pageSize;
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

  /// Fetches approved patient reviews for a clinic
  Future<List<ReviewModel>> getClinicReviews(String clinicId) async {
    final cleanId = clinicId.trim();
    if (cleanId.isEmpty) return [];

    try {
      final response = await _apiClient.get(ApiConfig.clinicReviews(cleanId));
      final data = response.data;
      List<dynamic> items = [];
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        items = data['results'] as List<dynamic>? ?? [];
      } else if (data is List) {
        items = data;
      }

      return items
          .whereType<Map<String, dynamic>>()
          .map((m) => ReviewModel.fromJson(m, defaultClinicId: cleanId))
          .toList();
    } catch (_) {
      // Graceful fallback when database is empty or reviews table is unpopulated
      return [];
    }
  }

  /// Submits a patient review/feedback for a clinic
  Future<bool> submitClinicReview(
    String clinicId, {
    required double rating,
    required String comment,
    String? patientName,
  }) async {
    final cleanId = clinicId.trim();
    if (cleanId.isEmpty) return false;

    final payload = <String, dynamic>{
      'clinic': cleanId,
      'rating': rating,
      'comment': comment.trim(),
      if (patientName != null && patientName.trim().isNotEmpty) 'patient_name': patientName.trim(),
    };

    final response = await _apiClient.post(
      ApiConfig.clinicReviewSubmit(cleanId),
      data: payload,
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }
}
