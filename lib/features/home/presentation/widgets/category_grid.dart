import '../../../../core/theme/patient_design.dart';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
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
      icon: Icons.auto_awesome_outlined,
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
              Expanded(
                child: Text(
                  loc.tr('categories_title'),
                  style: PatientDesign.heading(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final minWidth = MediaQuery.textScalerOf(context).scale(1) > 1.3
                  ? 120.0
                  : 76.0;
              final columns = (constraints.maxWidth / minWidth).floor().clamp(
                2,
                4,
              );
              final width =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 18,
                children: [
                  for (final category in categories)
                    SizedBox(
                      width: width,
                      child: _CategoryItemWidget(
                        category: category,
                        label: loc.tr(category.translationKey),
                        onTap: () => onCategorySelected(category),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryItemWidget extends StatelessWidget {
  const _CategoryItemWidget({
    required this.category,
    required this.label,
    required this.onTap,
  });
  final CategoryItem category;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(context), width: .7),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceSubtle(context),
              ),
              child: Icon(
                category.icon,
                size: 24,
                color: AppColors.goldText(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: AppColors.text(context),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
