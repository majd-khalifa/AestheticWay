import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/widgets/luxury_shimmer.dart';
import 'package:aesthetic_way/core/widgets/luxury_error_view.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/offers/data/offers_repository.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinic_profile_screen.dart';

/// Screen 1/8: Exclusive Aesthetic Offers & Packages
/// Powered by live API: GET /api/v1/offers/
class OffersScreen extends StatefulWidget {
  final List<OfferModel>? initialOffers;

  const OffersScreen({super.key, this.initialOffers});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final OffersRepository _offersRepository = OffersRepository();

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<OfferModel>? _offers;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialOffers != null) {
      _offers = widget.initialOffers;
      _isLoading = false;
    } else {
      _loadOffers();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOffers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final offers = await _offersRepository.getOffers(search: _searchQuery);
      if (mounted) {
        setState(() {
          _offers = offers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleClaimOffer(OfferModel offer) async {
    final auth = await GuestAuthGuard.requireAuth(
      context,
      reasonTitle: LocaleService().tr('offer_claim'),
      reasonSubtitle: LocaleService().isArabic
          ? 'سجّل دخولك برقم الهاتف للاستفادة من باقة العرض'
          : 'Login with phone number to claim this offer lead',
    );
    if (!auth || !mounted) return;

    final clinic = ClinicModel(
      id: offer.clinicId,
      nameAr: offer.clinicNameAr,
      nameEn: offer.clinicNameEn ?? offer.clinicNameAr,
      descriptionAr: offer.termsAr,
      descriptionEn: offer.termsEn ?? '',
      coverImageUrl: offer.imageUrl,
      galleryImages: isValidNetworkImageUrl(offer.imageUrl) ? [offer.imageUrl] : const [],
      logoUrl: offer.imageUrl,
      rating: 0.0,
      reviewCount: 0,
      subscriptionTier: SubscriptionTier.basic,
      city: 'Dubai',
      areaAr: '',
      addressAr: '',
    );

    Navigator.push(
      context,
      LuxuryPageRoute(
        page: AppointmentRequestScreen(
          clinic: clinic,
          selectedOfferTitle: LocaleService().isArabic ? offer.titleAr : offer.titleEn,
          selectedOfferId: offer.id,
        ),
      ),
    );
  }

  void _navigateToClinic(String clinicId, {String? clinicNameAr, String? clinicNameEn}) {
    final clinic = ClinicModel(
      id: clinicId,
      nameAr: clinicNameAr ?? 'العيادة التجميلية',
      nameEn: clinicNameEn ?? 'Aesthetic Clinic',
      descriptionAr: '',
      descriptionEn: '',
      coverImageUrl: '',
      galleryImages: const [],
      logoUrl: '',
      rating: 0.0,
      reviewCount: 0,
      subscriptionTier: SubscriptionTier.basic,
      city: 'Dubai',
      areaAr: '',
      addressAr: '',
    );

    Navigator.push(
      context,
      LuxuryPageRoute(page: ClinicProfileScreen(clinic: clinic)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    final List<OfferModel> filteredOffers = (_offers ?? []).where((o) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return o.titleAr.toLowerCase().contains(q) ||
          o.titleEn.toLowerCase().contains(q) ||
          o.clinicNameAr.toLowerCase().contains(q) ||
          (o.clinicNameEn != null && o.clinicNameEn!.toLowerCase().contains(q));
    }).toList();

    return ListenableBuilder(
      listenable: loc,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Text(
              loc.tr('category_offers_title'),
              style: AppTypography.screenTitle.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                fontSize: 16,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _loadOffers,
            color: AppColors.accentChampagne,
            backgroundColor: AppColors.surface(context),
            child: Column(
              children: [
                // Search Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border(context), width: 0.8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: AppColors.text(context), fontSize: 13.5),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                      onSubmitted: (_) => _loadOffers(),
                      decoration: InputDecoration(
                        hintText: loc.isArabic ? 'ابحث في العروض التجميلية والعيادات...' : 'Search offers & clinics...',
                        hintStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                        prefixIcon: Icon(Icons.search_rounded, color: AppColors.mutedText(context), size: 18),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, size: 16, color: AppColors.mutedText(context)),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  _loadOffers();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),

                // Offers Content Area
                Expanded(
                  child: _isLoading && _offers == null
                      ? ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: 3,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) => const LuxuryShimmer(
                            width: double.infinity,
                            height: 240,
                            borderRadius: 16,
                          ),
                        )
                      : _errorMessage != null && _offers == null
                          ? LuxuryErrorView(
                              message: _errorMessage,
                              onRetry: _loadOffers,
                            )
                          : filteredOffers.isEmpty
                              ? Center(
                                  child: Text(
                                    loc.isArabic ? 'لا توجد عروض متاحة حالياً' : 'No offers currently available',
                                    style: TextStyle(color: AppColors.mutedText(context)),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                  itemCount: filteredOffers.length,
                                  itemBuilder: (context, index) {
                                    final offer = filteredOffers[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: LuxuryCard(
                                        padding: EdgeInsets.zero,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Offer Image & Discount Badge
                                            Stack(
                                              children: [
                                                LuxuryImage(
                                                  imageUrl: offer.imageUrl,
                                                  height: 160,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                                  placeholderIcon: Icons.local_offer_rounded,
                                                ),
                                                if (offer.discountPercentage > 0)
                                                  Positioned(
                                                    top: 12,
                                                    right: loc.isArabic ? 12 : null,
                                                    left: loc.isArabic ? null : 12,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.accentChampagne,
                                                        borderRadius: BorderRadius.circular(20),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withValues(alpha: 0.3),
                                                            blurRadius: 6,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        '${loc.tr("save_prefix")} ${offer.discountPercentage}%',
                                                        style: const TextStyle(
                                                          color: AppColors.backgroundDeep,
                                                          fontWeight: FontWeight.w900,
                                                          fontSize: 11.5,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),

                                            // Details Body
                                            Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Clinic Name Clickable Link
                                                  GestureDetector(
                                                    onTap: () => _navigateToClinic(
                                                      offer.clinicId,
                                                      clinicNameAr: offer.clinicNameAr,
                                                      clinicNameEn: offer.clinicNameEn,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.apartment_rounded, size: 14, color: AppColors.accentChampagne),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            loc.isArabic ? offer.clinicNameAr : (offer.clinicNameEn ?? offer.clinicNameAr),
                                                            style: const TextStyle(
                                                              color: AppColors.accentChampagne,
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w700,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),

                                                  // Title
                                                  Text(
                                                    loc.isArabic ? offer.titleAr : offer.titleEn,
                                                    style: AppTypography.cardTitle.copyWith(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w800,
                                                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),

                                                  // Terms / Description
                                                  Text(
                                                    (loc.isArabic ? offer.termsAr : offer.termsEn) ?? '',
                                                    style: AppTypography.bodyMedium.copyWith(
                                                      fontSize: 12,
                                                      color: AppColors.mutedText(context),
                                                      height: 1.45,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 12),

                                                  // Price & Action Row
                                                  Row(
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text(
                                                                '${offer.offerPrice.toInt()} ${loc.tr("currency_aed")}',
                                                                style: TextStyle(
                                                                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                                                  fontSize: 16,
                                                                  fontWeight: FontWeight.w900,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 8),
                                                              Text(
                                                                '${offer.originalPrice.toInt()} ${loc.tr("currency_aed")}',
                                                                style: TextStyle(
                                                                  color: AppColors.mutedText(context),
                                                                  fontSize: 12,
                                                                  decoration: TextDecoration.lineThrough,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            (loc.isArabic ? offer.validUntilText : (offer.validUntilTextEn ?? offer.validUntilText)),
                                                            style: const TextStyle(
                                                              color: AppColors.accentChampagne,
                                                              fontSize: 10.5,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const Spacer(),
                                                      SilverButton(
                                                        label: loc.tr('offer_claim'),
                                                        icon: Icons.send_rounded,
                                                        height: 38,
                                                        onPressed: () => _handleClaimOffer(offer),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
