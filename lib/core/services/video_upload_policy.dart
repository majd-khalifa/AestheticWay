import 'dart:math';
import 'package:dio/dio.dart';
import '../network/api_exception.dart';

///25MiB at512kbit/s takes≈410s; allow70s transport overhead. This budget does
/// not establish the deployed reverse proxy or storage deadline.
abstract class VideoUploadPolicy {
  static const traceKey = 'aw_video_transfer_trace';
  static const noReplayKey = 'aw_no_video_body_replay';
  static Duration get sendTimeout => Duration(
    seconds: const int.fromEnvironment(
      'AW_VIDEO_UPLOAD_SEND_SECONDS',
      defaultValue: 480,
    ).clamp(60, 1800),
  );
  static Duration get receiveTimeout => Duration(
    seconds: const int.fromEnvironment(
      'AW_VIDEO_UPLOAD_RECEIVE_SECONDS',
      defaultValue: 120,
    ).clamp(30, 600),
  );
  static Options options(VideoTransferTrace trace) => Options(
    sendTimeout: sendTimeout,
    receiveTimeout: receiveTimeout,
    headers: {'X-Request-ID': trace.requestId},
    extra: {traceKey: trace, noReplayKey: true},
  );
}

class VideoTransferTrace {
  VideoTransferTrace(int bytes)
    : sizeBand = bytes <= 5 * 1024 * 1024
          ? '0-5MiB'
          : bytes <= 10 * 1024 * 1024
          ? '5-10MiB'
          : bytes <= 20 * 1024 * 1024
          ? '10-20MiB'
          : '20-25MiB';
  final String sizeBand;
  final Stopwatch _elapsed = Stopwatch();
  final String requestId = _uuid();
  int? status;
  static String _uuid() {
    final r = Random.secure(), b = List.generate(16, (_) => 0);
    for (var i = 0; i < b.length; i++) {
      b[i] = r.nextInt(256);
    }
    b[6] = (b[6] & 15) | 64;
    b[8] = (b[8] & 63) | 128;
    final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  void start() => _elapsed.start();
  void finish(int? code) {
    status = code;
    _elapsed.stop();
  }

  VideoTransferDiagnostic snapshot() => VideoTransferDiagnostic(
    elapsedMilliseconds: _elapsed.elapsedMilliseconds,
    status: status,
    requestId: requestId,
    sizeBand: sizeBand,
  );
}

/// Explicit allowlist; never serialize RequestOptions, response bodies or URLs.
class VideoTransferDiagnostic {
  const VideoTransferDiagnostic({
    required this.elapsedMilliseconds,
    this.status,
    this.requestId,
    required this.sizeBand,
  });
  final int elapsedMilliseconds;
  final int? status;
  final String? requestId;
  final String sizeBand;
  String safeText(String phase) =>
      'phase=$phase elapsed_ms=$elapsedMilliseconds http=${status ?? 'none'} request_id=${requestId ?? 'none'} size_band=$sizeBand';
}

class VideoTransferException extends ApiException {
  VideoTransferException(ApiException cause, this.diagnostic)
    : super(
        message: cause.message,
        statusCode: cause.statusCode,
        errorCode: cause.errorCode,
        retryAfter: cause.retryAfter,
        isCancelled: cause.isCancelled,
        isLocalBackpressure: cause.isLocalBackpressure,
      );
  final VideoTransferDiagnostic diagnostic;
}
