import '../../../core/data/paged_collection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/category_model.dart';

/// Retry only an explicitly missing/unsupported route, never a rejected write.
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

  Future<dynamic> _write(
    String method,
    String suffix, {
    Map<String, dynamic>? data,
  }) async {
    Future<dynamic> send(String root) async {
      final path = '$root$suffix';
      switch (method) {
        case 'POST':
          return (await _api.post(path, data: data)).data;
        case 'PATCH':
          return (await _api.patch(path, data: data)).data;
        case 'DELETE':
          return (await _api.delete(path)).data;
      }
      throw ArgumentError.value(method);
    }

    try {
      return await send(ApiConfig.clinicCategories);
    } on ApiException catch (error) {
      if (![404, 405, 501].contains(error.statusCode)) rethrow;
      return send(ApiConfig.categories);
    }
  }

  CategoryModel _category(dynamic value) {
    final body =
        value is Map<String, dynamic> && value['data'] is Map<String, dynamic>
        ? value['data']
        : value;
    if (body is! Map<String, dynamic> ||
        body['id'] == null ||
        body['id'].toString().isEmpty) {
      throw const ApiException(
        message: 'The category response is missing its ID.',
      );
    }
    return CategoryModel.fromJson(body);
  }

  Future<CategoryModel> createCategory({
    required String nameEn,
    required String nameAr,
  }) async => _category(
    await _write(
      'POST',
      '',
      data: {'name_en': nameEn.trim(), 'name_ar': nameAr.trim()},
    ),
  );
  Future<CategoryModel> updateCategory(
    String id, {
    required String nameEn,
    required String nameAr,
  }) async => _category(
    await _write(
      'PATCH',
      '$id/',
      data: {'name_en': nameEn.trim(), 'name_ar': nameAr.trim()},
    ),
  );
  Future<void> deleteCategory(String id) async {
    await _write('DELETE', '$id/');
  }
}
