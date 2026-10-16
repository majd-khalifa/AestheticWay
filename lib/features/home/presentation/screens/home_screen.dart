import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/widgets/luxury_shimmer.dart';
import 'package:aesthetic_way/core/widgets/luxury_error_view.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_loading_skeleton.dart';
import 'package:aesthetic_way/core/widgets/luxury_empty_state.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/clinics/data/clinics_repository.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinic_profile_screen.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinics_list_screen.dart';
import 'package:aesthetic_way/features/clinics/presentation/widgets/contact_options_sheet.dart';
import 'package:aesthetic_way/features/clinics/presentation/widgets/filter_bottom_sheet.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';
import 'package:aesthetic_way/features/home/data/home_repository.dart';
import 'package:aesthetic_way/features/home/data/models/home_feed_model.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/offers/presentation/screens/offers_screen.dart';
import 'package:aesthetic_way/features/treatments/presentation/screens/treatments_screen.dart';
import 'package:aesthetic_way/features/practitioners/presentation/screens/practitioners_screen.dart';
import 'package:aesthetic_way/features/products/presentation/screens/products_screen.dart';
import 'package:aesthetic_way/features/articles/presentation/screens/articles_screen.dart';
import '../widgets/home_header.dart';
import '../widgets/featured_ads_carousel.dart';
import '../widgets/category_grid.dart';
import '../widgets/nearby_clinics_section.dart';
import '../widgets/active_offers_section.dart';

/// Screen 2: Luxury Home & Discovery Feed
/// Powered by live API: GET /api/v1/home/feed/
class HomeScreen extends StatefulWidget {
  final ValueChanged<String?>? onNavigateToClinics;

  const HomeScreen({super.key, this.onNavigateToClinics});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeRepository _homeRepository = HomeRepository();
  final ClinicsRepository _clinicsRepository = ClinicsRepository();

