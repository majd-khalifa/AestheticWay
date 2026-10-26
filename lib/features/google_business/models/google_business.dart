import '../../../core/utils/clinic_location.dart';

enum GoogleBusinessVerification { notProvided, pending, verified, rejected }

class GoogleBusinessAssociation {
  const GoogleBusinessAssociation({
    required this.clinicId,
    this.placeId = '',
    this.mapsUrl,
    this.syncStatus = '',
    this.lastSyncedAt,
    this.verification = GoogleBusinessVerification.notProvided,
    this.city = '',
  });
  final String clinicId, placeId, syncStatus;
  final String city;
  final String? mapsUrl;
  final DateTime? lastSyncedAt;
  final GoogleBusinessVerification verification;
  bool get linked => placeId.trim().isNotEmpty;
  // A successful rating sync does NOT prove ownership or business verification.
}

class GooglePlaceSuggestion {
  const GooglePlaceSuggestion({
    required this.placeId,
    required this.name,
    required this.address,
  });
  final String placeId, name, address;
}

class GoogleBusinessPlace {
  GoogleBusinessPlace({
    required this.placeId,
    required this.name,
    required this.address,
    required this.locality,
    required this.latitude,
    required this.longitude,
    required this.countryCode,
    required this.selectionProof,
    this.mapsUrl,
    this.proofExpiresIn = const Duration(seconds: 300),
    this.addressLanguage = '',
    this.emirateCode,
  }) {
    if (!validPlaceId(placeId) ||
        name.trim().isEmpty ||
        address.trim().isEmpty ||
        ClinicCoordinates.parse(latitude, longitude) == null) {
      throw ArgumentError('Invalid place detail');
    }
  }
  final String placeId, name, address, locality, countryCode;
  final String addressLanguage;
  final String? emirateCode;

  /// Opaque server-issued proof of the selected result, not an API key.
  final String selectionProof;
  final Duration proofExpiresIn;
  final double latitude, longitude;
  final String? mapsUrl;
  static bool validPlaceId(String value) =>
      value.trim().isNotEmpty &&
      value.length <= 255 &&
      !RegExp(r'\s|[\x00-\x1F\x7F]').hasMatch(value);
}

class GoogleBusinessCapabilities {
  const GoogleBusinessCapabilities({
    this.search = false,
    this.link = false,
    this.unlink = false,
  });
  final bool search, link, unlink;
}
