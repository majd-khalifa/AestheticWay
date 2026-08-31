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
    required this.categoryAr,
    required this.categoryEn,
    this.isAvailable = true,
    this.isPublishedByAdmin = true,
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
    );
  }
}
