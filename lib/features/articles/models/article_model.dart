/// Medical Aesthetic Awareness & Knowledge Guide Article
/// Published through the clinic by a licensed practitioner/doctor.
class ArticleModel {
  final String id;
  final String titleAr;
  final String titleEn;
  final String coverImageUrl;
  final String summaryAr;
  final String summaryEn;
  final String contentAr;
  final String contentEn;
  final String authorDoctorId;
  final String authorDoctorNameAr;
  final String authorDoctorNameEn;
  final String authorDoctorSpecialtyAr;
  final String authorDoctorSpecialtyEn;
  final String authorDoctorAvatar;
  final String clinicId;
  final String clinicNameAr;
  final String? clinicNameEn;
  final String categoryAr;
  final String categoryEn;
  final DateTime publishedAt;
  final bool isPublished;
  final bool isApprovedByAdmin;

  const ArticleModel({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.coverImageUrl,
    required this.summaryAr,
    required this.summaryEn,
    required this.contentAr,
    required this.contentEn,
    required this.authorDoctorId,
    required this.authorDoctorNameAr,
    required this.authorDoctorNameEn,
    required this.authorDoctorSpecialtyAr,
    required this.authorDoctorSpecialtyEn,
    required this.authorDoctorAvatar,
    required this.clinicId,
    required this.clinicNameAr,
    this.clinicNameEn,
    required this.categoryAr,
    required this.categoryEn,
    required this.publishedAt,
    this.isPublished = true,
    this.isApprovedByAdmin = true,
  });

  ArticleModel copyWith({
    String? id,
    String? titleAr,
    String? titleEn,
    String? coverImageUrl,
    String? summaryAr,
    String? summaryEn,
    String? contentAr,
    String? contentEn,
    String? authorDoctorId,
    String? authorDoctorNameAr,
    String? authorDoctorNameEn,
    String? authorDoctorSpecialtyAr,
    String? authorDoctorSpecialtyEn,
    String? authorDoctorAvatar,
    String? clinicId,
    String? clinicNameAr,
    String? clinicNameEn,
    String? categoryAr,
    String? categoryEn,
    DateTime? publishedAt,
    bool? isPublished,
    bool? isApprovedByAdmin,
  }) {
    return ArticleModel(
      id: id ?? this.id,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      summaryAr: summaryAr ?? this.summaryAr,
      summaryEn: summaryEn ?? this.summaryEn,
      contentAr: contentAr ?? this.contentAr,
      contentEn: contentEn ?? this.contentEn,
      authorDoctorId: authorDoctorId ?? this.authorDoctorId,
      authorDoctorNameAr: authorDoctorNameAr ?? this.authorDoctorNameAr,
      authorDoctorNameEn: authorDoctorNameEn ?? this.authorDoctorNameEn,
      authorDoctorSpecialtyAr: authorDoctorSpecialtyAr ?? this.authorDoctorSpecialtyAr,
      authorDoctorSpecialtyEn: authorDoctorSpecialtyEn ?? this.authorDoctorSpecialtyEn,
      authorDoctorAvatar: authorDoctorAvatar ?? this.authorDoctorAvatar,
      clinicId: clinicId ?? this.clinicId,
      clinicNameAr: clinicNameAr ?? this.clinicNameAr,
      clinicNameEn: clinicNameEn ?? this.clinicNameEn,
      categoryAr: categoryAr ?? this.categoryAr,
      categoryEn: categoryEn ?? this.categoryEn,
      publishedAt: publishedAt ?? this.publishedAt,
      isPublished: isPublished ?? this.isPublished,
      isApprovedByAdmin: isApprovedByAdmin ?? this.isApprovedByAdmin,
    );
  }
}
