import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/core/widgets/pagination_footer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/widgets/luxury_loading_skeleton.dart';
import 'package:aesthetic_way/core/widgets/luxury_empty_state.dart';
import 'package:aesthetic_way/features/articles/data/articles_repository.dart';
import 'package:aesthetic_way/features/articles/models/article_model.dart';
import 'package:aesthetic_way/features/articles/presentation/screens/article_detail_screen.dart';

/// Screen 7/8: Medical Aesthetic Articles & Guides Directory
class ArticlesScreen extends StatefulWidget {
  final ArticlesRepository? repository;
  final String? clinicId;
  final String? practitionerId;

  const ArticlesScreen({
    super.key,
    this.repository,
    this.clinicId,
    this.practitionerId,
  });

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  late final ArticlesRepository _repository;
  final ScrollController _scrollController = ScrollController();
  late final PagedCollection<ArticleModel> _paging;
  List<ArticleModel> get _articles => _paging.items;
  bool get _isLoading => _paging.isLoading;
  String? get _errorMessage => _paging.items.isEmpty ? _paging.error : null;
  void _pageChanged() {
    if (mounted) setState(() {});
  }

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ArticlesRepository();
    _paging = PagedCollection<ArticleModel>(
      loader: (page, q) => _repository.getArticles(
        clinicId: widget.clinicId,
        practitionerId: widget.practitionerId,
        search: q['search'] as String?,
        page: page,
        pageSize: 20,
      ),
      keyOf: (item) => item.id,
    )..addListener(_pageChanged);
    _scrollController.addListener(_onScroll);
    _loadArticles();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _paging.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 250) {
      _loadMoreArticles();
    }
  }

  Future<void> _loadArticles({bool showLoading = true}) =>
      _paging.refresh(query: {'search': _searchQuery});

  Future<void> _loadMoreArticles() => _paging.loadMore();

  void _onSearchChanged(String value) {
    _searchQuery = value.trim();
    _paging.search({'search': _searchQuery});
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    final filteredArticles = _articles;

    return ListenableBuilder(
      listenable: loc,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Text(
              loc.tr('category_articles_title'),
              style: AppTypography.screenTitle.copyWith(
                color: isDark
                    ? AppColors.silverPrimary
                    : AppColors.lightTextPrimary,
                fontSize: 16,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark
                    ? AppColors.silverPrimary
                    : AppColors.lightTextPrimary,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: PagedScrollBoundary(
            onLoadMore: _paging.loadMore,
            child: Column(
              children: [
                // Search Input
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.border(context),
                        width: 0.8,
                      ),
                    ),
                    child: TextField(
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 13.5,
                      ),
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: loc.isArabic
                            ? 'ابحث في المقالات، النصائح، الأطباء...'
                            : 'Search articles, advice, doctors...',
                        hintStyle: TextStyle(
                          color: AppColors.text(
                            context,
                          ).withValues(alpha: 0.68),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.mutedText(context),
                          size: 18,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Articles List
                Expanded(
                  child: LuxuryRefreshIndicator(
                    onRefresh: () => _loadArticles(showLoading: false),
                    child: _buildBody(context, loc, isDark, filteredArticles),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    LocaleService loc,
    bool isDark,
    List<ArticleModel> filteredArticles,
  ) {
    if (_isLoading) {
      return const LuxuryListSkeleton(itemCount: 4, cardHeight: 120);
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.mutedText(context),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _loadArticles,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.accentChampagne,
                    ),
                    label: Text(
                      loc.isArabic ? 'إعادة المحاولة' : 'Retry',
                      style: TextStyle(
                        color: AppColors.goldText(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (filteredArticles.isEmpty) {
      return LuxuryRefreshIndicator(
        onRefresh: _loadArticles,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.10),
            LuxuryEmptyState(
              icon: Icons.article_outlined,
              title: loc.isArabic
                  ? 'لا توجد مقالات طبية حالياً'
                  : 'No medical articles or guides',
              subtitle: loc.isArabic
                  ? 'سيتم نشر نصائح تجميلية وأدلة طبية موثقة قريباً'
                  : 'Verified aesthetic guides and articles will be published soon',
              actionLabel: loc.isArabic ? 'تحديث' : 'Refresh',
              onAction: _loadArticles,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: filteredArticles.length + 1,
      itemBuilder: (context, index) {
        if (index >= filteredArticles.length) {
          return PaginationFooter(
            loading: _paging.isLoadingMore,
            hasMore: _paging.hasMore,
            error: _paging.error,
            onLoadMore: _paging.loadMore,
          );
        }
        final article = filteredArticles[index];
        final categoryLabel = loc.isArabic
            ? article.categoryAr
            : article.categoryEn;
        final authorName = loc.isArabic
            ? article.authorDoctorNameAr
            : article.authorDoctorNameEn;
        final displayAuthor = authorName.isNotEmpty
            ? authorName
            : (loc.isArabic
                  ? (article.clinicNameAr.isNotEmpty
                        ? article.clinicNameAr
                        : 'أستيتك واي')
                  : (article.clinicNameEn ?? 'Aesthetic Way'));

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: LuxuryCard(
            onTap: () {
              Navigator.push(
                context,
                LuxuryPageRoute(page: ArticleDetailScreen(article: article)),
              );
            },
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LuxuryImage(
                  imageUrl: article.coverImageUrl,
                  fallbackLogoUrl: article.clinicLogoUrl,
                  height: 150,
                  width: double.infinity,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  placeholderIcon: Icons.article_outlined,
                  iconSize: 36,
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (categoryLabel.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentChampagne.withValues(
                                  alpha: isDark ? 0.15 : 0.2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                categoryLabel,
                                style: TextStyle(
                                  color: AppColors.goldText(context),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Text(
                            DateFormat(
                              'yyyy/MM/dd',
                            ).format(article.publishedAt),
                            style: TextStyle(
                              color: AppColors.mutedText(context),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.isArabic ? article.titleAr : article.titleEn,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.silverPrimary
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        loc.isArabic ? article.summaryAr : article.summaryEn,
                        style: TextStyle(
                          color: AppColors.mutedText(context),
                          fontSize: 12,
                          height: 1.45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (article.authorDoctorAvatar.isNotEmpty)
                            LuxuryAvatar(
                              imageUrl: article.authorDoctorAvatar,
                              radius: 12,
                              fallbackLogoUrl: article.clinicLogoUrl,
                            )
                          else
                            const CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.cardSurfaceHover,
                              child: Icon(
                                Icons.person_rounded,
                                size: 14,
                                color: AppColors.accentChampagne,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              displayAuthor,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.silverPrimary
                                    : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: AppColors.accentChampagne,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
