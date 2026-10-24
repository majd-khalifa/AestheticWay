import '../../../core/network/api_config.dart';

/// Allowed review fields only. Never forward regulatory identifiers to widgets.
class AdminReviewMedia {
  const AdminReviewMedia({
    required this.id,
    required this.url,
    this.mimeType = '',
  });
  final String id, url, mimeType;
  factory AdminReviewMedia.fromJson(Map<String, dynamic> j) => AdminReviewMedia(
    id: '${j['id'] ?? ''}',
    url: ApiConfig.firstMediaUrl([j['url']]),
    mimeType: '${j['mime_type'] ?? ''}',
  );
  bool get isImage =>
      url.isNotEmpty &&
      (mimeType.isEmpty || mimeType.startsWith('image/')) &&
      !RegExp(
        r'\.(mp4|mov|webm)(?:[?#]|$)',
        caseSensitive: false,
      ).hasMatch(url);
}

class AdminReviewPractitioner {
  const AdminReviewPractitioner({
    required this.id,
    this.nameEn = '',
    this.nameAr = '',
    this.titleEn = '',
    this.titleAr = '',
    this.specialityEn = '',
    this.specialityAr = '',
    this.type = '',
    this.status = '',
    this.avatar = '',
  });
  final String id,
      nameEn,
      nameAr,
      titleEn,
      titleAr,
      specialityEn,
      specialityAr,
      type,
      status,
      avatar;
  factory AdminReviewPractitioner.fromJson(Map<String, dynamic> j) =>
      AdminReviewPractitioner(
        id: '${j['id'] ?? ''}',
        nameEn: '${j['name_en'] ?? ''}',
        nameAr: '${j['name_ar'] ?? ''}',
        titleEn: '${j['title_en'] ?? ''}',
        titleAr: '${j['title_ar'] ?? ''}',
        specialityEn: '${j['speciality_en'] ?? ''}',
        specialityAr: '${j['speciality_ar'] ?? ''}',
        type: '${j['type'] ?? ''}',
        status: '${j['status'] ?? ''}',
        avatar: ApiConfig.firstMediaUrl([j['avatar_url']]),
      );
}

class AdminReviewTreatment {
  const AdminReviewTreatment({
    required this.id,
    this.nameEn = '',
    this.nameAr = '',
    this.categoryName = '',
    this.status = '',
    this.isActive = false,
  });
  final String id, nameEn, nameAr, categoryName, status;
  final bool isActive;
  factory AdminReviewTreatment.fromJson(Map<String, dynamic> j) =>
      AdminReviewTreatment(
        id: '${j['id'] ?? ''}',
        nameEn: '${j['name_en'] ?? ''}',
        nameAr: '${j['name_ar'] ?? ''}',
        categoryName: '${j['category_name'] ?? ''}',
        status: '${j['status'] ?? ''}',
        isActive: j['is_active'] == true,
      );
}
