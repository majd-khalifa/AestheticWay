import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../preferences/persistent_preference.dart';

/// Defaults to Light on first install; keeps saved Dark/Light/System choices.
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal()
    : this.withStorage(
        const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        ),
      );
  ThemeService.withStorage(FlutterSecureStorage storage)
    : _preference = PersistentPreference<ThemeMode>(
        defaultValue: ThemeMode.light,
        read: () => storage.read(key: storageKey),
        write: (value) => storage.write(key: storageKey, value: value),
        decode: (value) => switch (value) {
          'dark' => ThemeMode.dark,
          'system' => ThemeMode.system,
          _ => ThemeMode.light,
        },
        encode: (value) => value.name,
      ) {
    _preference.addListener(notifyListeners);
  }
  static const String storageKey = 'aw_pref_theme_mode';
  final PersistentPreference<ThemeMode> _preference;
  ThemeMode get themeMode => _preference.value;
  bool get isDarkMode => themeMode == ThemeMode.dark;
  bool get isLightMode => themeMode == ThemeMode.light;
  bool get isSaving => _preference.isSaving;
  bool get saveFailed => _preference.saveFailed;
  Future<void> init() => _preference.restore();
  bool isDark(BuildContext context) => themeMode == ThemeMode.system
      ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
      : isDarkMode;
  Future<void> setThemeMode(ThemeMode mode) => _preference.setValue(mode);
  Future<void> toggleTheme() =>
      setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  Future<void> retrySave() => _preference.retrySave();
  @override
  void dispose() {
    _preference.removeListener(notifyListeners);
    _preference.dispose();
    super.dispose();
  }
}
