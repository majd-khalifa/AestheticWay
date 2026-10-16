import 'dart:math';
import 'package:flutter/material.dart';
import '../data/referral_repository.dart';
import '../models/referral_model.dart';

/// Referral & Rewards Service managing invites, milestone calculations, and 15% discount codes
class ReferralService extends ChangeNotifier {
  static final ReferralService _instance = ReferralService._internal();
  factory ReferralService() => _instance;
  ReferralService._internal();

  ReferralRepository _repository = ReferralRepository();
  bool _mockMode = false;
  bool _hasLoadedFromApi = false;

  PatientReferralStatusModel? _statusModel;
  bool _isLoading = false;
  String? _errorMessage;

  // Fallback demo data for offline state & test safety
  String _fallbackReferralCode = 'AW-DUBAI-88';
  int _fallbackSuccessfulInvites = 0;
  int _fallbackBonusPoints = 0;
  int _fallbackConsumedPoints = 0;
  final List<ReferralDiscountCode> _issuedCodes = [];

  PatientReferralStatusModel? get statusModel => _statusModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @visibleForTesting
  void enableMockMode({
    PatientReferralStatusModel? testStatus,
    int? testInvites,
    int? testPoints,
  }) {
    _mockMode = true;
    if (_issuedCodes.isEmpty) {
      _initFallbackData();
    }
    if (testStatus != null) {
      _statusModel = testStatus;
    }
    if (testInvites != null) {
      _fallbackSuccessfulInvites = testInvites;
    }
    if (testPoints != null) {
      _fallbackBonusPoints = testPoints;
    }
    notifyListeners();
  }

  @visibleForTesting
  void setRepositoryForTesting(ReferralRepository repository) {
    _repository = repository;
  }

  @visibleForTesting
  void resetTestingState() {
    _mockMode = false;
    _hasLoadedFromApi = false;
    _isLoading = false;
    _errorMessage = null;
    _statusModel = null;
    _fallbackBonusPoints = 0;
    _fallbackConsumedPoints = 0;
    _issuedCodes.clear();
  }

  String get userReferralCode => _statusModel?.referralCode.isNotEmpty == true
      ? _statusModel!.referralCode
      : _fallbackReferralCode;

  String get inviteLink {
    if (_statusModel?.inviteLink.isNotEmpty == true) {
      return _statusModel!.inviteLink;
    }
    return 'https://aestheticway.ae/invite/$userReferralCode';
  }

  int get successfulInvites => _statusModel?.successfulInvitesCount ?? _fallbackSuccessfulInvites;

  int get currentPoints {
    if (_statusModel != null) {
      return _statusModel!.currentPoints;
    }
    int pts = 0;
    if (_fallbackSuccessfulInvites >= 20) pts += 100;
    if (_fallbackSuccessfulInvites >= 35) pts += 175;
    if (_fallbackSuccessfulInvites >= 50) pts += 250;
    return max(0, pts + _fallbackBonusPoints - _fallbackConsumedPoints);
  }

  /// Next uncompleted milestone threshold from [20, 35, 50]
  int get nextMilestoneThreshold {
    final count = successfulInvites;
    if (count < 20) return 20;
    if (count < 35) return 35;
    return 50;
  }

  /// Whether the user has completed all milestone tiers (>= 50)
  bool get hasCompletedAllMilestones => successfulInvites >= 50;

  /// Remaining invites needed to reach the next milestone
  int get remainingInvitesForNextMilestone {
    final count = successfulInvites;
    if (count < 20) return 20 - count;
    if (count < 35) return 35 - count;
    if (count < 50) return 50 - count;
    return 0;
  }

  /// Progress ratio towards next milestone: count / nextMilestone (e.g. at 3 invites: 3 / 20 = 0.15)
  double get nextMilestoneProgressRatio {
    final count = successfulInvites;
    if (count >= 50) return 1.0;
    final target = nextMilestoneThreshold;
    if (target <= 0) return 0.0;
    return (count / target).clamp(0.0, 1.0);
  }

