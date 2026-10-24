import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';

/// Status of the Appointment Request (Lead only)
enum AppointmentLeadStatus {
  sent, // تم الإرسال (awaiting clinic reception contact)
  contacted, // تم التواصل (clinic contacted user via call/WhatsApp)
  closed, // مغلق (inquiry completed or archived)
}

extension AppointmentLeadStatusExtension on AppointmentLeadStatus {
  String get labelAr {
    switch (this) {
      case AppointmentLeadStatus.sent:
        return 'تم الإرسال';
      case AppointmentLeadStatus.contacted:
        return 'تم التواصل';
      case AppointmentLeadStatus.closed:
        return 'مغلق';
    }
  }

  String get labelEn {
    switch (this) {
      case AppointmentLeadStatus.sent:
        return 'Sent';
      case AppointmentLeadStatus.contacted:
        return 'Contacted';
      case AppointmentLeadStatus.closed:
        return 'Closed';
    }
  }
}

/// Preferred Time Window for Lead Request
enum PreferredTimeWindow {
  morning, // صباحاً
  afternoon, // ظهراً
  evening, // مساءً
}

extension PreferredTimeWindowExtension on PreferredTimeWindow {
  String get labelAr {
    switch (this) {
      case PreferredTimeWindow.morning:
        return 'الفترة الصباحية (9 ص - 12 م)';
      case PreferredTimeWindow.afternoon:
        return 'فترة الظهيرة (12 م - 4 م)';
      case PreferredTimeWindow.evening:
        return 'الفترة المسائية (4 م - 9 م)';
    }
  }

  String get labelEn {
    switch (this) {
      case PreferredTimeWindow.morning:
        return 'Morning (9 AM - 12 PM)';
      case PreferredTimeWindow.afternoon:
        return 'Afternoon (12 PM - 4 PM)';
      case PreferredTimeWindow.evening:
        return 'Evening (4 PM - 9 PM)';
    }
  }
}

class ClinicInternalNote {
  final String id;
  final String authorName;
  final String note;
  final DateTime createdAt;

  const ClinicInternalNote({
    required this.id,
    required this.authorName,
    required this.note,
    required this.createdAt,
  });

  factory ClinicInternalNote.fromJson(Map<String, dynamic> json) {
    DateTime createdAt = DateTime.now();
    if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at'].toString());
      } catch (_) {}
    }
    return ClinicInternalNote(
      id: json['id']?.toString() ?? '',
      authorName: json['author_name']?.toString() ?? 'Staff',
      note: json['note']?.toString() ?? '',
      createdAt: createdAt,
    );
  }
}

/// Lead Generation Request Entity
class AppointmentRequestModel {
  final String id;
  final String referenceCode; // e.g. #REQ-98241
  final String clinicId;
  final String clinicNameAr;
  final String? clinicNameEn;
  final String? clinicPhone;
  final String? clinicWhatsapp;
  final String? clinicLogoUrl;
  final String? branchId;
  final String branchNameAr;
  final String? branchNameEn;
  final String serviceNameAr;
  final String? serviceNameEn;
  final String? practitionerId;
  final String? practitionerNameAr;
  final String? practitionerNameEn;
  final PractitionerType? practitionerType;
  final DateTime? preferredDate;
  final PreferredTimeWindow? preferredTimeWindow;
  final String patientFullName;
  final String patientPhone;
  final String? notes;
  final bool consentAccepted;
  final AppointmentLeadStatus status;
  final DateTime createdAt;
  final String? leadType;
  final String? treatmentId;
  final String? offerId;
  final String? offerTitleAr;
  final String? offerTitleEn;
  final bool hasNotesDirectory;
  final List<ClinicInternalNote> internalNotes;

  const AppointmentRequestModel({
    required this.id,
    required this.referenceCode,
    required this.clinicId,
    required this.clinicNameAr,
    this.clinicNameEn,
    this.clinicPhone,
    this.clinicWhatsapp,
    this.clinicLogoUrl,
    this.branchId,
    required this.branchNameAr,
    this.branchNameEn,
    required this.serviceNameAr,
    this.serviceNameEn,
    this.practitionerId,
    this.practitionerNameAr,
    this.practitionerNameEn,
    this.practitionerType,
    this.preferredDate,
    this.preferredTimeWindow,
    required this.patientFullName,
    required this.patientPhone,
    this.notes,
    required this.consentAccepted,
    required this.status,
    required this.createdAt,
    this.leadType,
    this.treatmentId,
    this.offerId,
    this.offerTitleAr,
    this.offerTitleEn,
    this.hasNotesDirectory = false,
    this.internalNotes = const [],
  });

