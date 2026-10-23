import '../../../core/data/paged_collection.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/auth/guest_auth_guard.dart';
import '../../../core/auth/session_snapshot.dart';
import '../models/category_model.dart';

/// Public active taxonomy and separate authenticated Super Admin management.
class CategoryRepository {
  CategoryRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  /// The verified public API exposes active treatment categories only.
  /// Admin reads must never select a clinic or probe a clinic write route.
  Future<List<CategoryModel>> getCategories({
    int page = 1,
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

  /// Clinics must request a global category rather than mutate the taxonomy.
  static ApiException writesUnavailable() => ApiException(
    statusCode: 405,
    errorCode: 'CATEGORY_WRITES_UNSUPPORTED',
    message: LocaleService().isArabic
        ? 'التصنيفات مشتركة على مستوى المنصة. اختر تصنيفاً موجوداً أو أرسل طلب تصنيف جديد للموافقة عليه.'
        : 'Categories are shared across the platform. Select an existing category or request a new category for approval.',
  );

  Future<CategoryModel> createCategory({
    required String nameEn,
    required String nameAr,
  }) async => throw writesUnavailable();
  Future<CategoryModel> updateCategory(
    String id, {
    required String nameEn,
    required String nameAr,
  }) async => throw writesUnavailable();
  Future<void> deleteCategory(String id) async => throw writesUnavailable();

  static const adminPath = 'admin-portal/treatment-categories/';
  void _requireAdmin() {
    if (!AuthState().isLoggedIn || !AuthState().isSuperAdmin) {
      throw const ApiException(
        message: 'Super Admin access is required.',
        statusCode: 403,
      );
    }
  }

  Future<List<CategoryModel>> getAdminCategories({int page = 1}) async {
    _requireAdmin();
    final session = SessionSnapshot();
    final response = await _api.get(
      adminPath,
      queryParameters: {'page': page, 'page_size': catalogPageSize},
    );
    session.ensureCurrent();
    return PageItems<CategoryModel>.fromResponse(
      response.data,
      CategoryModel.fromJson,
      page: page,
    );
  }

  Future<CategoryModel> saveAdminCategory({
    String? id,
    required String nameEn,
    required String nameAr,
    required int displayOrder,
    required bool isActive,
  }) async {
    _requireAdmin();
    final session = SessionSnapshot();
    // Slug and icon are server-owned. Always PATCH edits, preserving other fields.
    final payload = {
      'name_en': nameEn.trim(),
      'name_ar': nameAr.trim(),
      'display_order': displayOrder,
      'is_active': isActive,
    };
    final response = id == null
        ? await _api.post(adminPath, data: payload)
        : await _api.patch('$adminPath$id/', data: payload);
    session.ensureCurrent();
    return CategoryModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> deleteAdminCategory(String id) async {
    _requireAdmin();
    final session = SessionSnapshot();
    await _api.delete('$adminPath$id/');
    session.ensureCurrent();
  }
}
