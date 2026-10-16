import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:url_launcher/url_launcher.dart';

/// Google Maps Deep-Linking Engine
abstract class MapsLauncher {
  /// Opens clinic location on Google Maps
  static Future<bool> openMapLocation({
    required double latitude,
    required double longitude,
    String? googleMapsUrl,
    String? placeId,
    String? placeName,
  }) async {
    final hasValidUrl = googleMapsUrl != null &&
        googleMapsUrl.trim().toLowerCase().startsWith('http');
    final hasCoordinates = latitude != 0.0 || longitude != 0.0;

    if (!hasValidUrl &&
        !hasCoordinates &&
        (placeName == null || placeName.trim().isEmpty)) {
      if (kDebugMode) {
        debugPrint(
          '[MapsLauncher.openMapLocation] Failed: googleMapsUrl ("$googleMapsUrl"), coordinates ($latitude, $longitude), and placeName ("$placeName") are all empty.',
        );
      }
      return false;
    }

    if (hasValidUrl) {
      final uri = Uri.parse(googleMapsUrl.trim());
      try {
        if (await canLaunchUrl(uri)) {
          return await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[MapsLauncher.openMapLocation] Primary googleMapsUrl launch failed ($uri): $e. Falling back to coordinates/search.',
          );
        }
      }
    }

    // Standard Google Maps search URL with coordinates and place ID fallback
    String url;
    if (placeId != null && placeId.isNotEmpty && hasCoordinates) {
      url =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=$placeId';
    } else if (hasCoordinates) {
      url =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    } else {
      url =
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(placeName ?? 'UAE')}';
    }

    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MapsLauncher.openMapLocation] Failed to launch $uri: $e');
      }
      return false;
    }
  }

  /// Triggers native turn-by-turn directions to the clinic
  static Future<bool> openDirections({
    required double latitude,
    required double longitude,
    String? googleMapsUrl,
    String? destinationTitle,
  }) async {
    final hasValidUrl = googleMapsUrl != null &&
        googleMapsUrl.trim().toLowerCase().startsWith('http');
    final hasCoordinates = latitude != 0.0 || longitude != 0.0;

    if (!hasValidUrl &&
        !hasCoordinates &&
        (destinationTitle == null || destinationTitle.trim().isEmpty)) {
      if (kDebugMode) {
        debugPrint(
          '[MapsLauncher.openDirections] Failed: googleMapsUrl ("$googleMapsUrl"), coordinates ($latitude, $longitude), and destinationTitle ("$destinationTitle") are all empty.',
        );
      }
      return false;
    }

    if (hasValidUrl) {
      final uri = Uri.parse(googleMapsUrl.trim());
      try {
        if (await canLaunchUrl(uri)) {
          return await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[MapsLauncher.openDirections] Primary googleMapsUrl launch failed ($uri): $e. Falling back to directions URL.',
          );
        }
      }
    }

    final destination = hasCoordinates
        ? '$latitude,$longitude'
        : Uri.encodeComponent(destinationTitle ?? 'UAE');
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MapsLauncher.openDirections] Failed to launch $uri: $e');
      }
      return false;
    }
  }
}
