class TreatmentModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String categoryAr;
  final String categoryEn;
  final String? categoryId;
  final String descriptionAr;
  final String? descriptionEn;
  final String durationText;
  final String? durationTextEn;
  final String downtimeText;
  final String? downtimeTextEn;
  final String targetAreaAr;
  final String? targetAreaEn;
  final int clinicsCount;
  final String imageUrl;
  final String? clinicId;
  final String? clinicNameAr;
  final String? clinicNameEn;
  final double? price;
  final String status;
  final bool isActive;
  final List<String> practitionerIds;

  const TreatmentModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.categoryAr,
    required this.categoryEn,
    this.categoryId,
    required this.descriptionAr,
    this.descriptionEn,
    required this.durationText,
    this.durationTextEn,
    required this.downtimeText,
    this.downtimeTextEn,
    required this.targetAreaAr,
    this.targetAreaEn,
    required this.clinicsCount,
    required this.imageUrl,
    this.clinicId,
    this.clinicNameAr,
    this.clinicNameEn,
    this.price,
    this.status = 'active',
    this.isActive = true,
    this.practitionerIds = const [],
  });

  TreatmentModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? categoryAr,
    String? categoryEn,
    String? categoryId,
    String? descriptionAr,
    String? descriptionEn,
    String? durationText,
    String? durationTextEn,
    String? downtimeText,
    String? downtimeTextEn,
    String? targetAreaAr,
    String? targetAreaEn,
    int? clinicsCount,
    String? imageUrl,
    String? clinicId,
    String? clinicNameAr,
    String? clinicNameEn,
    double? price,
    String? status,
    bool? isActive,
    List<String>? practitionerIds,
  }) {
    return TreatmentModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      categoryAr: categoryAr ?? this.categoryAr,
      categoryEn: categoryEn ?? this.categoryEn,
      categoryId: categoryId ?? this.categoryId,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      durationText: durationText ?? this.durationText,
      durationTextEn: durationTextEn ?? this.durationTextEn,
      downtimeText: downtimeText ?? this.downtimeText,
      downtimeTextEn: downtimeTextEn ?? this.downtimeTextEn,
      targetAreaAr: targetAreaAr ?? this.targetAreaAr,
      targetAreaEn: targetAreaEn ?? this.targetAreaEn,
      clinicsCount: clinicsCount ?? this.clinicsCount,
      imageUrl: imageUrl ?? this.imageUrl,
      clinicId: clinicId ?? this.clinicId,
      clinicNameAr: clinicNameAr ?? this.clinicNameAr,
      clinicNameEn: clinicNameEn ?? this.clinicNameEn,
      price: price ?? this.price,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      practitionerIds: practitionerIds ?? this.practitionerIds,
    );
  }

  Map<String, dynamic> toPortalJson() {
    return {
      if (categoryId != null && categoryId!.isNotEmpty) 'category': categoryId,
      'name_en': nameEn,
      'name_ar': nameAr,
      'description_en': descriptionEn ?? '',
      'description_ar': descriptionAr,
      if (price != null) 'price': price,
      'status': status,
      'is_active': isActive,
      'practitioners': practitionerIds,
    };
  }

  factory TreatmentModel.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] is Map<String, dynamic> ? json['category'] as Map<String, dynamic> : null;
    final catId = cat != null
        ? cat['id']?.toString()
        : json['category']?.toString();
    final catAr = cat != null
        ? (cat['name_ar'] ?? cat['name_en'] ?? '')
        : (json['category_name_ar'] ?? json['category_name'] ?? json['category_ar'] ?? '');
    final catEn = cat != null
        ? (cat['name_en'] ?? cat['name_ar'] ?? '')
        : (json['category_name_en'] ?? json['category_name'] ?? json['category_en'] ?? '');

    final clinicMap = json['clinic'] is Map<String, dynamic> ? json['clinic'] as Map<String, dynamic> : null;
    final parsedClinicId = clinicMap != null ? clinicMap['id']?.toString() : json['clinic_id']?.toString();
    final parsedClinicNameAr = clinicMap != null ? clinicMap['name_ar']?.toString() : json['clinic_name_ar']?.toString();
    final parsedClinicNameEn = clinicMap != null ? clinicMap['name_en']?.toString() : json['clinic_name_en']?.toString();

    final durationMins = json['duration_minutes'];
    final defaultDurationAr = durationMins != null ? '$durationMins دقيقة' : '30 - 45 دقيقة';
    final defaultDurationEn = durationMins != null ? '$durationMins mins' : '30 - 45 mins';

    final practs = json['practitioners'] is List
        ? (json['practitioners'] as List)
            .map((p) => p is Map ? (p['id']?.toString() ?? '') : p.toString())
            .where((id) => id.isNotEmpty)
            .toList()
        : <String>[];

    return TreatmentModel(
      id: json['id']?.toString() ?? '',
      nameAr: json['name_ar'] ?? json['name_en'] ?? '',
      nameEn: json['name_en'] ?? json['name_ar'] ?? '',
      categoryAr: catAr.isNotEmpty ? catAr : 'إجراء تجميلي',
      categoryEn: catEn.isNotEmpty ? catEn : 'Aesthetic Procedure',
      categoryId: catId,
      descriptionAr: json['description_ar'] ?? '',
      descriptionEn: json['description_en'],
      durationText: json['duration_text'] ?? defaultDurationAr,
      durationTextEn: json['duration_text_en'] ?? defaultDurationEn,
      downtimeText: json['downtime_text'] ?? 'بدون فترة نقاهة',
      downtimeTextEn: json['downtime_text_en'] ?? 'No downtime',
      targetAreaAr: json['target_area_ar'] ?? 'الوجه والرقبة',
      targetAreaEn: json['target_area_en'] ?? 'Face & Neck',
      clinicsCount: json['clinics_count'] is int ? json['clinics_count'] as int : 1,
      imageUrl: json['image_url'] ?? '',
      clinicId: parsedClinicId,
      clinicNameAr: parsedClinicNameAr,
      clinicNameEn: parsedClinicNameEn,
      price: double.tryParse(json['price']?.toString() ?? ''),
      status: json['status']?.toString() ?? 'active',
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
      practitionerIds: practs,
    );
  }
}
