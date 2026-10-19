import '../../../../core/data/paged_collection.dart';
import '../../../../core/widgets/pagination_footer.dart';
import '../../../../core/widgets/bounded_catalog_preview.dart';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/practitioner_badge.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/utils/maps_launcher.dart';
import 'package:aesthetic_way/core/utils/contact_launcher.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/clinics/data/clinics_repository.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/offers/data/offers_repository.dart';
import 'package:aesthetic_way/features/practitioners/data/practitioners_repository.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/practitioners/presentation/screens/practitioner_profile_screen.dart';
import 'package:aesthetic_way/features/treatments/data/treatments_repository.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';

/// Clinic Profile Screen with Google Maps, Staff Badges, Treatments & Lead CTAs (Fully Bilingual)
class ClinicProfileScreen extends StatefulWidget {
  final ClinicModel clinic;

  const ClinicProfileScreen({super.key, required this.clinic});

  @override
  State<ClinicProfileScreen> createState() => _ClinicProfileScreenState();
}

class _ClinicProfileScreenState extends State<ClinicProfileScreen>
    with SingleTickerProviderStateMixin {
  final ClinicsRepository _clinicsRepository = ClinicsRepository();
  final OffersRepository _offersRepository = OffersRepository();
  final PractitionersRepository _practitionersRepository =
      PractitionersRepository();
  final TreatmentsRepository _treatmentsRepository = TreatmentsRepository();

  late ClinicModel _clinic;
  late final PagedCollection<ClinicBranch> _branchPage;
  late final PagedCollection<PractitionerModel> _staffPage;
  late final PagedCollection<TreatmentModel> _treatmentPage;
  late final PagedCollection<OfferModel> _offerPage;
  List<PractitionerModel> get _practitioners => _staffPage.items;
  List<TreatmentModel> get _treatments => _treatmentPage.items;
  List<OfferModel> get _offers => _offerPage.items;
  void _catalogChanged() {
    if (mounted) setState(() {});
  }

  void _tabChanged() {
    switch (_tabController.index) {
      case 1:
        _staffPage.refresh(force: false);
      case 2:
        _treatmentPage.refresh(force: false);
      case 3:
        _offerPage.refresh(force: false);
    }
  }

  bool _isLoading = true;

  late TabController _tabController;
  final PageController _galleryController = PageController();
  int _currentGalleryIndex = 0;

  @override
  void initState() {
    super.initState();
    _clinic = widget.clinic;
    _branchPage = PagedCollection<ClinicBranch>(
      items: _clinic.branches.take(6).toList(),
      keyOf: (b) => b.id,
      loader: (page, _) async {
        if (_clinic.hasBranchDirectory) {
          return _clinicsRepository.getBranches(_clinic.id, page: page);
        }
        return PageItems(
          _clinic.branches
              .skip((page - 1) * catalogPageSize)
              .take(catalogPageSize),
          hasMore: page * catalogPageSize < _clinic.branches.length,
          total: _clinic.branches.length,
        );
      },
    )..addListener(_catalogChanged);
    _branchPage.hasMore =
        _clinic.hasBranchDirectory || _clinic.branches.length > 6;
    _staffPage = PagedCollection<PractitionerModel>(
      loader: (page, _) => _practitionersRepository.getPractitioners(
        clinicId: widget.clinic.id,
        page: page,
      ),
      keyOf: (item) => item.id,
    )..addListener(_catalogChanged);
    _treatmentPage = PagedCollection<TreatmentModel>(
      loader: (page, _) => _treatmentsRepository.getTreatments(
        clinic: widget.clinic.id,
        page: page,
      ),
      keyOf: (item) => item.id,
    )..addListener(_catalogChanged);
    _offerPage = PagedCollection<OfferModel>(
      loader: (page, _) =>
          _offersRepository.getOffers(clinicId: widget.clinic.id, page: page),
      keyOf: (item) => item.id,
    )..addListener(_catalogChanged);
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_tabChanged);
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final fullClinic = await _clinicsRepository.getClinicDetail(
        widget.clinic.id,
      );
      if (!mounted) return;
      setState(() {
        _clinic = fullClinic;
        _isLoading = false;
        _branchPage.items
          ..clear()
          ..addAll(fullClinic.branches.take(6));
        _branchPage.hasMore =
            fullClinic.hasBranchDirectory || fullClinic.branches.length > 6;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_tabChanged);
    _tabController.dispose();
    _branchPage.dispose();
    _staffPage.dispose();
    _treatmentPage.dispose();
    _offerPage.dispose();
    _galleryController.dispose();
    super.dispose();
  }

  void _handleAppointmentRequest({PractitionerModel? practitioner}) async {
    final loc = LocaleService();
    final auth = await GuestAuthGuard.requireAuth(
      context,
      reasonTitle: loc.tr('request_consultation'),
      reasonSubtitle: loc.isArabic
          ? 'سجّل دخولك لمتابعة إرسال طلب الموعد إلى العيادة'
          : 'Login to submit your consultation request to the clinic',
    );

    if (!auth || !mounted) return;

    Navigator.push(
      context,
      LuxuryPageRoute(
        page: AppointmentRequestScreen(
          clinic: _clinic,
          preselectedPractitioner: practitioner,
        ),
      ),
    );
  }

  void _handlePractitionerTap(PractitionerModel practitioner) {
    Navigator.push(
      context,
      LuxuryPageRoute(
        page: PractitionerProfileScreen(practitioner: practitioner),
      ),
    );
  }

  Widget _buildGoogleRatingBadge(
    BuildContext context,
    ClinicModel clinic,
    LocaleService loc,
  ) {
    final isDark = AppColors.isDark(context);
    final hasRating =
        clinic.googleRating > 0.0 || clinic.googleReviewsCount > 0;

    final ratingText = hasRating
        ? '${clinic.googleRating.toStringAsFixed(1)} ★ (${clinic.googleReviewsCount} ${loc.isArabic ? "تقييم Google" : "Google reviews"})'
        : (loc.isArabic ? 'جديد على خرائط Google' : 'New on Google Maps');

    final linkIndicatorText = loc.isArabic
        ? 'اعرض على خرائط Google'
        : 'View on Google Maps';

    return InkWell(
      onTap: () {
        if (clinic.hasMapLocation) {
          MapsLauncher.openMapLocation(
            latitude: clinic.latitude,
            longitude: clinic.longitude,
            googleMapsUrl: clinic.googleMapsUrl,
            placeId: clinic.googlePlaceId,
            placeName: loc.isArabic ? clinic.nameAr : clinic.nameEn,
          );
        } else {
          AppSnackBar.show(
            context,
            loc.isArabic
                ? 'موقع الخريطة غير متوفر لهذه العيادة'
                : 'Map location is not available for this clinic',
            type: AppSnackBarType.info,
          );
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? AppColors.accentChampagne.withValues(alpha: 0.35)
                : const Color(0xFFCBD5E1),
            width: 0.8,
          ),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasRating ? Icons.star_rounded : Icons.location_on_outlined,
                  size: 15,
                  color: AppColors.accentChampagne,
                ),
                const SizedBox(width: 4),
                Text(
                  ratingText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.silverPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mutedText(context),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  linkIndicatorText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldText(context),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.open_in_new_rounded,
                  size: 11,
                  color: AppColors.accentChampagne,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinic = _clinic;
    final validImages = {
      if (resolveImageProvider(clinic.coverImageUrl) != null)
        clinic.coverImageUrl.trim(),
      ...clinic.galleryImages
          .where((img) => resolveImageProvider(img) != null)
          .map((img) => img.trim()),
    }.toList();
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    return ListenableBuilder(
      listenable: loc,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // Luxury Hero Media Bar (No favorite/heart icon per client spec)
                SliverAppBar(
                  expandedHeight: 240,
                  pinned: true,
                  backgroundColor: AppColors.bg(context),
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.silverPrimary,
                        size: 18,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (validImages.isEmpty)
                          LuxuryImage(
                            imageUrl: null,
                            fallbackLogoUrl: clinic.logoUrl,
                            fit: BoxFit.cover,
                            placeholderIcon: Icons.local_hospital_outlined,
                          )
                        else
                          PageView.builder(
                            controller: _galleryController,
                            itemCount: validImages.length,
                            onPageChanged: (idx) {
                              setState(() {
                                _currentGalleryIndex = idx;
                              });
                            },
                            itemBuilder: (context, index) {
                              return LuxuryImage(
                                imageUrl: validImages[index],
                                fallbackLogoUrl: clinic.logoUrl,
                                fit: BoxFit.cover,
                                placeholderIcon: Icons.local_hospital_outlined,
                              );
                            },
                          ),
                        // Gradient overlay blending cleanly with active theme background
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.45),
                                Colors.transparent,
                                AppColors.bg(context),
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                        ),
                        // Gallery dots indicator
                        if (validImages.length > 1)
                          Positioned(
                            bottom: 12,
                            right: 0,
                            left: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                validImages.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2.5,
                                  ),
                                  width: _currentGalleryIndex == index ? 16 : 5,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    color: _currentGalleryIndex == index
                                        ? AppColors.accentChampagne
                                        : AppColors.silverBorder.withValues(
                                            alpha: 0.35,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Clinic Information Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsetsDirectional.only(end: 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accentChampagne.withValues(
                                    alpha: 0.4,
                                  ),
                                  width: 1.2,
                                ),
                              ),
                              child: LuxuryAvatar(
                                imageUrl: clinic.logoUrl,
                                fallbackLogoUrl: clinic.logoUrl,
                                radius: 26,
                                fallbackIcon: Icons.local_hospital_outlined,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.isArabic
                                        ? clinic.nameAr
                                        : clinic.nameEn,
                                    style: AppTypography.heroTitle.copyWith(
                                      fontSize: 20,
                                      color: AppColors.text(context),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    loc.isArabic
                                        ? clinic.nameEn
                                        : clinic.nameAr,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.subtext(context),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Sleek High-Contrast Google Maps Rating Badge
                                  _buildGoogleRatingBadge(context, clinic, loc),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Quick Action Buttons (Google Maps / Call / WhatsApp)
                        Row(
                          children: [
                            // Google Maps Action
                            Expanded(
                              child: Opacity(
                                opacity: clinic.hasMapLocation ? 1.0 : 0.45,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    if (clinic.hasMapLocation) {
                                      MapsLauncher.openMapLocation(
                                        latitude: clinic.latitude,
                                        longitude: clinic.longitude,
                                        googleMapsUrl: clinic.googleMapsUrl,
                                        placeId: clinic.googlePlaceId,
                                        placeName: loc.isArabic
                                            ? clinic.nameAr
                                            : clinic.nameEn,
                                      );
                                    } else {
                                      AppSnackBar.show(
                                        context,
                                        loc.isArabic
                                            ? 'موقع الخريطة غير متوفر لهذه العيادة'
                                            : 'Map location is not available for this clinic',
                                        type: AppSnackBarType.info,
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    Icons.map_outlined,
                                    size: 14,
                                    color: AppColors.subtext(context),
                                  ),
                                  label: Text(
                                    loc.tr('map_google'),
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.text(context),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppColors.border(context),
                                      width: 0.8,
                                    ),
                                    backgroundColor: AppColors.surface(context),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 9,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Direct Call Action
                            Expanded(
                              child: Opacity(
                                opacity: clinic.hasPhone ? 1.0 : 0.45,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    if (clinic.hasPhone) {
                                      ContactLauncher.makePhoneCall(
                                        clinic.effectivePhone,
                                      );
                                    } else {
                                      AppSnackBar.show(
                                        context,
                                        loc.isArabic
                                            ? 'رقم الهاتف غير متوفر لهذه العيادة'
                                            : 'Phone number is not available for this clinic',
                                        type: AppSnackBarType.info,
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    Icons.phone_outlined,
                                    size: 14,
                                    color: AppColors.subtext(context),
                                  ),
                                  label: Text(
                                    loc.tr('call_btn'),
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.text(context),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppColors.border(context),
                                      width: 0.8,
                                    ),
                                    backgroundColor: AppColors.surface(context),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 9,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // WhatsApp Action
                            Expanded(
                              child: Opacity(
                                opacity: clinic.hasWhatsapp ? 1.0 : 0.45,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    if (clinic.hasWhatsapp) {
                                      ContactLauncher.openWhatsApp(
                                        phoneNumber: clinic.whatsapp,
                                      );
                                    } else {
                                      AppSnackBar.show(
                                        context,
                                        loc.isArabic
                                            ? 'رقم الواتساب غير متوفر لهذه العيادة'
                                            : 'WhatsApp is not available for this clinic',
                                        type: AppSnackBarType.info,
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 14,
                                    color: Color(0xFF059669),
                                  ),
                                  label: Text(
                                    loc.tr('whatsapp_btn'),
                                    style: AppTypography.caption.copyWith(
                                      color: const Color(0xFF059669),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.45),
                                      width: 0.8,
                                    ),
                                    backgroundColor: AppColors.surface(context),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 9,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Primary Button: Appointment Request (Lead only)
                        SilverButton(
                          label: loc.tr('request_consultation'),
                          icon: Icons.calendar_month_outlined,
                          isFullWidth: true,
                          height: 46,
                          onPressed: () => _handleAppointmentRequest(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tab Bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: AppColors.accentChampagne,
                      labelColor: isDark
                          ? AppColors.accentChampagne
                          : AppColors.lightTextPrimary,
                      unselectedLabelColor: AppColors.subtext(context),
                      indicatorWeight: 2.5,
                      labelStyle: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      unselectedLabelStyle: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: [
                        Tab(text: loc.tr('tab_about')),
                        Tab(
                          text:
                              '${loc.tr("tab_staff")} (${_practitioners.length})',
                        ),
                        Tab(
                          text:
                              '${loc.tr("tab_treatments")} (${_treatments.length})',
                        ),
                        Tab(
                          text: '${loc.tr("tab_offers")} (${_offers.length})',
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLoading)
                  const SliverToBoxAdapter(
                    child: LinearProgressIndicator(
                      color: AppColors.accentChampagne,
                      backgroundColor: Colors.transparent,
                      minHeight: 2,
                    ),
                  ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _AboutAndLocationTab(
                  clinic: clinic,
                  loc: loc,
                  branches: _branchPage,
                ),
                _StaffTab(
                  page: _staffPage,
                  practitioners: _practitioners,
                  isLoading: _staffPage.isLoading,
                  loc: loc,
                  onPractitionerTap: _handlePractitionerTap,
                  onRequestWithPractitioner: (p) =>
                      _handleAppointmentRequest(practitioner: p),
                ),
                _TreatmentsTab(
                  page: _treatmentPage,
                  treatments: _treatments,
                  isLoading: _treatmentPage.isLoading,
                  loc: loc,
                  onRequestTreatment: () => _handleAppointmentRequest(),
                ),
                _OffersTab(
                  page: _offerPage,
                  offers: _offers,
                  isLoading: _offerPage.isLoading,
                  loc: loc,
                  clinicLogoUrl: clinic.logoUrl,
                  onRequestOffer: () => _handleAppointmentRequest(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------
// TAB 1: About & Google Maps
// -------------------------------------------------------------
class _AboutAndLocationTab extends StatelessWidget {
  final ClinicModel clinic;
  final LocaleService loc;

  final PagedCollection<ClinicBranch> branches;
  const _AboutAndLocationTab({
    required this.clinic,
    required this.loc,
    required this.branches,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      children: [
        // About Section
        LuxuryCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.tr('about_clinic'),
                style: AppTypography.cardTitle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.isArabic ? clinic.descriptionAr : clinic.descriptionEn,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.subtext(context),
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: AppColors.subtext(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('working_hours'),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.text(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.isArabic
                              ? clinic.workingHoursAr
                              : clinic.workingHoursEn,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.subtext(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Google Maps & Directions Card
        LuxuryCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_pin,
                        color: AppColors.accentChampagne,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        loc.tr('geo_location'),
                        style: AppTypography.cardTitle.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.text(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                loc.isArabic ? clinic.addressAr : clinic.addressEn,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.text(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              // Interactive Map Preview Box
              Container(
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHover(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.border(context),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.bg(context),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accentChampagne,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.accentChampagne,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        loc.isArabic ? clinic.nameAr : clinic.nameEn,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.text(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (clinic.hasMapLocation) {
                          MapsLauncher.openDirections(
                            latitude: clinic.latitude,
                            longitude: clinic.longitude,
                            googleMapsUrl: clinic.googleMapsUrl,
                            destinationTitle: loc.isArabic
                                ? clinic.nameAr
                                : clinic.nameEn,
                          );
                        } else {
                          AppSnackBar.show(
                            context,
                            loc.isArabic
                                ? 'موقع الخريطة غير متوفر لهذه العيادة'
                                : 'Map location is not available for this clinic',
                            type: AppSnackBarType.info,
                          );
                        }
                      },
                      icon: Icon(
                        Icons.directions,
                        size: 15,
                        color: AppColors.subtext(context),
                      ),
                      label: Text(
                        loc.tr('directions'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text(context),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.border(context),
                          width: 0.8,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (clinic.hasMapLocation) {
                          MapsLauncher.openMapLocation(
                            latitude: clinic.latitude,
                            longitude: clinic.longitude,
                            googleMapsUrl: clinic.googleMapsUrl,
                            placeId: clinic.googlePlaceId,
                            placeName: loc.isArabic
                                ? clinic.nameAr
                                : clinic.nameEn,
                          );
                        } else {
                          AppSnackBar.show(
                            context,
                            loc.isArabic
                                ? 'موقع الخريطة غير متوفر لهذه العيادة'
                                : 'Map location is not available for this clinic',
                            type: AppSnackBarType.info,
                          );
                        }
                      },
                      icon: Icon(
                        Icons.open_in_new,
                        size: 15,
                        color: isDark ? AppColors.backgroundDeep : Colors.white,
                      ),
                      label: Text(
                        loc.tr('open_in_maps'),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.backgroundDeep
                              : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.silverPrimary
                            : AppColors.lightTextPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Clinic Branches (if any)
        if (clinic.branches.isNotEmpty) ...[
          Text(
            loc.tr('branches_in_uae'),
            style: AppTypography.cardTitle.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 8),
          BoundedCatalogPreview<ClinicBranch>(
            items: () => branches.items,
            listenable: branches,
            page: branches,
            itemBuilder: (context, b) => _BranchTile(
              branch: b,
              clinicName: loc.isArabic ? clinic.nameAr : clinic.nameEn,
              loc: loc,
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _BranchTile extends StatelessWidget {
  final ClinicBranch branch;
  final String clinicName;
  final LocaleService loc;

  const _BranchTile({
    required this.branch,
    required this.clinicName,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return LuxuryCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.isArabic ? branch.nameAr : branch.nameEn,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.isArabic ? branch.addressAr : branch.addressEn,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.subtext(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.directions,
              color: AppColors.subtext(context),
              size: 18,
            ),
            onPressed: () {
              MapsLauncher.openDirections(
                latitude: branch.latitude,
                longitude: branch.longitude,
                destinationTitle:
                    '$clinicName - ${loc.isArabic ? branch.nameAr : branch.nameEn}',
              );
            },
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 2: Medical Staff & Practitioners
// -------------------------------------------------------------
class _StaffTab extends StatelessWidget {
  final PagedCollection<dynamic> page;
  final List<PractitionerModel> practitioners;
  final bool isLoading;
  final LocaleService loc;
  final ValueChanged<PractitionerModel> onPractitionerTap;
  final ValueChanged<PractitionerModel> onRequestWithPractitioner;

  const _StaffTab({
    required this.page,
    required this.practitioners,
    required this.isLoading,
    required this.loc,
    required this.onPractitionerTap,
    required this.onRequestWithPractitioner,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    if (isLoading && practitioners.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentChampagne),
      );
    }

    if (practitioners.isEmpty) {
      return Center(
        child: Text(
          loc.isArabic
              ? 'لا يوجد ممارسون مدرجون حالياً'
              : 'No practitioners listed currently',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.subtext(context),
          ),
        ),
      );
    }

    return PagedScrollBoundary(
      onLoadMore: page.loadMore,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
        itemCount: practitioners.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= practitioners.length) {
            return PaginationFooter(
              loading: page.isLoadingMore,
              hasMore: page.hasMore,
              error: page.error,
              onLoadMore: page.loadMore,
            );
          }
          final p = practitioners[index];
          return LuxuryCard(
            onTap: () => onPractitionerTap(p),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LuxuryAvatar(
                      imageUrl: p.avatarUrl,
                      fallbackLogoUrl: p.clinicLogoUrl,
                      radius: 26,
                      fallbackIcon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.isArabic ? p.nameAr : p.nameEn,
                            style: AppTypography.cardTitle.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: AppColors.text(context),
                            ),
                          ),
                          const SizedBox(height: 3),
                          PractitionerBadge(type: p.type),
                          const SizedBox(height: 4),
                          Text(
                            loc.isArabic ? p.specialtyAr : p.specialtyEn,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.subtext(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.subtext(context),
                    ),
                  ],
                ),
                if ((loc.isArabic ? p.aboutAr : (p.aboutEn ?? p.aboutAr))
                    .isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    loc.isArabic ? p.aboutAr : (p.aboutEn ?? p.aboutAr),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.subtext(context),
                      height: 1.45,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () => onRequestWithPractitioner(p),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.silverPrimary
                              : AppColors.lightTextPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          loc.tr('request_with_doctor'),
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.backgroundDeep
                                : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 3: Treatments
// -------------------------------------------------------------
class _TreatmentsTab extends StatelessWidget {
  final PagedCollection<dynamic> page;
  final List<TreatmentModel> treatments;
  final bool isLoading;
  final LocaleService loc;
  final VoidCallback onRequestTreatment;

  const _TreatmentsTab({
    required this.page,
    required this.treatments,
    required this.isLoading,
    required this.loc,
    required this.onRequestTreatment,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && treatments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentChampagne),
      );
    }

    if (treatments.isEmpty) {
      return Center(
        child: Text(
          loc.isArabic
              ? 'لا توجد علاجات مدرجة حالياً'
              : 'No treatments listed currently',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.subtext(context),
          ),
        ),
      );
    }

    return PagedScrollBoundary(
      onLoadMore: page.loadMore,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
        itemCount: treatments.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= treatments.length) {
            return PaginationFooter(
              loading: page.isLoadingMore,
              hasMore: page.hasMore,
              error: page.error,
              onLoadMore: page.loadMore,
            );
          }
          final t = treatments[index];
          final duration = t.formattedDuration(loc.isArabic);
          final downtime =
              (loc.isArabic
                      ? t.downtimeText
                      : (t.downtimeTextEn ?? t.downtimeText))
                  .trim();
          final metaParts = <String>[
            if (duration.isNotEmpty) '${loc.tr("duration_label")}: $duration',
            if (downtime.isNotEmpty) downtime,
            if (t.price != null && t.price! > 0)
              '${t.price!.toInt()} ${loc.tr("currency_aed")}',
          ];

          return LuxuryCard(
            onTap: onRequestTreatment,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LuxuryImage(
                  imageUrl: t.imageUrl,
                  fallbackLogoUrl: t.clinicLogoUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(8),
                  placeholderIcon: Icons.spa_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.isArabic ? t.nameAr : t.nameEn,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.text(context),
                        ),
                      ),
                      if (metaParts.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          metaParts.join(' • '),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.subtext(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        loc.isArabic
                            ? t.descriptionAr
                            : (t.descriptionEn ?? t.descriptionAr),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.subtext(context),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 4: Offers
// -------------------------------------------------------------
class _OffersTab extends StatelessWidget {
  final PagedCollection<dynamic> page;
  final List<OfferModel> offers;
  final bool isLoading;
  final LocaleService loc;
  final String clinicLogoUrl;
  final VoidCallback onRequestOffer;

  const _OffersTab({
    required this.page,
    required this.offers,
    required this.isLoading,
    required this.loc,
    required this.clinicLogoUrl,
    required this.onRequestOffer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    if (isLoading && offers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentChampagne),
      );
    }

    if (offers.isEmpty) {
      return Center(
        child: Text(
          loc.isArabic
              ? 'لا توجد عروض حالية لهذه العيادة'
              : 'No current offers for this clinic',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.subtext(context),
          ),
        ),
      );
    }

    return PagedScrollBoundary(
      onLoadMore: page.loadMore,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
        itemCount: offers.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= offers.length) {
            return PaginationFooter(
              loading: page.isLoadingMore,
              hasMore: page.hasMore,
              error: page.error,
              onLoadMore: page.loadMore,
            );
          }
          final offer = offers[index];
          return LuxuryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (offer.imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LuxuryImage(
                      imageUrl: offer.imageUrl,
                      fallbackLogoUrl: clinicLogoUrl,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  loc.isArabic ? offer.titleAr : offer.titleEn,
                  style: AppTypography.cardTitle.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.text(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  loc.isArabic
                      ? offer.termsAr
                      : (offer.termsEn ?? offer.termsAr),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.subtext(context),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${offer.offerPrice.toInt()} ${loc.tr("currency_aed")} (${loc.isArabic ? "بدل" : "was"} ${offer.originalPrice.toInt()} ${loc.tr("currency_aed")})',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.text(context),
                          ),
                        ),
                        Text(
                          loc.isArabic
                              ? offer.validUntilText
                              : (offer.validUntilTextEn ??
                                    offer.validUntilText),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.subtext(context),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: onRequestOffer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.silverPrimary
                            : AppColors.lightTextPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        loc.tr('offer_claim'),
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.backgroundDeep
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.bg(context), child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return true;
  }
}