  /// Patient history must never manufacture a reference, date or sent status.
  factory AppointmentRequestModel.fromPatientJson(Map<String, dynamic> json) {
    final reference = json['reference_code']?.toString().trim() ?? '';
    final submitted = DateTime.tryParse(json['created_at']?.toString() ?? '');
    if (reference.isEmpty ||
        submitted == null ||
        !const ['new', 'contacted', 'closed'].contains(json['status']) ||
        (json['id']?.toString().trim().isEmpty ?? true)) {
      throw const FormatException('Incomplete patient request record');
    }
    String name(Object? summary, String arKey, String enKey) {
      if (summary is! Map) return '';
      final ar = summary[arKey]?.toString().trim() ?? '';
      final en = summary[enKey]?.toString().trim() ?? '';
      return ar.isNotEmpty ? ar : en;
    }

    final clinic = json['clinic_summary'];
    final branch = json['branch_summary'];
    final practitioner = json['practitioner_summary'];
    final service =
        json['product_summary'] ??
        json['treatment_summary'] ??
        json['offer_summary'];
    final isOffer =
        json['offer_summary'] != null &&
        json['product_summary'] == null &&
        json['treatment_summary'] == null;
    final serviceAr = name(
      service,
      isOffer ? 'title_ar' : 'name_ar',
      isOffer ? 'title_en' : 'name_en',
    );
    final serviceEn = name(
      service,
      isOffer ? 'title_en' : 'name_en',
      isOffer ? 'title_ar' : 'name_ar',
    );
    final submittedService = json['service_name']?.toString().trim() ?? '';
    final parsed = AppointmentRequestModel.fromJson({
      ...json,
      // Defence in depth if a misconfigured endpoint includes staff-only data.
      // Clinic/Admin consumers of fromJson retain their operational fields.
      'internal_notes': const <Map<String, dynamic>>[],
      'notes_directory_url': null,
    });
    return parsed.copyWith(
      referenceCode: reference,
      createdAt: submitted,
      clinicNameAr: name(clinic, 'name_ar', 'name_en'),
      clinicNameEn: name(clinic, 'name_en', 'name_ar'),
      branchNameAr: name(branch, 'name_ar', 'name_en'),
      branchNameEn: name(branch, 'name_en', 'name_ar'),
      serviceNameAr: serviceAr.isNotEmpty ? serviceAr : submittedService,
      serviceNameEn: serviceEn.isNotEmpty ? serviceEn : submittedService,
      practitionerNameAr: name(practitioner, 'name_ar', 'name_en'),
      practitionerNameEn: name(practitioner, 'name_en', 'name_ar'),
    );
  }

