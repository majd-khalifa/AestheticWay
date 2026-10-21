import '../widgets/lead_rejection_notice.dart';
import 'my_requests_screen.dart';
import 'package:aesthetic_way/core/theme/patient_design.dart';
import '../../../../core/utils/entity_id.dart';
import '../../../../core/utils/clinic_location.dart';
import '../../../clinics/data/clinics_repository.dart';
import 'package:aesthetic_way/core/widgets/paged_entity_field.dart';
import 'package:aesthetic_way/core/data/paged_collection.dart';
import '../../../treatments/data/treatments_repository.dart';
import '../../../treatments/models/treatment_model.dart';
import '../../../practitioners/data/practitioners_repository.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/luxury_phone_input_field.dart';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';
import 'package:aesthetic_way/features/appointment_lead/data/leads_repository.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_success_screen.dart';

/// Appointment Request Form Screen (Lead Generation ONLY)
/// Fully responsive and perfectly styled for both Dark and Soft Light Luxury themes
class AppointmentRequestScreen extends StatefulWidget {
  final ClinicModel clinic;
  final PractitionerModel? preselectedPractitioner;
  final String? preselectedServiceName;
  final String? preselectedTreatmentId;
  final String? selectedOfferTitle;
  final String? selectedOfferId;
  final LeadsRepository? leadsRepository;
  final TreatmentsRepository? treatmentsRepository;
  final PractitionersRepository? practitionersRepository;

  const AppointmentRequestScreen({
    super.key,
    required this.clinic,
    this.preselectedPractitioner,
    this.preselectedServiceName,
    this.preselectedTreatmentId,
    this.selectedOfferTitle,
    this.selectedOfferId,
    this.leadsRepository,
    this.treatmentsRepository,
    this.practitionersRepository,
  });

  @override
  State<AppointmentRequestScreen> createState() =>
      _AppointmentRequestScreenState();
}

