/// Review Model for Clinic Patient Experience & Synced Feedback
class ReviewModel {
  final String id;
  final String clinicId;
  final String authorName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool isVerifiedPatient;

  const ReviewModel({
    required this.id,
    required this.clinicId,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isVerifiedPatient = true,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json, {String defaultClinicId = ''}) {
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      clinicId: json['clinic']?.toString() ?? json['clinic_id']?.toString() ?? defaultClinicId,
      authorName: json['patient_name']?.toString() ??
          json['author_name']?.toString() ??
          json['user_name']?.toString() ??
          'Patient',
      rating: double.tryParse(json['rating']?.toString() ?? '') ?? 5.0,
      comment: json['comment']?.toString() ?? json['text']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isVerifiedPatient: json['is_verified_patient'] == true || json['is_verified'] == true,
    );
  }
}
