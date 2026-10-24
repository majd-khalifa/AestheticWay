import '../../../core/auth/guest_auth_guard.dart';
import '../../../core/auth/session_snapshot.dart';
import '../../../core/network/api_exception.dart';
import '../../clinic_portal/data/clinic_catalog_repository.dart';
import '../../clinics/models/clinic_model.dart';
import '../models/google_business.dart';

/// Search/details/link await Ali's authenticated, tenant-bound Places(New) API.
/// No guessed /places/ URL, direct Google REST call or server key in Flutter.
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
  CurrentClinicGoogleBusinessRepository({ClinicCatalogRepository? catalog})
    : _catalog = catalog ?? ClinicCatalogRepository();
  final ClinicCatalogRepository _catalog;
  @override
  GoogleBusinessCapabilities get capabilities =>
      const GoogleBusinessCapabilities(unlink: true);
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
    final ack = await _catalog.updateClinicProfile({
      'google_place_id': '',
      'google_maps_url': '',
    });
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
}
