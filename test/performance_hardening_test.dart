import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/network/auth_interceptor.dart';
import 'package:aesthetic_way/core/network/request_backpressure.dart';
import 'package:aesthetic_way/core/network/retry_after.dart';
import 'package:aesthetic_way/core/widgets/lazy_tab_stack.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/luxury_loading_skeleton.dart';
import 'package:aesthetic_way/features/home/data/home_repository.dart';
import 'package:aesthetic_way/features/products/data/products_repository.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/products/presentation/screens/products_screen.dart';
import 'package:aesthetic_way/features/products/presentation/widgets/brand_product_media.dart';
import 'performance_probe_test.dart' show ProbeAdapter, probeBody;

Map<String, dynamic> _page(int page, {int count = 520}) => {
  'count': count,
  'next': page * 20 < count ? '?page=${page + 1}' : null,
  'results': List.generate(
    (count - (page - 1) * 20).clamp(0, 20),
    (i) => {
      'id': 'fixture-${(page - 1) * 20 + i}',
      'name_en': 'Synthetic ${(page - 1) * 20 + i}',
      'brand_name_en': 'Fixture',
      'status': 'active',
    },
  ),
};

ResponseBody _failure(int status, {String? retry}) => ResponseBody.fromString(
  jsonEncode({'detail': 'Synthetic service failure'}),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
    if (retry != null) 'retry-after': [retry],
  },
);

