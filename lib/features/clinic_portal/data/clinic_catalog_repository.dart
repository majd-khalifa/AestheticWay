import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/services/media_upload_service.dart';
import '../../articles/models/article_model.dart';
import '../../clinics/models/clinic_model.dart';
import '../../offers/models/offer_model.dart';
import '../../practitioners/models/practitioner_model.dart';
import '../../products/models/product_model.dart';
import '../../treatments/models/category_model.dart';
import '../../treatments/models/treatment_model.dart';
import 'models/clinic_setup_checklist_model.dart';

/// Repository for Clinic Partner Catalog Management (Practitioners, Treatments, Offers, Products, Articles, Categories)
class ClinicCatalogRepository {
  static final ClinicCatalogRepository _instance = ClinicCatalogRepository._internal();
  factory ClinicCatalogRepository({ApiClient? apiClient, MediaUploadService? mediaUploadService}) {
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
    final rawVal = payload[imageKey]?.toString();

    if (rawVal != null &&
        rawVal.isNotEmpty &&
        !rawVal.startsWith('http') &&
        File(rawVal).existsSync()) {
      try {
        final uploadResult = await _mediaUpload.uploadImage(
          filePath: rawVal,
          mediaType: mediaType,
        );
        final assetId = uploadResult['id']?.toString();
        final assetUrl = uploadResult['url']?.toString();

        if (assetId != null && assetId.isNotEmpty) {
          payload['media_asset'] = assetId;
        }
        if (assetUrl != null && assetUrl.isNotEmpty) {
          payload[imageKey] = assetUrl;
        } else {
          payload.remove(imageKey);
        }
      } catch (e) {
        debugPrint('[ClinicCatalogRepository] Media upload failed for $imageKey: $e');
        payload.remove(imageKey);
      }
    } else if (rawVal != null && (rawVal.isEmpty || !rawVal.startsWith('http'))) {
      payload.remove(imageKey);
    }

    return payload;
  }

