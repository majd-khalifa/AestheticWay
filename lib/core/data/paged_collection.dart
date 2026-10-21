import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:clock/clock.dart';
import '../network/api_exception.dart';
import '../localization/app_locale.dart';

const catalogPageSize = 20;

/// List-compatible result that retains the server's pagination envelope.
class PageItems<T> extends ListBase<T> {
  PageItems(Iterable<T> items, {required this.hasMore, this.total})
    : _items = List<T>.of(items);
  final List<T> _items;
  final bool hasMore;
  final int? total;

  factory PageItems.fromResponse(
    dynamic body,
    T Function(Map<String, dynamic>) parse, {
    int page = 1,
  }) {
    dynamic data = body;
    if (data is Map && data['data'] != null) data = data['data'];
    final envelope = data is Map ? data : null;
    final raw = envelope?['results'] ?? data;
    final values = raw is List ? raw : const [];
    final count = int.tryParse(envelope?['count']?.toString() ?? '');
    final more = envelope != null && envelope.containsKey('next')
        ? envelope['next'] != null && envelope['next'].toString().isNotEmpty
        : count != null
        ? page * catalogPageSize < count
        : values.length == catalogPageSize;
    return PageItems(
      values.take(catalogPageSize).whereType<Map<String, dynamic>>().map(parse),
      hasMore: more,
      total: count,
    );
  }
  @override
  int get length => _items.length;
  @override
  set length(int value) => _items.length = value;
  @override
  T operator [](int index) => _items[index];
  @override
  void operator []=(int index, T value) => _items[index] = value;
}

typedef PageLoader<T> =
    Future<List<T>> Function(int page, Map<String, dynamic> query);

/// One page request at a time per query; newer queries invalidate older responses.
class PagedCollection<T> extends ChangeNotifier {
  PagedCollection({
    required this.loader,
    required this.keyOf,
    List<T>? items,
    DateTime Function()? now,
  }) : items = items ?? <T>[],
       _now = now ?? clock.now;
  final PageLoader<T> loader;
  final String Function(T) keyOf;
  final List<T> items;
  final DateTime Function() _now;
  DateTime? _retryAt;
  int _failures = 0;
  DateTime? get retryNotBefore => _retryAt;
  bool get _coolingDown => _retryAt?.isAfter(_now()) ?? false;
  void _resetBackoff() {
    _failures = 0;
    _retryAt = null;
  }

  Map<String, dynamic> _query = {};
  Future<void>? _firstFlight;
  Future<void>? _nextFlight;
  Timer? _debounce;
  int _requestId = 0;
  int _page = 0;
  bool _disposed = false;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool isLoaded = false;
  bool hasMore = true;
  int? total;
  String? error;
  int get currentPage => _page;
  Map<String, dynamic> get query => Map.unmodifiable(_query);

  Future<void> refresh({Map<String, dynamic>? query, bool force = true}) {
    if (_disposed) return Future.value();
    final nextQuery = Map<String, dynamic>.of(query ?? _query);
    final sameQuery = mapEquals(nextQuery, _query);
    if (sameQuery && _firstFlight != null) return _firstFlight!;
    if (sameQuery && _coolingDown) return Future.value();
    if (sameQuery && isLoaded && !force) return Future.value();
    _debounce?.cancel();
    if (!sameQuery) {
      _resetBackoff();
      items.clear();
      isLoaded = false;
      _page = 0;
      total = null;
    }
    _query = nextQuery;
    final requestId = ++_requestId;
    _nextFlight = null;
    isLoadingMore = false;
    isLoading = true;
    error = null;
    if (!sameQuery || !isLoaded) hasMore = true;
    _notify();
    final flight = _fetch(1, requestId);
    _firstFlight = flight;
    return flight.whenComplete(() {
      if (identical(_firstFlight, flight)) _firstFlight = null;
    });
  }

  /// Commit an acknowledged write without letting an older GET erase it.
  void mutate(void Function(List<T>) change) {
    if (_disposed) return;
    ++_requestId;
    _debounce?.cancel();
    _firstFlight = null;
    _nextFlight = null;
    isLoading = false;
    isLoadingMore = false;
    error = null;
    _resetBackoff();
    final before = items.length;
    change(items);
    if (total != null) {
      total = (total! + items.length - before).clamp(0, 1 << 31);
    }
    _notify();
  }

  /// Invalidate immediately on input, before waiting for the 350 ms quiet period.
  void search(Map<String, dynamic> query) {
    if (_disposed) return;
    _debounce?.cancel();
    ++_requestId;
    _firstFlight = null;
    _nextFlight = null;
    if (!mapEquals(query, _query)) {
      _resetBackoff();
      items.clear();
      total = null;
      _page = 0;
    }
    _query = Map.of(query);
    isLoading = true;
    isLoadingMore = false;
    isLoaded = false;
    error = null;
    _notify();
    _debounce = Timer(const Duration(milliseconds: 350), () => refresh());
  }

  Future<void> loadMore() {
    if (_disposed || isLoading || !hasMore || _coolingDown) {
      return Future.value();
    }
    if (!isLoaded) return refresh();
    if (_nextFlight != null) return _nextFlight!;
    isLoadingMore = true;
    error = null;
    _notify();
    final flight = _fetch(_page + 1, _requestId);
    _nextFlight = flight;
    return flight.whenComplete(() {
      if (identical(_nextFlight, flight)) _nextFlight = null;
    });
  }

  Future<void> _fetch(int page, int requestId) async {
    try {
      final result = await loader(page, Map.of(_query));
      if (_disposed || requestId != _requestId) return;
      final bounded = result.take(catalogPageSize).toList();
      final previousKeys = page == 1 ? <String>{} : items.map(keyOf).toSet();
      final unique = bounded
          .where((item) => previousKeys.add(keyOf(item)))
          .toList();
      if (page == 1) items.clear();
      items.addAll(unique);
      total = result is PageItems<T> ? result.total : null;
      hasMore = result is PageItems<T>
          ? result.hasMore
          : result.length == catalogPageSize;
      if (page > 1 && unique.isEmpty) hasMore = false;
      _page = page;
      isLoaded = true;
      error = null;
      _resetBackoff();
    } catch (e) {
      if (_disposed || requestId != _requestId) return;
      if (page > 1 && e is ApiException && e.statusCode == 404) {
        hasMore = false;
      } else if (e is ApiException && e.isCancelled) {
        // Query/session cancellation is lifecycle control, not server failure.
        error = null;
      } else {
        error = e is ApiException
            ? e.message
            : LocaleService().isArabic
            ? 'تعذر تحميل المحتوى. يرجى المحاولة مرة أخرى.'
            : 'Unable to load content. Please try again.';
        final seconds = 1 << _failures.clamp(0, 5);
        _failures++;
        var delay = Duration(seconds: seconds.clamp(1, 30));
        if (e is ApiException &&
            e.retryAfter != null &&
            e.retryAfter! > delay) {
          delay = e.retryAfter!;
        }
        _retryAt = _now().add(delay);
      }
    } finally {
      if (!_disposed && requestId == _requestId) {
        isLoading = false;
        isLoadingMore = false;
        _notify();
      }
    }
  }

  void clear() {
    ++_requestId;
    _debounce?.cancel();
    _firstFlight = null;
    _nextFlight = null;
    items.clear();
    _query = {};
    _page = 0;
    isLoading = false;
    isLoadingMore = false;
    isLoaded = false;
    hasMore = true;
    total = null;
    error = null;
    _resetBackoff();
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_requestId;
    _debounce?.cancel();
    super.dispose();
  }
}
