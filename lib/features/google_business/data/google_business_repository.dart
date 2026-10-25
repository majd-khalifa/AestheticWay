import '../../../core/auth/guest_auth_guard.dart';
import '../../../core/auth/session_snapshot.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../clinic_portal/data/clinic_catalog_repository.dart';
import '../../clinics/models/clinic_model.dart';
import '../models/google_business.dart';

/// Authenticated, tenant-bound Places(New) contracts verified in backend465bf30.
/// No direct Google REST call or server key in Flutter.
abstract class GoogleBusinessRepository {
  GoogleBusinessCapabilities get capabilities;
  Future<GoogleBusinessAssociation> current();
  Future<List<GooglePlaceSuggestion>> autocomplete(
    String query, {
    required String sessionToken,
    required String languageCode,
  }) => Future.error(UnsupportedError('Google Business search unavailable'));
  Future<GoogleBusinessPlace> details(
    String placeId, {
    required String sessionToken,
    required String languageCode,
  }) => Future.error(UnsupportedError('Google Business details unavailable'));
  Future<GoogleBusinessAssociation> link(
    GoogleBusinessPlace place, {
    required String clinicId,
    required String expectedPlaceId,
  }) => Future.error(UnsupportedError('Google Business linking unavailable'));
  Future<GoogleBusinessAssociation> unlink({
    required String clinicId,
    required String expectedPlaceId,
  });
}

class CurrentClinicGoogleBusinessRepository extends GoogleBusinessRepository {
  CurrentClinicGoogleBusinessRepository({
    ClinicCatalogRepository? catalog,
    ApiClient? api,
  }) : _api = api ?? ApiClient(),
       _catalog =
           catalog ?? ClinicCatalogRepository(apiClient: api ?? ApiClient());
  final ApiClient _api;
  static const _base = 'clinic-portal/profile/google-business/';
  final ClinicCatalogRepository _catalog;
  @override
  GoogleBusinessCapabilities get capabilities =>
      const GoogleBusinessCapabilities(search: true, link: true, unlink: true);
  void _admin() {
    if (!AuthState().isLoggedIn || !AuthState().isClinicAdmin) {
      throw const ApiException(
        message: 'Clinic administrator access required.',
        statusCode: 403,
      );
    }
  }

  GoogleBusinessAssociation _association(ClinicModel c) =>
      GoogleBusinessAssociation(
        clinicId: c.id,
        placeId: c.googlePlaceId?.trim() ?? '',
        mapsUrl: c.googleMapsUrl,
        syncStatus: c.googleSyncStatus,
        lastSyncedAt: c.googleLastSyncedAt,
        verification: switch (c.googleLinkStatus) {
          'linked_verified_place' => GoogleBusinessVerification.verified,
          'pending_review' => GoogleBusinessVerification.pending,
          'rejected' => GoogleBusinessVerification.rejected,
          _ => GoogleBusinessVerification.notProvided,
        },
      );
  @override
  Future<GoogleBusinessAssociation> current() async {
    _admin();
    final session = SessionSnapshot();
    final c = await _catalog.getClinicProfile();
    session.ensureCurrent();
    _admin();
    if (c.id.isEmpty) {
      throw const ApiException(
        message: 'Clinic profile could not be verified.',
      );
    }
    return _association(c);
  }

  @override
  Future<GoogleBusinessAssociation> unlink({
    required String clinicId,
    required String expectedPlaceId,
  }) async {
    _admin();
    final session = SessionSnapshot();
    final before = await current();
    session.ensureCurrent();
    if (before.clinicId != clinicId ||
        before.placeId != expectedPlaceId ||
        expectedPlaceId.isEmpty) {
      throw const ApiException(
        message: 'The association changed. Refresh before continuing.',
        statusCode: 409,
      );
    }
    final response = await _api.post(
      '${_base}unlink/',
      data: {'expected_current_place_id': expectedPlaceId},
    );
    final ack = ClinicModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
    session.ensureCurrent();
    if (ack.id != clinicId || (ack.googlePlaceId?.trim().isNotEmpty ?? false)) {
      throw const ApiException(
        message: 'Unlinking was not confirmed. Refresh before retrying.',
      );
    }
    if (ack.googleSyncStatus != 'not_configured') {
      throw const ApiException(
        message: 'Unlinking was not acknowledged. Refresh before retrying.',
      );
    }
    // Controller performs the post-write fresh GET for durable UI success.
    return _association(ack);
  }

