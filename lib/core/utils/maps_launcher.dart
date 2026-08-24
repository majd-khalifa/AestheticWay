import 'package:url_launcher/url_launcher.dart';

/// Google Maps Deep-Linking Engine
abstract class MapsLauncher {
  /// Opens clinic location on Google Maps
  static Future<bool> openMapLocation({
    required double latitude,
    required double longitude,
    String? placeId,
    String? placeName,
  }) async {
    // Standard Google Maps search URL with coordinates and place ID fallback
    String url;
    if (placeId != null && placeId.isNotEmpty) {
      url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=$placeId';
    } else if (placeName != null && placeName.isNotEmpty) {
      url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(placeName)}';
    } else {
      url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Triggers native turn-by-turn directions to the clinic
  static Future<bool> openDirections({
    required double latitude,
    required double longitude,
    String? destinationTitle,
  }) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
