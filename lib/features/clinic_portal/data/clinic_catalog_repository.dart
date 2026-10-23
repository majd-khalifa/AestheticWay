import '../../../core/auth/session_snapshot.dart';
import 'package:aesthetic_way/features/treatments/data/category_repository.dart';
import 'package:aesthetic_way/features/treatments/models/category_model.dart';
import '../../../core/data/paged_collection.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/media_upload_service.dart';
import '../../../core/services/media_payload_builder.dart';
import '../../articles/models/article_model.dart';
import '../../clinics/models/clinic_model.dart';
import '../../offers/models/offer_model.dart';
import '../../practitioners/models/practitioner_model.dart';
import '../../products/models/product_model.dart';
import '../../treatments/models/treatment_model.dart';
import 'models/clinic_setup_checklist_model.dart';

/// Repository for Clinic Partner Catalog Management (Practitioners, Treatments, Offers, Products, Articles, Categories)
class ClinicCatalogRepository {
  static final ClinicCatalogRepository _instance =
      ClinicCatalogRepository._internal();
  factory ClinicCatalogRepository({
    ApiClient? apiClient,
    MediaUploadService? mediaUploadService,
  }) {
    if (apiClient != null || mediaUploadService != null) {
      final client = apiClient ?? ApiClient();
      return ClinicCatalogRepository._custom(
        client,
        mediaUploadService ?? MediaUploadService(client: client),
      );
    }
    return _instance;
  }
  ClinicCatalogRepository._internal()
    : _api = ApiClient(),
      _mediaUpload = MediaUploadService();
  ClinicCatalogRepository._custom(this._api, this._mediaUpload);

  final ApiClient _api;
  final MediaUploadService _mediaUpload;

  /// Resolves local image files for entities backed by [MediaAsset] (Practitioners, Offers, Products, Articles).
  /// Uploads local files to /api/v1/media/upload/ first to obtain the asset UUID and public URL.
  Future<Map<String, dynamic>> _resolveMediaAssetPayload(
    Map<String, dynamic> data, {
    required String imageKey,
    required String mediaType,
  }) async {
    final payload = Map<String, dynamic>.from(data);
    if (!payload.containsKey(imageKey)) return payload;
    final rawValue = payload[imageKey];
    final rawVal = rawValue is String ? rawValue.trim() : rawValue;
    if (rawVal == null || rawVal == '') {
      // Clear both representations so a legacy URL cannot resurrect the image.
      payload[imageKey] = null;
      payload['media_asset'] = null;
    } else if (rawVal is MultipartFile) {
      return payload;
    } else if (!_isRemoteUrl(rawVal.toString())) {
      final uploadResult = await _mediaUpload.uploadImage(
        filePath: rawVal.toString(),
        mediaType: mediaType,
      );
      final assetId = uploadResult['id']?.toString().trim();
      final assetUrl = ApiConfig.firstMediaUrl([uploadResult['url']]);
      if (assetId == null || assetId.isEmpty || !_isRemoteUrl(assetUrl)) {
        throw const ApiException(
          message: 'The image upload response is missing its asset ID or URL.',
        );
      }
      payload['media_asset'] = assetId;
      payload[imageKey] = assetUrl;
    } else {
      payload[imageKey] = rawVal;
    }

    return payload;
  }

  Future<dynamic> _buildPayload(
    Map<String, dynamic> data, {
    required List<String> fileKeys,
  }) => MediaPayloadBuilder(_mediaUpload).build(data, fileKeys: fileKeys);

  static bool _isRemoteUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  dynamic _catalogPayload(Map<String, dynamic> payload) =>
      payload.values.any((value) => value is MultipartFile)
      ? FormData.fromMap(payload)
      : payload;

  // -------------------------------------------------------------
  // PRACTITIONERS
  // -------------------------------------------------------------

