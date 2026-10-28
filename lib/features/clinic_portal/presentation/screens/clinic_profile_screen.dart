import '../../../../core/widgets/async_action_button.dart';
import '../../../google_business/presentation/google_business_screen.dart';
import '../../../../core/auth/session_snapshot.dart';
import 'clinic_media_screen.dart';
import '../../../../core/services/local_media_cache.dart';
import '../../../../core/widgets/account_privacy_actions.dart';
import '../widgets/clinic_catalog_cards.dart';
import 'clinic_offers_screen.dart';
import 'package:aesthetic_way/core/widgets/paged_entity_field.dart';
import '../../data/clinic_catalog_repository.dart';
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
import 'package:aesthetic_way/core/utils/maps_launcher.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/articles/models/article_model.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/login_screen.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/widgets/luxury_image_picker_field.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import '../widgets/clinic_editorial_header.dart';
import '../widgets/clinic_location_selector.dart';
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
  bool _locationBusy = false;

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
    final editorSession = SessionSnapshot();
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                              if (!editorSession.isCurrent) {
                                setModalState(
                                  () => modalErrorMessage = loc.isArabic
                                      ? 'تغيرت الجلسة. أغلق النموذج وأعد فتحه.'
                                      : 'Your session changed. Close and reopen this form.',
                                );
                                return;
                              }

                              final data = <String, dynamic>{
                                'name_en': nameEnController.text.trim(),
                                'name_ar':
                                    nameArController.text.trim().isNotEmpty
                                    ? nameArController.text.trim()
                                    : nameEnController.text.trim(),
                                'speciality_en': specialtyEnController.text
                                    .trim(),
                                'speciality_ar': specialtyArController.text
                                    .trim(),
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

  void _showAddServiceDialog(
    BuildContext context,
    LocaleService loc, {
    TreatmentModel? existing,
  }) {
    showClinicTreatmentEditor(context, loc, existing: existing);
  }

  void _showProductFormDialog(
    BuildContext context,
    LocaleService loc, {
    ProductModel? existing,
  }) {
    final formKey = GlobalKey<FormState>();
    final editorSession = SessionSnapshot();
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: loc.isArabic
                            ? 'اسم المنتج بالإنجليزية *'
                            : 'Product Name (English) *',
                        hintText: 'e.g. Hyaluronic Acid Serum',
                        prefixIcon: const Icon(
                          Icons.auto_awesome_outlined,
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: loc.isArabic
                            ? 'اسم المنتج بالعربية'
                            : 'Product Name (Arabic)',
                        hintText: 'مثال: سيروم حمض الهيالورونيك',
                        prefixIcon: const Icon(
                          Icons.auto_awesome_outlined,
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                              if (!editorSession.isCurrent) {
                                setModalState(
                                  () => modalErrorMessage = loc.isArabic
                                      ? 'تغيرت الجلسة. أغلق النموذج وأعد فتحه.'
                                      : 'Your session changed. Close and reopen this form.',
                                );
                                return;
                              }
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
    final editorSession = SessionSnapshot();
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                              if (!editorSession.isCurrent) {
                                setModalState(
                                  () => modalErrorMessage = loc.isArabic
                                      ? 'تغيرت الجلسة. أغلق النموذج وأعد فتحه.'
                                      : 'Your session changed. Close and reopen this form.',
                                );
                                return;
                              }
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
    final editorSession = SessionSnapshot();
    final nameArCtrl = TextEditingController(text: clinic.nameAr);
    final nameEnCtrl = TextEditingController(text: clinic.nameEn);
    final descArCtrl = TextEditingController(text: clinic.descriptionAr);
    final descEnCtrl = TextEditingController(text: clinic.descriptionEn);
    ClinicLocationSelection? selectedLocation;
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                    OutlinedButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final result = await showClinicLocationSelector(
                                ctx,
                                city: selectedLocation?.city ?? clinic.city,
                                addressAr:
                                    selectedLocation?.addressAr ??
                                    clinic.editableAddressAr,
                                addressEn:
                                    selectedLocation?.addressEn ??
                                    clinic.editableAddressEn,
                                latitude:
                                    selectedLocation?.latitude ??
                                    clinic.latitude,
                                longitude:
                                    selectedLocation?.longitude ??
                                    clinic.longitude,
                              );
                              if (!ctx.mounted || result == null) return;
                              setModalState(() => selectedLocation = result);
                            },
                      icon: const Icon(Icons.location_on_outlined),
                      label: Text(
                        loc.isArabic
                            ? 'تحديد موقع العيادة على الخريطة'
                            : 'Choose Clinic Location on Map',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      clinicLocationSummary(
                        selectedLocation?.city ?? clinic.city,
                        loc.isArabic
                            ? (selectedLocation?.addressAr ?? clinic.addressAr)
                            : (selectedLocation?.addressEn ?? clinic.addressEn),
                        arabic: loc.isArabic,
                      ),
                      style: TextStyle(color: AppColors.mutedText(ctx)),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: descArCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                              if (!editorSession.isCurrent) {
                                setModalState(
                                  () => modalErrorMessage = loc.isArabic
                                      ? 'تغيرت الجلسة. أغلق النموذج وأعد فتحه.'
                                      : 'Your session changed. Close and reopen this form.',
                                );
                                return;
                              }
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
                                  addressAr: selectedLocation?.addressAr,
                                  addressEn: selectedLocation?.addressEn,
                                  city: selectedLocation?.city,
                                  emirate: selectedLocation?.emirate,
                                  latitude: selectedLocation?.latitude,
                                  longitude: selectedLocation?.longitude,
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

  Future<void> _updateClinicLocation(
    BuildContext context,
    LocaleService loc,
  ) async {
    if (_locationBusy) return;
    final editorSession = SessionSnapshot();
    setState(() => _locationBusy = true);
    final service = ClinicPortalService();
    final clinic = service.activeClinic;
    try {
      final result = await showClinicLocationSelector(
        context,
        city: clinic.city,
        addressAr: clinic.editableAddressAr,
        addressEn: clinic.editableAddressEn,
        latitude: clinic.latitude,
        longitude: clinic.longitude,
      );
      if (result == null || !context.mounted) return;
      editorSession.ensureCurrent();
      await service.updateClinicCoordinates(
        addressAr: result.addressAr,
        addressEn: result.addressEn,
        city: result.city,
        emirate: result.emirate,
        latitude: result.latitude,
        longitude: result.longitude,
      );
      if (context.mounted) {
        showAppSnackBar(
          context,
          loc.isArabic ? 'تم تحديث موقع العيادة' : 'Clinic location updated',
          type: AppSnackBarType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          e is ApiException
              ? e.message
              : loc.isArabic
              ? 'تعذر حفظ الموقع. حاول مجدداً.'
              : 'Could not save location. Please try again.',
          type: AppSnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _locationBusy = false);
    }
  }

  Future<void> _deleteCatalogItem(
    BuildContext context,
    LocaleService loc,
    Future<void> Function() remove,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.isArabic ? 'حذف العنصر؟' : 'Delete this item?'),
        content: Text(
          loc.isArabic
              ? 'سيتم حذف العنصر من ملف العيادة.'
              : 'This item will be removed from the clinic profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.isArabic ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await remove();
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          e is ApiException
              ? e.message
              : loc.isArabic
              ? 'تعذر حذف العنصر'
              : 'Could not delete item',
          type: AppSnackBarType.error,
        );
      }
    }
  }

  Widget _productRow(BuildContext context, ProductModel p) {
    final loc = LocaleService();
    final clinicService = ClinicPortalService();
    return ClinicCatalogMiniRow(
      title: loc.isArabic ? p.nameAr : p.nameEn,
      subtitle: loc.isArabic
          ? (p.brandNameAr ?? p.brandNameEn ?? '')
          : (p.brandNameEn ?? p.brandNameAr ?? ''),
      imageUrl: p.imageUrl,
      mediaCacheKey: LocalMediaCache.entity('product', p.id),
      preserveImageShape: true,
      icon: Icons.auto_awesome_outlined,
      onEdit: () => _showProductFormDialog(context, loc, existing: p),
      onDelete: () => _deleteCatalogItem(
        context,
        loc,
        () => clinicService.deleteProduct(p.id),
      ),
    );
  }

  Widget _articleRow(BuildContext context, ArticleModel art) {
    final loc = LocaleService();
    final clinicService = ClinicPortalService();
    return ClinicCatalogMiniRow(
      title: loc.isArabic ? art.titleAr : art.titleEn,
      subtitle: loc.isArabic ? art.authorDoctorNameAr : art.authorDoctorNameEn,
      imageUrl: art.coverImageUrl,
      mediaCacheKey: LocalMediaCache.entity('article', art.id),
      icon: Icons.article_outlined,
      onEdit: () => _showArticleFormDialog(context, loc, existing: art),
      onDelete: () => _deleteCatalogItem(
        context,
        loc,
        () => clinicService.deleteArticle(art.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final themeService = ThemeService();
    final clinicService = ClinicPortalService();
    final isDark = AppColors.isDark(context);
    return ListenableBuilder(
      listenable: Listenable.merge([loc, themeService, clinicService]),
      builder: (context, _) {
        final clinic = clinicService.activeClinic;
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
              LuxuryCard(
                padding: EdgeInsets.zero,
                child: ClinicEditorialHeader(
                  clinic: clinic,
                  onEdit: () => _showEditClinicProfileDialog(context, loc),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ClinicMediaScreen(),
                  ),
                ),
                icon: const Icon(Icons.perm_media_outlined),
                label: Text(
                  loc.isArabic
                      ? 'إدارة معرض الصور والفيديو'
                      : 'Manage photo gallery and video',
                ),
              ),
              const SizedBox(height: 16),
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.isArabic
                          ? 'الموقع ونشاط Google'
                          : 'Location & Google Business',
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AsyncActionButton(
                      icon: Icons.business_outlined,
                      label: loc.isArabic
                          ? 'مراجعة ارتباط Google Business'
                          : 'Review Google Business association',
                      onPressed: (action) async {
                        await action.wait(
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => GoogleBusinessScreen(
                                onEditManualPin: () =>
                                    _updateClinicLocation(context, loc),
                              ),
                            ),
                          ),
                        );
                        await action.wait(
                          ClinicPortalService().refreshClinicProfile(),
                        );
                      },
                    ),
                    Text(
                      loc.isArabic
                          ? 'الدبوس اليدوي مستقل عن ارتباط نشاط Google.'
                          : 'The manual pin is separate from Google Business linking.',
                    ),
                    Text(
                      clinicLocationSummary(
                        clinic.city,
                        loc.isArabic ? clinic.addressAr : clinic.addressEn,
                        arabic: loc.isArabic,
                      ),
                      style: TextStyle(
                        color: AppColors.mutedText(context),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (ClinicLocationSelection.validCoordinates(
                      clinic.latitude,
                      clinic.longitude,
                    ))
                      ClinicMapPreview(
                        key: ValueKey('${clinic.latitude},${clinic.longitude}'),
                        latitude: clinic.latitude,
                        longitude: clinic.longitude,
                      )
                    else
                      Container(
                        height: 100,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.goldText(
                            context,
                          ).withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          loc.isArabic
                              ? 'حدد موقع العيادة على الخريطة'
                              : 'Choose the clinic’s map location',
                          style: TextStyle(color: AppColors.text(context)),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _locationBusy
                              ? null
                              : () => _updateClinicLocation(context, loc),
                          icon: _locationBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.edit_location_alt_outlined),
                          label: Text(
                            _locationBusy
                                ? (loc.isArabic
                                      ? 'جارٍ تحديث الموقع…'
                                      : 'Updating location…')
                                : loc.isArabic
                                ? 'تحديث موقع العيادة'
                                : 'Update Location',
                          ),
                        ),
                        AsyncActionButton(
                          icon: Icons.open_in_new,
                          label: loc.isArabic
                              ? 'فتح الدبوس اليدوي في خرائط Google'
                              : 'Open manual pin in Google Maps',
                          onPressed:
                              !ClinicLocationSelection.validCoordinates(
                                clinic.latitude,
                                clinic.longitude,
                              )
                              ? null
                              : (_) async {
                                  if (!await MapsLauncher.openVerifiedLocation(
                                    latitude: clinic.latitude,
                                    longitude: clinic.longitude,
                                  )) {
                                    throw StateError('Directions unavailable');
                                  }
                                },
                        ),
                      ],
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
                    ClinicSectionHeader(
                      title: loc.tr('clinic_team_title'),
                      addLabel: loc.tr('clinic_add_practitioner'),
                      onAdd: () => _showAddPractitionerDialog(context, loc),
                      onManage: () => Navigator.push(
                        context,
                        LuxuryPageRoute(
                          page: const ClinicPractitionersScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    BoundedCatalogPreview<PractitionerModel>(
                      items: () => clinicService.clinicPractitioners,
                      listenable: clinicService,
                      page: clinicService.collection('practitioners'),
                      itemBuilder: (context, p) => ClinicPractitionerCard(
                        practitioner: p,
                        compact: true,
                        clinicLogoUrl: clinic.logoUrl,
                        onEdit: () => _showAddPractitionerDialog(
                          context,
                          loc,
                          existing: p,
                        ),
                        onDelete: () => _deleteCatalogItem(
                          context,
                          loc,
                          () => clinicService.deletePractitioner(p.id),
                        ),
                      ),
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
                    ClinicSectionHeader(
                      title: loc.tr('clinic_services_title'),
                      addLabel: loc.tr('clinic_add_service'),
                      onAdd: () => _showAddServiceDialog(context, loc),
                      onManage: () => Navigator.push(
                        context,
                        LuxuryPageRoute(page: const ClinicTreatmentsScreen()),
                      ),
                    ),
                    const SizedBox(height: 8),
                    BoundedCatalogPreview<TreatmentModel>(
                      items: () => clinicService.clinicTreatments,
                      listenable: clinicService,
                      page: clinicService.collection('treatments'),
                      itemBuilder: (context, t) => ClinicTreatmentCard(
                        treatment: t,
                        practitioners: clinicService.clinicPractitioners,
                        onEdit: () =>
                            _showAddServiceDialog(context, loc, existing: t),
                        onDelete: () => _deleteCatalogItem(
                          context,
                          loc,
                          () => clinicService.deleteTreatment(t.id),
                        ),
                      ),
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
                    ClinicSectionHeader(
                      title: loc.tr('clinic_nav_offers'),
                      addLabel: loc.tr('clinic_btn_add_offer'),
                      onAdd: () => showClinicOfferEditor(context, loc),
                      onManage: () => Navigator.push(
                        context,
                        LuxuryPageRoute(page: const ClinicOffersScreen()),
                      ),
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
                      itemBuilder: (context, offer) => ClinicOfferCard(
                        offer: offer,
                        onEdit: () => showClinicOfferEditor(
                          context,
                          loc,
                          existing: offer,
                        ),
                        onDelete: () => _deleteCatalogItem(
                          context,
                          loc,
                          () => clinicService.deleteOffer(offer.id),
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
                    ClinicSectionHeader(
                      title: loc.tr('clinic_manage_products'),
                      addLabel: loc.tr('clinic_add_product'),
                      onAdd: () => _showProductFormDialog(context, loc),
                      onManage: () => showBoundedCatalogSheet<ProductModel>(
                        context,
                        items: () => clinicService.clinicProducts,
                        listenable: clinicService,
                        page: clinicService.collection('products'),
                        itemBuilder: _productRow,
                      ),
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
                        itemBuilder: _productRow,
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
                    ClinicSectionHeader(
                      title: loc.tr('clinic_manage_articles'),
                      addLabel: loc.tr('clinic_add_article'),
                      onAdd: () => _showArticleFormDialog(context, loc),
                      onManage: () => showBoundedCatalogSheet<ArticleModel>(
                        context,
                        items: () => clinicService.clinicArticles,
                        listenable: clinicService,
                        page: clinicService.collection('articles'),
                        itemBuilder: _articleRow,
                      ),
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
                        itemBuilder: _articleRow,
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
              const AccountPrivacyActions(),
              const SizedBox(height: 12),
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
