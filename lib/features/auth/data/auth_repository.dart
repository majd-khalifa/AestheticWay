import 'package:dio/dio.dart';
import '../../../core/auth/session_changed_exception.dart';
import '../../../core/network/api_transport_policy.dart';
import '../../../core/network/api_exception.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/auth/guest_auth_guard.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/services/device_token_service.dart';
import 'models/auth_models.dart';

/// Repository for all Authentication & Identity operations
class AuthRepository {
  static final AuthRepository _instance = AuthRepository._internal();

  factory AuthRepository({ApiClient? apiClient, TokenStorage? tokenStorage}) {
    if (apiClient != null || tokenStorage != null) {
      return AuthRepository._custom(
        apiClient ?? ApiClient(),
        tokenStorage ?? TokenStorage(),
      );
    }
    return _instance;
  }

  AuthRepository._internal()
    : _api = ApiClient(),
      _tokenStorage = TokenStorage();

  AuthRepository._custom(this._api, this._tokenStorage);

  final ApiClient _api;
  final TokenStorage _tokenStorage;
  static int _authenticationAttempt = 0;
  (int, int) _snapshot() =>
      (_tokenStorage.sessionEpoch, AuthState().sessionEpoch);
  void _check((int, int) stamp) {
    if (stamp != _snapshot()) throw const SessionChangedException();
  }

  void _validateUser(UserModel user) {
    if (user.id.isEmpty ||
        ![
          'patient',
          'clinic_admin',
          'clinic_staff',
          'super_admin',
        ].contains(user.role)) {
      throw const ApiException(
        message: 'Unable to verify account identity. Please sign in again.',
      );
    }
  }

  Future<void> _storeUser(UserModel user, (int, int) stamp) async {
    _check(stamp);
    _validateUser(user);
    final saving = _tokenStorage.saveUser(user.toJson());
    final next = _snapshot();
    await saving;
    _check(next);
  }

  Future<void> _acceptAuthentication(
    AuthResponse response,
    (int, int) stamp,
    int attempt,
  ) async {
    _check(stamp);
    _validateUser(response.user);
    if (attempt != _authenticationAttempt ||
        response.accessToken.isEmpty ||
        response.refreshToken.isEmpty) {
      throw const SessionChangedException();
    }
    final clearing = _tokenStorage.clear();
    AuthState().logout();
    var current = _snapshot();
    await clearing;
    _check(current);
    if (attempt != _authenticationAttempt) {
      throw const SessionChangedException();
    }
    await _tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    _check(current);
    if (attempt != _authenticationAttempt) {
      throw const SessionChangedException();
    }
    final saving = _tokenStorage.saveUser(response.user.toJson());
    current = _snapshot();
    await saving;
    _check(current);
    if (attempt != _authenticationAttempt) {
      throw const SessionChangedException();
    }
    AuthState().login(
      name: response.user.fullName,
      phone: response.user.phone,
      email: response.user.email ?? '',
      role: response.user.role,
      isVerified: response.user.isVerified,
    );
  }

