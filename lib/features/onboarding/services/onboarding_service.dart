import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/preferences/persistent_preference.dart';

/// Device preference, separate from authentication keys and account logout.
class OnboardingService extends ChangeNotifier {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal()
    : this.withStorage(
        const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        ),
      );
  OnboardingService.withStorage(FlutterSecureStorage storage)
    : _preference = PersistentPreference<bool>(
        defaultValue: false,
        read: () => storage.read(key: storageKey),
        write: (value) => storage.write(key: storageKey, value: value),
        decode: (value) => value == 'true',
        encode: (value) => '$value',
      ) {
    _preference.addListener(notifyListeners);
  }
  static const storageKey = 'aw_pref_onboarding_completed';
  final PersistentPreference<bool> _preference;
  bool get hasSeenOnboarding => _preference.value;
  bool get saveFailed => _preference.saveFailed;
  Future<void> init() => _preference.restore();
  Future<void> completeOnboarding() => _preference.setValue(true);

  /// Replaying introduction never resets completion. Authentication also proves
  /// the introduction must not interrupt this established user's next launch.
  Future<void> recordAuthenticatedSession() async {
    if (!hasSeenOnboarding || saveFailed) await completeOnboarding();
  }

  @override
  void dispose() {
    _preference.removeListener(notifyListeners);
    _preference.dispose();
    super.dispose();
  }
}
