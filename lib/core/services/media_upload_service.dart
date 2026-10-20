import '../auth/session_changed_exception.dart';
import 'media_file_policy.dart';
import '../auth/session_snapshot.dart';
import 'local_media_cache.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_config.dart';
import '../network/api_exception.dart';

/// Centralized service for binary media uploads to backend /api/v1/media/upload/
class MediaUploadService {
  static final MediaUploadService _instance = MediaUploadService._internal();
  factory MediaUploadService({ApiClient? client}) {
    if (client != null) {
      return MediaUploadService._custom(client);
    }
    return _instance;
  }

  MediaUploadService._internal() : _client = ApiClient();
  MediaUploadService._custom(this._client);

  final ApiClient _client;

  /// Uploads a local file to the secure backend media service using multipart/form-data.
  ///
  /// [filePath] Local path to image on device.
  /// [mediaType] One of: 'clinic_logo', 'clinic_cover', 'clinic_gallery',
  ///             'practitioner_avatar', 'product_image', 'offer_image',
  ///             'article_cover', 'patient_profile_image'.
  /// [clinicId] Target clinic UUID (optional, auto-resolved by backend for clinic staff/admins).
  Future<Map<String, dynamic>> uploadImage({
    required String filePath,
    required String mediaType,
    String? clinicId,
  }) async {
    final cacheEpoch = LocalMediaCache().epoch;
    final session = SessionSnapshot();
    try {
      final mime = await MediaFilePolicy.inspect(filePath);
      final fileName = 'image.${mime.subtype == 'jpeg' ? 'jpg' : mime.subtype}';
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: mime,
        ),
        'media_type': mediaType,
        if (clinicId != null && clinicId.isNotEmpty) 'clinic_id': clinicId,
      });

      session.ensureCurrent();
      final response = await _client.post(
        ApiConfig.mediaUpload,
        data: formData,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        LocalMediaCache().remember(
          localPath: filePath,
          remoteUrl: data['url'] is String ? data['url'] as String : null,
          expectedEpoch: cacheEpoch,
        );
        return data;
      }
      return <String, dynamic>{};
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[media_upload] failed status=${e.response?.statusCode} type=${e.type.name}',
        );
      }
      throw ApiException.fromDioError(e);
    } catch (e) {
      if (kDebugMode) debugPrint('[media_upload] failed type=${e.runtimeType}');
      if (e is ApiException || e is SessionChangedException) rethrow;
      throw const ApiException(
        message: 'The image could not be uploaded. Please try again.',
      );
    }
  }
}