  /// Preserve international E.164 numbers; assume UAE only for local input.
  static String normalizePhone(String phone) {
    final value = phone.trim();
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.startsWith('+')) return '+$digits';
    if (digits.startsWith('00')) return '+${digits.substring(2)}';
    if (digits.startsWith('971')) return '+$digits';
    return '+971${digits.replaceFirst(RegExp(r'^0+'), '')}';
  }

  /// Register a new patient account
  Future<RegisterResponse> register({
    required String fullName,
    required String phone,
    required String password,
    String? email,
    String? referralCode,
  }) async {
    final normalized = normalizePhone(phone);
    final String platform = kIsWeb
        ? 'web'
        : (Platform.isAndroid ? 'android' : 'ios');

    final data = <String, dynamic>{
      'full_name': fullName.trim(),
      'phone': normalized,
      'password': password,
      'device_platform': platform,
    };

    if (email != null && email.trim().isNotEmpty) {
      data['email'] = email.trim();
    }

    // Only include referral_code if provided, non-empty, and not a placeholder like 'string'
    final cleanRef = referralCode?.trim();
    if (cleanRef != null &&
        cleanRef.isNotEmpty &&
        cleanRef.toLowerCase() != 'string' &&
        cleanRef.toLowerCase() != 'null') {
      data['referral_code'] = cleanRef;
    }

    final response = await _api.post(ApiConfig.register, data: data);
    return RegisterResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Verify 6-digit OTP code
  Future<AuthResponse?> verifyOtp({
    required String phone,
    required String otpCode,
    required String purpose, // 'registration' | 'login' | 'password_reset'
  }) async {
    final normalized = normalizePhone(phone);
    final stamp = _snapshot();
    final attempt = ++_authenticationAttempt;
    final response = await _api.post(
      ApiConfig.verifyOtp,
      data: {
        'phone': normalized,
        'otp_code': otpCode.trim(),
        'purpose': purpose,
      },
    );

    final data = response.data as Map<String, dynamic>;

    if (purpose == 'registration' || purpose == 'login') {
      final authResponse = AuthResponse.fromJson(data);
      await _acceptAuthentication(authResponse, stamp, attempt);

      return authResponse;
    }

    return null;
  }

  /// Login with phone or email identifier and password
  Future<AuthResponse> login({
    required String identifier,
    required String password,
  }) async {
    final stamp = _snapshot();
    final attempt = ++_authenticationAttempt;
    final trimmed = identifier.trim();
    final normalizedIdentifier = trimmed.contains('@')
        ? trimmed
        : normalizePhone(trimmed);

    final response = await _api.post(
      ApiConfig.login,
      data: {'identifier': normalizedIdentifier, 'password': password},
    );

    final authResponse = AuthResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
    await _acceptAuthentication(authResponse, stamp, attempt);

    return authResponse;
  }

  /// Resend OTP
  Future<Map<String, dynamic>> resendOtp({
    required String phone,
    required String purpose,
  }) async {
    final normalized = normalizePhone(phone);
    final response = await _api.post(
      ApiConfig.resendOtp,
      data: {'phone': normalized, 'purpose': purpose},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Request password reset OTP
  Future<Map<String, dynamic>> forgotPassword({required String phone}) async {
    final normalized = normalizePhone(phone);
    final response = await _api.post(
      ApiConfig.forgotPassword,
      data: {'phone': normalized},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Reset password after OTP verification
  Future<Map<String, dynamic>> resetPassword({
    required String phone,
    String? otpCode,
    required String newPassword,
  }) async {
    final normalized = normalizePhone(phone);
    final data = <String, dynamic>{
      'phone': normalized,
      'new_password': newPassword,
    };
    if (otpCode != null && otpCode.trim().isNotEmpty) {
      data['otp_code'] = otpCode.trim();
    }
    final response = await _api.post(ApiConfig.resetPassword, data: data);
    return response.data as Map<String, dynamic>;
  }

  /// Logout, deactivate push token, and revoke refresh token on backend
  Future<void> logout() async {
    ++_authenticationAttempt;
    final access = _tokenStorage.currentAccessToken;
    final refresh = _tokenStorage.currentRefreshToken;
    final base = ApiConfig.baseUrl;
    final device = DeviceTokenService().getSavedToken();
    final deviceClearing = DeviceTokenService().clearLocalToken();
    // Invalidate locally before any network wait. A new login must not be erased
    // when an old logout/revocation eventually finishes.
    final clearing = _tokenStorage.clear();
    AuthState().logout();
    final deviceToken = await device;
    await deviceClearing;
    await clearing;
    if (access == null || refresh == null) return;
    final dio = Dio(
      BaseOptions(
        baseUrl: base,
        followRedirects: false,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          'Authorization': 'Bearer $access',
          'Accept': 'application/json',
        },
      ),
    );
    try {
      if (!ApiTransportPolicy.permits(
        Uri.parse(base).resolve(ApiConfig.logout),
        base,
      )) {
        return;
      }
      // Dedicated captured credentials; never attach a newer account's token or
      // run the shared refresh flow for this already-invalidated session.
      if (deviceToken?.isNotEmpty == true) {
        try {
          await dio.delete(
            ApiConfig.notificationDeviceDeactivate(deviceToken!),
          );
        } catch (_) {}
      }
      await dio.post(ApiConfig.logout, data: {'refresh_token': refresh});
    } catch (_) {
      // Local logout still succeeds offline; server expiry/revocation is required.
    } finally {
      dio.close(force: true);
    }
  }

  /// Get current user profile from server (GET /api/v1/auth/me/)
  Future<UserModel> getMe() async {
    final stamp = _snapshot();
    final response = await _api.get(ApiConfig.me);
    final user = UserModel.fromJson(response.data as Map<String, dynamic>);
    await _storeUser(user, stamp);
    AuthState().login(
      name: user.fullName,
      phone: user.phone,
      email: user.email ?? '',
      role: user.role,
      isVerified: user.isVerified,
    );
    return user;
  }

  /// Update current user profile on server (PATCH /api/v1/auth/me/)
  /// Accepted fields by backend UserProfileSerializer: full_name, phone, email
  Future<UserModel> updateMe({
    required String fullName,
    String? email,
    String? phone,
  }) async {
    final stamp = _snapshot();
    final payload = <String, dynamic>{'full_name': fullName.trim()};

    if (email != null) {
      final cleanEmail = email.trim();
      payload['email'] = cleanEmail.isNotEmpty
          ? cleanEmail.toLowerCase()
          : null;
    }

    if (phone != null && phone.trim().isNotEmpty) {
      payload['phone'] = normalizePhone(phone.trim());
    }

    final response = await _api.patch(ApiConfig.me, data: payload);
    final user = UserModel.fromJson(response.data as Map<String, dynamic>);
    await _storeUser(user, stamp);
    AuthState().login(
      name: user.fullName,
      phone: user.phone,
      email: user.email ?? '',
      role: user.role,
      isVerified: user.isVerified,
    );
    return user;
  }

  /// Request phone change OTP (POST /api/v1/auth/me/phone/change/request/)
  Future<Map<String, dynamic>> requestPhoneChange(String newPhone) async {
    final response = await _api.post(
      ApiConfig.authPhoneChangeRequest,
      data: {'new_phone': normalizePhone(newPhone)},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Confirm phone change with OTP (POST /api/v1/auth/me/phone/change/confirm/)
  Future<Map<String, dynamic>> confirmPhoneChange({
    required String newPhone,
    required String code,
  }) async {
    final stamp = _snapshot();
    final response = await _api.post(
      ApiConfig.authPhoneChangeConfirm,
      data: {'new_phone': normalizePhone(newPhone), 'code': code.trim()},
    );
    _check(stamp);
    // Refresh user profile after confirmation
    try {
      await getMe();
    } catch (_) {}
    return response.data as Map<String, dynamic>;
  }

  /// Request email change OTP (POST /api/v1/auth/me/email/change/request/)
  Future<Map<String, dynamic>> requestEmailChange(String newEmail) async {
    final response = await _api.post(
      ApiConfig.authEmailChangeRequest,
      data: {'new_email': newEmail.trim().toLowerCase()},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Confirm email change with OTP (POST /api/v1/auth/me/email/change/confirm/)
  Future<Map<String, dynamic>> confirmEmailChange({
    required String newEmail,
    required String code,
  }) async {
    final stamp = _snapshot();
    final response = await _api.post(
      ApiConfig.authEmailChangeConfirm,
      data: {'new_email': newEmail.trim().toLowerCase(), 'code': code.trim()},
    );
    _check(stamp);
    // Refresh user profile after confirmation
    try {
      await getMe();
    } catch (_) {}
    return response.data as Map<String, dynamic>;
  }

  /// Check if user is currently logged in with a valid token
  Future<bool> isLoggedIn() async {
    return await _tokenStorage.hasToken();
  }
}
