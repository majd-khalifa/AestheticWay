import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../articles/models/article_model.dart';
import '../../clinics/models/clinic_model.dart';
import '../../offers/models/offer_model.dart';
import '../../practitioners/models/practitioner_model.dart';
import '../../products/models/product_model.dart';
import '../../treatments/models/category_model.dart';
import '../../treatments/models/treatment_model.dart';

/// Repository for Clinic Partner Catalog Management (Practitioners, Treatments, Offers, Products, Articles, Categories)
class ClinicCatalogRepository {
  static final ClinicCatalogRepository _instance = ClinicCatalogRepository._internal();
  factory ClinicCatalogRepository({ApiClient? apiClient}) {
    if (apiClient != null) {
      return ClinicCatalogRepository._custom(apiClient);
    }
    return _instance;
  }
  ClinicCatalogRepository._internal() : _api = ApiClient();
  ClinicCatalogRepository._custom(this._api);

  final ApiClient _api;

  // -------------------------------------------------------------
  // PRACTITIONERS
  // -------------------------------------------------------------

  Future<List<PractitionerModel>> getPractitioners({String? search}) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _api.get(
      ApiConfig.clinicPractitioners,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final rawData = response.data;
    List<dynamic> items = [];
    if (rawData is Map<String, dynamic> && rawData.containsKey('results')) {
      items = rawData['results'] as List<dynamic>? ?? [];
    } else if (rawData is List) {
      items = rawData;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((m) => PractitionerModel.fromJson(m))
        .toList();
  }

  Future<PractitionerModel> createPractitioner(Map<String, dynamic> data) async {
    final response = await _api.post(
      ApiConfig.clinicPractitioners,
      data: data,
    );
    return PractitionerModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PractitionerModel> updatePractitioner(String id, Map<String, dynamic> data) async {
    final response = await _api.patch(
      ApiConfig.clinicPractitionerDetail(id),
      data: data,
    );
    return PractitionerModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePractitioner(String id) async {
    await _api.delete(ApiConfig.clinicPractitionerDetail(id));
  }

  // -------------------------------------------------------------
  // TREATMENTS
  // -------------------------------------------------------------

  Future<List<TreatmentModel>> getTreatments({String? search}) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _api.get(
      ApiConfig.clinicTreatments,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final rawData = response.data;
    List<dynamic> items = [];
    if (rawData is Map<String, dynamic> && rawData.containsKey('results')) {
      items = rawData['results'] as List<dynamic>? ?? [];
    } else if (rawData is List) {
      items = rawData;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((m) => TreatmentModel.fromJson(m))
        .toList();
  }

  Future<TreatmentModel> createTreatment(Map<String, dynamic> data) async {
    final response = await _api.post(
      ApiConfig.clinicTreatments,
      data: data,
    );
    return TreatmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TreatmentModel> updateTreatment(String id, Map<String, dynamic> data) async {
    final response = await _api.patch(
      ApiConfig.clinicTreatmentDetail(id),
      data: data,
    );
    return TreatmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTreatment(String id) async {
    await _api.delete(ApiConfig.clinicTreatmentDetail(id));
  }

  // -------------------------------------------------------------
  // OFFERS
  // -------------------------------------------------------------

  Future<List<OfferModel>> getOffers({String? search}) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _api.get(
      ApiConfig.clinicOffers,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final rawData = response.data;
    List<dynamic> items = [];
    if (rawData is Map<String, dynamic> && rawData.containsKey('results')) {
      items = rawData['results'] as List<dynamic>? ?? [];
    } else if (rawData is List) {
      items = rawData;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((m) => OfferModel.fromJson(m))
        .toList();
  }

  Future<OfferModel> createOffer(Map<String, dynamic> data) async {
    final response = await _api.post(
      ApiConfig.clinicOffers,
      data: data,
    );
    return OfferModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OfferModel> updateOffer(String id, Map<String, dynamic> data) async {
    final response = await _api.patch(
      ApiConfig.clinicOfferDetail(id),
      data: data,
    );
    return OfferModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OfferModel> updateOfferStatus(String id, String status) async {
    final response = await _api.patch(
      ApiConfig.clinicOfferDetail(id),
      data: {
        'status': status,
        'is_active': status == 'active',
      },
    );
    return OfferModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteOffer(String id) async {
    await _api.delete(ApiConfig.clinicOfferDetail(id));
  }

  // -------------------------------------------------------------
  // PRODUCTS
  // -------------------------------------------------------------

  Future<List<ProductModel>> getProducts({String? search}) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _api.get(
      ApiConfig.clinicProducts,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final rawData = response.data;
    List<dynamic> items = [];
    if (rawData is Map<String, dynamic> && rawData.containsKey('results')) {
      items = rawData['results'] as List<dynamic>? ?? [];
    } else if (rawData is List) {
      items = rawData;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((m) => ProductModel.fromJson(m))
        .toList();
  }

  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    final response = await _api.post(
      ApiConfig.clinicProducts,
      data: data,
    );
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProductModel> updateProduct(String id, Map<String, dynamic> data) async {
    final response = await _api.patch(
      ApiConfig.clinicProductDetail(id),
      data: data,
    );
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteProduct(String id) async {
    await _api.delete(ApiConfig.clinicProductDetail(id));
  }

  // -------------------------------------------------------------
  // ARTICLES
  // -------------------------------------------------------------

  Future<List<ArticleModel>> getArticles({String? search}) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _api.get(
      ApiConfig.clinicArticles,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final rawData = response.data;
    List<dynamic> items = [];
    if (rawData is Map<String, dynamic> && rawData.containsKey('results')) {
      items = rawData['results'] as List<dynamic>? ?? [];
    } else if (rawData is List) {
      items = rawData;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((m) => ArticleModel.fromJson(m))
        .toList();
  }

  Future<ArticleModel> createArticle(Map<String, dynamic> data) async {
    final response = await _api.post(
      ApiConfig.clinicArticles,
      data: data,
    );
    return ArticleModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ArticleModel> updateArticle(String id, Map<String, dynamic> data) async {
    final response = await _api.patch(
      ApiConfig.clinicArticleDetail(id),
      data: data,
    );
    return ArticleModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteArticle(String id) async {
    await _api.delete(ApiConfig.clinicArticleDetail(id));
  }

  // -------------------------------------------------------------
  // CATEGORIES (for treatment categorization)
  // -------------------------------------------------------------

  Future<List<CategoryModel>> getCategories() async {
    final response = await _api.get(ApiConfig.categories);

    final rawData = response.data;
    List<dynamic> items = [];
    if (rawData is Map<String, dynamic> && rawData.containsKey('results')) {
      items = rawData['results'] as List<dynamic>? ?? [];
    } else if (rawData is List) {
      items = rawData;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((m) => CategoryModel.fromJson(m))
        .toList();
  }

  // -------------------------------------------------------------
  // CLINIC PROFILE (GET & PATCH /api/v1/clinic-portal/profile/)
  // -------------------------------------------------------------

  Future<ClinicModel> getClinicProfile() async {
    final response = await _api.get(ApiConfig.clinicProfile);
    final body = response.data;
    final rawData = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
    return ClinicModel.fromJson(rawData as Map<String, dynamic>);
  }

  Future<ClinicModel> updateClinicProfile(Map<String, dynamic> data) async {
    final response = await _api.patch(
      ApiConfig.clinicProfile,
      data: data,
    );
    final body = response.data;
    final rawData = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
    return ClinicModel.fromJson(rawData as Map<String, dynamic>);
  }
}