  /// Dynamic explanatory text for invites progress (Arabic & English)
  String getMilestoneDynamicMessage({required bool isArabic}) {
    final count = successfulInvites;
    if (count < 20) {
      final remaining = 20 - count;
      return isArabic
          ? '$count استخدموا كودك · باقي $remaining دعوة للحصول على 100 نقطة'
          : '$count used your code · $remaining more invites to earn 100 pts';
    } else if (count < 35) {
      final remaining = 35 - count;
      return isArabic
          ? '$count دعوة ناجحة · باقي $remaining دعوة للحصول على +175 نقطة'
          : '$count successful invites · $remaining more invites to earn +175 pts';
    } else if (count < 50) {
      final remaining = 50 - count;
      return isArabic
          ? '$count دعوة ناجحة · باقي $remaining دعوة للحصول على +250 نقطة'
          : '$count successful invites · $remaining more invites to earn +250 pts';
    } else {
      return isArabic
          ? 'أكملت كل العتبات · يمكنك استبدال النقاط عند توفر 500+'
          : 'All invite milestones completed · Redeem when you reach 500+ pts';
    }
  }

  bool get canCollectDiscountCode => _statusModel?.canCollectCode ?? (currentPoints >= 500);

  List<ReferralDiscountCode> get userCodes {
    if (_statusModel != null && _statusModel!.discountCodes.isNotEmpty) {
      return _statusModel!.discountCodes;
    }
    return _issuedCodes.where((c) => c.userId == 'current_user').toList();
  }

  List<ReferralDiscountCode> get allPlatformCodes => List.unmodifiable(_issuedCodes);

  bool isMilestoneAwarded(int requiredInvites) {
    if (_statusModel != null) {
      return _statusModel!.milestones[requiredInvites.toString()] == true ||
          successfulInvites >= requiredInvites;
    }
    return successfulInvites >= requiredInvites;
  }

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

