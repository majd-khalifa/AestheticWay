import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/pagination_footer.dart';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';

/// Super Admin Tab 4: Platform-wide Content Moderation (Offers, Products, Articles)
class AdminOffersScreen extends StatefulWidget {
  const AdminOffersScreen({super.key});

  @override
  State<AdminOffersScreen> createState() => _AdminOffersScreenState();
}

class _AdminOffersScreenState extends State<AdminOffersScreen> {
  int _activeModuleIndex = 0; // 0: Offers, 1: Products, 2: Articles
  int _selectedFilterIndex = 0; // 0: All, 1: Active, 2: Suspended
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AdminPortalService().loadCollection('offers');
    });
  }

  String get _moduleKey =>
      const ['offers', 'products', 'articles'][_activeModuleIndex];
  void _queryChanged() => AdminPortalService().searchCollection(_moduleKey, {
    'search': _searchQuery,
    'status': switch (_selectedFilterIndex) {
      1 => 'active',
      2 => 'suspended',
      _ => null,
    },
  });

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final adminService = AdminPortalService();
    final isDark = AppColors.isDark(context);

    return ListenableBuilder(
      listenable: Listenable.merge([loc, adminService]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          body: PagedScrollBoundary(
            onLoadMore: () => adminService.loadMore(_moduleKey),
            child: Column(
              children: [
                // Moderation Top Modules Selector (Offers / Products / Articles)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cardSurface
                          : AppColors.lightCardSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border(context),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        _ModuleTabItem(
                          title: loc.tr('cat_offers'),
                          icon: Icons.local_offer_outlined,
                          isSelected: _activeModuleIndex == 0,
                          onTap: () {
                            setState(() {
                              _activeModuleIndex = 0;
                              _selectedFilterIndex = 0;
                            });
                            _queryChanged();
                          },
                        ),
                        _ModuleTabItem(
                          title: loc.tr('cat_products'),
                          icon: Icons.shopping_bag_outlined,
                          isSelected: _activeModuleIndex == 1,
                          onTap: () {
                            setState(() {
                              _activeModuleIndex = 1;
                              _selectedFilterIndex = 0;
                            });
                            _queryChanged();
                          },
                        ),
                        _ModuleTabItem(
                          title: loc.tr('cat_articles'),
                          icon: Icons.article_outlined,
                          isSelected: _activeModuleIndex == 2,
                          onTap: () {
                            setState(() {
                              _activeModuleIndex = 2;
                              _selectedFilterIndex = 0;
                            });
                            _queryChanged();
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Input
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: TextField(
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: loc.isArabic
                          ? 'بحث في المحتوى أو العيادة...'
                          : 'Search content or clinic...',
                      hintStyle: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppColors.mutedText(context),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.cardSurface
                          : AppColors.lightCardSurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.border(context),
                          width: 0.8,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.accentChampagne,
                          width: 1.4,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                      _queryChanged();
                    },
                  ),
                ),

                // Module Content
                Expanded(
                  child: _activeModuleIndex == 0
                      ? _buildOffersList(context, loc, adminService, isDark)
                      : _activeModuleIndex == 1
                      ? _buildProductsList(context, loc, adminService, isDark)
                      : _buildArticlesList(context, loc, adminService, isDark),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOffersList(
    BuildContext context,
    LocaleService loc,
    AdminPortalService adminService,
    bool isDark,
  ) {
    var offers = adminService.allOffers;
    if (_selectedFilterIndex == 1) {
      offers = offers
          .where((o) => !adminService.isOfferSuspended(o.id))
          .toList();
    } else if (_selectedFilterIndex == 2) {
      offers = offers
          .where((o) => adminService.isOfferSuspended(o.id))
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      offers = offers
          .where(
            (o) =>
                o.titleAr.toLowerCase().contains(q) ||
                o.titleEn.toLowerCase().contains(q) ||
                o.clinicNameAr.toLowerCase().contains(q),
          )
          .toList();
    }

    return RefreshIndicator(
      onRefresh: () => adminService.loadOffers(),
      color: AppColors.accentChampagne,
      backgroundColor: isDark
          ? AppColors.cardSurface
          : AppColors.lightCardSurface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: offers.length + 1,
        itemBuilder: (context, index) {
          if (index >= offers.length) {
            return PaginationFooter(
              loading: adminService.collection('offers').isLoadingMore,
              hasMore: adminService.collection('offers').hasMore,
              error: adminService.collection('offers').error,
              onLoadMore: () => adminService.loadMore('offers'),
            );
          }

          final offer = offers[index];
          final isSuspended = adminService.isOfferSuspended(offer.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LuxuryCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LuxuryImage(
                      imageUrl: offer.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      customPlaceholder: Container(
                        width: 60,
                        height: 60,
                        color: isDark
                            ? AppColors.cardSurfaceHover
                            : AppColors.lightCardSurfaceHover,
                        child: const Icon(
                          Icons.local_offer_outlined,
                          color: AppColors.accentChampagne,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.isArabic ? offer.titleAr : offer.titleEn,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.silverPrimary
                                : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          loc.isArabic
                              ? offer.clinicNameAr
                              : (offer.clinicNameEn ?? offer.clinicNameAr),
                          style: TextStyle(
                            color: AppColors.goldText(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${offer.offerPrice.toInt()} ${loc.tr("currency_aed")} (خصم ${offer.discountPercentage}%)',
                          style: TextStyle(
                            color: AppColors.mutedText(context),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Switch(
                        value: !isSuspended,
                        activeThumbColor: const Color(0xFF10B981),
                        inactiveThumbColor: Colors.redAccent,
                        inactiveTrackColor: Colors.redAccent.withValues(
                          alpha: 0.3,
                        ),
                        onChanged: (_) async {
                          final success = await adminService
                              .toggleOfferModeration(offer.id);
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  adminService.errorMessage ??
                                      'Error updating offer',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      Text(
                        !isSuspended
                            ? (loc.isArabic ? 'نشط' : 'Active')
                            : (loc.isArabic ? 'موقوف' : 'Suspended'),
                        style: TextStyle(
                          color: !isSuspended
                              ? const Color(0xFF10B981)
                              : Colors.redAccent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsList(
    BuildContext context,
    LocaleService loc,
    AdminPortalService adminService,
    bool isDark,
  ) {
    var products = adminService.allProducts;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      products = products
          .where(
            (p) =>
                p.nameAr.toLowerCase().contains(q) ||
                p.nameEn.toLowerCase().contains(q) ||
                p.clinicNameAr.toLowerCase().contains(q),
          )
          .toList();
    }

    return RefreshIndicator(
      onRefresh: () => adminService.loadProducts(),
      color: AppColors.accentChampagne,
      backgroundColor: isDark
          ? AppColors.cardSurface
          : AppColors.lightCardSurface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: products.length + 1,
        itemBuilder: (context, index) {
          if (index >= products.length) {
            return PaginationFooter(
              loading: adminService.collection('products').isLoadingMore,
              hasMore: adminService.collection('products').hasMore,
              error: adminService.collection('products').error,
              onLoadMore: () => adminService.loadMore('products'),
            );
          }

          final product = products[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LuxuryCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LuxuryImage(
                      imageUrl: product.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      customPlaceholder: Container(
                        width: 60,
                        height: 60,
                        color: isDark
                            ? AppColors.cardSurfaceHover
                            : AppColors.lightCardSurfaceHover,
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.accentChampagne,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.isArabic ? product.nameAr : product.nameEn,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.silverPrimary
                                : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          loc.isArabic
                              ? product.clinicNameAr
                              : (product.clinicNameEn ?? product.clinicNameAr),
                          style: TextStyle(
                            color: AppColors.goldText(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          loc.isArabic
                              ? product.categoryAr
                              : product.categoryEn,
                          style: TextStyle(
                            color: AppColors.mutedText(context),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Switch(
                        value: product.isPublishedByAdmin,
                        activeThumbColor: const Color(0xFF10B981),
                        inactiveThumbColor: Colors.redAccent,
                        inactiveTrackColor: Colors.redAccent.withValues(
                          alpha: 0.3,
                        ),
                        onChanged: (_) async {
                          final success = await adminService
                              .toggleProductModeration(product.id);
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  adminService.errorMessage ??
                                      'Error updating product',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      Text(
                        product.isPublishedByAdmin
                            ? (loc.isArabic ? 'منشور' : 'Published')
                            : (loc.isArabic ? 'موقوف' : 'Suspended'),
                        style: TextStyle(
                          color: product.isPublishedByAdmin
                              ? const Color(0xFF10B981)
                              : Colors.redAccent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticlesList(
    BuildContext context,
    LocaleService loc,
    AdminPortalService adminService,
    bool isDark,
  ) {
    var articles = adminService.allArticles;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      articles = articles
          .where(
            (a) =>
                a.titleAr.toLowerCase().contains(q) ||
                a.titleEn.toLowerCase().contains(q) ||
                a.clinicNameAr.toLowerCase().contains(q) ||
                a.authorDoctorNameAr.toLowerCase().contains(q),
          )
          .toList();
    }

    return RefreshIndicator(
      onRefresh: () => adminService.loadArticles(),
      color: AppColors.accentChampagne,
      backgroundColor: isDark
          ? AppColors.cardSurface
          : AppColors.lightCardSurface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: articles.length + 1,
        itemBuilder: (context, index) {
          if (index >= articles.length) {
            return PaginationFooter(
              loading: adminService.collection('articles').isLoadingMore,
              hasMore: adminService.collection('articles').hasMore,
              error: adminService.collection('articles').error,
              onLoadMore: () => adminService.loadMore('articles'),
            );
          }

          final article = articles[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LuxuryCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LuxuryImage(
                      imageUrl: article.coverImageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      customPlaceholder: Container(
                        width: 60,
                        height: 60,
                        color: isDark
                            ? AppColors.cardSurfaceHover
                            : AppColors.lightCardSurfaceHover,
                        child: const Icon(
                          Icons.article_outlined,
                          color: AppColors.accentChampagne,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.isArabic ? article.titleAr : article.titleEn,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.silverPrimary
                                : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${loc.tr("article_author_by")}: ${loc.isArabic ? article.authorDoctorNameAr : article.authorDoctorNameEn}',
                          style: TextStyle(
                            color: AppColors.goldText(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          loc.isArabic
                              ? article.clinicNameAr
                              : (article.clinicNameEn ?? article.clinicNameAr),
                          style: TextStyle(
                            color: AppColors.mutedText(context),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Switch(
                        value: article.isApprovedByAdmin,
                        activeThumbColor: const Color(0xFF10B981),
                        inactiveThumbColor: Colors.redAccent,
                        inactiveTrackColor: Colors.redAccent.withValues(
                          alpha: 0.3,
                        ),
                        onChanged: (_) async {
                          final success = await adminService
                              .toggleArticleModeration(article.id);
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  adminService.errorMessage ??
                                      'Error updating article',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      Text(
                        article.isApprovedByAdmin
                            ? (loc.isArabic ? 'معتمد' : 'Approved')
                            : (loc.isArabic ? 'موقوف' : 'Suspended'),
                        style: TextStyle(
                          color: article.isApprovedByAdmin
                              ? const Color(0xFF10B981)
                              : Colors.redAccent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ModuleTabItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModuleTabItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentChampagne : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? AppColors.backgroundDeep
                    : AppColors.mutedText(context),
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.backgroundDeep
                      : AppColors.mutedText(context),
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
