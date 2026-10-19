import '../../../core/data/paged_collection.dart';
import 'package:dio/dio.dart';
import '../../../core/services/media_payload_builder.dart';
import '../../../core/services/media_upload_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../offers/models/offer_model.dart';
import '../../products/models/product_model.dart';
import '../../articles/models/article_model.dart';
import '../models/admin_analytics_model.dart';
import '../models/admin_clinic_model.dart';
import '../models/admin_dashboard_model.dart';
import '../models/admin_lead_model.dart';

/// Repository handling Super Admin API operations across the platform
class AdminRepository {
  static final AdminRepository _instance = AdminRepository._internal();
  factory AdminRepository({
    ApiClient? apiClient,
    MediaUploadService? mediaUploadService,
  }) {
    if (apiClient != null || mediaUploadService != null) {
      final client = apiClient ?? ApiClient();
      return AdminRepository._custom(
        client,
        mediaUploadService ?? MediaUploadService(client: client),
      );
    }
    return _instance;
  }
  AdminRepository._internal()
    : _api = ApiClient(),
      _mediaUpload = MediaUploadService();
  AdminRepository._custom(this._api, this._mediaUpload);

  final ApiClient _api;
  final MediaUploadService _mediaUpload;

  Future<dynamic> _buildPayload(
    Map<String, dynamic> data, {
    required List<String> fileKeys,
    String? clinicId,
  }) async {
    final payload = await MediaPayloadBuilder(
      _mediaUpload,
    ).build(data, fileKeys: fileKeys, clinicId: clinicId);
    if (payload is FormData && data['admin_user'] is Map) {
      // Flat keys are part of the provisioning contract handed off to Ali.
      payload.fields.removeWhere(
        (field) => field.key.startsWith('admin_user['),
      );
      for (final entry in (data['admin_user'] as Map).entries) {
        final name = entry.key == 'temporary_password'
            ? 'admin_temporary_password'
            : 'admin_${entry.key}';
        payload.fields.add(MapEntry(name, entry.value?.toString() ?? ''));
      }
    }
    return payload;
  }

  // -------------------------------------------------------------
  // 1. DASHBOARD
  // -------------------------------------------------------------

  Future<AdminDashboardModel> getDashboard() async {
    final response = await _api.get(ApiConfig.adminDashboard);
    return AdminDashboardModel.fromJson(response.data as Map<String, dynamic>);
  }

  // -------------------------------------------------------------
  // 2. CLINICS
  // -------------------------------------------------------------

