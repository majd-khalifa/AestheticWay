// Deterministic local probes. Virtual time and fixture bytes are not device
// latency, network throughput, frame timing or production capacity evidence.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/home/data/home_repository.dart';
import 'package:aesthetic_way/features/products/data/products_repository.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/products/presentation/screens/products_screen.dart';
import 'package:aesthetic_way/features/products/presentation/widgets/brand_product_media.dart';

class ProbeAdapter implements HttpClientAdapter {
  ProbeAdapter(this.reply);
  final Future<ResponseBody> Function(RequestOptions) reply;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) => reply(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody probeBody(Object value) => ResponseBody.fromString(
  jsonEncode(value),
  200,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

class _HomeApi implements ApiClient {
  final calls = <String>[];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    calls.add(path);
    await Future<void>.delayed(
      Duration(milliseconds: path.contains('home') ? 100 : 150),
    );
    final Object data = path.contains('home')
        ? {
            'featured_ads': [],
            'categories': [],
            'active_offers': [],
            'nearby_clinics': [],
          }
        : {'count': 0, 'next': null, 'results': []};
    return Response<T>(
      data: data as T,
      requestOptions: RequestOptions(path: path),
    );
  }
}

void probe(Map<String, Object> metrics) {
  // ignore: avoid_print
  print('PERFORMANCE_PROBE ${jsonEncode(metrics)}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  late HttpClientAdapter originalAdapter;
  late String originalBase;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    originalAdapter = api.dio.httpClientAdapter;
    originalBase = api.dio.options.baseUrl;
    api.dio.options.baseUrl = 'https://fixture.example.test/api/v1/';
  });
  tearDown(() {
    api.dio.httpClientAdapter = originalAdapter;
    api.dio.options.baseUrl = originalBase;
  });

  testWidgets('probe product card decode budget at 160 logical pixels, DPR 3', (
    tester,
  ) async {
    final product = ProductModel.fromJson({
      'id': 'fixture-image',
      'name_en': 'Fixture',
      'image': 'assets/images/app_launcher_icon.png',
    });
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844), devicePixelRatio: 3),
          child: Center(
            child: SizedBox(
              width: 160,
              child: BrandProductMedia(product: product),
            ),
          ),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image).first);
    expect(image.image, isA<ResizeImage>());
    probe({
      'scenario': 'card_decode_budget',
      'logical_width': 160,
      'dpr': 3,
      'provider_decode_width': (image.image as ResizeImage).width!,
    });
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('probe Home dependency critical path using virtual delays', (
    tester,
  ) async {
    final homeApi = _HomeApi();
    var done = false;
    final pending = HomeRepository(
      apiClient: homeApi,
    ).getHomeFeed().then((_) => done = true);
    var elapsed = 0;
    while (!done && elapsed < 500) {
      await tester.pump(const Duration(milliseconds: 10));
      elapsed += 10;
    }
    await pending;
    expect(homeApi.calls.length, 2);
    probe({
      'scenario': 'home_dependency',
      'virtual_ms': elapsed,
      'requests': homeApi.calls.length,
      'feed_delay_ms': 100,
      'directory_delay_ms': 150,
    });
  });

  test(
    'probe overlapping identical GET requests through the actual ApiClient',
    () async {
      var requests = 0;
      final release = Completer<void>();
      api.dio.httpClientAdapter = ProbeAdapter((_) async {
        requests++;
        await release.future;
        return probeBody({'count': 0, 'next': null, 'results': []});
      });
      final burst = List.generate(
        20,
        (_) =>
            api.get('products/', queryParameters: {'page': 1, 'page_size': 20}),
      );
      await Future<void>.delayed(Duration.zero);
      release.complete();
      await Future.wait(burst);
      probe({
        'scenario': 'identical_get_burst',
        'callers': 20,
        'adapter_requests': requests,
      });
      expect(requests, greaterThan(0));
    },
  );

  test('probe repeated next-page failures without waiting', () async {
    var failures = 0;
    final page = PagedCollection<int>(
      keyOf: (i) => '$i',
      loader: (number, _) async {
        if (number == 1) {
          return PageItems(List.generate(20, (i) => i), hasMore: true);
        }
        failures++;
        throw const ApiException(
          message: 'Synthetic temporary service failure.',
          statusCode: 503,
        );
      },
    );
    await page.refresh();
    for (var i = 0; i < 10; i++) {
      await page.loadMore();
    }
    probe({
      'scenario': 'failed_scroll_burst',
      'attempts': 10,
      'loader_failures': failures,
      'retained_records': page.items.length,
    });
    expect(page.items.length, 20);
    page.dispose();
  });

  testWidgets('probe real product screen first page with 520 server records', (
    tester,
  ) async {
    var requests = 0, responseBytes = 0;
    api.dio.httpClientAdapter = ProbeAdapter((o) async {
      requests++;
      expect(o.queryParameters['page_size'], 20);
      expect(o.queryParameters['page'], 1);
      final data = {
        'count': 520,
        'next': '?page=2',
        'results': List.generate(
          20,
          (i) => {
            'id': 'fixture-$i',
            'name_en': 'Synthetic skincare $i',
            'name_ar': 'منتج اصطناعي $i',
            'brand_name_en': 'Fixture Brand',
            'description_en': 'Synthetic catalog fixture',
            'status': 'active',
          },
        ),
      };
      responseBytes += utf8.encode(jsonEncode(data)).length;
      return probeBody(data);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: ProductsScreen(repository: ProductsRepository(apiClient: api)),
      ),
    );
    await tester.pumpAndSettle();
    final mountedCards = find.byType(BrandProductMedia).evaluate().length;
    probe({
      'scenario': 'products_first_page',
      'server_records': 520,
      'requested_page_size': 20,
      'adapter_requests': requests,
      'fixture_json_utf8_bytes': responseBytes,
      'mounted_cards': mountedCards,
    });
    expect(requests, 1);
    expect(mountedCards, inExclusiveRange(0, 20));
    await tester.pumpWidget(const SizedBox());
  });
}