  String _selectedCity = 'الكل';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  HomeFeedModel? _feed;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final feed = await _homeRepository.getHomeFeed(city: _selectedCity);
      if (mounted) {
        setState(() {
          _feed = feed;
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

  void _navigateToClinicProfile(ClinicModel clinic) {
    Navigator.push(
      context,
      LuxuryPageRoute(
        page: ClinicProfileScreen(clinic: clinic),
      ),
    );
  }

  Future<void> _handleAppointmentLeadRequest(ClinicModel clinic) async {
    final auth = await GuestAuthGuard.requireAuth(
      context,
      reasonTitle: LocaleService().tr('request_consultation'),
      reasonSubtitle: LocaleService().isArabic
          ? 'سجل دخولك برقم الهاتف لإرسال طلبك للعيادة'
          : 'Login with phone number to submit your lead',
    );
    if (!auth || !mounted) return;

    Navigator.push(
      context,
      LuxuryPageRoute(
        page: AppointmentRequestScreen(clinic: clinic),
      ),
    );
  }

  void _handleContact(ClinicModel clinic) {
    ContactOptionsSheet.show(context, clinic);
  }

  void _handleOfferTap(OfferModel offer) async {
    final existingClinic = _feed?.nearbyClinics.where((c) => c.id == offer.clinicId).firstOrNull;
    if (existingClinic != null) {
      _navigateToClinicProfile(existingClinic);
      return;
    }

    try {
      final clinic = await _clinicsRepository.getClinicDetail(offer.clinicId);
      if (mounted) {
        _navigateToClinicProfile(clinic);
      }
    } catch (_) {
      // Create minimal fallback clinic representation if detail fetch fails
      final fallbackClinic = ClinicModel(
        id: offer.clinicId,
        nameAr: offer.clinicNameAr,
        nameEn: offer.clinicNameEn ?? offer.clinicNameAr,
        descriptionAr: offer.termsAr,
        descriptionEn: offer.termsEn ?? '',
        coverImageUrl: offer.imageUrl,
        galleryImages: offer.imageUrl.isNotEmpty ? [offer.imageUrl] : [],
        logoUrl: offer.imageUrl,
        rating: 4.8,
        reviewCount: 0,
        subscriptionTier: SubscriptionTier.basic,
        licenseAuthority: 'DHA',
        licenseNumber: '',
        city: _selectedCity,
        areaAr: '',
        areaEn: '',
        addressAr: '',
        addressEn: '',
        distanceKm: 0.0,
        mainPhone: '',
        receptionPhone: '',
        whatsapp: '',
        workingHoursAr: '',
        workingHoursEn: '',
        branches: const [],
        practitionerIds: const [],
        treatmentIds: const [],
      );
      if (mounted) {
        _navigateToClinicProfile(fallbackClinic);
      }
    }
  }

  void _handleCategoryTap(CategoryItem category) {
    switch (category.id) {
      case 'offers':
        Navigator.push(context, LuxuryPageRoute(page: const OffersScreen()));
        break;
      case 'treatments':
        Navigator.push(context, LuxuryPageRoute(page: const TreatmentsScreen()));
        break;
      case 'doctors':
        Navigator.push(context, LuxuryPageRoute(page: const PractitionersScreen(initialRoleFilter: 'doctors')));
        break;
      case 'skin_experts':
        Navigator.push(context, LuxuryPageRoute(page: const PractitionersScreen(initialRoleFilter: 'skin_experts')));
        break;
      case 'surgery':
        Navigator.push(context, LuxuryPageRoute(page: const TreatmentsScreen(initialCategory: 'Plastic Surgery')));
        break;
      case 'products':
        Navigator.push(context, LuxuryPageRoute(page: const ProductsScreen()));
        break;
      case 'articles':
        Navigator.push(context, LuxuryPageRoute(page: const ArticlesScreen()));
        break;
      case 'clinics':
      default:
        if (widget.onNavigateToClinics != null) {
          widget.onNavigateToClinics!(null);
        } else {
          Navigator.push(
            context,
            LuxuryPageRoute(
              page: ClinicsListScreen(
                initialCity: _selectedCity,
              ),
            ),
          );
        }
        break;
    }
  }

  void _openFilterSheet() {
    FilterBottomSheet.show(
      context: context,
      currentFilters: ClinicFilterOptions(selectedCity: _selectedCity),
      onApply: (filters) {
        Navigator.push(
          context,
          LuxuryPageRoute(
            page: ClinicsListScreen(
              initialCity: filters.selectedCity,
              initialCategory: filters.selectedSpecialtyId,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();

    return ListenableBuilder(
      listenable: loc,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          body: SafeArea(
            bottom: false,
            child: LuxuryRefreshIndicator(
              onRefresh: _loadFeed,
              child: _buildBody(context, loc),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, LocaleService loc) {
    // 1. Loading State
    if (_isLoading && _feed == null) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: HomeHeader(
              selectedCity: _selectedCity,
              onCityChanged: (city) {
                setState(() {
                  _selectedCity = city;
                });
                _loadFeed();
              },
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSearchBar(context, loc),
          ),
          const SliverToBoxAdapter(
            child: HomeFeedSkeleton(),
          ),
        ],
      );
    }

    // 2. Error State
    if (_errorMessage != null && _feed == null) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: HomeHeader(
              selectedCity: _selectedCity,
              onCityChanged: (city) {
                setState(() {
                  _selectedCity = city;
                });
                _loadFeed();
              },
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: LuxuryErrorView(
              onRetry: _loadFeed,
            ),
          ),
        ],
      );
    }

    // 3. Success State
    final feed = _feed!;
    final allClinics = feed.nearbyClinics;

    // Carousel: Featured/VIP clinics first
    List<ClinicModel> topAds = allClinics.where((c) => c.isEligibleForTopCarousel).toList();
    if (topAds.isEmpty && allClinics.isNotEmpty) {
      topAds = allClinics.take(3).toList();
    }

    // Filter by search query if user typed something
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      topAds = topAds.where((c) {
        return c.nameAr.toLowerCase().contains(q) ||
            c.nameEn.toLowerCase().contains(q) ||
            c.areaAr.toLowerCase().contains(q) ||
            c.areaEn.toLowerCase().contains(q);
      }).toList();
    }

    // Filter nearby list
    List<ClinicModel> nearbyList = allClinics;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      nearbyList = nearbyList.where((c) {
        return c.nameAr.toLowerCase().contains(q) ||
            c.nameEn.toLowerCase().contains(q) ||
            c.areaAr.toLowerCase().contains(q) ||
            c.areaEn.toLowerCase().contains(q);
      }).toList();
    }

    // Filter offers
    List<OfferModel> offersList = feed.activeOffers;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      offersList = offersList.where((o) {
        return o.titleAr.toLowerCase().contains(q) ||
            o.titleEn.toLowerCase().contains(q) ||
            o.clinicNameAr.toLowerCase().contains(q) ||
            (o.clinicNameEn?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // 1. Header with Official Client Logo & City selector
        SliverToBoxAdapter(
          child: HomeHeader(
            selectedCity: _selectedCity,
            onCityChanged: (city) {
              setState(() {
                _selectedCity = city;
              });
              _loadFeed();
            },
          ),
        ),

        // 2. Search Bar + Filter Trigger
        SliverToBoxAdapter(
          child: _buildSearchBar(context, loc),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 6)),

        // 3. Top Featured / Sponsored Clinics Carousel
        if (topAds.isNotEmpty)
          SliverToBoxAdapter(
            child: FeaturedAdsCarousel(
              ads: topAds,
              onClinicTap: _navigateToClinicProfile,
              onRequestAppointmentTap: _handleAppointmentLeadRequest,
              onContactTap: _handleContact,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 18)),

        // 4. Categories Quick Access Grid (8 Official Categories)
        SliverToBoxAdapter(
          child: CategoryGrid(
            onCategorySelected: _handleCategoryTap,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 18)),

        // 5. Active Medical Offers Section
        if (offersList.isNotEmpty)
          SliverToBoxAdapter(
            child: ActiveOffersSection(
              offers: offersList,
              onOfferTap: _handleOfferTap,
            ),
          ),

        if (offersList.isNotEmpty) const SliverToBoxAdapter(child: SizedBox(height: 18)),

        // 6. Nearby Verified Clinics Section
        if (nearbyList.isNotEmpty)
          SliverToBoxAdapter(
            child: NearbyClinicsSection(
              clinics: nearbyList,
              onClinicTap: _navigateToClinicProfile,
              onRequestTap: _handleAppointmentLeadRequest,
              onContactTap: _handleContact,
            ),
          ),

        // Empty state when catalog is empty
        if (topAds.isEmpty && offersList.isEmpty && nearbyList.isEmpty)
          SliverToBoxAdapter(
            child: LuxuryEmptyState(
              icon: Icons.apartment_rounded,
              title: loc.isArabic ? 'لا توجد عيادات متاحة حالياً' : 'No clinics available right now',
              subtitle: loc.isArabic
                  ? 'سيتم إضافة عيادات وأطباء جدد قريباً في هذا النطاق الجغرافي'
                  : 'New clinics and doctors will be listed soon in this area',
              actionLabel: loc.isArabic ? 'تحديث' : 'Refresh',
              onAction: _loadFeed,
            ),
          ),

        // Extra bottom spacing to float cleanly above bottom nav bar
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, LocaleService loc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.border(context),
                  width: 0.8,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: AppColors.text(context), fontSize: 13.5),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: loc.tr('search_hint'),
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.mutedText(context),
                    fontSize: 12,
                  ),
                  prefixIcon: Icon(Icons.search, color: AppColors.subtext(context), size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 16, color: AppColors.mutedText(context)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _openFilterSheet,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.border(context),
                  width: 0.8,
                ),
              ),
              child: const Center(
                child: Icon(Icons.tune_rounded, size: 18, color: AppColors.accentChampagne),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
