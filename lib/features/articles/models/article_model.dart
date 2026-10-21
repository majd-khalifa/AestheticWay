import '../../../core/utils/source_text.dart';
import 'package:aesthetic_way/core/network/api_config.dart';

/// Medical Aesthetic Awareness & Knowledge Guide Article
/// Published through the clinic by a licensed practitioner/doctor.
class ArticleModel {
  final String id;
  final String slug;
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
  final String? clinicLogoUrl;
  final String categoryAr;
  final String categoryEn;
  final DateTime publishedAt;
  final bool hasPublicationDate;
  final bool isPublished;
  final bool isApprovedByAdmin;
  final String status;

  const ArticleModel({
    required this.id,
    this.slug = '',
    required this.titleAr,
    required this.titleEn,
    required this.coverImageUrl,
    this.summaryAr = '',
    this.summaryEn = '',
    required this.contentAr,
    required this.contentEn,
    this.authorDoctorId = '',
    this.authorDoctorNameAr = '',
    this.authorDoctorNameEn = '',
    this.authorDoctorSpecialtyAr = '',
    this.authorDoctorSpecialtyEn = '',
    this.authorDoctorAvatar = '',
    this.clinicId = '',
    this.clinicNameAr = '',
    this.clinicNameEn,
    this.clinicLogoUrl,
    this.categoryAr = '',
    this.categoryEn = '',
    required this.publishedAt,
    this.hasPublicationDate = true,
    this.isPublished = true,
    this.isApprovedByAdmin = true,
    this.status = 'active',
  });

  ArticleModel copyWith({
    String? id,
    String? slug,
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
    String? clinicLogoUrl,
    String? categoryAr,
    String? categoryEn,
    DateTime? publishedAt,
    bool? isPublished,
    bool? isApprovedByAdmin,
    String? status,
  }) {
    return ArticleModel(
      id: id ?? this.id,
      slug: slug ?? this.slug,
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
      authorDoctorSpecialtyAr:
          authorDoctorSpecialtyAr ?? this.authorDoctorSpecialtyAr,
      authorDoctorSpecialtyEn:
          authorDoctorSpecialtyEn ?? this.authorDoctorSpecialtyEn,
      authorDoctorAvatar: authorDoctorAvatar ?? this.authorDoctorAvatar,
      clinicId: clinicId ?? this.clinicId,
      clinicNameAr: clinicNameAr ?? this.clinicNameAr,
      clinicNameEn: clinicNameEn ?? this.clinicNameEn,
      clinicLogoUrl: clinicLogoUrl ?? this.clinicLogoUrl,
      categoryAr: categoryAr ?? this.categoryAr,
      categoryEn: categoryEn ?? this.categoryEn,
      publishedAt: publishedAt ?? this.publishedAt,
      hasPublicationDate: publishedAt != null || hasPublicationDate,
      isPublished: isPublished ?? this.isPublished,
      isApprovedByAdmin: isApprovedByAdmin ?? this.isApprovedByAdmin,
      status: status ?? this.status,
    );
  }

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    final clinic = json['clinic'] is Map<String, dynamic>
        ? json['clinic'] as Map<String, dynamic>
        : null;
    final rawAuthor = json['author_practitioner'];
    Map<String, dynamic>? authorMap;
    String authorId = '';
    if (rawAuthor is Map<String, dynamic>) {
      authorMap = rawAuthor;
      authorId = rawAuthor['id']?.toString() ?? '';
    } else if (rawAuthor != null) {
      authorId = rawAuthor.toString();
    }

    final rawStatus = json['status']?.toString().toLowerCase() ?? 'active';
    final isPublishedVal = json['is_published'] as bool? ?? true;

    final titleEnVal = firstSourceText([json['title_en'], json['title_ar']]);
    final titleArVal = (json['title_ar'] as String? ?? '').trim().isNotEmpty
        ? json['title_ar'] as String
        : titleEnVal;

    final contentEnVal = firstSourceText([
      json['content_en'],
      json['content_ar'],
    ]);
    final contentArVal = (json['content_ar'] as String? ?? '').trim().isNotEmpty
        ? json['content_ar'] as String
        : contentEnVal;

    return ArticleModel(
      id: json['id']?.toString() ?? '',
      slug: json['slug'] as String? ?? '',
      titleAr: titleArVal,
      titleEn: titleEnVal,
      coverImageUrl: ApiConfig.firstMediaUrl([
        json['cover_image_url'],
        json['cover_image'],
        json['image_url'],
        json['image'],
      ]),
      summaryAr: contentArVal,
      summaryEn: contentEnVal,
      contentAr: contentArVal,
      contentEn: contentEnVal,
      authorDoctorId: authorId,
      authorDoctorNameAr:
          authorMap?['name_ar'] as String? ??
          authorMap?['name_en'] as String? ??
          '',
      authorDoctorNameEn: authorMap?['name_en'] as String? ?? '',
      authorDoctorSpecialtyAr:
          authorMap?['title_ar'] as String? ??
          authorMap?['title_en'] as String? ??
          '',
      authorDoctorSpecialtyEn: authorMap?['title_en'] as String? ?? '',
      authorDoctorAvatar: ApiConfig.firstMediaUrl([
        authorMap?['avatar_url'],
        authorMap?['photo_url'],
        authorMap?['avatar'],
      ]),
      clinicId:
          clinic?['id']?.toString() ?? json['clinic_id']?.toString() ?? '',
      clinicNameAr:
          clinic?['name_ar'] as String? ?? clinic?['name_en'] as String? ?? '',
      clinicNameEn: clinic?['name_en'] as String?,
      clinicLogoUrl: () {
        final res = ApiConfig.firstMediaUrl([
          clinic?['logo'],
          clinic?['logo_url'],
          json['clinic_logo'],
          json['clinic_logo_url'],
        ]);
        return res.isNotEmpty ? res : null;
      }(),
      categoryAr: json['category_ar'] as String? ?? '',
      categoryEn: json['category_en'] as String? ?? '',
      hasPublicationDate:
          DateTime.tryParse('${json['published_at'] ?? json['created_at']}') !=
          null,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'].toString()) ?? DateTime.now()
          : (json['created_at'] != null
                ? DateTime.tryParse(json['created_at'].toString()) ??
                      DateTime.now()
                : DateTime.now()),
      isPublished: isPublishedVal,
      isApprovedByAdmin: json['status'] != null
          ? (rawStatus == 'active')
          : true,
      status: rawStatus,
    );
  }

  /// Converts model into payload for ClinicArticlePortalSerializer (`/api/v1/clinic-portal/articles/`)
  Map<String, dynamic> toPortalJson() {
    final map = <String, dynamic>{
      'title_en': titleEn.trim(),
      'title_ar': titleAr.trim(),
      'content_en': contentEn.trim(),
      'content_ar': contentAr.trim(),
      'is_published': isPublished,
      'status': status,
    };
    if (authorDoctorId.trim().isNotEmpty) {
      map['author_practitioner'] = authorDoctorId.trim();
    } else {
      map['author_practitioner'] = null;
    }
    if (coverImageUrl.trim().isNotEmpty) {
      map['cover_image'] = coverImageUrl.trim();
    }
    return map;
  }
}
