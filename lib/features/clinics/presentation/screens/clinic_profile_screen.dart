import '../../../../core/widgets/viewport_activity.dart';
import '../../../../core/widgets/silver_button.dart';
import '../../../treatments/presentation/widgets/patient_treatment_card.dart';
import '../widgets/patient_clinic_gallery.dart';
import 'package:aesthetic_way/core/theme/patient_design.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../practitioners/presentation/widgets/patient_practitioner_card.dart';
import '../../../offers/presentation/widgets/patient_offer_card.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/auth/guest_auth_guard.dart';
import '../../../../core/data/paged_collection.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/clinic_location.dart';
import '../../../../core/utils/entity_id.dart';
import '../../../../core/widgets/luxury_animations.dart';
import '../../../../core/widgets/luxury_empty_state.dart';
import '../../../../core/widgets/luxury_image.dart';
import '../../../../core/widgets/pagination_footer.dart';
import '../../../../core/widgets/async_action_button.dart';
import '../../../appointment_lead/presentation/screens/appointment_request_screen.dart';
import '../../../offers/data/offers_repository.dart';
import '../../../offers/models/offer_model.dart';
import '../../../practitioners/data/practitioners_repository.dart';
import '../../../practitioners/models/practitioner_model.dart';
import '../../../practitioners/presentation/screens/practitioner_profile_screen.dart';
import '../../../treatments/data/treatments_repository.dart';
import '../../../treatments/models/treatment_model.dart';
import '../../../treatments/presentation/screens/treatment_detail_screen.dart';
import '../../data/clinics_repository.dart';
import '../../models/clinic_model.dart';
import '../widgets/contact_options_sheet.dart';
import '../widgets/google_clinic_rating.dart';

/// Single natural-height document: switching tabs never reserves an empty viewport.
class ClinicProfileScreen extends StatefulWidget {
  const ClinicProfileScreen({
    super.key,
    required this.clinic,
    this.clinicsRepository,
    this.practitionersRepository,
    this.treatmentsRepository,
    this.offersRepository,
  });
  final ClinicModel clinic;
  final ClinicsRepository? clinicsRepository;
  final PractitionersRepository? practitionersRepository;
  final TreatmentsRepository? treatmentsRepository;
  final OffersRepository? offersRepository;
  @override
  State<ClinicProfileScreen> createState() => _ClinicProfileScreenState();
}

