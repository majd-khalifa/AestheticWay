import '../widgets/clinic_treatment_editor.dart';
import '../widgets/clinic_catalog_cards.dart';
import '../widgets/clinic_category_manager.dart';
import 'package:aesthetic_way/core/widgets/pagination_footer.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/silver_button.dart';
import '../../../treatments/models/treatment_model.dart';
import '../../services/clinic_portal_service.dart';

/// Clinic Portal: Treatments & Services Management Screen
class ClinicTreatmentsScreen extends StatefulWidget {
  const ClinicTreatmentsScreen({super.key});

  @override
  State<ClinicTreatmentsScreen> createState() => _ClinicTreatmentsScreenState();
}

class _ClinicTreatmentsScreenState extends State<ClinicTreatmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ClinicPortalService().loadCollection('treatments');
      ClinicPortalService().getOrFetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(
    BuildContext context,
    LocaleService loc,
    TreatmentModel t,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.isDark(context)
            ? AppColors.cardSurface
            : Colors.white,
        title: Text(
          loc.isArabic ? 'حذف الإجراء الطبي' : 'Delete Treatment',
          style: AppTypography.cardTitle.copyWith(
            color: AppColors.isDark(context)
                ? AppColors.silverPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          loc.isArabic
              ? 'هل أنت متأكد من حذف "${t.nameAr}" من قائمة الخدمات؟'
              : 'Are you sure you want to delete "${t.nameEn}" from services?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.mutedText(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ClinicPortalService().deleteTreatment(t.id);
                if (context.mounted) {
                  showAppSnackBar(
                    context,
                    loc.isArabic ? 'تم حذف الإجراء بنجاح' : 'Treatment deleted',
                    type: AppSnackBarType.success,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  showAppSnackBar(
                    context,
                    e.toString(),
                    type: AppSnackBarType.error,
                  );
                }
              }
            },
            child: Text(
              loc.isArabic ? 'حذف' : 'Delete',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _queryChanged() => ClinicPortalService().searchCollection('treatments', {
    'search': _searchQuery,
    'category': _selectedCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final clinicService = ClinicPortalService();
    final isDark = AppColors.isDark(context);

    return ListenableBuilder(
      listenable: Listenable.merge([loc, clinicService]),
      builder: (context, _) {
        final all = clinicService.clinicTreatments;
        final filtered = all.where((t) {
          final matchesCategory =
              _selectedCategoryId == null ||
              t.categoryId == _selectedCategoryId;
          if (!matchesCategory) return false;
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return t.nameEn.toLowerCase().contains(q) ||
              t.nameAr.toLowerCase().contains(q) ||
              t.categoryEn.toLowerCase().contains(q) ||
              t.categoryAr.toLowerCase().contains(q);
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Text(
              loc.isArabic
                  ? 'إدارة الخدمات والعلاجات'
                  : 'Treatments & Services',
              style: AppTypography.screenTitle.copyWith(
                color: isDark
                    ? AppColors.silverPrimary
                    : AppColors.lightTextPrimary,
                fontSize: 16,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => showClinicCategoryManager(context),
                tooltip: loc.isArabic ? 'تصفح التصنيفات' : 'Browse Categories',
                icon: Icon(
                  Icons.create_new_folder_outlined,
                  color: AppColors.text(context),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.accentChampagne,
                ),
                tooltip: loc.isArabic ? 'إضافة إجراء' : 'Add Treatment',
                onPressed: () => showClinicTreatmentEditor(context, loc),
              ),
            ],
          ),
          body: PagedScrollBoundary(
            onLoadMore: () => clinicService.loadMore('treatments'),
            child: Column(
              children: [
                // Search input
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: loc.isArabic
                          ? 'بحث عن علاج أو إجراء تجميلي...'
                          : 'Search treatment or procedure...',
                      hintStyle: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        color: AppColors.accentChampagne,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.cardSurfaceHover
                          : AppColors.lightCardSurfaceHover,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.border(context),
                          width: 0.8,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.accentChampagne,
                          width: 1.4,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim());
                      _queryChanged();
                    },
                  ),
                ),

                // Categories Filter Chips
                if (clinicService.categories.isNotEmpty)
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(
                              loc.isArabic ? 'الكل' : 'All',
                              style: TextStyle(
                                color: _selectedCategoryId == null
                                    ? (isDark
                                          ? AppColors.goldText(context)
                                          : AppColors.backgroundDeep)
                                    : (isDark
                                          ? AppColors.silverPrimary
                                          : AppColors.lightTextPrimary),
                                fontWeight: _selectedCategoryId == null
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            selected: _selectedCategoryId == null,
                            selectedColor: isDark
                                ? AppColors.accentChampagne.withValues(
                                    alpha: 0.25,
                                  )
                                : AppColors.accentChampagne.withValues(
                                    alpha: 0.35,
                                  ),
                            checkmarkColor: isDark
                                ? AppColors.accentChampagne
                                : AppColors.backgroundDeep,
                            onSelected: (_) {
                              setState(() => _selectedCategoryId = null);
                              _queryChanged();
                            },
                          ),
                        ),
                        ...clinicService.categories.map((cat) {
                          final isSel = _selectedCategoryId == cat.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(
                                loc.isArabic ? cat.nameAr : cat.nameEn,
                                style: TextStyle(
                                  color: isSel
                                      ? (isDark
                                            ? AppColors.goldText(context)
                                            : AppColors.backgroundDeep)
                                      : (isDark
                                            ? AppColors.silverPrimary
                                            : AppColors.lightTextPrimary),
                                  fontWeight: isSel
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                              selected: isSel,
                              selectedColor: isDark
                                  ? AppColors.accentChampagne.withValues(
                                      alpha: 0.25,
                                    )
                                  : AppColors.accentChampagne.withValues(
                                      alpha: 0.35,
                                    ),
                              checkmarkColor: isDark
                                  ? AppColors.accentChampagne
                                  : AppColors.backgroundDeep,
                              onSelected: (_) {
                                setState(
                                  () => _selectedCategoryId = isSel
                                      ? null
                                      : cat.id,
                                );
                                _queryChanged();
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                const SizedBox(height: 6),

                // Content List
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.accentChampagne,
                    onRefresh: () => clinicService.loadCollection(
                      'treatments',
                      refresh: true,
                    ),
                    child: filtered.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.25,
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.spa_outlined,
                                      size: 48,
                                      color: AppColors.mutedText(context),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      loc.isArabic
                                          ? 'لا توجد خدمات مطابقة'
                                          : 'No treatments found',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.mutedText(context),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SilverButton(
                                      label: loc.isArabic
                                          ? 'إضافة إجراء جديد'
                                          : 'Add Treatment',
                                      icon: Icons.add,
                                      height: 38,
                                      onPressed: () =>
                                          showClinicTreatmentEditor(
                                            context,
                                            loc,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: filtered.length + 1,
                            itemBuilder: (context, index) {
                              if (index >= filtered.length) {
                                return PaginationFooter(
                                  loading: clinicService
                                      .collection('treatments')
                                      .isLoadingMore,
                                  hasMore: clinicService
                                      .collection('treatments')
                                      .hasMore,
                                  error: clinicService
                                      .collection('treatments')
                                      .error,
                                  onLoadMore: () =>
                                      clinicService.loadMore('treatments'),
                                );
                              }

                              final t = filtered[index];

                              return ClinicTreatmentCard(
                                treatment: t,
                                practitioners:
                                    clinicService.clinicPractitioners,
                                onEdit: () => showClinicTreatmentEditor(
                                  context,
                                  loc,
                                  existing: t,
                                ),
                                onDelete: () => _confirmDelete(context, loc, t),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showClinicTreatmentEditor(context, loc),
            backgroundColor: AppColors.accentChampagne,
            foregroundColor: AppColors.backgroundDeep,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              loc.isArabic ? 'إضافة إجراء' : 'Add Treatment',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> showClinicTreatmentEditor(
  BuildContext context,
  LocaleService loc, {
  TreatmentModel? existing,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppColors.surface(context),
  builder: (_) => ClinicTreatmentEditor(existing: existing),
);
