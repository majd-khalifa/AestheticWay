import 'package:url_launcher/url_launcher.dart';
import 'clinic_location.dart';

/// Google Maps Deep-Linking Engine
abstract class MapsLauncher {
  static Uri? verifiedPlaceUri({
    double? latitude,
    double? longitude,
    String? googleMapsUrl,
    String? placeId,
  }) {
    final stored = verifiedGoogleMapsUri(googleMapsUrl);
    if (stored != null) return stored;
    final point = ClinicCoordinates.parse(latitude, longitude);
    final place = placeId?.trim() ?? '';
    if (point == null && place.isEmpty) return null;
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': point == null ? place : '${point.latitude},${point.longitude}',
      if (place.isNotEmpty) 'query_place_id': place,
    });
  }

  static Uri? verifiedDirectionsUri({
    double? latitude,
    double? longitude,
    String? googleMapsUrl,
  }) {
    final stored = verifiedGoogleMapsUri(googleMapsUrl);
    if (stored != null) return stored;
    final point = ClinicCoordinates.parse(latitude, longitude);
    if (point == null) return null;
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${point.latitude},${point.longitude}',
      'travelmode': 'driving',
    });
  }

  static Future<bool> openVerifiedLocation({
    double? latitude,
    double? longitude,
    String? googleMapsUrl,
  }) async {
    final uri = verifiedDirectionsUri(
      latitude: latitude,
      longitude: longitude,
      googleMapsUrl: googleMapsUrl,
    );
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Only vetted Google links or source coordinates/search text may be launched.
  static Future<bool> openMapLocation({
    required double latitude,
    required double longitude,
    String? googleMapsUrl,
    String? placeId,
    String? placeName,
  }) async {
    final uri =
        verifiedPlaceUri(
          latitude: latitude,
          longitude: longitude,
          googleMapsUrl: googleMapsUrl,
          placeId: placeId,
        ) ??
        ((placeName?.trim().isNotEmpty ?? false)
            ? Uri.https('www.google.com', '/maps/search/', {
                'api': '1',
                'query': placeName!.trim(),
              })
            : null);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openDirections({
    required double latitude,
    required double longitude,
    String? googleMapsUrl,
    String? destinationTitle,
  }) async {
    final uri =
        verifiedDirectionsUri(
          latitude: latitude,
          longitude: longitude,
          googleMapsUrl: googleMapsUrl,
        ) ??
        ((destinationTitle?.trim().isNotEmpty ?? false)
            ? Uri.https('www.google.com', '/maps/dir/', {
                'api': '1',
                'destination': destinationTitle!.trim(),
                'travelmode': 'driving',
              })
            : null);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
