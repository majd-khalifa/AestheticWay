import '../localization/app_locale.dart';
import 'api_exception.dart';
import 'package:clock/clock.dart';

/// No retries or response cache. Reject early while this API/session is cooling
/// down, so scroll/retry taps cannot flood a server that supplied Retry-After.
class RequestBackpressure {
  RequestBackpressure({DateTime Function()? now}) : _now = now ?? clock.now;
  final DateTime Function() _now;
  String? _scope;
  DateTime? _until;
  int _failures = 0;

  void clear() {
    _scope = null;
    _until = null;
    _failures = 0;
  }

  void check(String scope) {
    if (_scope != scope) {
      clear();
      _scope = scope;
    }
    final remaining = _until?.difference(_now());
    if (remaining != null && remaining > Duration.zero) {
      throw ApiException(
        message: LocaleService().isArabic
            ? 'يرجى الانتظار قليلاً قبل المحاولة مرة أخرى.'
            : 'Please wait a moment before trying again.',
        statusCode: 429,
        errorCode: 'THROTTLED',
        isLocalBackpressure: true,
        retryAfter: remaining,
      );
    }
  }

  void record(String scope, ApiException error) {
    if (scope != _scope || ![429, 503].contains(error.statusCode)) {
      return;
    }
    final delay =
        error.retryAfter ??
        Duration(seconds: (1 << _failures.clamp(0, 5)).clamp(1, 30));
    _failures++;
    if (delay <= Duration.zero) return;
    final until = _now().add(delay);
    if (_until == null || until.isAfter(_until!)) _until = until;
  }

  void succeeded(String scope) {
    if (scope == _scope) _failures = 0;
    // An already in-flight success must not cancel another request's deadline.
  }
}
