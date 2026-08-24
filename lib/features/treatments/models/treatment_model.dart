class TreatmentModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String categoryAr;
  final String categoryEn;
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

  const TreatmentModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.categoryAr,
    required this.categoryEn,
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
  });
}
