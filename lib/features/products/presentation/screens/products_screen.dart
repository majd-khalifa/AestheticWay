import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/features/products/data/products_repository.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/products/presentation/screens/product_detail_screen.dart';

/// Screen 6/8: Products & Medical Skincare Directory (Discovery & Inquiry Only)
class ProductsScreen extends StatefulWidget {
  final ProductsRepository? repository;
  final String? clinicId;

  const ProductsScreen({
    super.key,
    this.repository,
    this.clinicId,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final ProductsRepository _repository;
  final ScrollController _scrollController = ScrollController();
  final List<ProductModel> _products = [];
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
    _repository = widget.repository ?? ProductsRepository();
    _scrollController.addListener(_onScroll);
    _loadProducts();
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
      _loadMoreProducts();
    }
  }

  Future<void> _loadProducts({bool showLoading = true}) async {
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
      final items = await _repository.getProducts(
        clinicId: widget.clinicId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        page: 1,
        pageSize: 20,
      );
      if (mounted) {
        setState(() {
          _products
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

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final items = await _repository.getProducts(
        clinicId: widget.clinicId,
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
        _products.addAll(items);
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
      _loadProducts(showLoading: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    final categories = [
      {'id': 'all', 'label': loc.tr('product_category_all')},
      {'id': 'cosmeceuticals', 'label': loc.tr('product_category_cosmeceuticals')},
      {'id': 'skincare', 'label': loc.tr('product_category_skincare')},
      {'id': 'devices', 'label': loc.tr('product_category_devices')},
      {'id': 'sunscreens', 'label': loc.tr('product_category_sunscreens')},
    ];

    final filteredProducts = _products.where((p) {
      if (_selectedCategory != 'all') {
        final combinedAr = '${p.categoryAr} ${p.nameAr} ${p.descriptionAr}';
        final combinedEn = '${p.categoryEn} ${p.nameEn} ${p.descriptionEn}'.toLowerCase();
        if (_selectedCategory == 'cosmeceuticals' &&
            !combinedAr.contains('علاجية') &&
            !combinedAr.contains('سيروم') &&
            !combinedEn.contains('cosmeceutical') &&
            !combinedEn.contains('serum')) {
          return false;
        }
        if (_selectedCategory == 'skincare' &&
            !combinedAr.contains('عناية') &&
            !combinedAr.contains('بشرة') &&
            !combinedEn.contains('skincare') &&
            !combinedEn.contains('skin') &&
            !combinedEn.contains('cleanser') &&
            !combinedEn.contains('cream')) {
          return false;
        }
        if (_selectedCategory == 'devices' &&
            !combinedAr.contains('أجهزة') &&
            !combinedAr.contains('جهاز') &&
            !combinedEn.contains('device')) {
          return false;
        }
        if (_selectedCategory == 'sunscreens' &&
            !combinedAr.contains('واقي') &&
            !combinedAr.contains('شمس') &&
            !combinedEn.contains('sun') &&
            !combinedEn.contains('spf')) {
          return false;
        }
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return p.nameAr.toLowerCase().contains(q) ||
            p.nameEn.toLowerCase().contains(q) ||
            p.clinicNameAr.toLowerCase().contains(q) ||
            (p.clinicNameEn?.toLowerCase().contains(q) ?? false) ||
            p.descriptionAr.toLowerCase().contains(q) ||
            p.descriptionEn.toLowerCase().contains(q);
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
            automaticallyImplyLeading: false,
            title: Text(
              loc.tr('category_products_title'),
              style: AppTypography.screenTitle.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                fontSize: 16,
              ),
            ),
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
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
                          ? 'ابحث في المنتجات، السيرومات، الأجهزة...'
                          : 'Search products, serums, devices...',
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
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppColors.backgroundDeep : AppColors.text(context),
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

              // Products Grid
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accentChampagne,
                  onRefresh: () => _loadProducts(showLoading: false),
                  child: _buildBody(context, loc, filteredProducts),
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
    List<ProductModel> filteredProducts,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    onPressed: _loadProducts,
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

    if (filteredProducts.isEmpty) {
      return RefreshIndicator(
        color: AppColors.accentChampagne,
        onRefresh: _loadProducts,
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
                        child: const Icon(Icons.shopping_bag_outlined, size: 36, color: AppColors.accentChampagne),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        loc.isArabic ? 'لا توجد منتجات طبية حالياً' : 'No medical skincare products',
                        style: AppTypography.cardTitle.copyWith(
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        loc.isArabic
                            ? 'سيتم إضافة منتجات علاجية ومستحضرات طبية جديدة قريباً'
                            : 'New medical skincare products will be added soon',
                        style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadProducts,
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

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.78,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = filteredProducts[index];
                return _ProductCard(
                  product: product,
                  onTap: () {
                    Navigator.push(
                      context,
                      LuxuryPageRoute(page: ProductDetailScreen(product: product)),
                    );
                  },
                );
              },
              childCount: filteredProducts.length,
            ),
          ),
        ),
        if (_isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
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
            ),
          ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);
    final categoryLabel = loc.isArabic ? product.categoryAr : product.categoryEn;

    return LuxuryCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: LuxuryImage(
                    imageUrl: product.imageUrl,
                    fallbackLogoUrl: product.clinicLogoUrl,
                    width: double.infinity,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    placeholderIcon: Icons.shopping_bag_outlined,
                    iconSize: 32,
                  ),
                ),
                if (categoryLabel.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: loc.isArabic ? 8 : null,
                    right: loc.isArabic ? null : 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentChampagne,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        categoryLabel,
                        style: const TextStyle(
                          color: AppColors.backgroundDeep,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.isArabic ? product.nameAr : product.nameEn,
                  style: TextStyle(
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Builder(
                  builder: (context) {
                    final brandText = loc.isArabic
                        ? (product.brandNameAr?.isNotEmpty == true
                            ? product.brandNameAr!
                            : (product.brandNameEn?.isNotEmpty == true
                                ? product.brandNameEn!
                                : (product.sponsorCompany ?? product.clinicNameAr)))
                        : (product.brandNameEn?.isNotEmpty == true
                            ? product.brandNameEn!
                            : (product.brandNameAr?.isNotEmpty == true
                                ? product.brandNameAr!
                                : (product.sponsorCompany ?? (product.clinicNameEn ?? product.clinicNameAr))));
                    return Text(
                      brandText.isNotEmpty
                          ? brandText
                          : (loc.isArabic ? product.clinicNameAr : (product.clinicNameEn ?? product.clinicNameAr)),
                      style: TextStyle(color: AppColors.mutedText(context), fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
