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

  /// Helper to normalize UAE phone numbers to standard E.164 (+9715XXXXXXXX)
  /// Accepts formats such as:
  /// - 501234567 -> +971501234567
  /// - 0501234567 -> +971501234567
  /// - 50 123 4567 -> +971501234567
  /// - +971 50 123 4567 -> +971501234567
  /// - 971501234567 -> +971501234567
  static String normalizePhone(String phone) {
    var cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('+971')) {
      cleaned = cleaned.substring(4);
    } else if (cleaned.startsWith('00971')) {
      cleaned = cleaned.substring(5);
    } else if (cleaned.startsWith('971')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    while (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    return '+971$cleaned';
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
    final String platform = kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : 'ios');

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
      await _tokenStorage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );
      await _tokenStorage.saveUser(authResponse.user.toJson());

      // Update global AuthState
      AuthState().login(
        name: authResponse.user.fullName,
        phone: authResponse.user.phone,
        email: authResponse.user.email ?? '',
        role: authResponse.user.role,
        isVerified: authResponse.user.isVerified,
      );

      return authResponse;
    }

    return null;
  }

  /// Login with phone or email identifier and password
  Future<AuthResponse> login({
    required String identifier,
    required String password,
  }) async {
    final trimmed = identifier.trim();
    final normalizedIdentifier = trimmed.contains('@') ? trimmed : normalizePhone(trimmed);

    final response = await _api.post(
      ApiConfig.login,
      data: {
        'identifier': normalizedIdentifier,
        'password': password,
      },
    );

    final authResponse = AuthResponse.fromJson(response.data as Map<String, dynamic>);
    await _tokenStorage.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
    );
    await _tokenStorage.saveUser(authResponse.user.toJson());

    // Update global AuthState
    AuthState().login(
      name: authResponse.user.fullName,
      phone: authResponse.user.phone,
      email: authResponse.user.email ?? '',
      role: authResponse.user.role,
      isVerified: authResponse.user.isVerified,
    );

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
      data: {
        'phone': normalized,
        'purpose': purpose,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Request password reset OTP
  Future<Map<String, dynamic>> forgotPassword({
    required String phone,
  }) async {
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
    final response = await _api.post(
      ApiConfig.resetPassword,
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Logout, deactivate push token, and revoke refresh token on backend
  Future<void> logout() async {
    try {
      await DeviceTokenService().deactivateCurrentDevice();
    } catch (_) {}

    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        // Logout body strictly requires "refresh_token": "<token>"
        await _api.post(
          ApiConfig.logout,
          data: {'refresh_token': refreshToken},
        );
      } catch (_) {
        // Ignore backend errors during logout cleanup
      }
    }
    await _tokenStorage.clear();
    AuthState().logout();
  }

  /// Get current user profile from server (GET /api/v1/auth/me/)
  Future<UserModel> getMe() async {
    final response = await _api.get(ApiConfig.me);
    final user = UserModel.fromJson(response.data as Map<String, dynamic>);
    try {
      await _tokenStorage.saveUser(user.toJson());
    } catch (_) {}
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
    final payload = <String, dynamic>{
      'full_name': fullName.trim(),
    };

    if (email != null) {
      final cleanEmail = email.trim();
      payload['email'] = cleanEmail.isNotEmpty ? cleanEmail.toLowerCase() : null;
    }

    if (phone != null && phone.trim().isNotEmpty) {
      payload['phone'] = normalizePhone(phone.trim());
    }

    final response = await _api.patch(ApiConfig.me, data: payload);
    final user = UserModel.fromJson(response.data as Map<String, dynamic>);
    try {
      await _tokenStorage.saveUser(user.toJson());
    } catch (_) {}
    AuthState().updateProfile(
      name: user.fullName,
      phone: user.phone,
      email: user.email ?? '',
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
    final response = await _api.post(
      ApiConfig.authPhoneChangeConfirm,
      data: {
        'new_phone': normalizePhone(newPhone),
        'code': code.trim(),
      },
    );
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
    final response = await _api.post(
      ApiConfig.authEmailChangeConfirm,
      data: {
        'new_email': newEmail.trim().toLowerCase(),
        'code': code.trim(),
      },
    );
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
