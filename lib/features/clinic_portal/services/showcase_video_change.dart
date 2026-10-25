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
    final advice = switch (status) {
      400 =>
        ar
            ? 'راجع صيغة الملف وحجمه ومدته وفق الحدود المعروضة.'
            : 'Check the displayed file format, size and duration limits.',
      403 =>
        ar
            ? 'حدّث الملف للتحقق من صلاحية VIP وصلاحيات المشرف.'
            : 'Refresh the profile to check VIP eligibility and administrator permissions.',
      413 =>
        ar
            ? 'رفض الخادم حجم الطلب. اختر ملفاً أصغر أو اطلب مراجعة حد رفع الفيديو في الخادم.'
            : 'The server rejected the upload size. Choose a smaller file or ask platform management to check the upload limit.',
      429 =>
        ar
            ? 'انتظر انتهاء فترة التهدئة قبل المحاولة مجدداً.'
            : 'Wait for the cooldown before retrying.',
      int code when code >= 500 =>
        ar
            ? 'الخادم غير متاح مؤقتاً. زوّد دعم المنصة بوقت المحاولة وحالة HTTP لمراجعة فشل الحفظ. تحقّق من الملف المحفوظ قبل إعادة الرفع.'
            : 'The server is temporarily unavailable. Give platform support the attempt time and HTTP status to inspect the failed save. Check the saved profile before re-uploading.',
      _ =>
        cause?.errorCode == 'TIMEOUT'
            ? (ar
                  ? 'انتهت مهلة الاتصال؛ قد يكون الخادم أكمل الحفظ. تحقّق أولاً.'
                  : 'The connection timed out; the server may have completed saving. Verify first.')
            : '',
    };
    final base = ar
        ? 'تعذر $phase${status == null ? '' : ' (HTTP $status)'}. لم يتم تأكيد الحفظ. احتُفظ باختيارك؛ تحقّق من الفيديو المحفوظ قبل إعادة الرفع.'
        : '$phase failed${status == null ? '' : ' (HTTP $status)'}. Saving is not confirmed. Your selection is preserved; check the saved video before uploading again.';
    return advice.isEmpty ? base : '$base $advice';
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
