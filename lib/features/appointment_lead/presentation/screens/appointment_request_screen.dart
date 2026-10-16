import 'package:aesthetic_way/core/widgets/luxury_phone_input_field.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/widgets/practitioner_badge.dart';
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
  final String? selectedOfferTitle;
  final String? selectedOfferId;
  final LeadsRepository? leadsRepository;

  const AppointmentRequestScreen({
    super.key,
    required this.clinic,
    this.preselectedPractitioner,
    this.preselectedServiceName,
    this.selectedOfferTitle,
    this.selectedOfferId,
    this.leadsRepository,
  });

  @override
  State<AppointmentRequestScreen> createState() => _AppointmentRequestScreenState();
}

class _AppointmentRequestScreenState extends State<AppointmentRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  final TextEditingController _notesController = TextEditingController();
  late final LeadsRepository _leadsRepository;

  String? _selectedBranchId;
  String? _selectedTreatment;
  String? _selectedPractitionerId;
  final PreferredTimeWindow _timeWindow = PreferredTimeWindow.evening;
  bool _consentAccepted = false;
  bool _isSubmitting = false;
  String? _rateLimitBannerMessage;

  final Map<String, String> _treatmentNameToId = {};

  Map<String, ClinicBranch> get _uniqueBranches {
    final Map<String, ClinicBranch> map = {};
    for (final b in widget.clinic.branches) {
      if (b.id.isNotEmpty && !map.containsKey(b.id)) {
        map[b.id] = b;
      }
    }
    return map;
  }

  Map<String, PractitionerModel> get _uniquePractitioners {
    final Map<String, PractitionerModel> map = {};
    if (widget.clinic.rawPractitioners != null) {
      for (final raw in widget.clinic.rawPractitioners!) {
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
    return map;
  }

  @override
  void initState() {
    super.initState();
    _leadsRepository = widget.leadsRepository ?? LeadsRepository();
    final auth = AuthState();
    _nameController = TextEditingController(text: auth.isLoggedIn ? auth.userName : '');
    
    // Clean local phone digits without country code prefix
    String initialPhone = '';
    if (auth.isLoggedIn && auth.userPhone.isNotEmpty) {
      final clean = auth.userPhone.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.startsWith('971')) {
        initialPhone = clean.substring(3);
      } else if (clean.startsWith('0')) {
        initialPhone = clean.substring(1);
      } else {
        initialPhone = clean;
      }
    }
    _phoneController = TextEditingController(text: initialPhone);

    if (widget.clinic.branches.isNotEmpty) {
      _selectedBranchId = widget.clinic.branches.first.id;
    }

    _selectedPractitionerId = widget.preselectedPractitioner?.id;

    // Build initial treatment options from clinic.rawTreatments
    final defaultTreatment = 'استشارة تجميلية وجلدية عامة';
    final Set<String> validOptions = {defaultTreatment};

    if (widget.clinic.rawTreatments != null) {
      for (final raw in widget.clinic.rawTreatments!) {
        if (raw is Map<String, dynamic>) {
          final nameAr = (raw['name_ar'] ?? raw['name_en'] ?? '').toString().trim();
          final nameEn = (raw['name_en'] ?? raw['name_ar'] ?? '').toString().trim();
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

    if (widget.preselectedServiceName != null &&
        widget.preselectedServiceName!.isNotEmpty &&
        validOptions.contains(widget.preselectedServiceName)) {
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
    if (_isSubmitting) return;
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
      _rateLimitBannerMessage = null;
    });

    // Format phone into E.164: +9715XXXXXXXX
    final rawPhone = _phoneController.text.trim();
    final formattedPhone = LuxuryPhoneInputField.normalizeToE164(rawPhone);

    final actualServiceName = widget.selectedOfferTitle != null && widget.selectedOfferTitle!.isNotEmpty
        ? widget.selectedOfferTitle!
        : (_selectedTreatment ?? (loc.isArabic ? 'استشارة تجميلية وجلدية عامة' : 'General Aesthetic & Derma Consultation'));

    final payload = <String, dynamic>{
      'clinic': widget.clinic.id,
      'consent_accepted': true,
      'service_name': actualServiceName,
      'patient_name': _nameController.text.trim(),
      'patient_phone': formattedPhone,
      'preferred_time_window': _timeWindow.name,
    };

    final isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

    final selectedBranch = _selectedBranchId != null ? _uniqueBranches[_selectedBranchId] : null;
    final selectedPractitioner = _selectedPractitionerId != null ? _uniquePractitioners[_selectedPractitionerId] : null;

    if (_selectedBranchId != null && isUuid.hasMatch(_selectedBranchId!)) {
      payload['branch'] = _selectedBranchId;
    }

    if (widget.selectedOfferId != null && isUuid.hasMatch(widget.selectedOfferId!)) {
      payload['offer'] = widget.selectedOfferId;
      payload['lead_type'] = 'offer';
    } else {
      final tId = _treatmentNameToId[_selectedTreatment];
      if (tId != null && isUuid.hasMatch(tId)) {
        payload['treatment'] = tId;
      }
    }

    if (_selectedPractitionerId != null && isUuid.hasMatch(_selectedPractitionerId!)) {
      payload['practitioner'] = _selectedPractitionerId;
    }

    if (_notesController.text.trim().isNotEmpty) {
      payload['notes'] = _notesController.text.trim();
    }

    try {
      final result = await _leadsRepository.createLead(payload);

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      final request = AppointmentRequestModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        referenceCode: result.leadReference.isNotEmpty
            ? result.leadReference
            : '#REQ-${10000 + Random().nextInt(89999)}',
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
        preferredDate: DateTime.now(),
        preferredTimeWindow: _timeWindow,
        patientFullName: _nameController.text.trim(),
        patientPhone: formattedPhone,
        notes: _notesController.text.trim(),
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
      if (!mounted) return;
      final is429 = e.statusCode == 429 ||
          e.message.contains('already submitted') ||
          e.message.contains('too many requests') ||
          e.message.contains('مؤخراً') ||
          e.message.contains('مؤخرا');
      final isSuspendedOrInactive = e.statusCode == 403 ||
          e.statusCode == 404 ||
          (e.statusCode == 400 && (e.message.toLowerCase().contains('suspended') ||
              e.message.toLowerCase().contains('inactive') ||
              e.message.contains('معلقة') ||
              e.message.contains('غير متاحة') ||
              e.message.toLowerCase().contains('not found')));
      setState(() {
        _isSubmitting = false;
        if (is429) {
          _rateLimitBannerMessage = loc.isArabic
              ? 'يرجى الانتظار لحظات قبل إرسال طلب جديد لنفس العيادة'
              : 'Please wait a moment before submitting another request to this clinic';
        }
      });
      final errorMessage = is429
          ? (loc.isArabic
              ? 'تم إرسال طلب مشابه مؤخرًا. يرجى المحاولة بعد قليل'
              : 'A similar request was recently submitted. Please try again shortly.')
          : isSuspendedOrInactive
              ? (loc.isArabic
                  ? 'العيادة غير متاحة حالياً لتلقي الطلبات. يرجى اختيار عيادة أخرى'
                  : 'This clinic is currently unavailable to accept requests. Please choose another clinic.')
              : e.message;
      showAppSnackBar(
        context,
        errorMessage,
        type: AppSnackBarType.error,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      showAppSnackBar(
        context,
        loc.isArabic ? 'فشل إرسال الطلب، يرجى المحاولة مرة أخرى' : 'Failed to send request. Please try again.',
        type: AppSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    // 1. Resilient Service / Treatment options derived from clinic.rawTreatments
    final defaultTreatment = loc.isArabic ? 'استشارة تجميلية وجلدية عامة' : 'General Aesthetic & Derma Consultation';
    final Set<String> distinctTreatments = {defaultTreatment};

    if (widget.clinic.rawTreatments != null) {
      for (final raw in widget.clinic.rawTreatments!) {
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
    final treatmentList = distinctTreatments.toList();

    if (_selectedTreatment == null || !distinctTreatments.contains(_selectedTreatment)) {
      _selectedTreatment = defaultTreatment;
    }

    // 2. Resilient Branch options
    final branchMap = _uniqueBranches;
    if (_selectedBranchId != null && !branchMap.containsKey(_selectedBranchId)) {
      _selectedBranchId = branchMap.isNotEmpty ? branchMap.keys.first : null;
    }
    if (_selectedBranchId == null && branchMap.isNotEmpty) {
      _selectedBranchId = branchMap.keys.first;
    }

    // 3. Resilient Practitioner options
    final practitionerMap = _uniquePractitioners;
    if (_selectedPractitionerId != null && !practitionerMap.containsKey(_selectedPractitionerId)) {
      _selectedPractitionerId = null;
    }

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        appBar: AppBar(
          backgroundColor: AppColors.bg(context),
          elevation: 0,
          title: Text(
            loc.tr('request_consultation'),
            style: AppTypography.screenTitle.copyWith(
              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              size: 18,
              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
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
              if (widget.selectedOfferTitle != null && widget.selectedOfferTitle!.isNotEmpty) ...[
                LuxuryCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.15 : 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_offer_outlined, color: AppColors.accentChampagne, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.isArabic ? 'باقة العرض المختارة' : 'Selected Offer Package',
                              style: const TextStyle(
                                color: AppColors.accentChampagne,
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
                                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
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

              if (_rateLimitBannerMessage != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_top_rounded, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _rateLimitBannerMessage!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: const Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Clinic Summary Card
              LuxuryCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: (widget.clinic.coverImageUrl.isNotEmpty && widget.clinic.coverImageUrl.startsWith('http'))
                          ? Image.network(
                              widget.clinic.coverImageUrl,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 52,
                                height: 52,
                                color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                                child: Icon(
                                  Icons.local_hospital_outlined,
                                  color: isDark ? AppColors.silverMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            )
                          : Container(
                              width: 52,
                              height: 52,
                              color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                              child: Icon(
                                Icons.local_hospital_outlined,
                                color: isDark ? AppColors.silverMuted : AppColors.lightTextMuted,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.isArabic ? widget.clinic.nameAr : widget.clinic.nameEn,
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.clinic.city} • ${loc.isArabic ? widget.clinic.areaAr : widget.clinic.areaEn}',
                            style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Branch Selector
              if (branchMap.isNotEmpty) ...[
                Text(
                  loc.tr('select_branch'),
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                LuxuryCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedBranchId,
                      isExpanded: true,
                      dropdownColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                      iconEnabledColor: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      items: branchMap.values.map((b) {
                        return DropdownMenuItem<String?>(
                          value: b.id,
                          child: Text(
                            loc.isArabic ? '${b.nameAr} (${b.areaAr})' : '${b.nameEn} (${b.areaEn})',
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedBranchId = val;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Service / Treatment Selection
              Text(
                loc.tr('select_service'),
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              LuxuryCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTreatment,
                    isExpanded: true,
                    dropdownColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                    iconEnabledColor: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    items: treatmentList.map((tName) {
                      return DropdownMenuItem<String>(
                        value: tName,
                        child: Text(
                          tName,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedTreatment = val;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Preferred Practitioner (Optional)
              if (practitionerMap.isNotEmpty) ...[
                Text(
                  loc.tr('select_practitioner'),
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                LuxuryCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedPractitionerId,
                      isExpanded: true,
                      dropdownColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                      iconEnabledColor: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      hint: Text(
                        loc.tr('any_practitioner'),
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedText(context)),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            loc.tr('any_practitioner'),
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        ...practitionerMap.values.map((p) {
                          return DropdownMenuItem<String?>(
                            value: p.id,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    loc.isArabic ? p.nameAr : p.nameEn,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PractitionerBadge(type: p.type, showIcon: false),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedPractitionerId = val;
                        });
                      },
                    ),
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
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: loc.tr('full_name'),
                    labelStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12.5),
                    floatingLabelStyle: TextStyle(
                      color: isDark ? AppColors.silverPrimary : AppColors.primarySoftNavy,
                      fontWeight: FontWeight.w600,
                    ),
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.mutedText(context), size: 18),
                    filled: true,
                    fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context), width: 0.85),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.silverPrimary : AppColors.primarySoftNavy,
                        width: 1.4,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return loc.isArabic ? 'يرجى كتابة الاسم' : 'Please enter full name';
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
                    color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: loc.tr('notes_opt'),
                    labelStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12.5),
                    floatingLabelStyle: TextStyle(
                      color: isDark ? AppColors.silverPrimary : AppColors.primarySoftNavy,
                      fontWeight: FontWeight.w600,
                    ),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context), width: 0.85),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.silverPrimary : AppColors.primarySoftNavy,
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
                        checkColor: isDark ? AppColors.backgroundDeep : Colors.white,
                        side: BorderSide(color: AppColors.border(context), width: 1.2),
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
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Telegram-like Smooth Submit Button
                SilverButton(
                  label: loc.tr('submit_lead_btn'),
                  icon: Icons.send_rounded,
                  isFullWidth: true,
                  height: 48,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submitLeadRequest,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
  }
}