class _AppointmentRequestScreenState extends State<AppointmentRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  final TextEditingController _notesController = TextEditingController();
  late final LeadsRepository _leadsRepository;

  ClinicBranch? _selectedBranch;
  PractitionerModel? _selectedPractitioner;
  String? _selectedBranchId;
  String? _selectedTreatment;
  String? _selectedPractitionerId;
  String? _selectedPractitionerLabel;
  bool _consentAccepted = false;
  bool _isSubmitting = false;
  ApiException? _submissionRejection;
  bool _openingRequests = false;
  final _rejectionKey = GlobalKey();

  final Map<String, String> _treatmentNameToId = {};

  Map<String, ClinicBranch> get _uniqueBranches {
    final Map<String, ClinicBranch> map = {};
    for (final b in widget.clinic.branches) {
      if (b.id.isNotEmpty && !map.containsKey(b.id)) {
        map[b.id] = b;
      }
    }
    if (_selectedBranch != null) map[_selectedBranch!.id] = _selectedBranch!;
    return map;
  }

  Map<String, PractitionerModel> get _uniquePractitioners {
    final Map<String, PractitionerModel> map = {};
    if (widget.clinic.rawPractitioners != null) {
      for (final raw in widget.clinic.rawPractitioners!.take(20)) {
        if (raw is Map<String, dynamic>) {
          try {
            final p = PractitionerModel.fromJson(
              raw,
              clinicId: widget.clinic.id,
              clinicNameAr: widget.clinic.nameAr,
              clinicNameEn: widget.clinic.nameEn,
            );
            if (p.id.isNotEmpty && !map.containsKey(p.id)) {
              map[p.id] = p;
            }
          } catch (_) {}
        }
      }
    }
    final preselected = widget.preselectedPractitioner;
    if (preselected != null &&
        preselected.clinicId == widget.clinic.id &&
        isEntityUuid(preselected.id)) {
      map[preselected.id] = preselected;
    }
    if (_selectedPractitioner != null) {
      map[_selectedPractitioner!.id] = _selectedPractitioner!;
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    _leadsRepository = widget.leadsRepository ?? LeadsRepository();
    final auth = AuthState();
    _nameController = TextEditingController(
      text: auth.isLoggedIn ? auth.userName : '',
    );

    _phoneController = TextEditingController(
      text: auth.isLoggedIn ? auth.userPhone : '',
    );

    if (widget.clinic.branches.isNotEmpty) {
      _selectedBranchId = widget.clinic.branches.first.id;
    }

    final preselected = widget.preselectedPractitioner;
    _selectedPractitionerId = preselected?.clinicId == widget.clinic.id
        ? preselected?.id
        : null;
    _selectedPractitionerLabel = _selectedPractitionerId == null
        ? null
        : LocaleService().isArabic
        ? widget.preselectedPractitioner?.nameAr
        : widget.preselectedPractitioner?.nameEn;

    // Build initial treatment options from clinic.rawTreatments
    final defaultTreatment = LocaleService().isArabic
        ? 'استشارة تجميلية وجلدية عامة'
        : 'General Aesthetic & Derma Consultation';
    final Set<String> validOptions = {defaultTreatment};

    if (widget.clinic.rawTreatments != null) {
      for (final raw in widget.clinic.rawTreatments!.take(20)) {
        if (raw is Map<String, dynamic>) {
          final nameAr = (raw['name_ar'] ?? raw['name_en'] ?? '')
              .toString()
              .trim();
          final nameEn = (raw['name_en'] ?? raw['name_ar'] ?? '')
              .toString()
              .trim();
          final id = raw['id']?.toString() ?? '';
          if (nameAr.isNotEmpty) {
            validOptions.add(nameAr);
            if (id.isNotEmpty) _treatmentNameToId[nameAr] = id;
          }
          if (nameEn.isNotEmpty && nameEn != nameAr) {
            validOptions.add(nameEn);
            if (id.isNotEmpty) _treatmentNameToId[nameEn] = id;
          }
        }
      }
    }

    if (isEntityUuid(widget.preselectedTreatmentId) &&
        widget.preselectedServiceName != null) {
      _treatmentNameToId[widget.preselectedServiceName!] =
          widget.preselectedTreatmentId!;
    }
    if (widget.preselectedServiceName != null &&
        widget.preselectedServiceName!.isNotEmpty) {
      _selectedTreatment = widget.preselectedServiceName;
    } else {
      _selectedTreatment = defaultTreatment;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitLeadRequest() async {
    if (_isSubmitting || !isEntityUuid(widget.clinic.id)) return;
    if (!AuthState().isLoggedIn || !AuthState().isPatient) return;
    final sessionEpoch = AuthState().sessionEpoch;
    final loc = LocaleService();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_consentAccepted) {
      showAppSnackBar(
        context,
        loc.isArabic
            ? 'يرجى الموافقة على مشاركة البيانات مع العيادة لمتابعة الطلب'
            : 'Please accept consent to share contact details with clinic',
        type: AppSnackBarType.error,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submissionRejection = null;
    });

    // Format phone into E.164: +9715XXXXXXXX
    final rawPhone = _phoneController.text.trim();
    final formattedPhone = LuxuryPhoneInputField.normalizeToE164(rawPhone);

    final actualServiceName =
        widget.selectedOfferTitle != null &&
            widget.selectedOfferTitle!.isNotEmpty
        ? widget.selectedOfferTitle!
        : (_selectedTreatment ??
              (loc.isArabic
                  ? 'استشارة تجميلية وجلدية عامة'
                  : 'General Aesthetic & Derma Consultation'));

    final payload = <String, dynamic>{
      'clinic': widget.clinic.id,
      'consent_accepted': true,
      'service_name': actualServiceName,
      'patient_name': _nameController.text.trim(),
      'patient_phone': formattedPhone,
    };

    final isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );

    final selectedBranch = _selectedBranchId != null
        ? _uniqueBranches[_selectedBranchId]
        : null;
    final selectedPractitioner = _selectedPractitionerId != null
        ? _uniquePractitioners[_selectedPractitionerId]
        : null;

    if (_selectedBranchId != null && isUuid.hasMatch(_selectedBranchId!)) {
      payload['branch'] = _selectedBranchId;
    }

    if (widget.selectedOfferId != null &&
        isUuid.hasMatch(widget.selectedOfferId!)) {
      payload['offer'] = widget.selectedOfferId;
      payload['lead_type'] = 'offer';
    } else {
      final tId = _treatmentNameToId[_selectedTreatment];
      if (tId != null && isUuid.hasMatch(tId)) {
        payload['treatment'] = tId;
      }
    }

    if (_selectedPractitionerId != null &&
        isUuid.hasMatch(_selectedPractitionerId!)) {
      payload['practitioner'] = _selectedPractitionerId;
    }

    if (_notesController.text.trim().isNotEmpty) {
      payload['notes'] = _notesController.text.trim();
    }

    try {
      final result = await _leadsRepository.createLead(payload);

      if (!result.success || result.leadReference.trim().isEmpty) {
        throw const ApiException(
          message: 'The server did not confirm this request.',
        );
      }
      if (!mounted || sessionEpoch != AuthState().sessionEpoch) return;
      setState(() {
        _isSubmitting = false;
      });

      final request = AppointmentRequestModel(
        id: result.leadReference,
        referenceCode: result.leadReference,
        clinicId: widget.clinic.id,
        clinicNameAr: widget.clinic.nameAr,
        clinicNameEn: widget.clinic.nameEn,
        branchId: selectedBranch?.id,
        branchNameAr: selectedBranch?.nameAr ?? widget.clinic.areaAr,
        branchNameEn: selectedBranch?.nameEn ?? widget.clinic.areaEn,
        serviceNameAr: actualServiceName,
        serviceNameEn: actualServiceName,
        practitionerId: selectedPractitioner?.id,
        practitionerNameAr: selectedPractitioner?.nameAr,
        practitionerNameEn: selectedPractitioner?.nameEn,
        practitionerType: selectedPractitioner?.type,
        patientFullName: payload['patient_name'] as String,
        patientPhone: formattedPhone,
        notes: payload['notes'] as String?,
        consentAccepted: true,
        status: AppointmentLeadStatus.sent,
        createdAt: result.createdAt,
      );

      Navigator.pushReplacement(
        context,
        LuxuryPageRoute(
          page: AppointmentSuccessScreen(
            request: request,
            clinic: widget.clinic,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted || sessionEpoch != AuthState().sessionEpoch) return;
      if (e.isCancelled) {
        setState(() => _isSubmitting = false);
        return;
      }
      final is429 = e.statusCode == 429 || e.errorCode == 'DUPLICATE_LEAD';
      final isSuspendedOrInactive =
          e.statusCode == 403 ||
          e.statusCode == 404 ||
          (e.statusCode == 400 &&
              (e.message.toLowerCase().contains('suspended') ||
                  e.message.toLowerCase().contains('inactive') ||
                  e.message.contains('معلقة') ||
                  e.message.contains('غير متاحة') ||
                  e.message.toLowerCase().contains('not found')));
      setState(() {
        _isSubmitting = false;
        if (is429) _submissionRejection = e;
      });
      if (is429) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || sessionEpoch != AuthState().sessionEpoch) return;
          final target = _rejectionKey.currentContext;
          if (target != null) {
            Scrollable.ensureVisible(
              target,
              alignment: .5,
              duration: const Duration(milliseconds: 200),
            );
          }
        });
        return;
      }
      final errorMessage = isSuspendedOrInactive
          ? (loc.isArabic
                ? 'العيادة غير متاحة حالياً لتلقي الطلبات. يرجى اختيار عيادة أخرى'
                : 'This clinic is currently unavailable to accept requests. Please choose another clinic.')
          : e.message;
      showAppSnackBar(context, errorMessage, type: AppSnackBarType.error);
    } catch (e) {
      if (!mounted || sessionEpoch != AuthState().sessionEpoch) return;
      setState(() {
        _isSubmitting = false;
      });
      showAppSnackBar(
        context,
        loc.isArabic
            ? 'فشل إرسال الطلب، يرجى المحاولة مرة أخرى'
            : 'Failed to send request. Please try again.',
        type: AppSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) => PatientDesign(builder: _buildPatient);

  Widget _buildPatient(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    // 1. Resilient Service / Treatment options derived from clinic.rawTreatments
    final defaultTreatment = loc.isArabic
        ? 'استشارة تجميلية وجلدية عامة'
        : 'General Aesthetic & Derma Consultation';
    final Set<String> distinctTreatments = {defaultTreatment};

    if (widget.clinic.rawTreatments != null) {
      for (final raw in widget.clinic.rawTreatments!.take(20)) {
        if (raw is Map<String, dynamic>) {
          final name = loc.isArabic
              ? (raw['name_ar'] ?? raw['name_en'] ?? '').toString().trim()
              : (raw['name_en'] ?? raw['name_ar'] ?? '').toString().trim();
          final id = raw['id']?.toString() ?? '';
          if (name.isNotEmpty) {
            distinctTreatments.add(name);
            if (id.isNotEmpty) _treatmentNameToId[name] = id;
          }
        }
      }
    }

    _selectedTreatment ??= defaultTreatment;

    // 2. Resilient Branch options
    final branchMap = _uniqueBranches;
    if (_selectedBranchId != null &&
        !branchMap.containsKey(_selectedBranchId)) {
      _selectedBranchId = branchMap.isNotEmpty ? branchMap.keys.first : null;
    }
    if (_selectedBranchId == null && branchMap.isNotEmpty) {
      _selectedBranchId = branchMap.keys.first;
    }

    // 3. Resilient Practitioner options
    final practitionerMap = _uniquePractitioners;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        appBar: AppBar(
          backgroundColor: AppColors.bg(context),
          elevation: 0,
          title: Text(
            loc.tr('request_consultation'),
            style: PatientDesign.heading(context, size: 23).copyWith(
              color: isDark
                  ? AppColors.silverPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              size: 18,
              color: isDark
                  ? AppColors.silverPrimary
                  : AppColors.lightTextPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Offer Summary Card (If opened from an offer)
              if (widget.selectedOfferTitle != null &&
                  widget.selectedOfferTitle!.isNotEmpty) ...[
                LuxuryCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentChampagne.withValues(
                            alpha: isDark ? 0.15 : 0.2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_offer_outlined,
                          color: AppColors.accentChampagne,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.isArabic
                                  ? 'باقة العرض المختارة'
                                  : 'Selected Offer Package',
                              style: TextStyle(
                                color: AppColors.goldText(context),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.selectedOfferTitle!,
                              style: AppTypography.cardTitle.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.silverPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Clinic Summary Card
              LuxuryCard(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child:
                          (resolveImageProvider(
                                widget.clinic.primaryPhotoUrl,
                              ) !=
                              null)
                          ? LuxuryImage(
                              imageUrl: widget.clinic.primaryPhotoUrl,
                              width: 106,
                              height: 100,
                              fit: BoxFit.cover,
                              customPlaceholder: Container(
                                width: 82,
                                height: 78,
                                color: isDark
                                    ? AppColors.cardSurfaceHover
                                    : AppColors.lightCardSurfaceHover,
                                child: Icon(
                                  Icons.local_hospital_outlined,
                                  color: isDark
                                      ? AppColors.silverMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                            )
                          : Container(
                              width: 106,
                              height: 100,
                              color: isDark
                                  ? AppColors.cardSurfaceHover
                                  : AppColors.lightCardSurfaceHover,
                              child: Icon(
                                Icons.local_hospital_outlined,
                                color: isDark
                                    ? AppColors.silverMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.isArabic
                                ? 'العيادة المختارة'
                                : 'SELECTED CLINIC',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: loc.isArabic ? 0 : 1,
                              color: AppColors.goldText(context),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            loc.isArabic
                                ? widget.clinic.nameAr
                                : widget.clinic.nameEn,
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 18,
                              fontFamily: loc.isArabic
                                  ? 'PatientArabic'
                                  : 'PatientDisplay',
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.silverPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatClinicLocation(
                              widget.clinic.city,
                              loc.isArabic
                                  ? widget.clinic.areaAr
                                  : widget.clinic.areaEn,
                              arabic: loc.isArabic,
                            ),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.mutedText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Branch Selector
              if (branchMap.length > 1) ...[
                Padding(
                  padding: EdgeInsets.zero,
                  child: PagedEntityField<ClinicBranch>(
                    label: loc.tr('select_branch'),
                    hint: loc.isArabic ? 'ابحث عن الفرع' : 'Search branches',
                    value: _selectedBranchId,
                    valueLabel: branchMap[_selectedBranchId] == null
                        ? ''
                        : (loc.isArabic
                              ? branchMap[_selectedBranchId]!.nameAr
                              : branchMap[_selectedBranchId]!.nameEn),
                    keyOf: (b) => b.id,
                    labelOf: (b) => loc.isArabic ? b.nameAr : b.nameEn,
                    loader: (page, search) async {
                      if (widget.clinic.hasBranchDirectory) {
                        return ClinicsRepository().getBranches(
                          widget.clinic.id,
                          page: page,
                          search: search,
                        );
                      }
                      final all = branchMap.values
                          .where(
                            (b) =>
                                search.isEmpty ||
                                '${b.nameAr} ${b.nameEn}'
                                    .toLowerCase()
                                    .contains(search.toLowerCase()),
                          )
                          .toList();
                      return PageItems(
                        all
                            .skip((page - 1) * catalogPageSize)
                            .take(catalogPageSize),
                        hasMore: page * catalogPageSize < all.length,
                        total: all.length,
                      );
                    },
                    onChanged: (b) => setState(() {
                      _selectedBranch = b;
                      _selectedBranchId = b?.id;
                    }),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Service / Treatment Selection
              Padding(
                padding: EdgeInsets.zero,
                child: PagedEntityField<TreatmentModel>(
                  label: loc.tr('select_service'),
                  hint: loc.isArabic
                      ? 'ابحث عن الخدمة الطبية'
                      : 'Search medical services',
                  value: _treatmentNameToId[_selectedTreatment],
                  valueLabel: _selectedTreatment ?? defaultTreatment,
                  clearLabel: defaultTreatment,
                  keyOf: (t) => t.id,
                  labelOf: (t) => loc.isArabic ? t.nameAr : t.nameEn,
                  loader: (page, search) =>
                      (widget.treatmentsRepository ?? TreatmentsRepository())
                          .getTreatments(
                            clinic: widget.clinic.id,
                            page: page,
                            search: search,
                          ),
                  onChanged: (t) => setState(() {
                    _selectedTreatment = t == null
                        ? defaultTreatment
                        : (loc.isArabic ? t.nameAr : t.nameEn);
                    if (t != null) {
                      _treatmentNameToId[_selectedTreatment!] = t.id;
                    }
                  }),
                ),
              ),
              const SizedBox(height: 14),

              // Preferred Practitioner (Optional)
              ...[
                Padding(
                  padding: EdgeInsets.zero,
                  child: PagedEntityField<PractitionerModel>(
                    label: loc.tr('select_practitioner'),
                    hint: loc.isArabic
                        ? 'ابحث عن الممارس'
                        : 'Search practitioners',
                    value: _selectedPractitionerId,
                    valueLabel:
                        _selectedPractitionerLabel ??
                        (practitionerMap[_selectedPractitionerId] == null
                            ? ''
                            : (loc.isArabic
                                  ? practitionerMap[_selectedPractitionerId]!
                                        .nameAr
                                  : practitionerMap[_selectedPractitionerId]!
                                        .nameEn)),
                    clearLabel: loc.tr('any_practitioner'),
                    keyOf: (p) => p.id,
                    labelOf: (p) => loc.isArabic ? p.nameAr : p.nameEn,
                    loader: (page, search) =>
                        (widget.practitionersRepository ??
                                PractitionersRepository())
                            .getPractitioners(
                              clinicId: widget.clinic.id,
                              page: page,
                              search: search,
                            ),
                    onChanged: (p) => setState(() {
                      _selectedPractitioner = p;
                      _selectedPractitionerId = p?.id;
                      _selectedPractitionerLabel = p == null
                          ? null
                          : (loc.isArabic ? p.nameAr : p.nameEn);
                    }),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Patient Info
              Text(
                loc.tr('contact_info_title'),
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.silverPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: loc.tr('full_name'),
                  hintText: loc.isArabic
                      ? 'الاسم الكامل كما تود أن تناديك العيادة'
                      : 'Your full name',
                  hintStyle: TextStyle(
                    color: AppColors.text(context).withValues(alpha: 0.68),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                  ),
                  labelStyle: TextStyle(
                    color: AppColors.mutedText(context),
                    fontSize: 12.5,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: isDark
                        ? AppColors.silverPrimary
                        : AppColors.primarySoftNavy,
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AppColors.mutedText(context),
                    size: 18,
                  ),
                  filled: true,
                  fillColor: AppColors.surface(context),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.border(context),
                      width: 0.85,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.silverPrimary
                          : AppColors.primarySoftNavy,
                      width: 1.4,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return loc.isArabic
                        ? 'يرجى كتابة الاسم'
                        : 'Please enter full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              LuxuryPhoneInputField(
                controller: _phoneController,
                isRequired: true,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: loc.tr('notes_opt'),
                  hintText: loc.isArabic
                      ? 'اكتب استفسارك أو الإجراء التجميلي المطلوب (اختياري)...'
                      : 'Describe the treatment or consultation you are looking for (optional)...',
                  hintStyle: TextStyle(
                    color: AppColors.text(context).withValues(alpha: 0.68),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                  ),
                  labelStyle: TextStyle(
                    color: AppColors.mutedText(context),
                    fontSize: 12.5,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: isDark
                        ? AppColors.silverPrimary
                        : AppColors.primarySoftNavy,
                    fontWeight: FontWeight.w600,
                  ),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: AppColors.surface(context),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.border(context),
                      width: 0.85,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.silverPrimary
                          : AppColors.primarySoftNavy,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Legal Consent Checkbox
              InkWell(
                onTap: () {
                  setState(() {
                    _consentAccepted = !_consentAccepted;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _consentAccepted,
                      activeColor: AppColors.accentChampagne,
                      checkColor: isDark
                          ? AppColors.backgroundDeep
                          : Colors.white,
                      side: BorderSide(
                        color: AppColors.border(context),
                        width: 1.2,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _consentAccepted = val ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          loc.tr('consent_text'),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.mutedText(context),
                            height: 1.45,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (!isEntityUuid(widget.clinic.id))
                Text(
                  loc.isArabic
                      ? 'العيادة غير متاحة لاستقبال الطلبات'
                      : 'This clinic is unavailable for inquiries',
                ),
              if (_submissionRejection != null) ...[
                LeadRejectionNotice(
                  key: _rejectionKey,
                  error: _submissionRejection!,
                  onViewRequests: _openingRequests
                      ? null
                      : () async {
                          if (_openingRequests) return;
                          setState(() => _openingRequests = true);
                          try {
                            await Navigator.of(context).push(
                              LuxuryPageRoute(
                                page: MyRequestsScreen(
                                  leadsRepository: _leadsRepository,
                                ),
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _openingRequests = false);
                            }
                          }
                        },
                ),
                const SizedBox(height: 14),
              ],
              // Submit the inquiry only after explicit consent.
              SilverButton(
                label: loc.tr('submit_lead_btn'),
                icon: Icons.send_rounded,
                isFullWidth: true,
                height: 48,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting || !isEntityUuid(widget.clinic.id)
                    ? null
                    : _submitLeadRequest,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
