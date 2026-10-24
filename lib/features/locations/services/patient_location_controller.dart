import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/auth/guest_auth_guard.dart';
import '../data/uae_location_repository.dart';

/// Session-memory foreground location only. Never persisted or put in telemetry.
class PatientPosition {
  const PatientPosition(this.latitude, this.longitude);
  final double latitude, longitude;
  bool get valid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180 &&
      (latitude != 0 || longitude != 0);
  // Coverage envelope, NOT proof of emirate/city membership (no reverse geocoder).
  bool get potentiallyUae =>
      valid &&
      latitude >= 22.6 &&
      latitude <= 26.2 &&
      longitude >= 51.4 &&
      longitude <= 56.6;
}

enum PatientLocationState {
  manual,
  requesting,
  ready,
  denied,
  deniedForever,
  disabled,
  timeout,
  outsideCoverage,
  unavailable,
}

abstract class ForegroundLocationProvider {
  Future<bool> servicesEnabled();
  Future<LocationPermission> permission();
  Future<LocationPermission> requestPermission();
  Future<PatientPosition> position();
}

class DeviceForegroundLocation implements ForegroundLocationProvider {
  @override
  Future<bool> servicesEnabled() => Geolocator.isLocationServiceEnabled();
  @override
  Future<LocationPermission> permission() => Geolocator.checkPermission();
  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();
  @override
  Future<PatientPosition> position() async {
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return PatientPosition(p.latitude, p.longitude);
  }
}

class PatientLocationController extends ChangeNotifier {
  PatientLocationController({ForegroundLocationProvider? provider})
    : _provider = provider ?? DeviceForegroundLocation() {
    AuthState().addListener(_sessionChanged);
  }
  final ForegroundLocationProvider _provider;
  int _generation = 0;
  bool _disposed = false;
  int _session = AuthState().sessionEpoch;
  String city = 'All';
  PatientPosition? position;
  PatientLocationState state = PatientLocationState.manual;
  bool get busy => state == PatientLocationState.requesting;
  void selectCity(String value) {
    ++_generation;
    city = compatibilityUaeCatalog.legacyCityQuery(value) ?? 'All';
    position = null;
    state = PatientLocationState.manual;
    notifyListeners();
  }

  void _sessionChanged() {
    if (_session == AuthState().sessionEpoch) return;
    _session = AuthState().sessionEpoch;
    selectCity('All');
  }

  Future<void> useDeviceLocation() async {
    if (busy ||
        _disposed ||
        !AuthState().isLoggedIn ||
        !AuthState().isPatient) {
      return;
    }
    final generation = ++_generation;
    bool current() => !_disposed && generation == _generation;
    state = PatientLocationState.requesting;
    position = null;
    notifyListeners();
    PatientLocationState result = PatientLocationState.unavailable;
    PatientPosition? found;
    try {
      if (!await _provider.servicesEnabled()) {
        result = PatientLocationState.disabled;
      } else {
        var permission = await _provider.permission();
        if (!current()) return;
        if (permission == LocationPermission.denied) {
          permission = await _provider.requestPermission();
        }
        if (!current()) return;
        if (permission == LocationPermission.deniedForever) {
          result = PatientLocationState.deniedForever;
        } else if (![
          LocationPermission.whileInUse,
          LocationPermission.always,
        ].contains(permission)) {
          result = PatientLocationState.denied;
        } else {
          final p = await _provider.position();
          if (!p.valid) {
            result = PatientLocationState.unavailable;
          } else if (!p.potentiallyUae) {
            result = PatientLocationState.outsideCoverage;
          } else {
            found = p;
            result = PatientLocationState.ready;
          }
        }
      }
    } on TimeoutException {
      result = PatientLocationState.timeout;
    } catch (_) {
      result = PatientLocationState.unavailable;
    }
    if (!current()) return;
    position = found;
    state = result;
    notifyListeners();
  }

  /// Discard GPS on backgrounding; a later user action may reacquire it.
  void releasePosition() {
    if (position != null || busy) {
      ++_generation;
      position = null;
      state = PatientLocationState.manual;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    position = null;
    AuthState().removeListener(_sessionChanged);
    super.dispose();
  }
}
