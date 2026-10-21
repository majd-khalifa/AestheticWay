import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure Local Storage for JWT Tokens and Cached User Profile
class TokenStorage {
  static final TokenStorage _instance = TokenStorage._internal();
  factory TokenStorage() => _instance;
  TokenStorage._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );

  Future<void>? _writeTail;
  Future<void>? _initializing;
  bool _initialized = false;

  // Persist credential changes in their invocation order, including logout.
  Future<void> _persist(Future<void> Function() task) {
    final pending = _writeTail;
    late final Future<void> next;
    next = (pending == null ? task() : pending.then((_) => task()))
        .catchError((Object _) {})
        .whenComplete(() {
          if (identical(_writeTail, next)) _writeTail = null;
        });
    _writeTail = next;
    return next;
  }

  int _sessionEpoch = 0;
  int _credentialVersion = 0;
  int get sessionEpoch => _sessionEpoch;
  int get credentialVersion => _credentialVersion;

  // In-memory cache for fast synchronous access
  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  Map<String, dynamic>? _cachedUserData;

  static const String _keyAccessToken = 'aw_access_token';
  static const String _keyRefreshToken = 'aw_refresh_token';
  static const String _keyUserData = 'aw_user_data';

  /// Initialize and load tokens from secure storage into memory
  Future<void> init() {
    return _initializing ??= _readInitial();
  }

  Future<void> _readInitial() async {
    final version = _credentialVersion;
    final epoch = _sessionEpoch;
    try {
      await _writeTail;
      final values = await Future.wait([
        _storage.read(key: _keyAccessToken),
        _storage.read(key: _keyRefreshToken),
        _storage.read(key: _keyUserData),
      ]);
      if (version != _credentialVersion || epoch != _sessionEpoch) return;
      final rawUser = values[2];
      final user = rawUser != null && rawUser.isNotEmpty
          ? jsonDecode(rawUser) as Map<String, dynamic>
          : null;
      _cachedAccessToken = values[0];
      _cachedRefreshToken = values[1];
      _cachedUserData = user;
    } catch (_) {
      /* A locked keychain leaves the session unauthenticated. */
    } finally {
      _initialized = true;
      _initializing = null;
    }
  }

  /// Get current access token
  Future<String?> getAccessToken() async {
    if (!_initialized) await init();
    return _cachedAccessToken;
  }

  /// Synchronous access token from cache
  String? get currentAccessToken => _cachedAccessToken;

  /// Get current refresh token
  Future<String?> getRefreshToken() async {
    if (!_initialized) await init();
    return _cachedRefreshToken;
  }

  /// Synchronous refresh token from cache
  String? get currentRefreshToken => _cachedRefreshToken;

  /// Save JWT tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    _initialized = true;
    _credentialVersion++;
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    return _persist(() async {
      await _storage.write(key: _keyAccessToken, value: accessToken);
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    });
  }

  /// Save user profile data
  Future<void> saveUser(Map<String, dynamic> userJson) {
    _initialized = true;
    if (_cachedUserData?['id'] != userJson['id'] ||
        _cachedUserData?['phone'] != userJson['phone'] ||
        _cachedUserData?['role'] != userJson['role']) {
      _sessionEpoch++;
    }
    _cachedUserData = Map.of(userJson);
    final encoded = jsonEncode(userJson);
    return _persist(() => _storage.write(key: _keyUserData, value: encoded));
  }

  /// Get cached user data
  Map<String, dynamic>? getUser() =>
      _cachedUserData == null ? null : Map.unmodifiable(_cachedUserData!);

  /// Get user role string (e.g. 'patient', 'clinic_admin', 'clinic_staff', 'super_admin')
  String? getUserRole() => _cachedUserData?['role']?.toString();

  /// Check if user has an access token
  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored tokens and user data (Logout)
  Future<void> clear() {
    _initialized = true;
    _sessionEpoch++;
    _credentialVersion++;
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedUserData = null;
    return _persist(() async {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyUserData);
    });
  }
}
