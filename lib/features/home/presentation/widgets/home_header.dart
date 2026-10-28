import '../../../locations/models/uae_location.dart';
import '../../../locations/presentation/uae_location_picker.dart';
import '../../../locations/data/uae_location_repository.dart';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/app_brand_logo.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';

/// Home Screen Luxury Header with Official Client Logo and City Selector adapting to Themes
class HomeHeader extends StatelessWidget {
  final String selectedCity;
  final ValueChanged<String> onCityChanged;
  final String? selectedAreaCode;
  final ValueChanged<UaeLocality>? onLocalityChanged;

  const HomeHeader({
    super.key,
    required this.selectedCity,
    required this.onCityChanged,
    this.selectedAreaCode,
    this.onLocalityChanged,
  });

  String _displayCityLabel(LocaleService loc) =>
      currentUaeCatalog.resolve(selectedCity)?.label(loc.isArabic) ??
      (currentUaeCatalog.legacyCityQuery(selectedCity) ?? loc.tr('city_all'));

  Future<void> _showCityPicker(BuildContext context) async {
    final locality = await showUaeLocalityPicker(
      context,
      selected: selectedCity,
      areaCode: selectedAreaCode,
    );
    if (context.mounted && locality != null) {
      if (onLocalityChanged != null) {
        onLocalityChanged!(locality);
      } else {
        onCityChanged(locality.city.nameEn);
      }
    }
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppBrandLogo.header(height: 46, width: 46),
              const SizedBox(width: 8),
              Text(
                'AESTHETIC\nWAY',
                style: TextStyle(
                  color: AppColors.text(context),
                  fontFamily: 'PatientDisplay',
                  fontSize: 13,
                  height: 1.35,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

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
                  mainAxisSize: MainAxisSize.min,
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
