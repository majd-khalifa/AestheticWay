import 'package:flutter/foundation.dart';
import '../../../core/auth/guest_auth_guard.dart';
import '../../../core/auth/session_snapshot.dart';
import '../../../core/data/paged_collection.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/network/api_exception.dart';
import '../data/nearby_clinics_repository.dart';
import 'patient_location_controller.dart';

class NearbyDiscoveryController extends ChangeNotifier {
  NearbyDiscoveryController(this.location, this.repository) {
    paging = PagedCollection<NearbyClinic>(
      keyOf: (r) => r.clinic.id,
      loader: (page, q) async {
        final session = SessionSnapshot();
        final query = q['selection'] as NearbySearchQuery;
        final result = await repository.search(query, page: page);
        session.ensureCurrent();
        if (_disposed || q['generation'] != _generation) {
          throw const ApiException(message: 'Location changed.');
        }
        if (result.items.isNotEmpty &&
            (result.reference == NearbyDistanceReference.unknown ||
                (result.reference == NearbyDistanceReference.selectedLocality &&
                    query.locality == null))) {
          throw const ApiException(
            message: 'Distance reference could not be verified.',
          );
        }
        if (result.reference == NearbyDistanceReference.device &&
            query.origin == null) {
          throw const ApiException(
            message: 'Distance reference could not be verified.',
          );
        }
        if (result.reference == NearbyDistanceReference.manualLocality &&
            (query.locality == null ||
                result.items.any((r) => r.distanceKm != null))) {
          throw const ApiException(
            message: 'Manual discovery must not claim distances.',
          );
        }
        if (result.reference != NearbyDistanceReference.unknown &&
            result.reference != NearbyDistanceReference.manualLocality) {
          double previous = page == 1 || paging.items.isEmpty
              ? -1
              : paging.items.last.distanceKm!;
          for (final row in result.items) {
            if (row.distanceKm == null || row.distanceKm! < previous) {
              throw const ApiException(
                message: 'Proximity ordering could not be verified.',
              );
            }
            previous = row.distanceKm!;
          }
        }
        if (page == 1) reference = result.reference;
        if (reference != result.reference) {
          throw const ApiException(
            message: 'Distance reference changed. Refresh before continuing.',
          );
        }
        return PageItems(
          result.items.take(catalogPageSize),
          hasMore: result.hasMore,
          total: result.total,
        );
      },
    )..addListener(notifyListeners);
    location.addListener(_changed);
    _changed();
  }
  final PatientLocationController location;
  final NearbyClinicsRepository repository;
  late final PagedCollection<NearbyClinic> paging;
  int _generation = 0;
  bool _active = true, _disposed = false;
  void setActive(bool value) {
    if (_active == value) return;
    _active = value;
    _changed();
  }

  NearbyDistanceReference reference = NearbyDistanceReference.unknown;
  bool get allowed => AuthState().isLoggedIn && AuthState().isPatient;
  bool get canQuery =>
      !_disposed &&
      _active &&
      allowed &&
      repository.supported &&
      (location.position != null || location.locality != null) &&
      !location.busy;
  void _changed() {
    ++_generation;
    reference = NearbyDistanceReference.unknown;
    if (!canQuery) {
      paging.clear();
      return;
    }
    paging.search({
      'generation': _generation,
      'selection': NearbySearchQuery(
        origin: location.position,
        locality: location.locality,
      ),
    });
  }

  Future<void> refresh() async {
    if (!canQuery) return;
    await paging.refresh();
  }

  String distanceLabel(NearbyClinic row) {
    final ar = LocaleService().isArabic;
    return switch (reference) {
      NearbyDistanceReference.device =>
        ar
            ? 'على بُعد ${row.distanceKm?.toStringAsFixed(1)} كم تقريباً'
            : 'Approximately ${row.distanceKm?.toStringAsFixed(1)} km away',
      NearbyDistanceReference.selectedLocality =>
        ar
            ? '${row.distanceKm?.toStringAsFixed(1)} كم من الموقع المحدد'
            : '${row.distanceKm?.toStringAsFixed(1)} km from the selected locality',
      NearbyDistanceReference.unknown ||
      NearbyDistanceReference.manualLocality => '',
    };
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    location.removeListener(_changed);
    paging.removeListener(notifyListeners);
    paging.dispose();
    super.dispose();
  }
}