  @override
  Future<List<GooglePlaceSuggestion>> autocomplete(
    String query, {
    required String sessionToken,
    required String languageCode,
  }) async {
    _admin();
    final session = SessionSnapshot();
    final response = await _api.post(
      '${_base}autocomplete/',
      data: {
        'query': query.trim(),
        'session_token': sessionToken,
        'language_code': languageCode,
      },
    );
    session.ensureCurrent();
    final data = response.data;
    // Actual source returns suggestions, not the handoff example's results.
    if (data is! Map || data['suggestions'] is! List) {
      throw const ApiException(message: 'Invalid Google search response.');
    }
    return [
      for (final raw in data['suggestions'] as List)
        if (raw is Map &&
            GoogleBusinessPlace.validPlaceId('${raw['place_id'] ?? ''}'))
          GooglePlaceSuggestion(
            placeId: '${raw['place_id']}',
            name: '${raw['main_text'] ?? ''}'.trim().isNotEmpty
                ? '${raw['main_text']}'
                : '${raw['formatted_text'] ?? ''}',
            address: '${raw['secondary_text'] ?? ''}',
          ),
    ];
  }

  @override
  Future<GoogleBusinessPlace> details(
    String placeId, {
    required String sessionToken,
    required String languageCode,
  }) async {
    _admin();
    final session = SessionSnapshot();
    final response = await _api.post(
      '${_base}details/',
      data: {
        'place_id': placeId,
        'session_token': sessionToken,
        'language_code': languageCode,
      },
    );
    session.ensureCurrent();
    final d = Map<String, dynamic>.from(response.data as Map);
    final ttl = int.tryParse('${d['proof_expires_in']}');
    if (ttl == null ||
        ttl <= 0 ||
        ttl > 300 ||
        '${d['selection_proof'] ?? ''}'.isEmpty) {
      throw const ApiException(
        message: 'The selected result could not be verified.',
      );
    }
    return GoogleBusinessPlace(
      placeId: '${d['place_id'] ?? ''}',
      name: '${d['display_name'] ?? ''}',
      address: '${d['formatted_address'] ?? ''}',
      locality: '${d['locality'] ?? ''}',
      latitude: double.parse('${d['latitude']}'),
      longitude: double.parse('${d['longitude']}'),
      countryCode: '${d['country_code'] ?? ''}',
      selectionProof: '${d['selection_proof']}',
      mapsUrl: d['google_maps_url']?.toString(),
      proofExpiresIn: Duration(seconds: ttl),
    );
  }

  @override
  Future<GoogleBusinessAssociation> link(
    GoogleBusinessPlace place, {
    required String clinicId,
    required String expectedPlaceId,
  }) async {
    _admin();
    final session = SessionSnapshot();
    final before = await current();
    session.ensureCurrent();
    if (before.clinicId != clinicId || before.placeId != expectedPlaceId) {
      throw const ApiException(
        message: 'Refresh the Google association.',
        statusCode: 409,
        errorCode: 'STALE_GOOGLE_ASSOCIATION',
      );
    }
    final response = await _api.post(
      '${_base}link/',
      data: {
        'place_id': place.placeId, 'selection_proof': place.selectionProof,
        'expected_current_place_id': expectedPlaceId,
        // Maps URL is owned by the backend's single-use selection proof.
      },
    );
    session.ensureCurrent();
    final ack = ClinicModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
    if (ack.id != clinicId ||
        ack.googlePlaceId != place.placeId ||
        ack.googleLinkStatus != 'linked_verified_place') {
      throw const ApiException(
        message:
            'The selected place was not acknowledged. Refresh before retrying.',
      );
    }
    return _association(ack);
  }
}
