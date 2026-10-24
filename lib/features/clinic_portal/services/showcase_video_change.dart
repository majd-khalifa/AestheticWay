import '../../../core/localization/app_locale.dart';
import '../../../core/network/api_exception.dart';

enum VideoSaveStage { entitlement, upload, acknowledgment, reload, persistence }

/// Contains no file paths, response bodies, tokens or signed URLs in diagnostics.
class ShowcaseVideoFailure extends ApiException {
  ShowcaseVideoFailure(this.stage, {ApiException? cause, this.receipt})
    : super(
        message: _message(stage, cause),
        statusCode: cause?.statusCode,
        retryAfter: cause?.retryAfter,
        isLocalBackpressure: cause?.isLocalBackpressure ?? false,
        errorCode: 'VIDEO_${stage.name.toUpperCase()}',
      );
  final VideoSaveStage stage;
  final ShowcaseVideoReceipt? receipt;
  static String _message(VideoSaveStage stage, ApiException? cause) {
    final ar = LocaleService().isArabic;
    final phase = switch (stage) {
      VideoSaveStage.entitlement =>
        ar ? 'التحقق من صلاحية الفيديو' : 'Video permission refresh',
      VideoSaveStage.upload => ar ? 'رفع الفيديو' : 'Video upload',
      VideoSaveStage.acknowledgment =>
        ar ? 'تأكيد حفظ الفيديو' : 'Video save acknowledgment',
      VideoSaveStage.reload =>
        ar ? 'إعادة تحميل الفيديو المحفوظ' : 'Saved-video reload',
      VideoSaveStage.persistence =>
        ar ? 'التحقق من حفظ الفيديو' : 'Video persistence check',
    };
    final status = cause?.isLocalBackpressure == true
        ? null
        : cause?.statusCode;
    return ar
        ? 'تعذر $phase${status == null ? '' : ' (HTTP $status)'}. لم يتم تأكيد الحفظ. احتُفظ باختيارك؛ تحقّق من الفيديو المحفوظ قبل إعادة الرفع.'
        : '$phase failed${status == null ? '' : ' (HTTP $status)'}. Saving is not confirmed. Your selection is preserved; check the saved video before uploading again.';
  }
}

/// Private in-memory write receipt, discarded when the editor/session closes.
class ShowcaseVideoReceipt {
  const ShowcaseVideoReceipt(this.clinicId, this.videoUrl, this.coverUrl);
  final String clinicId;
  final String? videoUrl;
  final String coverUrl;
  static String? remoteKey(String? value) {
    final uri = Uri.tryParse(value ?? '');
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.path.isEmpty) {
      return null;
    }
    return '${uri.scheme}://${uri.authority}${uri.path}';
  }
}
