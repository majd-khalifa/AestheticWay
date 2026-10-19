import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/ltr_text_field.dart';
import '../../../../core/widgets/silver_button.dart';
import '../../../../core/widgets/luxury_image_picker_field.dart';
import '../../../../core/network/api_exception.dart';
import '../../../offers/models/offer_model.dart';
import '../../services/clinic_portal_service.dart';

Future<void> showClinicOfferEditor(
  BuildContext context,
  LocaleService loc, {
  OfferModel? existing,
}) async {
  final formKey = GlobalKey<FormState>();
  String? offerImagePath;
  bool imageChanged = false;
  final titleEnController = TextEditingController(text: existing?.titleEn);
  final titleArController = TextEditingController(text: existing?.titleAr);
  final originalPriceController = TextEditingController(
    text: existing?.originalPrice.toString() ?? '',
  );
  final offerPriceController = TextEditingController(
    text: existing?.offerPrice.toString() ?? '',
  );
  final termsEnController = TextEditingController(text: existing?.termsEn);
  final termsArController = TextEditingController(text: existing?.termsAr);

  DateTime startsAt = existing?.startsAt ?? DateTime.now();
  DateTime endsAt =
      existing?.endsAt ?? DateTime.now().add(const Duration(days: 30));
  String? modalErrorMessage;
  bool isSubmitting = false;

  final isDark = AppColors.isDark(context);
  ModalRoute<void>? editorRoute;

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        editorRoute = ModalRoute.of<void>(ctx);
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
                      existing == null
                          ? loc.tr('clinic_add_offer_title')
                          : (loc.isArabic ? 'تعديل العرض' : 'Edit Offer'),
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

                    // Titles EN & AR
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
                            ? 'عنوان العرض بالإنجليزية *'
                            : 'Offer Title (English) *',
                        hintText: 'e.g. Summer Laser & Glow Package',
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
                            ? 'عنوان العرض بالعربية *'
                            : 'Offer Title (Arabic) *',
                        hintText: 'مثال: باقة الليزر والنضارة المتكاملة',
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

                    // Offer Banner Image Picker
                    LuxuryImagePickerField(
                      label: loc.isArabic
                          ? 'صورة العرض / البانر الترويجي'
                          : 'Offer Banner Image',
                      height: 130,
                      initialUrl: existing?.imageUrl,
                      onImageSelected: (path) {
                        offerImagePath = path;
                        imageChanged = true;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Prices Row
                    Row(
                      children: [
                        Expanded(
                          child: LtrTextFormField(
                            controller: originalPriceController,
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
                              labelText: loc.tr('clinic_offer_original_price'),
                              hintText: 'e.g. 1500',
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
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: LtrTextFormField(
                            controller: offerPriceController,
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
                              labelText: loc.tr('clinic_offer_discount_price'),
                              hintText: 'e.g. 990',
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Date Pickers Row (Mandatory in Backend!)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              side: BorderSide(
                                color: AppColors.border(ctx),
                                width: 0.8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppColors.accentChampagne,
                            ),
                            label: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.isArabic ? 'تاريخ البدء' : 'Start Date',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.mutedText(ctx),
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  '${startsAt.year}-${startsAt.month.toString().padLeft(2, '0')}-${startsAt.day.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.silverPrimary
                                        : AppColors.lightTextPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: startsAt,
                                firstDate: startsAt.isBefore(DateTime.now())
                                    ? startsAt
                                    : DateTime.now().subtract(
                                        const Duration(days: 1),
                                      ),
                                lastDate: startsAt.add(
                                  const Duration(days: 730),
                                ),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  startsAt = picked;
                                  if (endsAt.isBefore(startsAt)) {
                                    endsAt = startsAt.add(
                                      const Duration(days: 30),
                                    );
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              side: BorderSide(
                                color: AppColors.border(ctx),
                                width: 0.8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.event_available,
                              size: 16,
                              color: AppColors.accentChampagne,
                            ),
                            label: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.isArabic ? 'تاريخ الانتهاء' : 'End Date',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.mutedText(ctx),
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  '${endsAt.year}-${endsAt.month.toString().padLeft(2, '0')}-${endsAt.day.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.silverPrimary
                                        : AppColors.lightTextPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: endsAt.isAfter(startsAt)
                                    ? endsAt
                                    : startsAt.add(const Duration(days: 1)),
                                firstDate: startsAt,
                                lastDate: endsAt.isAfter(startsAt)
                                    ? endsAt.add(const Duration(days: 730))
                                    : startsAt.add(const Duration(days: 730)),
                              );
                              if (picked != null) {
                                setModalState(() => endsAt = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Terms / Description EN & AR
                    LtrTextFormField(
                      controller: termsEnController,
                      maxLines: 2,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'الشروط والوصف بالإنجليزية'
                            : 'Terms & Description (English)',
                        hintText:
                            'e.g. Includes consultation and skin analysis.',
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
                      controller: termsArController,
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
                            ? 'الشروط والوصف بالعربية'
                            : 'Terms & Description (Arabic)',
                        hintText: 'مثال: شامل الاستشارة وتحليل البشرة.',
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
                      label: loc.tr('clinic_offer_save'),
                      icon: Icons.check_circle_outline,
                      isFullWidth: true,
                      height: 46,
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => modalErrorMessage = null);
                              if (!formKey.currentState!.validate()) return;

                              if (!endsAt.isAfter(startsAt)) {
                                setModalState(() {
                                  modalErrorMessage = loc.isArabic
                                      ? 'تاريخ نهاية العرض لا يمكن أن يكون قبل تاريخ البداية'
                                      : 'Offer end date cannot be earlier than the start date.';
                                });
                                return;
                              }

                              final origPrice = double.tryParse(
                                originalPriceController.text,
                              );
                              final offPrice = double.tryParse(
                                offerPriceController.text,
                              );
                              if (origPrice == null ||
                                  offPrice == null ||
                                  !origPrice.isFinite ||
                                  !offPrice.isFinite ||
                                  origPrice < 0 ||
                                  offPrice < 0 ||
                                  offPrice > origPrice) {
                                setModalState(
                                  () => modalErrorMessage = loc.isArabic
                                      ? 'أدخل أسعاراً صحيحة؛ سعر العرض لا يتجاوز السعر الأصلي.'
                                      : 'Enter valid prices; the offer price must not exceed the original price.',
                                );
                                return;
                              }

                              final data = <String, dynamic>{
                                'title_en': titleEnController.text.trim(),
                                'title_ar':
                                    titleArController.text.trim().isNotEmpty
                                    ? titleArController.text.trim()
                                    : titleEnController.text.trim(),
                                'description_en':
                                    termsEnController.text.trim().isNotEmpty
                                    ? termsEnController.text.trim()
                                    : 'Special promotional aesthetic offer.',
                                'description_ar':
                                    termsArController.text.trim().isNotEmpty
                                    ? termsArController.text.trim()
                                    : 'عرض ترويجي تجميلي خاص.',
                                'original_price': origPrice,
                                'offer_price': offPrice,
                                'starts_at': startsAt.toIso8601String(),
                                'ends_at': endsAt.toIso8601String(),
                                'status': existing?.status ?? 'active',
                                'is_active': existing?.isActive ?? true,
                              };
                              if (imageChanged) {
                                data['image'] = offerImagePath;
                              }

                              setModalState(() => isSubmitting = true);

                              try {
                                if (existing == null) {
                                  await ClinicPortalService().createOffer(data);
                                } else {
                                  await ClinicPortalService().updateOffer(
                                    existing.id,
                                    data,
                                  );
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  showAppSnackBar(
                                    context,
                                    loc.tr('clinic_offer_saved_success'),
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
  } finally {
    // The popped Future completes before the reverse animation unmounts fields.
    // Keep controllers alive until the sheet's route has actually been removed.
    await editorRoute?.completed;
    titleEnController.dispose();
    titleArController.dispose();
    originalPriceController.dispose();
    offerPriceController.dispose();
    termsEnController.dispose();
    termsArController.dispose();
  }
}