  Future<dynamic> _buildPayload(
    Map<String, dynamic> data, {
    required List<String> fileKeys,
  }) async {
    final mapCopy = Map<String, dynamic>.from(data);
    bool hasLocalFiles = false;
    final Map<String, File> localFiles = {};

    for (final key in fileKeys) {
      final val = mapCopy[key]?.toString();
      if (val != null && val.isNotEmpty && !val.startsWith('http')) {
        final f = File(val);
        if (f.existsSync()) {
          hasLocalFiles = true;
          localFiles[key] = f;
        } else {
          mapCopy.remove(key);
        }
      } else {
        // null, empty, or existing remote URL -> omit so Django keeps existing image
        mapCopy.remove(key);
      }
    }

    if (hasLocalFiles) {
      final formDataMap = <String, dynamic>{};
      for (final entry in mapCopy.entries) {
        if (localFiles.containsKey(entry.key)) {
          final f = localFiles[entry.key]!;
          formDataMap[entry.key] = await MultipartFile.fromFile(
            f.path,
            filename: f.path.split(Platform.pathSeparator).last,
          );
        } else {
          formDataMap[entry.key] = entry.value;
        }
      }
      for (final entry in localFiles.entries) {
        if (!formDataMap.containsKey(entry.key)) {
          formDataMap[entry.key] = await MultipartFile.fromFile(
            entry.value.path,
            filename: entry.value.path.split(Platform.pathSeparator).last,
          );
        }
      }
      return FormData.fromMap(formDataMap);
    } else {
      return mapCopy;
    }
  }


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
    final payload = await _resolveMediaAssetPayload(
      data,
      imageKey: 'avatar',
      mediaType: 'practitioner_avatar',
    );
    final response = await _api.post(
      ApiConfig.clinicPractitioners,
      data: payload,
    );
    return PractitionerModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PractitionerModel> updatePractitioner(String id, Map<String, dynamic> data) async {
    final payload = await _resolveMediaAssetPayload(
      data,
      imageKey: 'avatar',
      mediaType: 'practitioner_avatar',
    );
    final response = await _api.patch(
      ApiConfig.clinicPractitionerDetail(id),
      data: payload,
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
    final sanitized = Map<String, dynamic>.from(data);
    if (sanitized['category'] == null || sanitized['category'].toString().trim().isEmpty) {
      if (sanitized['category_id'] != null && sanitized['category_id'].toString().trim().isNotEmpty) {
        sanitized['category'] = sanitized['category_id'];
      } else {
        try {
          final cats = await getCategories();
          if (cats.isNotEmpty) {
            sanitized['category'] = cats.first.id;
          }
        } catch (_) {}
      }
    }
    if (sanitized['category'] != null) {
      sanitized['category_id'] = sanitized['category'];
    }
    if (sanitized['practitioners'] == null || (sanitized['practitioners'] is List && (sanitized['practitioners'] as List).isEmpty)) {
      sanitized['practitioners'] = <String>[];
    }
    sanitized.remove('duration_minutes');

    final response = await _api.post(
      ApiConfig.clinicTreatments,
      data: sanitized,
    );
    return TreatmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TreatmentModel> updateTreatment(String id, Map<String, dynamic> data) async {
    final sanitized = Map<String, dynamic>.from(data);
    if (sanitized['category'] != null) {
      sanitized['category_id'] = sanitized['category'];
    }
    if (sanitized['practitioners'] == null || (sanitized['practitioners'] is List && (sanitized['practitioners'] as List).isEmpty)) {
      sanitized['practitioners'] = <String>[];
    }
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
    final payload = await _resolveMediaAssetPayload(
      data,
      imageKey: 'image',
      mediaType: 'offer_image',
    );
    final response = await _api.post(
      ApiConfig.clinicOffers,
      data: payload,
    );
    return OfferModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OfferModel> updateOffer(String id, Map<String, dynamic> data) async {
    final payload = await _resolveMediaAssetPayload(
      data,
      imageKey: 'image',
      mediaType: 'offer_image',
    );
    final response = await _api.patch(
      ApiConfig.clinicOfferDetail(id),
      data: payload,
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
    final sanitized = Map<String, dynamic>.from(data);
    if (sanitized.containsKey('price') &&
        (sanitized['price'] == null || sanitized['price'].toString().trim().isEmpty)) {
      sanitized.remove('price');
    }
    final payload = await _resolveMediaAssetPayload(
      sanitized,
      imageKey: 'image',
      mediaType: 'product_image',
    );
    final response = await _api.post(
      ApiConfig.clinicProducts,
      data: payload,
    );
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProductModel> updateProduct(String id, Map<String, dynamic> data) async {
    final sanitized = Map<String, dynamic>.from(data);
    if (sanitized.containsKey('price') &&
        (sanitized['price'] == null || sanitized['price'].toString().trim().isEmpty)) {
      sanitized.remove('price');
    }
    final payload = await _resolveMediaAssetPayload(
      sanitized,
      imageKey: 'image',
      mediaType: 'product_image',
    );
    final response = await _api.patch(
      ApiConfig.clinicProductDetail(id),
      data: payload,
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
    final sanitized = Map<String, dynamic>.from(data);
    if (sanitized['cover_image'] == null && sanitized['image'] != null) {
      sanitized['cover_image'] = sanitized['image'];
    }
    sanitized.remove('image');
    final payload = await _resolveMediaAssetPayload(
      sanitized,
      imageKey: 'cover_image',
      mediaType: 'article_cover',
    );
    final response = await _api.post(
      ApiConfig.clinicArticles,
      data: payload,
    );
    return ArticleModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ArticleModel> updateArticle(String id, Map<String, dynamic> data) async {
    final sanitized = Map<String, dynamic>.from(data);
    if (sanitized['cover_image'] == null && sanitized['image'] != null) {
      sanitized['cover_image'] = sanitized['image'];
    }
    sanitized.remove('image');
    final payload = await _resolveMediaAssetPayload(
      sanitized,
      imageKey: 'cover_image',
      mediaType: 'article_cover',
    );
    final response = await _api.patch(
      ApiConfig.clinicArticleDetail(id),
      data: payload,
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
    if (rawData is Map<String, dynamic>) {
      if (rawData.containsKey('results') && rawData['results'] is List) {
        items = rawData['results'] as List<dynamic>;
      } else if (rawData.containsKey('data')) {
        final d = rawData['data'];
        if (d is List) {
          items = d;
        } else if (d is Map && d.containsKey('results') && d['results'] is List) {
          items = d['results'] as List<dynamic>;
        }
      }
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
    final requestData = await _buildPayload(
      data,
      fileKeys: ['logo', 'cover_image', 'video_ad_file'],
    );

    final response = await _api.patch(
      ApiConfig.clinicProfile,
      data: requestData,
    );
    final body = response.data;
    final rawData = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
    return ClinicModel.fromJson(rawData as Map<String, dynamic>);
  }

  // -------------------------------------------------------------
  // CLINIC BRANCHES (CRUD /api/v1/clinic-portal/branches/)
  // -------------------------------------------------------------

  Future<List<ClinicBranch>> getBranches() async {
    final response = await _api.get(ApiConfig.clinicBranches);
    final rawData = response.data;
    List<dynamic> items = [];
    if (rawData is Map<String, dynamic> && rawData.containsKey('results')) {
      items = rawData['results'] as List<dynamic>? ?? [];
    } else if (rawData is List) {
      items = rawData;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((m) => ClinicBranch.fromJson(m))
        .toList();
  }

  Future<ClinicBranch> createBranch(Map<String, dynamic> data) async {
    final response = await _api.post(
      ApiConfig.clinicBranches,
      data: data,
    );
    final body = response.data;
    final rawData = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
    return ClinicBranch.fromJson(rawData as Map<String, dynamic>);
  }

  Future<ClinicBranch> updateBranch(String id, Map<String, dynamic> data) async {
    final response = await _api.patch(
      ApiConfig.clinicBranchDetail(id),
      data: data,
    );
    final body = response.data;
    final rawData = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
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
    final rawData = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
    return ClinicSetupChecklistModel.fromJson(rawData as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> submitProfileForReview() async {
    final response = await _api.post(
      ApiConfig.clinicSubmitForReview,
      data: {},
    );
    return response.data as Map<String, dynamic>? ?? {};
  }
}
