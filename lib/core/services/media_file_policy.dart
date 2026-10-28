import '../localization/app_locale.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../network/api_exception.dart';

/// Early UX checks only; Django must independently decode/validate all content.
abstract class MediaFilePolicy {
  static Future<DioMediaType> inspect(String path, {bool video = false}) async {
    final file = File(path);
    if (!await file.exists()) {
      throw ApiException(
        errorCode: 'LOCAL_MEDIA_MISSING',
        message: LocaleService().isArabic
            ? 'يرجى اختيار ملف الوسائط مجدداً.'
            : 'Please select the media file again.',
      );
    }
    final size = await file.length();
    if (size <= 0 || size > (video ? 25 : 5) * 1024 * 1024) {
      throw ApiException(
        errorCode: 'LOCAL_MEDIA_SIZE',
        message: LocaleService().isArabic
            ? (video
                  ? 'اختر فيديو لا يتجاوز حجمه 25 MB.'
                  : 'اختر صورة لا يتجاوز حجمها 5 MB.')
            : (video
                  ? 'Select a video no larger than 25 MB.'
                  : 'Select an image no larger than 5 MB.'),
      );
    }
    final ext = path.split('.').last.toLowerCase();
    final handle = await file.open();
    late List<int> bytes;
    try {
      bytes = await handle.read(16);
    } finally {
      await handle.close();
    }
    bool prefix(List<int> p) =>
        bytes.length >= p.length &&
        List.generate(p.length, (i) => bytes[i] == p[i]).every((v) => v);
    if (!video) {
      if (['jpg', 'jpeg'].contains(ext) && prefix([255, 216, 255])) {
        return DioMediaType('image', 'jpeg');
      }
      if (ext == 'png' && prefix([137, 80, 78, 71, 13, 10, 26, 10])) {
        return DioMediaType('image', 'png');
      }
      if (ext == 'webp' &&
          prefix([82, 73, 70, 70]) &&
          bytes.length >= 12 &&
          String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
        return DioMediaType('image', 'webp');
      }
    } else {
      if (ext == 'webm' && prefix([26, 69, 223, 163])) {
        return DioMediaType('video', 'webm');
      }
      if (['mp4', 'mov'].contains(ext) &&
          bytes.length >= 8 &&
          [
            'ftyp',
            'moov',
            'mdat',
            'wide',
          ].contains(String.fromCharCodes(bytes.sublist(4, 8)))) {
        return DioMediaType('video', ext == 'mov' ? 'quicktime' : 'mp4');
      }
    }
    throw ApiException(
      errorCode: 'LOCAL_MEDIA_FORMAT',
      message: LocaleService().isArabic
          ? 'تنسيق الملف المحدد غير مدعوم أو محتواه غير صالح.'
          : 'The selected media format is not supported or its content is invalid.',
    );
  }
}
