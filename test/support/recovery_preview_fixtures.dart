// Disposable fixtures only; never imported by application code.
import 'package:dio/dio.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import '../onboarding_review_workflows_test.dart' as f;
import 'patient_fixtures.dart';

class ForegroundGps extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => Position(
    latitude: 25.1,
    longitude: 55.2,
    timestamp: DateTime.utc(2026),
    accuracy: 100,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

Map<String, dynamic> gpsClinic() => {
  'id': patientClinicId,
  'name_en': 'Disposable GPS clinic',
  'name_ar': 'عيادة اختبار الموقع',
  'city': 'Dubai',
  'latitude': 25.11,
  'longitude': 55.2,
};
Object homeGpsReply(RequestOptions r) {
  if (r.path == 'home/feed/') {
    return {
      'nearby_clinics': [gpsClinic()],
      'featured_ads': [],
      'active_offers': [],
      'categories': [],
    };
  }
  if (r.path == 'clinics/nearby/') {
    return f.page([
      {
        ...gpsClinic(),
        'distance_km': 2.4,
        'nearest_branch_id': null,
        'nearest_branch': null,
      },
    ]);
  }
  return f.page(r.path == 'clinics/' ? [gpsClinic()] : []);
}
