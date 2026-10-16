import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
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
  final List<ArticleModel> _articles = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;

  String _selectedCategory = 'all';
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ArticlesRepository();
    _scrollController.addListener(_onScroll);
    _loadArticles();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounce?.cancel();
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

  Future<void> _loadArticles({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _isLoadingMore = false;
        _hasMore = true;
        _currentPage = 1;
        _errorMessage = null;
      });
    }

    try {
      final items = await _repository.getArticles(
        clinicId: widget.clinicId,
        practitionerId: widget.practitionerId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        page: 1,
        pageSize: 20,
      );
      if (mounted) {
        setState(() {
          _articles
            ..clear()
            ..addAll(items);
          _isLoading = false;
          _errorMessage = null;
          if (items.length < 20) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadMoreArticles() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final items = await _repository.getArticles(
        clinicId: widget.clinicId,
        practitionerId: widget.practitionerId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        page: nextPage,
        pageSize: 20,
      );

      if (!mounted) return;
      setState(() {
        _currentPage = nextPage;
        _isLoadingMore = false;
        if (items.length < 20) {
          _hasMore = false;
        }
        _articles.addAll(items);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearchChanged(String val) {
    final trimmed = val.trim();
    if (_searchQuery == trimmed) return;
    setState(() {
      _searchQuery = trimmed;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _loadArticles(showLoading: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    final categories = [
      {'id': 'all', 'label': loc.tr('article_category_all')},
      {'id': 'injectables', 'label': loc.tr('article_category_injectables')},
      {'id': 'laser', 'label': loc.tr('article_category_laser')},
      {'id': 'glow', 'label': loc.tr('article_category_glow')},
      {'id': 'surgery', 'label': loc.tr('article_category_surgery')},
    ];

    final filteredArticles = _articles.where((a) {
      if (_selectedCategory != 'all') {
        final combinedAr = '${a.categoryAr} ${a.titleAr} ${a.contentAr}';
        final combinedEn = '${a.categoryEn} ${a.titleEn} ${a.contentEn}'.toLowerCase();
        if (_selectedCategory == 'injectables' &&
            !combinedAr.contains('فيلر') &&
            !combinedAr.contains('بوتوكس') &&
            !combinedAr.contains('حقن') &&
            !combinedEn.contains('filler') &&
            !combinedEn.contains('botox') &&
            !combinedEn.contains('inject')) {
          return false;
        }
        if (_selectedCategory == 'laser' &&
            !combinedAr.contains('ليزر') &&
            !combinedEn.contains('laser')) {
          return false;
        }
        if (_selectedCategory == 'glow' &&
            !combinedAr.contains('نضارة') &&
            !combinedAr.contains('بشرة') &&
            !combinedEn.contains('glow') &&
            !combinedEn.contains('skin') &&
            !combinedEn.contains('hyaluronic')) {
          return false;
        }
        if (_selectedCategory == 'surgery' &&
            !combinedAr.contains('جراحة') &&
            !combinedEn.contains('surgery')) {
          return false;
        }
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return a.titleAr.toLowerCase().contains(q) ||
            a.titleEn.toLowerCase().contains(q) ||
            a.summaryAr.toLowerCase().contains(q) ||
            a.summaryEn.toLowerCase().contains(q) ||
            a.authorDoctorNameAr.toLowerCase().contains(q) ||
            a.authorDoctorNameEn.toLowerCase().contains(q);
      }
      return true;
    }).toList();

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
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                fontSize: 16,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border(context), width: 0.8),
                  ),
                  child: TextField(
                    style: TextStyle(color: AppColors.text(context), fontSize: 13.5),
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: loc.isArabic
                          ? 'ابحث في المقالات، النصائح، الأطباء...'
                          : 'Search articles, advice, doctors...',
                      hintStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.mutedText(context), size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              // Category Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = _selectedCategory == cat['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          cat['label']!,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected ? AppColors.backgroundDeep : AppColors.mutedText(context),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.accentChampagne,
                        backgroundColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                        side: BorderSide(
                          color: isSelected ? AppColors.accentChampagne : AppColors.border(context),
                          width: 0.8,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = cat['id']!;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),

              // Articles List
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accentChampagne,
                  onRefresh: () => _loadArticles(showLoading: false),
                  child: _buildBody(context, loc, isDark, filteredArticles),
                ),
              ),
            ],
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentChampagne),
      );
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
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 42),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.mutedText(context), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _loadArticles,
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.accentChampagne),
                    label: Text(
                      loc.isArabic ? 'إعادة المحاولة' : 'Retry',
                      style: const TextStyle(
                        color: AppColors.accentChampagne,
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
      return RefreshIndicator(
        color: AppColors.accentChampagne,
        onRefresh: _loadArticles,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LuxuryCard(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accentChampagne.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.article_outlined, size: 36, color: AppColors.accentChampagne),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        loc.isArabic ? 'لا توجد مقالات طبية حالياً' : 'No medical articles or guides',
                        style: AppTypography.cardTitle.copyWith(
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        loc.isArabic
                            ? 'سيتم نشر نصائح تجميلية وأدلة طبية موثقة قريباً'
                            : 'Verified aesthetic guides and articles will be published soon',
                        style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadArticles,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(loc.isArabic ? 'تحديث' : 'Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          foregroundColor: isDark ? AppColors.backgroundDeep : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: filteredArticles.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredArticles.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentChampagne,
                ),
              ),
            ),
          );
        }
        final article = filteredArticles[index];
        final categoryLabel = loc.isArabic ? article.categoryAr : article.categoryEn;
        final authorName = loc.isArabic ? article.authorDoctorNameAr : article.authorDoctorNameEn;
        final displayAuthor = authorName.isNotEmpty
            ? authorName
            : (loc.isArabic
                ? (article.clinicNameAr.isNotEmpty ? article.clinicNameAr : 'أستيتك واي')
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.15 : 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                categoryLabel,
                                style: const TextStyle(
                                  color: AppColors.accentChampagne,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Text(
                            DateFormat('yyyy/MM/dd').format(article.publishedAt),
                            style: TextStyle(color: AppColors.mutedText(context), fontSize: 10.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.isArabic ? article.titleAr : article.titleEn,
                        style: TextStyle(
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
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
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: NetworkImage(article.authorDoctorAvatar),
                              backgroundColor: AppColors.cardSurfaceHover,
                            )
                          else
                            const CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.cardSurfaceHover,
                              child: Icon(Icons.person_rounded, size: 14, color: AppColors.accentChampagne),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              displayAuthor,
                              style: TextStyle(
                                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.accentChampagne),
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
