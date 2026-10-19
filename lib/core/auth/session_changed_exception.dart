/// Signals that an asynchronous response belongs to a previous account.
class SessionChangedException implements Exception {
  const SessionChangedException();

  @override
  String toString() => 'The session changed. Please sign in again.';
}
