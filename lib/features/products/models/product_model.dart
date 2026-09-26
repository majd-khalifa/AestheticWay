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

  const ProductModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.clinicId,
    required this.clinicNameAr,
    this.clinicNameEn,
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
  }) {
    return ProductModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      clinicId: clinicId ?? this.clinicId,
      clinicNameAr: clinicNameAr ?? this.clinicNameAr,
      clinicNameEn: clinicNameEn ?? this.clinicNameEn,
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

    return ProductModel(
      id: json['id']?.toString() ?? '',
      nameAr: nameArVal,
      nameEn: nameEnVal,
      clinicId: clinic?['id']?.toString() ?? json['clinic_id']?.toString() ?? '',
      clinicNameAr: clinic?['name_ar'] as String? ?? clinic?['name_en'] as String? ?? '',
      clinicNameEn: clinic?['name_en'] as String?,
      descriptionAr: descArVal,
      descriptionEn: descEnVal,
      price: (json['price'] != null)
          ? (double.tryParse(json['price'].toString()) ?? 0.0)
          : 0.0,
      originalPrice: null,
      imageUrl: json['image_url'] as String? ?? json['image'] as String? ?? '',
      categoryAr: json['category_ar'] as String? ?? '',
      categoryEn: json['category_en'] as String? ?? '',
      isAvailable: isActive,
      isPublishedByAdmin: json['status'] != null ? (rawStatus == 'active') : isActive,
      status: rawStatus,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
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
    if (price >= 0) {
      map['price'] = price.toStringAsFixed(2);
    }
    if (imageUrl.trim().isNotEmpty) {
      map['image'] = imageUrl.trim();
    }
    return map;
  }
}
