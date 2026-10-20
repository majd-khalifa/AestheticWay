import 'local_media_cache.dart';
import 'dart:io';
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
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw ApiException(message: 'Local image file not found at: $filePath');
      }

      final fileName = filePath.split(RegExp(r'[\\/]')).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'media_type': mediaType,
        if (clinicId != null && clinicId.isNotEmpty) 'clinic_id': clinicId,
      });

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
      debugPrint('[MediaUploadService] Upload failed: $e');
      throw ApiException.fromDioError(e);
    } catch (e) {
      debugPrint('[MediaUploadService] Unexpected upload error: $e');
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }
}