  void _initFallbackData() {
    _fallbackReferralCode = 'AW-DUBAI-88';
    _fallbackSuccessfulInvites = 0;
    _fallbackBonusPoints = 0;
    _fallbackConsumedPoints = 0;
    _issuedCodes.clear();
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

  /// Fetch live referral status from backend API
  Future<void> loadReferralStatus({bool refresh = false}) async {
    if (_mockMode) return;
    if (!refresh && _hasLoadedFromApi && _statusModel != null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final status = await _repository.getMyReferralStatus();
      _statusModel = status;
      _hasLoadedFromApi = true;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Collect / Redeem 500 points for a 15% Discount Code
  Future<ReferralDiscountCode> collectDiscountCode({String userName = 'سارة المنصوري'}) async {
    if (_mockMode) {
      final randomSuffix = (1000 + Random().nextInt(9000)).toString();
      final newCode = 'AW-15-$randomSuffix';
      _fallbackConsumedPoints += 500;

      final discountCode = ReferralDiscountCode(
        code: newCode,
        discountPercent: 15.0,
        status: ReferralCodeStatus.available,
        userId: 'current_user',
        userName: userName,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 90)),
      );

      _issuedCodes.insert(0, discountCode);
      notifyListeners();
      return discountCode;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.collectDiscountCode();

      // Refetch live status to sync ledger & codes accurately
      try {
        final refreshedStatus = await _repository.getMyReferralStatus();
        _statusModel = refreshedStatus;
      } catch (_) {
        if (_statusModel != null) {
          final newCodeObj = ReferralDiscountCode(
            code: result.code,
            status: ReferralCodeStatus.available,
            createdAt: DateTime.now(),
            expiresAt: result.expiresAt ?? DateTime.now().add(const Duration(days: 90)),
          );
          _statusModel = PatientReferralStatusModel(
            referralCode: _statusModel!.referralCode,
            successfulInvitesCount: _statusModel!.successfulInvitesCount,
            totalSuccessfulInvites: _statusModel!.totalSuccessfulInvites,
            currentPoints: result.remainingPoints,
            pointsToCollect: _statusModel!.pointsToCollect,
            canCollectCode: result.remainingPoints >= 500,
            pointsExpire: _statusModel!.pointsExpire,
            milestones: _statusModel!.milestones,
            discountCodes: [newCodeObj, ..._statusModel!.discountCodes],
          );
        }
      }

      final collectedCodeObj = ReferralDiscountCode(
        code: result.code,
        status: ReferralCodeStatus.available,
        createdAt: DateTime.now(),
        expiresAt: result.expiresAt ?? DateTime.now().add(const Duration(days: 90)),
      );

      _issuedCodes.insert(0, collectedCodeObj);
      _errorMessage = null;
      notifyListeners();
      return collectedCodeObj;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verify discount code entered in Clinic Portal (sync fallback for mock mode)
  ReferralDiscountCode? verifyCode(String rawCode) {
    final clean = rawCode.trim().toUpperCase();
    try {
      return _issuedCodes.firstWhere((c) => c.code.toUpperCase() == clean);
    } catch (_) {
      try {
        return _statusModel?.discountCodes.firstWhere((c) => c.code.toUpperCase() == clean);
      } catch (_) {
        return null;
      }
    }
  }

  /// Verify discount code via Live Clinic Portal API (or mock mode in tests)
  Future<ReferralDiscountCode?> verifyClinicCodeLive(String rawCode) async {
    final clean = rawCode.trim().toUpperCase();
    if (_mockMode) {
      return verifyCode(clean);
    }

    try {
      final res = await _repository.verifyClinicDiscountCode(clean);
      final isValid = res['is_valid'] == true;
      final statusStr = res['status']?.toString().toLowerCase() ?? '';
      final codeStr = res['code']?.toString() ?? clean;
      if (!isValid && statusStr.isEmpty) {
        return null;
      }

      final status = (isValid || statusStr == 'available')
          ? ReferralCodeStatus.available
          : (statusStr == 'expired' ? ReferralCodeStatus.expired : ReferralCodeStatus.used);

      final verifiedCode = ReferralDiscountCode(
        code: codeStr,
        discountPercent: 15.0,
        status: status,
        userId: res['user_id']?.toString() ?? 'patient',
        userName: res['patient_name']?.toString() ?? res['user_name']?.toString() ?? 'مريض معتمد',
        createdAt: DateTime.tryParse(res['created_at']?.toString() ?? '') ?? DateTime.now(),
        expiresAt: DateTime.tryParse(res['expires_at']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 60)),
        usedClinicName: res['redeemed_clinic']?.toString(),
      );

      final existingIdx = _issuedCodes.indexWhere((c) => c.code.toUpperCase() == clean);
      if (existingIdx != -1) {
        _issuedCodes[existingIdx] = verifiedCode;
      } else {
        _issuedCodes.insert(0, verifiedCode);
      }
      notifyListeners();
      return verifiedCode;
    } catch (_) {
      return verifyCode(clean);
    }
  }

  /// Mark discount code as used by a specific clinic (sync fallback for mock mode)
  bool redeemCode({
    required String code,
    required String clinicId,
    required String clinicName,
  }) {
    final clean = code.trim().toUpperCase();
    final index = _issuedCodes.indexWhere((c) => c.code.toUpperCase() == clean);
    if (index != -1) {
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
    return false;
  }

  /// Redeem discount code via Live Clinic Portal API (or mock mode in tests)
  Future<bool> redeemClinicCodeLive({
    required String code,
    required String clinicId,
    required String clinicName,
  }) async {
    final clean = code.trim().toUpperCase();
    if (_mockMode) {
      return redeemCode(code: clean, clinicId: clinicId, clinicName: clinicName);
    }

    try {
      final res = await _repository.redeemClinicDiscountCode(clean);
      final success = res['success'] == true;
      if (success) {
        final redeemedClinic = res['redeemed_clinic']?.toString() ?? clinicName;
        final index = _issuedCodes.indexWhere((c) => c.code.toUpperCase() == clean);
        if (index != -1) {
          _issuedCodes[index] = _issuedCodes[index].copyWith(
            status: ReferralCodeStatus.used,
            usedAt: DateTime.now(),
            usedClinicId: clinicId,
            usedClinicName: redeemedClinic,
          );
        } else {
          _issuedCodes.insert(
            0,
            ReferralDiscountCode(
              code: clean,
              discountPercent: 15.0,
              status: ReferralCodeStatus.used,
              userId: 'patient',
              userName: 'مريض معتمد',
              createdAt: DateTime.now(),
              expiresAt: DateTime.now().add(const Duration(days: 60)),
              usedAt: DateTime.now(),
              usedClinicId: clinicId,
              usedClinicName: redeemedClinic,
            ),
          );
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Register an invite (e.g. from registration screen)
  void registerInvite({String? referralCode}) {
    _fallbackSuccessfulInvites += 1;
    notifyListeners();
  }

  /// Add demo invites for presentation testing
  void addDemoInvites(int count) {
    _fallbackSuccessfulInvites += count;
    notifyListeners();
  }

  /// Fast-track points for live demonstration
  void addDemoPoints(int points) {
    _fallbackBonusPoints += points;
    notifyListeners();
  }
}
