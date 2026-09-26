import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/features/articles/models/article_model.dart';

/// Repository for Public Discovery of Educational & Medical Aesthetic Articles
class ArticlesRepository {
  final ApiClient _apiClient;

  ArticlesRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetches published articles from `GET /api/v1/articles/`
  Future<List<ArticleModel>> getArticles({
    String? clinicId,
    String? practitionerId,
    String? search,
    int page = 1,
  }) async {
    final Map<String, dynamic> queryParams = {};

    if (clinicId != null && clinicId.trim().isNotEmpty) {
      queryParams['clinic_id'] = clinicId.trim();
    }

    if (practitionerId != null && practitionerId.trim().isNotEmpty) {
      queryParams['practitioner_id'] = practitionerId.trim();
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    if (page > 1) {
      queryParams['page'] = page;
    }

    final response = await _apiClient.get(
      ApiConfig.articles,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final data = response.data;
    List<dynamic> list;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      list = data['results'] as List<dynamic>? ?? [];
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map((m) => ArticleModel.fromJson(m))
        .toList();
  }

  /// Fetches single article detail by UUID or slug from `GET /api/v1/articles/<id>/`
  Future<ArticleModel> getArticleDetail(String idOrSlug) async {
    final cleanId = idOrSlug.trim();
    final response = await _apiClient.get(ApiConfig.articleDetail(cleanId));
    return ArticleModel.fromJson(response.data as Map<String, dynamic>);
  }
}
