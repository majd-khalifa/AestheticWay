import '../../features/locations/data/uae_location_repository.dart';

/// Coordinates must come from a stored record or a confirmed map selection.
class ClinicCoordinates {
  const ClinicCoordinates(this.latitude, this.longitude);
  final double latitude, longitude;
  static ClinicCoordinates? parse(Object? lat, Object? lng) {
    final a = double.tryParse('$lat'), b = double.tryParse('$lng');
    if (a == null ||
        b == null ||
        !a.isFinite ||
        !b.isFinite ||
        a < -90 ||
        a > 90 ||
        b < -180 ||
        b > 180 ||
        (a == 0 && b == 0)) {
      return null;
    }
    return ClinicCoordinates(a, b);
  }
}

const clinicCities = <String, String>{
  'Dubai': 'دبي',
  'Abu Dhabi': 'أبوظبي',
  'Sharjah': 'الشارقة',
  'Ajman': 'عجمان',
  'Ras Al Khaimah': 'رأس الخيمة',
  'Fujairah': 'الفجيرة',
  'Umm Al Quwain': 'أم القيوين',
};
String _normalized(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[أإآ]'), 'ا')
    .replaceAll(RegExp(r'\s+'), '');
String _cityKey(String value) {
  final n = _normalized(value);
  for (final entry in clinicCities.entries) {
    if (_normalized(entry.key) == n || _normalized(entry.value) == n) {
      return entry.key;
    }
  }
  return value.trim();
}

String localizedClinicCity(String value, {required bool arabic}) {
  final city = currentUaeCatalog.resolve(value);
  if (city != null) return city.label(arabic);
  final key = _cityKey(value);
  return arabic ? (clinicCities[key] ?? value.trim()) : key;
}

String formatClinicLocation(String city, String area, {required bool arabic}) {
  final parts = <String>[], seen = <String>{};
  for (final value in [city, area]) {
    if (value.trim().isEmpty || !seen.add(_normalized(_cityKey(value)))) {
      continue;
    }
    parts.add(localizedClinicCity(value, arabic: arabic));
  }
  return parts.isEmpty
      ? (arabic ? 'الموقع غير متوفر' : 'Location not provided')
      : parts.join(' • ');
}

/// Only recognized Google Maps links are eligible for the location action.
Uri? verifiedGoogleMapsUri(String? value) {
  final uri = Uri.tryParse(value?.trim() ?? '');
  if (uri == null ||
      !['http', 'https'].contains(uri.scheme) ||
      uri.userInfo.isNotEmpty ||
      uri.hasPort) {
    return null;
  }
  final host = uri.host.toLowerCase();
  final known =
      host == 'maps.app.goo.gl' ||
      (host == 'goo.gl' && uri.path.startsWith('/maps')) ||
      ([
            'google.com',
            'www.google.com',
            'google.ae',
            'www.google.ae',
          ].contains(host) &&
          uri.path.startsWith('/maps')) ||
      ['maps.google.com', 'maps.google.ae'].contains(host);
  return known ? uri.replace(scheme: 'https') : null;
}
