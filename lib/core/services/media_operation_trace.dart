import '../network/api_exception.dart';

enum MediaOperationStage {
  localValidation,
  multipartUpload,
  acknowledgment,
  galleryRead,
  profileRead,
  deletion,
}

/// In-memory support facts only. Never retains bodies, URLs, filenames or IDs.
class MediaOperationTrace {
  final startedAt = DateTime.now().toUtc();
  MediaOperationStage stage = MediaOperationStage.localValidation;
  int? httpStatus;
  int? uploadHttpStatus;
  bool assetAcknowledged = false;
  bool galleryVerified = false, profileVerified = false;
  String? code;
  List<String> fields = const [];

  void begin(MediaOperationStage value) {
    stage = value;
    httpStatus = null;
    code = null;
    fields = const [];
  }

  void failed(Object error) {
    if (error is! ApiException) {
      code = 'CLIENT_ERROR';
      return;
    }
    httpStatus = error.statusCode ?? httpStatus;
    if (stage == MediaOperationStage.multipartUpload ||
        stage == MediaOperationStage.acknowledgment) {
      uploadHttpStatus = error.statusCode ?? uploadHttpStatus;
    }
    code = error.isCancelled
        ? 'CANCELLED'
        : safeCodes.contains(error.errorCode)
        ? error.errorCode
        : error.errorCode == null
        ? 'UNSPECIFIED'
        : 'UNRECOGNIZED_API_CODE';
    fields =
        (error.fieldErrors?.keys ?? const <String>[])
            .where(safeFields.contains)
            .toList()
          ..sort();
  }

  static const safeFields = {
    'file',
    'media_type',
    'clinic_id',
    'media_asset',
    'id',
    'url',
    'mime_type',
    'non_field_errors',
  };
  static const safeCodes = {
    'VALIDATION_ERROR',
    'PERMISSION_DENIED',
    'NOT_AUTHENTICATED',
    'AUTHENTICATION_FAILED',
    'NOT_FOUND',
    'THROTTLED',
    'SERVER_ERROR',
    'STORAGE_ERROR',
    'TIMEOUT',
    'CONNECTION_ERROR',
    'CANCELLED',
    'LOCAL_MEDIA_MISSING',
    'LOCAL_MEDIA_SIZE',
    'LOCAL_MEDIA_FORMAT',
    'INVALID_MEDIA_ACK',
    'GALLERY_READ_UNCONFIRMED',
    'PROFILE_GALLERY_UNCONFIRMED',
  };

  String get supportDetails =>
      'stage=${stage.name}; HTTP=${httpStatus ?? "none"}; '
      'upload_HTTP=${uploadHttpStatus ?? "none"}; '
      'code=${code ?? "none"}; fields=${fields.isEmpty ? "none" : fields.join(",")}; '
      'asset_ack=${assetAcknowledged ? "yes" : "unconfirmed"}; '
      'gallery_read=${galleryVerified ? "verified" : "unconfirmed"}; '
      'profile_read=${profileVerified ? "verified" : "unconfirmed"}; '
      'started_utc=${startedAt.toIso8601String()}';
}
