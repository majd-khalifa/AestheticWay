import '../../../core/data/single_flight.dart';
import '../../../core/auth/session_changed_exception.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/referral_repository.dart';
import '../models/referral_model.dart';

/// Account-scoped invitation status. No reward redemption is performed by Flutter.
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
  String _fallbackReferralCode = '';
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

  int _sessionEpoch = 0;

  /// Discard all account-scoped state and invalidate outstanding requests.
  void clearSession({bool notify = true}) {
    _statusFlights.clear();
    _sessionEpoch++;
    _mockMode = false;
    _hasLoadedFromApi = false;
    _isLoading = false;
    _errorMessage = null;
    _statusModel = null;
    _fallbackBonusPoints = 0;
    _fallbackConsumedPoints = 0;
    _issuedCodes.clear();
    _fallbackReferralCode = '';
    _fallbackSuccessfulInvites = 0;
    if (notify) notifyListeners();
  }

  @visibleForTesting
  void resetTestingState() => clearSession(notify: false);

  Future<T> _inSession<T>(Future<T> future, int epoch) async {
    try {
      final result = await future;
      if (epoch != _sessionEpoch) throw const SessionChangedException();
      return result;
    } catch (_) {
      if (epoch != _sessionEpoch) throw const SessionChangedException();
      rethrow;
    }
  }

  String get userReferralCode => _statusModel?.referralCode.isNotEmpty == true
      ? _statusModel!.referralCode
      : _fallbackReferralCode;

  String get inviteLink {
    if (_statusModel?.inviteLink.isNotEmpty == true) {
      return _statusModel!.inviteLink;
    }
    return '';
  }

  int get successfulInvites =>
      _statusModel?.successfulInvitesCount ?? _fallbackSuccessfulInvites;

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
          ? '$count دعوة ناجحة · باقي $remaining دعوة للحصول على 100 نقطة'
          : '$count successful invites · $remaining more invites to earn 100 pts';
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
          ? 'أكملت جميع مراحل الدعوات'
          : 'All invitation milestones completed';
    }
  }

  // Disabled compatibility entry points: never expose or invoke retired operations.
  bool get canCollectDiscountCode => false;
  List<ReferralDiscountCode> get userCodes => const [];
  List<ReferralDiscountCode> get allPlatformCodes => const [];

  bool isMilestoneAwarded(int requiredInvites) {
    if (_statusModel != null) {
      return _statusModel!.milestones[requiredInvites.toString()] == true;
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
      titleAr: '50 دعوة → +250 نقطة',
      titleEn: '50 Invites → +250 pts',
      icon: Icons.card_giftcard_outlined,
    ),
  ];

  /// Fetch live referral status from backend API
  final _statusFlights = SingleFlight();
  Future<void> loadReferralStatus({bool refresh = false}) =>
      _statusFlights.run('status', () => _loadReferralStatus(refresh: refresh));
  Future<void> _loadReferralStatus({bool refresh = false}) async {
    final sessionEpoch = _sessionEpoch;
    if (_mockMode) return;
    if (!refresh && _hasLoadedFromApi && _statusModel != null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final status = await _inSession(
        _repository.getMyReferralStatus(),
        sessionEpoch,
      );
      _statusModel = status;
      _hasLoadedFromApi = true;
      _errorMessage = null;
    } catch (e) {
      if (sessionEpoch != _sessionEpoch) {
        return;
      }
      _errorMessage = e.toString();
    } finally {
      if (sessionEpoch == _sessionEpoch) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<ReferralDiscountCode> collectDiscountCode({String userName = ''}) =>
      Future.error(UnsupportedError('Referral redemption has been retired'));
  ReferralDiscountCode? verifyCode(String rawCode) => null;
  Future<ReferralDiscountCode?> verifyClinicCodeLive(String rawCode) async =>
      null;
  bool redeemCode({
    required String code,
    required String clinicId,
    required String clinicName,
  }) => false;
  Future<bool> redeemClinicCodeLive({
    required String code,
    required String clinicId,
    required String clinicName,
  }) async => false;

  @visibleForTesting
  void addDemoInvites(int count) {
    if (!_mockMode) return;
    _fallbackSuccessfulInvites += max(0, count);
    notifyListeners();
  }

  @visibleForTesting
  void addDemoPoints(int points) {
    if (!_mockMode) return;
    _fallbackBonusPoints += max(0, points);
    notifyListeners();
  }
}