  Future<List<AdminClinicModel>> getClinics({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? tier,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      queryParams['status'] = status.toLowerCase();
    }
    if (tier != null && tier.isNotEmpty && tier.toLowerCase() != 'all') {
      queryParams['tier'] = tier.toLowerCase();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    queryParams['page'] = page;
    queryParams['page_size'] = catalogPageSize;
    final response = await _api.get(
      ApiConfig.adminClinics,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return PageItems<AdminClinicModel>.fromResponse(
      response.data,
      AdminClinicModel.fromJson,
      page: page,
    );
  }

  Future<AdminClinicModel> getClinicDetail(String id) async {
    final response = await _api.get(ApiConfig.adminClinicDetail(id));
    return AdminClinicModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> suspendClinic(
    String id, {
    String reason = '',
  }) async {
    final response = await _api.post(
      ApiConfig.adminClinicSuspend(id),
      data: {'reason': reason},
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> activateClinic(
    String id, {
    String reason = '',
  }) async {
    final response = await _api.post(
      ApiConfig.adminClinicActivate(id),
      data: {'reason': reason},
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  /// Atomically provision a new Clinic and its initial Administrator
  Future<Map<String, dynamic>> createClinic(Map<String, dynamic> data) async {
    final payload = await _buildPayload(
      data,
      fileKeys: ['logo', 'cover_image', 'video_ad_file'],
    );
    final response = await _api.post(ApiConfig.adminClinics, data: payload);
    return response.data as Map<String, dynamic>? ?? {};
  }

  /// Reset temporary password for a Clinic Administrator
  Future<Map<String, dynamic>> resetClinicAdminPassword(
    String clinicId, {
    String? customPassword,
  }) async {
    final payload = <String, dynamic>{};
    if (customPassword != null && customPassword.trim().isNotEmpty) {
      payload['custom_password'] = customPassword.trim();
    }
    final response = await _api.post(
      ApiConfig.adminClinicResetPassword(clinicId),
      data: payload,
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  /// Archive / Soft-delete a clinic and all associated catalog entities
  Future<void> archiveClinic(String clinicId) async {
    await _api.delete(ApiConfig.adminClinicDetail(clinicId));
  }

  /// Update clinic details and settings (`PATCH /api/v1/admin/clinics/{id}/`)
  Future<AdminClinicModel> updateClinic(
    String id,
    Map<String, dynamic> data,
  ) async {
    final payload = await _buildPayload(
      data,
      fileKeys: ['logo', 'cover_image', 'video_ad_file'],
      clinicId: id,
    );
    final response = await _api.patch(
      ApiConfig.adminClinicDetail(id),
      data: payload,
    );
    return AdminClinicModel.fromJson(response.data as Map<String, dynamic>);
  }

  // -------------------------------------------------------------
  // 3. LEADS (READ-ONLY SUPERVISION)
  // -------------------------------------------------------------

  Future<List<AdminLeadModel>> getLeads({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? clinicId,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      queryParams['status'] = status.toLowerCase();
    }
    if (clinicId != null && clinicId.isNotEmpty && clinicId != 'all') {
      queryParams['clinic'] = clinicId;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    queryParams['page'] = page;
    queryParams['page_size'] = catalogPageSize;
    final response = await _api.get(
      ApiConfig.adminLeads,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return PageItems<AdminLeadModel>.fromResponse(
      response.data,
      AdminLeadModel.fromJson,
      page: page,
    );
  }

  Future<AdminLeadModel> getLeadDetail(String id) async {
    final response = await _api.get(ApiConfig.adminLeadDetail(id));
    return AdminLeadModel.fromJson(response.data as Map<String, dynamic>);
  }

  // -------------------------------------------------------------
  // 4. OFFERS MODERATION
  // -------------------------------------------------------------

  Future<List<OfferModel>> getOffers({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? clinicId,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      queryParams['status'] = status.toLowerCase();
    }
    if (clinicId != null && clinicId.isNotEmpty && clinicId != 'all') {
      queryParams['clinic'] = clinicId;
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    queryParams['page'] = page;
    queryParams['page_size'] = catalogPageSize;
    final response = await _api.get(
      ApiConfig.adminOffers,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return PageItems<OfferModel>.fromResponse(
      response.data,
      OfferModel.fromJson,
      page: page,
    );
  }

  Future<Map<String, dynamic>> approveOffer(
    String id, {
    String notes = '',
  }) async {
    final response = await _api.post(
      ApiConfig.adminOfferApprove(id),
      data: {
        'moderation_notes': notes.isNotEmpty
            ? notes
            : 'Approved by Super Admin',
      },
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> suspendOffer(
    String id, {
    String notes = '',
  }) async {
    final response = await _api.post(
      ApiConfig.adminOfferSuspend(id),
      data: {
        'moderation_notes': notes.isNotEmpty
            ? notes
            : 'Suspended by Super Admin',
      },
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  // -------------------------------------------------------------
  // 5. PRODUCTS MODERATION
  // -------------------------------------------------------------

  Future<List<ProductModel>> getProducts({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? clinicId,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      queryParams['status'] = status.toLowerCase();
    }
    if (clinicId != null && clinicId.isNotEmpty && clinicId != 'all') {
      queryParams['clinic'] = clinicId;
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    queryParams['page'] = page;
    queryParams['page_size'] = catalogPageSize;
    final response = await _api.get(
      ApiConfig.adminProducts,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return PageItems<ProductModel>.fromResponse(
      response.data,
      ProductModel.fromJson,
      page: page,
    );
  }

  Future<Map<String, dynamic>> approveProduct(
    String id, {
    String notes = '',
  }) async {
    final response = await _api.post(
      ApiConfig.adminProductApprove(id),
      data: {
        'moderation_notes': notes.isNotEmpty
            ? notes
            : 'Approved by Super Admin',
      },
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> suspendProduct(
    String id, {
    String notes = '',
  }) async {
    final response = await _api.post(
      ApiConfig.adminProductSuspend(id),
      data: {
        'moderation_notes': notes.isNotEmpty
            ? notes
            : 'Suspended by Super Admin',
      },
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  // -------------------------------------------------------------
  // 6. ARTICLES MODERATION
  // -------------------------------------------------------------

  Future<List<ArticleModel>> getArticles({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? clinicId,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      queryParams['status'] = status.toLowerCase();
    }
    if (clinicId != null && clinicId.isNotEmpty && clinicId != 'all') {
      queryParams['clinic'] = clinicId;
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    queryParams['page'] = page;
    queryParams['page_size'] = catalogPageSize;
    final response = await _api.get(
      ApiConfig.adminArticles,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return PageItems<ArticleModel>.fromResponse(
      response.data,
      ArticleModel.fromJson,
      page: page,
    );
  }

  Future<Map<String, dynamic>> approveArticle(
    String id, {
    String notes = '',
  }) async {
    final response = await _api.post(
      ApiConfig.adminArticleApprove(id),
      data: {
        'moderation_notes': notes.isNotEmpty
            ? notes
            : 'Approved by Super Admin',
      },
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> suspendArticle(
    String id, {
    String notes = '',
  }) async {
    final response = await _api.post(
      ApiConfig.adminArticleSuspend(id),
      data: {
        'moderation_notes': notes.isNotEmpty
            ? notes
            : 'Suspended by Super Admin',
      },
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  // -------------------------------------------------------------
  // 5. ANALYTICS
  // -------------------------------------------------------------

  Future<AdminAnalyticsModel> getAnalytics({
    String? dateFrom,
    String? dateTo,
  }) async {
    final queryParams = <String, dynamic>{};
    if (dateFrom != null && dateFrom.isNotEmpty) {
      queryParams['date_from'] = dateFrom;
    }
    if (dateTo != null && dateTo.isNotEmpty) queryParams['date_to'] = dateTo;

    final response = await _api.get(
      ApiConfig.adminAnalytics,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return AdminAnalyticsModel.fromJson(response.data as Map<String, dynamic>);
  }
}
