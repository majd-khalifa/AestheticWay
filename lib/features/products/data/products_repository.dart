import '../../../core/data/paged_collection.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';

/// Repository for Public Discovery of Medical Skincare & Clinic Products (Inquiry Only)
class ProductsRepository {
  final ApiClient _apiClient;

  ProductsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Fetches active products from `GET /api/v1/products/`
  Future<List<ProductModel>> getProducts({
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
      ApiConfig.products,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return PageItems<ProductModel>.fromResponse(
      response.data,
      ProductModel.fromJson,
      page: page,
    );
  }

  /// Fetches single product detail by UUID from `GET /api/v1/products/<id>/`
  Future<ProductModel> getProductDetail(String id) async {
    final cleanId = id.trim();
    final response = await _apiClient.get(ApiConfig.productDetail(cleanId));
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }
}
