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
  factory AdminRepository({ApiClient? apiClient}) {
    if (apiClient != null) {
      return AdminRepository._custom(apiClient);
    }
    return _instance;
  }
  AdminRepository._internal() : _api = ApiClient();
  AdminRepository._custom(this._api);

  final ApiClient _api;

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

    final response = await _api.get(
      ApiConfig.adminClinics,
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
        .map((c) => AdminClinicModel.fromJson(c))
        .toList();
  }

  Future<AdminClinicModel> getClinicDetail(String id) async {
    final response = await _api.get(ApiConfig.adminClinicDetail(id));
    return AdminClinicModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> suspendClinic(String id, {String reason = ''}) async {
    final response = await _api.post(
      ApiConfig.adminClinicSuspend(id),
      data: {'reason': reason},
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> activateClinic(String id, {String reason = ''}) async {
    final response = await _api.post(
      ApiConfig.adminClinicActivate(id),
      data: {'reason': reason},
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  // -------------------------------------------------------------
  // 3. LEADS (READ-ONLY SUPERVISION)
  // -------------------------------------------------------------

  Future<List<AdminLeadModel>> getLeads({
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

    final response = await _api.get(
      ApiConfig.adminLeads,
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
        .map((l) => AdminLeadModel.fromJson(l))
        .toList();
  }

  Future<AdminLeadModel> getLeadDetail(String id) async {
    final response = await _api.get(ApiConfig.adminLeadDetail(id));
    return AdminLeadModel.fromJson(response.data as Map<String, dynamic>);
  }

  // -------------------------------------------------------------
  // 4. OFFERS MODERATION
  // -------------------------------------------------------------

  Future<List<OfferModel>> getOffers({
    String? status,
    String? clinicId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      queryParams['status'] = status.toLowerCase();
    }
    if (clinicId != null && clinicId.isNotEmpty && clinicId != 'all') {
      queryParams['clinic'] = clinicId;
    }

    final response = await _api.get(
      ApiConfig.adminOffers,
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
        .map((o) => OfferModel.fromJson(o))
        .toList();
  }

  Future<Map<String, dynamic>> approveOffer(String id, {String notes = ''}) async {
    final response = await _api.post(
      ApiConfig.adminOfferApprove(id),
      data: {'moderation_notes': notes.isNotEmpty ? notes : 'Approved by Super Admin'},
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> suspendOffer(String id, {String notes = ''}) async {
    final response = await _api.post(
      ApiConfig.adminOfferSuspend(id),
      data: {'moderation_notes': notes.isNotEmpty ? notes : 'Suspended by Super Admin'},
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  // -------------------------------------------------------------
  // 5. PRODUCTS MODERATION
  // -------------------------------------------------------------

  Future<List<ProductModel>> getProducts({
    String? status,
    String? clinicId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      queryParams['status'] = status.toLowerCase();
    }
    if (clinicId != null && clinicId.isNotEmpty && clinicId != 'all') {
      queryParams['clinic'] = clinicId;
    }

    final response = await _api.get(
      ApiConfig.adminProducts,
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
        .map((p) => ProductModel.fromJson(p))
        .toList();
  }

  Future<Map<String, dynamic>> approveProduct(String id, {String notes = ''}) async {
    final response = await _api.post(
      ApiConfig.adminProductApprove(id),
      data: {'moderation_notes': notes.isNotEmpty ? notes : 'Approved by Super Admin'},
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> suspendProduct(String id, {String notes = ''}) async {
    final response = await _api.post(
      ApiConfig.adminProductSuspend(id),
      data: {'moderation_notes': notes.isNotEmpty ? notes : 'Suspended by Super Admin'},
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  // -------------------------------------------------------------
  // 6. ARTICLES MODERATION
  // -------------------------------------------------------------

  Future<List<ArticleModel>> getArticles({
    String? status,
    String? clinicId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      queryParams['status'] = status.toLowerCase();
    }
    if (clinicId != null && clinicId.isNotEmpty && clinicId != 'all') {
      queryParams['clinic'] = clinicId;
    }

    final response = await _api.get(
      ApiConfig.adminArticles,
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
        .map((a) => ArticleModel.fromJson(a))
        .toList();
  }

  Future<Map<String, dynamic>> approveArticle(String id, {String notes = ''}) async {
    final response = await _api.post(
      ApiConfig.adminArticleApprove(id),
      data: {'moderation_notes': notes.isNotEmpty ? notes : 'Approved by Super Admin'},
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> suspendArticle(String id, {String notes = ''}) async {
    final response = await _api.post(
      ApiConfig.adminArticleSuspend(id),
      data: {'moderation_notes': notes.isNotEmpty ? notes : 'Suspended by Super Admin'},
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
    if (dateFrom != null && dateFrom.isNotEmpty) queryParams['date_from'] = dateFrom;
    if (dateTo != null && dateTo.isNotEmpty) queryParams['date_to'] = dateTo;

    final response = await _api.get(
      ApiConfig.adminAnalytics,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return AdminAnalyticsModel.fromJson(response.data as Map<String, dynamic>);
  }
}
