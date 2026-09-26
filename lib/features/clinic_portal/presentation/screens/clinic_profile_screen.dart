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
import 'clinic_practitioners_screen.dart';
import 'clinic_treatments_screen.dart';

/// Clinic Tab 4: Clinic Profile, Google Maps Linking, Medical Team & Services Manager
class ClinicProfileScreen extends StatelessWidget {
  const ClinicProfileScreen({super.key});

  void _showAddPractitionerDialog(BuildContext context, LocaleService loc) {
    final formKey = GlobalKey<FormState>();
    final nameEnController = TextEditingController();
    final nameArController = TextEditingController();
    final specialtyEnController = TextEditingController();
    final specialtyArController = TextEditingController();
    final bioEnController = TextEditingController();
    final bioArController = TextEditingController();
    var selectedType = PractitionerType.doctor;
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
                      loc.tr('clinic_add_practitioner'),
                      style: AppTypography.cardTitle.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Role / Type Dropdown
                    DropdownButtonFormField<PractitionerType>(
                      initialValue: selectedType,
                      dropdownColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'نوع الممارس' : 'Practitioner Type',
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
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
                          child: Text(label, style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
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
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'الاسم بالإنجليزية *' : 'Full Name (English) *',
                        hintText: 'e.g. Dr. Sarah Al Mansoori',
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: nameArController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'الاسم بالعربية *' : 'Full Name (Arabic) *',
                        hintText: 'مثال: د. سارة المنصوري',
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                    ),
                    const SizedBox(height: 10),

                    // Specialty EN & AR
                    LtrTextFormField(
                      controller: specialtyEnController,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'التخصص بالإنجليزية' : 'Specialty (English)',
                        hintText: 'e.g. Aesthetic Dermatology',
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
                      controller: specialtyArController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'التخصص بالعربية' : 'Specialty (Arabic)',
                        hintText: 'مثال: جلدية وتجميل',
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    const SizedBox(height: 10),

                    // Short Professional Bio EN & AR
                    LtrTextFormField(
                      controller: bioEnController,
                      maxLines: 2,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'نبذة مهنية بالإنجليزية' : 'Bio (English)',
                        hintText: 'Brief clinical biography...',
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
                      controller: bioArController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'نبذة مهنية بالعربية' : 'Bio (Arabic)',
                        hintText: 'نبذة عن الخبرات والشهادات التخصصية...',
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SilverButton(
                      label: loc.tr('clinic_add_practitioner'),
                      icon: Icons.check,
                      isFullWidth: true,
                      height: 44,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        final data = <String, dynamic>{
                          'name_en': nameEnController.text.trim(),
                          'name_ar': nameArController.text.trim().isNotEmpty
                              ? nameArController.text.trim()
                              : nameEnController.text.trim(),
                          'title_en': 'Certified Practitioner',
                          'title_ar': 'ممارس طبي معتمد',
                          'speciality_en': specialtyEnController.text.trim().isNotEmpty
                              ? specialtyEnController.text.trim()
                              : 'Aesthetic Practitioner',
                          'speciality_ar': specialtyArController.text.trim().isNotEmpty
                              ? specialtyArController.text.trim()
                              : 'ممارس تجميلي معتمد',
                          'type': selectedType.value,
                          'bio_en': bioEnController.text.trim(),
                          'bio_ar': bioArController.text.trim(),
                          'status': 'active',
                        };

                        try {
                          await ClinicPortalService().createPractitioner(data);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            showAppSnackBar(
                              context,
                              loc.tr('clinic_practitioner_saved'),
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

    String? chosenCategoryId = clinicService.categories.isNotEmpty ? clinicService.categories.first.id : null;
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
                      loc.tr('clinic_add_service'),
                      style: AppTypography.cardTitle.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category Selector Dropdown (Live API categories)
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

                    // Service Name EN & AR
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
                      validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
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
                      validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                    ),
                    const SizedBox(height: 10),

                    // Price (AED)
                    LtrTextFormField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.tr('clinic_service_price'),
                        hintText: '750',
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                    ),
                    const SizedBox(height: 10),

                    // Description EN & AR
                    LtrTextFormField(
                      controller: descEnController,
                      maxLines: 2,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'الوصف الطبي بالإنجليزية' : 'Description (English)',
                        hintText: 'e.g. Deep cleansing and skin hydration...',
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
                        hintText: 'وصف للمزايا وشروط الجلسة...',
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
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
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        if (chosenCategoryId == null && clinicService.categories.isNotEmpty) {
                          chosenCategoryId = clinicService.categories.first.id;
                        }

                        final data = <String, dynamic>{
                          'category': ?chosenCategoryId,
                          'name_en': nameEnController.text.trim(),
                          'name_ar': nameArController.text.trim().isNotEmpty
                              ? nameArController.text.trim()
                              : nameEnController.text.trim(),
                          'description_en': descEnController.text.trim(),
                          'description_ar': descArController.text.trim(),
                          'price': double.tryParse(priceController.text.trim()) ?? 750.0,
                          'status': 'active',
                          'is_active': true,
                        };

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
                          if (context.mounted) {
                            showAppSnackBar(context, e.toString(), type: AppSnackBarType.error);
                          }
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
    final nameEnController = TextEditingController(text: existing?.nameEn ?? '');
    final nameArController = TextEditingController(text: existing?.nameAr ?? '');
    final priceController = TextEditingController(
      text: existing != null && existing.price > 0
          ? existing.price.toStringAsFixed(0)
          : '',
    );
    final descEnController = TextEditingController(text: existing?.descriptionEn ?? '');
    final descArController = TextEditingController(text: existing?.descriptionAr ?? '');
    final imageController = TextEditingController(text: existing?.imageUrl ?? '');
    bool isAvailable = existing?.isAvailable ?? true;
    final isDark = AppColors.isDark(context);

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
                      isEditing
                          ? (loc.isArabic ? 'تعديل المنتج' : 'Edit Product')
                          : loc.tr('clinic_add_product'),
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Name EN (LTR required)
                    LtrTextFormField(
                      controller: nameEnController,
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'اسم المنتج بالإنجليزية *' : 'Product Name (English) *',
                        hintText: 'e.g. Hyaluronic Acid Serum',
                        prefixIcon: const Icon(Icons.shopping_bag_outlined, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'اسم المنتج بالعربية' : 'Product Name (Arabic)',
                        hintText: 'مثال: سيروم حمض الهيالورونيك',
                        prefixIcon: const Icon(Icons.shopping_bag_outlined, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Price (AED)
                    LtrTextFormField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: '${loc.tr("clinic_product_price")} *',
                        hintText: 'e.g. 250',
                        prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return loc.tr('clinic_validation_required');
                        }
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null || parsed < 0) {
                          return loc.isArabic ? 'أدخل رقماً صحيحاً' : 'Invalid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Description EN (LTR)
                    LtrTextFormField(
                      controller: descEnController,
                      maxLines: 2,
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'وصف المنتج بالإنجليزية' : 'Description (English)',
                        hintText: 'Key ingredients, usage instructions...',
                        prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description AR
                    TextFormField(
                      controller: descArController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'وصف المنتج بالعربية' : 'Description (Arabic)',
                        hintText: 'المكونات وطريقة الاستخدام...',
                        prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Image URL (LTR)
                    LtrTextFormField(
                      controller: imageController,
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.tr('clinic_product_image'),
                        hintText: 'https://...',
                        prefixIcon: const Icon(Icons.image_outlined, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Active Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.accentChampagne,
                      title: Text(
                        loc.isArabic ? 'متوفر للاستفسار' : 'Available for Inquiry',
                        style: TextStyle(color: AppColors.text(ctx), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      value: isAvailable,
                      onChanged: (val) => setModalState(() => isAvailable = val),
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    SilverButton(
                      label: isEditing
                          ? (loc.isArabic ? 'حفظ التعديلات' : 'Save Changes')
                          : loc.tr('clinic_add_product'),
                      icon: Icons.check,
                      isFullWidth: true,
                      height: 44,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final nameEn = nameEnController.text.trim();
                        final nameAr = nameArController.text.trim().isNotEmpty
                            ? nameArController.text.trim()
                            : nameEn;
                        final descEn = descEnController.text.trim();
                        final descAr = descArController.text.trim().isNotEmpty
                            ? descArController.text.trim()
                            : descEn;
                        final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                        final image = imageController.text.trim();

                        final payload = <String, dynamic>{
                          'name_en': nameEn,
                          'name_ar': nameAr,
                          'description_en': descEn,
                          'description_ar': descAr,
                          'price': price.toStringAsFixed(2),
                          'is_active': isAvailable,
                          'status': existing?.status ?? 'active',
                        };
                        if (image.isNotEmpty) {
                          payload['image'] = image;
                        }

                        try {
                          if (isEditing) {
                            await ClinicPortalService().updateProduct(existing.id, payload);
                          } else {
                            await ClinicPortalService().createProduct(payload);
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
                          if (context.mounted) {
                            showAppSnackBar(context, e.toString(), type: AppSnackBarType.error);
                          }
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
    final titleEnController = TextEditingController(text: existing?.titleEn ?? '');
    final titleArController = TextEditingController(text: existing?.titleAr ?? '');
    final contentEnController = TextEditingController(text: existing?.contentEn ?? '');
    final contentArController = TextEditingController(text: existing?.contentAr ?? '');
    final imageController = TextEditingController(text: existing?.coverImageUrl ?? '');
    bool isPublished = existing?.isPublished ?? true;

    final clinicService = ClinicPortalService();
    final practitioners = clinicService.clinicPractitioners;
    String? selectedDoctorId = existing?.authorDoctorId.isNotEmpty == true
        ? existing!.authorDoctorId
        : (practitioners.isNotEmpty ? practitioners.first.id : null);
    if (selectedDoctorId != null && !practitioners.any((p) => p.id == selectedDoctorId)) {
      selectedDoctorId = practitioners.isNotEmpty ? practitioners.first.id : null;
    }

    final isDark = AppColors.isDark(context);

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
                      isEditing
                          ? (loc.isArabic ? 'تعديل المقال الطبي' : 'Edit Medical Article')
                          : loc.tr('clinic_add_article'),
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title EN (LTR required)
                    LtrTextFormField(
                      controller: titleEnController,
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'عنوان المقال بالإنجليزية *' : 'Article Title (English) *',
                        hintText: 'e.g. Benefits of Hyaluronic Acid',
                        prefixIcon: const Icon(Icons.article_outlined, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'عنوان المقال بالعربية' : 'Article Title (Arabic)',
                        hintText: 'مثال: فوائد حمض الهيالورونيك للبشرة',
                        prefixIcon: const Icon(Icons.article_outlined, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Doctor Author Dropdown
                    if (practitioners.isNotEmpty) ...[
                      DropdownButtonFormField<String?>(
                        initialValue: selectedDoctorId,
                        dropdownColor: AppColors.surface(ctx),
                        style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                        decoration: InputDecoration(
                          labelText: loc.tr('clinic_article_doctor_author'),
                          prefixIcon: const Icon(Icons.person_rounded, color: AppColors.accentChampagne, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(loc.isArabic ? 'بدون تحديد طبيب (باسم العيادة)' : 'No specific doctor (Clinic)'),
                          ),
                          ...practitioners.map((doc) {
                            return DropdownMenuItem<String?>(
                              value: doc.id,
                              child: Text(loc.isArabic ? doc.nameAr : doc.nameEn),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setModalState(() => selectedDoctorId = val);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Content EN (LTR required)
                    LtrTextFormField(
                      controller: contentEnController,
                      maxLines: 4,
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'محتوى المقال بالإنجليزية *' : 'Article Content (English) *',
                        hintText: 'Write full medical article guidance...',
                        prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'محتوى المقال بالعربية' : 'Article Content (Arabic)',
                        hintText: 'اكتب محتوى المقال والنصائح الطبية...',
                        prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cover Image URL (LTR)
                    LtrTextFormField(
                      controller: imageController,
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.tr('clinic_article_cover'),
                        hintText: 'https://...',
                        prefixIcon: const Icon(Icons.image_outlined, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Published Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.accentChampagne,
                      title: Text(
                        loc.isArabic ? 'نشر المقال فوراً' : 'Publish Immediately',
                        style: TextStyle(color: AppColors.text(ctx), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      value: isPublished,
                      onChanged: (val) => setModalState(() => isPublished = val),
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    SilverButton(
                      label: isEditing
                          ? (loc.isArabic ? 'حفظ التعديلات' : 'Save Changes')
                          : loc.tr('clinic_add_article'),
                      icon: Icons.check,
                      isFullWidth: true,
                      height: 44,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final titleEn = titleEnController.text.trim();
                        final titleAr = titleArController.text.trim().isNotEmpty
                            ? titleArController.text.trim()
                            : titleEn;
                        final contentEn = contentEnController.text.trim();
                        final contentAr = contentArController.text.trim().isNotEmpty
                            ? contentArController.text.trim()
                            : contentEn;
                        final coverImage = imageController.text.trim();

                        final payload = <String, dynamic>{
                          'title_en': titleEn,
                          'title_ar': titleAr,
                          'content_en': contentEn,
                          'content_ar': contentAr,
                          'author_practitioner': selectedDoctorId,
                          'is_published': isPublished,
                          'status': existing?.status ?? 'active',
                        };
                        if (coverImage.isNotEmpty) {
                          payload['cover_image'] = coverImage;
                        }

                        try {
                          if (isEditing) {
                            await clinicService.updateArticle(existing.id, payload);
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
                          if (context.mounted) {
                            showAppSnackBar(context, e.toString(), type: AppSnackBarType.error);
                          }
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
    final phoneCtrl = TextEditingController(text: clinic.mainPhone);
    final whatsappCtrl = TextEditingController(text: clinic.whatsapp);
    final addressArCtrl = TextEditingController(text: clinic.addressAr);
    final mapsUrlCtrl = TextEditingController(text: clinic.googleMapsUrl ?? '');
    final isDark = AppColors.isDark(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
                  loc.isArabic ? 'تعديل ملف العيادة' : 'Edit Clinic Profile',
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: nameArCtrl,
                  decoration: InputDecoration(labelText: loc.isArabic ? 'اسم العيادة (عربي)' : 'Clinic Name (Arabic)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                ),
                const SizedBox(height: 10),
                LtrTextFormField(
                  controller: nameEnCtrl,
                  decoration: InputDecoration(labelText: loc.isArabic ? 'اسم العيادة (إنجليزي)' : 'Clinic Name (English)'),
                ),
                const SizedBox(height: 10),
                LtrTextFormField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(labelText: loc.isArabic ? 'رقم الهاتف' : 'Phone Number'),
                ),
                const SizedBox(height: 10),
                LtrTextFormField(
                  controller: whatsappCtrl,
                  decoration: InputDecoration(labelText: loc.isArabic ? 'رقم الواتساب' : 'WhatsApp Number'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: addressArCtrl,
                  decoration: InputDecoration(labelText: loc.isArabic ? 'العنوان' : 'Address'),
                ),
                const SizedBox(height: 10),
                LtrTextFormField(
                  controller: mapsUrlCtrl,
                  decoration: InputDecoration(labelText: loc.isArabic ? 'رابط خرائط جوجل' : 'Google Maps URL'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: descArCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: loc.isArabic ? 'نبذة عن العيادة' : 'Description (Arabic)'),
                ),
                const SizedBox(height: 18),
                SilverButton(
                  label: loc.isArabic ? 'حفظ التعديلات' : 'Save Changes',
                  icon: Icons.check_rounded,
                  isFullWidth: true,
                  height: 44,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await clinicService.updateClinicProfile(
                        nameAr: nameArCtrl.text.trim(),
                        nameEn: nameEnCtrl.text.trim().isNotEmpty ? nameEnCtrl.text.trim() : nameArCtrl.text.trim(),
                        descriptionAr: descArCtrl.text.trim(),
                        descriptionEn: descEnCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        whatsapp: whatsappCtrl.text.trim(),
                        addressAr: addressArCtrl.text.trim(),
                        googleMapsUrl: mapsUrlCtrl.text.trim().isNotEmpty ? mapsUrlCtrl.text.trim() : null,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        showAppSnackBar(
                          context,
                          loc.isArabic ? 'تم تحديث ملف العيادة بنجاح' : 'Clinic profile updated successfully',
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
                const SizedBox(height: 20),
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
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Clinic Overview Card
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            clinic.coverImageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 60,
                              height: 60,
                              color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                              child: const Icon(Icons.apartment_rounded, color: AppColors.accentChampagne),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.isArabic ? clinic.nameAr : clinic.nameEn,
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${clinic.city} • ${loc.isArabic ? clinic.areaAr : clinic.areaEn}',
                                style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                              ),
                              const SizedBox(height: 6),
                              TierBadge(tier: clinic.subscriptionTier),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.accentChampagne),
                          tooltip: loc.isArabic ? 'تعديل ملف العيادة' : 'Edit Clinic Profile',
                          onPressed: () => _showEditClinicProfileDialog(context, loc),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      loc.isArabic ? clinic.descriptionAr : clinic.descriptionEn,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.mutedText(context),
                        fontSize: 12,
                        height: 1.5,
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
                        const Icon(Icons.map_outlined, color: AppColors.accentChampagne, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          loc.tr('clinic_maps_config'),
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loc.isArabic ? clinic.addressAr : clinic.addressEn,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 12.5,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
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
                          destinationTitle: loc.isArabic ? clinic.nameAr : clinic.nameEn,
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
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.open_in_new_rounded, color: AppColors.silverPrimary, size: 18),
                              tooltip: loc.isArabic ? 'إدارة الكادر الطبي' : 'Manage Staff',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  LuxuryPageRoute(page: const ClinicPractitionersScreen()),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentChampagne, size: 20),
                              tooltip: loc.tr('clinic_add_practitioner'),
                              onPressed: () => _showAddPractitionerDialog(context, loc),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...clinicService.clinicPractitioners.map((p) {
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
                                  color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                                  child: const Icon(Icons.person, size: 20, color: AppColors.accentChampagne),
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
                                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    loc.isArabic ? p.specialtyAr : p.specialtyEn,
                                    style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            PractitionerBadge(type: p.type, showIcon: false),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.errorRed),
                              tooltip: loc.isArabic ? 'حذف' : 'Delete',
                              onPressed: () => clinicService.deletePractitioner(p.id),
                            ),
                          ],
                        ),
                      );
                    }),
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
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.open_in_new_rounded, color: AppColors.silverPrimary, size: 18),
                              tooltip: loc.isArabic ? 'إدارة الخدمات والعلاجات' : 'Manage Treatments',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  LuxuryPageRoute(page: const ClinicTreatmentsScreen()),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentChampagne, size: 20),
                              tooltip: loc.tr('clinic_add_service'),
                              onPressed: () => _showAddServiceDialog(context, loc),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...clinicService.clinicTreatments.map((t) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.spa_outlined, size: 16, color: AppColors.accentChampagne),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                loc.isArabic ? t.nameAr : t.nameEn,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                            Text(
                              loc.isArabic ? t.durationText : (t.durationTextEn ?? t.durationText),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.accentChampagne,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.errorRed),
                              tooltip: loc.isArabic ? 'حذف' : 'Delete',
                              onPressed: () => clinicService.deleteTreatment(t.id),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Products Section
              LuxuryCard(
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
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentChampagne, size: 20),
                          tooltip: loc.tr('clinic_add_product'),
                          onPressed: () => _showProductFormDialog(context, loc),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (clinicService.clinicProducts.isEmpty)
                      Text(
                        loc.tr('product_empty'),
                        style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                      )
                    else
                      ...clinicService.clinicProducts.map((p) {
                        final catLabel = loc.isArabic ? p.categoryAr : p.categoryEn;
                        final priceLine = catLabel.isNotEmpty
                            ? '${p.price.toInt()} ${loc.tr("currency_aed")} • $catLabel'
                            : '${p.price.toInt()} ${loc.tr("currency_aed")}';
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
                                    color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                                    child: const Icon(Icons.shopping_bag_outlined, color: AppColors.accentChampagne, size: 18),
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
                                        fontSize: 12.5,
                                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      priceLine,
                                      style: const TextStyle(color: AppColors.accentChampagne, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 17, color: AppColors.silverSecondary),
                                tooltip: loc.isArabic ? 'تعديل' : 'Edit',
                                onPressed: () => _showProductFormDialog(context, loc, existing: p),
                              ),
                              IconButton(
                                icon: Icon(
                                  p.isAvailable ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                  size: 18,
                                  color: p.isAvailable ? const Color(0xFF10B981) : Colors.redAccent,
                                ),
                                tooltip: loc.tr('clinic_product_toggle_avail'),
                                onPressed: () async {
                                  try {
                                    await clinicService.toggleProductAvailability(p.id);
                                  } catch (e) {
                                    if (context.mounted) {
                                      showAppSnackBar(context, e.toString(), type: AppSnackBarType.error);
                                    }
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                onPressed: () async {
                                  try {
                                    await clinicService.deleteProduct(p.id);
                                  } catch (e) {
                                    if (context.mounted) {
                                      showAppSnackBar(context, e.toString(), type: AppSnackBarType.error);
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Articles Section
              LuxuryCard(
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
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentChampagne, size: 20),
                          tooltip: loc.tr('clinic_add_article'),
                          onPressed: () => _showArticleFormDialog(context, loc),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (clinicService.clinicArticles.isEmpty)
                      Text(
                        loc.tr('article_empty'),
                        style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                      )
                    else
                      ...clinicService.clinicArticles.map((art) {
                        final authorName = loc.isArabic ? art.authorDoctorNameAr : art.authorDoctorNameEn;
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
                                    color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                                    child: const Icon(Icons.article_outlined, color: AppColors.accentChampagne, size: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.isArabic ? art.titleAr : art.titleEn,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      authorSubtitle,
                                      style: TextStyle(color: AppColors.mutedText(context), fontSize: 10.5),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 17, color: AppColors.silverSecondary),
                                tooltip: loc.isArabic ? 'تعديل' : 'Edit',
                                onPressed: () => _showArticleFormDialog(context, loc, existing: art),
                              ),
                              IconButton(
                                icon: Icon(
                                  art.isPublished ? Icons.public_rounded : Icons.public_off_rounded,
                                  size: 18,
                                  color: art.isPublished ? const Color(0xFF10B981) : Colors.redAccent,
                                ),
                                tooltip: art.isPublished ? (loc.isArabic ? 'منشور' : 'Published') : (loc.isArabic ? 'مسودة' : 'Draft'),
                                onPressed: () async {
                                  try {
                                    await clinicService.toggleArticlePublish(art.id);
                                  } catch (e) {
                                    if (context.mounted) {
                                      showAppSnackBar(context, e.toString(), type: AppSnackBarType.error);
                                    }
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                onPressed: () async {
                                  try {
                                    await clinicService.deleteArticle(art.id);
                                  } catch (e) {
                                    if (context.mounted) {
                                      showAppSnackBar(context, e.toString(), type: AppSnackBarType.error);
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      }),
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
                      themeService.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                      color: AppColors.accentChampagne,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.tr('theme_title'),
                        style: TextStyle(
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DropdownButton<ThemeMode>(
                      value: themeService.themeMode,
                      dropdownColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text(loc.tr('theme_dark'), style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text(loc.tr('theme_light'), style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text(loc.tr('theme_system'), style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.language_rounded, color: AppColors.accentChampagne),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.tr('app_language'),
                        style: TextStyle(
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => loc.toggleLanguage(),
                      child: Text(
                        loc.tr('switch_language'),
                        style: const TextStyle(color: AppColors.accentChampagne, fontWeight: FontWeight.bold),
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
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
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
