import '../../clinics/models/clinic_model.dart';
import '../services/patient_location_controller.dart';

class NearbyClinic {
  NearbyClinic({required this.clinic, required this.distanceKm}) {
    if (!distanceKm.isFinite || distanceKm < 0) {
      throw ArgumentError('Invalid server distance');
    }
  }
  final ClinicModel clinic;

  /// Only an explicit server-calculated km field; never legacy `distance`.
  final double distanceKm;
}

class NearbyClinicsPage {
  const NearbyClinicsPage(this.items, {this.hasMore = false});
  final List<NearbyClinic> items;
  final bool hasMore;
}

/// Contract boundary, not an invented HTTP route. Enable only after Ali's source
/// confirms distance-first ordering, active/approved eligibility, branch
/// deduplication, stable pagination and distance_km units on supported databases.
abstract class NearbyClinicsRepository {
  bool get supported;
  Future<NearbyClinicsPage> getNearby(PatientPosition origin, {int page = 1});
}

class UnavailableNearbyClinicsRepository implements NearbyClinicsRepository {
  const UnavailableNearbyClinicsRepository();
  @override
  bool get supported => false;
  @override
  Future<NearbyClinicsPage> getNearby(PatientPosition origin, {int page = 1}) =>
      Future.error(
        UnsupportedError('No verified proximity contract in 09f49bb'),
      );
}
