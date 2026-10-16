import 'package:flutter/material.dart';

enum ReferralCodeStatus {
  available,
  used,
  expired,
}

ReferralCodeStatus parseReferralCodeStatus(String? status) {
  switch (status?.toLowerCase()) {
    case 'used':
      return ReferralCodeStatus.used;
    case 'expired':
      return ReferralCodeStatus.expired;
    case 'available':
    default:
      return ReferralCodeStatus.available;
  }
}

/// 15% Referral Discount Code Model
class ReferralDiscountCode {
  final String id;
  final String code; // e.g. AW-15-7892
  final double discountPercent; // 15.0
  final ReferralCodeStatus status;
  final String userId;
  final String userName;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final String? usedClinicId;
  final String? usedClinicName;

  const ReferralDiscountCode({
    this.id = '',
    required this.code,
    this.discountPercent = 15.0,
    required this.status,
    this.userId = 'current_user',
    this.userName = 'سارة المنصوري',
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
    this.usedClinicId,
    this.usedClinicName,
  });

  bool get isAvailable => status == ReferralCodeStatus.available;
  bool get isUsed => status == ReferralCodeStatus.used;
  bool get isExpired => status == ReferralCodeStatus.expired || DateTime.now().isAfter(expiresAt);

  factory ReferralDiscountCode.fromJson(Map<String, dynamic> json) {
    DateTime createdAt = DateTime.now();
    if (json['created_at'] != null) {
      createdAt = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    }

    DateTime expiresAt = DateTime.now().add(const Duration(days: 90));
    if (json['expires_at'] != null) {
      expiresAt = DateTime.tryParse(json['expires_at'].toString()) ?? expiresAt;
    }

    DateTime? usedAt;
    if (json['redeemed_at'] != null) {
      usedAt = DateTime.tryParse(json['redeemed_at'].toString());
    }

    return ReferralDiscountCode(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 15.0,
      status: parseReferralCodeStatus(json['status']?.toString()),
      userId: json['patient']?.toString() ?? 'current_user',
      userName: json['patient_name']?.toString() ?? 'سارة المنصوري',
      createdAt: createdAt,
      expiresAt: expiresAt,
      usedAt: usedAt,
      usedClinicId: json['redeemed_clinic']?.toString(),
      usedClinicName: json['redeemed_clinic_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'discount_percent': discountPercent,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'redeemed_at': usedAt?.toIso8601String(),
      'redeemed_clinic': usedClinicId,
    };
  }

  ReferralDiscountCode copyWith({
    String? id,
    String? code,
    double? discountPercent,
    ReferralCodeStatus? status,
    String? userId,
    String? userName,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? usedAt,
    String? usedClinicId,
    String? usedClinicName,
  }) {
    return ReferralDiscountCode(
      id: id ?? this.id,
      code: code ?? this.code,
      discountPercent: discountPercent ?? this.discountPercent,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
      usedClinicId: usedClinicId ?? this.usedClinicId,
      usedClinicName: usedClinicName ?? this.usedClinicName,
    );
  }
}

/// Referral Milestone Model
class ReferralMilestone {
  final int requiredInvites;
  final int pointsAwarded;
  final String titleAr;
  final String titleEn;
  final IconData icon;

  const ReferralMilestone({
    required this.requiredInvites,
    required this.pointsAwarded,
    required this.titleAr,
    required this.titleEn,
    required this.icon,
  });
}

/// Patient Referral Status Model matching GET /api/v1/referral/my-status/
class PatientReferralStatusModel {
  final String referralCode;
  final String inviteLink;
  final int successfulInvitesCount;
  final int totalSuccessfulInvites;
  final int currentPoints;
  final int pointsToCollect;
  final bool canCollectCode;
  final bool pointsExpire;
  final Map<String, bool> milestones;
  final List<ReferralDiscountCode> discountCodes;

  const PatientReferralStatusModel({
    required this.referralCode,
    this.inviteLink = '',
    required this.successfulInvitesCount,
    required this.totalSuccessfulInvites,
    required this.currentPoints,
    this.pointsToCollect = 500,
    required this.canCollectCode,
    this.pointsExpire = false,
    required this.milestones,
    required this.discountCodes,
  });

  factory PatientReferralStatusModel.fromJson(Map<String, dynamic> json) {
    final rawMilestones = json['milestones'] as Map<String, dynamic>? ?? {};
    final milestonesMap = <String, bool>{};
    rawMilestones.forEach((key, val) {
      milestonesMap[key] = val == true;
    });

    final rawCodes = json['discount_codes'] as List<dynamic>? ?? [];
    final codes = rawCodes
        .whereType<Map<String, dynamic>>()
        .map((c) => ReferralDiscountCode.fromJson(c))
        .toList();

    final invites = (json['successful_invites_count'] as num?)?.toInt() ??
        (json['total_successful_invites'] as num?)?.toInt() ??
        0;

    final code = json['referral_code']?.toString() ?? '';
    final link = json['invite_link']?.toString() ??
        (code.isNotEmpty ? 'https://aestheticway.ae/invite/$code' : '');

    return PatientReferralStatusModel(
      referralCode: code,
      inviteLink: link,
      successfulInvitesCount: invites,
      totalSuccessfulInvites: (json['total_successful_invites'] as num?)?.toInt() ?? invites,
      currentPoints: (json['current_points'] as num?)?.toInt() ?? 0,
      pointsToCollect: (json['points_to_collect'] as num?)?.toInt() ?? 500,
      canCollectCode: json['can_collect_code'] == true,
      pointsExpire: json['points_expire'] == true,
      milestones: milestonesMap,
      discountCodes: codes,
    );
  }
}

/// Result of POST /api/v1/referral/collect-code/
class CollectCodeResult {
  final bool success;
  final String code;
  final DateTime? expiresAt;
  final int remainingPoints;

  const CollectCodeResult({
    required this.success,
    required this.code,
    this.expiresAt,
    required this.remainingPoints,
  });

  factory CollectCodeResult.fromJson(Map<String, dynamic> json) {
    DateTime? expiresAt;
    if (json['expires_at'] != null) {
      expiresAt = DateTime.tryParse(json['expires_at'].toString());
    }

    return CollectCodeResult(
      success: json['success'] == true,
      code: json['code']?.toString() ?? '',
      expiresAt: expiresAt,
      remainingPoints: (json['remaining_points'] as num?)?.toInt() ?? 0,
    );
  }
}
