import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Theme management service supporting Light (default), Dark, and System modes
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String storageKey = 'aw_pref_theme_mode';
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Default on first launch (when no saved preference exists) is Light (Soft Light Luxury)
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;

  /// Restores persisted theme mode; defaults to Light mode when unset.
  Future<void> init() async {
    try {
      final savedMode = await _storage.read(key: storageKey);
      if (savedMode == ThemeMode.dark.name) {
        _themeMode = ThemeMode.dark;
      } else if (savedMode == ThemeMode.system.name) {
        _themeMode = ThemeMode.system;
      } else if (savedMode == ThemeMode.light.name) {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.light;
      }
      notifyListeners();
    } catch (_) {
      _themeMode = ThemeMode.light;
    }
  }

  bool isDark(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
    await _persistThemeMode(mode);
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
    await _persistThemeMode(_themeMode);
  }

  Future<void> _persistThemeMode(ThemeMode mode) async {
    try {
      await _storage.write(key: storageKey, value: mode.name);
    } catch (_) {}
  }
}
