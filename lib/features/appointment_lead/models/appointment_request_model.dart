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

/// Lead Generation Request Entity
class AppointmentRequestModel {
  final String id;
  final String referenceCode; // e.g. #REQ-98241
  final String clinicId;
  final String clinicNameAr;
  final String? clinicNameEn;
  final String branchNameAr;
  final String? branchNameEn;
  final String serviceNameAr;
  final String? serviceNameEn;
  final String? practitionerId;
  final String? practitionerNameAr;
  final String? practitionerNameEn;
  final PractitionerType? practitionerType;
  final DateTime preferredDate;
  final PreferredTimeWindow preferredTimeWindow;
  final String patientFullName;
  final String patientPhone;
  final String? notes;
  final bool consentAccepted;
  final AppointmentLeadStatus status;
  final DateTime createdAt;

  const AppointmentRequestModel({
    required this.id,
    required this.referenceCode,
    required this.clinicId,
    required this.clinicNameAr,
    this.clinicNameEn,
    required this.branchNameAr,
    this.branchNameEn,
    required this.serviceNameAr,
    this.serviceNameEn,
    this.practitionerId,
    this.practitionerNameAr,
    this.practitionerNameEn,
    this.practitionerType,
    required this.preferredDate,
    required this.preferredTimeWindow,
    required this.patientFullName,
    required this.patientPhone,
    this.notes,
    required this.consentAccepted,
    required this.status,
    required this.createdAt,
  });
}
