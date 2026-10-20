import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/services/media_upload_service.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/features/admin/data/admin_repository.dart';
import 'package:aesthetic_way/features/admin/models/admin_clinic_model.dart';
import 'package:aesthetic_way/features/articles/models/article_model.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';
import 'products_articles_live_test.dart' show FakeApiClient;

const _signed =
    'https://storage.example/fresh%20image.png?X-Amz-Signature=AbC%2F123&token=a%2Bb&expires=600';
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVR4nGN8ZuT2n4GBgYGJAQoAJKgCYaRJeyUAAAAASUVORK5CYII=',
);

class _Upload implements MediaUploadService {
  String url = _signed;
  final types = <String>[];
  final clinicIds = <String?>[];
  @override
  Future<Map<String, dynamic>> uploadImage({
    required String filePath,
    required String mediaType,
    String? clinicId,
  }) async {
    types.add(mediaType);
    clinicIds.add(clinicId);
    return {'id': 'new-asset', 'url': url};
  }
}

// Real NetworkImage decoding, with deterministic in-memory HTTP responses.
class _Images implements HttpClient {
  final requests = <String>[];
  final Map<String, int> statuses = {};
  final Map<String, Completer<HttpClientResponse>> pending = {};
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    requests.add(url.toString());
    return _Request(
      pending[url.toString()]?.future ??
          Future.value(_Response(statuses[url.toString()] ?? 200)),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Request implements HttpClientRequest {
  _Request(this.response);
  final Future<HttpClientResponse> response;
  @override
  Future<HttpClientResponse> close() => response;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.statusCode);
  @override
  final int statusCode;
  @override
  int get contentLength => _png.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(_png).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ImageProvider _unwrap(ImageProvider image) =>
    image is ResizeImage ? image.imageProvider : image;
Future<void> _decoded(WidgetTester tester) async {
  final image = tester.widget<Image>(find.byType(Image).last);
  await tester.runAsync(() async {
    final done = Completer<void>();
    final stream = image.image.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!done.isCompleted) done.complete();
      },
      onError: (Object e, StackTrace? stack) {
        if (!done.isCompleted) done.completeError(e, stack);
      },
    );
    stream.addListener(listener);
    try {
      await done.future.timeout(const Duration(seconds: 3));
    } finally {
      stream.removeListener(listener);
    }
  });
  await tester.pumpAndSettle();
  expect(tester.widget<RawImage>(find.byType(RawImage).first).image, isNotNull);
}

