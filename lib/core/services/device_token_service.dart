import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';

/// Lightweight service managing FCM push notification device tokens
/// connected to backend endpoint: /api/v1/notifications/devices/
class DeviceTokenService {
  static final DeviceTokenService _instance = DeviceTokenService._internal();
  factory DeviceTokenService() => _instance;
  DeviceTokenService._internal();

  static const String _storageKey = 'aw_device_push_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiClient _api = ApiClient();

  String? _lastRegisteredToken;

  /// Returns the currently active cached or persisted device push token
  Future<String?> getSavedToken() async {
    if (_lastRegisteredToken != null && _lastRegisteredToken!.isNotEmpty) {
      return _lastRegisteredToken;
    }
    try {
      _lastRegisteredToken = await _storage.read(key: _storageKey);
      return _lastRegisteredToken;
    } catch (_) {
      return null;
    }
  }

  /// Registers or updates the push notification device token on the backend.
  /// Automatically detects platform ('android' | 'ios' | 'web').
  Future<bool> registerDeviceToken({
    required String token,
    String? platform,
    String appVersion = '1.0.0',
  }) async {
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) return false;

    final resolvedPlatform =
        platform?.toLowerCase().trim() ?? _detectPlatform();

    final payload = {
      'token': cleanToken,
      'platform': resolvedPlatform,
      'app_version': appVersion.trim(),
    };

    try {
      await _api.post(ApiConfig.notificationDevices, data: payload);

      _lastRegisteredToken = cleanToken;
      try {
        await _storage.write(key: _storageKey, value: cleanToken);
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('[DeviceTokenService] Failed to register push token: $e');
      return false;
    }
  }

  /// Deactivates the given or currently saved push token on the backend (e.g. during user logout).
  Future<bool> deactivateCurrentDevice({String? token}) async {
    final tokenToDeactivate = token?.trim() ?? await getSavedToken();
    if (tokenToDeactivate == null || tokenToDeactivate.isEmpty) {
      return true;
    }

    try {
      await _api.delete(
        ApiConfig.notificationDeviceDeactivate(tokenToDeactivate),
      );
    } catch (e) {
      debugPrint('[DeviceTokenService] Deactivation notice: $e');
    } finally {
      _lastRegisteredToken = null;
      try {
        await _storage.delete(key: _storageKey);
      } catch (_) {}
    }

    return true;
  }

  String _detectPlatform() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isIOS) return 'ios';
      if (Platform.isAndroid) return 'android';
    } catch (_) {}
    return 'android';
  }
}
