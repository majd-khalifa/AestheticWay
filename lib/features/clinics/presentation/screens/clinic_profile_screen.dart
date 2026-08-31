import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/rating_chip.dart';
import 'package:aesthetic_way/core/widgets/distance_chip.dart';
import 'package:aesthetic_way/core/widgets/practitioner_badge.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/utils/maps_launcher.dart';
import 'package:aesthetic_way/core/utils/contact_launcher.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/data/mock_data.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
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
  late TabController _tabController;
  final PageController _galleryController = PageController();
  int _currentGalleryIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
          clinic: widget.clinic,
          preselectedPractitioner: practitioner,
        ),
      ),
    );
  }

  void _toggleFavorite() async {
    final auth = AuthState();
    final loc = LocaleService();
    if (!auth.isLoggedIn) {
      final loggedIn = await GuestAuthGuard.requireAuth(
        context,
        reasonTitle: loc.tr('my_favs'),
        reasonSubtitle: loc.isArabic
            ? 'سجل دخولك لحفظ العيادة في قائمتك المفضلة'
            : 'Login to save this clinic to your favorites',
      );
      if (!loggedIn || !mounted) return;
    }
    auth.toggleFavorite(widget.clinic.id);
  }

  @override
  Widget build(BuildContext context) {
    final clinic = widget.clinic;
    final mockData = MockDataService();
    final practitioners = mockData.getPractitionersForClinic(clinic.id);
    final allImages = [clinic.coverImageUrl, ...clinic.galleryImages];
    final auth = AuthState();
    final loc = LocaleService();

    return ListenableBuilder(
      listenable: loc,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // Luxury Hero Media Bar
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
                  actions: [
                    ListenableBuilder(
                      listenable: auth,
                      builder: (context, _) {
                        final isFav = auth.isFavorite(clinic.id);
                        return IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav
                                  ? const Color(0xFFF87171)
                                  : AppColors.silverPrimary,
                              size: 18,
                            ),
                          ),
                          onPressed: _toggleFavorite,
                        );
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          controller: _galleryController,
                          itemCount: allImages.length,
                          onPageChanged: (idx) {
                            setState(() {
                              _currentGalleryIndex = idx;
                            });
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              allImages[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: AppColors.cardSurfaceHover,
                                child: const Icon(
                                  Icons.local_hospital_outlined,
                                  size: 48,
                                  color: AppColors.silverMuted,
                                ),
                              ),
                            );
                          },
                        ),
                        // Dark gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.45),
                                Colors.transparent,
                                AppColors.backgroundDeep,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                        // Gallery dots indicator
                        if (allImages.length > 1)
                          Positioned(
                            bottom: 12,
                            right: 0,
                            left: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                allImages.length,
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
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    loc.isArabic
                                        ? clinic.nameEn
                                        : clinic.nameAr,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.silverMuted,
                                      fontSize: 11.5,
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
                            DistanceChip(
                              distanceKm: clinic.distanceKm,
                              areaName: loc.isArabic
                                  ? clinic.areaAr
                                  : clinic.areaEn,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Quick Action Buttons (Google Maps / Call / WhatsApp)
                        Row(
                          children: [
                            // Google Maps Action
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  MapsLauncher.openMapLocation(
                                    latitude: clinic.latitude,
                                    longitude: clinic.longitude,
                                    placeId: clinic.googlePlaceId,
                                    placeName: loc.isArabic
                                        ? clinic.nameAr
                                        : clinic.nameEn,
                                  );
                                },
                                icon: const Icon(
                                  Icons.map_outlined,
                                  size: 14,
                                  color: AppColors.silverSecondary,
                                ),
                                label: Text(
                                  loc.tr('map_google'),
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.silverPrimary,
                                    fontWeight: FontWeight.w600,
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
                            const SizedBox(width: 8),
                            // Direct Call Action
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => ContactLauncher.makePhoneCall(
                                  clinic.receptionPhone,
                                ),
                                icon: Icon(
                                  Icons.phone_outlined,
                                  size: 14,
                                  color: AppColors.subtext(context),
                                ),
                                label: Text(
                                  loc.tr('call_btn'),
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.text(context),
                                    fontWeight: FontWeight.w600,
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
                            const SizedBox(width: 8),
                            // WhatsApp Action
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => ContactLauncher.openWhatsApp(
                                  phoneNumber: clinic.whatsapp,
                                ),
                                icon: const Icon(
                                  Icons.chat_bubble_outline,
                                  size: 14,
                                  color: Color(0xFF10B981),
                                ),
                                label: Text(
                                  loc.tr('whatsapp_btn'),
                                  style: AppTypography.caption.copyWith(
                                    color: const Color(0xFF10B981),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11.5,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
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
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Primary Telegram-like Button: Appointment Request (Lead only)
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
                      labelColor: AppColors.accentChampagne,
                      unselectedLabelColor: AppColors.silverMuted,
                      indicatorWeight: 2.5,
                      labelStyle: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: AppTypography.bodyMedium,
                      tabs: [
                        Tab(text: loc.tr('tab_about')),
                        Tab(
                          text:
                              '${loc.tr("tab_staff")} (${practitioners.length})',
                        ),
                        Tab(text: loc.tr('tab_treatments')),
                        Tab(
                          text:
                              '${loc.tr("tab_offers")} (${clinic.featuredOffers.length})',
                        ),
                        Tab(
                          text:
                              '${loc.tr("tab_reviews")} (${clinic.reviewCount})',
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _AboutAndLocationTab(clinic: clinic, loc: loc),
                _StaffTab(
                  practitioners: practitioners,
                  loc: loc,
                  onRequestWithPractitioner: (p) =>
                      _handleAppointmentRequest(practitioner: p),
                ),
                _TreatmentsTab(
                  treatmentIds: clinic.treatmentIds,
                  loc: loc,
                  onRequestTreatment: () => _handleAppointmentRequest(),
                ),
                _OffersTab(
                  clinic: clinic,
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
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.isArabic ? clinic.descriptionAr : clinic.descriptionEn,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.silverSecondary,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: AppColors.silverSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('working_hours'),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.silverPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.isArabic
                              ? clinic.workingHoursAr
                              : clinic.workingHoursEn,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.silverMuted,
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
                        ),
                      ),
                    ],
                  ),
                  DistanceChip(distanceKm: clinic.distanceKm),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                loc.isArabic ? clinic.addressAr : clinic.addressEn,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              // Simulated Interactive Map Preview Box
              Container(
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.cardSurfaceHover,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle, width: 0.8),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundDeep,
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
                          color: AppColors.silverPrimary,
                          fontWeight: FontWeight.w600,
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
                        MapsLauncher.openDirections(
                          latitude: clinic.latitude,
                          longitude: clinic.longitude,
                          destinationTitle: loc.isArabic
                              ? clinic.nameAr
                              : clinic.nameEn,
                        );
                      },
                      icon: const Icon(
                        Icons.directions,
                        size: 15,
                        color: AppColors.silverSecondary,
                      ),
                      label: Text(
                        loc.tr('directions'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.borderSubtle,
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
                        MapsLauncher.openMapLocation(
                          latitude: clinic.latitude,
                          longitude: clinic.longitude,
                          placeId: clinic.googlePlaceId,
                          placeName: loc.isArabic
                              ? clinic.nameAr
                              : clinic.nameEn,
                        );
                      },
                      icon: const Icon(
                        Icons.open_in_new,
                        size: 15,
                        color: AppColors.backgroundDeep,
                      ),
                      label: Text(
                        loc.tr('open_in_maps'),
                        style: const TextStyle(
                          color: AppColors.backgroundDeep,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.silverPrimary,
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
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.isArabic ? branch.addressAr : branch.addressEn,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.silverMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.directions,
              color: AppColors.silverSecondary,
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
  final LocaleService loc;
  final ValueChanged<PractitionerModel> onRequestWithPractitioner;

  const _StaffTab({
    required this.practitioners,
    required this.loc,
    required this.onRequestWithPractitioner,
  });

  @override
  Widget build(BuildContext context) {
    if (practitioners.isEmpty) {
      return Center(
        child: Text(
          loc.isArabic
              ? 'لا يوجد ممارسون مدرجون حالياً'
              : 'No practitioners listed currently',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.silverMuted,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.cardSurfaceHover,
                    backgroundImage: NetworkImage(p.avatarUrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.isArabic ? p.nameAr : p.nameEn,
                          style: AppTypography.cardTitle.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        PractitionerBadge(type: p.type),
                        const SizedBox(height: 3),
                        Text(
                          loc.isArabic ? p.specialtyAr : p.specialtyEn,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.silverMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                loc.isArabic ? p.aboutAr : (p.aboutEn ?? p.aboutAr),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
                        color: AppColors.silverPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        loc.tr('request_with_doctor'),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.backgroundDeep,
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
  final List<String> treatmentIds;
  final LocaleService loc;
  final VoidCallback onRequestTreatment;

  const _TreatmentsTab({
    required this.treatmentIds,
    required this.loc,
    required this.onRequestTreatment,
  });

  @override
  Widget build(BuildContext context) {
    final mockData = MockDataService();
    final allTreatments = mockData.treatments;
    final treatments = allTreatments
        .where((t) => treatmentIds.contains(t.id))
        .toList();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      itemCount: treatments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final t = treatments[index];
        final duration = loc.isArabic
            ? t.durationText
            : (t.durationTextEn ?? t.durationText);
        final downtime = loc.isArabic
            ? t.downtimeText
            : (t.downtimeTextEn ?? t.downtimeText);

        return LuxuryCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  t.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 56,
                    height: 56,
                    color: AppColors.cardSurfaceHover,
                    child: const Icon(
                      Icons.spa_outlined,
                      color: AppColors.silverMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.isArabic ? t.nameAr : t.nameEn,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${loc.tr("duration_label")}: $duration • $downtime',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.silverMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.isArabic
                          ? t.descriptionAr
                          : (t.descriptionEn ?? t.descriptionAr),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
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
  final ClinicModel clinic;
  final LocaleService loc;
  final VoidCallback onRequestOffer;

  const _OffersTab({
    required this.clinic,
    required this.loc,
    required this.onRequestOffer,
  });

  @override
  Widget build(BuildContext context) {
    final mockData = MockDataService();
    final offers = mockData.offers
        .where((o) => o.clinicId == clinic.id)
        .toList();

    if (offers.isEmpty) {
      return Center(
        child: Text(
          loc.isArabic
              ? 'لا توجد عروض حالية لهذه العيادة'
              : 'No current offers for this clinic',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.silverMuted,
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
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                loc.isArabic ? offer.termsAr : (offer.termsEn ?? offer.termsAr),
                style: AppTypography.caption.copyWith(
                  color: AppColors.silverMuted,
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
                          color: AppColors.silverPrimary,
                        ),
                      ),
                      Text(
                        loc.isArabic
                            ? offer.validUntilText
                            : (offer.validUntilTextEn ?? offer.validUntilText),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.silverMuted,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: onRequestOffer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.silverPrimary,
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
                        color: AppColors.backgroundDeep,
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
class _ReviewsTab extends StatelessWidget {
  final ClinicModel clinic;
  final LocaleService loc;

  const _ReviewsTab({required this.clinic, required this.loc});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      children: [
        LuxuryCard(
          child: Row(
            children: [
              Text(
                clinic.rating.toStringAsFixed(1),
                style: AppTypography.heroTitle.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.silverPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.star, color: AppColors.starGold, size: 16),
                        Icon(Icons.star, color: AppColors.starGold, size: 16),
                        Icon(Icons.star, color: AppColors.starGold, size: 16),
                        Icon(Icons.star, color: AppColors.starGold, size: 16),
                        Icon(
                          Icons.star_half,
                          color: AppColors.starGold,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${loc.tr("reviews_summary")} (${clinic.reviewCount} ${loc.isArabic ? "مرضى" : "patients"})',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.silverMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _ReviewItem(
          patientName: loc.isArabic ? 'مجد' : 'Majd',
          rating: 5,
          dateText: loc.isArabic ? 'قبل يومين' : '2 days ago',
          comment: loc.isArabic
              ? 'تجربة استثنائية في فرع جميرا مع د. ريم، دقة متناهية وتعامل راقٍ ونتائج طبيعية جداً.'
              : 'Exceptional experience at Jumeirah branch with Dr. Reem. Utmost precision, elegance, and natural results.',
          verifiedVisit: true,
          loc: loc,
        ),
        _ReviewItem(
          patientName: loc.isArabic ? 'خالد س.' : 'Khaled S.',
          rating: 5,
          dateText: loc.isArabic ? 'قبل أسبوع' : '1 week ago',
          comment: loc.isArabic
              ? 'العيادة نظيفة جداً واستقبال رائع، والتزام تام بالمواعيد وتقنيات ليزر مريحة وغير مؤلمة.'
              : 'Spotless clinic, wonderful reception, punctual timing, and comfortable painless laser technology.',
          verifiedVisit: true,
          loc: loc,
        ),
      ],
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String patientName;
  final int rating;
  final String dateText;
  final String comment;
  final bool verifiedVisit;
  final LocaleService loc;

  const _ReviewItem({
    required this.patientName,
    required this.rating,
    required this.dateText,
    required this.comment,
    required this.verifiedVisit,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return LuxuryCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                patientName,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                dateText,
                style: AppTypography.caption.copyWith(
                  color: AppColors.silverMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              ...List.generate(
                rating,
                (_) =>
                    const Icon(Icons.star, size: 12, color: AppColors.starGold),
              ),
              const SizedBox(width: 6),
              if (verifiedVisit)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 10, color: Color(0xFF34D399)),
                      const SizedBox(width: 3),
                      Text(
                        loc.tr("verified_visit"),
                        style: AppTypography.badge.copyWith(
                          color: const Color(0xFF34D399),
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
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
