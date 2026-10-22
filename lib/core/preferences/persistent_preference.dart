import 'package:flutter/foundation.dart';

/// Immediate UI changes, ordered durable writes, and race-safe cold-start reads.
class PersistentPreference<T> extends ChangeNotifier {
  PersistentPreference({
    required T defaultValue,
    required this.read,
    required this.write,
    required this.decode,
    required this.encode,
  }) : value = defaultValue;
  final Future<String?> Function() read;
  final Future<void> Function(String) write;
  final T Function(String?) decode;
  final String Function(T) encode;
  T value;
  int _revision = 0, _pending = 0;
  bool _disposed = false;
  bool saveFailed = false;
  bool get isSaving => _pending > 0;
  Future<void>? _tail, _restoring;

  Future<void> restore() =>
      _restoring ??= _restore().whenComplete(() => _restoring = null);
  Future<void> _restore() async {
    final revision = _revision;
    try {
      await _tail;
      final stored = await read();
      if (_disposed || revision != _revision) return;
      value = decode(stored);
      _notify();
    } catch (_) {
      // Keep the current value on keychain/read failure; never overwrite a
      // deliberate in-session choice with a late default.
    }
  }

  Future<void> setValue(T next) {
    value = next;
    final revision = ++_revision;
    final encoded = encode(next);
    _pending++;
    saveFailed = false;
    _notify();
    final previous = _tail;
    late final Future<void> flight;
    flight = (previous ?? Future<void>.value())
        .then((_) async {
          try {
            await write(encoded);
            if (revision == _revision) saveFailed = false;
          } catch (_) {
            if (revision == _revision) saveFailed = true;
          } finally {
            _pending--;
            _notify();
          }
        })
        .whenComplete(() {
          if (identical(_tail, flight)) _tail = null;
        });
    _tail = flight;
    return flight;
  }

  Future<void> retrySave() => setValue(value);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