void main() {
  setUp(() {
    ApiConfig.resetBaseUrl();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });
  tearDown(() {
    ApiConfig.resetBaseUrl();
    debugNetworkImageHttpClientProvider = null;
  });
  final parsers =
      <String, (String, String, String Function(Map<String, dynamic>))>{
        'clinic logo': (
          'logo',
          'logo_url',
          (j) => ClinicModel.fromJson(j).logoUrl,
        ),
        'clinic cover': (
          'cover_image',
          'cover_image_url',
          (j) => ClinicModel.fromJson(j).coverImageUrl,
        ),
        'practitioner': (
          'avatar_url',
          'avatar',
          (j) => PractitionerModel.fromJson(j).avatarUrl,
        ),
        'product': (
          'image_url',
          'image',
          (j) => ProductModel.fromJson(j).imageUrl,
        ),
        'offer': ('image_url', 'image', (j) => OfferModel.fromJson(j).imageUrl),
        'article': (
          'cover_image_url',
          'cover_image',
          (j) => ArticleModel.fromJson(j).coverImageUrl,
        ),
        'treatment': (
          'image_url',
          'image',
          (j) => TreatmentModel.fromJson(j).imageUrl,
        ),
        'admin logo': (
          'logo',
          'logo_url',
          (j) => AdminClinicModel.fromJson(j).logo,
        ),
        'admin cover': (
          'cover_image',
          'cover_image_url',
          (j) => AdminClinicModel.fromJson(j).coverImage,
        ),
      };
  for (final entry in parsers.entries) {
    final (primary, alias, parse) = entry.value;
    test(
      '${entry.key}: blank canonical fields never mask a valid signed alias',
      () {
        for (final empty in [null, '', '   ', false, <String, dynamic>{}]) {
          expect(
            parse({primary: empty, alias: _signed}),
            _signed,
            reason: 'canonical=$empty',
          );
        }
      },
    );
    test(
      '${entry.key}: nonempty canonical URL takes precedence over old fallback',
      () {
        expect(
          parse({
            primary: _signed,
            alias: 'https://storage.example/old.png',
            'clinic': {'logo': 'https://storage.example/logo.png'},
          }),
          _signed,
        );
      },
    );
  }
  test(
    'nested clinic and article author empty aliases do not hide their images',
    () {
      final j = <String, dynamic>{
        'clinic': {'logo': ' ', 'logo_url': _signed},
        'author_practitioner': {'avatar_url': '', 'avatar': _signed},
      };
      expect(ProductModel.fromJson(j).clinicLogoUrl, _signed);
      expect(OfferModel.fromJson(j).clinicLogoUrl, _signed);
      expect(PractitionerModel.fromJson(j).clinicLogoUrl, _signed);
      expect(TreatmentModel.fromJson(j).clinicLogoUrl, _signed);
      expect(ArticleModel.fromJson(j).clinicLogoUrl, _signed);
      expect(ArticleModel.fromJson(j).authorDoctorAvatar, _signed);
      expect(
        ProductModel.fromJson({
          'clinic': 'clinic-uuid',
          'image_url': _signed,
        }).imageUrl,
        _signed,
      );
      expect(
        ArticleModel.fromJson({
          'clinic': 'clinic-uuid',
          'cover_image_url': _signed,
        }).coverImageUrl,
        _signed,
      );
    },
  );
  test('absent entity photos stay empty instead of becoming clinic logos', () {
    final j = <String, dynamic>{
      'clinic': {'logo': _signed},
    };
    expect(OfferModel.fromJson(j).imageUrl, '');
    expect(TreatmentModel.fromJson(j).imageUrl, '');
    expect(ProductModel.fromJson(j).imageUrl, '');
    expect(ArticleModel.fromJson(j).coverImageUrl, '');
    expect(PractitionerModel.fromJson(j).avatarUrl, '');
  });
  test(
    'relative media uses the actual configured host and preserves signed queries',
    () {
      ApiConfig.setBaseUrl('http://192.168.1.9:8000/api/v1/');
      for (final path in [
        '/media/catalog/image.png?sig=a%2Bb',
        'media/catalog/image.png?sig=a%2Bb',
        'catalog/image.png?sig=a%2Bb',
      ]) {
        expect(
          resolveNetworkImageUrl(path),
          'http://192.168.1.9:8000/media/catalog/image.png?sig=a%2Bb',
        );
      }
      expect(
        resolveNetworkImageUrl('//cdn.example/image.png?sig=a%2Bb'),
        'http://cdn.example/image.png?sig=a%2Bb',
      );
      expect(ApiConfig.firstMediaUrl(['', _signed]), _signed);
      expect(
        ClinicModel.fromJson({
          'gallery_images': [
            '',
            null,
            {'url': 'bad'},
            _signed,
          ],
        }).galleryImages,
        [_signed],
      );
    },
  );

  for (final circular in [false, true]) {
    testWidgets(
      '${circular ? 'avatar' : 'image'} decodes valid HTTP image instead of its fallback',
      (tester) async {
        final client = _Images();
        debugNetworkImageHttpClientProvider = () => client;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: circular
                  ? const LuxuryAvatar(
                      imageUrl: _signed,
                      fallbackLogoUrl: 'https://storage.example/logo.png',
                    )
                  : const LuxuryImage(
                      imageUrl: _signed,
                      fallbackLogoUrl: 'https://storage.example/logo.png',
                      width: 80,
                      height: 80,
                      customPlaceholder: Icon(
                        Icons.error,
                        key: Key('fallback'),
                      ),
                    ),
            ),
          ),
        );
        await _decoded(tester);
        expect(client.requests, [_signed]);
        expect(
          _unwrap(tester.widget<Image>(find.byType(Image)).image),
          isA<NetworkImage>(),
        );
        expect(find.byKey(const Key('fallback')), findsNothing);
        expect(tester.takeException(), isNull);
        debugNetworkImageHttpClientProvider = null;
      },
    );
  }
  testWidgets(
    'pending request shows no fallback; a replacement recovers after load error',
    (tester) async {
      final client = _Images();
      debugNetworkImageHttpClientProvider = () => client;
      const first = 'https://storage.example/pending.png';
      client.pending[first] = Completer<HttpClientResponse>();
      Future<void> mount(String url) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LuxuryImage(
              imageUrl: url,
              width: 80,
              height: 80,
              customPlaceholder: const Icon(Icons.error, key: Key('fallback')),
            ),
          ),
        ),
      );
      await mount(first);
      await tester.pump();
      expect(find.byKey(const Key('fallback')), findsNothing);
      client.pending[first]!.complete(_Response(404));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fallback')), findsOneWidget);
      await mount(_signed);
      await _decoded(tester);
      expect(find.byKey(const Key('fallback')), findsNothing);
      expect(tester.takeException(), isNull);
      debugNetworkImageHttpClientProvider = null;
    },
  );
  testWidgets(
    'network failure tries clinic logo; identical failed logo is not retried',
    (tester) async {
      final client = _Images();
      debugNetworkImageHttpClientProvider = () => client;
      const failed = 'https://storage.example/failed.png';
      client.statuses[failed] = 404;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LuxuryImage(
              imageUrl: failed,
              fallbackLogoUrl: _signed,
              width: 80,
              height: 80,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _decoded(tester);
      expect(client.requests, [failed, _signed]);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LuxuryImage(
              imageUrl: failed,
              fallbackLogoUrl: failed,
              width: 80,
              height: 80,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final provider = _unwrap(
        tester.widget<Image>(find.byType(Image).last).image,
      );
      expect(provider, isA<AssetImage>());
      expect(
        client.requests.where((u) => u == failed).length,
        lessThanOrEqualTo(2),
      );
      expect(tester.takeException(), isNull);
      debugNetworkImageHttpClientProvider = null;
    },
  );
  test(
    'absolute Windows drive and UNC paths resolve as files rather than URI schemes',
    () {
      for (final source in [
        r'C:\Users\tester\AppData\Local\Temp\picked image.png',
        'C:/Users/tester/AppData/Local/Temp/picked image.png',
        r'z:\clinic\logo.png',
        r'\\server\share\clinic logo.png',
        r'\\?\C:\clinic\logo.png',
      ]) {
        // Classification runs on every host; decoding a real native file is
        // covered separately below, without pretending Linux can read C:\.
        final provider = resolveImageProvider(source);
        expect(provider, isA<FileImage>(), reason: 'Source: $source');
        expect((provider! as FileImage).file.path, source);
      }
    },
  );

  test('HTTP URLs and unsupported URI schemes are not Windows files', () {
    for (final url in [
      'https://storage.example/C:/clinic/logo.png?token=signed',
      'http://localhost:8000/media/clinic.png',
    ]) {
      final provider = resolveImageProvider(url);
      expect(provider, isA<NetworkImage>());
      expect((provider! as NetworkImage).url, url);
    }
    expect(resolveImageProvider('C:relative.png'), isNull);
    expect(resolveImageProvider('content://media/external/images/123'), isNull);
  });

  testWidgets(
    'native files, file URIs and bundled assets render as primary images',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      final dir = Directory.systemTemp.createTempSync('aw-image-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File.fromUri(dir.uri.resolve('picked image %23.png'))
        ..writeAsBytesSync(_png);
      for (final (kind, source) in [
        ('native file path', file.path),
        ('file URI', file.uri.toString()),
        ('bundled asset', 'assets/images/app_launcher_icon.png'),
      ]) {
        final primary = resolveImageProvider(source);
        expect(primary, isNotNull, reason: '$kind: $source');
        expect(
          primary,
          kind == 'bundled asset' ? isA<AssetImage>() : isA<FileImage>(),
          reason: '$kind: $source',
        );
        await tester.runAsync(() async {
          final provider = ResizeImage.resizeIfNeeded(100, null, primary!);
          final stream = provider.resolve(ImageConfiguration.empty);
          final done = Completer<void>();
          final listener = ImageStreamListener(
            (_, _) {
              if (!done.isCompleted) done.complete();
            },
            onError: (Object e, StackTrace? stack) {
              if (!done.isCompleted) done.completeError(e, stack);
            },
          );
          stream.addListener(listener);
          try {
            await done.future.timeout(const Duration(seconds: 3));
          } finally {
            stream.removeListener(listener);
          }
        });
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LuxuryImage(
                imageUrl: source,
                width: 80,
                height: 80,
                customPlaceholder: const Icon(
                  Icons.error,
                  key: Key('fallback'),
                ),
              ),
            ),
          ),
        );
        await _decoded(tester);
        final provider = _unwrap(
          tester.widget<Image>(find.byType(Image)).image,
        );
        expect(
          provider,
          source.startsWith('assets/') ? isA<AssetImage>() : isA<FileImage>(),
        );
        expect(find.byKey(const Key('fallback')), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

  test(
    'every catalog upload sends fresh URL and asset UUID; removal clears both',
    () async {
      final upload = _Upload();
      final bodies = <Map<String, dynamic>>[];
      final api = FakeApiClient(
        onGet: (_, _) => {},
        onPost: (_, data) {
          final b = Map<String, dynamic>.from(data as Map);
          bodies.add(b);
          return {'id': 'new', ...b};
        },
        onPatch: (_, data) {
          final b = Map<String, dynamic>.from(data as Map);
          bodies.add(b);
          return {'id': 'new', ...b};
        },
      );
      final repo = ClinicCatalogRepository(
        apiClient: api,
        mediaUploadService: upload,
      );
      await repo.createPractitioner({
        'avatar': '/picked/p.png',
        'media_asset': 'old',
      });
      await repo.createOffer({'image': '/picked/o.png', 'media_asset': 'old'});
      await repo.createProduct({
        'image': '/picked/b.png',
        'media_asset': 'old',
      });
      await repo.createArticle({
        'cover_image': '/picked/a.png',
        'media_asset': 'old',
      });
      for (final body in bodies) {
        expect(body['media_asset'], 'new-asset');
        expect(body.values, contains(_signed));
      }
      expect(upload.types, [
        'practitioner_avatar',
        'offer_image',
        'product_image',
        'article_cover',
      ]);
      await repo.updatePractitioner('p', {'avatar': null});
      await repo.updateOffer('o', {'image': null});
      await repo.updateProduct('b', {'image': null});
      await repo.updateArticle('a', {'cover_image': null});
      for (final body in bodies.skip(4)) {
        expect(body['media_asset'], isNull);
        expect(body.values.every((v) => v == null), isTrue);
      }
    },
  );
  test(
    'relative upload response and whitespace URL preserve valid catalog images',
    () async {
      final upload = _Upload()..url = '/media/fresh.png?sig=a%2Bb';
      Map<String, dynamic>? body;
      final api = FakeApiClient(
        onGet: (_, _) => {},
        onPatch: (_, data) {
          body = Map<String, dynamic>.from(data as Map);
          return {'id': 'p', ...body!};
        },
      );
      final repo = ClinicCatalogRepository(
        apiClient: api,
        mediaUploadService: upload,
      );
      final product = await repo.updateProduct('p', {
        'image': '/picked/new.png',
      });
      expect(
        body!['image'],
        'https://aestheticway.ae/media/fresh.png?sig=a%2Bb',
      );
      expect(product.imageUrl, body!['image']);
      await repo.updateProduct('p', {'image': '  $_signed  '});
      expect(body!['image'], _signed);
      expect(upload.types.length, 1);
    },
  );
  test(
    'admin mixed replace/remove uses the injected uploader and target clinic',
    () async {
      final dir = Directory.systemTemp.createTempSync('aw-admin-image-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/logo.png')..writeAsBytesSync(_png);
      final upload = _Upload();
      Map<String, dynamic>? body;
      final api = FakeApiClient(
        onGet: (_, _) => {},
        onPatch: (_, data) {
          body = Map<String, dynamic>.from(data as Map);
          return {'id': 'clinic-a', ...body!};
        },
      );
      final admin = AdminRepository(apiClient: api, mediaUploadService: upload);
      final clinic = await admin.updateClinic('clinic-a', {
        'logo': file.path,
        'cover_image': null,
      });
      expect(body, {'logo': _signed, 'cover_image': null});
      expect(clinic.logo, _signed);
      expect(upload.clinicIds, ['clinic-a']);
    },
  );
  test(
    'admin direct uploads remain multipart and remote URLs are not stripped',
    () async {
      final dir = Directory.systemTemp.createTempSync('aw-admin-multipart-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/logo.png')..writeAsBytesSync(_png);
      dynamic body;
      final api = FakeApiClient(
        onGet: (_, _) => {},
        onPatch: (_, data) {
          body = data;
          return {'id': 'clinic-a'};
        },
      );
      final admin = AdminRepository(apiClient: api);
      await admin.updateClinic('clinic-a', {
        'logo': file.path,
        'cover_image': _signed,
      });
      expect(body, isA<FormData>());
      expect((body as FormData).files.single.key, 'logo');
      expect(
        Map<String, String>.fromEntries(
          (body as FormData).fields,
        )['cover_image'],
        _signed,
      );
      await admin.updateClinic('clinic-a', {'logo': _signed});
      expect(body, {'logo': _signed});
    },
  );
}
