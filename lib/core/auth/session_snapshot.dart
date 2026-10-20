import 'guest_auth_guard.dart';
import 'token_storage.dart';
import 'session_changed_exception.dart';

/// Use across asynchronous payload preparation before starting a private write.
class SessionSnapshot {
  SessionSnapshot()
    : _tokens = TokenStorage().sessionEpoch,
      _identity = AuthState().sessionEpoch;
  final int _tokens, _identity;
  bool get isCurrent =>
      _tokens == TokenStorage().sessionEpoch &&
      _identity == AuthState().sessionEpoch;
  void ensureCurrent() {
    if (!isCurrent) {
      throw const SessionChangedException();
    }
  }
}
