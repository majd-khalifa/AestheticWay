import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';

class CategoryItem {
  final String id;
  final String translationKey;
  final IconData icon;

  const CategoryItem({
    required this.id,
    required this.translationKey,
    required this.icon,
  });
}

/// Category Quick Access Grid with the 8 Official Categories & Dual-Theme Adaptation
class CategoryGrid extends StatelessWidget {
  final ValueChanged<CategoryItem> onCategorySelected;

  const CategoryGrid({super.key, required this.onCategorySelected});

  static const List<CategoryItem> categories = [
    CategoryItem(
      id: 'offers',
      translationKey: 'cat_offers',
      icon: Icons.local_offer_outlined,
    ),
    CategoryItem(
      id: 'treatments',
      translationKey: 'cat_treatments',
      icon: Icons.auto_fix_high_rounded,
    ),
    CategoryItem(
      id: 'doctors',
      translationKey: 'cat_doctors',
      icon: Icons.medical_services_outlined,
    ),
    CategoryItem(
      id: 'skin_experts',
      translationKey: 'cat_skin_experts',
      icon: Icons.face_retouching_natural_rounded,
    ),
    CategoryItem(
      id: 'surgery',
      translationKey: 'cat_surgery',
      icon: Icons.healing_rounded,
    ),
    CategoryItem(
      id: 'products',
      translationKey: 'cat_products',
      icon: Icons.shopping_bag_outlined,
    ),
    CategoryItem(
      id: 'articles',
      translationKey: 'cat_articles',
      icon: Icons.menu_book_rounded,
    ),
    CategoryItem(
      id: 'clinics',
      translationKey: 'cat_clinics',
      icon: Icons.apartment_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.accentChampagne,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                loc.tr('categories_title'),
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  letterSpacing: 0.25,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _CategoryItemWidget(
                category: cat,
                label: loc.tr(cat.translationKey),
                onTap: () => onCategorySelected(cat),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryItemWidget extends StatefulWidget {
  final CategoryItem category;
  final String label;
  final VoidCallback onTap;

  const _CategoryItemWidget({
    required this.category,
    required this.label,
    required this.onTap,
  });

  @override
  State<_CategoryItemWidget> createState() => _CategoryItemWidgetState();
}

class _CategoryItemWidgetState extends State<_CategoryItemWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final bgColors = isDark
        ? [
            _isPressed ? const Color(0xFF223454) : const Color(0xFF16233B),
            _isPressed ? const Color(0xFF141E34) : const Color(0xFF0F172A),
          ]
        : [
            _isPressed ? const Color(0xFFF1F5F9) : const Color(0xFFFFFFFF),
            _isPressed ? const Color(0xFFE2E8F0) : const Color(0xFFF8FAFC),
          ];

    final borderColor = _isPressed
        ? AppColors.accentChampagne.withValues(alpha: 0.8)
        : (isDark
            ? AppColors.silverBorder.withValues(alpha: 0.24)
            : AppColors.lightBorder);

    final iconColor = _isPressed
        ? AppColors.accentChampagne
        : (isDark ? AppColors.silverPrimary : AppColors.primarySoftNavy);

    final textColor = _isPressed
        ? (isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary)
        : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: bgColors,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: borderColor,
                  width: _isPressed ? 1.0 : 0.8,
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Center(
                child: Icon(
                  widget.category.icon,
                  size: 22,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.label,
              style: AppTypography.caption.copyWith(
                color: textColor,
                fontSize: 11,
                fontWeight: _isPressed ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
