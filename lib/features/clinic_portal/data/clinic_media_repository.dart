import '../../../core/auth/session_snapshot.dart';
import '../../../core/data/paged_collection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/media_upload_service.dart';
import '../../../core/services/media_operation_trace.dart';
import '../../../core/utils/entity_id.dart';
import 'package:dio/dio.dart';

class ClinicGalleryAsset {
  const ClinicGalleryAsset({
    required this.id,
    required this.clinicId,
    required this.url,
  });
  final String id, clinicId, url;
  factory ClinicGalleryAsset.fromJson(Map<String, dynamic> data) {
    final id = data['id']?.toString() ?? '';
    final clinic = data['clinic_id']?.toString() ?? '';
    final url = ApiConfig.firstMediaUrl([data['url']]);
    if (!isEntityUuid(id) ||
        !isEntityUuid(clinic) ||
        url.isEmpty ||
        data['media_type'] != 'clinic_gallery' ||
        !(data['mime_type']?.toString().startsWith('image/') ?? false)) {
      throw const ApiException(
        message:
            'The gallery response is incomplete or contains unsupported media.',
      );
    }
    return ClinicGalleryAsset(id: id, clinicId: clinic, url: url);
  }
}

/// Uses source-confirmed c25e901 media routes. Association happens at upload;
/// gallery_images is read-only and never PATCHed as an array of URLs.
class ClinicMediaRepository {
  ClinicMediaRepository({ApiClient? apiClient, MediaUploadService? uploads})
    : _api = apiClient ?? ApiClient(),
      _uploads =
          uploads ?? MediaUploadService(client: apiClient ?? ApiClient());
  final ApiClient _api;
  final MediaUploadService _uploads;
  Future<List<ClinicGalleryAsset>> getGallery(
    String clinicId, {
    int page = 1,
  }) async {
    if (!isEntityUuid(clinicId)) {
      throw const ApiException(
        message: 'Reload the clinic profile before managing media.',
      );
    }
    final response = await _api.get(
      'media/',
      queryParameters: {
        'media_type': 'clinic_gallery',
        'page': page,
        'page_size': catalogPageSize,
      },
    );
    final result = PageItems<ClinicGalleryAsset>.fromResponse(
      response.data,
      ClinicGalleryAsset.fromJson,
      page: page,
    );
    // Backend membership scoping is authoritative; reject ambiguous multi-clinic
    // responses instead of dropping rows and corrupting pagination metadata.
    if (result.any((a) => a.clinicId != clinicId)) {
      throw const ApiException(
        message: 'The media collection does not match the current clinic.',
      );
    }
    return result;
  }

  Future<ClinicGalleryAsset> uploadGallery(
    String clinicId,
    String path, {
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
    MediaOperationTrace? trace,
  }) async {
    if (!isEntityUuid(clinicId)) {
      throw const ApiException(
        message: 'Reload the clinic profile before managing media.',
      );
    }
    final session = SessionSnapshot();
    final operation = trace ?? MediaOperationTrace();
    final data = await _uploads.uploadImage(
      filePath: path,
      mediaType: 'clinic_gallery',
      clinicId: clinicId,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
      trace: operation,
    );
    session.ensureCurrent();
    operation.stage = MediaOperationStage.acknowledgment;
    if (operation.httpStatus != 201) {
      throw ApiException(
        message:
            'The upload was not acknowledged as a saved image. Review saved images before retrying.',
        statusCode: operation.httpStatus,
        errorCode: 'INVALID_MEDIA_ACK',
      );
    }
    late ClinicGalleryAsset asset;
    try {
      asset = ClinicGalleryAsset.fromJson(data);
    } on ApiException {
      throw ApiException(
        message:
            'The server acknowledged the upload, but its saved image record is incomplete. Review saved images before retrying.',
        statusCode: operation.httpStatus,
        errorCode: 'INVALID_MEDIA_ACK',
      );
    }
    if (asset.clinicId != clinicId) {
      throw ApiException(
        message: 'The uploaded image does not belong to the current clinic.',
        statusCode: operation.httpStatus,
        errorCode: 'INVALID_MEDIA_ACK',
      );
    }
    operation.assetAcknowledged = true;
    return asset;
  }

  Future<void> deleteGallery(String clinicId, ClinicGalleryAsset asset) async {
    if (!isEntityUuid(asset.id) ||
        asset.clinicId != clinicId ||
        !isEntityUuid(clinicId)) {
      throw const ApiException(
        message: 'This image cannot be removed from the current clinic.',
      );
    }
    await _api.delete('media/${asset.id}/');
  }
}
