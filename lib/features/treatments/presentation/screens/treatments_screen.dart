import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/features/treatments/data/treatments_repository.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';
import 'package:aesthetic_way/features/treatments/presentation/screens/treatment_detail_screen.dart';

/// Screen 2 & 5: Treatments & Plastic Surgery Directory
class TreatmentsScreen extends StatefulWidget {
  final String? initialCategory;

  const TreatmentsScreen({super.key, this.initialCategory});

  @override
  State<TreatmentsScreen> createState() => _TreatmentsScreenState();
}

class _TreatmentsScreenState extends State<TreatmentsScreen> {
  final TreatmentsRepository _repository = TreatmentsRepository();
  late String _selectedCategory;
  String _searchQuery = '';
  List<TreatmentModel> _treatments = [];
  List<Map<String, dynamic>> _apiCategories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'all';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.getTreatments(),
        _repository.getCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _treatments = results[0] as List<TreatmentModel>;
        _apiCategories = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    final isPlasticSurgeryOnly = widget.initialCategory != null &&
        (widget.initialCategory!.toLowerCase().contains('surgery') || widget.initialCategory!.contains('جراحة'));

    final screenTitle = isPlasticSurgeryOnly
        ? loc.tr('category_plastic_surgery_title')
        : loc.tr('category_treatments_title');

    final defaultCategories = [
      {'id': 'all', 'label': loc.tr('treatment_category_all')},
      {'id': 'surgery', 'label': loc.tr('treatment_category_surgery')},
      {'id': 'injectables', 'label': loc.tr('treatment_category_injectables')},
      {'id': 'skincare', 'label': loc.tr('treatment_category_skincare')},
      {'id': 'laser', 'label': loc.tr('treatment_category_laser')},
    ];

    final categories = _apiCategories.isNotEmpty
        ? [
            {'id': 'all', 'label': loc.tr('treatment_category_all')},
            ..._apiCategories.map((c) => {
                  'id': c['id']?.toString() ?? '',
                  'label': (loc.isArabic ? c['name_ar'] : c['name_en'])?.toString() ?? '',
                }),
          ]
        : defaultCategories;

    final filteredTreatments = _treatments.where((t) {
      if (isPlasticSurgeryOnly) {
        final matchesCat = t.categoryAr.contains('جراحة') || t.categoryEn.toLowerCase().contains('surgery');
        if (!matchesCat) return false;
      } else if (_selectedCategory != 'all') {
        if (t.categoryId == _selectedCategory) {
          // Exact API category UUID match
        } else if (_selectedCategory == 'surgery') {
          if (!t.categoryAr.contains('جراحة') && !t.categoryEn.toLowerCase().contains('surgery')) return false;
        } else if (_selectedCategory == 'injectables') {
          if (!t.categoryAr.contains('حقن') && !t.categoryEn.toLowerCase().contains('injectables')) return false;
        } else if (_selectedCategory == 'skincare') {
          if (!t.categoryAr.contains('عناية') && !t.categoryEn.toLowerCase().contains('skincare')) return false;
        } else if (_selectedCategory == 'laser') {
          if (!t.categoryAr.contains('ليزر') && !t.categoryEn.toLowerCase().contains('laser')) return false;
        } else {
          return false;
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
      listenable: loc,
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

              // Treatments List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.accentChampagne))
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_error!, style: TextStyle(color: AppColors.mutedText(context))),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _loadData,
                                  child: Text(loc.isArabic ? 'إعادة المحاولة' : 'Retry'),
                                ),
                              ],
                            ),
                          )
                        : filteredTreatments.isEmpty
                            ? RefreshIndicator(
                                color: AppColors.accentChampagne,
                                onRefresh: _loadData,
                                child: ListView(
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
                                                child: const Icon(Icons.spa_outlined, size: 36, color: AppColors.accentChampagne),
                                              ),
                                              const SizedBox(height: 14),
                                              Text(
                                                loc.isArabic ? 'لا توجد علاجات متاحة حالياً' : 'No treatments available',
                                                style: AppTypography.cardTitle.copyWith(
                                                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                loc.isArabic
                                                    ? 'سيتم إضافة خدمات تجميلية وجلدية جديدة قريباً'
                                                    : 'New cosmetic and derma treatments will be listed soon',
                                                style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 16),
                                              ElevatedButton.icon(
                                                onPressed: _loadData,
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
                              )
                            : RefreshIndicator(
                                color: AppColors.accentChampagne,
                                onRefresh: _loadData,
                                child: ListView.builder(
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
                                            LuxuryImage(
                                              imageUrl: treatment.imageUrl,
                                              fallbackLogoUrl: treatment.clinicLogoUrl,
                                              width: 80,
                                              height: 80,
                                              borderRadius: BorderRadius.circular(12),
                                              placeholderIcon: Icons.medical_services_rounded,
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
                                                  if (treatment.formattedDuration(loc.isArabic).isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${loc.tr("duration_label")}: ${treatment.formattedDuration(loc.isArabic)}',
                                                      style: TextStyle(color: AppColors.subtext(context), fontSize: 11.5, fontWeight: FontWeight.w600),
                                                    ),
                                                  ] else if ((loc.isArabic ? treatment.clinicNameAr : treatment.clinicNameEn)?.isNotEmpty == true) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      (loc.isArabic ? treatment.clinicNameAr : treatment.clinicNameEn)!,
                                                      style: TextStyle(color: AppColors.subtext(context), fontSize: 11.5),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
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
              ),
            ],
          ),
        );
      },
    );
  }
}
