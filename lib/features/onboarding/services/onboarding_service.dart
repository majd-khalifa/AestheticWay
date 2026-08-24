import 'package:flutter/foundation.dart';

/// Onboarding Service to track if the user has completed the initial onboarding walkthrough
class OnboardingService extends ChangeNotifier {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  bool _hasSeenOnboarding = false;

  bool get hasSeenOnboarding => _hasSeenOnboarding;

  void completeOnboarding() {
    _hasSeenOnboarding = true;
    notifyListeners();
  }

  void resetOnboarding() {
    _hasSeenOnboarding = false;
    notifyListeners();
  }
}
