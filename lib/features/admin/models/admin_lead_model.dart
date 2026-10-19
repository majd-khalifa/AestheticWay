import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';

/// Read-only Lead representation for Super Admin Supervision
class AdminLeadModel {
  final String id;
  final String referenceCode;
  final String status; // new, contacted, closed
  final String leadType; // consultation, treatment, offer, product
  final String serviceName;
  final String clinicId;
  final String clinicNameEn;
  final String clinicNameAr;
  final String clinicCity;
  final String clinicPhone;
  final String branchNameEn;
  final String practitionerNameEn;
  final String treatmentNameEn;
  final String offerTitleEn;
  final String patientName;
  final String patientPhone;
  final String patientEmail;
  final String preferredTimeWindow; // morning, afternoon, evening
  final String notes;
  final bool consentAccepted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  String get patientFullName => patientName;
  String get serviceNameAr => serviceName;
  String get serviceNameEn => serviceName;
  String get branchNameAr => branchNameEn.isNotEmpty ? branchNameEn : clinicCity;

  AppointmentLeadStatus get leadStatus {
    switch (status.toLowerCase()) {
      case 'contacted':
        return AppointmentLeadStatus.contacted;
      case 'closed':
      case 'confirmed':
      case 'completed':
        return AppointmentLeadStatus.closed;
      case 'new':
      case 'sent':
      default:
        return AppointmentLeadStatus.sent;
    }
  }

  const AdminLeadModel({
    required this.id,
    required this.referenceCode,
    required this.status,
    required this.leadType,
    required this.serviceName,
    required this.clinicId,
    required this.clinicNameEn,
    required this.clinicNameAr,
    this.clinicCity = '',
    this.clinicPhone = '',
    this.branchNameEn = '',
    this.practitionerNameEn = '',
    this.treatmentNameEn = '',
    this.offerTitleEn = '',
    required this.patientName,
    required this.patientPhone,
    this.patientEmail = '',
    this.preferredTimeWindow = 'morning',
    this.notes = '',
    this.consentAccepted = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory AdminLeadModel.fromJson(Map<String, dynamic> json) {
    final clinic = json['clinic'] is Map ? json['clinic'] as Map<String, dynamic> : <String, dynamic>{};
    final branch = json['branch'] is Map ? json['branch'] as Map<String, dynamic> : <String, dynamic>{};
    final practitioner = json['practitioner'] is Map ? json['practitioner'] as Map<String, dynamic> : <String, dynamic>{};
    final treatment = json['treatment'] is Map ? json['treatment'] as Map<String, dynamic> : <String, dynamic>{};
    final offer = json['offer'] is Map ? json['offer'] as Map<String, dynamic> : <String, dynamic>{};

    DateTime parsedCreated = DateTime.now();
    if (json['created_at'] != null) {
      parsedCreated = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    }

    DateTime? parsedUpdated;
    if (json['updated_at'] != null) {
      parsedUpdated = DateTime.tryParse(json['updated_at'].toString());
    }

    return AdminLeadModel(
      id: json['id']?.toString() ?? '',
      referenceCode: json['reference_code']?.toString() ?? '',
      status: json['status']?.toString().toLowerCase() ?? 'new',
      leadType: json['lead_type']?.toString().toLowerCase() ?? 'consultation',
      serviceName: json['service_name']?.toString() ?? '',
      clinicId: clinic['id']?.toString() ?? '',
      clinicNameEn: clinic['name_en']?.toString() ?? '',
      clinicNameAr: clinic['name_ar']?.toString() ?? (clinic['name_en']?.toString() ?? ''),
      clinicCity: clinic['city']?.toString() ?? '',
      clinicPhone: clinic['phone']?.toString() ?? '',
      branchNameEn: branch['name_en']?.toString() ?? '',
      practitionerNameEn: practitioner['name_en']?.toString() ?? '',
      treatmentNameEn: treatment['name_en']?.toString() ?? '',
      offerTitleEn: offer['title_en']?.toString() ?? '',
      patientName: json['patient_name']?.toString() ?? '',
      patientPhone: json['patient_phone']?.toString() ?? '',
      patientEmail: json['patient_email']?.toString() ?? '',
      preferredTimeWindow: json['preferred_time_window']?.toString().toLowerCase() ?? 'morning',
      notes: json['notes']?.toString() ?? '',
      consentAccepted: json['consent_accepted'] == true,
      createdAt: parsedCreated,
      updatedAt: parsedUpdated,
    );
  }
}
