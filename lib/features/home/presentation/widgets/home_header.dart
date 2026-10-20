import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/app_brand_logo.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';

/// Home Screen Luxury Header with Official Client Logo and City Selector adapting to Themes
class HomeHeader extends StatelessWidget {
  final String selectedCity;
  final ValueChanged<String> onCityChanged;

  const HomeHeader({
    super.key,
    required this.selectedCity,
    required this.onCityChanged,
  });

  String _displayCityLabel(LocaleService loc) {
    if (selectedCity == 'الكل' || selectedCity == 'All') {
      return loc.tr('city_all');
    }
    if (selectedCity == 'دبي' || selectedCity == 'Dubai') {
      return loc.isArabic ? 'دبي' : 'Dubai';
    }
    if (selectedCity == 'أبوظبي' || selectedCity == 'Abu Dhabi') {
      return loc.isArabic ? 'أبوظبي' : 'Abu Dhabi';
    }
    return selectedCity;
  }

  void _showCityPicker(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.tr('select_city'),
                  style: AppTypography.cardTitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.silverPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _CityOptionTile(
                  title: loc.tr('city_all'),
                  isSelected: selectedCity == 'الكل' || selectedCity == 'All',
                  onTap: () {
                    onCityChanged('الكل');
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
                _CityOptionTile(
                  title: loc.isArabic
                      ? 'دبي (جميرا، داون تاون، دبي مارينا)'
                      : 'Dubai (Jumeirah, Downtown, Marina)',
                  isSelected: selectedCity == 'دبي' || selectedCity == 'Dubai',
                  onTap: () {
                    onCityChanged('دبي');
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
                _CityOptionTile(
                  title: loc.isArabic
                      ? 'أبوظبي (البطين، الكورنيش، جزيرة المارية)'
                      : 'Abu Dhabi (Al Bateen, Corniche, Al Maryah)',
                  isSelected:
                      selectedCity == 'أبوظبي' || selectedCity == 'Abu Dhabi',
                  onTap: () {
                    onCityChanged('أبوظبي');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Official Brand Logo (assets/images/aesthetic_way_logo.png)
          const AppBrandLogo.header(height: 46, width: 104),

          // 2. City Selector (No heart/favorite icon on Home header per client spec)
          Flexible(
            child: GestureDetector(
              onTap: () => _showCityPicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.border(context),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: isDark
                          ? AppColors.silverPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _displayCityLabel(loc),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.text(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.mutedText(context),
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
}

class _CityOptionTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _CityOptionTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentChampagne.withValues(
                  alpha: isDark ? 0.15 : 0.12,
                )
              : (isDark
                    ? AppColors.cardSurfaceHover
                    : AppColors.lightCardSurfaceHover),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.accentChampagne
                : AppColors.border(context),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.goldText(context)
                      : (isDark
                            ? AppColors.silverPrimary
                            : AppColors.lightTextPrimary),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.accentChampagne,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
