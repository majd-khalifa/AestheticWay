import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/pagination_footer.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/widgets/silver_button.dart';
import '../../../offers/models/offer_model.dart';
import '../../services/clinic_portal_service.dart';
import '../widgets/clinic_offer_editor.dart';

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
      ClinicPortalService().loadCollection('offers');
    });
  }

  void _confirmDeleteOffer(
    BuildContext context,
    LocaleService loc,
    OfferModel offer,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.isDark(context)
            ? AppColors.cardSurface
            : Colors.white,
        title: Text(
          loc.isArabic ? 'حذف العرض الترويجي' : 'Delete Offer',
          style: AppTypography.cardTitle.copyWith(
            color: AppColors.isDark(context)
                ? AppColors.silverPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          loc.isArabic
              ? 'هل أنت متأكد من حذف عرض "${offer.titleAr}"؟'
              : 'Are you sure you want to delete "${offer.titleEn}"?',
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
                await ClinicPortalService().deleteOffer(offer.id);
                if (context.mounted) {
                  showAppSnackBar(
                    context,
                    loc.isArabic
                        ? 'تم حذف العرض بنجاح'
                        : 'Offer deleted successfully',
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
                color: isDark
                    ? AppColors.silverPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.accentChampagne,
                ),
                tooltip: loc.tr('clinic_btn_add_offer'),
                onPressed: () => showClinicOfferEditor(context, loc),
              ),
            ],
          ),
          body: PagedScrollBoundary(
            onLoadMore: () => clinicService.loadMore('offers'),
            child: clinicService.isLoading && offers.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentChampagne,
                      strokeWidth: 2.5,
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.accentChampagne,
                    onRefresh: () =>
                        clinicService.loadCollection('offers', refresh: true),
                    child: offers.isEmpty
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
                                      Icons.local_offer_outlined,
                                      size: 48,
                                      color: AppColors.mutedText(context),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      loc.tr('clinic_no_offers'),
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.mutedText(context),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SilverButton(
                                      label: loc.tr('clinic_btn_add_offer'),
                                      icon: Icons.add,
                                      height: 40,
                                      onPressed: () =>
                                          showClinicOfferEditor(context, loc),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: offers.length + 1,
                            itemBuilder: (context, index) {
                              if (index >= offers.length) {
                                return PaginationFooter(
                                  loading: clinicService
                                      .collection('offers')
                                      .isLoadingMore,
                                  hasMore: clinicService
                                      .collection('offers')
                                      .hasMore,
                                  error: clinicService
                                      .collection('offers')
                                      .error,
                                  onLoadMore: () =>
                                      clinicService.loadMore('offers'),
                                );
                              }

                              final offer = offers[index];
                              final isActive = offer.status == 'active';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: LuxuryCard(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: LuxuryImage(
                                              imageUrl: offer.imageUrl,
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              customPlaceholder: Container(
                                                width: 64,
                                                height: 64,
                                                color: isDark
                                                    ? AppColors.cardSurfaceHover
                                                    : AppColors
                                                          .lightCardSurfaceHover,
                                                child: const Icon(
                                                  Icons.local_offer,
                                                  color:
                                                      AppColors.accentChampagne,
                                                ),
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
                                                            ? offer.titleAr
                                                            : offer.titleEn,
                                                        style: AppTypography
                                                            .cardTitle
                                                            .copyWith(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: isDark
                                                                  ? AppColors
                                                                        .silverPrimary
                                                                  : AppColors
                                                                        .lightTextPrimary,
                                                            ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 7,
                                                            vertical: 2.5,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isActive
                                                            ? AppColors
                                                                  .successGreen
                                                                  .withValues(
                                                                    alpha: 0.15,
                                                                  )
                                                            : AppColors.mutedText(
                                                                context,
                                                              ).withValues(
                                                                alpha: 0.15,
                                                              ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        isActive
                                                            ? (loc.isArabic
                                                                  ? 'نشط'
                                                                  : 'Active')
                                                            : (loc.isArabic
                                                                  ? 'معلّق'
                                                                  : 'Suspended'),
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isActive
                                                              ? AppColors
                                                                    .successGreen
                                                              : AppColors.mutedText(
                                                                  context,
                                                                ),
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
                                                      style: AppTypography
                                                          .cardTitle
                                                          .copyWith(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color:
                                                                AppColors.goldText(
                                                                  context,
                                                                ),
                                                          ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '${offer.originalPrice.toInt()} ${loc.tr('currency_aed')}',
                                                      style: AppTypography
                                                          .caption
                                                          .copyWith(
                                                            decoration:
                                                                TextDecoration
                                                                    .lineThrough,
                                                            color:
                                                                AppColors.mutedText(
                                                                  context,
                                                                ),
                                                          ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .accentChampagne
                                                            .withValues(
                                                              alpha: 0.15,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '-${offer.discountPercentage}%',
                                                        style: AppTypography
                                                            .badge
                                                            .copyWith(
                                                              color:
                                                                  AppColors.goldText(
                                                                    context,
                                                                  ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
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
                                          const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 13,
                                            color: AppColors.accentChampagne,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              loc.isArabic
                                                  ? offer.validUntilText
                                                  : (offer.validUntilTextEn ??
                                                        offer.validUntilText),
                                              style: AppTypography.caption
                                                  .copyWith(
                                                    color: AppColors.mutedText(
                                                      context,
                                                    ),
                                                    fontSize: 11.5,
                                                  ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit_outlined,
                                              size: 20,
                                              color: AppColors.text(context),
                                            ),
                                            tooltip: loc.isArabic
                                                ? 'تعديل العرض'
                                                : 'Edit Offer',
                                            onPressed: () =>
                                                showClinicOfferEditor(
                                                  context,
                                                  loc,
                                                  existing: offer,
                                                ),
                                          ),
                                          // Toggle Active/Suspended Button
                                          IconButton(
                                            icon: Icon(
                                              isActive
                                                  ? Icons
                                                        .pause_circle_outline_rounded
                                                  : Icons
                                                        .play_circle_outline_rounded,
                                              size: 20,
                                              color: isActive
                                                  ? Colors.amber
                                                  : AppColors.successGreen,
                                            ),
                                            tooltip: isActive
                                                ? (loc.isArabic
                                                      ? 'تعليق العرض'
                                                      : 'Suspend Offer')
                                                : (loc.isArabic
                                                      ? 'تفعيل العرض'
                                                      : 'Activate Offer'),
                                            onPressed: () async {
                                              try {
                                                await clinicService
                                                    .toggleOfferStatus(
                                                      offer.id,
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
                                          // Delete Offer
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: AppColors.errorRed,
                                            ),
                                            tooltip: loc.isArabic
                                                ? 'حذف العرض'
                                                : 'Delete',
                                            onPressed: () =>
                                                _confirmDeleteOffer(
                                                  context,
                                                  loc,
                                                  offer,
                                                ),
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showClinicOfferEditor(context, loc),
            backgroundColor: AppColors.accentChampagne,
            foregroundColor: AppColors.backgroundDeep,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              loc.tr('clinic_btn_add_offer'),
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
