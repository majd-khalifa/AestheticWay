import 'package:aesthetic_way/core/widgets/paged_entity_field.dart';
import '../../data/clinic_catalog_repository.dart';
import '../../../treatments/models/category_model.dart';
import '../../../offers/models/offer_model.dart';
import '../../../treatments/models/treatment_model.dart';
import '../../../../core/widgets/bounded_catalog_preview.dart';
import '../widgets/clinic_offer_editor.dart';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/theme/theme_service.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/core/widgets/ltr_text_field.dart';
import 'package:aesthetic_way/core/widgets/tier_badge.dart';
import 'package:aesthetic_way/core/widgets/practitioner_badge.dart';
import 'package:aesthetic_way/core/utils/maps_launcher.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/articles/models/article_model.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/login_screen.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/luxury_image_picker_field.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'clinic_practitioners_screen.dart';
import 'clinic_treatments_screen.dart';

/// Clinic Tab 4: Clinic Profile, Google Maps Linking, Medical Team & Services Manager
class ClinicProfileScreen extends StatefulWidget {
  const ClinicProfileScreen({super.key});

  @override
  State<ClinicProfileScreen> createState() => ClinicProfileScreenState();
}

class ClinicProfileScreenState extends State<ClinicProfileScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _productsSectionKey = GlobalKey();
  final GlobalKey _articlesSectionKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void scrollToSection(String section) {
    GlobalKey? targetKey;
    if (section == 'products') {
      targetKey = _productsSectionKey;
    } else if (section == 'articles') {
      targetKey = _articlesSectionKey;
    }

    if (targetKey != null && targetKey.currentContext != null) {
      Scrollable.ensureVisible(
        targetKey.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.1,
      );
    }
  }

  void _showAddPractitionerDialog(
    BuildContext context,
    LocaleService loc, {
    PractitionerModel? existing,
  }) {
    final formKey = GlobalKey<FormState>();
    final isEditing = existing != null;
    final nameEnController = TextEditingController(
      text: existing?.nameEn ?? '',
    );
    final nameArController = TextEditingController(
      text: existing?.nameAr ?? '',
    );
    final specialtyEnController = TextEditingController(
      text: existing?.specialtyEn ?? '',
    );
    final specialtyArController = TextEditingController(
      text: existing?.specialtyAr ?? '',
    );
    final bioEnController = TextEditingController(
      text: existing?.aboutEn ?? '',
    );
    final bioArController = TextEditingController(
      text: existing?.aboutAr ?? '',
    );
    var selectedType = existing?.type ?? PractitionerType.doctor;
    String? avatarPath = existing?.avatarUrl;
    bool avatarPathChanged = false;
    String? modalErrorMessage;
    bool isSubmitting = false;
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
                                ? 'تعديل بيانات الطبيب / الممارس'
                                : 'Edit Practitioner')
                          : loc.tr('clinic_add_practitioner'),
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

                    // Practitioner Avatar Picker
                    Center(
                      child: LuxuryImagePickerField(
                        label: loc.isArabic
                            ? 'صورة الطبيب / الممارس'
                            : 'Practitioner Photo',
                        initialUrl: existing?.avatarUrl.isNotEmpty == true
                            ? existing?.avatarUrl
                            : null,
                        isCircular: true,
                        height: 110,
                        width: 110,
                        onImageSelected: (path) {
                          avatarPath = path;
                          avatarPathChanged = true;
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Role / Type Dropdown
                    DropdownButtonFormField<PractitionerType>(
                      initialValue: selectedType,
                      dropdownColor: isDark
                          ? AppColors.cardSurface
                          : AppColors.lightCardSurface,
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'نوع الممارس'
                            : 'Practitioner Type',
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
                      items: PractitionerType.values.map((type) {
                        String label;
                        switch (type) {
                          case PractitionerType.doctor:
                            label = loc.tr('role_doctor');
                            break;
                          case PractitionerType.nurse:
                            label = loc.tr('role_nurse');
                            break;
                          case PractitionerType.licensedProfessional:
                            label = loc.tr('role_specialist');
                            break;
                        }
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setModalState(() {
                            selectedType = v;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Full Name EN & AR
                    LtrTextFormField(
                      controller: nameEnController,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'الاسم بالإنجليزية *'
                            : 'Full Name (English) *',
                        hintText: 'e.g. Dr. Sarah Al Mansoori',
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
                      validator: (val) => (val == null || val.trim().isEmpty)
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
                        labelText: loc.isArabic
                            ? 'الاسم بالعربية *'
                            : 'Full Name (Arabic) *',
                        hintText: 'مثال: د. سارة المنصوري',
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
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? loc.tr('clinic_validation_required')
                          : null,
                    ),
                    const SizedBox(height: 10),

                    // Specialty EN & AR
                    LtrTextFormField(
                      controller: specialtyEnController,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'التخصص بالإنجليزية'
                            : 'Specialty (English)',
                        hintText: 'e.g. Aesthetic Dermatology',
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
                      controller: specialtyArController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'التخصص بالعربية'
                            : 'Specialty (Arabic)',
                        hintText: 'مثال: جلدية وتجميل',
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

                    const SizedBox(height: 10),

                    // Short Professional Bio EN & AR
                    LtrTextFormField(
                      controller: bioEnController,
                      maxLines: 2,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'نبذة مهنية بالإنجليزية'
                            : 'Bio (English)',
                        hintText:
                            'e.g. Consultant Dermatologist with 12+ years in facial aesthetics...',
                        hintStyle: TextStyle(
                          color: AppColors.text(
                            context,
                          ).withValues(alpha: 0.68),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                        ),
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
                      controller: bioArController,
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
                        labelText: loc.isArabic
                            ? 'نبذة مهنية بالعربية'
                            : 'Bio (Arabic)',
                        hintText:
                            'مثال: استشارية أمراض جلدية وتجميل بخبرة تزيد عن 12 عاماً في الحقن التجميلي...',
                        hintStyle: TextStyle(
                          color: AppColors.text(
                            context,
                          ).withValues(alpha: 0.68),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                        ),
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
                    const SizedBox(height: 20),

                    // Save Button
                    SilverButton(
                      label: isEditing
                          ? (loc.isArabic ? 'حفظ التعديلات' : 'Save Changes')
                          : loc.tr('clinic_add_practitioner'),
                      icon: Icons.check,
                      isFullWidth: true,
                      height: 44,
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => modalErrorMessage = null);
                              if (!formKey.currentState!.validate()) return;

                              final data = <String, dynamic>{
                                'name_en': nameEnController.text.trim(),
                                'name_ar':
                                    nameArController.text.trim().isNotEmpty
                                    ? nameArController.text.trim()
                                    : nameEnController.text.trim(),
                                'title_en': 'Certified Practitioner',
                                'title_ar': 'ممارس طبي معتمد',
                                'speciality_en':
                                    specialtyEnController.text.trim().isNotEmpty
                                    ? specialtyEnController.text.trim()
                                    : 'Aesthetic Practitioner',
                                'speciality_ar':
                                    specialtyArController.text.trim().isNotEmpty
                                    ? specialtyArController.text.trim()
                                    : 'ممارس تجميلي معتمد',
                                'type': selectedType.value,
                                'bio_en': bioEnController.text.trim(),
                                'bio_ar': bioArController.text.trim(),
                                'status': existing?.status ?? 'active',
                              };
                              if (avatarPathChanged) {
                                data['avatar'] = avatarPath;
                              }

                              setModalState(() => isSubmitting = true);

                              try {
                                if (isEditing) {
                                  await ClinicPortalService()
                                      .updatePractitioner(existing.id, data);
                                } else {
                                  await ClinicPortalService()
                                      .createPractitioner(data);
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  showAppSnackBar(
                                    context,
                                    isEditing
                                        ? (loc.isArabic
                                              ? 'تم تحديث بيانات الطبيب بنجاح'
                                              : 'Practitioner updated successfully')
                                        : loc.tr('clinic_practitioner_saved'),
                                    type: AppSnackBarType.success,
                                  );
                                }
                              } catch (e) {
                                if (!ctx.mounted) return;
                                String cleanMsg;
                                if (e is ApiException) {
                                  cleanMsg = e.message;
                                } else {
                                  cleanMsg =
                                      ApiException.sanitizeRegulatoryCompliance(
                                        e
                                            .toString()
                                            .replaceFirst('Exception: ', '')
                                            .replaceFirst('ApiException: ', ''),
                                      );
                                }
                                setModalState(() {
                                  modalErrorMessage = cleanMsg;
                                  isSubmitting = false;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddServiceDialog(BuildContext context, LocaleService loc) {
    final formKey = GlobalKey<FormState>();
    final nameEnController = TextEditingController();
    final nameArController = TextEditingController();
    final priceController = TextEditingController(text: '750');
    final descEnController = TextEditingController();
    final descArController = TextEditingController();
    final clinicService = ClinicPortalService();
    if (clinicService.categories.isEmpty) {
      clinicService.getOrFetchCategories();
    }
    final categories = clinicService.categories;
    String? chosenCategoryId = categories.isNotEmpty
        ? categories.first.id
        : null;
    String? chosenCategoryLabel;
    final isDark = AppColors.isDark(context);

    String? modalErrorMessage;
    bool isSubmitting = false;

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
                      loc.tr('clinic_add_service'),
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

                    // Category Selector Dropdown (Live API categories)
                    PagedEntityField<CategoryModel>(
                      label: loc.isArabic ? 'التصنيف الطبي *' : 'Category *',
                      hint: loc.isArabic
                          ? 'ابحث عن التصنيف الطبي'
                          : 'Search medical categories',
                      value: chosenCategoryId,
                      valueLabel:
                          chosenCategoryLabel ??
                          categories
                              .where((c) => c.id == chosenCategoryId)
                              .map((c) => loc.isArabic ? c.nameAr : c.nameEn)
                              .firstOrNull ??
                          '',
                      keyOf: (c) => c.id,
                      labelOf: (c) => loc.isArabic ? c.nameAr : c.nameEn,
                      loader: (page, search) => ClinicCatalogRepository()
                          .getCategories(page: page, search: search),
                      validator: (v) => v == null
                          ? loc.tr('clinic_validation_required')
                          : null,
                      onChanged: (c) => setModalState(() {
                        chosenCategoryId = c?.id;
                        chosenCategoryLabel = c == null
                            ? null
                            : (loc.isArabic ? c.nameAr : c.nameEn);
                        modalErrorMessage = null;
                      }),
                    ),
                    const SizedBox(height: 10),

                    // Service Name EN & AR
                    LtrTextFormField(
                      controller: nameEnController,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
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
                      validator: (val) => (val == null || val.trim().isEmpty)
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
                      validator: (val) => (val == null || val.trim().isEmpty)
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
                        labelText: loc.tr('clinic_service_price'),
                        hintText: '750',
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
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? loc.tr('clinic_validation_required')
                          : null,
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
                        labelText: loc.isArabic
                            ? 'الوصف الطبي بالإنجليزية'
                            : 'Description (English)',
                        hintText: 'e.g. Deep cleansing and skin hydration...',
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
                        labelText: loc.isArabic
                            ? 'الوصف الطبي بالعربية'
                            : 'Description (Arabic)',
                        hintText: 'وصف للمزايا وشروط الجلسة...',
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
                    const SizedBox(height: 20),

                    // Save Button
                    SilverButton(
                      label: loc.tr('clinic_add_service'),
                      icon: Icons.check,
                      isFullWidth: true,
                      height: 44,
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
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
                                'description_en': descEnController.text.trim(),
                                'description_ar': descArController.text.trim(),
                                'price':
                                    double.tryParse(
                                      priceController.text.trim(),
                                    ) ??
                                    750.0,
                                'status': 'active',
                                'is_active': true,
                                'practitioners': <String>[],
                              };

                              setModalState(() {
                                modalErrorMessage = null;
                                isSubmitting = true;
                              });

                              try {
                                await clinicService.createTreatment(data);
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  showAppSnackBar(
                                    context,
                                    loc.tr('clinic_service_saved'),
                                    type: AppSnackBarType.success,
                                  );
                                }
                              } catch (e) {
                                if (!ctx.mounted) return;
                                String cleanMsg;
                                if (e is ApiException) {
                                  cleanMsg = e.message;
                                } else {
                                  cleanMsg =
                                      ApiException.sanitizeRegulatoryCompliance(
                                        e
                                            .toString()
                                            .replaceFirst('Exception: ', '')
                                            .replaceFirst('ApiException: ', ''),
                                      );
                                }
                                setModalState(() {
                                  modalErrorMessage = cleanMsg;
                                  isSubmitting = false;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showProductFormDialog(
    BuildContext context,
    LocaleService loc, {
    ProductModel? existing,
  }) {
    final formKey = GlobalKey<FormState>();
    final isEditing = existing != null;
    final nameEnController = TextEditingController(
      text: existing?.nameEn ?? '',
    );
    final nameArController = TextEditingController(
      text: existing?.nameAr ?? '',
    );
    final brandEnController = TextEditingController(
      text: existing?.brandNameEn ?? '',
    );
    final brandArController = TextEditingController(
      text: existing?.brandNameAr ?? '',
    );
    final sponsorController = TextEditingController(
      text: existing?.sponsorCompany ?? '',
    );
    final descEnController = TextEditingController(
      text: existing?.descriptionEn ?? '',
    );
    final descArController = TextEditingController(
      text: existing?.descriptionAr ?? '',
    );
    String? selectedProductImagePath = existing?.imageUrl;
    bool selectedProductImagePathChanged = false;
    bool isAvailable = existing?.isAvailable ?? true;
    final isDark = AppColors.isDark(context);

    String? modalErrorMessage;
    bool isSubmitting = false;

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
                                ? 'تعديل المنتج التجميلي'
                                : 'Edit Cosmetic Product')
                          : (loc.isArabic
                                ? 'إضافة منتج تجميلي (إعلان علامة تجارية)'
                                : 'Add Cosmetic Showcase Product'),
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
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                modalErrorMessage!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () =>
                                  setModalState(() => modalErrorMessage = null),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.redAccent,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Name EN (LTR required)
                    LtrTextFormField(
                      controller: nameEnController,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'اسم المنتج بالإنجليزية *'
                            : 'Product Name (English) *',
                        hintText: 'e.g. Hyaluronic Acid Serum',
                        prefixIcon: const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.accentChampagne,
                          size: 18,
                        ),
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
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? loc.tr('clinic_validation_required')
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Name AR
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
                        labelText: loc.isArabic
                            ? 'اسم المنتج بالعربية'
                            : 'Product Name (Arabic)',
                        hintText: 'مثال: سيروم حمض الهيالورونيك',
                        prefixIcon: const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.accentChampagne,
                          size: 18,
                        ),
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
                    const SizedBox(height: 12),

                    // Brand Name EN (LTR)
                    LtrTextFormField(
                      controller: brandEnController,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'اسم العلامة التجارية بالإنجليزية'
                            : 'Brand Name (English)',
                        hintText: 'e.g. SkinCeuticals, Obagi',
                        prefixIcon: const Icon(
                          Icons.verified_outlined,
                          color: AppColors.accentChampagne,
                          size: 18,
                        ),
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
                    const SizedBox(height: 12),

                    // Brand Name AR
                    TextFormField(
                      controller: brandArController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'اسم العلامة التجارية بالعربية'
                            : 'Brand Name (Arabic)',
                        hintText: 'مثال: سكين سوتيكالز',
                        prefixIcon: const Icon(
                          Icons.verified_outlined,
                          color: AppColors.accentChampagne,
                          size: 18,
                        ),
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
                    const SizedBox(height: 12),

                    // Sponsoring Company / Agency (LTR)
                    LtrTextFormField(
                      controller: sponsorController,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'الشركة / الجهة الراعية'
                            : 'Sponsoring Agency / Company',
                        hintText: 'e.g. Regional Cosmetics Distributor',
                        prefixIcon: const Icon(
                          Icons.business_outlined,
                          color: AppColors.accentChampagne,
                          size: 18,
                        ),
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
                    const SizedBox(height: 12),

                    // Description EN (LTR)
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
                        labelText: loc.isArabic
                            ? 'وصف المنتج بالإنجليزية'
                            : 'Description (English)',
                        hintText: 'Key benefits, active ingredients, usage...',
                        prefixIcon: const Icon(
                          Icons.notes_rounded,
                          color: AppColors.accentChampagne,
                          size: 18,
                        ),
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
                    const SizedBox(height: 12),

                    // Description AR
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
                        labelText: loc.isArabic
                            ? 'وصف المنتج بالعربية'
                            : 'Description (Arabic)',
                        hintText: 'الفوائد، المواد الفعالة وطريقة الاستخدام...',
                        prefixIcon: const Icon(
                          Icons.notes_rounded,
                          color: AppColors.accentChampagne,
                          size: 18,
                        ),
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
                    const SizedBox(height: 12),

                    // Product Image Picker (Camera & Gallery)
                    LuxuryImagePickerField(
                      label: loc.tr('clinic_product_image'),
                      initialUrl: existing?.imageUrl,
                      height: 130,
                      onImageSelected: (path) {
                        selectedProductImagePath = path;
                        selectedProductImagePathChanged = true;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Active Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.accentChampagne,
                      title: Text(
                        loc.isArabic
                            ? 'عرض المنتج في التطبيق'
                            : 'Show in App Directory',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.lightTextPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: isAvailable,
                      onChanged: (val) =>
                          setModalState(() => isAvailable = val),
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    SilverButton(
                      label: isEditing
                          ? (loc.isArabic ? 'حفظ التعديلات' : 'Save Changes')
                          : (loc.isArabic
                                ? 'إضافة المنتج للإعلان'
                                : 'Add to Showcase'),
                      icon: Icons.check,
                      isFullWidth: true,
                      height: 44,
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() {
                                modalErrorMessage = null;
                                isSubmitting = true;
                              });

                              final nameEn = nameEnController.text.trim();
                              final nameAr =
                                  nameArController.text.trim().isNotEmpty
                                  ? nameArController.text.trim()
                                  : nameEn;
                              final descEn = descEnController.text.trim();
                              final descAr =
                                  descArController.text.trim().isNotEmpty
                                  ? descArController.text.trim()
                                  : descEn;

                              final payload = <String, dynamic>{
                                'name_en': nameEn,
                                'name_ar': nameAr,
                                'description_en': descEn,
                                'description_ar': descAr,
                                'brand_name_en': brandEnController.text.trim(),
                                'brand_name_ar': brandArController.text.trim(),
                                'sponsor_company': sponsorController.text
                                    .trim(),
                                'is_active': isAvailable,
                                'status': existing?.status ?? 'active',
                              };
                              if (selectedProductImagePathChanged) {
                                payload['image'] = selectedProductImagePath;
                              }

                              try {
                                if (isEditing) {
                                  await ClinicPortalService().updateProduct(
                                    existing.id,
                                    payload,
                                  );
                                } else {
                                  await ClinicPortalService().createProduct(
                                    payload,
                                  );
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  showAppSnackBar(
                                    context,
                                    loc.tr('clinic_product_saved'),
                                    type: AppSnackBarType.success,
                                  );
                                }
                              } catch (e) {
                                if (!ctx.mounted) return;
                                String cleanMsg;
                                if (e is ApiException) {
                                  cleanMsg = e.message;
                                } else {
                                  cleanMsg =
                                      ApiException.sanitizeRegulatoryCompliance(
                                        e
                                            .toString()
                                            .replaceFirst('Exception: ', '')
                                            .replaceFirst('ApiException: ', ''),
                                      );
                                }
                                setModalState(() {
                                  modalErrorMessage = cleanMsg;
                                  isSubmitting = false;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showArticleFormDialog(
    BuildContext context,
    LocaleService loc, {
    ArticleModel? existing,
  }) {
    final formKey = GlobalKey<FormState>();
    final isEditing = existing != null;
    final titleEnController = TextEditingController(
      text: existing?.titleEn ?? '',
    );
    final titleArController = TextEditingController(
      text: existing?.titleAr ?? '',
    );
    final contentEnController = TextEditingController(
      text: existing?.contentEn ?? '',
    );
    final contentArController = TextEditingController(
      text: existing?.contentAr ?? '',
    );
    String? selectedArticleImagePath = existing?.coverImageUrl;
    bool selectedArticleImagePathChanged = false;
    bool isPublished = existing?.isPublished ?? true;

    final clinicService = ClinicPortalService();
    final practitioners = clinicService.clinicPractitioners;
    String? selectedDoctorId = existing?.authorDoctorId.isNotEmpty == true
        ? existing!.authorDoctorId
        : null;
    String? selectedDoctorLabel = existing?.authorDoctorNameEn;

    final isDark = AppColors.isDark(context);
    String? modalErrorMessage;
    bool isSubmitting = false;

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
                                ? 'تعديل المقال الطبي'
                                : 'Edit Medical Article')
                          : (loc.isArabic
                                ? 'كتابة ونشر مقال جديد'
                                : 'Write & Publish Article'),
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
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                modalErrorMessage!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () =>
                                  setModalState(() => modalErrorMessage = null),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.redAccent,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Title EN (LTR required)
                    LtrTextFormField(
                      controller: titleEnController,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'عنوان المقال بالإنجليزية *'
                            : 'Article Title (English) *',
                        hintText: 'e.g. Benefits of Hyaluronic Acid',
                        prefixIcon: const Icon(
                          Icons.article_outlined,
                          color: AppColors.accentChampagne,
                          size: 18,
                        ),
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
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? loc.tr('clinic_validation_required')
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Title AR
                    TextFormField(
                      controller: titleArController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'عنوان المقال بالعربية'
                            : 'Article Title (Arabic)',
                        hintText: 'مثال: فوائد حمض الهيالورونيك للبشرة',
                        prefixIcon: const Icon(
                          Icons.article_outlined,
                          color: AppColors.accentChampagne,
                          size: 18,
                        ),
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
                    const SizedBox(height: 12),

                    // Doctor Author Dropdown
                    ...[
                      PagedEntityField<PractitionerModel>(
                        label: loc.tr('clinic_article_doctor_author'),
                        hint: loc.isArabic
                            ? 'ابحث عن الممارس'
                            : 'Search practitioners',
                        value: selectedDoctorId,
                        valueLabel:
                            selectedDoctorLabel ??
                            practitioners
                                .where((p) => p.id == selectedDoctorId)
                                .map((p) => loc.isArabic ? p.nameAr : p.nameEn)
                                .firstOrNull ??
                            '',
                        clearLabel: loc.isArabic
                            ? 'باسم العيادة'
                            : 'On behalf of the clinic',
                        keyOf: (p) => p.id,
                        labelOf: (p) => loc.isArabic ? p.nameAr : p.nameEn,
                        loader: (page, search) => ClinicCatalogRepository()
                            .getPractitioners(page: page, search: search),
                        onChanged: (p) => setModalState(() {
                          selectedDoctorId = p?.id;
                          selectedDoctorLabel = p == null
                              ? null
                              : (loc.isArabic ? p.nameAr : p.nameEn);
                        }),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Content EN (LTR required)
                    LtrTextFormField(
                      controller: contentEnController,
                      maxLines: 4,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'محتوى المقال بالإنجليزية *'
                            : 'Article Content (English) *',
                        hintText: 'Write full medical article guidance...',
                        prefixIcon: const Icon(
                          Icons.notes_rounded,
                          color: AppColors.accentChampagne,
                          size: 18,
                        ),
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
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? loc.tr('clinic_validation_required')
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Content AR
                    TextFormField(
                      controller: contentArController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 4,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'محتوى المقال بالعربية'
                            : 'Article Content (Arabic)',
                        hintText: 'اكتب محتوى المقال والنصائح الطبية...',
                        prefixIcon: const Icon(
                          Icons.notes_rounded,
                          color: AppColors.accentChampagne,
                          size: 18,
                        ),
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
                    const SizedBox(height: 12),

                    // Cover Image Picker
                    LuxuryImagePickerField(
                      label: loc.tr('clinic_article_cover'),
                      initialUrl: existing?.coverImageUrl,
                      height: 140,
                      onImageSelected: (path) {
                        selectedArticleImagePath = path;
                        selectedArticleImagePathChanged = true;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Published Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.accentChampagne,
                      title: Text(
                        loc.isArabic
                            ? 'نشر المقال فوراً'
                            : 'Publish Immediately',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.lightTextPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: isPublished,
                      onChanged: (val) =>
                          setModalState(() => isPublished = val),
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    SilverButton(
                      label: isEditing
                          ? (loc.isArabic ? 'حفظ التعديلات' : 'Save Changes')
                          : (loc.isArabic
                                ? 'نشر / حفظ المقال'
                                : 'Save Article'),
                      icon: Icons.check,
                      isFullWidth: true,
                      height: 44,
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() {
                                modalErrorMessage = null;
                                isSubmitting = true;
                              });

                              final titleEn = titleEnController.text.trim();
                              final titleAr =
                                  titleArController.text.trim().isNotEmpty
                                  ? titleArController.text.trim()
                                  : titleEn;
                              final contentEn = contentEnController.text.trim();
                              final contentAr =
                                  contentArController.text.trim().isNotEmpty
                                  ? contentArController.text.trim()
                                  : contentEn;

                              final payload = <String, dynamic>{
                                'title_en': titleEn,
                                'title_ar': titleAr,
                                'content_en': contentEn,
                                'content_ar': contentAr,
                                'author_practitioner': selectedDoctorId,
                                'is_published': isPublished,
                                'status': existing?.status ?? 'active',
                              };
                              if (selectedArticleImagePathChanged) {
                                payload['cover_image'] =
                                    selectedArticleImagePath;
                              }

                              try {
                                if (isEditing) {
                                  await clinicService.updateArticle(
                                    existing.id,
                                    payload,
                                  );
                                } else {
                                  await clinicService.createArticle(payload);
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  showAppSnackBar(
                                    context,
                                    loc.tr('clinic_article_saved'),
                                    type: AppSnackBarType.success,
                                  );
                                }
                              } catch (e) {
                                if (!ctx.mounted) return;
                                String cleanMsg;
                                if (e is ApiException) {
                                  cleanMsg = e.message;
                                } else {
                                  cleanMsg =
                                      ApiException.sanitizeRegulatoryCompliance(
                                        e
                                            .toString()
                                            .replaceFirst('Exception: ', '')
                                            .replaceFirst('ApiException: ', ''),
                                      );
                                }
                                setModalState(() {
                                  modalErrorMessage = cleanMsg;
                                  isSubmitting = false;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditClinicProfileDialog(BuildContext context, LocaleService loc) {
    final clinicService = ClinicPortalService();
    final clinic = clinicService.activeClinic;
    final formKey = GlobalKey<FormState>();
    final nameArCtrl = TextEditingController(text: clinic.nameAr);
    final nameEnCtrl = TextEditingController(text: clinic.nameEn);
    final descArCtrl = TextEditingController(text: clinic.descriptionAr);
    final descEnCtrl = TextEditingController(text: clinic.descriptionEn);
    final addressArCtrl = TextEditingController(text: clinic.addressAr);
    final mapsUrlCtrl = TextEditingController(text: clinic.googleMapsUrl ?? '');
    final isDark = AppColors.isDark(context);
    String? logoPath;
    String? coverPath;
    bool logoChanged = false;
    bool coverChanged = false;
    String? modalErrorMessage;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: Form(
                key: formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      loc.isArabic
                          ? 'تعديل ملف العيادة'
                          : 'Edit Clinic Profile',
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
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

                    // Visual Branding (Logo & Cover Photo)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: LuxuryImagePickerField(
                            label: loc.isArabic
                                ? 'شعار العيادة'
                                : 'Clinic Logo',
                            initialUrl: clinic.logoUrl.isNotEmpty
                                ? clinic.logoUrl
                                : null,
                            height: 120,
                            onImageSelected: (path) {
                              logoPath = path;
                              logoChanged = true;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: LuxuryImagePickerField(
                            label: loc.isArabic ? 'صورة الغلاف' : 'Cover Photo',
                            initialUrl: clinic.coverImageUrl.isNotEmpty
                                ? clinic.coverImageUrl
                                : null,
                            height: 120,
                            onImageSelected: (path) {
                              coverPath = path;
                              coverChanged = true;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: nameArCtrl,
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'اسم العيادة (عربي)'
                            : 'Clinic Name (Arabic)',
                        hintText: 'مثال: عيادة جميرا للتجميل والليزر',
                        hintStyle: TextStyle(
                          color: AppColors.text(
                            context,
                          ).withValues(alpha: 0.68),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? loc.tr('clinic_validation_required')
                          : null,
                    ),
                    const SizedBox(height: 10),
                    LtrTextFormField(
                      controller: nameEnCtrl,
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'اسم العيادة (إنجليزي)'
                            : 'Clinic Name (English)',
                        hintText: 'e.g. Jumeirah Aesthetic & Laser Clinic',
                        hintStyle: TextStyle(
                          color: AppColors.text(
                            context,
                          ).withValues(alpha: 0.68),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: addressArCtrl,
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'العنوان' : 'Address',
                        hintText: loc.isArabic
                            ? 'مثال: جميرا 1، شارع شاطئ جميرا، دبي'
                            : 'e.g. Jumeirah 1, Jumeirah Beach Road, Dubai',
                        hintStyle: TextStyle(
                          color: AppColors.text(
                            context,
                          ).withValues(alpha: 0.68),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    LtrTextFormField(
                      controller: mapsUrlCtrl,
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'رابط خرائط جوجل'
                            : 'Google Maps URL',
                        hintText: 'https://maps.google.com/...',
                        hintStyle: TextStyle(
                          color: AppColors.text(
                            context,
                          ).withValues(alpha: 0.68),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descArCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'نبذة عن العيادة'
                            : 'Description (Arabic)',
                        hintText: loc.isArabic
                            ? 'اكتب نبذة تعريفية تبرز خبرات العيادة وأحدث التقنيات التجميلية المتوفرة...'
                            : 'Highlight your medical expertise, technologies, and patient care standards...',
                        hintStyle: TextStyle(
                          color: AppColors.text(
                            context,
                          ).withValues(alpha: 0.68),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    LtrTextFormField(
                      controller: descEnCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'نبذة عن العيادة (إنجليزي)'
                            : 'Description (English)',
                        hintText:
                            'Describe your clinic, medical expertise, and patient care.',
                      ),
                    ),
                    const SizedBox(height: 18),
                    SilverButton(
                      label: loc.isArabic ? 'حفظ التعديلات' : 'Save Changes',
                      icon: Icons.check_rounded,
                      isFullWidth: true,
                      height: 44,
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => modalErrorMessage = null);
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSubmitting = true);
                              try {
                                await clinicService.updateClinicProfile(
                                  nameAr: nameArCtrl.text.trim(),
                                  nameEn: nameEnCtrl.text.trim().isNotEmpty
                                      ? nameEnCtrl.text.trim()
                                      : nameArCtrl.text.trim(),
                                  descriptionAr: descArCtrl.text.trim(),
                                  descriptionEn: descEnCtrl.text.trim(),
                                  phone: clinic.mainPhone,
                                  whatsapp: clinic.whatsapp,
                                  addressAr: addressArCtrl.text.trim(),
                                  googleMapsUrl:
                                      mapsUrlCtrl.text.trim().isNotEmpty
                                      ? mapsUrlCtrl.text.trim()
                                      : null,
                                  logo: logoPath,
                                  coverImage: coverPath,
                                  clearLogo: logoChanged && logoPath == null,
                                  clearCoverImage:
                                      coverChanged && coverPath == null,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  showAppSnackBar(
                                    context,
                                    loc.isArabic
                                        ? 'تم تحديث ملف العيادة بنجاح'
                                        : 'Clinic profile updated successfully',
                                    type: AppSnackBarType.success,
                                  );
                                }
                              } catch (e) {
                                if (!ctx.mounted) return;
                                String cleanMsg;
                                if (e is ApiException) {
                                  cleanMsg = e.message;
                                } else {
                                  cleanMsg =
                                      ApiException.sanitizeRegulatoryCompliance(
                                        e
                                            .toString()
                                            .replaceFirst('Exception: ', '')
                                            .replaceFirst('ApiException: ', ''),
                                      );
                                }
                                setModalState(() {
                                  modalErrorMessage = cleanMsg;
                                  isSubmitting = false;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final themeService = ThemeService();
    final clinicService = ClinicPortalService();
    final isDark = AppColors.isDark(context);
    final clinic = clinicService.activeClinic;

    return ListenableBuilder(
      listenable: Listenable.merge([loc, themeService, clinicService]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Text(
              loc.tr('clinic_nav_profile'),
              style: AppTypography.screenTitle.copyWith(
                color: isDark
                    ? AppColors.silverPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Clinic Overview Card
              LuxuryCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (clinic.coverImageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: LuxuryImage(
                          imageUrl: clinic.coverImageUrl,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholderIcon: Icons.photo_library_outlined,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              LuxuryImage(
                                imageUrl: clinic.logoUrl,
                                width: 60,
                                height: 60,
                                borderRadius: BorderRadius.circular(12),
                                placeholderIcon: Icons.apartment_rounded,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.isArabic
                                          ? clinic.nameAr
                                          : clinic.nameEn,
                                      style: AppTypography.cardTitle.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? AppColors.silverPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${clinic.city} • ${loc.isArabic ? clinic.areaAr : clinic.areaEn}',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.mutedText(context),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TierBadge(tier: clinic.subscriptionTier),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: AppColors.accentChampagne,
                                ),
                                tooltip: loc.isArabic
                                    ? 'تعديل ملف العيادة'
                                    : 'Edit Clinic Profile',
                                onPressed: () =>
                                    _showEditClinicProfileDialog(context, loc),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Text(
                            loc.isArabic
                                ? clinic.descriptionAr
                                : clinic.descriptionEn,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.mutedText(context),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Google Maps Location Card
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.map_outlined,
                          color: AppColors.accentChampagne,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          loc.tr('clinic_maps_config'),
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.silverPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loc.isArabic ? clinic.addressAr : clinic.addressEn,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 12.5,
                        color: isDark
                            ? AppColors.silverPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SilverButton(
                      label: loc.tr('open_in_maps'),
                      icon: Icons.directions_outlined,
                      height: 38,
                      onPressed: () {
                        MapsLauncher.openDirections(
                          latitude: clinic.latitude,
                          longitude: clinic.longitude,
                          destinationTitle: loc.isArabic
                              ? clinic.nameAr
                              : clinic.nameEn,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Medical Staff Section
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.tr('clinic_team_title'),
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.silverPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                color: AppColors.silverPrimary,
                                size: 18,
                              ),
                              tooltip: loc.isArabic
                                  ? 'إدارة الكادر الطبي'
                                  : 'Manage Staff',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  LuxuryPageRoute(
                                    page: const ClinicPractitionersScreen(),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                color: AppColors.accentChampagne,
                                size: 20,
                              ),
                              tooltip: loc.tr('clinic_add_practitioner'),
                              onPressed: () =>
                                  _showAddPractitionerDialog(context, loc),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    BoundedCatalogPreview<PractitionerModel>(
                      items: () => clinicService.clinicPractitioners,
                      listenable: clinicService,
                      page: clinicService.collection('practitioners'),
                      itemBuilder: (context, p) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.network(
                                  p.avatarUrl,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 36,
                                    height: 36,
                                    color: isDark
                                        ? AppColors.cardSurfaceHover
                                        : AppColors.lightCardSurfaceHover,
                                    child: const Icon(
                                      Icons.person,
                                      size: 20,
                                      color: AppColors.accentChampagne,
                                    ),
                                  ),
                                  cacheWidth: computeSafeCacheWidth(
                                    context,
                                    400,
                                    null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.isArabic ? p.nameAr : p.nameEn,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: isDark
                                            ? AppColors.silverPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      loc.isArabic
                                          ? p.specialtyAr
                                          : p.specialtyEn,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.mutedText(context),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PractitionerBadge(type: p.type, showIcon: false),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: AppColors.silverPrimary,
                                ),
                                tooltip: loc.isArabic ? 'تعديل' : 'Edit',
                                onPressed: () => _showAddPractitionerDialog(
                                  context,
                                  loc,
                                  existing: p,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                  color: AppColors.errorRed,
                                ),
                                tooltip: loc.isArabic ? 'حذف' : 'Delete',
                                onPressed: () =>
                                    clinicService.deletePractitioner(p.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Treatments / Services Section
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.tr('clinic_services_title'),
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.silverPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                color: AppColors.silverPrimary,
                                size: 18,
                              ),
                              tooltip: loc.isArabic
                                  ? 'إدارة الخدمات والعلاجات'
                                  : 'Manage Treatments',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  LuxuryPageRoute(
                                    page: const ClinicTreatmentsScreen(),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                color: AppColors.accentChampagne,
                                size: 20,
                              ),
                              tooltip: loc.tr('clinic_add_service'),
                              onPressed: () =>
                                  _showAddServiceDialog(context, loc),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    BoundedCatalogPreview<TreatmentModel>(
                      items: () => clinicService.clinicTreatments,
                      listenable: clinicService,
                      page: clinicService.collection('treatments'),
                      itemBuilder: (context, t) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.spa_outlined,
                                size: 16,
                                color: AppColors.accentChampagne,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  loc.isArabic ? t.nameAr : t.nameEn,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                    color: isDark
                                        ? AppColors.silverPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                loc.isArabic
                                    ? t.durationText
                                    : (t.durationTextEn ?? t.durationText),
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.goldText(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                  color: AppColors.errorRed,
                                ),
                                tooltip: loc.isArabic ? 'حذف' : 'Delete',
                                onPressed: () =>
                                    clinicService.deleteTreatment(t.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            loc.tr('clinic_nav_offers'),
                            style: AppTypography.cardTitle.copyWith(
                              color: AppColors.text(context),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          tooltip: loc.tr('clinic_btn_add_offer'),
                          onPressed: () => showClinicOfferEditor(context, loc),
                        ),
                      ],
                    ),
                    if (clinicService.clinicOffers.isEmpty)
                      Text(
                        loc.tr('clinic_no_offers'),
                        style: TextStyle(color: AppColors.subtext(context)),
                      ),
                    BoundedCatalogPreview<OfferModel>(
                      items: () => clinicService.clinicOffers,
                      listenable: clinicService,
                      page: clinicService.collection('offers'),
                      itemBuilder: (context, offer) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          loc.isArabic ? offer.titleAr : offer.titleEn,
                          style: TextStyle(color: AppColors.text(context)),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: loc.isArabic ? 'تعديل العرض' : 'Edit Offer',
                          onPressed: () => showClinicOfferEditor(
                            context,
                            loc,
                            existing: offer,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Products Section
              LuxuryCard(
                key: _productsSectionKey,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.tr('clinic_manage_products'),
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.silverPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            color: AppColors.accentChampagne,
                            size: 20,
                          ),
                          tooltip: loc.tr('clinic_add_product'),
                          onPressed: () => _showProductFormDialog(context, loc),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (clinicService.clinicProducts.isEmpty)
                      Text(
                        loc.tr('product_empty'),
                        style: TextStyle(
                          color: AppColors.mutedText(context),
                          fontSize: 12,
                        ),
                      )
                    else
                      BoundedCatalogPreview<ProductModel>(
                        items: () => clinicService.clinicProducts,
                        listenable: clinicService,
                        page: clinicService.collection('products'),
                        itemBuilder: (context, p) {
                          final catLabel = loc.isArabic
                              ? p.categoryAr
                              : p.categoryEn;
                          final brandLabel = loc.isArabic
                              ? (p.brandNameAr?.isNotEmpty == true
                                    ? p.brandNameAr!
                                    : (p.brandNameEn?.isNotEmpty == true
                                          ? p.brandNameEn!
                                          : (p.sponsorCompany?.isNotEmpty ==
                                                    true
                                                ? p.sponsorCompany!
                                                : (catLabel.isNotEmpty
                                                      ? catLabel
                                                      : 'إعلان علامة تجارية'))))
                              : (p.brandNameEn?.isNotEmpty == true
                                    ? p.brandNameEn!
                                    : (p.brandNameAr?.isNotEmpty == true
                                          ? p.brandNameAr!
                                          : (p.sponsorCompany?.isNotEmpty ==
                                                    true
                                                ? p.sponsorCompany!
                                                : (catLabel.isNotEmpty
                                                      ? catLabel
                                                      : 'Brand Showcase'))));
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    p.imageUrl,
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 38,
                                      height: 38,
                                      color: isDark
                                          ? AppColors.cardSurfaceHover
                                          : AppColors.lightCardSurfaceHover,
                                      child: const Icon(
                                        Icons.shopping_bag_outlined,
                                        color: AppColors.accentChampagne,
                                        size: 18,
                                      ),
                                    ),
                                    cacheWidth: computeSafeCacheWidth(
                                      context,
                                      400,
                                      null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.isArabic ? p.nameAr : p.nameEn,
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5,
                                              color: isDark
                                                  ? AppColors.silverPrimary
                                                  : AppColors.lightTextPrimary,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        brandLabel,
                                        style: TextStyle(
                                          color: AppColors.goldText(context),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 17,
                                    color: AppColors.silverSecondary,
                                  ),
                                  tooltip: loc.isArabic ? 'تعديل' : 'Edit',
                                  onPressed: () => _showProductFormDialog(
                                    context,
                                    loc,
                                    existing: p,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    p.isAvailable
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    size: 18,
                                    color: p.isAvailable
                                        ? const Color(0xFF10B981)
                                        : Colors.redAccent,
                                  ),
                                  tooltip: loc.tr(
                                    'clinic_product_toggle_avail',
                                  ),
                                  onPressed: () async {
                                    try {
                                      await clinicService
                                          .toggleProductAvailability(p.id);
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
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () async {
                                    try {
                                      await clinicService.deleteProduct(p.id);
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
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Articles Section
              LuxuryCard(
                key: _articlesSectionKey,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.tr('clinic_manage_articles'),
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.silverPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            color: AppColors.accentChampagne,
                            size: 20,
                          ),
                          tooltip: loc.tr('clinic_add_article'),
                          onPressed: () => _showArticleFormDialog(context, loc),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (clinicService.clinicArticles.isEmpty)
                      Text(
                        loc.tr('article_empty'),
                        style: TextStyle(
                          color: AppColors.mutedText(context),
                          fontSize: 12,
                        ),
                      )
                    else
                      BoundedCatalogPreview<ArticleModel>(
                        items: () => clinicService.clinicArticles,
                        listenable: clinicService,
                        page: clinicService.collection('articles'),
                        itemBuilder: (context, art) {
                          final authorName = loc.isArabic
                              ? art.authorDoctorNameAr
                              : art.authorDoctorNameEn;
                          final authorSubtitle = authorName.isNotEmpty
                              ? '${loc.tr("article_author_by")}: $authorName'
                              : (loc.isArabic ? clinic.nameAr : clinic.nameEn);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    art.coverImageUrl,
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 38,
                                      height: 38,
                                      color: isDark
                                          ? AppColors.cardSurfaceHover
                                          : AppColors.lightCardSurfaceHover,
                                      child: const Icon(
                                        Icons.article_outlined,
                                        color: AppColors.accentChampagne,
                                        size: 18,
                                      ),
                                    ),
                                    cacheWidth: computeSafeCacheWidth(
                                      context,
                                      400,
                                      null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.isArabic
                                            ? art.titleAr
                                            : art.titleEn,
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5,
                                              color: isDark
                                                  ? AppColors.silverPrimary
                                                  : AppColors.lightTextPrimary,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        authorSubtitle,
                                        style: TextStyle(
                                          color: AppColors.mutedText(context),
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 17,
                                    color: AppColors.silverSecondary,
                                  ),
                                  tooltip: loc.isArabic ? 'تعديل' : 'Edit',
                                  onPressed: () => _showArticleFormDialog(
                                    context,
                                    loc,
                                    existing: art,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    art.isPublished
                                        ? Icons.public_rounded
                                        : Icons.public_off_rounded,
                                    size: 18,
                                    color: art.isPublished
                                        ? const Color(0xFF10B981)
                                        : Colors.redAccent,
                                  ),
                                  tooltip: art.isPublished
                                      ? (loc.isArabic ? 'منشور' : 'Published')
                                      : (loc.isArabic ? 'مسودة' : 'Draft'),
                                  onPressed: () async {
                                    try {
                                      await clinicService.toggleArticlePublish(
                                        art.id,
                                      );
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
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () async {
                                    try {
                                      await clinicService.deleteArticle(art.id);
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
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Theme Switcher Tile
              LuxuryCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      themeService.isDarkMode
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color: AppColors.accentChampagne,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.tr('theme_title'),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.silverPrimary
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DropdownButton<ThemeMode>(
                      value: themeService.themeMode,
                      dropdownColor: isDark
                          ? AppColors.cardSurface
                          : AppColors.lightCardSurface,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text(
                            loc.tr('theme_dark'),
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text(
                            loc.tr('theme_light'),
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text(
                            loc.tr('theme_system'),
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) themeService.setThemeMode(mode);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Language Switcher Tile
              LuxuryCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      color: AppColors.accentChampagne,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.tr('app_language'),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.silverPrimary
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => loc.toggleLanguage(),
                      child: Text(
                        loc.tr('switch_language'),
                        style: TextStyle(
                          color: AppColors.goldText(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Logout Clinic Portal Button
              SilverButton(
                label: loc.tr('clinic_logout'),
                icon: Icons.logout_rounded,
                isFullWidth: true,
                height: 46,
                onPressed: () async {
                  await AuthRepository().logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}
