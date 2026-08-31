import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/data/mock_data.dart';
import 'package:aesthetic_way/features/articles/presentation/screens/article_detail_screen.dart';

/// Screen 7/8: Medical Aesthetic Articles & Guides Directory
class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final mockData = MockDataService();
    final isDark = AppColors.isDark(context);

    final categories = [
      {'id': 'all', 'label': loc.tr('article_category_all')},
      {'id': 'injectables', 'label': loc.tr('article_category_injectables')},
      {'id': 'laser', 'label': loc.tr('article_category_laser')},
      {'id': 'glow', 'label': loc.tr('article_category_glow')},
      {'id': 'surgery', 'label': loc.tr('article_category_surgery')},
    ];

    final filteredArticles = mockData.articles.where((a) {
      if (_selectedCategory != 'all') {
        if (_selectedCategory == 'injectables' && !a.categoryAr.contains('فيلر') && !a.categoryAr.contains('بوتوكس') && !a.categoryEn.toLowerCase().contains('filler')) return false;
        if (_selectedCategory == 'laser' && !a.categoryAr.contains('ليزر') && !a.categoryEn.toLowerCase().contains('laser')) return false;
        if (_selectedCategory == 'glow' && !a.categoryAr.contains('نضارة') && !a.categoryEn.toLowerCase().contains('glow')) return false;
        if (_selectedCategory == 'surgery' && !a.categoryAr.contains('جراحة') && !a.categoryEn.toLowerCase().contains('surgery')) return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return a.titleAr.toLowerCase().contains(q) ||
            a.titleEn.toLowerCase().contains(q) ||
            a.summaryAr.toLowerCase().contains(q) ||
            a.authorDoctorNameAr.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return ListenableBuilder(
      listenable: Listenable.merge([loc, mockData]),
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
              icon: Icon(Icons.arrow_back, color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary, size: 18),
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
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: loc.isArabic ? 'ابحث في المقالات، النصائح، الأطباء...' : 'Search articles, advice, doctors...',
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
                child: filteredArticles.isEmpty
                    ? Center(
                        child: Text(
                          loc.tr('article_empty'),
                          style: TextStyle(color: AppColors.mutedText(context)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filteredArticles.length,
                        itemBuilder: (context, index) {
                          final article = filteredArticles[index];
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
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    child: Image.network(
                                      article.coverImageUrl,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        height: 150,
                                        color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                                        child: const Center(
                                          child: Icon(Icons.article_outlined, color: AppColors.accentChampagne, size: 36),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.15 : 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                loc.isArabic ? article.categoryAr : article.categoryEn,
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
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundImage: NetworkImage(article.authorDoctorAvatar),
                                              backgroundColor: AppColors.cardSurfaceHover,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              loc.isArabic ? article.authorDoctorNameAr : article.authorDoctorNameEn,
                                              style: TextStyle(
                                                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                            const Spacer(),
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
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
