import '../../../core/localization/app_locale.dart';
import '../../../core/auth/guest_auth_guard.dart';
import '../../../core/auth/session_snapshot.dart';
import '../../../core/data/paged_collection.dart';
import '../../../core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/media_payload_builder.dart';
import '../../../core/services/media_upload_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../offers/models/offer_model.dart';
import '../../products/models/product_model.dart';
import '../../articles/models/article_model.dart';
import '../models/admin_analytics_model.dart';
import '../models/admin_reporting_period.dart';
import '../models/admin_clinic_model.dart';
import '../models/admin_dashboard_model.dart';
import '../models/admin_lead_model.dart';

/// Repository handling Super Admin API operations across the platform
class AdminRepository {
  static final clinicReviewDecisions = ValueNotifier<int>(0);
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

  static Map<String, dynamic> _moderationRow(
    Map<String, dynamic> row,
    String? filter,
  ) {
    final state =
        row['status']?.toString().toLowerCase() ??
        (['active', 'pending', 'suspended', 'rejected'].contains(filter)
            ? filter!
            : 'unknown');
    return {
      ...row,
      'status': state,
      'is_active': state == 'active' && row['is_active'] != false,
    };
  }

  static Map<String, dynamic> _object(dynamic value) {
    if (value is Map<String, dynamic> &&
        value['data'] is Map<String, dynamic>) {
      return value['data'];
    }
    if (value is Map<String, dynamic>) return value;
    throw const ApiException(
      message:
          'The server returned an invalid response. Please refresh before retrying.',
    );
  }

  // -------------------------------------------------------------
  // 1. DASHBOARD
  // -------------------------------------------------------------

  Future<AdminDashboardModel> getDashboard() async {
    final response = await _api.get(ApiConfig.adminDashboard);
    return AdminDashboardModel.fromJson(_object(response.data));
  }

  // -------------------------------------------------------------
  // 2. CLINICS
  // -------------------------------------------------------------

