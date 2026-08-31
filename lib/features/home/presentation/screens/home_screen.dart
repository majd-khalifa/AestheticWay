import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/data/mock_data.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinic_profile_screen.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinics_list_screen.dart';
import 'package:aesthetic_way/features/clinics/presentation/widgets/contact_options_sheet.dart';
import 'package:aesthetic_way/features/clinics/presentation/widgets/filter_bottom_sheet.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';
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
/// Reordered: 1) Header+Search, 2) Featured/VIP Carousel, 3) 8 Categories, 4) Offers, 5) Nearby Clinics
class HomeScreen extends StatefulWidget {
  final ValueChanged<String?>? onNavigateToClinics;

  const HomeScreen({super.key, this.onNavigateToClinics});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCity = 'الكل';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _handleFavoritesTap() async {
    final auth = await GuestAuthGuard.requireAuth(
      context,
      reasonTitle: LocaleService().tr('my_favs'),
      reasonSubtitle: LocaleService().isArabic
          ? 'سجّل دخولك لحفظ ومراجعة عياداتك المفضلة'
          : 'Login to save and access your favorite clinics',
    );
    if (!mounted) return;
    if (auth) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleService().isArabic ? 'تم فتح قائمة المفضلة بنجاح' : 'Favorites list opened'),
          backgroundColor: AppColors.surface(context),
        ),
      );
    }
  }

  void _handleContact(ClinicModel clinic) {
    ContactOptionsSheet.show(context, clinic);
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
    final mockData = MockDataService();
    final loc = LocaleService();

    return ListenableBuilder(
      listenable: loc,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          body: SafeArea(
            bottom: false,
            child: ListenableBuilder(
              listenable: mockData,
              builder: (context, _) {
                // Filter top carousel ads
                final topAds = mockData.topCarouselAds.where((c) {
                  final matchesCity = _selectedCity == 'الكل' || _selectedCity == 'All' ||
                      (_selectedCity.contains('دبي') || _selectedCity.contains('Dubai') ? c.city.toLowerCase() == 'dubai' : true) &&
                      (_selectedCity.contains('أبوظبي') || _selectedCity.contains('Abu Dhabi') ? c.city.toLowerCase() == 'abu dhabi' : true);
                  final matchesQuery = _searchQuery.isEmpty ||
                      c.nameAr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      c.nameEn.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      c.areaAr.toLowerCase().contains(_searchQuery.toLowerCase());
                  return matchesCity && matchesQuery;
                }).toList();

                final nearbyList = mockData.nearbyClinics.where((c) {
                  final matchesCity = _selectedCity == 'الكل' || _selectedCity == 'All' ||
                      (_selectedCity.contains('دبي') || _selectedCity.contains('Dubai') ? c.city.toLowerCase() == 'dubai' : true) &&
                      (_selectedCity.contains('أبوظبي') || _selectedCity.contains('Abu Dhabi') ? c.city.toLowerCase() == 'abu dhabi' : true);
                  final matchesQuery = _searchQuery.isEmpty ||
                      c.nameAr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      c.nameEn.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      c.areaAr.toLowerCase().contains(_searchQuery.toLowerCase());
                  return matchesCity && matchesQuery;
                }).toList();

                return CustomScrollView(
                  slivers: [
                    // 1. Header with Official Client Logo & City selector
                    SliverToBoxAdapter(
                      child: HomeHeader(
                        selectedCity: _selectedCity,
                        onCityChanged: (city) {
                          setState(() {
                            _selectedCity = city;
                          });
                        },
                        onFavoritesTap: _handleFavoritesTap,
                      ),
                    ),

                    // 2. Search Bar + Filter Trigger
                    SliverToBoxAdapter(
                      child: Padding(
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
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 6)),

                    // 3. Top Featured / Sponsored Clinics Carousel (VIP 1st, Featured 2nd)
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

                    // 5. Active Medical Offers Section (NOW ABOVE Nearby Clinics)
                    SliverToBoxAdapter(
                      child: ActiveOffersSection(
                        offers: mockData.offers,
                        onOfferTap: (offer) {
                          final clinic = mockData.getClinicById(offer.clinicId);
                          if (clinic != null) {
                            _navigateToClinicProfile(clinic);
                          }
                        },
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 18)),

                    // 6. Nearby Verified Clinics Section
                    SliverToBoxAdapter(
                      child: NearbyClinicsSection(
                        clinics: nearbyList,
                        onClinicTap: _navigateToClinicProfile,
                        onRequestTap: _handleAppointmentLeadRequest,
                        onContactTap: _handleContact,
                      ),
                    ),

                    // Extra bottom spacing to float cleanly above bottom nav bar
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
