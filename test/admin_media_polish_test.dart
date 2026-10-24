import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/clinic_portal/services/showcase_video_change.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_clinic_reviews_screen.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/portal_media_frame.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_media_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'onboarding_review_workflows_test.dart' as f;
import 'clinic_media_contract_test.dart'
    show Gallery, Picker, ShortVideoPlatform, finishNativeWork;
import 'support/patient_visual_harness.dart';
import 'support/settle_preview_images.dart';

const imageUrl =
    'https://fixture.invalid/media/genuine.png?signature=disposable';
final pixels = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVR4nGN8ZuT2n4GBgYGJAQoAJKgCYaRJeyUAAAAASUVORK5CYII=',
);

class Wire extends f.Adapter {
  Wire(super.reply);
  final sent = <List<int>>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    final bytes = BytesBuilder();
    if (stream != null) {
      await for (final chunk in stream) {
        bytes.add(chunk);
      }
    }
    sent.add(bytes.takeBytes());
    return super.fetch(o, null, cancel);
  }
}

class Images implements HttpClient {
  int requests = 0, status = 200;
  List<int> bytes = pixels;
  Completer<HttpClientResponse>? pending;
  @override
  Future<HttpClientRequest> getUrl(Uri uri) async {
    requests++;
    return ImageRequest(
      pending?.future ?? Future.value(ImageResponse(status, bytes)),
    );
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class ImageRequest implements HttpClientRequest {
  ImageRequest(this.response);
  final Future<HttpClientResponse> response;
  @override
  Future<HttpClientResponse> close() => response;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class ImageResponse extends Stream<List<int>> implements HttpClientResponse {
  ImageResponse(this.statusCode, this.data);
  final List<int> data;
  @override
  final int statusCode;
  @override
  int get contentLength => data.length;
  @override
  HttpHeaders get headers => ImageHeaders();
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(data).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class ImageHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class ObservedPicker extends Picker {
  int videoCalls = 0;
  @override
  Future<XFile?> getVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) {
    videoCalls++;
    return super.getVideo(
      source: source,
      preferredCameraDevice: preferredCameraDevice,
      maxDuration: maxDuration,
    );
  }
}

class InvalidDuration extends ShortVideoPlatform {
  InvalidDuration(this.seconds);
  final int seconds;
  @override
  void initialize(int id) => streams[id]!.add(
    VideoEvent(
      eventType: VideoEventType.initialized,
      size: const Size(64, 64),
      duration: Duration(seconds: seconds),
    ),
  );
}

class CodecFailure extends ShortVideoPlatform {
  @override
  void initialize(int id) => streams[id]!.addError(
    PlatformException(
      code: 'codec_error',
      message: 'Disposable decoder fixture',
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  final api = ApiClient(), service = ClinicPortalService();
  late HttpClientAdapter original;
  late Wire wire;
  late ObservedPicker picker;
  late ImagePickerPlatform oldPicker;
  late VideoPlayerPlatform oldVideo;
  late ShortVideoPlatform video;
  String? privateTier, publicTier, saved;
  String accountState = 'active', setupState = 'approved';
  int? failure;
  bool offline = false;
  Map<String, dynamic> profile() => {
    ...f.clinic(status: setupState),
    'status': accountState,
    'subscription_tier': ?privateTier,
    'cover_image': File(
      'test/fixtures/media/fragrance_photo.jpg',
    ).absolute.uri.toString(),
    'video_ad_file': saved,
  }..removeWhere((key, _) => key == 'subscription_tier' && privateTier == null);
  void use(FutureOr<ResponseBody> Function(RequestOptions) reply) {
    wire = Wire(reply);
    api.dio.httpClientAdapter = wire;
  }

  void canonical() => use((o) {
    if (o.path == ApiConfig.clinicProfile && o.method == 'PATCH') {
      if (offline) {
        throw DioException(
          requestOptions: o,
          type: DioExceptionType.connectionError,
        );
      }
      if (failure != null) {
        return f.body({
          'video_ad_file': ['Only VIP tier clinics can upload a video ad.'],
        }, failure!);
      }
      saved = o.data is FormData
          ? 'https://fixture.invalid/media/saved.mp4'
          : null;
    }
    if (o.path == ApiConfig.clinicProfile) return f.body(profile());
    if (o.path == ApiConfig.clinicDetail(f.id)) {
      return f.body({'id': f.id, 'subscription_tier': publicTier});
    }
    return f.body(f.page([]));
  });
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    AuthState().login(
      name: 'Disposable QA',
      phone: 'fixture-clinic',
      role: 'clinic_admin',
    );
    original = api.dio.httpClientAdapter;
    api.updateBaseUrl('https://fixture.invalid/api/v1/');
    accountState = 'active';
    setupState = 'approved';
    privateTier = null;
    publicTier = 'vip';
    saved = null;
    failure = null;
    offline = false;
    canonical();
    service.resetTestingState();
    service.setCatalogRepositoryForTesting(
      ClinicCatalogRepository(apiClient: api),
    );
    service.setActiveClinicForTesting(
      ClinicModel.fromJson({'id': f.id, 'subscription_tier': 'basic'}),
    );
    oldPicker = ImagePickerPlatform.instance;
    picker = ObservedPicker();
    ImagePickerPlatform.instance = picker;
    oldVideo = VideoPlayerPlatform.instance;
    video = ShortVideoPlatform();
    VideoPlayerPlatform.instance = video;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });
  tearDown(() async {
    api.dio.httpClientAdapter = original;
    api.updateBaseUrl(ApiConfig.defaultProductionBaseUrl);
    ApiConfig.resetBaseUrl();
    ImagePickerPlatform.instance = oldPicker;
    VideoPlayerPlatform.instance = oldVideo;
    for (final stream in video.streams.values) {
      await stream.close();
    }
    debugNetworkImageHttpClientProvider = null;
    service.resetTestingState();
    AuthState().logout();
    await TokenStorage().clear();
  });

  for (final input in [
    null,
    '',
    'future_tier',
    'VIP ',
    'vip_platinum',
    'featured',
    'basic',
  ]) {
    test(
      'tier parsing distinguishes unknown from a confirmed entitlement: $input',
      () {
        final model = ClinicModel.fromJson({'subscription_tier': input});
        expect(
          model.subscriptionTierKnown,
          ['VIP ', 'vip_platinum', 'featured', 'basic'].contains(input),
        );
        expect(
          model.subscriptionTier == SubscriptionTier.vipPlatinum,
          ['VIP ', 'vip_platinum'].contains(input),
        );
      },
    );
  }
  test(
    'omitted private tier joins only current same-UUID read-only tier and preserves private media',
    () async {
      final result = await ClinicCatalogRepository(
        apiClient: api,
      ).getClinicProfile();
      expect(result.subscriptionTier, SubscriptionTier.vipPlatinum);
      expect(result.subscriptionTierKnown, isTrue);
      expect(result.coverImageUrl, profile()['cover_image']);
      expect(wire.requests.map((r) => r.path), [
        ApiConfig.clinicProfile,
        ApiConfig.clinicDetail(f.id),
      ]);
      expect(wire.requests.every((r) => r.method == 'GET'), isTrue);
    },
  );
  for (final tier in ['featured', 'basic', 'unknown']) {
    test(
      'reported private $tier cannot be overridden by a public VIP label',
      () async {
        privateTier = tier;
        final result = await ClinicCatalogRepository(
          apiClient: api,
        ).getClinicProfile();
        expect(
          result.subscriptionTier == SubscriptionTier.vipPlatinum,
          isFalse,
        );
        expect(wire.requests, hasLength(1));
      },
    );
  }
  test(
    'foreign UUID and unavailable public detail remain unknown without denying the private profile',
    () async {
      use(
        (o) => o.path == ApiConfig.clinicProfile
            ? f.body(profile())
            : f.body({'id': f.proposalId, 'subscription_tier': 'vip'}),
      );
      expect(
        (await ClinicCatalogRepository(
          apiClient: api,
        ).getClinicProfile()).subscriptionTierKnown,
        isFalse,
      );
      use(
        (o) => o.path == ApiConfig.clinicProfile
            ? f.body(profile())
            : f.body({}, 404),
      );
      expect(
        (await ClinicCatalogRepository(
          apiClient: api,
        ).getClinicProfile()).subscriptionTierKnown,
        isFalse,
      );
    },
  );
  test(
    'session switch during tier resolution never accepts the old profile',
    () async {
      final waiting = Completer<ResponseBody>(), entered = Completer<void>();
      use((o) {
        if (o.path == ApiConfig.clinicProfile) return f.body(profile());
        entered.complete();
        return waiting.future;
      });
      final pending = ClinicCatalogRepository(
        apiClient: api,
      ).getClinicProfile();
      final assertion = expectLater(pending, throwsA(anything));
      await entered.future;
      AuthState().logout();
      waiting.complete(f.body({'id': f.id, 'subscription_tier': 'vip'}));
      await assertion;
    },
  );
  test(
    'actual multipart contains MP4 bytes and no editable tier, poster or MediaAsset fields',
    () async {
      final file = File(
        'test/fixtures/clinic_media/short_showcase.mp4',
      ).absolute;
      final result = await ClinicCatalogRepository(
        apiClient: api,
      ).updateClinicProfile({'video_ad_file': file.path});
      expect(result.videoUrl, saved);
      final index = wire.requests.indexWhere((o) => o.method == 'PATCH');
      final request = wire.requests[index];
      expect(request.data, isA<FormData>());
      expect((request.data as FormData).files.single.key, 'video_ad_file');
      expect((request.data as FormData).fields, isEmpty);
      expect(latin1.decode(wire.sent[index]), contains('ftyp'));
      expect(request.contentType, startsWith('multipart/form-data; boundary='));
    },
  );

  Future<void> openMedia(WidgetTester tester) async {
    await f.render(tester, ClinicMediaScreen(repository: Gallery()));
    await tester.scrollUntilVisible(find.text('Select gallery video'), 200);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'stale Basic refreshes to genuinely reported VIP and picker cancellation sends no write',
    (tester) async {
      await openMedia(tester);
      expect(
        service.activeClinic.subscriptionTier,
        SubscriptionTier.vipPlatinum,
      );
      final button = find.ancestor(
        of: find.text('Select gallery video'),
        matching: find.byType(TextButton),
      );
      expect(tester.widget<TextButton>(button).onPressed, isNotNull);
      await tester.tap(find.text('Select gallery video'));
      await tester.pumpAndSettle();
      expect(wire.requests.where((r) => r.method == 'PATCH'), isEmpty);
      expect(find.text('Upload and save video'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  for (final tier in ['basic', 'featured', 'future_tier']) {
    testWidgets('fresh private $tier does not retain a stale VIP grant', (
      tester,
    ) async {
      privateTier = tier;
      service.setActiveClinicForTesting(
        ClinicModel.fromJson({'id': f.id, 'subscription_tier': 'vip'}),
      );
      await openMedia(tester);
      final button = find.ancestor(
        of: find.text('Select gallery video'),
        matching: find.byType(OutlinedButton),
      );
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
      expect(wire.requests.where((r) => r.method == 'PATCH'), isEmpty);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    });
  }
  for (final rejected in [400, 403, -1, 0, 200]) {
    testWidgets(
      'native video real-file submission retains truthful state and safe retry: $rejected',
      (tester) async {
        failure = rejected > 0 ? rejected : null;
        offline = rejected == -1;
        picker.video = File(
          'test/fixtures/clinic_media/short_showcase.mp4',
        ).absolute.path;
        await openMedia(tester);
        await tester.tap(find.text('Select gallery video'));
        await finishNativeWork(tester, () => video.probed.isCompleted);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Upload and save video'),
          150,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Upload and save video'));
        await finishNativeWork(
          tester,
          () => wire.requests.any((r) => r.method == 'PATCH'),
        );
        await tester.pumpAndSettle();
        if (rejected == 0) {
          expect(
            service.activeClinic.videoUrl,
            'https://fixture.invalid/media/saved.mp4',
          );
          expect(find.text('Upload and save video'), findsNothing);
          await tester.scrollUntilVisible(
            find.text('Saved video change verified.'),
            -250,
          );
          await tester.pumpAndSettle();
          expect(find.text('Saved video change verified.'), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          await openMedia(tester);
          expect(service.activeClinic.videoUrl, saved);
          expect(find.text('Remove saved video'), findsOneWidget);
        } else {
          expect(find.text('Upload and save video'), findsOneWidget);
          expect(find.text('Saved video change verified.'), findsNothing);
          expect(saved, isNull);
          failure = null;
          offline = false;
          if (rejected == -1 || rejected == 200) {
            final writes = wire.requests
                .where((r) => r.method == 'PATCH')
                .length;
            await tester.ensureVisible(find.text('Check saved video'));
            await tester.tap(find.text('Check saved video'));
            await tester.pumpAndSettle();
            expect(
              wire.requests.where((r) => r.method == 'PATCH').length,
              writes,
            );
          }
          await tester.ensureVisible(find.text('Upload and save video'));
          await tester.tap(find.text('Upload and save video'));
          await finishNativeWork(
            tester,
            () => service.activeClinic.videoUrl != null,
          );
          await tester.pumpAndSettle();
          expect(service.activeClinic.videoUrl, saved);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
      },
    );
  }
  for (final codec in [false, true]) {
    testWidgets(
      'invalid native video/codec error is not uploaded codec=$codec',
      (tester) async {
        if (codec) {
          video = CodecFailure();
          VideoPlayerPlatform.instance = video;
        }
        picker.video = File(
          codec
              ? 'test/fixtures/clinic_media/short_showcase.mp4'
              : 'test/fixtures/media/portrait_photo.png',
        ).absolute.path;
        await openMedia(tester);
        await tester.tap(find.text('Select gallery video'));
        await finishNativeWork(
          tester,
          () =>
              picker.videoCalls > 0 &&
              find.text('Processing media…').evaluate().isEmpty,
        );
        await tester.pumpAndSettle();
        expect(find.text('Upload and save video'), findsNothing);
        expect(wire.requests.where((r) => r.method == 'PATCH'), isEmpty);
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
      },
    );
  }
  testWidgets(
    'expired session removes media controls and cannot use previous VIP state',
    (tester) async {
      await openMedia(tester);
      AuthState().logout();
      await tester.pumpAndSettle();
      expect(find.text('Select gallery video'), findsNothing);
      expect(wire.requests.where((r) => r.method == 'PATCH'), isEmpty);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'pending real network frame has a bounded skeleton and renders actual decoded pixels when ready',
    (tester) async {
      final client = Images()..pending = Completer<HttpClientResponse>();
      debugNetworkImageHttpClientProvider = () => client;
      await f.render(
        tester,
        const Scaffold(body: PortalMediaFrame(imageUrl: imageUrl)),
      );
      expect(find.text('Loading image…'), findsOneWidget);
      final size = tester.getSize(find.byType(PortalMediaFrame));
      expect(size.width / size.height, closeTo(16 / 9, .01));
      await tester.runAsync(() async {
        client.pending!.complete(ImageResponse(200, pixels));
      });
      client.pending = null;
      await tester.pump();
      await settlePreviewImages(tester);
      expect(find.text('Loading image…'), findsNothing);
      expect(
        tester.widget<RawImage>(find.byType(RawImage).first).image,
        isNotNull,
      );
      debugNetworkImageHttpClientProvider = null;
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  for (final bad in ['expired', 'corrupt', 'html']) {
    testWidgets(
      'genuine decode/network failure has a branded bounded retry panel: $bad',
      (tester) async {
        final client = Images();
        if (bad == 'expired') client.status = 403;
        if (bad == 'corrupt') client.bytes = [0, 1, 2];
        if (bad == 'html') {
          client.bytes = utf8.encode('<html>Not an image</html>');
        }
        debugNetworkImageHttpClientProvider = () => client;
        await f.render(
          tester,
          const Scaffold(body: PortalMediaFrame(imageUrl: imageUrl)),
        );
        await finishNativeWork(
          tester,
          () => find.text('Image unavailable').evaluate().isNotEmpty,
        );
        expect(find.text('Retry'), findsOneWidget);
        expect(
          tester.getSize(find.byType(PortalMediaFrame)).height,
          lessThan(250),
        );
        client.status = 200;
        client.bytes = pixels;
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        await settlePreviewImages(tester);
        expect(find.text('Image unavailable'), findsNothing);
        expect(
          tester.widget<RawImage>(find.byType(RawImage).first).image,
          isNotNull,
        );
        debugNetworkImageHttpClientProvider = null;
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
      },
    );
  }
  testWidgets(
    'logo is a contained square and fullscreen shows original proportions without cropping',
    (tester) async {
      final file = File('test/fixtures/media/fragrance_photo.jpg').absolute;
      await f.render(
        tester,
        Scaffold(
          body: PortalMediaFrame(
            imageUrl: file.uri.toString(),
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            expandable: true,
          ),
        ),
      );
      await settlePreviewImages(tester);
      expect(tester.getSize(find.byType(PortalMediaFrame)), const Size(80, 80));
      expect(
        tester.widget<LuxuryImage>(find.byType(LuxuryImage)).fit,
        BoxFit.contain,
      );
      await tester.tap(find.byType(PortalMediaFrame).first);
      await tester.pumpAndSettle();
      await settlePreviewImages(tester);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(
        tester.widget<LuxuryImage>(find.byType(LuxuryImage).last).fit,
        BoxFit.contain,
      );
      expect(
        tester.widget<RawImage>(find.byType(RawImage).last).image,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'missing tier can recover through a fresh private response without assuming public visibility',
    (tester) async {
      var privateNowReports = false;
      use((o) {
        if (o.path == ApiConfig.clinicProfile) {
          return f.body({
            ...profile(),
            if (privateNowReports) 'subscription_tier': 'vip',
          });
        }
        return f.body({}, 404);
      });
      await openMedia(tester);
      expect(find.textContaining('did not establish'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.ancestor(
                of: find.text('Select gallery video'),
                matching: find.byType(OutlinedButton),
              ),
            )
            .onPressed,
        isNull,
      );
      privateNowReports = true;
      await tester.tap(find.text('Verify video entitlement'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Select gallery video'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(
              find.ancestor(
                of: find.text('Select gallery video'),
                matching: find.byType(TextButton),
              ),
            )
            .onPressed,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'failed current profile verification has a recoverable state and no stale VIP write',
    (tester) async {
      var unavailable = true;
      use((o) {
        if (unavailable) {
          throw DioException(
            requestOptions: o,
            type: DioExceptionType.connectionError,
          );
        }
        if (o.path == ApiConfig.clinicProfile) {
          return f.body({...profile(), 'subscription_tier': 'vip'});
        }
        return f.body(f.page([]));
      });
      await f.render(tester, ClinicMediaScreen(repository: Gallery()));
      expect(find.text('Retry profile verification'), findsOneWidget);
      expect(wire.requests.where((r) => r.method == 'PATCH'), isEmpty);
      unavailable = false;
      await tester.tap(find.text('Retry profile verification'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Select gallery video'), 200);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(
              find.ancestor(
                of: find.text('Select gallery video'),
                matching: find.byType(TextButton),
              ),
            )
            .onPressed,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'permission is rechecked before native selection after a server downgrade',
    (tester) async {
      await openMedia(tester);
      privateTier = 'basic';
      await tester.tap(find.text('Select gallery video'));
      await tester.pumpAndSettle();
      expect(picker.videoCalls, 0);
      expect(service.activeClinic.subscriptionTier, SubscriptionTier.basic);
      expect(wire.requests.where((r) => r.method == 'PATCH'), isEmpty);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets('oversized video is rejected before native decoding or upload', (
    tester,
  ) async {
    final file = (await tester.runAsync(() async {
      final folder = await Directory.systemTemp.createTemp('aw-video-size-');
      final file = File('${folder.path}/oversize.mp4');
      final handle = await file.open(mode: FileMode.write);
      await handle.truncate(26 * 1024 * 1024);
      await handle.close();
      return file;
    }))!;
    addTearDown(() => file.parent.deleteSync(recursive: true));
    picker.video = file.path;
    await openMedia(tester);
    await tester.tap(find.text('Select gallery video'));
    await finishNativeWork(
      tester,
      () =>
          picker.videoCalls > 0 &&
          find.text('Processing media…').evaluate().isEmpty,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('no larger than 25 MB'), findsOneWidget);
    expect(video.created, 0);
    expect(wire.requests.where((r) => r.method == 'PATCH'), isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      testWidgets(
        '320dp admin review at 180 percent text scale dark=$dark ar=$ar',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 1000);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          AuthState().login(name: 'QA', phone: 'admin', role: 'super_admin');
          use((_) => f.body({...profile(), 'setup_status': 'submitted'}));
          await f.render(
            tester,
            const MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.8)),
              child: AdminClinicReviewDetail(clinicId: f.id),
            ),
            width: 320,
            dark: dark,
            ar: ar,
          );
          await settlePreviewImages(tester);
          await f.capture(
            tester,
            'polish_review_scaled_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('approve-clinic-profile')),
            250,
            scrollable: find
                .descendant(
                  of: find.byType(ListView),
                  matching: find.byType(Scrollable),
                )
                .first,
            maxScrolls: 70,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.binding.setSurfaceSize(null);
        },
      );
      testWidgets(
        '320dp failed media at 180 percent has bounded accessible retry dark=$dark ar=$ar',
        (tester) async {
          final client = Images()..status = 403;
          debugNetworkImageHttpClientProvider = () => client;
          await f.render(
            tester,
            const MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.8)),
              child: Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [PortalMediaFrame(imageUrl: imageUrl)],
                  ),
                ),
              ),
            ),
            width: 320,
            dark: dark,
            ar: ar,
          );
          await finishNativeWork(
            tester,
            () => find
                .text(ar ? 'تعذر تحميل الصورة' : 'Image unavailable')
                .evaluate()
                .isNotEmpty,
          );
          await f.capture(
            tester,
            'polish_gallery_error_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          expect(
            tester.getSize(find.byType(PortalMediaFrame)).height,
            lessThan(200),
          );
          expect(find.text(ar ? 'إعادة التحميل' : 'Retry'), findsOneWidget);
          expect(tester.takeException(), isNull);
          debugNetworkImageHttpClientProvider = null;
          await tester.pumpWidget(const SizedBox());
          await tester.binding.setSurfaceSize(null);
        },
      );
    }
  }
  for (final seconds in [0, 16]) {
    testWidgets(
      'invalid decoded video duration is not queued or uploaded: $seconds',
      (tester) async {
        video = InvalidDuration(seconds);
        VideoPlayerPlatform.instance = video;
        picker.video = File(
          'test/fixtures/clinic_media/short_showcase.mp4',
        ).absolute.path;
        await openMedia(tester);
        await tester.tap(find.text('Select gallery video'));
        await finishNativeWork(
          tester,
          () =>
              picker.videoCalls > 0 &&
              find.text('Processing media…').evaluate().isEmpty,
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('up to 15 seconds'), findsOneWidget);
        expect(find.text('Upload selected video'), findsNothing);
        expect(wire.requests.where((r) => r.method == 'PATCH'), isEmpty);
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
      },
    );
  }

  testWidgets('48px thumbnail loading and real HTTP failure never overflow', (
    tester,
  ) async {
    final client = Images()..pending = Completer<HttpClientResponse>();
    debugNetworkImageHttpClientProvider = () => client;
    await f.render(
      tester,
      const Scaffold(
        body: PortalMediaFrame(imageUrl: imageUrl, width: 48, height: 48),
      ),
    );
    expect(tester.getSize(find.byType(PortalMediaFrame)), const Size(48, 48));
    expect(find.byTooltip('Retry image'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      client.pending!.complete(ImageResponse(403, []));
    });
    await finishNativeWork(
      tester,
      () => find
          .byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == 'Image unavailable',
          )
          .evaluate()
          .isNotEmpty,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Retry image'), findsOneWidget);
    debugNetworkImageHttpClientProvider = null;
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  for (final setup in ['draft', 'submitted', 'rejected']) {
    testWidgets(
      '09f49bb unpublished private VIP full video journey and cold service restart: $setup',
      (tester) async {
        accountState = 'pending';
        setupState = setup;
        privateTier = 'vip';
        publicTier = null;
        picker.video = File(
          'test/fixtures/clinic_media/short_showcase.mp4',
        ).absolute.path;
        await openMedia(tester);
        expect(service.activeClinic.subscriptionTierKnown, isTrue);
        expect(
          wire.requests.where((r) => r.path == ApiConfig.clinicDetail(f.id)),
          isEmpty,
        );
        await tester.tap(find.text('Select gallery video'));
        await finishNativeWork(tester, () => video.probed.isCompleted);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Upload and save video'),
          150,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Upload and save video'));
        await finishNativeWork(tester, () => saved != null);
        await tester.pumpAndSettle();
        expect(service.activeClinic.videoUrl, saved);
        expect(
          wire.sent.any((bytes) => latin1.decode(bytes).contains('ftyp')),
          isTrue,
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        // Cold in-memory service: retain only the independently acknowledged server fixture.
        service.resetTestingState();
        service.setCatalogRepositoryForTesting(
          ClinicCatalogRepository(apiClient: api),
        );
        await openMedia(tester);
        expect(service.activeClinic.videoUrl, saved);
        await settlePreviewImages(tester);
        await f.capture(tester, 'backend09_vip_cold_$setup');
        await tester.ensureVisible(find.text('Preview video'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Preview video'));
        await finishNativeWork(tester, () => video.created >= 2);
        await tester.pumpAndSettle();
        expect(find.text('Pause video'), findsOneWidget);
        await tester.ensureVisible(find.text('Remove saved video'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remove saved video'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remove'));
        await finishNativeWork(
          tester,
          () =>
              saved == null &&
              !service.activeClinic.hasVideoAd &&
              tester
                      .widget<TextButton>(
                        find.ancestor(
                          of: find.text('Select gallery video'),
                          matching: find.byType(TextButton),
                        ),
                      )
                      .onPressed !=
                  null,
        );
        await tester.pumpAndSettle();
        expect(saved, isNull);
        expect(service.activeClinic.hasVideoAd, isFalse);
        expect(service.activeClinic.coverImageUrl, isNotEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
      },
    );
  }
  for (final outcome in [
    'reload503',
    'missing',
    'oldVideo',
    'wrongClinic',
    'coverChanged',
  ]) {
    test(
      'VIP PATCH acknowledgment requires same-clinic remote persistence: $outcome',
      () async {
        privateTier = 'vip';
        await service.refreshClinicProfile();
        var written = false, failRead = true, writes = 0;
        use((o) {
          if (o.method == 'PATCH') {
            written = true;
            writes++;
            saved = 'https://fixture.invalid/media/new.mp4';
            return f.body(profile());
          }
          if (o.path == ApiConfig.clinicProfile && written && failRead) {
            if (outcome == 'reload503') {
              return f.body({
                'error': {'code': 'SERVICE_UNAVAILABLE'},
              }, 503);
            }
            final data = profile();
            if (outcome == 'missing') data['video_ad_file'] = null;
            if (outcome == 'oldVideo') {
              data['video_ad_file'] = 'https://fixture.invalid/media/old.mp4';
            }
            if (outcome == 'wrongClinic') data['id'] = 'other-clinic';
            if (outcome == 'coverChanged') {
              data['cover_image'] = 'https://fixture.invalid/other.png';
            }
            return f.body(data);
          }
          return f.body(profile());
        });
        Object? error;
        try {
          await service.updateShowcaseVideo(
            File('test/fixtures/clinic_media/short_showcase.mp4').absolute.path,
          );
        } catch (e) {
          error = e;
        }
        expect(error, isA<ShowcaseVideoFailure>());
        final failure = error! as ShowcaseVideoFailure;
        expect(
          failure.stage,
          outcome == 'reload503'
              ? VideoSaveStage.reload
              : VideoSaveStage.persistence,
        );
        expect(failure.receipt, isNotNull);
        expect(service.activeClinic.hasVideoAd, false);
        expect(writes, 1);
        if (outcome != 'reload503') {
          failRead = false;
          await service.verifyShowcaseVideo(failure.receipt!);
          expect(service.activeClinic.videoUrl, saved);
          expect(
            writes,
            1,
            reason: 'Recovery is GET-only; never repeat the multipart write',
          );
        }
      },
    );
  }
  testWidgets(
    'video save reload failure remains beside controls and keeps selection and gallery',
    (tester) async {
      privateTier = 'vip';
      var written = false;
      use((o) {
        if (o.method == 'PATCH') {
          written = true;
          saved = 'https://fixture.invalid/media/new.mp4';
          return f.body(profile());
        }
        if (written && o.path == ApiConfig.clinicProfile) {
          return f.body({...profile(), 'video_ad_file': null});
        }
        return f.body(profile());
      });
      picker.video = File(
        'test/fixtures/clinic_media/short_showcase.mp4',
      ).absolute.path;
      await openMedia(tester);
      await tester.tap(find.text('Select gallery video'));
      await finishNativeWork(tester, () => video.probed.isCompleted);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Upload and save video'));
      await tester.tap(find.text('Upload and save video'));
      await finishNativeWork(
        tester,
        () =>
            written &&
            find
                .textContaining('Video persistence check failed')
                .evaluate()
                .isNotEmpty,
      );
      await tester.pumpAndSettle();
      expect(find.text('Discard selected video'), findsOneWidget);
      expect(find.text('Saved video change verified.'), findsNothing);
      expect(
        find.byKey(const ValueKey('video-operation-error')),
        findsOneWidget,
      );
      expect(find.text('Refresh saved images'), findsOneWidget);
      expect(wire.requests.where((r) => r.method == 'PATCH'), hasLength(1));
      await tester.ensureVisible(
        find.byKey(const ValueKey('video-operation-error')),
      );
      await f.capture(tester, 'video_save_persistence_failure');
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  for (final fault in ['timeout', '503', 'cancel']) {
    test(
      'video upload $fault is not replayed or mistaken for a gallery error',
      () async {
        privateTier = 'vip';
        await service.refreshClinicProfile();
        use((o) {
          if (fault == 'timeout') {
            throw DioException(
              requestOptions: o,
              type: DioExceptionType.sendTimeout,
            );
          }
          return f.body({
            'error': {'code': 'SERVICE_UNAVAILABLE'},
          }, 503);
        });
        final token = CancelToken();
        if (fault == 'cancel') token.cancel();
        await expectLater(
          service.updateShowcaseVideo(
            File('test/fixtures/clinic_media/short_showcase.mp4').absolute.path,
            cancelToken: token,
          ),
          throwsA(
            isA<ShowcaseVideoFailure>().having(
              (e) => e.stage,
              'stage',
              VideoSaveStage.upload,
            ),
          ),
        );
        expect(
          wire.requests.where((r) => r.method == 'PATCH').length,
          lessThanOrEqualTo(1),
        );
        expect(wire.requests.where((r) => r.method == 'GET'), isEmpty);
        expect(service.activeClinic.hasVideoAd, false);
      },
    );
  }
  test(
    'video byte progress is observable; PATCH and fresh GET are distinct operations',
    () async {
      privateTier = 'vip';
      await service.refreshClinicProfile();
      var lastSent = 0, totalBytes = 0;
      final start = wire.requests.length;
      await service.updateShowcaseVideo(
        File('test/fixtures/clinic_media/short_showcase.mp4').absolute.path,
        onSendProgress: (sent, total) {
          lastSent = sent;
          totalBytes = total;
        },
      );
      expect(lastSent, greaterThan(0));
      expect(lastSent, totalBytes);
      expect(wire.requests.skip(start).map((r) => r.method), ['PATCH', 'GET']);
      expect(service.activeClinic.hasVideoAd, true);
    },
  );
  testWidgets(
    'save preflight GET failure is video-specific and sends no PATCH',
    (tester) async {
      privateTier = 'vip';
      await openMedia(tester);
      picker.video = File(
        'test/fixtures/clinic_media/short_showcase.mp4',
      ).absolute.path;
      await tester.tap(find.text('Select gallery video'));
      await finishNativeWork(tester, () => video.probed.isCompleted);
      await tester.pumpAndSettle();
      use(
        (o) => f.body({
          'error': {'code': 'SERVICE_UNAVAILABLE'},
        }, 503),
      );
      await tester.ensureVisible(find.text('Upload and save video'));
      await tester.tap(find.text('Upload and save video'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Video permission refresh failed (HTTP 503)'),
        findsOneWidget,
      );
      expect(wire.requests.where((r) => r.method == 'PATCH'), isEmpty);
      expect(find.text('Discard selected video'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  test(
    'local backpressure is not falsely labeled as an actual HTTP acknowledgment',
    () {
      final error = ShowcaseVideoFailure(
        VideoSaveStage.upload,
        cause: const ApiException(
          message: 'local',
          statusCode: 429,
          isLocalBackpressure: true,
        ),
      );
      expect(error.isLocalBackpressure, true);
      expect(error.message, isNot(contains('HTTP')));
    },
  );
}
