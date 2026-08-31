import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/data/mock_data.dart';
import 'package:aesthetic_way/features/treatments/presentation/screens/treatment_detail_screen.dart';

/// Screen 2 & 5: Treatments & Plastic Surgery Directory
class TreatmentsScreen extends StatefulWidget {
  final String? initialCategory;

  const TreatmentsScreen({super.key, this.initialCategory});

  @override
  State<TreatmentsScreen> createState() => _TreatmentsScreenState();
}

class _TreatmentsScreenState extends State<TreatmentsScreen> {
  late String _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'all';
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final mockData = MockDataService();
    final isDark = AppColors.isDark(context);

    final isPlasticSurgeryOnly = widget.initialCategory != null &&
        (widget.initialCategory!.toLowerCase().contains('surgery') || widget.initialCategory!.contains('جراحة'));

    final screenTitle = isPlasticSurgeryOnly
        ? loc.tr('category_plastic_surgery_title')
        : loc.tr('category_treatments_title');

    final categories = [
      {'id': 'all', 'label': loc.tr('treatment_category_all')},
      {'id': 'surgery', 'label': loc.tr('treatment_category_surgery')},
      {'id': 'injectables', 'label': loc.tr('treatment_category_injectables')},
      {'id': 'skincare', 'label': loc.tr('treatment_category_skincare')},
      {'id': 'laser', 'label': loc.tr('treatment_category_laser')},
    ];

    final filteredTreatments = mockData.treatments.where((t) {
      // Plastic surgery icon filter
      if (isPlasticSurgeryOnly) {
        final matchesCat = t.categoryAr.contains('جراحة') || t.categoryEn.toLowerCase().contains('surgery');
        if (!matchesCat) return false;
      } else if (_selectedCategory != 'all') {
        if (_selectedCategory == 'surgery') {
          if (!t.categoryAr.contains('جراحة') && !t.categoryEn.toLowerCase().contains('surgery')) return false;
        } else if (_selectedCategory == 'injectables') {
          if (!t.categoryAr.contains('حقن') && !t.categoryEn.toLowerCase().contains('injectables')) return false;
        } else if (_selectedCategory == 'skincare') {
          if (!t.categoryAr.contains('عناية') && !t.categoryEn.toLowerCase().contains('skincare')) return false;
        } else if (_selectedCategory == 'laser') {
          if (!t.categoryAr.contains('ليزر') && !t.categoryEn.toLowerCase().contains('laser')) return false;
        }
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return t.nameAr.toLowerCase().contains(q) ||
            t.nameEn.toLowerCase().contains(q) ||
            t.descriptionAr.toLowerCase().contains(q) ||
            t.targetAreaAr.toLowerCase().contains(q);
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
              screenTitle,
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
              // Search Box
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
                      hintText: loc.tr('treatments_search_hint'),
                      hintStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.mutedText(context), size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              // Category Tabs (Only if not exclusively plastic surgery)
              if (!isPlasticSurgeryOnly)
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

              // Treatments List
              Expanded(
                child: filteredTreatments.isEmpty
                    ? Center(
                        child: Text(
                          loc.isArabic ? 'لا توجد علاجات مطابقة' : 'No treatments found',
                          style: TextStyle(color: AppColors.mutedText(context)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filteredTreatments.length,
                        itemBuilder: (context, index) {
                          final treatment = filteredTreatments[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: LuxuryCard(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  LuxuryPageRoute(page: TreatmentDetailScreen(treatment: treatment)),
                                );
                              },
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      treatment.imageUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        width: 80,
                                        height: 80,
                                        color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                                        child: const Icon(Icons.medical_services_rounded, color: AppColors.accentChampagne),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.12 : 0.18),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            loc.isArabic ? treatment.categoryAr : treatment.categoryEn,
                                            style: const TextStyle(
                                              color: AppColors.accentChampagne,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          loc.isArabic ? treatment.nameAr : treatment.nameEn,
                                          style: TextStyle(
                                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${loc.tr("duration_label")}: ${loc.isArabic ? treatment.durationText : treatment.durationTextEn}',
                                          style: TextStyle(color: AppColors.mutedText(context), fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.accentChampagne),
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
