import 'package:flutter/material.dart';

enum ReferralCodeStatus {
  available,
  used,
  expired,
}

/// 15% Referral Discount Code Model
class ReferralDiscountCode {
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
    required this.code,
    this.discountPercent = 15.0,
    required this.status,
    required this.userId,
    required this.userName,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
    this.usedClinicId,
    this.usedClinicName,
  });

  bool get isAvailable => status == ReferralCodeStatus.available;
  bool get isUsed => status == ReferralCodeStatus.used;
  bool get isExpired => status == ReferralCodeStatus.expired || DateTime.now().isAfter(expiresAt);

  ReferralDiscountCode copyWith({
    ReferralCodeStatus? status,
    DateTime? usedAt,
    String? usedClinicId,
    String? usedClinicName,
  }) {
    return ReferralDiscountCode(
      code: code,
      discountPercent: discountPercent,
      status: status ?? this.status,
      userId: userId,
      userName: userName,
      createdAt: createdAt,
      expiresAt: expiresAt,
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
