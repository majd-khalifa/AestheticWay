import '../widgets/brand_product_media.dart';
import '../../../../core/widgets/editorial_heading.dart';
import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/core/widgets/pagination_footer.dart';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/widgets/luxury_loading_skeleton.dart';
import 'package:aesthetic_way/core/widgets/luxury_empty_state.dart';
import 'package:aesthetic_way/features/products/data/products_repository.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/products/presentation/screens/product_detail_screen.dart';

/// Screen 6/8: Products & Medical Skincare Directory (Discovery & Inquiry Only)
class ProductsScreen extends StatefulWidget {
  final ProductsRepository? repository;
  final String? clinicId;

  const ProductsScreen({super.key, this.repository, this.clinicId});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final ProductsRepository _repository;
  final ScrollController _scrollController = ScrollController();
  late final PagedCollection<ProductModel> _paging;
  List<ProductModel> get _products => _paging.items;
  bool get _isLoading => _paging.isLoading;
  String? get _errorMessage => _paging.items.isEmpty ? _paging.error : null;
  void _pageChanged() {
    if (mounted) setState(() {});
  }

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ProductsRepository();
    _paging = PagedCollection<ProductModel>(
      loader: (page, q) => _repository.getProducts(
        clinicId: widget.clinicId,
        search: q['search'] as String?,
        page: page,
        pageSize: 20,
      ),
      keyOf: (item) => item.id,
    )..addListener(_pageChanged);
    _scrollController.addListener(_onScroll);
    _loadProducts();
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
      _loadMoreProducts();
    }
  }

  Future<void> _loadProducts({bool showLoading = true}) =>
      _paging.refresh(query: {'search': _searchQuery});

  Future<void> _loadMoreProducts() => _paging.loadMore();

  void _onSearchChanged(String value) {
    _searchQuery = value.trim();
    _paging.search({'search': _searchQuery});
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    final filteredProducts = _products;

    return ListenableBuilder(
      listenable: loc,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            automaticallyImplyLeading: false,
            title: Text(
              loc.tr('category_products_title'),
              style: AppTypography.screenTitle.copyWith(
                color: isDark
                    ? AppColors.silverPrimary
                    : AppColors.lightTextPrimary,
                fontSize: 16,
              ),
            ),
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark
                          ? AppColors.silverPrimary
                          : AppColors.lightTextPrimary,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
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
                            ? 'ابحث في المنتجات، السيرومات، الأجهزة...'
                            : 'Search products, serums, devices...',
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

                if (MediaQuery.sizeOf(context).height -
                        MediaQuery.viewInsetsOf(context).bottom >
                    420)
                  EditorialHeading(
                    eyebrow: loc.isArabic
                        ? 'علامات تجميلية'
                        : 'COSMETIC BRANDS',
                    title: loc.isArabic
                        ? 'عناية تستحق التعرّف عليها'
                        : 'A closer look at skincare',
                  ),
                // Products Grid
                Expanded(
                  child: LuxuryRefreshIndicator(
                    onRefresh: () => _loadProducts(showLoading: false),
                    child: _buildBody(context, loc, filteredProducts),
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
    List<ProductModel> filteredProducts,
  ) {
    if (_isLoading) {
      return const LuxuryListSkeleton(itemCount: 4, cardHeight: 130);
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
                    onPressed: _loadProducts,
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

    if (filteredProducts.isEmpty) {
      return LuxuryRefreshIndicator(
        onRefresh: _loadProducts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.10),
            LuxuryEmptyState(
              icon: Icons.shopping_bag_outlined,
              title: loc.isArabic
                  ? 'لا توجد منتجات طبية حالياً'
                  : 'No medical skincare products',
              subtitle: loc.isArabic
                  ? 'سيتم إضافة منتجات علاجية ومستحضرات طبية جديدة قريباً'
                  : 'New medical skincare products will be added soon',
              actionLabel: loc.isArabic ? 'تحديث' : 'Refresh',
              onAction: _loadProducts,
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  MediaQuery.sizeOf(context).width < 350 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.3
                  ? 1
                  : 2,
              mainAxisExtent:
                  340 +
                  (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0, 2) *
                      90,
              crossAxisSpacing: 18,
              mainAxisSpacing: 24,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = filteredProducts[index];
              return _ProductCard(
                product: product,
                onTap: () {
                  Navigator.push(
                    context,
                    LuxuryPageRoute(
                      page: ProductDetailScreen(product: product),
                    ),
                  );
                },
              );
            }, childCount: filteredProducts.length),
          ),
        ),
        SliverToBoxAdapter(
          child: PaginationFooter(
            loading: _paging.isLoadingMore,
            hasMore: _paging.hasMore,
            error: _paging.error,
            onLoadMore: _paging.loadMore,
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});
  final ProductModel product;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final locale = LocaleService();
    final brand = productBrandLabel(product, locale);
    return RepaintBoundary(
      child: LuxuryCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        borderRadius: 16,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: BrandProductMedia(product: product)),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (brand.isNotEmpty) ...[
                      Text(
                        brand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.5,
                          letterSpacing: locale.isArabic ? 0 : 0.8,
                          fontWeight: FontWeight.w600,
                          color: AppColors.subtext(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      locale.isArabic ? product.nameAr : product.nameEn,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
