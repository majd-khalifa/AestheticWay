import 'package:aesthetic_way/core/network/api_config.dart';

class OfferModel {
  final String id;
  final String titleAr;
  final String titleEn;
  final String clinicId;
  final String clinicNameAr;
  final String? clinicNameEn;
  final String? clinicLogoUrl;
  final double originalPrice;
  final double offerPrice;
  final int discountPercentage;
  final String validUntilText;
  final String? validUntilTextEn;
  final int daysRemaining;
  final String termsAr;
  final String? termsEn;
  final String imageUrl;
  final String status;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const OfferModel({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.clinicId,
    required this.clinicNameAr,
    this.clinicNameEn,
    this.clinicLogoUrl,
    required this.originalPrice,
    required this.offerPrice,
    required this.discountPercentage,
    required this.validUntilText,
    this.validUntilTextEn,
    required this.daysRemaining,
    required this.termsAr,
    this.termsEn,
    required this.imageUrl,
    this.status = 'active',
    this.isActive = true,
    this.startsAt,
    this.endsAt,
  });

  OfferModel copyWith({
    String? id,
    String? titleAr,
    String? titleEn,
    String? clinicId,
    String? clinicNameAr,
    String? clinicNameEn,
    String? clinicLogoUrl,
    double? originalPrice,
    double? offerPrice,
    int? discountPercentage,
    String? validUntilText,
    String? validUntilTextEn,
    int? daysRemaining,
    String? termsAr,
    String? termsEn,
    String? imageUrl,
    String? status,
    bool? isActive,
    DateTime? startsAt,
    DateTime? endsAt,
  }) {
    return OfferModel(
      id: id ?? this.id,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      clinicId: clinicId ?? this.clinicId,
      clinicNameAr: clinicNameAr ?? this.clinicNameAr,
      clinicNameEn: clinicNameEn ?? this.clinicNameEn,
      clinicLogoUrl: clinicLogoUrl ?? this.clinicLogoUrl,
      originalPrice: originalPrice ?? this.originalPrice,
      offerPrice: offerPrice ?? this.offerPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      validUntilText: validUntilText ?? this.validUntilText,
      validUntilTextEn: validUntilTextEn ?? this.validUntilTextEn,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      termsAr: termsAr ?? this.termsAr,
      termsEn: termsEn ?? this.termsEn,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
    );
  }

  Map<String, dynamic> toPortalJson() {
    return {
      'title_en': titleEn,
      'title_ar': titleAr,
      'description_en': termsEn ?? '',
      'description_ar': termsAr,
      'original_price': originalPrice,
      'offer_price': offerPrice,
      'starts_at': (startsAt ?? DateTime.now()).toIso8601String(),
      'ends_at': (endsAt ?? DateTime.now().add(const Duration(days: 30))).toIso8601String(),
      'status': status,
      'is_active': isActive,
    };
  }

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    final clinicObj = json['clinic'] is Map<String, dynamic> ? json['clinic'] as Map<String, dynamic> : null;
    final origPrice = double.tryParse(json['original_price']?.toString() ?? '') ?? 0.0;
    final offPrice = double.tryParse(json['offer_price']?.toString() ?? '') ?? 0.0;

    int discount = 0;
    if (origPrice > 0 && offPrice < origPrice) {
      discount = (((origPrice - offPrice) / origPrice) * 100).round();
    }

    // Days remaining and dates from starts_at / ends_at
    int days = 7;
    String validText = 'ساري لفترة محدودة';
    String validTextEn = 'Limited time offer';
    DateTime? sAt;
    DateTime? eAt;

    if (json['starts_at'] != null) {
      sAt = DateTime.tryParse(json['starts_at'].toString());
    }
    if (json['ends_at'] != null) {
      eAt = DateTime.tryParse(json['ends_at'].toString());
      if (eAt != null) {
        final diff = eAt.difference(DateTime.now()).inDays;
        if (diff > 0) {
          days = diff;
          validText = 'متبقي $days يوم';
          validTextEn = '$days days remaining';
        } else if (diff == 0) {
          validText = 'ينتهي اليوم';
          validTextEn = 'Ends today';
        } else {
          validText = 'منتهي';
          validTextEn = 'Expired';
        }
      }
    }

    final rawImg = json['image_url']?.toString() ??
        json['image']?.toString() ??
        (clinicObj != null ? (clinicObj['logo']?.toString() ?? clinicObj['logo_url']?.toString()) : null);
    final img = ApiConfig.resolveUrl(rawImg);

    final rawClinicLogo = clinicObj != null
        ? (clinicObj['logo']?.toString() ?? clinicObj['logo_url']?.toString())
        : (json['clinic_logo']?.toString() ?? json['clinic_logo_url']?.toString());
    final clinicLogo = ApiConfig.resolveUrl(rawClinicLogo);

    return OfferModel(
      id: json['id']?.toString() ?? '',
      titleAr: json['title_ar'] ?? json['title_en'] ?? '',
      titleEn: json['title_en'] ?? json['title_ar'] ?? '',
      clinicId: clinicObj != null
          ? clinicObj['id']?.toString() ?? ''
          : (json['clinic_id']?.toString() ?? ''),
      clinicNameAr: clinicObj != null
          ? (clinicObj['name_ar'] ?? clinicObj['name_en'] ?? '')
          : (json['clinic_name_ar'] ?? ''),
      clinicNameEn: clinicObj != null
          ? (clinicObj['name_en'] ?? clinicObj['name_ar'] ?? '')
          : json['clinic_name_en'],
      clinicLogoUrl: clinicLogo,
      originalPrice: origPrice,
      offerPrice: offPrice,
      discountPercentage: discount,
      validUntilText: validText,
      validUntilTextEn: validTextEn,
      daysRemaining: days,
      termsAr: json['description_ar'] ?? 'تطبق الشروط والأحكام الطبية',
      termsEn: json['description_en'] ?? 'Medical terms and conditions apply',
      imageUrl: img,
      status: json['status']?.toString() ?? 'active',
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
      startsAt: sAt,
      endsAt: eAt,
    );
  }
}