class _ClinicProfileScreenState extends State<ClinicProfileScreen> {
  late ClinicModel _clinic;
  late final ClinicsRepository _repo;
  late final PagedCollection<ClinicBranch> _branches;
  late final PagedCollection<PractitionerModel> _staff;
  late final PagedCollection<TreatmentModel> _treatments;
  late final PagedCollection<OfferModel> _offers;
  int _tab = 0;
  bool _loading = false;
  bool _detailFailed = false;
  @override
  void initState() {
    super.initState();
    _clinic = widget.clinic;
    _repo = widget.clinicsRepository ?? ClinicsRepository();
    _branches = PagedCollection<ClinicBranch>(
      keyOf: (b) => b.id,
      items: List.of(_clinic.branches),
      loader: (page, _) async => _clinic.hasBranchDirectory
          ? _repo.getBranches(_clinic.id, page: page)
          : PageItems(_clinic.branches, hasMore: false),
    )..addListener(_changed);
    _staff = PagedCollection<PractitionerModel>(
      keyOf: (p) => p.id,
      loader: (page, _) =>
          (widget.practitionersRepository ?? PractitionersRepository())
              .getPractitioners(clinicId: _clinic.id, page: page),
    )..addListener(_changed);
    _treatments = PagedCollection<TreatmentModel>(
      keyOf: (t) => t.id,
      loader: (page, _) =>
          (widget.treatmentsRepository ?? TreatmentsRepository()).getTreatments(
            clinic: _clinic.id,
            page: page,
          ),
    )..addListener(_changed);
    _offers = PagedCollection<OfferModel>(
      keyOf: (o) => o.id,
      loader: (page, _) => (widget.offersRepository ?? OffersRepository())
          .getOffers(clinicId: _clinic.id, page: page),
    )..addListener(_changed);
    _fetchDetails();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchDetails() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _detailFailed = false;
    });
    try {
      final detail = await _repo.getClinicDetail(widget.clinic.id);
      if (!mounted) return;
      setState(() {
        _clinic = detail;
        _branches.items
          ..clear()
          ..addAll(detail.branches);
      });
      if (detail.hasBranchDirectory) await _branches.refresh();
    } catch (_) {
      if (mounted) setState(() => _detailFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _select(int value) {
    setState(() => _tab = value);
    switch (value) {
      case 0:
        if (_clinic.hasBranchDirectory) _branches.refresh(force: false);
      case 1:
        _staff.refresh(force: false);
      case 2:
        _treatments.refresh(force: false);
      case 3:
        _offers.refresh(force: false);
    }
  }

  Future<void> _request(
    AsyncActionScope action, {
    PractitionerModel? practitioner,
    OfferModel? offer,
    TreatmentModel? treatment,
  }) async {
    if (!isEntityUuid(_clinic.id) ||
        (offer != null && !isEntityUuid(offer.id))) {
      return;
    }
    final loc = LocaleService();
    final auth = await action.wait(
      GuestAuthGuard.requireAuth(
        context,
        reasonTitle: loc.tr('request_consultation'),
        reasonSubtitle: loc.tr('request_consultation'),
      ),
    );
    if (!auth || !mounted) return;
    Navigator.push(
      context,
      LuxuryPageRoute(
        page: AppointmentRequestScreen(
          clinic: _clinic,
          preselectedPractitioner: practitioner,
          preselectedTreatmentId: treatment?.id,
          preselectedServiceName: treatment == null
              ? null
              : (loc.isArabic ? treatment.nameAr : treatment.nameEn),
          selectedOfferId: offer?.id,
          selectedOfferTitle: offer == null
              ? null
              : (loc.isArabic ? offer.titleAr : offer.titleEn),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _branches.dispose();
    _staff.dispose();
    _treatments.dispose();
    _offers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PatientDesign(builder: _buildPatient);

  Widget _buildPatient(BuildContext context) {
    final loc = LocaleService();
    final clinic = _clinic;
    final images = {
      if (clinic.coverImageUrl.isNotEmpty) clinic.coverImageUrl,
      ...clinic.galleryImages,
    }.toList();
    final description = loc.isArabic
        ? clinic.descriptionAr
        : clinic.descriptionEn;
    final hours = loc.isArabic ? clinic.workingHoursAr : clinic.workingHoursEn;
    final tabs = [
      loc.tr('tab_about'),
      loc.tr('tab_staff'),
      loc.tr('tab_treatments'),
      loc.tr('tab_offers'),
    ];
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(loc.isArabic ? 'ملف العيادة' : 'Clinic profile'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchDetails();
          if (mounted) {
            _select(_tab);
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            PatientClinicGallery(images: images),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LuxuryImage(
                        imageUrl: clinic.logoUrl,
                        width: 62,
                        height: 62,
                        fit: BoxFit.contain,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.isArabic ? clinic.nameAr : clinic.nameEn,
                              style: PatientDesign.heading(context, size: 24),
                            ),
                            const SizedBox(height: 6),
                            if (clinic.city.isNotEmpty ||
                                clinic.areaAr.isNotEmpty ||
                                clinic.areaEn.isNotEmpty)
                              Text(
                                formatClinicLocation(
                                  clinic.city,
                                  loc.isArabic ? clinic.areaAr : clinic.areaEn,
                                  arabic: loc.isArabic,
                                ),
                                style: TextStyle(
                                  color: AppColors.subtext(context),
                                ),
                              ),
                            GoogleClinicRating(clinic: clinic),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_loading) const LinearProgressIndicator(),
                  if (_detailFailed)
                    TextButton.icon(
                      onPressed: _fetchDetails,
                      icon: const Icon(Icons.sync),
                      label: Text(
                        loc.isArabic
                            ? 'تعذر تحديث تفاصيل العيادة، حاول مجدداً'
                            : 'Clinic details could not refresh. Try again',
                      ),
                    ),
                  const SizedBox(height: 16),
                  AsyncActionButton(
                    label: loc.tr('request_consultation'),
                    icon: Icons.chat_bubble_outline,
                    isFullWidth: true,
                    onPressed: isEntityUuid(clinic.id)
                        ? (action) => _request(action)
                        : null,
                  ),
                  if (!isEntityUuid(clinic.id))
                    Text(
                      loc.isArabic
                          ? 'العيادة غير متاحة لاستقبال الطلبات'
                          : 'This clinic is unavailable for inquiries',
                    ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (clinic.hasPhone || clinic.hasWhatsapp)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                ContactOptionsSheet.show(context, clinic),
                            icon: const Icon(Icons.phone_outlined, size: 18),
                            label: Text(
                              loc.tr('contact_btn'),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      if ((clinic.hasPhone || clinic.hasWhatsapp) &&
                          clinic.mapsUri != null)
                        const SizedBox(width: 8),
                      if (clinic.mapsUri != null)
                        Expanded(
                          child: AsyncActionButton(
                            label: loc.tr('map_google'),
                            icon: Icons.map_outlined,
                            variant: SilverButtonVariant.secondary,
                            loadingLabel: loc.isArabic
                                ? 'جارٍ فتح الخرائط'
                                : 'Opening Maps',
                            onPressed: (action) async {
                              final opened = await action.wait(
                                launchUrl(
                                  clinic.mapsUri!,
                                  mode: LaunchMode.externalApplication,
                                ),
                              );
                              if (!opened) {
                                throw StateError('Map handler unavailable');
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: Semantics(
                      selected: _tab == i,
                      button: true,
                      child: InkWell(
                        onTap: () => _select(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _tab == i
                                    ? AppColors.goldText(context)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                [
                                  Icons.article_outlined,
                                  Icons.people_outline,
                                  Icons.auto_awesome_outlined,
                                  Icons.local_offer_outlined,
                                ][i],
                                size: 21,
                                color: _tab == i
                                    ? AppColors.goldText(context)
                                    : AppColors.subtext(context),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tabs[i],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  fontWeight: _tab == i
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: _tab == i
                                      ? AppColors.goldText(context)
                                      : AppColors.subtext(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_tab == 0)
              LuxuryCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (description.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          loc.isArabic ? 'عن العيادة' : 'About the clinic',
                          style: TextStyle(
                            fontFamily: loc.isArabic
                                ? 'PatientArabic'
                                : 'PatientDisplay',
                            fontSize: 23,
                            color: AppColors.text(context),
                          ),
                        ),
                      ),
                    if (description.trim().isNotEmpty)
                      Text(
                        description,
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontSize: 15,
                          height: 1.7,
                        ),
                      ),
                    if (hours.trim().isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time),
                        title: Text(loc.tr('working_hours')),
                        subtitle: Text(hours),
                      ),
                    if (clinic.addressAr.isNotEmpty ||
                        clinic.addressEn.isNotEmpty ||
                        clinic.mapsUri != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 28,
                                  color: AppColors.goldText(context),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.isArabic
                                            ? 'موقع العيادة'
                                            : 'Clinic location',
                                        style: PatientDesign.heading(
                                          context,
                                          size: 18,
                                        ),
                                      ),
                                      if (clinic.addressAr.isNotEmpty ||
                                          clinic.addressEn.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 6,
                                          ),
                                          child: Text(
                                            loc.isArabic
                                                ? clinic.addressAr
                                                : clinic.addressEn,
                                            style: TextStyle(
                                              fontSize: 13,
                                              height: 1.5,
                                              color: AppColors.subtext(context),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (clinic.mapsUri != null) ...[
                              const SizedBox(height: 12),
                              AsyncActionButton(
                                label: loc.tr('map_google'),
                                loadingLabel: loc.isArabic
                                    ? 'جارٍ فتح الخرائط'
                                    : 'Opening Maps',
                                variant: SilverButtonVariant.secondary,
                                icon: Icons.open_in_new,
                                onPressed: (action) async {
                                  final opened = await action.wait(
                                    launchUrl(
                                      clinic.mapsUri!,
                                      mode: LaunchMode.externalApplication,
                                    ),
                                  );
                                  if (!opened) {
                                    throw StateError('Map handler unavailable');
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (!clinic.hasMapLocation)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          loc.isArabic
                              ? 'موقع الخريطة غير متوفر'
                              : 'Map location is not available',
                          style: TextStyle(color: AppColors.subtext(context)),
                        ),
                      ),
                    for (final b in _branches.items)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.domain_outlined),
                        title: Text(loc.isArabic ? b.nameAr : b.nameEn),
                        subtitle: Text(
                          loc.isArabic ? b.addressAr : b.addressEn,
                        ),
                      ),
                    if (clinic.hasBranchDirectory) _footer(_branches),
                  ],
                ),
              ),

            if (_tab == 0 && clinic.rawPractitioners?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              _previewHeading(loc.tr('tab_staff'), () => _select(1)),
              const SizedBox(height: 8),
              PatientPractitionerCard(
                practitioner: PractitionerModel.fromJson({
                  ...Map<String, dynamic>.from(
                    clinic.rawPractitioners!.first as Map,
                  ),
                  'clinic': {
                    'id': clinic.id,
                    'name_en': clinic.nameEn,
                    'name_ar': clinic.nameAr,
                    'logo': clinic.logoUrl,
                  },
                }),
                onTap: () => _select(1),
              ),
            ],
            if (_tab == 0 && clinic.rawTreatments?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              _previewHeading(loc.tr('tab_treatments'), () => _select(2)),
              const SizedBox(height: 8),
              for (final raw in clinic.rawTreatments!.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PatientTreatmentCard(
                    treatment: TreatmentModel.fromJson({
                      ...Map<String, dynamic>.from(raw as Map),
                      'clinic': {
                        'id': clinic.id,
                        'name_en': clinic.nameEn,
                        'name_ar': clinic.nameAr,
                      },
                    }),
                    onTap: () => _select(2),
                  ),
                ),
            ],

            if (_tab == 0) ...[
              const SizedBox(height: 16),
              ViewportActivity(
                onChanged: (visible) {
                  // Only the visible preview requests one bounded, clinic-scoped
                  // page. The Offers tab shares this collection and its flight.
                  if (visible && !_offers.isLoaded && _offers.error == null) {
                    _offers.refresh(force: false);
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _previewHeading(loc.tr('tab_offers'), () => _select(3)),
                    if (_offers.isLoading) const LinearProgressIndicator(),
                    if (_offers.error != null && _offers.items.isEmpty)
                      TextButton(
                        onPressed: () => _offers.refresh(),
                        child: Text(
                          loc.isArabic
                              ? 'تعذر التحميل، أعد المحاولة'
                              : 'Could not load. Try again',
                        ),
                      ),
                    for (final offer in _offers.items.take(1))
                      PatientOfferCard(
                        offer: offer,
                        compact: true,
                        onInquiryAction: (action) =>
                            _request(action, offer: offer),
                      ),
                    if (_offers.isLoaded && _offers.items.isEmpty)
                      Text(
                        loc.isArabic
                            ? 'لا توجد عروض منشورة'
                            : 'No offers published',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.subtext(context),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            if (_tab == 1) ...[
              ..._state(
                _staff,
                loc.isArabic
                    ? 'لا يوجد طاقم طبي منشور'
                    : 'No medical staff published',
              ),
              for (final p in _staff.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PatientPractitionerCard(
                    practitioner: p,
                    onTap: () => Navigator.push(
                      context,
                      LuxuryPageRoute(
                        page: PractitionerProfileScreen(practitioner: p),
                      ),
                    ),
                    onInquiryAction: (action) =>
                        _request(action, practitioner: p),
                  ),
                ),
              _footer(_staff),
            ],
            if (_tab == 2) ...[
              ..._state(
                _treatments,
                loc.isArabic
                    ? 'لا توجد إجراءات منشورة'
                    : 'No treatments published',
              ),
              for (final t in _treatments.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PatientTreatmentCard(
                    treatment: t,
                    onTap: () => Navigator.push(
                      context,
                      LuxuryPageRoute(
                        page: TreatmentDetailScreen(treatment: t),
                      ),
                    ),
                  ),
                ),
              _footer(_treatments),
            ],
            if (_tab == 3) ...[
              ..._state(
                _offers,
                loc.isArabic ? 'لا توجد عروض منشورة' : 'No offers published',
              ),
              for (final o in _offers.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PatientOfferCard(
                    offer: o,
                    onInquiryAction: (action) => _request(action, offer: o),
                  ),
                ),
              _footer(_offers),
            ],
          ],
        ),
      ),
    );
  }

  Widget _previewHeading(String title, VoidCallback onTap) => Row(
    children: [
      Expanded(
        child: Text(title, style: PatientDesign.heading(context, size: 21)),
      ),
      TextButton(
        onPressed: onTap,
        child: Text(LocaleService().isArabic ? 'عرض الكل' : 'View all'),
      ),
    ],
  );

  Widget _footer<T>(PagedCollection<T> page) => PaginationFooter(
    loading: page.isLoadingMore,
    hasMore: page.hasMore,
    error: page.error,
    onLoadMore: page.error == null ? page.loadMore : () => page.refresh(),
  );
  List<Widget> _state<T>(PagedCollection<T> page, String empty) {
    if (page.isLoading && page.items.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (page.error != null && page.items.isEmpty) {
      return [
        TextButton.icon(
          onPressed: page.refresh,
          icon: const Icon(Icons.sync),
          label: Text(
            LocaleService().isArabic
                ? 'تعذر التحميل، أعد المحاولة'
                : 'Could not load. Try again',
          ),
        ),
      ];
    }
    if (page.items.isEmpty) {
      return [
        LuxuryEmptyState(
          icon: Icons.layers_outlined,
          title: empty,
          subtitle: LocaleService().isArabic
              ? 'يمكنك الاستفسار من العيادة مباشرة'
              : 'You can send the clinic a general inquiry',
        ),
      ];
    }
    return [];
  }
}
