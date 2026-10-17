import 'package:aesthetic_way/core/network/api_config.dart';

/// Product Entity for Aesthetic & Medical Skincare, Cosmeceuticals and Beauty Devices
/// Note: AESTHETIC WAY does not process in-app payments or carts; products are for discovery & lead inquiry.
class ProductModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String clinicId;
  final String clinicNameAr;
  final String? clinicNameEn;
  final String descriptionAr;
  final String descriptionEn;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final String categoryAr;
  final String categoryEn;
  final bool isAvailable;
  final bool isPublishedByAdmin;
  final String status;
  final DateTime? createdAt;
  final String? brandNameEn;
  final String? brandNameAr;
  final String? sponsorCompany;
  final String? clinicLogoUrl;

  const ProductModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.clinicId,
    required this.clinicNameAr,
    this.clinicNameEn,
    this.clinicLogoUrl,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    this.categoryAr = '',
    this.categoryEn = '',
    this.isAvailable = true,
    this.isPublishedByAdmin = true,
    this.status = 'active',
    this.createdAt,
    this.brandNameEn,
    this.brandNameAr,
    this.sponsorCompany,
  });

  ProductModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? clinicId,
    String? clinicNameAr,
    String? clinicNameEn,
    String? descriptionAr,
    String? descriptionEn,
    double? price,
    double? originalPrice,
    String? imageUrl,
    String? categoryAr,
    String? categoryEn,
    bool? isAvailable,
    bool? isPublishedByAdmin,
    String? status,
    DateTime? createdAt,
    String? brandNameEn,
    String? brandNameAr,
    String? sponsorCompany,
    String? clinicLogoUrl,
  }) {
    return ProductModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      clinicId: clinicId ?? this.clinicId,
      clinicNameAr: clinicNameAr ?? this.clinicNameAr,
      clinicNameEn: clinicNameEn ?? this.clinicNameEn,
      clinicLogoUrl: clinicLogoUrl ?? this.clinicLogoUrl,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryAr: categoryAr ?? this.categoryAr,
      categoryEn: categoryEn ?? this.categoryEn,
      isAvailable: isAvailable ?? this.isAvailable,
      isPublishedByAdmin: isPublishedByAdmin ?? this.isPublishedByAdmin,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      brandNameEn: brandNameEn ?? this.brandNameEn,
      brandNameAr: brandNameAr ?? this.brandNameAr,
      sponsorCompany: sponsorCompany ?? this.sponsorCompany,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final clinic = json['clinic'] as Map<String, dynamic>?;
    final rawStatus = json['status']?.toString().toLowerCase() ?? 'active';
    final isActive = json['is_active'] as bool? ?? (rawStatus == 'active');

    final nameEnVal = json['name_en'] as String? ?? '';
    final nameArVal = (json['name_ar'] as String? ?? '').trim().isNotEmpty
        ? json['name_ar'] as String
        : nameEnVal;

    final descEnVal = json['description_en'] as String? ?? '';
    final descArVal = (json['description_ar'] as String? ?? '').trim().isNotEmpty
        ? json['description_ar'] as String
        : descEnVal;

    final clinicLogoRaw = clinic?['logo'] as String? ??
        clinic?['logo_url'] as String? ??
        json['clinic_logo'] as String? ??
        json['clinic_logo_url'] as String?;
    final clinicLogo = ApiConfig.resolveUrl(clinicLogoRaw);

    return ProductModel(
      id: json['id']?.toString() ?? '',
      nameAr: nameArVal,
      nameEn: nameEnVal,
      clinicId: clinic?['id']?.toString() ?? json['clinic_id']?.toString() ?? '',
      clinicNameAr: clinic?['name_ar'] as String? ?? clinic?['name_en'] as String? ?? '',
      clinicNameEn: clinic?['name_en'] as String?,
      clinicLogoUrl: clinicLogo.isNotEmpty ? clinicLogo : null,
      descriptionAr: descArVal,
      descriptionEn: descEnVal,
      price: (json['price'] != null)
          ? (double.tryParse(json['price'].toString()) ?? 0.0)
          : 0.0,
      originalPrice: null,
      imageUrl: ApiConfig.resolveUrl(json['image_url'] as String? ?? json['image'] as String? ?? ''),
      categoryAr: json['category_ar'] as String? ?? '',
      categoryEn: json['category_en'] as String? ?? '',
      isAvailable: isActive,
      isPublishedByAdmin: json['status'] != null ? (rawStatus == 'active') : isActive,
      status: rawStatus,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      brandNameEn: json['brand_name_en'] as String?,
      brandNameAr: json['brand_name_ar'] as String?,
      sponsorCompany: json['sponsor_company'] as String?,
    );
  }

  /// Converts model into payload for ClinicProductPortalSerializer (`/api/v1/clinic-portal/products/`)
  Map<String, dynamic> toPortalJson() {
    final map = <String, dynamic>{
      'name_en': nameEn.trim(),
      'name_ar': nameAr.trim(),
      'description_en': descriptionEn.trim(),
      'description_ar': descriptionAr.trim(),
      'is_active': isAvailable,
      'status': status,
    };
    if (brandNameEn != null && brandNameEn!.trim().isNotEmpty) {
      map['brand_name_en'] = brandNameEn!.trim();
    }
    if (brandNameAr != null && brandNameAr!.trim().isNotEmpty) {
      map['brand_name_ar'] = brandNameAr!.trim();
    }
    if (sponsorCompany != null && sponsorCompany!.trim().isNotEmpty) {
      map['sponsor_company'] = sponsorCompany!.trim();
    }
    if (price > 0) {
      map['price'] = price.toStringAsFixed(2);
    }
    if (imageUrl.trim().isNotEmpty) {
      map['image'] = imageUrl.trim();
    }
    return map;
  }
}
