import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/network/auth_interceptor.dart';
import 'package:aesthetic_way/core/services/video_upload_policy.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/services/showcase_video_change.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'admin_media_polish_test.dart' show Wire;
import 'onboarding_review_workflows_test.dart' as f;
import 'physical_qa_wire_test.dart' as p;
import 'clinic_media_contract_test.dart' show finishNativeWork;
import 'support/large_showcase_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory folder;
  late File clip;
  late ApiClient api;
  late HttpClientAdapter original;
  late ClinicPortalService service;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    await TokenStorage().saveTokens(
      accessToken: 'disposable-access',
      refreshToken: 'disposable-refresh',
    );
    AuthState().login(
      name: 'Disposable QA',
      phone: 'fixture',
      role: 'clinic_admin',
    );
    folder = Directory.systemTemp.createTempSync('aw-video-budget-');
    clip = File('${folder.path}/phone_capture.mp4')
      ..writeAsBytesSync(largeShowcaseBytes(paddingBytes: 19 * 1024 * 1024));
    api = ApiClient();
    original = api.dio.httpClientAdapter;
    service = ClinicPortalService()..resetTestingState();
    service.setCatalogRepositoryForTesting(
      ClinicCatalogRepository(apiClient: api),
    );
    service.setActiveClinicForTesting(ClinicModel.fromJson(p.profile()));
  });
  tearDown(() {
    api.dio.httpClientAdapter = original;
    service.resetTestingState();
    AuthState().logout();
    folder.deleteSync(recursive: true);
  });
  test(
    '401 refreshes credentials once but never replays a video body',
    () async {
      final refresh = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      final refreshWire = f.Adapter(
        (r) => f.body({'access': 'new-disposable-access'}),
      );
      refresh.httpClientAdapter = refreshWire;
      final transport = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      transport.interceptors.add(
        AuthInterceptor(transport, refreshDio: refresh),
      );
      final wire = Wire((r) => f.body({'detail': 'expired'}, 401));
      transport.httpClientAdapter = wire;
      final data = FormData.fromMap({
        'video_ad_file': await MultipartFile.fromFile(clip.path),
      });
      await expectLater(
        transport.patch<dynamic>(
          ApiConfig.clinicProfile,
          data: data,
          options: VideoUploadPolicy.options(
            VideoTransferTrace(clip.lengthSync()),
          ),
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'actual HTTP',
            401,
          ),
        ),
      );
      expect(wire.requests, hasLength(1));
      expect(refreshWire.requests, hasLength(1));
      expect(await TokenStorage().getAccessToken(), 'new-disposable-access');
      transport.close(force: true);
      refresh.close(force: true);
    },
  );
  testWidgets(
    '19MiB streamed file survives a320s simulated transfer with endpoint-only budgets and genuine progress',
    (tester) async {
      String? stored;
      final response = Completer<ResponseBody>();
      Timer? transfer, deadline;
      final adapter = Wire((r) {
        if (r.method != 'PATCH') return f.body(p.profile(stored));
        transfer = Timer(const Duration(seconds: 320), () {
          stored = 'https://fixture.invalid/saved.mp4';
          response.complete(f.body(p.profile(stored)));
        });
        deadline = Timer(
          r.sendTimeout ?? ApiConfig.sendTimeout,
          () => response.completeError(
            DioException(requestOptions: r, type: DioExceptionType.sendTimeout),
          ),
        );
        return response.future.whenComplete(() {
          transfer?.cancel();
          deadline?.cancel();
        });
      });
      api.dio.httpClientAdapter = adapter;
      var finished = false;
      final progress = <(int, int)>[];
      final saving = service
          .updateShowcaseVideo(
            clip.path,
            onSendProgress: (sent, total) => progress.add((sent, total)),
          )
          .then((_) => finished = true);
      await finishNativeWork(tester, () => adapter.requests.isNotEmpty);
      final upload = adapter.requests.single;
      expect(upload.sendTimeout, const Duration(seconds: 480));
      expect(upload.receiveTimeout, const Duration(seconds: 120));
      expect(upload.connectTimeout, const Duration(seconds: 30));
      expect(
        (upload.data as FormData).files.single.value.length,
        clip.lengthSync(),
      );
      expect(adapter.sent.single.length, greaterThan(19 * 1024 * 1024));
      await tester.pump(const Duration(seconds: 61));
      expect(finished, false);
      await tester.pump(const Duration(seconds: 260));
      await tester.pump();
      await saving;
      expect(finished, true);
      expect(adapter.requests.map((r) => r.method), ['PATCH', 'GET']);
      expect(adapter.requests.last.sendTimeout, const Duration(seconds: 60));
      expect(adapter.requests.last.receiveTimeout, const Duration(seconds: 60));
      expect(api.dio.options.sendTimeout, const Duration(seconds: 60));
      expect(progress, isNotEmpty);
      expect(progress.last.$1, progress.last.$2);
      expect(service.activeClinic.videoUrl, stored);
    },
  );
  for (final code in [413, 429, 500, 502, 504]) {
    test(
      'HTTP$code surfaces actual failure, safe support metadata and sends no automatic retry',
      () async {
        final adapter = Wire(
          (r) => f.body({
            'error': {
              'code': 'PRIVATE_PROVIDER_DETAIL',
              'message': 'private path and credentials',
            },
          }, code),
        );
        api.dio.httpClientAdapter = adapter;
        ShowcaseVideoFailure? failure;
        try {
          await service.updateShowcaseVideo(clip.path);
        } on ShowcaseVideoFailure catch (e) {
          failure = e;
        }
        expect(failure, isNotNull);
        expect(failure!.statusCode, code);
        expect(failure.stage, VideoSaveStage.upload);
        expect(adapter.requests, hasLength(1));
        final diagnostic = failure.diagnostic!;
        final safe = diagnostic.safeText(failure.stage.name);
        expect(diagnostic.sizeBand, '10-20MiB');
        expect(
          diagnostic.requestId,
          adapter.requests.single.headers['X-Request-ID'],
        );
        expect(diagnostic.requestId, matches(RegExp(r'^[a-f0-9-]{36}$')));
        expect(safe, contains('http=$code'));
        for (final forbidden in [
          clip.path,
          'https://',
          'Bearer',
          'disposable-access',
          'private path',
        ]) {
          expect(safe, isNot(contains(forbidden)));
        }
        expect(service.activeClinic.hasVideoAd, false);
        expect(clip.existsSync(), true);
      },
    );
  }
  test(
    'connection loss after body transmission is uncertain; explicit freshGET never repeats PATCH',
    () async {
      String? stored;
      final adapter = Wire((r) {
        if (r.method == 'PATCH') {
          stored = 'https://fixture.invalid/persisted.mp4';
          throw DioException(
            requestOptions: r,
            type: DioExceptionType.connectionError,
          );
        }
        return f.body(p.profile(stored));
      });
      api.dio.httpClientAdapter = adapter;
      await expectLater(
        service.updateShowcaseVideo(clip.path),
        throwsA(
          isA<ShowcaseVideoFailure>().having(
            (e) => e.statusCode,
            'no HTTP acknowledgment',
            isNull,
          ),
        ),
      );
      expect(service.activeClinic.hasVideoAd, false);
      expect(adapter.requests, hasLength(1));
      await service.refreshClinicProfile();
      expect(service.activeClinic.videoUrl, stored);
      expect(adapter.requests.map((r) => r.method), ['PATCH', 'GET']);
      expect(clip.existsSync(), true);
    },
  );
  testWidgets(
    'cancellation near completion preserves the selected file and does not replay multipart',
    (tester) async {
      final ack = Completer<ResponseBody>(), token = CancelToken();
      final adapter = Wire((r) => ack.future);
      api.dio.httpClientAdapter = adapter;
      final outcome = expectLater(
        service.updateShowcaseVideo(clip.path, cancelToken: token),
        throwsA(
          isA<ShowcaseVideoFailure>().having(
            (e) => e.isCancelled,
            'cancelled',
            true,
          ),
        ),
      );
      await finishNativeWork(tester, () => adapter.requests.isNotEmpty);
      token.cancel();
      await tester.pump();
      await outcome;
      expect(adapter.requests, hasLength(1));
      expect(clip.existsSync(), true);
      expect(service.activeClinic.hasVideoAd, false);
      ack.complete(f.body(p.profile('https://fixture.invalid/late.mp4')));
      await tester.pump();
      expect(service.activeClinic.hasVideoAd, false);
    },
  );
  testWidgets(
    'receive deadline after persisted but unacknowledged save requires read-only reconciliation',
    (tester) async {
      String? stored;
      final adapter = Wire((r) {
        if (r.method != 'PATCH') return f.body(p.profile(stored));
        stored = 'https://fixture.invalid/late-ack.mp4';
        final c = Completer<ResponseBody>();
        Timer(
          r.receiveTimeout!,
          () => c.completeError(
            DioException(
              requestOptions: r,
              type: DioExceptionType.receiveTimeout,
            ),
          ),
        );
        return c.future;
      });
      api.dio.httpClientAdapter = adapter;
      var failed = false;
      final outcome = expectLater(
        service.updateShowcaseVideo(clip.path),
        throwsA(isA<ShowcaseVideoFailure>()),
      ).whenComplete(() => failed = true);
      await finishNativeWork(tester, () => adapter.requests.isNotEmpty);
      await tester.pump(const Duration(seconds: 121));
      await finishNativeWork(tester, () => failed);
      await outcome;
      expect(service.activeClinic.hasVideoAd, false);
      var reconciled = false;
      final refresh = service.refreshClinicProfile().then(
        (_) => reconciled = true,
      );
      await finishNativeWork(tester, () => reconciled);
      await refresh;
      expect(service.activeClinic.videoUrl, stored);
      expect(adapter.requests.where((r) => r.method == 'PATCH'), hasLength(1));
    },
  );
}