  factory AppointmentRequestModel.fromJson(Map<String, dynamic> json) {
    // 1. Status mapping: backend returns 'new', 'contacted', 'closed'
    final rawStatus = (json['status'] ?? '').toString().toLowerCase();
    AppointmentLeadStatus status;
    switch (rawStatus) {
      case 'contacted':
        status = AppointmentLeadStatus.contacted;
        break;
      case 'closed':
        status = AppointmentLeadStatus.closed;
        break;
      case 'new':
      case 'sent':
      default:
        status = AppointmentLeadStatus.sent;
        break;
    }

    // 2. Preferred time window: 'morning', 'afternoon', 'evening'
    final rawWindow = (json['preferred_time_window'] ?? '')
        .toString()
        .toLowerCase();
    PreferredTimeWindow? timeWindow;
    switch (rawWindow) {
      case 'morning':
        timeWindow = PreferredTimeWindow.morning;
        break;
      case 'afternoon':
        timeWindow = PreferredTimeWindow.afternoon;
        break;
      case 'evening':
        timeWindow = PreferredTimeWindow.evening;
        break;
      default:
        timeWindow = null;
        break;
    }

    // 3. Summaries extraction
    final clinicSummary = json['clinic_summary'] as Map<String, dynamic>?;
    final branchSummary = json['branch_summary'] as Map<String, dynamic>?;
    final practitionerSummary =
        json['practitioner_summary'] as Map<String, dynamic>?;
    final treatmentSummary = json['treatment_summary'] as Map<String, dynamic>?;
    final offerSummary = json['offer_summary'] as Map<String, dynamic>?;
    final productSummary = json['product_summary'] as Map<String, dynamic>?;

    final clinicId =
        json['clinic']?.toString() ?? clinicSummary?['id']?.toString() ?? '';
    final clinicNameAr =
        clinicSummary?['name_ar']?.toString() ??
        json['clinic_name_ar']?.toString() ??
        'عيادة تجميلية';
    final clinicNameEn =
        clinicSummary?['name_en']?.toString() ??
        json['clinic_name_en']?.toString() ??
        json['clinic_name']?.toString() ??
        'Aesthetic Clinic';

    final branchNameAr =
        branchSummary?['name_ar']?.toString() ??
        json['branch_name_ar']?.toString() ??
        'الفرع الرئيسي';
    final branchNameEn =
        branchSummary?['name_en']?.toString() ??
        json['branch_name_en']?.toString() ??
        'Main Branch';

    // Service / Product / Offer name
    String serviceNameAr = json['service_name']?.toString() ?? '';
    String? serviceNameEn = json['service_name_en']?.toString();
    if (productSummary != null) {
      serviceNameAr =
          productSummary['name_ar']?.toString() ??
          productSummary['name_en']?.toString() ??
          serviceNameAr;
      serviceNameEn =
          productSummary['name_en']?.toString() ??
          productSummary['name_ar']?.toString() ??
          serviceNameEn;
    } else if (treatmentSummary != null) {
      serviceNameAr = treatmentSummary['name_ar']?.toString() ?? serviceNameAr;
      serviceNameEn = treatmentSummary['name_en']?.toString() ?? serviceNameEn;
    } else if (offerSummary != null) {
      serviceNameAr = offerSummary['title_ar']?.toString() ?? serviceNameAr;
      serviceNameEn = offerSummary['title_en']?.toString() ?? serviceNameEn;
    }
    if (serviceNameAr.isEmpty) {
      serviceNameAr =
          (json['lead_type']?.toString() == 'product' ||
              json['lead_type']?.toString() == 'product_inquiry')
          ? 'استفسار عن منتج طبي'
          : 'استشارة تجميلية وجلدية عامة';
    }

    // Practitioner summary
    String? practitionerId =
        json['practitioner']?.toString() ??
        practitionerSummary?['id']?.toString();
    String? practitionerNameAr =
        practitionerSummary?['name_ar']?.toString() ??
        json['practitioner_name_ar']?.toString();
    String? practitionerNameEn =
        practitionerSummary?['name_en']?.toString() ??
        json['practitioner_name_en']?.toString();
    PractitionerType? practitionerType;
    final rawType =
        (practitionerSummary?['type'] ?? json['practitioner_type'] ?? '')
            .toString()
            .toLowerCase();
    if (rawType.contains('nurse')) {
      practitionerType = PractitionerType.nurse;
    } else if (rawType.contains('licensed')) {
      practitionerType = PractitionerType.licensedProfessional;
    } else if (rawType.contains('doctor')) {
      practitionerType = PractitionerType.doctor;
    }

    DateTime createdAt = DateTime.now();
    if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at'].toString());
      } catch (_) {}
    }

    final preferredDate = DateTime.tryParse(
      json['preferred_date']?.toString() ?? '',
    );

    return AppointmentRequestModel(
      id: json['id']?.toString() ?? '',
      referenceCode: json['reference_code']?.toString() ?? '#REQ-00000',
      clinicId: clinicId,
      clinicNameAr: clinicNameAr,
      clinicNameEn: clinicNameEn,
      clinicPhone: clinicSummary?['phone']?.toString(),
      clinicWhatsapp: clinicSummary?['whatsapp']?.toString(),
      clinicLogoUrl: clinicSummary?['logo_url']?.toString(),
      branchId: json['branch']?.toString() ?? branchSummary?['id']?.toString(),
      branchNameAr: branchNameAr,
      branchNameEn: branchNameEn,
      serviceNameAr: serviceNameAr,
      serviceNameEn: serviceNameEn,
      practitionerId: practitionerId,
      practitionerNameAr: practitionerNameAr,
      practitionerNameEn: practitionerNameEn,
      practitionerType: practitionerType,
      preferredDate: preferredDate,
      preferredTimeWindow: timeWindow,
      patientFullName:
          json['patient_name']?.toString() ??
          json['patient_full_name']?.toString() ??
          '',
      patientPhone: json['patient_phone']?.toString() ?? '',
      notes: json['notes']?.toString(),
      consentAccepted: json['consent_accepted'] == true,
      status: status,
      createdAt: createdAt,
      leadType: json['lead_type']?.toString(),
      treatmentId:
          json['treatment']?.toString() ?? treatmentSummary?['id']?.toString(),
      offerId: json['offer']?.toString() ?? offerSummary?['id']?.toString(),
      offerTitleAr: offerSummary?['title_ar']?.toString(),
      offerTitleEn: offerSummary?['title_en']?.toString(),
      hasNotesDirectory: json['notes_directory_url'] != null,
      internalNotes: (json['internal_notes'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((n) => ClinicInternalNote.fromJson(n))
          .toList(),
    );
  }

  bool get isProductInquiry =>
      leadType == 'product' || leadType == 'product_inquiry';

  AppointmentRequestModel copyWith({
    String? id,
    String? referenceCode,
    String? clinicId,
    String? clinicNameAr,
    String? clinicNameEn,
    String? clinicPhone,
    String? clinicWhatsapp,
    String? clinicLogoUrl,
    String? branchId,
    String? branchNameAr,
    String? branchNameEn,
    String? serviceNameAr,
    String? serviceNameEn,
    String? practitionerId,
    String? practitionerNameAr,
    String? practitionerNameEn,
    PractitionerType? practitionerType,
    DateTime? preferredDate,
    PreferredTimeWindow? preferredTimeWindow,
    String? patientFullName,
    String? patientPhone,
    String? notes,
    bool? consentAccepted,
    AppointmentLeadStatus? status,
    DateTime? createdAt,
    String? leadType,
    String? treatmentId,
    String? offerId,
    String? offerTitleAr,
    String? offerTitleEn,
    bool? hasNotesDirectory,
    List<ClinicInternalNote>? internalNotes,
  }) {
    return AppointmentRequestModel(
      id: id ?? this.id,
      referenceCode: referenceCode ?? this.referenceCode,
      clinicId: clinicId ?? this.clinicId,
      clinicNameAr: clinicNameAr ?? this.clinicNameAr,
      clinicNameEn: clinicNameEn ?? this.clinicNameEn,
      clinicPhone: clinicPhone ?? this.clinicPhone,
      clinicWhatsapp: clinicWhatsapp ?? this.clinicWhatsapp,
      clinicLogoUrl: clinicLogoUrl ?? this.clinicLogoUrl,
      branchId: branchId ?? this.branchId,
      branchNameAr: branchNameAr ?? this.branchNameAr,
      branchNameEn: branchNameEn ?? this.branchNameEn,
      serviceNameAr: serviceNameAr ?? this.serviceNameAr,
      serviceNameEn: serviceNameEn ?? this.serviceNameEn,
      practitionerId: practitionerId ?? this.practitionerId,
      practitionerNameAr: practitionerNameAr ?? this.practitionerNameAr,
      practitionerNameEn: practitionerNameEn ?? this.practitionerNameEn,
      practitionerType: practitionerType ?? this.practitionerType,
      preferredDate: preferredDate ?? this.preferredDate,
      preferredTimeWindow: preferredTimeWindow ?? this.preferredTimeWindow,
      patientFullName: patientFullName ?? this.patientFullName,
      patientPhone: patientPhone ?? this.patientPhone,
      notes: notes ?? this.notes,
      consentAccepted: consentAccepted ?? this.consentAccepted,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      leadType: leadType ?? this.leadType,
      treatmentId: treatmentId ?? this.treatmentId,
      offerId: offerId ?? this.offerId,
      offerTitleAr: offerTitleAr ?? this.offerTitleAr,
      offerTitleEn: offerTitleEn ?? this.offerTitleEn,
      hasNotesDirectory: hasNotesDirectory ?? this.hasNotesDirectory,
      internalNotes: internalNotes ?? this.internalNotes,
    );
  }

  Map<String, dynamic> toCreatePayload() {
    final payload = <String, dynamic>{
      'clinic': clinicId,
      'consent_accepted': consentAccepted,
    };
    if (branchId != null && branchId!.isNotEmpty) {
      payload['branch'] = branchId;
    }
    if (serviceNameAr.isNotEmpty) {
      payload['service_name'] = serviceNameAr;
    }
    if (patientFullName.isNotEmpty) {
      payload['patient_name'] = patientFullName;
    }
    if (patientPhone.isNotEmpty) {
      payload['patient_phone'] = patientPhone;
    }
    if (notes != null && notes!.trim().isNotEmpty) {
      payload['notes'] = notes!.trim();
    }
    payload['preferred_time_window'] = '';
    // Historical scheduling metadata is never resubmitted by the lead-only UI.
    if (leadType != null && leadType!.isNotEmpty) {
      payload['lead_type'] = leadType == 'product'
          ? 'product_inquiry'
          : leadType;
    }
    if (practitionerId != null && practitionerId!.isNotEmpty) {
      payload['practitioner'] = practitionerId;
    }
    if (treatmentId != null && treatmentId!.isNotEmpty) {
      payload['treatment'] = treatmentId;
    }
    if (offerId != null && offerId!.isNotEmpty) {
      payload['offer'] = offerId;
    }
    return payload;
  }
}
