import '../../../core/utils/clinic_location.dart';
import '../../clinics/models/clinic_model.dart';
import '../models/uae_location.dart';
import '../services/patient_location_controller.dart';

class NearbyClinic {
  NearbyClinic({
    required this.clinic,
    required this.distanceKm,
    this.branchId,
    this.branchLocation,
  }) {
    if (branchLocation != null &&
        ClinicCoordinates.parse(
              branchLocation!.latitude,
              branchLocation!.longitude,
            ) ==
            null) {
      throw ArgumentError('Invalid branch location');
    }
    if (!distanceKm.isFinite || distanceKm < 0) {
      throw ArgumentError('Invalid server distance');
    }
  }
  final ClinicModel clinic;

  /// Only explicit server km from a confirmed query origin; never legacy distance.
  final double distanceKm;
  final String? branchId;

  /// Confirmed closest eligible branch, not a default city/map center.
  final ClinicCoordinates? branchLocation;
}

enum NearbyDistanceReference { unknown, device, selectedLocality }

class NearbyClinicsPage {
  const NearbyClinicsPage(
    this.items, {
    this.hasMore = false,
    this.total,
    this.reference = NearbyDistanceReference.unknown,
  });
  final List<NearbyClinic> items;
  final bool hasMore;
  final int? total;
  final NearbyDistanceReference reference;
}

class NearbySearchQuery {
  const NearbySearchQuery({this.origin, this.locality});
  final PatientPosition? origin;
  final UaeLocality? locality;
}

/// No HTTP adapter until Ali confirms canonical locality, eligible deduplicated
/// branches, distance-first ordering/units and stable pagination. Page size is20.
abstract class NearbyClinicsRepository {
  const NearbyClinicsRepository();
  bool get supported;
  Future<NearbyClinicsPage> search(NearbySearchQuery query, {int page = 1});
  Future<NearbyClinicsPage> getNearby(PatientPosition origin, {int page = 1}) =>
      search(NearbySearchQuery(origin: origin), page: page);
}

class UnavailableNearbyClinicsRepository extends NearbyClinicsRepository {
  const UnavailableNearbyClinicsRepository();
  @override
  bool get supported => false;
  @override
  Future<NearbyClinicsPage> search(NearbySearchQuery query, {int page = 1}) =>
      Future.error(
        UnsupportedError('No verified proximity contract in 09f49bb'),
      );
}
