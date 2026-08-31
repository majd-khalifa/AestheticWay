/// Practitioner types strictly defined in AESTHETIC WAY
enum PractitionerType {
  doctor, // طبيب / Doctor
  nurse, // ممرض مرخص / Licensed Nurse
  licensedProfessional, // أخصائي مرخص / Licensed Professional (Laser/Aesthetician)
}

extension PractitionerTypeExtension on PractitionerType {
  String get labelAr {
    switch (this) {
      case PractitionerType.doctor:
        return 'طبيب';
      case PractitionerType.nurse:
        return 'ممرض مرخص';
      case PractitionerType.licensedProfessional:
        return 'أخصائي مرخص';
    }
  }

  String get labelEn {
    switch (this) {
      case PractitionerType.doctor:
        return 'Doctor';
      case PractitionerType.nurse:
        return 'Licensed Nurse';
      case PractitionerType.licensedProfessional:
        return 'Licensed Professional';
    }
  }
}

/// Healthcare professional entity
class PractitionerModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final PractitionerType type;
  final String specialtyAr;
  final String specialtyEn;
  final String classificationAr; // e.g. استشاري أول جلدية وتجميل
  final String? classificationEn; // e.g. Senior Consultant Dermatologist
  final String licenseAuthority; // DHA, DOH, MOHAP
  final String licenseNumber; // e.g. DHA-P-004812
  final String avatarUrl;
  final int yearsOfExperience;
  final double rating;
  final int reviewCount;
  final List<String> languages;
  final String clinicId;
  final String clinicNameAr;
  final String? clinicNameEn;
  final List<String> procedures;
  final List<String>? proceduresEn;
  final String aboutAr;
  final String? aboutEn;

  const PractitionerModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.type,
    required this.specialtyAr,
    required this.specialtyEn,
    required this.classificationAr,
    this.classificationEn,
    required this.licenseAuthority,
    required this.licenseNumber,
    required this.avatarUrl,
    required this.yearsOfExperience,
    required this.rating,
    required this.reviewCount,
    required this.languages,
    required this.clinicId,
    required this.clinicNameAr,
    this.clinicNameEn,
    required this.procedures,
    this.proceduresEn,
    required this.aboutAr,
    this.aboutEn,
  });
}
