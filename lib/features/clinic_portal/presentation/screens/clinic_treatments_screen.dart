import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/ltr_text_field.dart';
import '../../../../core/widgets/luxury_card.dart';
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
      ClinicPortalService().loadCatalogData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showTreatmentFormDialog(
    BuildContext context,
    LocaleService loc, {
    TreatmentModel? existing,
  }) {
    final formKey = GlobalKey<FormState>();
    final isEditing = existing != null;
    final clinicService = ClinicPortalService();

    final nameEnController = TextEditingController(text: existing?.nameEn ?? '');
    final nameArController = TextEditingController(text: existing?.nameAr ?? '');
    final priceController = TextEditingController(
      text: existing?.price != null ? existing!.price!.toInt().toString() : '750',
    );
    final descEnController = TextEditingController(text: existing?.descriptionEn ?? '');
    final descArController = TextEditingController(text: existing?.descriptionAr ?? '');

    String? chosenCategoryId = existing?.categoryId;
    if (chosenCategoryId == null && clinicService.categories.isNotEmpty) {
      chosenCategoryId = clinicService.categories.first.id;
    }

    final selectedPractitioners = List<String>.from(existing?.practitionerIds ?? []);
    final isDark = AppColors.isDark(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                color: isDark ? AppColors.backgroundDeep : AppColors.lightCardSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppColors.border(ctx), width: 0.8)),
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
                          color: AppColors.mutedText(ctx).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEditing
                          ? (loc.isArabic ? 'تعديل الإجراء / الخدمة' : 'Edit Treatment')
                          : (loc.isArabic ? 'إضافة إجراء تجميلي جديد' : 'Add Treatment / Service'),
                      style: AppTypography.cardTitle.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category Selector
                    if (clinicService.categories.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: chosenCategoryId,
                        dropdownColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                        decoration: InputDecoration(
                          labelText: loc.isArabic ? 'التصنيف الطبي *' : 'Category *',
                          filled: true,
                          fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                          ),
                        ),
                        items: clinicService.categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat.id,
                            child: Text(
                              loc.isArabic ? cat.nameAr : cat.nameEn,
                              style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setModalState(() => chosenCategoryId = v);
                          }
                        },
                        validator: (v) => v == null ? loc.tr('clinic_validation_required') : null,
                      ),
                    const SizedBox(height: 10),

                    // Name EN & Name AR
                    LtrTextFormField(
                      controller: nameEnController,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'اسم الإجراء بالإنجليزية *' : 'Treatment Name (English) *',
                        hintText: 'e.g. HydraFacial Deluxe',
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: nameArController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'اسم الإجراء بالعربية *' : 'Treatment Name (Arabic) *',
                        hintText: 'مثال: هيدرافاشيال ديلوكس',
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                    ),
                    const SizedBox(height: 10),

                    // Price (AED)
                    LtrTextFormField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'السعر التقديري (درهم إماراتي)' : 'Estimated Price (AED)',
                        hintText: 'e.g. 750',
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description EN & AR
                    LtrTextFormField(
                      controller: descEnController,
                      maxLines: 2,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'الوصف الطبي بالإنجليزية' : 'Description (English)',
                        hintText: 'e.g. Deep cleansing and active serum infusion.',
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descArController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'الوصف الطبي بالعربية' : 'Description (Arabic)',
                        hintText: 'مثال: تنظيف عميق للبشرة وتغذية بالسيروم الفعال.',
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Practitioner Assignment Multi-Select
                    if (clinicService.clinicPractitioners.isNotEmpty) ...[
                      Text(
                        loc.isArabic ? 'تعيين الأطباء / الممارسين لهذا الإجراء:' : 'Assign Practitioners:',
                        style: AppTypography.cardTitle.copyWith(fontSize: 13, color: AppColors.silverPrimary),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: clinicService.clinicPractitioners.map((p) {
                          final isSelected = selectedPractitioners.contains(p.id);
                          return FilterChip(
                            label: Text(loc.isArabic ? p.nameAr : p.nameEn),
                            selected: isSelected,
                            selectedColor: AppColors.accentChampagne.withValues(alpha: 0.2),
                            checkmarkColor: AppColors.accentChampagne,
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
                          ? (loc.isArabic ? 'حفظ التعديلات' : 'Update Treatment')
                          : (loc.isArabic ? 'إضافة الإجراء' : 'Save Treatment'),
                      icon: Icons.check_circle_outline,
                      isFullWidth: true,
                      height: 46,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        if (chosenCategoryId == null) {
                          showAppSnackBar(
                            context,
                            loc.isArabic ? 'يرجى اختيار التصنيف الطبي' : 'Please select a category',
                            type: AppSnackBarType.error,
                          );
                          return;
                        }

                        final data = <String, dynamic>{
                          'category': chosenCategoryId,
                          'name_en': nameEnController.text.trim(),
                          'name_ar': nameArController.text.trim().isNotEmpty
                              ? nameArController.text.trim()
                              : nameEnController.text.trim(),
                          'description_en': descEnController.text.trim(),
                          'description_ar': descArController.text.trim(),
                          'status': 'active',
                          'is_active': true,
                          if (priceController.text.trim().isNotEmpty)
                            'price': double.tryParse(priceController.text.trim()) ?? 0.0,
                          if (selectedPractitioners.isNotEmpty)
                            'practitioners': selectedPractitioners,
                        };

                        try {
                          if (isEditing) {
                            await clinicService.updateTreatment(existing.id, data);
                          } else {
                            await clinicService.createTreatment(data);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            showAppSnackBar(
                              context,
                              isEditing
                                  ? (loc.isArabic ? 'تم تحديث الإجراء بنجاح' : 'Treatment updated successfully')
                                  : (loc.isArabic ? 'تمت إضافة الإجراء بنجاح' : 'Treatment added successfully'),
                              type: AppSnackBarType.success,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            showAppSnackBar(context, e.toString(), type: AppSnackBarType.error);
                          }
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
  }

  void _confirmDelete(BuildContext context, LocaleService loc, TreatmentModel t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.isDark(context) ? AppColors.cardSurface : Colors.white,
        title: Text(
          loc.isArabic ? 'حذف الإجراء الطبي' : 'Delete Treatment',
          style: AppTypography.cardTitle.copyWith(
            color: AppColors.isDark(context) ? AppColors.silverPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          loc.isArabic
              ? 'هل أنت متأكد من حذف "${t.nameAr}" من قائمة الخدمات؟'
              : 'Are you sure you want to delete "${t.nameEn}" from services?',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedText(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
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
                  showAppSnackBar(context, e.toString(), type: AppSnackBarType.error);
                }
              }
            },
            child: Text(loc.isArabic ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

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
          final matchesCategory = _selectedCategoryId == null || t.categoryId == _selectedCategoryId;
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
              loc.isArabic ? 'إدارة الخدمات والعلاجات' : 'Treatments & Services',
              style: AppTypography.screenTitle.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                fontSize: 16,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentChampagne),
                tooltip: loc.isArabic ? 'إضافة إجراء' : 'Add Treatment',
                onPressed: () => _showTreatmentFormDialog(context, loc),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: loc.isArabic ? 'بحث عن علاج أو إجراء تجميلي...' : 'Search treatment or procedure...',
                    hintStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.accentChampagne),
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
                    fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context), width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accentChampagne, width: 1.4),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
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
                          label: Text(loc.isArabic ? 'الكل' : 'All'),
                          selected: _selectedCategoryId == null,
                          selectedColor: AppColors.accentChampagne.withValues(alpha: 0.25),
                          onSelected: (_) => setState(() => _selectedCategoryId = null),
                        ),
                      ),
                      ...clinicService.categories.map((cat) {
                        final isSel = _selectedCategoryId == cat.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(loc.isArabic ? cat.nameAr : cat.nameEn),
                            selected: isSel,
                            selectedColor: AppColors.accentChampagne.withValues(alpha: 0.25),
                            onSelected: (_) => setState(() => _selectedCategoryId = isSel ? null : cat.id),
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
                  onRefresh: () => clinicService.loadCatalogData(refresh: true),
                  child: filtered.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.spa_outlined, size: 48, color: AppColors.mutedText(context)),
                                  const SizedBox(height: 12),
                                  Text(
                                    loc.isArabic ? 'لا توجد خدمات مطابقة' : 'No treatments found',
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedText(context)),
                                  ),
                                  const SizedBox(height: 16),
                                  SilverButton(
                                    label: loc.isArabic ? 'إضافة إجراء جديد' : 'Add Treatment',
                                    icon: Icons.add,
                                    height: 38,
                                    onPressed: () => _showTreatmentFormDialog(context, loc),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final t = filtered[index];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: LuxuryCard(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.accentChampagne.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.spa_rounded, color: AppColors.accentChampagne, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            loc.isArabic ? t.nameAr : t.nameEn,
                                            style: AppTypography.cardTitle.copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            loc.isArabic ? t.categoryAr : t.categoryEn,
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.mutedText(context),
                                              fontSize: 11.5,
                                            ),
                                          ),
                                          if (t.price != null && t.price! > 0) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              '${t.price!.toInt()} ${loc.tr('currency_aed')}',
                                              style: AppTypography.caption.copyWith(
                                                color: AppColors.accentChampagne,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.silverPrimary),
                                          tooltip: loc.isArabic ? 'تعديل' : 'Edit',
                                          onPressed: () => _showTreatmentFormDialog(context, loc, existing: t),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.errorRed),
                                          tooltip: loc.isArabic ? 'حذف' : 'Delete',
                                          onPressed: () => _confirmDelete(context, loc, t),
                                        ),
                                      ],
                                    ),
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showTreatmentFormDialog(context, loc),
            backgroundColor: AppColors.accentChampagne,
            foregroundColor: AppColors.backgroundDeep,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              loc.isArabic ? 'إضافة إجراء' : 'Add Treatment',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ),
        );
      },
    );
  }
}
