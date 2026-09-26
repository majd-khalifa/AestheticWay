/// Practitioner types strictly defined in AESTHETIC WAY
enum PractitionerType {
  doctor, // طبيب / Doctor
  nurse, // ممرض مرخص / Licensed Nurse
  licensedProfessional, // أخصائي مرخص / Licensed Professional (Laser/Aesthetician)
}

extension PractitionerTypeExtension on PractitionerType {
  String get value {
    switch (this) {
      case PractitionerType.doctor:
        return 'doctor';
      case PractitionerType.nurse:
        return 'nurse';
      case PractitionerType.licensedProfessional:
        return 'licensed_professional';
    }
  }

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
  final String status;

  const PractitionerModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.type,
    required this.specialtyAr,
    required this.specialtyEn,
    required this.classificationAr,
    this.classificationEn,
    this.licenseAuthority = '',
    this.licenseNumber = '',
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
    this.status = 'active',
  });

  PractitionerModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    PractitionerType? type,
    String? specialtyAr,
    String? specialtyEn,
    String? classificationAr,
    String? classificationEn,
    String? licenseAuthority,
    String? licenseNumber,
    String? avatarUrl,
    int? yearsOfExperience,
    double? rating,
    int? reviewCount,
    List<String>? languages,
    String? clinicId,
    String? clinicNameAr,
    String? clinicNameEn,
    List<String>? procedures,
    List<String>? proceduresEn,
    String? aboutAr,
    String? aboutEn,
    String? status,
  }) {
    return PractitionerModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      type: type ?? this.type,
      specialtyAr: specialtyAr ?? this.specialtyAr,
      specialtyEn: specialtyEn ?? this.specialtyEn,
      classificationAr: classificationAr ?? this.classificationAr,
      classificationEn: classificationEn ?? this.classificationEn,
      licenseAuthority: licenseAuthority ?? this.licenseAuthority,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      languages: languages ?? this.languages,
      clinicId: clinicId ?? this.clinicId,
      clinicNameAr: clinicNameAr ?? this.clinicNameAr,
      clinicNameEn: clinicNameEn ?? this.clinicNameEn,
      procedures: procedures ?? this.procedures,
      proceduresEn: proceduresEn ?? this.proceduresEn,
      aboutAr: aboutAr ?? this.aboutAr,
      aboutEn: aboutEn ?? this.aboutEn,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toPortalJson() {
    return {
      'name_en': nameEn,
      'name_ar': nameAr,
      'title_en': classificationEn ?? specialtyEn,
      'title_ar': classificationAr,
      'speciality_en': specialtyEn,
      'speciality_ar': specialtyAr,
      'type': type.value,
      'bio_en': aboutEn ?? '',
      'bio_ar': aboutAr,
      'status': status,
    };
  }

  factory PractitionerModel.fromJson(
    Map<String, dynamic> json, {
    String clinicId = '',
    String clinicNameAr = '',
    String? clinicNameEn,
  }) {
    PractitionerType pType = PractitionerType.doctor;
    final rawType = json['type']?.toString().toLowerCase() ?? '';
    if (rawType.contains('nurse')) {
      pType = PractitionerType.nurse;
    } else if (rawType.contains('licensed') || rawType.contains('professional') || rawType.contains('laser')) {
      pType = PractitionerType.licensedProfessional;
    }

    String resolvedClinicId = clinicId.isNotEmpty
        ? clinicId
        : (json['clinic_id']?.toString() ?? '');
    String resolvedClinicNameAr = clinicNameAr.isNotEmpty
        ? clinicNameAr
        : (json['clinic_name_ar']?.toString() ?? '');
    String? resolvedClinicNameEn = clinicNameEn ?? json['clinic_name_en']?.toString();

    if (json['clinic'] is Map<String, dynamic>) {
      final clinicMap = json['clinic'] as Map<String, dynamic>;
      if (resolvedClinicId.isEmpty) {
        resolvedClinicId = clinicMap['id']?.toString() ?? '';
      }
      if (resolvedClinicNameAr.isEmpty) {
        resolvedClinicNameAr =
            clinicMap['name_ar']?.toString() ?? clinicMap['name_en']?.toString() ?? '';
      }
      resolvedClinicNameEn ??=
          clinicMap['name_en']?.toString() ?? clinicMap['name_ar']?.toString();
    } else if (json['clinic'] is String && resolvedClinicId.isEmpty) {
      resolvedClinicId = json['clinic'] as String;
    }

    List<String> parsedProcedures = const [];
    List<String>? parsedProceduresEn;
    if (json['procedures'] is List) {
      parsedProcedures = List<String>.from(json['procedures'] as List);
      if (json['procedures_en'] is List) {
        parsedProceduresEn = List<String>.from(json['procedures_en'] as List);
      }
    } else if (json['treatments'] is List) {
      final treatmentsList = json['treatments'] as List;
      parsedProcedures = treatmentsList
          .whereType<Map<String, dynamic>>()
          .map((t) => (t['name_ar'] ?? t['name_en'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();
      parsedProceduresEn = treatmentsList
          .whereType<Map<String, dynamic>>()
          .map((t) => (t['name_en'] ?? t['name_ar'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return PractitionerModel(
      id: json['id']?.toString() ?? '',
      nameAr: json['name_ar'] ?? json['name_en'] ?? '',
      nameEn: json['name_en'] ?? json['name_ar'] ?? '',
      type: pType,
      specialtyAr: json['speciality_ar'] ?? json['title_ar'] ?? 'تجميل وجلدية',
      specialtyEn: json['speciality_en'] ?? json['title_en'] ?? 'Aesthetic & Dermatology',
      classificationAr: json['title_ar'] ?? json['speciality_ar'] ?? 'ممارس معتمد',
      classificationEn: json['title_en'] ?? json['speciality_en'] ?? 'Certified Practitioner',
      licenseAuthority: json['license_authority']?.toString() ?? '',
      licenseNumber: json['license_number']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString() ?? json['photo_url']?.toString() ?? json['avatar']?.toString() ?? '',
      yearsOfExperience: (json['years_of_experience'] ?? json['experience_years']) is int
          ? (json['years_of_experience'] ?? json['experience_years']) as int
          : 5,
      rating: double.tryParse(json['rating']?.toString() ?? '') ?? 4.9,
      reviewCount: json['review_count'] is int ? json['review_count'] as int : 0,
      languages: json['languages'] != null
          ? List<String>.from(json['languages'] as List)
          : const ['العربية', 'English'],
      clinicId: resolvedClinicId,
      clinicNameAr: resolvedClinicNameAr,
      clinicNameEn: resolvedClinicNameEn,
      procedures: parsedProcedures,
      proceduresEn: parsedProceduresEn,
      aboutAr: json['bio_ar'] ?? json['about_ar'] ?? '',
      aboutEn: json['bio_en'] ?? json['about_en'],
      status: json['status']?.toString() ?? 'active',
    );
  }
}
