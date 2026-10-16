import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';

class OffersRepository {
  final ApiClient _apiClient;

  OffersRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetches active promotional offers with optional clinic filter
  Future<List<OfferModel>> getOffers({
    String? clinicId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final Map<String, dynamic> queryParams = {};

    if (clinicId != null && clinicId.trim().isNotEmpty) {
      queryParams['clinic_id'] = clinicId.trim();
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    if (page >= 1) {
      queryParams['page'] = page;
    }

    if (pageSize > 0) {
      queryParams['page_size'] = pageSize;
    }

    final response = await _apiClient.get(
      ApiConfig.offers,
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
        .map((m) => OfferModel.fromJson(m))
        .toList();
  }

  /// Fetches single offer details by ID
  Future<OfferModel> getOfferDetail(String id) async {
    final cleanId = id.trim();
    final endpoint = '${ApiConfig.offers}$cleanId/';

    final response = await _apiClient.get(endpoint);
    return OfferModel.fromJson(response.data as Map<String, dynamic>);
  }
}
