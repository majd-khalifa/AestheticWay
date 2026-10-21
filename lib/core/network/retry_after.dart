import 'dart:io' show HttpDate, HttpException;
import 'package:clock/clock.dart';

/// Supports Retry-After delta seconds and RFC HTTP dates.
Duration? parseRetryAfter(String? value, {DateTime? now}) {
  if (value == null) return null;
  final seconds = int.tryParse(value.trim());
  if (seconds != null) {
    if (seconds < 0) return null;
    // Guard Duration/date arithmetic; do not turn a distant deadline into an
    // immediate retry. Up to a year can be represented without overflow.
    return Duration(seconds: seconds.clamp(0, 365 * 24 * 60 * 60));
  }
  try {
    final delay = HttpDate.parse(value).difference(now ?? clock.now());
    return delay.isNegative ? Duration.zero : delay;
  } on FormatException {
    return null;
  } on HttpException {
    return null;
  }
}
