import '../../../core/data/paged_collection.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';

class OffersRepository {
  final ApiClient _apiClient;

  OffersRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

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

    queryParams['page'] = page;
    queryParams['page_size'] = catalogPageSize;
    final response = await _apiClient.get(
      ApiConfig.offers,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return PageItems<OfferModel>.fromResponse(
      response.data,
      OfferModel.fromJson,
      page: page,
    );
  }

  /// Fetches single offer details by ID
  Future<OfferModel> getOfferDetail(String id) async {
    final cleanId = id.trim();
    final endpoint = '${ApiConfig.offers}$cleanId/';

    final response = await _apiClient.get(endpoint);
    return OfferModel.fromJson(response.data as Map<String, dynamic>);
  }
}
