import '../../../clinics/presentation/screens/clinics_list_screen.dart';
import '../../../locations/presentation/home_location_panel.dart';
import '../../../locations/services/patient_location_controller.dart';
import 'package:aesthetic_way/core/theme/patient_design.dart';
import '../../../../core/widgets/async_action_button.dart';
import '../../../offers/presentation/offer_actions.dart';
import 'dart:async';
import 'package:aesthetic_way/core/data/single_flight.dart';
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
  final ValueChanged<int>? onNavigateToTab;
  final HomeRepository? repository;

  const HomeScreen({
    super.key,
    this.onNavigateToClinics,
    this.onNavigateToTab,
    this.repository,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final PatientLocationController _location = PatientLocationController();
  int _locationSession = AuthState().sessionEpoch;
  void _locationChanged() {
    final epoch = AuthState().sessionEpoch;
    if (_selectedCity == _location.city && _locationSession == epoch) {
      if (mounted) setState(() {});
      return;
    }
    _locationSession = epoch;
    _cityChanged(_location.city);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _location.releasePosition();
  }

  late final HomeRepository _homeRepository =
      widget.repository ?? HomeRepository();
  final ClinicsRepository _clinicsRepository = ClinicsRepository();

  String _selectedCity = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final _feedFlights = SingleFlight();
  int _feedRequestId = 0;
  Timer? _cityDebounce, _searchDebounce;
  void _cityChanged(String city) {
    _cityDebounce?.cancel();
    ++_feedRequestId;
    _feedFlights.clear();
    if (!mounted) return;
    setState(() {
      _selectedCity = city;
      _isLoading = true;
      // A different city must not continue displaying the old city's records.
      _feed = null;
    });
    _cityDebounce = Timer(const Duration(milliseconds: 350), _loadFeed);
  }

  void _searchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _searchQuery = text.trim());
    });
  }

  HomeFeedModel? _feed;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _location.addListener(_locationChanged);
    _loadFeed();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _location.removeListener(_locationChanged);
    _location.dispose();
    ++_feedRequestId;
    _cityDebounce?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    final city = _selectedCity;
    final requestId = ++_feedRequestId;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final feed = await _feedFlights.run(
        city,
        () => _homeRepository.getHomeFeed(city: city),
      );
      if (mounted && requestId == _feedRequestId) {
        setState(() {
          _feed = feed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && requestId == _feedRequestId) {
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
      LuxuryPageRoute(page: ClinicProfileScreen(clinic: clinic)),
    );
  }

  Future<void> _handleAppointmentLeadRequest(
    ClinicModel clinic,
    AsyncActionScope action,
  ) async {
    final auth = await action.wait(
      GuestAuthGuard.requireAuth(
        context,
        reasonTitle: LocaleService().tr('request_consultation'),
        reasonSubtitle: LocaleService().isArabic
            ? 'سجل دخولك برقم الهاتف لإرسال طلبك للعيادة'
            : 'Login with phone number to submit your lead',
      ),
    );
    if (!auth || !mounted) return;

    Navigator.push(
      context,
      LuxuryPageRoute(page: AppointmentRequestScreen(clinic: clinic)),
    );
  }

  void _handleContact(ClinicModel clinic) {
    ContactOptionsSheet.show(context, clinic);
  }

  Future<void> _handleOfferTap(OfferModel offer, AsyncActionScope action) =>
      openOfferClinic(
        context,
        offer,
        action,
        _clinicsRepository,
        inquire: true,
      );

  void _handleCategoryTap(CategoryItem category) {
    switch (category.id) {
      case 'offers':
        if (widget.onNavigateToTab != null) {
          widget.onNavigateToTab!(3);
          return;
        }
        Navigator.push(context, LuxuryPageRoute(page: const OffersScreen()));
        break;
      case 'treatments':
        Navigator.push(
          context,
          LuxuryPageRoute(page: const TreatmentsScreen()),
        );
        break;
      case 'doctors':
        Navigator.push(
          context,
          LuxuryPageRoute(
            page: const PractitionersScreen(initialRoleFilter: 'doctors'),
          ),
        );
        break;
      case 'skin_experts':
        Navigator.push(
          context,
          LuxuryPageRoute(
            page: const PractitionersScreen(initialRoleFilter: 'skin_experts'),
          ),
        );
        break;
      case 'surgery':
        Navigator.push(
          context,
          LuxuryPageRoute(
            page: const TreatmentsScreen(initialCategory: 'Plastic Surgery'),
          ),
        );
        break;
      case 'products':
        if (widget.onNavigateToTab != null) {
          widget.onNavigateToTab!(2);
          return;
        }
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
              page: ClinicsListScreen(initialCity: _selectedCity),
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
  Widget build(BuildContext context) => PatientDesign(builder: _buildPatient);

  Widget _buildPatient(BuildContext context) {
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
              onCityChanged: _location.selectCity,
              selectedAreaCode: _location.areaCode,
              onLocalityChanged: _location.selectLocality,
            ),
          ),
          SliverToBoxAdapter(child: _buildSearchBar(context, loc)),
          const SliverToBoxAdapter(child: HomeFeedSkeleton()),
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
              onCityChanged: _location.selectCity,
              selectedAreaCode: _location.areaCode,
              onLocalityChanged: _location.selectLocality,
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: LuxuryErrorView(onRetry: _loadFeed),
          ),
        ],
      );
    }

    // 3. Success State
    final feed = _feed!;
    final allClinics = feed.nearbyClinics;

    final partners = feed.premiumPartners;
    final topAds = partners.map((partner) => partner.clinic).toList();
    final nearbyList = allClinics;
    final offersList = feed.activeOffers;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // 1. Header with Official Client Logo & City selector
        SliverToBoxAdapter(
          child: HomeHeader(
            selectedCity: _selectedCity,
            onCityChanged: _location.selectCity,
            selectedAreaCode: _location.areaCode,
            onLocalityChanged: _location.selectLocality,
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.isArabic
                      ? 'عناية جمالية تليق بك'
                      : 'Aesthetic Care, for You',
                  style: PatientDesign.heading(context, size: 27),
                ),
              ],
            ),
          ),
        ),

        // 2. Search Bar + Filter Trigger
        SliverToBoxAdapter(child: _buildSearchBar(context, loc)),

        const SliverToBoxAdapter(child: SizedBox(height: 6)),

        // 3. Top Featured / Sponsored Clinics Carousel
        if (topAds.isNotEmpty)
          SliverToBoxAdapter(
            child: FeaturedAdsCarousel(
              ads: topAds,
              placements: partners.map((partner) => partner.placement).toList(),
              onClinicTap: _navigateToClinicProfile,
              onRequestAction: _handleAppointmentLeadRequest,
              onContactTap: _handleContact,
            ),
          ),

        if (feed.partnerDirectoryUnavailable)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextButton.icon(
                onPressed: _loadFeed,
                icon: const Icon(Icons.refresh),
                label: Text(
                  loc.isArabic
                      ? 'تعذر تحميل العيادات الشريكة، حاول مجدداً'
                      : 'Partner clinics could not load. Try again',
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        SliverToBoxAdapter(child: HomeLocationPanel(controller: _location)),

        // 4. Categories Quick Access Grid (8 Official Categories)
        SliverToBoxAdapter(
          child: CategoryGrid(onCategorySelected: _handleCategoryTap),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // 5. Active Medical Offers Section
        if (offersList.isNotEmpty)
          SliverToBoxAdapter(
            child: ActiveOffersSection(
              offers: offersList,
              onOfferAction: _handleOfferTap,
            ),
          ),

        if (offersList.isNotEmpty)
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // 6. Nearby Verified Clinics Section
        if (nearbyList.isNotEmpty)
          SliverToBoxAdapter(
            child: NearbyClinicsSection(
              clinics: nearbyList,
              city: _selectedCity,
              onSeeAll: () => Navigator.push(
                context,
                LuxuryPageRoute(
                  page: ClinicsListScreen(initialCity: _selectedCity),
                ),
              ),
              onClinicTap: _navigateToClinicProfile,
              onRequestAction: _handleAppointmentLeadRequest,
              onContactTap: _handleContact,
            ),
          ),

        // Empty state when catalog is empty
        if (topAds.isEmpty && offersList.isEmpty && nearbyList.isEmpty)
          SliverToBoxAdapter(
            child: LuxuryEmptyState(
              icon: Icons.apartment_rounded,
              title: loc.isArabic
                  ? 'لا توجد عيادات متاحة حالياً'
                  : 'No clinics available right now',
              subtitle: loc.isArabic
                  ? 'سيتم إضافة عيادات وأطباء جدد قريباً في هذا النطاق الجغرافي'
                  : 'New clinics and doctors will be listed soon in this area',
              actionLabel: loc.isArabic ? 'تحديث' : 'Refresh',
              onAction: _loadFeed,
            ),
          ),

        // Extra bottom spacing to float cleanly above bottom nav bar
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
              height: 52,
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
                textInputAction: TextInputAction.search,
                onSubmitted: (value) => Navigator.push(
                  context,
                  LuxuryPageRoute(
                    page: ClinicsListScreen(
                      initialCity: _selectedCity,
                      initialSearch: value,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: AppColors.text(context),
                  fontSize: 13.5,
                ),
                onChanged: _searchChanged,
                decoration: InputDecoration(
                  hintText: loc.isArabic
                      ? 'ابحث في دليل العيادات'
                      : 'Search the clinic directory',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.text(context),
                    fontSize: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.subtext(context),
                    size: 18,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: 16,
                            color: AppColors.mutedText(context),
                          ),
                          onPressed: () {
                            _searchDebounce?.cancel();
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
              height: 52,
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
                child: Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: AppColors.accentChampagne,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