  Future<List<AdminClinicModel>> getClinics({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? tier,
    String? setupStatus,
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

    if (setupStatus != null && setupStatus != 'all') {
      if (![
        'draft',
        'submitted',
        'approved',
        'rejected',
      ].contains(setupStatus)) {
        throw ArgumentError.value(setupStatus, 'setupStatus');
      }
      queryParams['setup_status'] = setupStatus;
    }
    queryParams['page'] = page;
    queryParams['page_size'] = catalogPageSize;
    final response = await _api.get(
      ApiConfig.adminClinics,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final rows = PageItems<AdminClinicModel>.fromResponse(
      response.data,
      AdminClinicModel.fromJson,
      page: page,
    );
    if (setupStatus != null &&
        setupStatus != 'all' &&
        rows.any((row) => row.setupStatus != setupStatus)) {
      throw ApiException(
        message: LocaleService().isArabic
            ? 'لم يطبق الخادم مرشح مراجعة الملف. حدّث البيانات وتحقق من إصدار الخادم.'
            : 'The server did not apply the setup review filter. Refresh and verify the backend version.',
      );
    }
    return rows;
  }

  Future<AdminClinicModel> getClinicDetail(String id) async {
    final response = await _api.get(ApiConfig.adminClinicDetail(id));
    return AdminClinicModel.fromJson(_object(response.data));
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

  /// Setup approval is distinct from ordinary activation. Django verify also
  /// activates the clinic; callers must explicitly confirm both effects.
  Future<AdminClinicModel> approveClinicProfile(String id) async {
    if (!AuthState().isLoggedIn || !AuthState().isSuperAdmin) {
      throw const ApiException(
        message: 'Super Admin access is required.',
        statusCode: 403,
      );
    }
    final session = SessionSnapshot();
    // Re-read after the confirmation dialog; a stale inbox must not re-approve
    // an already reviewed profile. Django independently guards the transition.
    final latest = await getClinicDetail(id);
    session.ensureCurrent();
    if (latest.id != id || latest.setupStatus != 'submitted') {
      throw ApiException(
        message: LocaleService().isArabic
            ? 'تغيرت حالة الملف. حدّث المراجعة قبل اتخاذ إجراء.'
            : 'The profile status changed. Refresh before reviewing.',
      );
    }
    final response = await _api.post(
      ApiConfig.adminClinicVerify(id),
      data: {'reason': 'Clinic profile approved through platform review.'},
    );
    session.ensureCurrent();
    final ack = _object(response.data);
    if (ack['status'] != 'success' ||
        ack['clinic_id']?.toString() != id ||
        ack['setup_status'] != 'approved' ||
        ack['new_status'] != 'active') {
      throw const ApiException(
        message:
            'The profile approval response could not be verified. Refresh before retrying.',
      );
    }
    final refreshed = await getClinicDetail(id);
    session.ensureCurrent();
    if (refreshed.id != id ||
        refreshed.setupStatus != 'approved' ||
        refreshed.status != 'active') {
      throw const ApiException(
        message: 'Please refresh the clinic review status.',
      );
    }
    clinicReviewDecisions.value++;
    return refreshed;
  }

  Future<AdminClinicModel> rejectClinicSetup(String id, String reason) async {
    if (!AuthState().isLoggedIn || !AuthState().isSuperAdmin) {
      throw const ApiException(
        message: 'Super Admin access is required.',
        statusCode: 403,
      );
    }
    final text = reason.trim();
    if (text.isEmpty || text.length > 1000) {
      throw ApiException(
        message: LocaleService().isArabic
            ? 'أدخل سبباً واضحاً من 1 إلى 1000 حرف.'
            : 'Enter a clear reason from 1 to 1000 characters.',
        statusCode: 400,
      );
    }
    final session = SessionSnapshot();
    final latest = await getClinicDetail(id);
    session.ensureCurrent();
    if (latest.id != id || latest.setupStatus != 'submitted') {
      throw ApiException(
        message: LocaleService().isArabic
            ? 'تغيرت حالة الملف. حدّث المراجعة.'
            : 'The profile status changed. Refresh the review.',
        statusCode: 409,
        errorCode: 'INVALID_SETUP_TRANSITION',
      );
    }
    final result = await _api.post(
      ApiConfig.adminClinicRejectSetup(id),
      data: {'rejection_reason': text},
    );
    session.ensureCurrent();
    final ack = _object(result.data);
    if (ack['status'] != 'success' ||
        ack['clinic_id']?.toString() != id ||
        ack['setup_status'] != 'rejected' ||
        ack['rejection_reason'] != text) {
      throw const ApiException(
        message:
            'The server did not confirm the review decision. Refresh before retrying.',
      );
    }
    final refreshed = await getClinicDetail(id);
    session.ensureCurrent();
    if (refreshed.id != id ||
        refreshed.setupStatus != 'rejected' ||
        refreshed.moderationNotes != text) {
      throw const ApiException(
        message:
            'The saved rejection could not be verified. Refresh before retrying.',
      );
    }
    clinicReviewDecisions.value++;
    return refreshed;
  }

  /// Atomically provision a new Clinic and its initial Administrator
  Future<Map<String, dynamic>> createClinic(Map<String, dynamic> data) async {
    final session = SessionSnapshot();
    final payload = await _buildPayload(
      data,
      fileKeys: ['logo', 'cover_image', 'video_ad_file'],
    );
    session.ensureCurrent();
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
    final session = SessionSnapshot();
    final payload = await _buildPayload(
      data,
      fileKeys: ['logo', 'cover_image', 'video_ad_file'],
      clinicId: id,
    );
    session.ensureCurrent();
    final response = await _api.patch(
      ApiConfig.adminClinicDetail(id),
      data: payload,
    );
    return AdminClinicModel.fromJson(_object(response.data));
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
    String? dateFrom,
    String? dateTo,
  }) async {
    AdminReportingPeriod.validate(dateFrom, dateTo);
    final queryParams = <String, dynamic>{
      'date_from': ?dateFrom,
      'date_to': ?dateTo,
    };
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
    return AdminLeadModel.fromJson(_object(response.data));
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
      (row) => OfferModel.fromJson(_moderationRow(row, status)),
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
      (row) => ProductModel.fromJson(_moderationRow(row, status)),
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
      (row) => ArticleModel.fromJson(_moderationRow(row, status)),
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
    AdminReportingPeriod.validate(dateFrom, dateTo);
    final queryParams = <String, dynamic>{};
    if (dateFrom != null && dateFrom.isNotEmpty) {
      queryParams['date_from'] = dateFrom;
    }
    if (dateTo != null && dateTo.isNotEmpty) queryParams['date_to'] = dateTo;

    final response = await _api.get(
      ApiConfig.adminAnalytics,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final result = AdminAnalyticsModel.fromJson(_object(response.data));
    if ((dateFrom != null && result.dateFrom != dateFrom) ||
        (dateTo != null && result.dateTo != dateTo)) {
      throw ApiException(
        message: LocaleService().isArabic
            ? 'لم يؤكد الخادم فترة التقرير. حدّث البيانات قبل استخدام الأرقام.'
            : 'The server did not confirm the reporting dates. Refresh before using these figures.',
      );
    }
    return result;
  }

  Future<AdminReferralAnalyticsModel> getReferralAnalytics() async {
    final response = await _api.get(ApiConfig.adminReferralAnalytics);
    return AdminReferralAnalyticsModel.fromJson(_object(response.data));
  }
}
