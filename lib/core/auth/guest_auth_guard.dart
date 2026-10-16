import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import 'token_storage.dart';

/// User Authentication State Handler
class AuthState extends ChangeNotifier {
  static final AuthState _instance = AuthState._internal();
  factory AuthState() => _instance;
  AuthState._internal();

  bool _isLoggedIn = false;
  String _userName = '';
  String _userPhone = '';
  String _userEmail = '';
  String _userRole = 'patient';
  bool _isVerified = false;
  final Set<String> _favoriteClinicIds = {};

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userPhone => _userPhone;
  String get userEmail => _userEmail;
  String get userRole => _userRole;
  bool get isVerified => _isVerified;
  Set<String> get favoriteClinicIds => _favoriteClinicIds;

  bool get isSuperAdmin => _userRole == 'super_admin';
  bool get isClinicAdmin => _userRole == 'clinic_admin';
  bool get isClinicStaff => _userRole == 'clinic_staff';
  bool get isPatient => _userRole == 'patient' || _userRole.isEmpty;

  void login({
    required String name,
    required String phone,
    String email = '',
    String role = 'patient',
    bool isVerified = false,
  }) {
    _isLoggedIn = true;
    _userName = name;
    _userPhone = phone;
    _userEmail = email;
    _userRole = role;
    _isVerified = isVerified;
    notifyListeners();
  }

  void updateProfile({
    required String name,
    required String phone,
    String email = '',
    bool? isVerified,
  }) {
    _userName = name;
    _userPhone = phone;
    _userEmail = email;
    if (isVerified != null) {
      _isVerified = isVerified;
    }
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _userName = '';
    _userPhone = '';
    _userEmail = '';
    _userRole = 'patient';
    _isVerified = false;
    TokenStorage().clear();
    notifyListeners();
  }

  /// Restore user session from persistent TokenStorage
  Future<void> restoreSession() async {
    await TokenStorage().init();
    final hasToken = await TokenStorage().hasToken();
    final user = TokenStorage().getUser();
    if (hasToken && user != null) {
      _isLoggedIn = true;
      _userName = user['full_name']?.toString() ?? '';
      _userPhone = user['phone']?.toString() ?? '';
      _userEmail = user['email']?.toString() ?? '';
      _userRole = user['role']?.toString() ?? 'patient';
      _isVerified = user['is_verified'] == true;
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
      return true;
    }

    // In mandatory auth mode, if session is ever lost, redirect cleanly to LoginScreen and clear stack
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
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

