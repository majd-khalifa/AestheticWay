/// Coalesces concurrent identical work; completed work is never cached.
class SingleFlight {
  final Map<String, Future<dynamic>> _pending = {};
  Future<T> run<T>(String key, Future<T> Function() task) {
    final pending = _pending[key];
    if (pending != null) return pending as Future<T>;
    late final Future<T> flight;
    flight = Future<T>.sync(task).whenComplete(() {
      if (identical(_pending[key], flight)) _pending.remove(key);
    });
    _pending[key] = flight;
    return flight;
  }

  void clear() => _pending.clear();
}
