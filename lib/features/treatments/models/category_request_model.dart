class CategoryRequestModel {
  const CategoryRequestModel({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.status,
    this.clinicName = '',
    this.rejectionReason = '',
    this.resolvedCategoryId,
  });
  final String id, nameEn, nameAr, status, clinicName, rejectionReason;
  final String? resolvedCategoryId;
  factory CategoryRequestModel.fromJson(Map<String, dynamic> json) =>
      CategoryRequestModel(
        id: json['id']?.toString() ?? '',
        nameEn: json['name_en']?.toString() ?? '',
        nameAr: json['name_ar']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        clinicName: json['clinic_name']?.toString() ?? '',
        rejectionReason: json['rejection_reason']?.toString() ?? '',
        resolvedCategoryId: json['resolved_category_id']?.toString(),
      );
}
