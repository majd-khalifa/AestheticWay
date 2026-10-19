import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/pagination_footer.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/ltr_text_field.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/widgets/practitioner_badge.dart';
import '../../../../core/widgets/silver_button.dart';
import '../../../../core/widgets/luxury_image_picker_field.dart';
import '../../../../core/network/api_exception.dart';
import '../../../practitioners/models/practitioner_model.dart';
import '../../services/clinic_portal_service.dart';

/// Clinic Portal: Medical Practitioners Management Screen
class ClinicPractitionersScreen extends StatefulWidget {
  const ClinicPractitionersScreen({super.key});

  @override
  State<ClinicPractitionersScreen> createState() =>
      _ClinicPractitionersScreenState();
}

class _ClinicPractitionersScreenState extends State<ClinicPractitionersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ClinicPortalService().loadCollection('practitioners');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPractitionerFormDialog(
    BuildContext context,
    LocaleService loc, {
    PractitionerModel? existing,
  }) {
    final formKey = GlobalKey<FormState>();
    final isEditing = existing != null;

    String? avatarPath = existing?.avatarUrl;
    bool avatarPathChanged = false;
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
    final titleEnController = TextEditingController(
      text: existing?.classificationEn ?? '',
    );
    final titleArController = TextEditingController(
      text: existing?.classificationAr ?? '',
    );
    final bioEnController = TextEditingController(
      text: existing?.aboutEn ?? '',
    );
    final bioArController = TextEditingController(
      text: existing?.aboutAr ?? '',
    );

    PractitionerType selectedType = existing?.type ?? PractitionerType.doctor;
    String status = existing?.status ?? 'active';
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
                          : (loc.isArabic
                                ? 'إضافة ممارس طبي جديد'
                                : 'Add Medical Practitioner'),
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

                    // Practitioner Type Dropdown
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
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            loc.isArabic ? type.labelAr : type.labelEn,
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
                          setModalState(() => selectedType = v);
                        }
                      },
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
                        labelText: loc.isArabic
                            ? 'الاسم الكامل بالإنجليزية *'
                            : 'Full Name (English) *',
                        hintText: 'e.g. Dr. Layla Al Hashemi',
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
                        labelText: loc.isArabic
                            ? 'الاسم الكامل بالعربية *'
                            : 'Full Name (Arabic) *',
                        hintText: 'مثال: د. ليلى الهاشمي',
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
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? loc.tr('clinic_validation_required')
                          : null,
                    ),
                    const SizedBox(height: 10),

                    // Title EN & Title AR
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
                            ? 'المسمى المهني بالإنجليزية'
                            : 'Professional Title (English)',
                        hintText: 'e.g. Senior Consultant Dermatologist',
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
                            ? 'المسمى المهني بالعربية'
                            : 'Professional Title (Arabic)',
                        hintText: 'مثال: استشاري أول جلدية وتجميل',
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

                    // Bio EN & Bio AR
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
                            'e.g. Specialist with 10+ years in anti-aging treatments and facial aesthetics...',
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
                            'مثال: أخصائية بخبرة تزيد عن 10 سنوات في علاجات مكافحة الشيخوخة ونضارة الوجه...',
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

                    SilverButton(
                      label: isEditing
                          ? (loc.isArabic ? 'حفظ التعديلات' : 'Update')
                          : (loc.isArabic
                                ? 'إضافة الممارس'
                                : 'Save Practitioner'),
                      icon: Icons.check_circle_outline,
                      isFullWidth: true,
                      height: 46,
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
                                'title_en':
                                    titleEnController.text.trim().isNotEmpty
                                    ? titleEnController.text.trim()
                                    : specialtyEnController.text.trim(),
                                'title_ar':
                                    titleArController.text.trim().isNotEmpty
                                    ? titleArController.text.trim()
                                    : specialtyArController.text.trim(),
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
                                'status': status,
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
                                              ? 'تم تحديث بيانات الممارس بنجاح'
                                              : 'Practitioner updated successfully')
                                        : (loc.isArabic
                                              ? 'تم إضافة الممارس بنجاح'
                                              : 'Practitioner added successfully'),
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

  void _confirmDelete(
    BuildContext context,
    LocaleService loc,
    PractitionerModel p,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.isDark(context)
            ? AppColors.cardSurface
            : Colors.white,
        title: Text(
          loc.isArabic ? 'حذف الممارس الطبي' : 'Delete Practitioner',
          style: AppTypography.cardTitle.copyWith(
            color: AppColors.isDark(context)
                ? AppColors.silverPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          loc.isArabic
              ? 'هل أنت متأكد من رغبتك في إزالة "${p.nameAr}" من قائمة الفريق الطبي؟'
              : 'Are you sure you want to remove "${p.nameEn}" from the medical team?',
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
                await ClinicPortalService().deletePractitioner(p.id);
                if (context.mounted) {
                  showAppSnackBar(
                    context,
                    loc.isArabic
                        ? 'تم حذف الممارس بنجاح'
                        : 'Practitioner removed',
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

  void _queryChanged() => ClinicPortalService().searchCollection(
    'practitioners',
    {'search': _searchQuery},
  );

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final clinicService = ClinicPortalService();
    final isDark = AppColors.isDark(context);

    return ListenableBuilder(
      listenable: Listenable.merge([loc, clinicService]),
      builder: (context, _) {
        final all = clinicService.clinicPractitioners;
        final filtered = _searchQuery.isEmpty
            ? all
            : all.where((p) {
                final q = _searchQuery.toLowerCase();
                return p.nameEn.toLowerCase().contains(q) ||
                    p.nameAr.toLowerCase().contains(q) ||
                    p.specialtyEn.toLowerCase().contains(q) ||
                    p.specialtyAr.toLowerCase().contains(q);
              }).toList();

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Text(
              loc.isArabic ? 'إدارة الكادر الطبي' : 'Medical Staff',
              style: AppTypography.screenTitle.copyWith(
                color: isDark
                    ? AppColors.silverPrimary
                    : AppColors.lightTextPrimary,
                fontSize: 16,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.accentChampagne,
                ),
                tooltip: loc.isArabic ? 'إضافة ممارس' : 'Add Practitioner',
                onPressed: () => _showPractitionerFormDialog(context, loc),
              ),
            ],
          ),
          body: PagedScrollBoundary(
            onLoadMore: () => clinicService.loadMore('practitioners'),
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
                      hintText: loc.isArabic
                          ? 'بحث بالاسم أو التخصص...'
                          : 'Search by name or specialty...',
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

                // Content List
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.accentChampagne,
                    onRefresh: () => clinicService.loadCollection(
                      'practitioners',
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
                                      Icons.person_search_outlined,
                                      size: 48,
                                      color: AppColors.mutedText(context),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      loc.isArabic
                                          ? 'لا يوجد ممارسون مطابقون'
                                          : 'No practitioners found',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.mutedText(context),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SilverButton(
                                      label: loc.isArabic
                                          ? 'إضافة ممارس جديد'
                                          : 'Add Practitioner',
                                      icon: Icons.add,
                                      height: 38,
                                      onPressed: () =>
                                          _showPractitionerFormDialog(
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
                                      .collection('practitioners')
                                      .isLoadingMore,
                                  hasMore: clinicService
                                      .collection('practitioners')
                                      .hasMore,
                                  error: clinicService
                                      .collection('practitioners')
                                      .error,
                                  onLoadMore: () =>
                                      clinicService.loadMore('practitioners'),
                                );
                              }

                              final p = filtered[index];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: LuxuryCard(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(22),
                                        child: Image.network(
                                          p.avatarUrl,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            width: 44,
                                            height: 44,
                                            color: isDark
                                                ? AppColors.cardSurfaceHover
                                                : AppColors
                                                      .lightCardSurfaceHover,
                                            child: const Icon(
                                              Icons.person,
                                              color: AppColors.accentChampagne,
                                              size: 24,
                                            ),
                                          ),
                                          cacheWidth: computeSafeCacheWidth(
                                            context,
                                            400,
                                            null,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    loc.isArabic
                                                        ? p.nameAr
                                                        : p.nameEn,
                                                    style: AppTypography
                                                        .cardTitle
                                                        .copyWith(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: isDark
                                                              ? AppColors
                                                                    .silverPrimary
                                                              : AppColors
                                                                    .lightTextPrimary,
                                                        ),
                                                  ),
                                                ),
                                                PractitionerBadge(
                                                  type: p.type,
                                                  showIcon: false,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              loc.isArabic
                                                  ? p.specialtyAr
                                                  : p.specialtyEn,
                                              style: AppTypography.caption
                                                  .copyWith(
                                                    color: AppColors.mutedText(
                                                      context,
                                                    ),
                                                    fontSize: 11.5,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                              color: AppColors.silverPrimary,
                                            ),
                                            tooltip: loc.isArabic
                                                ? 'تعديل'
                                                : 'Edit',
                                            onPressed: () =>
                                                _showPractitionerFormDialog(
                                                  context,
                                                  loc,
                                                  existing: p,
                                                ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: AppColors.errorRed,
                                            ),
                                            tooltip: loc.isArabic
                                                ? 'حذف'
                                                : 'Delete',
                                            onPressed: () =>
                                                _confirmDelete(context, loc, p),
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
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showPractitionerFormDialog(context, loc),
            backgroundColor: AppColors.accentChampagne,
            foregroundColor: AppColors.backgroundDeep,
            icon: const Icon(Icons.person_add_rounded),
            label: Text(
              loc.isArabic ? 'إضافة ممارس' : 'Add Practitioner',
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
