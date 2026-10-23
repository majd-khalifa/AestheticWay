import '../../../core/data/paged_collection.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/category_model.dart';

/// Verified active treatment-category reads; unsupported writes fail locally.
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

  /// d1023b0 has no category write API, including for Super Admin.
  /// This is a local contract guard, not a fabricated HTTP response.
  static ApiException writesUnavailable() => ApiException(
    statusCode: 405,
    errorCode: 'CATEGORY_WRITES_UNSUPPORTED',
    message: LocaleService().isArabic
        ? 'التصنيفات مشتركة على مستوى المنصة. الإضافة والتعديل والحذف غير مدعومة حالياً. اختر تصنيفاً موجوداً أو تواصل مع إدارة المنصة.'
        : 'Categories are shared across the platform. Adding, editing and deleting categories are currently unsupported. Select an existing category or contact the platform administrator.',
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
}
