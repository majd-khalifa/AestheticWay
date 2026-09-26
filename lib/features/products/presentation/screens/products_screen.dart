import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
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
  final List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedCategory = 'all';
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ProductsRepository();
    _loadProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final items = await _repository.getProducts(
        clinicId: widget.clinicId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (mounted) {
        setState(() {
          _products
            ..clear()
            ..addAll(items);
          _isLoading = false;
          _errorMessage = null;
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
            title: Text(
              loc.tr('category_products_title'),
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
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Text(
              loc.tr('product_empty'),
              style: TextStyle(color: AppColors.mutedText(context)),
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
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
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    product.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                      child: const Center(
                        child: Icon(Icons.shopping_bag_outlined, color: AppColors.accentChampagne, size: 32),
                      ),
                    ),
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
                Text(
                  loc.isArabic ? product.clinicNameAr : (product.clinicNameEn ?? product.clinicNameAr),
                  style: TextStyle(color: AppColors.mutedText(context), fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${product.price.toInt()} ${loc.tr("currency_aed")}',
                      style: const TextStyle(
                        color: AppColors.accentChampagne,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    if (product.originalPrice != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '${product.originalPrice!.toInt()}',
                        style: TextStyle(
                          color: AppColors.mutedText(context),
                          fontSize: 10,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