  Future<List<PractitionerModel>> getPractitioners({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    queryParams['page'] = page;
    queryParams['page_size'] = catalogPageSize;
    final response = await _api.get(
      ApiConfig.clinicPractitioners,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return PageItems<PractitionerModel>.fromResponse(
      response.data,
      PractitionerModel.fromJson,
      page: page,
    );
  }

  Future<PractitionerModel> createPractitioner(
    Map<String, dynamic> data,
  ) async {
    final session = SessionSnapshot();
    final payload = await _resolveMediaAssetPayload(
      data,
      imageKey: 'avatar',
      mediaType: 'practitioner_avatar',
    );
    session.ensureCurrent();
    final response = await _api.post(
      ApiConfig.clinicPractitioners,
      data: _catalogPayload(payload),
    );
    return PractitionerModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PractitionerModel> updatePractitioner(
    String id,
    Map<String, dynamic> data,
  ) async {
    final session = SessionSnapshot();
    final payload = await _resolveMediaAssetPayload(
      data,
      imageKey: 'avatar',
      mediaType: 'practitioner_avatar',
    );
    session.ensureCurrent();
    final response = await _api.patch(
      ApiConfig.clinicPractitionerDetail(id),
      data: _catalogPayload(payload),
    );
    return PractitionerModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePractitioner(String id) async {
    await _api.delete(ApiConfig.clinicPractitionerDetail(id));
  }

  // -------------------------------------------------------------
  // TREATMENTS
  // -------------------------------------------------------------

  Future<List<TreatmentModel>> getTreatments({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? category,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    queryParams['page'] = page;
    queryParams['page_size'] = catalogPageSize;
    final response = await _api.get(
      ApiConfig.clinicTreatments,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return PageItems<TreatmentModel>.fromResponse(
      response.data,
      TreatmentModel.fromJson,
      page: page,
    );
  }

  Future<TreatmentModel> createTreatment(Map<String, dynamic> data) async {
    final sanitized = Map<String, dynamic>.from(data);
    sanitized['category'] ??= sanitized.remove('category_id');
    if (sanitized['category'] == null ||
        sanitized['category'].toString().trim().isEmpty) {
      throw const ApiException(
        message: 'Select an existing medical category.',
        errorCode: 'CATEGORY_REQUIRED',
      );
    }
    sanitized.remove('category_id');
    sanitized.remove('duration_minutes');

    final response = await _api.post(
      ApiConfig.clinicTreatments,
      data: sanitized,
    );
    return TreatmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TreatmentModel> updateTreatment(
    String id,
    Map<String, dynamic> data,
  ) async {
    final sanitized = Map<String, dynamic>.from(data);
    if (!sanitized.containsKey('category') &&
        sanitized.containsKey('category_id')) {
      sanitized['category'] = sanitized['category_id'];
    }
    sanitized.remove('category_id');
    // Omission preserves existing M2M assignments; [] explicitly clears them.
    sanitized.remove('duration_minutes');

    final response = await _api.patch(
      ApiConfig.clinicTreatmentDetail(id),
      data: sanitized,
    );
    return TreatmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTreatment(String id) async {
    await _api.delete(ApiConfig.clinicTreatmentDetail(id));
  }

  // -------------------------------------------------------------
  // OFFERS
  // -------------------------------------------------------------

  Future<List<OfferModel>> getOffers({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    queryParams['page'] = page;
    queryParams['page_size'] = catalogPageSize;
    final response = await _api.get(
      ApiConfig.clinicOffers,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return PageItems<OfferModel>.fromResponse(
      response.data,
      OfferModel.fromJson,
      page: page,
    );
  }

  Future<OfferModel> createOffer(Map<String, dynamic> data) async {
    final session = SessionSnapshot();
    final payload = await _resolveMediaAssetPayload(
      data,
      imageKey: 'image',
      mediaType: 'offer_image',
    );
    session.ensureCurrent();
    final response = await _api.post(
      ApiConfig.clinicOffers,
      data: _catalogPayload(payload),
    );
    return OfferModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OfferModel> updateOffer(String id, Map<String, dynamic> data) async {
    final session = SessionSnapshot();
    final payload = await _resolveMediaAssetPayload(
      data,
      imageKey: 'image',
      mediaType: 'offer_image',
    );
    session.ensureCurrent();
    final response = await _api.patch(
      ApiConfig.clinicOfferDetail(id),
      data: _catalogPayload(payload),
    );
    return OfferModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OfferModel> updateOfferStatus(String id, String status) async {
    final response = await _api.patch(
      ApiConfig.clinicOfferDetail(id),
      data: {'status': status, 'is_active': status == 'active'},
    );
    return OfferModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteOffer(String id) async {
    await _api.delete(ApiConfig.clinicOfferDetail(id));
  }

  // -------------------------------------------------------------
  // PRODUCTS
  // -------------------------------------------------------------

  Future<List<ProductModel>> getProducts({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    queryParams['page'] = page;
    queryParams['page_size'] = catalogPageSize;
    final response = await _api.get(
      ApiConfig.clinicProducts,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return PageItems<ProductModel>.fromResponse(
      response.data,
      ProductModel.fromJson,
      page: page,
    );
  }

  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    final sanitized = Map<String, dynamic>.from(data);
    // Cosmetic brand showcases never send commercial price fields.
    sanitized.remove('price');
    final session = SessionSnapshot();
    final payload = await _resolveMediaAssetPayload(
      sanitized,
      imageKey: 'image',
      mediaType: 'product_image',
    );
    session.ensureCurrent();
    final response = await _api.post(
      ApiConfig.clinicProducts,
      data: _catalogPayload(payload),
    );
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProductModel> updateProduct(
    String id,
    Map<String, dynamic> data,
  ) async {
    final sanitized = Map<String, dynamic>.from(data);
    // Cosmetic brand showcases never send commercial price fields.
    sanitized.remove('price');
    final session = SessionSnapshot();
    final payload = await _resolveMediaAssetPayload(
      sanitized,
      imageKey: 'image',
      mediaType: 'product_image',
    );
    session.ensureCurrent();
    final response = await _api.patch(
      ApiConfig.clinicProductDetail(id),
      data: _catalogPayload(payload),
    );
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteProduct(String id) async {
    await _api.delete(ApiConfig.clinicProductDetail(id));
  }

  // -------------------------------------------------------------
  // ARTICLES
  // -------------------------------------------------------------

  Future<List<ArticleModel>> getArticles({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    queryParams['page'] = page;
    queryParams['page_size'] = catalogPageSize;
    final response = await _api.get(
      ApiConfig.clinicArticles,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return PageItems<ArticleModel>.fromResponse(
      response.data,
      ArticleModel.fromJson,
      page: page,
    );
  }

  Future<ArticleModel> createArticle(Map<String, dynamic> data) async {
    final sanitized = Map<String, dynamic>.from(data);
    if (sanitized['cover_image'] == null && sanitized['image'] != null) {
      sanitized['cover_image'] = sanitized['image'];
    }
    sanitized.remove('image');
    final session = SessionSnapshot();
    final payload = await _resolveMediaAssetPayload(
      sanitized,
      imageKey: 'cover_image',
      mediaType: 'article_cover',
    );
    session.ensureCurrent();
    final response = await _api.post(
      ApiConfig.clinicArticles,
      data: _catalogPayload(payload),
    );
    return ArticleModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ArticleModel> updateArticle(
    String id,
    Map<String, dynamic> data,
  ) async {
    final sanitized = Map<String, dynamic>.from(data);
    if (sanitized['cover_image'] == null && sanitized['image'] != null) {
      sanitized['cover_image'] = sanitized['image'];
    }
    sanitized.remove('image');
    final session = SessionSnapshot();
    final payload = await _resolveMediaAssetPayload(
      sanitized,
      imageKey: 'cover_image',
      mediaType: 'article_cover',
    );
    session.ensureCurrent();
    final response = await _api.patch(
      ApiConfig.clinicArticleDetail(id),
      data: _catalogPayload(payload),
    );
    return ArticleModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteArticle(String id) async {
    await _api.delete(ApiConfig.clinicArticleDetail(id));
  }

  // -------------------------------------------------------------
  // CATEGORIES (for treatment categorization)
  // -------------------------------------------------------------

  Future<List<CategoryModel>> getCategories({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final response = await _api.get(
      ApiConfig.categories,
      queryParameters: {
        'page': page,
        'page_size': catalogPageSize,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    return PageItems<CategoryModel>.fromResponse(
      response.data,
      CategoryModel.fromJson,
      page: page,
    );
  }

  // -------------------------------------------------------------
  // CLINIC PROFILE (GET & PATCH /api/v1/clinic-portal/profile/)
  // -------------------------------------------------------------

  Future<ClinicModel> getClinicProfile() async {
    final response = await _api.get(ApiConfig.clinicProfile);
    final body = response.data;
    final rawData = body is Map<String, dynamic>
        ? (body['data'] ?? body)
        : body;
    return ClinicModel.fromJson(rawData as Map<String, dynamic>);
  }

  Future<ClinicModel> updateClinicProfile(Map<String, dynamic> data) async {
    final session = SessionSnapshot();
    final requestData = await _buildPayload(
      data,
      fileKeys: ['logo', 'cover_image', 'video_ad_file'],
    );

    session.ensureCurrent();
    final response = await _api.patch(
      ApiConfig.clinicProfile,
      data: requestData,
    );
    final body = response.data;
    final rawData = body is Map<String, dynamic>
        ? (body['data'] ?? body)
        : body;
    return ClinicModel.fromJson(rawData as Map<String, dynamic>);
  }

  // -------------------------------------------------------------
  // CLINIC BRANCHES (CRUD /api/v1/clinic-portal/branches/)
  // -------------------------------------------------------------

  Future<List<ClinicBranch>> getBranches({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _api.get(
      ApiConfig.clinicBranches,
      queryParameters: {'page': page, 'page_size': catalogPageSize},
    );
    return PageItems<ClinicBranch>.fromResponse(
      response.data,
      ClinicBranch.fromJson,
      page: page,
    );
  }

  Future<ClinicBranch> createBranch(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConfig.clinicBranches, data: data);
    final body = response.data;
    final rawData = body is Map<String, dynamic>
        ? (body['data'] ?? body)
        : body;
    return ClinicBranch.fromJson(rawData as Map<String, dynamic>);
  }

  Future<ClinicBranch> updateBranch(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.patch(
      ApiConfig.clinicBranchDetail(id),
      data: data,
    );
    final body = response.data;
    final rawData = body is Map<String, dynamic>
        ? (body['data'] ?? body)
        : body;
    return ClinicBranch.fromJson(rawData as Map<String, dynamic>);
  }

  Future<void> deleteBranch(String id) async {
    await _api.delete(ApiConfig.clinicBranchDetail(id));
  }

  // -------------------------------------------------------------
  // ONBOARDING & SETUP CHECKLIST
  // -------------------------------------------------------------

  Future<ClinicSetupChecklistModel> getSetupChecklist() async {
    final response = await _api.get(ApiConfig.clinicSetupChecklist);
    final body = response.data;
    final rawData = body is Map<String, dynamic>
        ? (body['data'] ?? body)
        : body;
    return ClinicSetupChecklistModel.fromJson(rawData as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> submitProfileForReview() async {
    final response = await _api.post(ApiConfig.clinicSubmitForReview, data: {});
    return response.data as Map<String, dynamic>? ?? {};
  }

  Future<CategoryModel> createCategory({
    required String nameEn,
    required String nameAr,
  }) => CategoryRepository(
    apiClient: _api,
  ).createCategory(nameEn: nameEn, nameAr: nameAr);
  Future<CategoryModel> updateCategory(
    String id, {
    required String nameEn,
    required String nameAr,
  }) => CategoryRepository(
    apiClient: _api,
  ).updateCategory(id, nameEn: nameEn, nameAr: nameAr);
  Future<void> deleteCategory(String id) =>
      CategoryRepository(apiClient: _api).deleteCategory(id);
}
