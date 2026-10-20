import '../widgets/clinic_catalog_cards.dart';
import 'package:aesthetic_way/core/widgets/pagination_footer.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
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

                              return ClinicOfferCard(
                                offer: offer,
                                onEdit: () => showClinicOfferEditor(
                                  context,
                                  loc,
                                  existing: offer,
                                ),
                                onDelete: () =>
                                    _confirmDeleteOffer(context, loc, offer),
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
