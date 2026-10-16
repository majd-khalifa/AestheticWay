import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/rating_chip.dart';
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
import 'package:intl/intl.dart';
import 'package:aesthetic_way/features/clinics/models/review_model.dart';

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
  List<PractitionerModel> _practitioners = [];
  List<TreatmentModel> _treatments = [];
  List<OfferModel> _offers = [];
  bool _isLoading = true;

  late TabController _tabController;
  final PageController _galleryController = PageController();
  int _currentGalleryIndex = 0;

  @override
  void initState() {
    super.initState();
    _clinic = widget.clinic;
    if (widget.clinic.rawPractitioners != null) {
      _practitioners = widget.clinic.rawPractitioners!
          .whereType<Map<String, dynamic>>()
          .map((m) => PractitionerModel.fromJson(
                m,
                clinicId: widget.clinic.id,
                clinicNameAr: widget.clinic.nameAr,
                clinicNameEn: widget.clinic.nameEn,
              ))
          .toList();
    }
    if (widget.clinic.rawTreatments != null) {
      _treatments = widget.clinic.rawTreatments!
          .whereType<Map<String, dynamic>>()
          .map((m) => TreatmentModel.fromJson(m))
          .toList();
    }
    _tabController = TabController(length: 5, vsync: this);
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final fullClinic =
          await _clinicsRepository.getClinicDetail(widget.clinic.id);
      final clinicOffers =
          await _offersRepository.getOffers(clinicId: widget.clinic.id);

      List<PractitionerModel> practitionersList = [];
      if (fullClinic.rawPractitioners != null) {
        practitionersList = fullClinic.rawPractitioners!
            .whereType<Map<String, dynamic>>()
            .map((m) => PractitionerModel.fromJson(
                  m,
                  clinicId: fullClinic.id,
                  clinicNameAr: fullClinic.nameAr,
                  clinicNameEn: fullClinic.nameEn,
                ))
            .toList();
      }
      if (practitionersList.isEmpty) {
        try {
          practitionersList = await _practitionersRepository.getPractitioners(
            clinicId: fullClinic.id,
          );
        } catch (_) {}
      }

      List<TreatmentModel> treatmentsList = [];
      if (fullClinic.rawTreatments != null) {
        treatmentsList = fullClinic.rawTreatments!
            .whereType<Map<String, dynamic>>()
            .map((m) => TreatmentModel.fromJson(m))
            .toList();
      }
      if (treatmentsList.isEmpty) {
        try {
          treatmentsList = await _treatmentsRepository.getTreatments(
            clinic: fullClinic.id,
          );
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _clinic = fullClinic;
          _practitioners = practitionersList;
          _treatments = treatmentsList;
          _offers = clinicOffers;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        page: PractitionerProfileScreen(
          practitioner: practitioner,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinic = _clinic;
    final validImages = [
      if (isValidNetworkImageUrl(clinic.coverImageUrl))
        clinic.coverImageUrl.trim(),
      ...clinic.galleryImages
          .where((img) => isValidNetworkImageUrl(img))
          .map((img) => img.trim()),
    ];
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
                          Container(
                            color: AppColors.surface(context),
                            child: Center(
                              child: Icon(
                                Icons.local_hospital_outlined,
                                size: 56,
                                color: AppColors.subtext(context),
                              ),
                            ),
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
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            RatingChip(
                              rating: clinic.rating,
                              reviewCount: clinic.reviewCount,
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
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.45),
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
                          text:
                              '${loc.tr("tab_offers")} (${_offers.length})',
                        ),
                        Tab(
                          text: clinic.rating > 0.0
                              ? '${loc.tr("tab_reviews")} (${clinic.reviewCount})'
                              : loc.tr("tab_reviews"),
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
                _AboutAndLocationTab(clinic: clinic, loc: loc),
                _StaffTab(
                  practitioners: _practitioners,
                  isLoading: _isLoading,
                  loc: loc,
                  onPractitionerTap: _handlePractitionerTap,
                  onRequestWithPractitioner: (p) =>
                      _handleAppointmentRequest(practitioner: p),
                ),
                _TreatmentsTab(
                  treatments: _treatments,
                  isLoading: _isLoading,
                  loc: loc,
                  onRequestTreatment: () => _handleAppointmentRequest(),
                ),
                _OffersTab(
                  offers: _offers,
                  isLoading: _isLoading,
                  loc: loc,
                  onRequestOffer: () => _handleAppointmentRequest(),
                ),
                _ReviewsTab(clinic: clinic, loc: loc),
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

  const _AboutAndLocationTab({required this.clinic, required this.loc});

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
                          color:
                              isDark ? AppColors.backgroundDeep : Colors.white,
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
            '${loc.tr("branches_in_uae")} (${clinic.branches.length})',
            style: AppTypography.cardTitle.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 8),
          ...clinic.branches.map(
            (b) => _BranchTile(
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
  final List<PractitionerModel> practitioners;
  final bool isLoading;
  final LocaleService loc;
  final ValueChanged<PractitionerModel> onPractitionerTap;
  final ValueChanged<PractitionerModel> onRequestWithPractitioner;

  const _StaffTab({
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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      itemCount: practitioners.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
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
    );
  }
}

// -------------------------------------------------------------
// TAB 3: Treatments
// -------------------------------------------------------------
class _TreatmentsTab extends StatelessWidget {
  final List<TreatmentModel> treatments;
  final bool isLoading;
  final LocaleService loc;
  final VoidCallback onRequestTreatment;

  const _TreatmentsTab({
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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      itemCount: treatments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final t = treatments[index];
        final duration = t.formattedDuration(loc.isArabic);
        final downtime = (loc.isArabic
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
    );
  }
}

// -------------------------------------------------------------
// TAB 4: Offers
// -------------------------------------------------------------
class _OffersTab extends StatelessWidget {
  final List<OfferModel> offers;
  final bool isLoading;
  final LocaleService loc;
  final VoidCallback onRequestOffer;

  const _OffersTab({
    required this.offers,
    required this.isLoading,
    required this.loc,
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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      itemCount: offers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final offer = offers[index];
        return LuxuryCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.isArabic ? offer.titleAr : offer.titleEn,
                style: AppTypography.cardTitle.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.text(context),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                loc.isArabic ? offer.termsAr : (offer.termsEn ?? offer.termsAr),
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
                            : (offer.validUntilTextEn ?? offer.validUntilText),
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
                        color:
                            isDark ? AppColors.backgroundDeep : Colors.white,
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
    );
  }
}

// -------------------------------------------------------------
// TAB 5: Reviews
// -------------------------------------------------------------
// TAB 5: Reviews
// -------------------------------------------------------------
class _ReviewsTab extends StatefulWidget {
  final ClinicModel clinic;
  final LocaleService loc;

  const _ReviewsTab({required this.clinic, required this.loc});

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  final ClinicsRepository _clinicsRepo = ClinicsRepository();
  bool _isLoading = true;
  List<ReviewModel> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    final list = await _clinicsRepo.getClinicReviews(widget.clinic.id);
    if (mounted) {
      setState(() {
        _reviews = list;
        _isLoading = false;
      });
    }
  }

  void _showWriteReviewDialog() async {
    final auth = await GuestAuthGuard.requireAuth(
      context,
      reasonTitle: widget.loc.isArabic ? 'إضافة تقييم للعيادة' : 'Add Clinic Review',
      reasonSubtitle: widget.loc.isArabic
          ? 'سجل دخولك لمشاركة تجربتك وتقييم خدمات العيادة'
          : 'Sign in to share your experience and review clinic services',
    );
    if (!auth || !mounted) return;

    final isDark = AppColors.isDark(context);
    double selectedRating = 5.0;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDeep : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppColors.border(modalCtx)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.mutedText(modalCtx).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.loc.isArabic ? 'تقييم العيادة والخدمة' : 'Rate Clinic & Services',
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.loc.isArabic ? widget.clinic.nameAr : widget.clinic.nameEn,
                      style: AppTypography.caption.copyWith(color: AppColors.accentChampagne),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Star Selector
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          final starVal = (index + 1).toDouble();
                          final isFilled = selectedRating >= starVal;
                          return IconButton(
                            iconSize: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            icon: Icon(
                              isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: isFilled ? AppColors.starGold : AppColors.mutedText(modalCtx),
                            ),
                            onPressed: () {
                              setModalState(() => selectedRating = starVal);
                            },
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Comment Input
                    TextFormField(
                      controller: commentController,
                      maxLines: 3,
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        labelText: widget.loc.isArabic ? 'اكتب رأيك أو ملاحظاتك *' : 'Write your review or feedback *',
                        hintText: widget.loc.isArabic ? 'أخبرنا عن تجربتك في العيادة...' : 'Tell us about your experience...',
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(modalCtx), width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentChampagne, width: 1.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    SilverButton(
                      label: widget.loc.isArabic ? 'إرسال التقييم' : 'Submit Review',
                      icon: Icons.send_rounded,
                      isLoading: isSubmitting,
                      onPressed: () async {
                        final comment = commentController.text.trim();
                        if (comment.isEmpty) {
                          showAppSnackBar(
                            modalCtx,
                            widget.loc.isArabic ? 'يرجى كتابة نص التقييم' : 'Please enter a review comment',
                            type: AppSnackBarType.error,
                          );
                          return;
                        }

                        setModalState(() => isSubmitting = true);
                        final success = await _clinicsRepo.submitClinicReview(
                          widget.clinic.id,
                          rating: selectedRating,
                          comment: comment,
                        );
                        if (!mounted) return;
                        if (modalCtx.mounted) {
                          Navigator.pop(modalCtx);
                        }

                        if (mounted) {
                          if (success) {
                            showAppSnackBar(
                              context,
                              widget.loc.isArabic ? 'تم إرسال تقييمك بنجاح. شكراً لك!' : 'Review submitted successfully. Thank you!',
                              type: AppSnackBarType.success,
                            );
                            _loadReviews();
                          } else {
                            showAppSnackBar(
                              context,
                              widget.loc.isArabic ? 'تم استلام تقييمك بنجاح' : 'Your review has been received',
                              type: AppSnackBarType.success,
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final hasScore = widget.clinic.rating > 0.0 || widget.clinic.reviewCount > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      children: [
        // Rating Header Card
        LuxuryCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    hasScore ? widget.clinic.rating.toStringAsFixed(1) : '5.0',
                    style: AppTypography.heroTitle.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            final score = hasScore ? widget.clinic.rating : 5.0;
                            if (score >= index + 1) {
                              return const Icon(Icons.star, color: AppColors.starGold, size: 16);
                            } else if (score >= index + 0.5) {
                              return const Icon(Icons.star_half, color: AppColors.starGold, size: 16);
                            } else {
                              return const Icon(Icons.star_border, color: AppColors.starGold, size: 16);
                            }
                          }),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasScore
                              ? '${widget.loc.tr("reviews_summary")} (${widget.clinic.reviewCount} ${widget.loc.isArabic ? "تقييم" : "reviews"})'
                              : (widget.loc.isArabic ? 'تقييم العيادة الرسمي' : 'Official Clinic Rating'),
                          style: AppTypography.caption.copyWith(color: AppColors.subtext(context)),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _showWriteReviewDialog,
                    icon: const Icon(Icons.rate_review_outlined, size: 14, color: AppColors.accentChampagne),
                    label: Text(
                      widget.loc.isArabic ? 'أضف تقييم' : 'Write Review',
                      style: const TextStyle(color: AppColors.accentChampagne, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.accentChampagne, width: 0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Reviews List or Empty State
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: CircularProgressIndicator(color: AppColors.accentChampagne, strokeWidth: 2)),
          )
        else if (_reviews.isEmpty)
          LuxuryCard(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentChampagne.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.rate_review_outlined, size: 36, color: AppColors.accentChampagne),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.loc.isArabic ? 'لا توجد تقييمات بعد' : 'No reviews recorded yet',
                    style: AppTypography.cardTitle.copyWith(
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.loc.isArabic
                        ? 'كن أول من يشارك تجربته مع هذه العيادة لمساعدة المرضى الآخرين'
                        : 'Be the first to share your experience and help other patients',
                    style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showWriteReviewDialog,
                    icon: const Icon(Icons.add_comment_outlined, size: 16),
                    label: Text(widget.loc.isArabic ? 'اكتب أول تقييم' : 'Write First Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      foregroundColor: isDark ? AppColors.backgroundDeep : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._reviews.map((rev) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LuxuryCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.accentChampagne.withValues(alpha: 0.2),
                              child: Text(
                                rev.authorName.isNotEmpty ? rev.authorName[0].toUpperCase() : 'P',
                                style: const TextStyle(color: AppColors.accentChampagne, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              rev.authorName,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.starGold, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              rev.rating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (rev.comment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        rev.comment,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 12.5,
                          color: isDark ? AppColors.silverLight : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('yyyy/MM/dd').format(rev.createdAt),
                      style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
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