class _HomeApi implements ApiClient {
  _HomeApi(this.reply);
  final Future<Object> Function(String) reply;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async => Response<T>(
    data: await reply(path) as T,
    requestOptions: RequestOptions(path: path),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient(), tokens = TokenStorage();
  late HttpClientAdapter original;
  late String base;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await tokens.clear();
    await LocaleService().setLanguage(AppLanguage.english);
    original = api.dio.httpClientAdapter;
    base = api.dio.options.baseUrl;
    api.dio.options.baseUrl = 'https://fixture.example.test/api/v1/';
  });
  tearDown(() async {
    api.dio.httpClientAdapter = original;
    api.dio.options.baseUrl = base;
    await tokens.clear();
  });

  test(
    '520 products are fetched as 26 distinct server pages, never at initial load',
    () async {
      final numbers = <int>[];
      api.dio.httpClientAdapter = ProbeAdapter((o) async {
        expect(o.queryParameters['page_size'], 20);
        final number = o.queryParameters['page'] as int;
        numbers.add(number);
        return probeBody(_page(number));
      });
      final repository = ProductsRepository(apiClient: api);
      final page = PagedCollection<ProductModel>(
        keyOf: (p) => p.id,
        loader: (n, _) => repository.getProducts(page: n, pageSize: 500),
      );
      await page.refresh();
      expect(numbers, [1]);
      expect(page.items.length, 20);
      while (page.hasMore) {
        await page.loadMore();
      }
      for (var i = 0; i < 20; i++) {
        await page.loadMore();
      }
      expect(numbers, List.generate(26, (i) => i + 1));
      expect(page.items.map((p) => p.id).toSet().length, 520);
      page.dispose();
    },
  );

  test(
    'failed scrolling backs off exponentially and offline recovery keeps prior pages',
    () async {
      var now = DateTime.utc(2026, 10, 20), failures = 0;
      final page = PagedCollection<int>(
        now: () => now,
        keyOf: (i) => '$i',
        loader: (number, _) async {
          if (number == 1) {
            return PageItems(List.generate(20, (i) => i), hasMore: true);
          }
          if (++failures <= 2) {
            throw const ApiException(message: 'Synthetic offline');
          }
          return PageItems([19, 20, 21], hasMore: false);
        },
      );
      await page.refresh();
      await page.loadMore();
      for (var i = 0; i < 100; i++) {
        await page.loadMore();
      }
      expect(failures, 1);
      expect(page.items.length, 20);
      now = now.add(const Duration(seconds: 1));
      await page.loadMore();
      expect(failures, 2);
      now = now.add(const Duration(seconds: 1));
      await page.loadMore();
      expect(failures, 2);
      now = now.add(const Duration(seconds: 1));
      await page.loadMore();
      expect(page.items.length, 22);
      expect(page.items.toSet().length, 22);
      expect(page.retryNotBefore, isNull);
      expect(page.error, isNull);
      page.dispose();
    },
  );

  test(
    'Retry-After cannot be bypassed by refreshing the same paged query',
    () async {
      var now = DateTime.utc(2026, 10, 20), calls = 0;
      final page = PagedCollection<int>(
        now: () => now,
        keyOf: (i) => '$i',
        loader: (_, _) async {
          if (++calls == 1) {
            throw const ApiException(
              message: 'Synthetic rate limit',
              statusCode: 429,
              retryAfter: Duration(seconds: 15),
            );
          }
          return PageItems([1], hasMore: false);
        },
      );
      await page.refresh();
      await page.refresh();
      await page.loadMore();
      now = now.add(const Duration(seconds: 14));
      await page.refresh();
      expect(calls, 1);
      now = now.add(const Duration(seconds: 1));
      await page.refresh();
      expect(calls, 2);
      expect(page.items, [1]);
      page.dispose();
    },
  );

  test(
    'same-query refresh failure keeps validated content and terminal pagination',
    () async {
      var fail = false;
      final page = PagedCollection<int>(
        keyOf: (i) => '$i',
        loader: (_, _) async {
          if (fail) {
            throw const ApiException(
              message: 'Synthetic failure',
              statusCode: 503,
            );
          }
          return PageItems([1, 2], hasMore: false);
        },
      );
      await page.refresh();
      fail = true;
      await page.refresh();
      expect(page.items, [1, 2]);
      expect(page.hasMore, isFalse);
      // A different query may not keep data from the old city/category.
      await page.refresh(query: {'city': 'abu dhabi'});
      expect(page.items, isEmpty);
      page.dispose();
    },
  );

  test('cancellation is silent and never starts a retry timer', () async {
    final page = PagedCollection<int>(
      keyOf: (i) => '$i',
      loader: (_, _) async {
        throw const ApiException(message: '', isCancelled: true);
      },
    );
    await page.refresh();
    expect(page.error, isNull);
    expect(page.retryNotBefore, isNull);
    expect(page.isLoading, isFalse);
    page.dispose();
  });

  testWidgets(
    'rapid city/category search changes send only the final query at 350 ms',
    (tester) async {
      final calls = <Map<String, dynamic>>[];
      final page = PagedCollection<int>(
        keyOf: (i) => '$i',
        loader: (_, q) async {
          calls.add(q);
          return PageItems([calls.length], hasMore: false);
        },
      );
      for (var i = 0; i < 8; i++) {
        page.search({
          'city': i.isEven ? 'dubai' : 'abu dhabi',
          'category': 'fixture-$i',
        });
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(calls, isEmpty);
      await tester.pump(const Duration(milliseconds: 249));
      expect(calls, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(calls, [
        {'city': 'abu dhabi', 'category': 'fixture-7'},
      ]);
      page.dispose();
    },
  );

  test(
    'equivalent overlapping GETs coalesce; completed responses are not cached',
    () async {
      var calls = 0;
      final gate = Completer<void>();
      final started = Completer<void>();
      api.dio.httpClientAdapter = ProbeAdapter((_) async {
        calls++;
        if (!started.isCompleted) started.complete();
        await gate.future;
        return probeBody({'fixture': true});
      });
      final a = api.get<Map<String, dynamic>>(
        'products/',
        queryParameters: {'page': 1, 'city': 'dubai'},
      );
      final b = api.get<dynamic>(
        'products/',
        queryParameters: {'city': 'dubai', 'page': 1},
      );
      await started.future;
      expect(calls, 1);
      gate.complete();
      expect((await a).data!['fixture'], isTrue);
      await b;
      expect(calls, 1);
      await api.get('products/', queryParameters: {'page': 1, 'city': 'dubai'});
      expect(calls, 2);
    },
  );

  test(
    'different filters, locale and custom Options remain independent reads',
    () async {
      var calls = 0;
      final gate = Completer<void>();
      final started = Completer<void>();
      api.dio.httpClientAdapter = ProbeAdapter((_) async {
        calls++;
        if (calls == 4) started.complete();
        await gate.future;
        return probeBody({'fixture': true});
      });
      final a = api.get('products/', queryParameters: {'city': 'dubai'});
      final b = api.get('products/', queryParameters: {'city': 'abu dhabi'});
      await LocaleService().setLanguage(AppLanguage.arabic);
      final c = api.get('products/', queryParameters: {'city': 'dubai'});
      final d = api.get<String>(
        'products/',
        queryParameters: {'city': 'dubai'},
        options: Options(responseType: ResponseType.plain),
      );
      await started.future;
      expect(calls, 4);
      gate.complete();
      await Future.wait([a, b, c]);
      expect((await d).data, isA<String>());
    },
  );

  test(
    'session switching never coalesces a new read with an older account',
    () async {
      final gates = <Completer<void>>[];
      final started = [Completer<void>(), Completer<void>()];
      api.dio.httpClientAdapter = ProbeAdapter((_) async {
        final gate = Completer<void>();
        gates.add(gate);
        started[gates.length - 1].complete();
        await gate.future;
        return probeBody({'fixture': gates.length});
      });
      final old = expectLater(
        api.get('leads/my/'),
        throwsA(
          isA<ApiException>().having((e) => e.isCancelled, 'cancelled', isTrue),
        ),
      );
      await started[0].future;
      await tokens.clear();
      final fresh = api.get('leads/my/');
      await started[1].future;
      expect(gates.length, 2);
      gates[1].complete();
      await fresh;
      gates[0].complete();
      await old;
    },
  );

  test(
    'writes are never coalesced or retried and invalidate in-flight read reuse',
    () async {
      var reads = 0, writes = 0;
      final gate = Completer<void>();
      final started = [Completer<void>(), Completer<void>()];
      api.dio.httpClientAdapter = ProbeAdapter((o) async {
        if (o.method == 'GET') {
          reads++;
          started[reads - 1].complete();
          await gate.future;
          return probeBody({'fixture': true});
        }
        writes++;
        return probeBody({'id': 'fixture-write'});
      });
      final before = api.get('products/');
      await started[0].future;
      await Future.wait([
        api.post('products/', data: {'name_en': 'Synthetic'}),
        api.post('products/', data: {'name_en': 'Synthetic'}),
      ]);
      final after = api.get('products/');
      await started[1].future;
      expect(reads, 2);
      expect(writes, 2);
      gate.complete();
      await Future.wait([before, after]);
    },
  );

  test(
    'Retry-After supports seconds and HTTP dates without retaining response data',
    () {
      final now = DateTime.utc(2026, 10, 20, 12);
      expect(parseRetryAfter('15', now: now), const Duration(seconds: 15));
      expect(
        parseRetryAfter(
          HttpDate.format(now.add(const Duration(seconds: 30))),
          now: now,
        ),
        const Duration(seconds: 30),
      );
      expect(
        parseRetryAfter(
          HttpDate.format(now.subtract(const Duration(seconds: 5))),
          now: now,
        ),
        Duration.zero,
      );
      expect(parseRetryAfter('-5', now: now), isNull);
      expect(parseRetryAfter('malformed', now: now), isNull);
    },
  );

  test(
    'duplicate Retry-After headers cannot break error handling or shorten the deadline',
    () {
      final options = RequestOptions(path: 'fixture/');
      final error = DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 429,
          headers: Headers.fromMap({
            'retry-after': ['malformed', '15', '30'],
          }),
        ),
      );
      expect(
        ApiException.fromDioError(error).retryAfter,
        const Duration(seconds: 30),
      );
    },
  );

  test(
    'server backpressure is bounded to the current API/session and expires without automatic retries',
    () {
      var now = DateTime.utc(2026, 10, 20);
      final pressure = RequestBackpressure(now: () => now);
      pressure.check('A');
      pressure.record(
        'A',
        const ApiException(
          message: 'Fixture',
          statusCode: 429,
          retryAfter: Duration(seconds: 10),
        ),
      );
      expect(() => pressure.check('A'), throwsA(isA<ApiException>()));
      now = now.add(const Duration(seconds: 10));
      pressure.check('A');
      pressure.check('B');
      pressure.record(
        'A',
        const ApiException(
          message: 'Old fixture',
          statusCode: 503,
          retryAfter: Duration(minutes: 1),
        ),
      );
      pressure.check('B');
    },
  );

  test(
    'missing Retry-After still backs off, and an in-flight success cannot erase the deadline',
    () {
      var now = DateTime.utc(2026, 10, 20);
      final pressure = RequestBackpressure(now: () => now);
      pressure.check('fixture');
      pressure.record(
        'fixture',
        const ApiException(message: 'Fixture', statusCode: 503),
      );
      expect(
        () => pressure.check('fixture'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.retryAfter,
            'delay',
            const Duration(seconds: 1),
          ),
        ),
      );
      now = now.add(const Duration(seconds: 1));
      pressure.check('fixture');
      pressure.record(
        'fixture',
        const ApiException(message: 'Fixture', statusCode: 503),
      );
      pressure.succeeded('fixture');
      expect(
        () => pressure.check('fixture'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.retryAfter,
            'delay',
            const Duration(seconds: 2),
          ),
        ),
      );
      now = now.add(const Duration(seconds: 2));
      pressure.check('fixture');
    },
  );

  test(
    'actual ApiClient honors Retry-After before further reads or writes',
    () async {
      var calls = 0;
      api.dio.httpClientAdapter = ProbeAdapter((_) async {
        calls++;
        return _failure(429, retry: '60');
      });
      await expectLater(
        api.get('products/'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.retryAfter,
            'retry',
            const Duration(seconds: 60),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await expectLater(
          api.get('clinics/'),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', 429),
          ),
        );
      }
      await expectLater(
        api.post('leads/', data: {'synthetic': true}),
        throwsA(isA<ApiException>()),
      );
      expect(calls, 1);
    },
  );

  test(
    'refresh rate-limit metadata reaches the caller without logging out or retrying',
    () async {
      await tokens.saveTokens(
        accessToken: 'fixture-access',
        refreshToken: 'fixture-refresh',
      );
      final dio = Dio(
        BaseOptions(baseUrl: 'https://fixture.example.test/api/v1/'),
      );
      final refresh = Dio();
      var rotations = 0;
      dio.httpClientAdapter = ProbeAdapter((_) async => _failure(401));
      refresh.httpClientAdapter = ProbeAdapter((_) async {
        rotations++;
        return _failure(429, retry: '15');
      });
      dio.interceptors.add(AuthInterceptor(dio, refreshDio: refresh));
      await expectLater(
        dio.get('products/'),
        throwsA(
          isA<DioException>()
              .having((e) => e.response?.statusCode, 'status', 429)
              .having(
                (e) => e.response?.headers.value('retry-after'),
                'retry',
                '15',
              ),
        ),
      );
      expect(rotations, 1);
      expect(tokens.currentAccessToken, 'fixture-access');
      dio.close();
      refresh.close();
    },
  );

  testWidgets('same-query refresh keeps genuine product cards visible', (
    tester,
  ) async {
    var calls = 0;
    final gate = Completer<void>();
    api.dio.httpClientAdapter = ProbeAdapter((_) async {
      if (++calls == 2) await gate.future;
      return probeBody(_page(1));
    });
    await tester.pumpWidget(
      MaterialApp(
        home: ProductsScreen(repository: ProductsRepository(apiClient: api)),
      ),
    );
    await tester.pumpAndSettle();
    final refresh = tester.state<RefreshIndicatorState>(
      find.byType(RefreshIndicator).first,
    );
    unawaited(refresh.show());
    for (var frame = 0; frame < 40 && calls < 2; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(calls, 2);
    expect(find.byType(BrandProductMedia), findsWidgets);
    expect(find.byType(LuxuryListSkeleton), findsNothing);
    gate.complete();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'narrow product imagery uses physical card dimensions and preserves aspect ratio',
    (tester) async {
      final product = ProductModel.fromJson({
        'id': 'fixture',
        'image': 'assets/images/app_launcher_icon.png',
      });
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              devicePixelRatio: 3,
            ),
            child: Center(
              child: SizedBox(
                width: 160,
                child: BrandProductMedia(product: product),
              ),
            ),
          ),
        ),
      );
      final provider =
          tester.widget<Image>(find.byType(Image).first).image as ResizeImage;
      expect(provider.width, 480);
      // A 160-wide studio frame is 200 high (4:5), at DPR 3.
      expect(provider.height, 600);
      expect(provider.policy, ResizeImagePolicy.fit);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('very tall real PNG decoding is bounded on both dimensions', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(Colors.blue, BlendMode.src);
      final picture = recorder.endRecording();
      final source = await picture.toImage(32, 4096);
      picture.dispose();
      final bytes = await source.toByteData(format: ui.ImageByteFormat.png);
      source.dispose();
      final dir = Directory.systemTemp.createTempSync('aw-decode-fixture-');
      try {
        final file = File('${dir.path}/synthetic.png')
          ..writeAsBytesSync(bytes!.buffer.asUint8List());
        final stream = boundedImageDecode(
          600,
          FileImage(file),
        ).resolve(ImageConfiguration.empty);
        final result = Completer<Size>();
        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (info, _) {
            result.complete(
              Size(info.image.width.toDouble(), info.image.height.toDouble()),
            );
            stream.removeListener(listener);
            info.dispose();
          },
          onError: (Object error, StackTrace? stack) =>
              result.completeError(error, stack),
        );
        stream.addListener(listener);
        final decoded = await result.future.timeout(const Duration(seconds: 5));
        expect(decoded.height, lessThanOrEqualTo(2160));
        expect(decoded.width, greaterThan(0));
        expect(decoded.width / decoded.height, closeTo(32 / 4096, 0.001));
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });

  testWidgets('rapid repeated tab switches reuse the loaded product page', (
    tester,
  ) async {
    var calls = 0, index = 0;
    late StateSetter change;
    api.dio.httpClientAdapter = ProbeAdapter((_) async {
      calls++;
      return probeBody(_page(1));
    });
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (_, setState) {
            change = setState;
            return LazyTabStack(
              index: index,
              builders: [
                (_) => ProductsScreen(
                  repository: ProductsRepository(apiClient: api),
                ),
                (_) => const Scaffold(body: Text('Fixture alternate tab')),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 20; i++) {
      change(() => index = 1 - index);
      await tester.pump();
    }
    expect(calls, 1);
    await tester.pumpWidget(const SizedBox());
  });

  test('optional directory failure cannot discard a valid Home feed', () async {
    final repo = HomeRepository(
      apiClient: _HomeApi((path) async {
        if (!path.contains('home')) {
          throw const ApiException(message: 'Synthetic directory failure');
        }
        return {
          'featured_ads': [
            {'id': 'fixture-ad', 'subscription_tier': 'vip'},
          ],
          'categories': [],
          'nearby_clinics': [],
          'active_offers': [],
        };
      }),
    );
    final feed = await repo.getHomeFeed();
    expect(feed.featuredAds.single.id, 'fixture-ad');
    expect(feed.partnerDirectoryUnavailable, isTrue);
  });
}
