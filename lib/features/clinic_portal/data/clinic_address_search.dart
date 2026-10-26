import 'package:dio/dio.dart';
import '../../../core/utils/clinic_location.dart';

/// Only genuine OSM result data. No generated translations or invented locality.
class ClinicAddressResult {
  const ClinicAddressResult({
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.addressEn,
    required this.addressAr,
    this.city = '',
    this.emirate = '',
  });
  final String title, addressEn, addressAr, city, emirate;
  final double latitude, longitude;
  static bool withinUae(double lat, double lng) =>
      ClinicCoordinates.parse(lat, lng) != null &&
      lat >= 22 &&
      lat <= 26.5 &&
      lng >= 51 &&
      lng <= 57;
  static ClinicAddressResult? fromJson(
    Map<String, dynamic> d, {
    required String language,
  }) {
    final lat = double.tryParse('${d['lat']}'),
        lng = double.tryParse('${d['lon']}');
    final a = d['address'] is Map ? d['address'] as Map : const {};
    if (lat == null ||
        lng == null ||
        !withinUae(lat, lng) ||
        a['country_code']?.toString().toLowerCase() != 'ae') {
      return null;
    }
    String text(Object? value) =>
        value is String && value.length <= 1500 ? value.trim() : '';
    final display = text(d['display_name']);
    if (display.isEmpty) return null;
    String localized(String code) {
      final parts = <String>[];
      for (final k in [
        'building',
        'house_name',
        'road',
        'neighbourhood',
        'suburb',
        'city',
        'state',
      ]) {
        final v = text(a['$k:$code']);
        if (v.isNotEmpty && !parts.contains(v)) parts.add(v);
      }
      if (parts.isNotEmpty) return parts.join('، ');
      // Nominatim may fall back to a different script despite accept-language.
      // Do not label that fallback as a translated address.
      final script = code == 'ar'
          ? RegExp(r'[\u0600-\u06FF]')
          : RegExp(r'[A-Za-z]');
      return language == code && script.hasMatch(display) ? display : '';
    }

    return ClinicAddressResult(
      title: display,
      latitude: lat,
      longitude: lng,
      addressEn: localized('en'),
      addressAr: localized('ar'),
      city: text(a['city'] ?? a['town'] ?? a['village'] ?? a['municipality']),
      emirate: text(a['state']),
    );
  }
}

/// Existing deliberate OSM address lookup: explicit submit only, no auth header,
/// one request/s in this process, small in-memory cache. Cross-device aggregate
/// limits and runtime provider switching require the backend proxy in handoff.
class ClinicAddressSearch {
  ClinicAddressSearch({Dio? client})
    : _client =
          client ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              followRedirects: false,
              headers: {
                'User-Agent': 'AestheticWay/1.0 (https://aestheticway.ae)',
              },
            ),
          );
  final Dio _client;
  static DateTime? _lastRequest;
  static final _cache = <String, (DateTime, List<ClinicAddressResult>)>{};
  Future<List<ClinicAddressResult>> search(
    String query, {
    required String language,
    CancelToken? cancelToken,
  }) async {
    final key = '$language:${query.trim()}';
    final cached = _cache[key];
    if (cached != null &&
        DateTime.now().difference(cached.$1) < const Duration(minutes: 10)) {
      return cached.$2;
    }
    if (_lastRequest != null &&
        DateTime.now().difference(_lastRequest!) < const Duration(seconds: 1)) {
      throw StateError('Address search is cooling down.');
    }
    _lastRequest = DateTime.now();
    final response = await _client.get<List<dynamic>>(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: {
        'q': query.trim(),
        'format': 'jsonv2',
        'countrycodes': 'ae',
        'limit': 4,
        'accept-language': language,
        'addressdetails': 1,
        'namedetails': 1,
      },
      cancelToken: cancelToken,
    );
    final rows = <ClinicAddressResult>[
      for (final d in response.data ?? [])
        if (d is Map)
          ?ClinicAddressResult.fromJson(
            Map<String, dynamic>.from(d),
            language: language,
          ),
    ];
    if (_cache.length >= 12) _cache.remove(_cache.keys.first);
    _cache[key] = (DateTime.now(), rows);
    return rows;
  }

  void close() => _client.close(force: true);
}
