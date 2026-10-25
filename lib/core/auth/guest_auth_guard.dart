import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import 'token_storage.dart';
import '../../features/onboarding/services/onboarding_service.dart';
import '../../features/clinic_portal/services/clinic_portal_service.dart';
import '../../features/admin/services/admin_portal_service.dart';
import '../../features/referral/services/referral_service.dart';

/// User Authentication State Handler
class AuthState extends ChangeNotifier {
  static final AuthState _instance = AuthState._internal();
  factory AuthState() => _instance;
  AuthState._internal();

  int _sessionEpoch = 0;
  int get sessionEpoch => _sessionEpoch;
  bool _isLoggedIn = false;
  bool _hasAuthenticatedSession = false;
  bool get hasAuthenticatedSession => _hasAuthenticatedSession;
  String _userName = '';
  String _userPhone = '';
  String _userEmail = '';
  String _userRole = 'patient';
  bool _isVerified = false;
  bool _isEmailVerified = false;
  final Set<String> _favoriteClinicIds = {};

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userPhone => _userPhone;
  String get userEmail => _userEmail;
  String get userRole => _userRole;
  bool get isVerified => _isVerified;
  bool get isEmailVerified => _isEmailVerified;
  Set<String> get favoriteClinicIds => _favoriteClinicIds;

  bool get isSuperAdmin => _userRole == 'super_admin';
  bool get isClinicAdmin => _userRole == 'clinic_admin';
  bool get isClinicStaff => _userRole == 'clinic_staff';
  bool get isPatient => _userRole == 'patient';

  void login({
    required String name,
    required String phone,
    String email = '',
    String role = 'patient',
    bool isVerified = false,
    bool isEmailVerified = false,
  }) {
    final changed = !_isLoggedIn || _userPhone != phone || _userRole != role;
    if (_isLoggedIn && changed) {
      ClinicPortalService().clearSession();
      AdminPortalService().clearSession();
      ReferralService().clearSession();
      _favoriteClinicIds.clear();
    }
    if (changed) ++_sessionEpoch;
    _hasAuthenticatedSession = true;
    _isLoggedIn = true;
    _userName = name;
    _userPhone = phone;
    _userEmail = email;
    _userRole = role;
    _isVerified = isVerified;
    _isEmailVerified = isEmailVerified;
    notifyListeners();
  }

  void updateProfile({
    required String name,
    required String phone,
    String email = '',
    bool? isVerified,
    bool? isEmailVerified,
  }) {
    final sameEmail =
        email.trim().toLowerCase() == _userEmail.trim().toLowerCase();
    _userName = name;
    _userPhone = phone;
    _userEmail = email;
    if (isVerified != null) {
      _isVerified = isVerified;
    }
    _isEmailVerified = isEmailVerified ?? (sameEmail && _isEmailVerified);
    notifyListeners();
  }

  void logout() {
    if (TokenStorage().currentAccessToken != null ||
        TokenStorage().currentRefreshToken != null ||
        TokenStorage().getUser() != null) {
      unawaited(TokenStorage().clear());
    }
    // Also cover forced logout after token refresh fails.
    ClinicPortalService().clearSession();
    AdminPortalService().clearSession();
    ReferralService().clearSession();
    ++_sessionEpoch;
    _isLoggedIn = false;
    _userName = '';
    _userPhone = '';
    _userEmail = '';
    _userRole = 'patient';
    _isVerified = false;
    _isEmailVerified = false;
    _favoriteClinicIds.clear();
    notifyListeners();
  }

  /// Restore user session from persistent TokenStorage
  Future<void> restoreSession({OnboardingService? onboardingService}) async {
    final identity = _sessionEpoch;
    await TokenStorage().init();
    final credentials = TokenStorage().sessionEpoch;
    final hasToken = await TokenStorage().hasToken();
    final user = TokenStorage().getUser();
    if (hasToken && user != null) {
      await (onboardingService ?? OnboardingService())
          .recordAuthenticatedSession();
      // Preference I/O must never resurrect an identity after logout or a
      // replacement login while startup restoration was waiting.
      if (identity != _sessionEpoch ||
          credentials != TokenStorage().sessionEpoch) {
        return;
      }
      ++_sessionEpoch;
      _hasAuthenticatedSession = true;
      _isLoggedIn = true;
      _userName = user['full_name']?.toString() ?? '';
      _userPhone = user['phone']?.toString() ?? '';
      _userEmail = user['email']?.toString() ?? '';
      _userRole = user['role']?.toString() ?? '';
      _isVerified = user['is_verified'] == true;
      _isEmailVerified = user['is_email_verified'] == true;
      notifyListeners();
    }
  }

  bool isFavorite(String clinicId) => _favoriteClinicIds.contains(clinicId);

  void toggleFavorite(String clinicId) {
    if (_favoriteClinicIds.contains(clinicId)) {
      _favoriteClinicIds.remove(clinicId);
    } else {
      _favoriteClinicIds.add(clinicId);
    }
    notifyListeners();
  }
}

/// Guard to ensure authentication and prevent unauthenticated access.
/// Guest Mode is completely deprecated: authentication is strictly mandatory.
class GuestAuthGuard {
  static Future<bool> requireAuth(
    BuildContext context, {
    String? reasonTitle,
    String? reasonSubtitle,
  }) async {
    if (AuthState().isLoggedIn) {
      return AuthState().isPatient;
    }

    // In mandatory auth mode, if session is ever lost, redirect cleanly to LoginScreen and clear stack
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      (route) => false,
    );
    return false;
  }
}
