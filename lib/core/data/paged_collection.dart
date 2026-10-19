import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../network/api_exception.dart';

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
  PagedCollection({required this.loader, required this.keyOf, List<T>? items})
    : items = items ?? <T>[];
  final PageLoader<T> loader;
  final String Function(T) keyOf;
  final List<T> items;
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
    if (sameQuery && isLoaded && !force) return Future.value();
    _debounce?.cancel();
    if (!sameQuery) {
      isLoaded = false;
      _page = 0;
      total = null;
    }
    if (!sameQuery) {
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
    hasMore = true;
    _notify();
    final flight = _fetch(1, requestId);
    _firstFlight = flight;
    return flight.whenComplete(() {
      if (identical(_firstFlight, flight)) _firstFlight = null;
    });
  }

  /// Invalidate immediately on input, before waiting for the 350 ms quiet period.
  void search(Map<String, dynamic> query) {
    if (_disposed) return;
    _debounce?.cancel();
    ++_requestId;
    _firstFlight = null;
    _nextFlight = null;
    _query = Map.of(query);
    isLoading = true;
    isLoadingMore = false;
    isLoaded = false;
    error = null;
    _notify();
    _debounce = Timer(const Duration(milliseconds: 350), () => refresh());
  }

  Future<void> loadMore() {
    if (_disposed || isLoading || !hasMore) return Future.value();
    if (!isLoaded) return refresh();
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
    } catch (e) {
      if (_disposed || requestId != _requestId) return;
      if (page > 1 && e is ApiException && e.statusCode == 404) {
        hasMore = false;
      } else {
        error = e is ApiException ? e.message : e.toString();
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
