import '../widgets/clinic_catalog_cards.dart';
import '../widgets/clinic_category_manager.dart';
import '../widgets/clinic_category_field.dart';
import 'package:aesthetic_way/core/widgets/pagination_footer.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/ltr_text_field.dart';
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
                onPressed: () => showClinicCategoryEditor(context),
                tooltip: loc.isArabic ? 'إضافة تصنيف جديد' : 'Add New Category',
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

void showClinicTreatmentEditor(
  BuildContext context,
  LocaleService loc, {
  TreatmentModel? existing,
}) {
  ClinicPortalService().loadCollection('practitioners');
  final formKey = GlobalKey<FormState>();
  final isEditing = existing != null;
  final clinicService = ClinicPortalService();

  final nameEnController = TextEditingController(text: existing?.nameEn ?? '');
  final nameArController = TextEditingController(text: existing?.nameAr ?? '');
  final priceController = TextEditingController(
    text: existing?.price != null ? existing!.price!.toInt().toString() : '750',
  );
  final descEnController = TextEditingController(
    text: existing?.descriptionEn ?? '',
  );
  final descArController = TextEditingController(
    text: existing?.descriptionAr ?? '',
  );

  if (clinicService.categories.isEmpty) {
    clinicService.getOrFetchCategories();
  }
  final categories = clinicService.categories;
  String? chosenCategoryId = existing?.categoryId;
  String? chosenCategoryLabel = existing == null
      ? null
      : (loc.isArabic ? existing.categoryAr : existing.categoryEn);
  if (chosenCategoryId == null && categories.isNotEmpty) {
    chosenCategoryId = categories.first.id;
  }

  final selectedPractitioners = List<String>.from(
    existing?.practitionerIds ?? [],
  );
  final isDark = AppColors.isDark(context);

  String? modalErrorMessage;
  bool isSubmitting = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return ListenableBuilder(
        listenable: clinicService,
        builder: (ctx, _) {
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              return Container(
                height: MediaQuery.of(ctx).size.height * 0.88,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDeep
                      : AppColors.lightCardSurface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(color: AppColors.border(ctx), width: 0.8),
                  ),
                ),
                child: Form(
                  key: formKey,
                  child: ListView(
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.mutedText(
                              ctx,
                            ).withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isEditing
                            ? (loc.isArabic
                                  ? 'تعديل الإجراء / الخدمة'
                                  : 'Edit Treatment')
                            : (loc.isArabic
                                  ? 'إضافة إجراء تجميلي جديد'
                                  : 'Add Treatment / Service'),
                        style: AppTypography.cardTitle.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isDark
                              ? AppColors.silverPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (modalErrorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(
                              alpha: isDark ? 0.2 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.6),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  modalErrorMessage!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () {
                                  setModalState(() => modalErrorMessage = null);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Category Selector
                      ClinicCategoryField(
                        categories: clinicService.categories,
                        value: chosenCategoryId,
                        valueLabel: chosenCategoryLabel,
                        onChanged: (c) => setModalState(() {
                          chosenCategoryId = c?.id;
                          chosenCategoryLabel = c == null
                              ? null
                              : (loc.isArabic ? c.nameAr : c.nameEn);
                          modalErrorMessage = null;
                        }),
                      ),
                      const SizedBox(height: 10),

                      // Name EN & Name AR
                      LtrTextFormField(
                        controller: nameEnController,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.lightTextPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: loc.isArabic
                              ? 'اسم الإجراء بالإنجليزية *'
                              : 'Treatment Name (English) *',
                          hintText: 'e.g. HydraFacial Deluxe',
                          filled: true,
                          fillColor: isDark
                              ? AppColors.cardSurfaceHover
                              : AppColors.lightCardSurfaceHover,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.border(ctx),
                              width: 0.8,
                            ),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? loc.tr('clinic_validation_required')
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: nameArController,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.lightTextPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: loc.isArabic
                              ? 'اسم الإجراء بالعربية *'
                              : 'Treatment Name (Arabic) *',
                          hintText: 'مثال: هيدرافاشيال ديلوكس',
                          filled: true,
                          fillColor: isDark
                              ? AppColors.cardSurfaceHover
                              : AppColors.lightCardSurfaceHover,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.border(ctx),
                              width: 0.8,
                            ),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? loc.tr('clinic_validation_required')
                            : null,
                      ),
                      const SizedBox(height: 10),

                      // Price (AED)
                      LtrTextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.lightTextPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: loc.isArabic
                              ? 'السعر التقديري (درهم إماراتي)'
                              : 'Estimated Price (AED)',
                          hintText: 'e.g. 750',
                          filled: true,
                          fillColor: isDark
                              ? AppColors.cardSurfaceHover
                              : AppColors.lightCardSurfaceHover,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.border(ctx),
                              width: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Description EN & AR
                      LtrTextFormField(
                        controller: descEnController,
                        maxLines: 2,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.lightTextPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: loc.isArabic
                              ? 'الوصف الطبي بالإنجليزية'
                              : 'Description (English)',
                          hintText:
                              'e.g. Deep cleansing and active serum infusion.',
                          filled: true,
                          fillColor: isDark
                              ? AppColors.cardSurfaceHover
                              : AppColors.lightCardSurfaceHover,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.border(ctx),
                              width: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: descArController,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.lightTextPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: loc.isArabic
                              ? 'الوصف الطبي بالعربية'
                              : 'Description (Arabic)',
                          hintText:
                              'مثال: تنظيف عميق للبشرة وتغذية بالسيروم الفعال.',
                          filled: true,
                          fillColor: isDark
                              ? AppColors.cardSurfaceHover
                              : AppColors.lightCardSurfaceHover,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.border(ctx),
                              width: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Practitioner Assignment Multi-Select
                      if (clinicService.clinicPractitioners.isNotEmpty) ...[
                        Text(
                          loc.isArabic
                              ? 'تعيين الأطباء / الممارسين لهذا الإجراء:'
                              : 'Assign Practitioners:',
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.silverPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: clinicService.clinicPractitioners.map((p) {
                            final isSelected = selectedPractitioners.contains(
                              p.id,
                            );
                            return FilterChip(
                              label: Text(
                                loc.isArabic ? p.nameAr : p.nameEn,
                                style: TextStyle(
                                  color: isSelected
                                      ? (isDark
                                            ? AppColors.goldText(context)
                                            : AppColors.backgroundDeep)
                                      : (isDark
                                            ? AppColors.silverPrimary
                                            : AppColors.lightTextPrimary),
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                              selected: isSelected,
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
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    selectedPractitioners.add(p.id);
                                  } else {
                                    selectedPractitioners.remove(p.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 20),

                      SilverButton(
                        label: isEditing
                            ? (loc.isArabic
                                  ? 'حفظ التعديلات'
                                  : 'Update Treatment')
                            : (loc.isArabic
                                  ? 'إضافة الإجراء'
                                  : 'Save Treatment'),
                        icon: Icons.check_circle_outline,
                        isFullWidth: true,
                        height: 46,
                        isLoading: isSubmitting,
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setModalState(() => modalErrorMessage = null);
                                if (!formKey.currentState!.validate()) return;
                                if (chosenCategoryId == null) {
                                  setModalState(() {
                                    modalErrorMessage = loc.isArabic
                                        ? 'يرجى اختيار التصنيف الطبي'
                                        : 'Please select a medical category';
                                  });
                                  return;
                                }

                                final data = <String, dynamic>{
                                  'category': chosenCategoryId,
                                  'category_id': chosenCategoryId,
                                  'name_en': nameEnController.text.trim(),
                                  'name_ar':
                                      nameArController.text.trim().isNotEmpty
                                      ? nameArController.text.trim()
                                      : nameEnController.text.trim(),
                                  'description_en': descEnController.text
                                      .trim(),
                                  'description_ar': descArController.text
                                      .trim(),
                                  'status': 'active',
                                  'is_active': true,
                                  if (priceController.text.trim().isNotEmpty)
                                    'price':
                                        double.tryParse(
                                          priceController.text.trim(),
                                        ) ??
                                        0.0,
                                  'practitioners': selectedPractitioners,
                                };

                                setModalState(() => isSubmitting = true);

                                try {
                                  if (isEditing) {
                                    await clinicService.updateTreatment(
                                      existing.id,
                                      data,
                                    );
                                  } else {
                                    await clinicService.createTreatment(data);
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted) {
                                    showAppSnackBar(
                                      context,
                                      isEditing
                                          ? (loc.isArabic
                                                ? 'تم تحديث الإجراء بنجاح'
                                                : 'Treatment updated successfully')
                                          : (loc.isArabic
                                                ? 'تمت إضافة الإجراء بنجاح'
                                                : 'Treatment added successfully'),
                                      type: AppSnackBarType.success,
                                    );
                                  }
                                } catch (e) {
                                  String cleanMsg;
                                  if (e is ApiException) {
                                    cleanMsg = e.message;
                                  } else {
                                    cleanMsg =
                                        ApiException.sanitizeRegulatoryCompliance(
                                          e
                                              .toString()
                                              .replaceFirst('Exception: ', '')
                                              .replaceFirst(
                                                'ApiException: ',
                                                '',
                                              ),
                                        );
                                  }
                                  if (!ctx.mounted) return;
                                  setModalState(() {
                                    modalErrorMessage = cleanMsg;
                                    isSubmitting = false;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}
