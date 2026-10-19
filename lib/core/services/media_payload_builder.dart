import 'dart:io';
import 'package:dio/dio.dart';
import '../network/api_exception.dart';
import '../network/api_config.dart';
import 'media_upload_service.dart';

/// Keeps URL, binary, omission and explicit removal semantics consistent.
class MediaPayloadBuilder {
  MediaPayloadBuilder(this._mediaUpload);
  final MediaUploadService _mediaUpload;

  Future<dynamic> build(
    Map<String, dynamic> data, {
    required List<String> fileKeys,
    String? clinicId,
  }) async {
    final mapCopy = Map<String, dynamic>.from(data);
    // JSON preserves explicit nulls. If another image is replaced in the same
    // save, upload it first instead of losing nulls in multipart encoding.
    final hasRemoval = fileKeys.any(
      (key) => mapCopy.containsKey(key) && mapCopy[key] == null,
    );
    bool hasFiles = false;
    for (final key in fileKeys) {
      final value = mapCopy[key];
      if (value == null) continue;
      if (value is String && _isRemoteUrl(value.trim())) {
        mapCopy[key] = value.trim();
        continue;
      }
      if (value is MultipartFile) {
        if (hasRemoval) {
          throw const ApiException(
            message:
                'Send image removals as JSON separately from prebuilt multipart files.',
          );
        }
        hasFiles = true;
        continue;
      }
      final path = value.toString();
      if (!File(path).existsSync()) {
        throw const ApiException(
          message:
              'The selected media file is no longer available. Please select it again.',
        );
      }
      if (hasRemoval && (key == 'logo' || key == 'cover_image')) {
        final uploaded = await _mediaUpload.uploadImage(
          filePath: path,
          mediaType: key == 'logo' ? 'clinic_logo' : 'clinic_cover',
          clinicId: clinicId,
        );
        final url = ApiConfig.firstMediaUrl([uploaded['url']]);
        if (!_isRemoteUrl(url)) {
          throw const ApiException(
            message: 'The image upload response is missing its URL.',
          );
        }
        mapCopy[key] = url;
      } else {
        if (hasRemoval) {
          throw const ApiException(
            message:
                'Please save the media removal before replacing the video.',
          );
        }
        mapCopy[key] = await MultipartFile.fromFile(
          path,
          filename: path.split(RegExp(r'[\\/]')).last,
        );
        hasFiles = true;
      }
    }
    return hasFiles ? FormData.fromMap(mapCopy) : mapCopy;
  }

  static bool _isRemoteUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }
}
