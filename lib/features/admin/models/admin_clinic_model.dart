import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';

/// Branch representation inside Admin Clinic Detail
class AdminClinicBranchModel {
  final String id;
  final String nameEn;
  final String nameAr;
  final String addressEn;
  final String city;
  final String phone;
  final bool isMainBranch;
  final bool isActive;
  final double latitude;
  final double longitude;

  const AdminClinicBranchModel({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.addressEn,
    required this.city,
    required this.phone,
    required this.isMainBranch,
    required this.isActive,
    this.latitude = 25.2048,
    this.longitude = 55.2708,
  });

  factory AdminClinicBranchModel.fromJson(Map<String, dynamic> json) {
    return AdminClinicBranchModel(
      id: json['id']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      nameAr: json['name_ar']?.toString() ?? '',
      addressEn: json['address_en']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isMainBranch: json['is_main_branch'] == true,
      isActive: json['is_active'] != false,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 25.2048,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 55.2708,
    );
  }
}

/// Super Admin Clinic Model for listing, detailed inspection, and status management
class AdminClinicModel {
  final String id;
  final String nameEn;
  final String nameAr;
  final String slug;
  final String city;
  final String emirate;
  final String status; // active, suspended, pending, rejected
  final String setupStatus; // draft, submitted, approved, rejected
  final String licenseNumber;
  final String licenseAuthority;
  final SubscriptionTier subscriptionTier;
  final bool isActive;
  final bool isFeatured;
  final int displayOrder;
  final String phone;
  final String whatsapp;
  final String email;
  final String logo;
  final String coverImage;
  final String? videoAdFile;
  final int branchesCount;
  final int practitionersCount;
  final int treatmentsCount;
  final int offersCount;
  final int productsCount;
  final int articlesCount;
  final int leadsCount;
  final List<AdminClinicBranchModel> branches;
  final Map<String, int> leadsByStatus;
  final String moderationNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminClinicModel({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.slug = '',
    required this.city,
    this.emirate = '',
    required this.status,
    this.setupStatus = 'draft',
    this.licenseNumber = '',
    this.licenseAuthority = 'DHA',
    required this.subscriptionTier,
    required this.isActive,
    this.isFeatured = false,
    this.displayOrder = 0,
    this.phone = '',
    this.whatsapp = '',
    this.email = '',
    this.logo = '',
    this.coverImage = '',
    this.videoAdFile,
    this.branchesCount = 0,
    this.practitionersCount = 0,
    this.treatmentsCount = 0,
    this.offersCount = 0,
    this.productsCount = 0,
    this.articlesCount = 0,
    this.leadsCount = 0,
    this.branches = const [],
    this.leadsByStatus = const {},
    this.moderationNotes = '',
    this.createdAt,
    this.updatedAt,
  });

  bool get isSuspended => status.toLowerCase() == 'suspended';
  String get coverImageUrl => coverImage;
  String get areaAr => city;
  String get areaEn => city;
  double get latitude =>
      branches.isNotEmpty ? branches.first.latitude : 25.2048;
  double get longitude =>
      branches.isNotEmpty ? branches.first.longitude : 55.2708;

  factory AdminClinicModel.fromJson(Map<String, dynamic> json) {
    SubscriptionTier tier = SubscriptionTier.basic;
    final rawTier = json['subscription_tier']?.toString().toLowerCase() ?? '';
    if (rawTier == 'vip' || rawTier == 'vipplatinum') {
      tier = SubscriptionTier.vipPlatinum;
    } else if (rawTier == 'featured') {
      tier = SubscriptionTier.featured;
    }

    List<AdminClinicBranchModel> parsedBranches = [];
    if (json['branches'] is List) {
      parsedBranches = (json['branches'] as List)
          .whereType<Map<String, dynamic>>()
          .map((b) => AdminClinicBranchModel.fromJson(b))
          .toList();
    }

    Map<String, int> parseCountMap(dynamic raw) {
      if (raw is Map) {
        return raw.map(
          (k, v) => MapEntry(k.toString(), (v is num) ? v.toInt() : 0),
        );
      }
      return {};
    }

    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return null;
      }
    }

    return AdminClinicModel(
      id: json['id']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      nameAr: json['name_ar']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      emirate: json['emirate']?.toString() ?? '',
      status: json['status']?.toString().toLowerCase() ?? 'active',
      setupStatus: json['setup_status']?.toString() ?? 'draft',
      licenseNumber: json['license_number']?.toString() ?? '',
      licenseAuthority: json['license_authority']?.toString() ?? 'DHA',
      subscriptionTier: tier,
      isActive:
          json['is_active'] != false &&
          json['status']?.toString().toLowerCase() != 'suspended',
      isFeatured: json['is_featured'] == true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      phone: json['phone']?.toString() ?? '',
      whatsapp: json['whatsapp']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      logo: ApiConfig.firstMediaUrl([json['logo'], json['logo_url']]),
      coverImage: ApiConfig.firstMediaUrl([
        json['cover_image'],
        json['cover_image_url'],
      ]),
      videoAdFile: () {
        final raw =
            json['video_ad_file']?.toString() ?? json['video_url']?.toString();
        final res = ApiConfig.resolveUrl(raw);
        return res.isNotEmpty ? res : null;
      }(),
      branchesCount:
          (json['branches_count'] as num?)?.toInt() ?? parsedBranches.length,
      practitionersCount: (json['practitioners_count'] as num?)?.toInt() ?? 0,
      treatmentsCount: (json['treatments_count'] as num?)?.toInt() ?? 0,
      offersCount: (json['offers_count'] as num?)?.toInt() ?? 0,
      productsCount: (json['products_count'] as num?)?.toInt() ?? 0,
      articlesCount: (json['articles_count'] as num?)?.toInt() ?? 0,
      leadsCount: (json['leads_count'] as num?)?.toInt() ?? 0,
      branches: parsedBranches,
      leadsByStatus: parseCountMap(json['leads_by_status']),
      moderationNotes: json['moderation_notes']?.toString() ?? '',
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  AdminClinicModel copyWith({
    String? status,
    String? setupStatus,
    String? licenseNumber,
    String? licenseAuthority,
    bool? isActive,
    SubscriptionTier? subscriptionTier,
    String? moderationNotes,
  }) {
    return AdminClinicModel(
      id: id,
      nameEn: nameEn,
      nameAr: nameAr,
      slug: slug,
      city: city,
      emirate: emirate,
      status: status ?? this.status,
      setupStatus: setupStatus ?? this.setupStatus,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseAuthority: licenseAuthority ?? this.licenseAuthority,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured,
      displayOrder: displayOrder,
      phone: phone,
      whatsapp: whatsapp,
      email: email,
      logo: logo,
      coverImage: coverImage,
      branchesCount: branchesCount,
      practitionersCount: practitionersCount,
      treatmentsCount: treatmentsCount,
      offersCount: offersCount,
      productsCount: productsCount,
      articlesCount: articlesCount,
      leadsCount: leadsCount,
      branches: branches,
      leadsByStatus: leadsByStatus,
      moderationNotes: moderationNotes ?? this.moderationNotes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
