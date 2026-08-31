import 'dart:math';
import 'package:flutter/material.dart';
import '../models/referral_model.dart';

/// Referral & Rewards Service managing invites, milestone calculations, and 15% discount codes
class ReferralService extends ChangeNotifier {
  static final ReferralService _instance = ReferralService._internal();
  factory ReferralService() => _instance;
  ReferralService._internal() {
    _initDemoData();
  }

  final String _userReferralCode = 'AW-DUBAI-88';
  int _successfulInvites = 36; // Start with 36 invites (cumulative: 100 + 175 = 275 points)
  int _bonusPoints = 0;
  int _consumedPoints = 0;

  final List<ReferralDiscountCode> _issuedCodes = [];

  String get userReferralCode => _userReferralCode;
  int get successfulInvites => _successfulInvites;

  /// Cumulative points calculated upon passing thresholds:
  /// - At 20 invites: +100 pts
  /// - At 35 invites: +175 pts (total: 275)
  /// - At 50 invites: +250 pts (total: 525 >= 500)
  int get currentPoints {
    int pts = 0;
    if (_successfulInvites >= 20) pts += 100;
    if (_successfulInvites >= 35) pts += 175;
    if (_successfulInvites >= 50) pts += 250;
    return max(0, pts + _bonusPoints - _consumedPoints);
  }

  /// Whether the user has accumulated at least 500 points to collect a 15% discount code
  bool get canCollectDiscountCode => currentPoints >= 500;

  /// List of discount codes collected by the current user
  List<ReferralDiscountCode> get userCodes =>
      _issuedCodes.where((c) => c.userId == 'current_user').toList();

  /// All platform issued discount codes (for Admin & Clinic verification)
  List<ReferralDiscountCode> get allPlatformCodes => List.unmodifiable(_issuedCodes);

  /// Official Client-Approved Referral Milestones (Cumulative: 100 + 175 + 250 = 525 pts >= 500)
  static const List<ReferralMilestone> milestones = [
    ReferralMilestone(
      requiredInvites: 20,
      pointsAwarded: 100,
      titleAr: '20 دعوة → +100 نقطة',
      titleEn: '20 Invites → +100 pts',
      icon: Icons.person_add_alt_outlined,
    ),
    ReferralMilestone(
      requiredInvites: 35,
      pointsAwarded: 175,
      titleAr: '35 دعوة → +175 نقطة',
      titleEn: '35 Invites → +175 pts',
      icon: Icons.group_add_outlined,
    ),
    ReferralMilestone(
      requiredInvites: 50,
      pointsAwarded: 250,
      titleAr: '50 دعوة → +250 نقطة (إجمالي 525 نقطة — تفعيل كود 15%)',
      titleEn: '50 Invites → +250 pts (Total 525 pts — Unlocks 15% Code)',
      icon: Icons.card_giftcard_outlined,
    ),
  ];

  void _initDemoData() {
    // Seed initial demo issued codes for testing
    _issuedCodes.addAll([
      ReferralDiscountCode(
        code: 'AW-15-4819',
        discountPercent: 15.0,
        status: ReferralCodeStatus.available,
        userId: 'current_user',
        userName: 'سارة المنصوري',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        expiresAt: DateTime.now().add(const Duration(days: 57)),
      ),
      ReferralDiscountCode(
        code: 'AW-15-2094',
        discountPercent: 15.0,
        status: ReferralCodeStatus.used,
        userId: 'user_ahmed',
        userName: 'أحمد الظاهري',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        expiresAt: DateTime.now().add(const Duration(days: 48)),
        usedAt: DateTime.now().subtract(const Duration(days: 2)),
        usedClinicId: 'elegance-downtown',
        usedClinicName: 'مركز الأناقة الطبي للجلدية والتجميل',
      ),
      ReferralDiscountCode(
        code: 'AW-15-7731',
        discountPercent: 15.0,
        status: ReferralCodeStatus.available,
        userId: 'user_reem',
        userName: 'ريم الكعبي',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        expiresAt: DateTime.now().add(const Duration(days: 55)),
      ),
    ]);
  }

  /// Register an invite (e.g. from registration screen)
  void registerInvite({String? referralCode}) {
    _successfulInvites += 1;
    notifyListeners();
  }

  /// Add demo invites for presentation testing
  void addDemoInvites(int count) {
    _successfulInvites += count;
    notifyListeners();
  }

  /// Fast-track points for live demonstration
  void addDemoPoints(int points) {
    _bonusPoints += points;
    notifyListeners();
  }

  /// Collect / Redeem 500 points for a 15% Discount Code
  ReferralDiscountCode collectDiscountCode({String userName = 'سارة المنصوري'}) {
    final randomSuffix = (1000 + Random().nextInt(9000)).toString();
    final newCode = 'AW-15-$randomSuffix';

    // Consume 500 points
    _consumedPoints += 500;

    final discountCode = ReferralDiscountCode(
      code: newCode,
      discountPercent: 15.0,
      status: ReferralCodeStatus.available,
      userId: 'current_user',
      userName: userName,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
    );

    _issuedCodes.insert(0, discountCode);
    notifyListeners();
    return discountCode;
  }

  /// Verify discount code entered in Clinic Portal
  ReferralDiscountCode? verifyCode(String rawCode) {
    final clean = rawCode.trim().toUpperCase();
    try {
      return _issuedCodes.firstWhere((c) => c.code.toUpperCase() == clean);
    } catch (_) {
      return null;
    }
  }

  /// Mark discount code as used by a specific clinic
  bool redeemCode({
    required String code,
    required String clinicId,
    required String clinicName,
  }) {
    final clean = code.trim().toUpperCase();
    final index = _issuedCodes.indexWhere((c) => c.code.toUpperCase() == clean);
    if (index == -1) return false;

    final existing = _issuedCodes[index];
    if (existing.status != ReferralCodeStatus.available) return false;

    _issuedCodes[index] = existing.copyWith(
      status: ReferralCodeStatus.used,
      usedAt: DateTime.now(),
      usedClinicId: clinicId,
      usedClinicName: clinicName,
    );

    notifyListeners();
    return true;
  }
}
