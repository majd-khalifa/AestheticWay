import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/core/data/single_flight.dart';
import 'package:aesthetic_way/core/network/auth_interceptor.dart';
import 'package:aesthetic_way/core/widgets/lazy_tab_stack.dart';

class CallbackAdapter implements HttpClientAdapter {
  CallbackAdapter(this.callback);
  final Future<ResponseBody> Function(RequestOptions) callback;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    if (stream != null) await stream.drain<void>();
    return callback(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody body(int status, Object data) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

class MountProbe extends StatefulWidget {
  const MountProbe({super.key, required this.number, required this.mounts});
  final int number;
  final List<int> mounts;
  @override
  State<MountProbe> createState() => MountProbeState();
}

class MountProbeState extends State<MountProbe> {
  int clicks = 0;
  @override
  void initState() {
    super.initState();
    widget.mounts.add(widget.number);
  }

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => setState(() => clicks++),
    child: Text('${widget.number}:$clicks:${TabActivity.isActive(context)}'),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'five tabs mount on first visit and preserve state with activity gating',
    (tester) async {
      final mounts = <int>[];
      var selected = 0;
      late StateSetter choose;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              choose = setState;
              return LazyTabStack(
                index: selected,
                builders: [
                  for (var i = 0; i < 5; i++)
                    (_) => MountProbe(number: i, mounts: mounts),
                ],
              );
            },
          ),
        ),
      );
      expect(mounts, [0]);
      await tester.tap(find.text('0:0:true'));
      await tester.pump();
      choose(() => selected = 3);
      await tester.pump();
      expect(mounts, [0, 3]);
      expect(find.text('0:1:false', skipOffstage: false), findsOneWidget);
      choose(() => selected = 0);
      await tester.pump();
      expect(mounts, [0, 3]);
      expect(find.text('0:1:true'), findsOneWidget);
    },
  );

  test(
    '500 duplicate initial and scroll requests share one operation per page',
    () async {
      final pending = <Completer<List<int>>>[];
      final pages = <int>[];
      final page = PagedCollection<int>(
        keyOf: (i) => '$i',
        loader: (number, _) {
          pages.add(number);
          final c = Completer<List<int>>();
          pending.add(c);
          return c.future;
        },
      );
      final first = List.generate(500, (_) => page.refresh());
      expect(pages, [1]);
      pending[0].complete(
        PageItems(List.generate(20, (i) => i), hasMore: true, total: 10000),
      );
      await Future.wait(first);
      expect(page.items.length, 20);
      expect(page.total, 10000);
      final more = List.generate(500, (_) => page.loadMore());
      expect(pages, [1, 2]);
      pending[1].complete(
        PageItems(List.generate(20, (i) => i + 20), hasMore: true),
      );
      await Future.wait(more);
      expect(page.items, List.generate(40, (i) => i));
      page.dispose();
    },
  );

  testWidgets(
    'search waits 350 ms and invalidates an old response immediately',
    (tester) async {
      final pending = <Completer<List<String>>>[];
      final queries = <Map<String, dynamic>>[];
      final page = PagedCollection<String>(
        keyOf: (i) => i,
        loader: (_, query) {
          queries.add(query);
          final c = Completer<List<String>>();
          pending.add(c);
          return c.future;
        },
      );
      final old = page.refresh();
      page.search({'search': 's'});
      await tester.pump(const Duration(milliseconds: 200));
      page.search({'search': 'skin', 'category': 'new'});
      pending[0].complete(['stale']);
      await old;
      expect(page.items, isEmpty);
      await tester.pump(const Duration(milliseconds: 349));
      expect(queries.length, 1);
      await tester.pump(const Duration(milliseconds: 1));
      expect(queries.last['search'], 'skin');
      page.search({'search': 'final'});
      pending[1].complete(['also stale']);
      await tester.pump();
      expect(page.items, isEmpty);
      await tester.pump(const Duration(milliseconds: 350));
      pending[2].complete(PageItems(['correct'], hasMore: false));
      await tester.pump();
      expect(page.items, ['correct']);
      expect(page.hasMore, isFalse);
      page.dispose();
    },
  );

  test(
    'pagination retries failed page without duplicates and honors next=null',
    () async {
      var failed = false;
      var now = DateTime.utc(2026, 10, 20);
      final calls = <int>[];
      final page = PagedCollection<int>(
        now: () => now,
        keyOf: (i) => '$i',
        loader: (number, _) async {
          calls.add(number);
          if (number == 1) {
            return PageItems(List.generate(20, (i) => i), hasMore: true);
          }
          if (!failed) {
            failed = true;
            throw StateError('offline');
          }
          return PageItems([19, 20, 21], hasMore: false);
        },
      );
      await page.refresh();
      await page.loadMore();
      expect(page.currentPage, 1);
      expect(page.error, isNotNull);
      await page.loadMore();
      expect(calls, [1, 2]);
      now = now.add(const Duration(seconds: 1));
      await page.loadMore();
      await page.loadMore();
      expect(calls, [1, 2, 2]);
      expect(page.items.length, 22);
      expect(page.items.toSet().length, 22);
      page.dispose();
    },
  );

  test(
    'oversized server response is capped at twenty and dispose ignores completion',
    () async {
      final result = PageItems<int>.fromResponse({
        'count': 10000,
        'next': null,
        'results': List.generate(1000, (i) => {'id': i}),
      }, (m) => m['id'] as int);
      expect(result.length, 20);
      expect(result.hasMore, isFalse);
      final c = Completer<List<int>>();
      final page = PagedCollection<int>(
        keyOf: (i) => '$i',
        loader: (_, _) => c.future,
      );
      final first = page.refresh();
      page.dispose();
      c.complete([1]);
      await first;
      expect(page.items, isEmpty);
    },
  );

  test(
    'single-flight does not let an old session clear a new session operation',
    () async {
      final single = SingleFlight();
      final old = Completer<int>();
      final newer = Completer<int>();
      final a = single.run('portal', () => old.future);
      single.clear();
      final b = single.run('portal', () => newer.future);
      old.complete(1);
      await a;
      final joined = single.run('portal', () async => 99);
      newer.complete(2);
      expect(await b, 2);
      expect(await joined, 2);
    },
  );

  group('shared JWT refresh', () {
    final storage = TokenStorage();
    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      await storage.clear();
      await storage.saveTokens(
        accessToken: 'expired',
        refreshToken: 'refresh-old',
      );
    });
    tearDown(() async => storage.clear());
    test(
      '500 concurrent 401s rotate refresh once and all retry with new access',
      () async {
        var refreshes = 0;
        var successes = 0;
        var initial = 0;
        final barrier = Completer<void>();
        final refreshGate = Completer<void>();
        final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid/api/v1/'));
        final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
        refreshDio.httpClientAdapter = CallbackAdapter((options) async {
          refreshes++;
          await refreshGate.future;
          return body(200, {'access': 'fresh', 'refresh': 'refresh-new'});
        });
        dio.httpClientAdapter = CallbackAdapter((options) async {
          if (options.headers['Authorization'] == 'Bearer fresh') {
            successes++;
            return body(200, {'ok': true});
          }
          initial++;
          if (initial == 500) barrier.complete();
          await barrier.future;
          return body(401, {'detail': 'expired'});
        });
        dio.interceptors.add(AuthInterceptor(dio, refreshDio: refreshDio));
        final calls = List.generate(500, (i) => dio.get('protected/$i/'));
        await barrier.future;
        while (refreshes == 0) {
          await Future<void>.delayed(Duration.zero);
        }
        refreshGate.complete();
        await Future.wait(calls);
        expect(refreshes, 1);
        expect(successes, 500);
        expect(storage.currentRefreshToken, 'refresh-new');
        dio.close();
        refreshDio.close();
      },
    );
    test(
      'multipart retry clones finalized data and validation errors keep session',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid/'));
        final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
        var refreshes = 0;
        refreshDio.httpClientAdapter = CallbackAdapter((_) async {
          refreshes++;
          return body(200, {'access': 'fresh'});
        });
        dio.httpClientAdapter = CallbackAdapter(
          (options) async => body(
            options.headers['Authorization'] == 'Bearer fresh' ? 400 : 401,
            {'detail': 'invalid image'},
          ),
        );
        dio.interceptors.add(AuthInterceptor(dio, refreshDio: refreshDio));
        await expectLater(
          dio.patch(
            'profile/',
            data: FormData.fromMap({
              'logo': MultipartFile.fromBytes([1, 2], filename: 'logo.jpg'),
            }),
          ),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'status',
              400,
            ),
          ),
        );
        expect(refreshes, 1);
        expect(storage.currentAccessToken, 'fresh');
        dio.close();
        refreshDio.close();
      },
    );
    test('logout during refresh cannot resurrect credentials', () async {
      final started = Completer<void>();
      final reply = Completer<void>();
      final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid/'));
      final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
      refreshDio.httpClientAdapter = CallbackAdapter((_) async {
        started.complete();
        await reply.future;
        return body(200, {'access': 'stale'});
      });
      dio.httpClientAdapter = CallbackAdapter((_) async => body(401, {}));
      dio.interceptors.add(AuthInterceptor(dio, refreshDio: refreshDio));
      final call = expectLater(
        dio.get('protected/'),
        throwsA(isA<DioException>()),
      );
      await started.future;
      await storage.clear();
      reply.complete();
      await call;
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      dio.close();
      refreshDio.close();
    });
    test(
      'overlapping token writes and logout persist in invocation order',
      () async {
        final first = storage.saveTokens(
          accessToken: 'older',
          refreshToken: 'older-refresh',
        );
        final clear = storage.clear();
        final newer = storage.saveTokens(
          accessToken: 'new-session',
          refreshToken: 'new-refresh',
        );
        await Future.wait([first, clear, newer]);
        const secure = FlutterSecureStorage();
        expect(await secure.read(key: 'aw_access_token'), 'new-session');
        expect(await secure.read(key: 'aw_refresh_token'), 'new-refresh');
      },
    );
  });
}
