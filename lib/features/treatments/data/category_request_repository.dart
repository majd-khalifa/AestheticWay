import 'package:flutter/foundation.dart';
import '../../../core/auth/guest_auth_guard.dart';
import '../../../core/auth/session_snapshot.dart';
import '../../../core/data/paged_collection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/category_request_model.dart';

class CategoryRequestRepository {
  static final decisions = ValueNotifier<int>(0);
  CategoryRequestRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();
  final ApiClient _api;
  static const clinicPath = 'clinic-portal/category-requests/';
  static const adminPath = 'admin-portal/category-requests/';
  void _requireRole(bool admin) {
    final auth = AuthState();
    if (!auth.isLoggedIn ||
        (admin
            ? !auth.isSuperAdmin
            : !(auth.isClinicAdmin || auth.isClinicStaff))) {
      throw const ApiException(
        message: 'This account cannot manage these requests.',
        statusCode: 403,
      );
    }
  }

  Future<List<CategoryRequestModel>> list({
    bool admin = false,
    int page = 1,
    String? status,
  }) async {
    _requireRole(admin);
    final session = SessionSnapshot();
    final response = await _api.get(
      admin ? adminPath : clinicPath,
      queryParameters: {
        'page': page,
        'page_size': catalogPageSize,
        if (admin && status != null) 'status': status,
      },
    );
    session.ensureCurrent();
    return PageItems<CategoryRequestModel>.fromResponse(
      response.data,
      CategoryRequestModel.fromJson,
      page: page,
    );
  }

  Future<CategoryRequestModel> submit({
    required String nameEn,
    required String nameAr,
  }) async {
    _requireRole(false);
    final session = SessionSnapshot();
    final response = await _api.post(
      clinicPath,
      data: {'name_en': nameEn.trim(), 'name_ar': nameAr.trim()},
    );
    session.ensureCurrent();
    return CategoryRequestModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<CategoryRequestModel> review(
    String id, {
    required bool approve,
    String reason = '',
  }) async {
    _requireRole(true);
    final session = SessionSnapshot();
    final response = await _api.post(
      '$adminPath$id/${approve ? 'approve' : 'reject'}/',
      data: approve ? <String, dynamic>{} : {'rejection_reason': reason.trim()},
    );
    session.ensureCurrent();
    decisions.value++;
    return CategoryRequestModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
