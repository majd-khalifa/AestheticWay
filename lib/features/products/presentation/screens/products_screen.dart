import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/data/mock_data.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/products/presentation/screens/product_detail_screen.dart';

/// Screen 6/8: Products & Medical Skincare Directory (Discovery & Inquiry)
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final mockData = MockDataService();
    final isDark = AppColors.isDark(context);

    final categories = [
      {'id': 'all', 'label': loc.tr('product_category_all')},
      {'id': 'cosmeceuticals', 'label': loc.tr('product_category_cosmeceuticals')},
      {'id': 'skincare', 'label': loc.tr('product_category_skincare')},
      {'id': 'devices', 'label': loc.tr('product_category_devices')},
      {'id': 'sunscreens', 'label': loc.tr('product_category_sunscreens')},
    ];

    final filteredProducts = mockData.products.where((p) {
      if (_selectedCategory != 'all') {
        if (_selectedCategory == 'cosmeceuticals' && !p.categoryAr.contains('علاجية') && !p.categoryEn.toLowerCase().contains('cosmeceutical')) return false;
        if (_selectedCategory == 'skincare' && !p.categoryAr.contains('عناية') && !p.categoryEn.toLowerCase().contains('skincare')) return false;
        if (_selectedCategory == 'devices' && !p.categoryAr.contains('أجهزة') && !p.categoryEn.toLowerCase().contains('device')) return false;
        if (_selectedCategory == 'sunscreens' && !p.categoryAr.contains('واقيات') && !p.categoryEn.toLowerCase().contains('sun')) return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return p.nameAr.toLowerCase().contains(q) ||
            p.nameEn.toLowerCase().contains(q) ||
            p.clinicNameAr.toLowerCase().contains(q) ||
            p.descriptionAr.toLowerCase().contains(q);
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
              loc.tr('category_products_title'),
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
                      hintText: loc.isArabic ? 'ابحث في المنتجات، السيرومات، الأجهزة...' : 'Search products, serums, devices...',
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
                child: filteredProducts.isEmpty
                    ? Center(
                        child: Text(
                          loc.tr('product_empty'),
                          style: TextStyle(color: AppColors.mutedText(context)),
                        ),
                      )
                    : GridView.builder(
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
                      ),
              ),
            ],
          ),
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
                      loc.isArabic ? product.categoryAr : product.categoryEn,
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
