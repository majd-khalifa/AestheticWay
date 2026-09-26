import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/ltr_text_field.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/widgets/silver_button.dart';
import '../../../offers/models/offer_model.dart';
import '../../services/clinic_portal_service.dart';

/// Clinic Tab 3: Clinic Offers & Treatment Packages Manager (Live API)
class ClinicOffersScreen extends StatefulWidget {
  const ClinicOffersScreen({super.key});

  @override
  State<ClinicOffersScreen> createState() => _ClinicOffersScreenState();
}

class _ClinicOffersScreenState extends State<ClinicOffersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ClinicPortalService().loadCatalogData();
    });
  }

  void _showAddOfferDialog(BuildContext context, LocaleService loc) {
    final formKey = GlobalKey<FormState>();
    final titleEnController = TextEditingController();
    final titleArController = TextEditingController();
    final originalPriceController = TextEditingController(text: '1500');
    final offerPriceController = TextEditingController(text: '999');
    final termsEnController = TextEditingController();
    final termsArController = TextEditingController();

    DateTime startsAt = DateTime.now();
    DateTime endsAt = DateTime.now().add(const Duration(days: 30));

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
                      loc.tr('clinic_add_offer_title'),
                      style: AppTypography.cardTitle.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Titles EN & AR
                    LtrTextFormField(
                      controller: titleEnController,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'عنوان العرض بالإنجليزية *' : 'Offer Title (English) *',
                        hintText: 'e.g. Exclusive Glow Package',
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
                      controller: titleArController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'عنوان العرض بالعربية *' : 'Offer Title (Arabic) *',
                        hintText: 'مثال: باقة النضارة الحصرية',
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

                    // Prices Row
                    Row(
                      children: [
                        Expanded(
                          child: LtrTextFormField(
                            controller: originalPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: loc.tr('clinic_offer_original_price'),
                              hintText: '1500',
                              filled: true,
                              fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: LtrTextFormField(
                            controller: offerPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: loc.tr('clinic_offer_discount_price'),
                              hintText: '999',
                              filled: true,
                              fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
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
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              side: BorderSide(color: AppColors.border(ctx), width: 0.8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.calendar_today, size: 16, color: AppColors.accentChampagne),
                            label: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.isArabic ? 'تاريخ البدء' : 'Start Date',
                                  style: AppTypography.caption.copyWith(color: AppColors.mutedText(ctx), fontSize: 10),
                                ),
                                Text(
                                  '${startsAt.year}-${startsAt.month.toString().padLeft(2, '0')}-${startsAt.day.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
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
                                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  startsAt = picked;
                                  if (endsAt.isBefore(startsAt)) {
                                    endsAt = startsAt.add(const Duration(days: 30));
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
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              side: BorderSide(color: AppColors.border(ctx), width: 0.8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.event_available, size: 16, color: AppColors.accentChampagne),
                            label: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.isArabic ? 'تاريخ الانتهاء' : 'End Date',
                                  style: AppTypography.caption.copyWith(color: AppColors.mutedText(ctx), fontSize: 10),
                                ),
                                Text(
                                  '${endsAt.year}-${endsAt.month.toString().padLeft(2, '0')}-${endsAt.day.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: endsAt.isAfter(startsAt) ? endsAt : startsAt.add(const Duration(days: 1)),
                                firstDate: startsAt,
                                lastDate: DateTime.now().add(const Duration(days: 730)),
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
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'الشروط والوصف بالإنجليزية' : 'Terms & Description (English)',
                        hintText: 'e.g. Includes consultation and skin analysis.',
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
                      controller: termsArController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'الشروط والوصف بالعربية' : 'Terms & Description (Arabic)',
                        hintText: 'مثال: شامل الاستشارة وتحليل البشرة.',
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SilverButton(
                      label: loc.tr('clinic_offer_save'),
                      icon: Icons.check_circle_outline,
                      isFullWidth: true,
                      height: 46,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final origPrice = double.tryParse(originalPriceController.text) ?? 1500;
                        final offPrice = double.tryParse(offerPriceController.text) ?? 999;

                        final data = <String, dynamic>{
                          'title_en': titleEnController.text.trim(),
                          'title_ar': titleArController.text.trim().isNotEmpty
                              ? titleArController.text.trim()
                              : titleEnController.text.trim(),
                          'description_en': termsEnController.text.trim().isNotEmpty
                              ? termsEnController.text.trim()
                              : 'Special promotional aesthetic offer.',
                          'description_ar': termsArController.text.trim().isNotEmpty
                              ? termsArController.text.trim()
                              : 'عرض ترويجي تجميلي خاص.',
                          'original_price': origPrice,
                          'offer_price': offPrice,
                          'starts_at': startsAt.toIso8601String(),
                          'ends_at': endsAt.toIso8601String(),
                          'status': 'active',
                          'is_active': true,
                        };

                        try {
                          await ClinicPortalService().createOffer(data);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            showAppSnackBar(
                              context,
                              loc.tr('clinic_offer_saved_success'),
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

  void _confirmDeleteOffer(BuildContext context, LocaleService loc, OfferModel offer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.isDark(context) ? AppColors.cardSurface : Colors.white,
        title: Text(
          loc.isArabic ? 'حذف العرض الترويجي' : 'Delete Offer',
          style: AppTypography.cardTitle.copyWith(
            color: AppColors.isDark(context) ? AppColors.silverPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          loc.isArabic
              ? 'هل أنت متأكد من حذف عرض "${offer.titleAr}"؟'
              : 'Are you sure you want to delete "${offer.titleEn}"?',
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
                await ClinicPortalService().deleteOffer(offer.id);
                if (context.mounted) {
                  showAppSnackBar(
                    context,
                    loc.isArabic ? 'تم حذف العرض بنجاح' : 'Offer deleted successfully',
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
        final offers = clinicService.clinicOffers;

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Text(
              loc.tr('clinic_nav_offers'),
              style: AppTypography.screenTitle.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
              ),
            ),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentChampagne),
                tooltip: loc.tr('clinic_btn_add_offer'),
                onPressed: () => _showAddOfferDialog(context, loc),
              ),
            ],
          ),
          body: clinicService.isLoading && offers.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accentChampagne, strokeWidth: 2.5),
                )
              : RefreshIndicator(
                  color: AppColors.accentChampagne,
                  onRefresh: () => clinicService.loadCatalogData(refresh: true),
                  child: offers.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_offer_outlined, size: 48, color: AppColors.mutedText(context)),
                                  const SizedBox(height: 12),
                                  Text(
                                    loc.tr('clinic_no_offers'),
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedText(context)),
                                  ),
                                  const SizedBox(height: 16),
                                  SilverButton(
                                    label: loc.tr('clinic_btn_add_offer'),
                                    icon: Icons.add,
                                    height: 40,
                                    onPressed: () => _showAddOfferDialog(context, loc),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: offers.length,
                          itemBuilder: (context, index) {
                            final offer = offers[index];
                            final isActive = offer.status == 'active';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: LuxuryCard(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            offer.imageUrl,
                                            width: 64,
                                            height: 64,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => Container(
                                              width: 64,
                                              height: 64,
                                              color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                                              child: const Icon(Icons.local_offer, color: AppColors.accentChampagne),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      loc.isArabic ? offer.titleAr : offer.titleEn,
                                                      style: AppTypography.cardTitle.copyWith(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w700,
                                                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                    decoration: BoxDecoration(
                                                      color: isActive
                                                          ? AppColors.successGreen.withValues(alpha: 0.15)
                                                          : AppColors.mutedText(context).withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      isActive
                                                          ? (loc.isArabic ? 'نشط' : 'Active')
                                                          : (loc.isArabic ? 'معلّق' : 'Suspended'),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: isActive
                                                            ? AppColors.successGreen
                                                            : AppColors.mutedText(context),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Text(
                                                    '${offer.offerPrice.toInt()} ${loc.tr('currency_aed')}',
                                                    style: AppTypography.cardTitle.copyWith(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w800,
                                                      color: AppColors.accentChampagne,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${offer.originalPrice.toInt()} ${loc.tr('currency_aed')}',
                                                    style: AppTypography.caption.copyWith(
                                                      decoration: TextDecoration.lineThrough,
                                                      color: AppColors.mutedText(context),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.accentChampagne.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      '-${offer.discountPercentage}%',
                                                      style: AppTypography.badge.copyWith(
                                                        color: AppColors.accentChampagne,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 16),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.accentChampagne),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            loc.isArabic ? offer.validUntilText : (offer.validUntilTextEn ?? offer.validUntilText),
                                            style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 11.5),
                                          ),
                                        ),
                                        // Toggle Active/Suspended Button
                                        IconButton(
                                          icon: Icon(
                                            isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                                            size: 20,
                                            color: isActive ? Colors.amber : AppColors.successGreen,
                                          ),
                                          tooltip: isActive
                                              ? (loc.isArabic ? 'تعليق العرض' : 'Suspend Offer')
                                              : (loc.isArabic ? 'تفعيل العرض' : 'Activate Offer'),
                                          onPressed: () async {
                                            try {
                                              await clinicService.toggleOfferStatus(offer.id);
                                            } catch (e) {
                                              if (context.mounted) {
                                                showAppSnackBar(context, e.toString(), type: AppSnackBarType.error);
                                              }
                                            }
                                          },
                                        ),
                                        // Delete Offer
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.errorRed),
                                          tooltip: loc.isArabic ? 'حذف العرض' : 'Delete',
                                          onPressed: () => _confirmDeleteOffer(context, loc, offer),
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddOfferDialog(context, loc),
            backgroundColor: AppColors.accentChampagne,
            foregroundColor: AppColors.backgroundDeep,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              loc.tr('clinic_btn_add_offer'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ),
        );
      },
    );
  }
}
