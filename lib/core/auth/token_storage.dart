import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure Local Storage for JWT Tokens and Cached User Profile
class TokenStorage {
  static final TokenStorage _instance = TokenStorage._internal();
  factory TokenStorage() => _instance;
  TokenStorage._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // In-memory cache for fast synchronous access
  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  Map<String, dynamic>? _cachedUserData;

  static const String _keyAccessToken = 'aw_access_token';
  static const String _keyRefreshToken = 'aw_refresh_token';
  static const String _keyUserData = 'aw_user_data';

  /// Initialize and load tokens from secure storage into memory
  Future<void> init() async {
    try {
      _cachedAccessToken = await _storage.read(key: _keyAccessToken);
      _cachedRefreshToken = await _storage.read(key: _keyRefreshToken);
      final rawUser = await _storage.read(key: _keyUserData);
      if (rawUser != null && rawUser.isNotEmpty) {
        _cachedUserData = jsonDecode(rawUser) as Map<String, dynamic>;
      }
    } catch (_) {
      // Fallback in case of platform storage issue
    }
  }

  /// Get current access token
  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null) return _cachedAccessToken;
    try {
      _cachedAccessToken = await _storage.read(key: _keyAccessToken);
    } catch (_) {}
    return _cachedAccessToken;
  }

  /// Synchronous access token from cache
  String? get currentAccessToken => _cachedAccessToken;

  /// Get current refresh token
  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) return _cachedRefreshToken;
    try {
      _cachedRefreshToken = await _storage.read(key: _keyRefreshToken);
    } catch (_) {}
    return _cachedRefreshToken;
  }

  /// Synchronous refresh token from cache
  String? get currentRefreshToken => _cachedRefreshToken;

  /// Save JWT tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    try {
      await _storage.write(key: _keyAccessToken, value: accessToken);
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    } catch (_) {}
  }

  /// Save user profile data
  Future<void> saveUser(Map<String, dynamic> userJson) async {
    _cachedUserData = userJson;
    try {
      await _storage.write(key: _keyUserData, value: jsonEncode(userJson));
    } catch (_) {}
  }

  /// Get cached user data
  Map<String, dynamic>? getUser() => _cachedUserData;

  /// Get user role string (e.g. 'patient', 'clinic_admin', 'clinic_staff', 'super_admin')
  String? getUserRole() => _cachedUserData?['role']?.toString();

  /// Check if user has an access token
  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored tokens and user data (Logout)
  Future<void> clear() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedUserData = null;
    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyUserData);
    } catch (_) {}
  }
}
