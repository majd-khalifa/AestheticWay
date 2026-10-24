import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/data/paged_collection.dart';
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
    if (distanceKm != null && (!distanceKm!.isFinite || distanceKm! < 0)) {
      throw ArgumentError('Invalid server distance');
    }
  }
  final ClinicModel clinic;

  /// Only explicit server km from a confirmed query origin; never legacy distance.
  final double? distanceKm;
  final String? branchId;

  /// Confirmed closest eligible branch, not a default city/map center.
  final ClinicCoordinates? branchLocation;
}

enum NearbyDistanceReference {
  unknown,
  device,
  selectedLocality,
  manualLocality,
}

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

/// Page size is20. Subscription tiers never change server distance ordering.
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

/// Actual401560b transport, held from patient production use because source
/// probes confirm active draft clinics are returned. Enable only after a supplied
/// backend revision enforces approved/public eligibility; no client flag bypass.
class BackendNearbyClinicsRepository extends NearbyClinicsRepository {
  BackendNearbyClinicsRepository({ApiClient? api}) : _api = api ?? ApiClient();
  final ApiClient _api;
  @override
  bool get supported => false;
  @override
  Future<NearbyClinicsPage> search(
    NearbySearchQuery query, {
    int page = 1,
  }) async {
    if (page < 1 || (query.origin == null && query.locality == null)) {
      throw const ApiException(message: 'Choose a location first.');
    }
    final gps = query.origin;
    if (gps != null && !gps.potentiallyUae) {
      throw const ApiException(message: 'Location is outside UAE coverage.');
    }
    final params = <String, dynamic>{
      'page': page,
      'page_size': catalogPageSize,
      if (gps != null) ...{
        'latitude': gps.latitude,
        'longitude': gps.longitude,
        'radius_km': 50,
      },
      if (gps == null) 'city': query.locality!.city.nameEn,
    };
    // /clinics/nearby requires both coordinates. Home's manual endpoint returns
    // distance_km:null and a source-limited top10; never fabricate a city center.
    final response = await _api.get(
      gps == null ? 'home/nearby-clinics/' : 'clinics/nearby/',
      queryParameters: params,
    );
    final data = response.data;
    if (data is! Map || data['results'] is! List) {
      throw const ApiException(message: 'Invalid nearby response.');
    }
    final rows = <NearbyClinic>[];
    for (final raw in data['results'] as List) {
      if (raw is! Map) {
        throw const ApiException(message: 'Invalid nearby clinic.');
      }
      final d = Map<String, dynamic>.from(raw);
      final km = d['distance_km'] is num
          ? (d['distance_km'] as num).toDouble()
          : null;
      if (gps != null && (km == null || !km.isFinite || km < 0)) {
        throw const ApiException(
          message: 'Server distance could not be verified.',
        );
      }
      if (gps == null && d['distance_km'] != null) {
        throw const ApiException(
          message: 'A distance requires a known origin.',
        );
      }
      final clinic = ClinicModel.fromJson(d);
      if (clinic.id.isEmpty) {
        throw const ApiException(message: 'Missing nearby clinic identity.');
      }
      final branch = d['nearest_branch_id']?.toString();
      rows.add(
        NearbyClinic(
          clinic: clinic,
          distanceKm: km,
          branchId: branch,
          // The list omits nearest-branch coordinates. Do not navigate to HQ
          // while presenting a branch distance; a confirmed branch detail is needed.
          branchLocation: branch == null
              ? ClinicCoordinates.parse(d['latitude'], d['longitude'])
              : null,
        ),
      );
    }
    return NearbyClinicsPage(
      rows,
      hasMore: data['next'] != null,
      total: data['count'] is int ? data['count'] as int : null,
      reference: gps == null
          ? NearbyDistanceReference.manualLocality
          : NearbyDistanceReference.device,
    );
  }
}
