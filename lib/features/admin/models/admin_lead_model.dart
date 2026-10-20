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
  final String storedBranchNameAr, storedServiceNameEn, storedServiceNameAr;
  final String treatmentNameAr, offerTitleAr, productNameEn, productNameAr;
  final String practitionerNameEn;
  final String treatmentNameEn;
  final String offerTitleEn;
  final String patientName;
  final String patientPhone;
  final String patientEmail;
  final String preferredTimeWindow; // morning, afternoon, evening
  final String notes;
  final bool consentAccepted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get patientFullName => patientName;
  String get serviceNameAr => localizedService(arabic: true);
  String get serviceNameEn => localizedService(arabic: false);
  String get branchNameAr =>
      storedBranchNameAr.isNotEmpty ? storedBranchNameAr : branchNameEn;
  String localizedClinic({required bool arabic}) => _first(
    arabic ? [clinicNameAr, clinicNameEn] : [clinicNameEn, clinicNameAr],
  );
  String localizedService({required bool arabic}) => _first(
    arabic
        ? [
            storedServiceNameAr,
            treatmentNameAr,
            offerTitleAr,
            productNameAr,
            serviceName,
            storedServiceNameEn,
            treatmentNameEn,
            offerTitleEn,
            productNameEn,
          ]
        : [
            storedServiceNameEn,
            treatmentNameEn,
            offerTitleEn,
            productNameEn,
            serviceName,
            storedServiceNameAr,
            treatmentNameAr,
            offerTitleAr,
            productNameAr,
          ],
  );
  static String _first(List<String> values) =>
      values.where((v) => v.trim().isNotEmpty).firstOrNull ?? '';

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
    this.storedBranchNameAr = '',
    this.storedServiceNameEn = '',
    this.storedServiceNameAr = '',
    this.treatmentNameAr = '',
    this.offerTitleAr = '',
    this.productNameEn = '',
    this.productNameAr = '',
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
    final clinic = json['clinic'] is Map
        ? json['clinic'] as Map<String, dynamic>
        : <String, dynamic>{};
    final branch = json['branch'] is Map
        ? json['branch'] as Map<String, dynamic>
        : <String, dynamic>{};
    final practitioner = json['practitioner'] is Map
        ? json['practitioner'] as Map<String, dynamic>
        : <String, dynamic>{};
    final treatment = json['treatment'] is Map
        ? json['treatment'] as Map<String, dynamic>
        : <String, dynamic>{};
    final offer = json['offer'] is Map
        ? json['offer'] as Map<String, dynamic>
        : <String, dynamic>{};

    final parsedCreated = DateTime.tryParse(
      json['created_at']?.toString() ?? '',
    );

    DateTime? parsedUpdated;
    if (json['updated_at'] != null) {
      parsedUpdated = DateTime.tryParse(json['updated_at'].toString());
    }

    return AdminLeadModel(
      id: json['id']?.toString() ?? '',
      referenceCode: json['reference_code']?.toString() ?? '',
      status: json['status']?.toString().toLowerCase() ?? 'unknown',
      leadType: json['lead_type']?.toString().toLowerCase() ?? 'consultation',
      serviceName: json['service_name']?.toString() ?? '',
      storedServiceNameEn: json['service_name_en']?.toString() ?? '',
      storedServiceNameAr: json['service_name_ar']?.toString() ?? '',
      storedBranchNameAr: branch['name_ar']?.toString() ?? '',
      treatmentNameAr: treatment['name_ar']?.toString() ?? '',
      offerTitleAr: offer['title_ar']?.toString() ?? '',
      productNameEn: json['product'] is Map
          ? json['product']['name_en']?.toString() ?? ''
          : '',
      productNameAr: json['product'] is Map
          ? json['product']['name_ar']?.toString() ?? ''
          : '',
      clinicId: clinic['id']?.toString() ?? '',
      clinicNameEn: clinic['name_en']?.toString() ?? '',
      clinicNameAr:
          clinic['name_ar']?.toString() ??
          (clinic['name_en']?.toString() ?? ''),
      clinicCity: clinic['city']?.toString() ?? '',
      clinicPhone: clinic['phone']?.toString() ?? '',
      branchNameEn: branch['name_en']?.toString() ?? '',
      practitionerNameEn: practitioner['name_en']?.toString() ?? '',
      treatmentNameEn: treatment['name_en']?.toString() ?? '',
      offerTitleEn: offer['title_en']?.toString() ?? '',
      patientName: json['patient_name']?.toString() ?? '',
      patientPhone: json['patient_phone']?.toString() ?? '',
      patientEmail: json['patient_email']?.toString() ?? '',
      preferredTimeWindow:
          json['preferred_time_window']?.toString().toLowerCase() ?? 'morning',
      notes: json['notes']?.toString() ?? '',
      consentAccepted: json['consent_accepted'] == true,
      createdAt: parsedCreated,
      updatedAt: parsedUpdated,
    );
  }
}
