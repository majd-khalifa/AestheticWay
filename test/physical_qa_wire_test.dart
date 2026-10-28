import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/services/showcase_video_change.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/google_business/data/google_business_repository.dart';
import 'onboarding_review_workflows_test.dart' as f;
import 'admin_media_polish_test.dart' show Wire;

Map<String, dynamic> profile([String? video]) => {
  ...f.clinic(),
  'cover_image': 'https://fixture.invalid/preserved-cover.png',
  'video_ad_file': video,
  'video_url': video,
  'subscription_tier': 'vip',
};
bool includesBytes(List<int> body, List<int> bytes) {
  for (var i = 0; i <= body.length - bytes.length; i++) {
    var matches = true;
    for (var j = 0; j < bytes.length; j++) {
      if (body[i + j] != bytes[j]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
    await LocaleService().setLanguage(AppLanguage.english);
  });
  tearDown(() => AuthState().logout());
  test(
    'HTTP500 sends exact authenticated multipart MP4 bytes once, rejects ACK and preserves active media',
    () async {
      final api = ApiClient(),
          old = ApiClient().dio.httpClientAdapter,
          service = ClinicPortalService();
      final wire = Wire(
        (r) => f.body({
          'error': {
            'code': 'INTERNAL_SERVER_ERROR',
            'message': 'DO NOT SHOW server traceback',
          },
        }, 500),
      );
      api.dio.httpClientAdapter = wire;
      service.resetTestingState();
      service.setCatalogRepositoryForTesting(
        ClinicCatalogRepository(apiClient: api),
      );
      service.setActiveClinicForTesting(ClinicModel.fromJson(profile()));
      addTearDown(() {
        api.dio.httpClientAdapter = old;
        service.resetTestingState();
      });
      final clip = File('test/fixtures/clinic_media/short_showcase.mp4');
      await expectLater(
        service.updateShowcaseVideo(clip.absolute.path),
        throwsA(
          isA<ShowcaseVideoFailure>()
              .having((e) => e.stage, 'stage', VideoSaveStage.upload)
              .having((e) => e.statusCode, 'status', 500)
              .having(
                (e) => e.message,
                'message',
                isNot(contains('traceback')),
              ),
        ),
      );
      expect(wire.requests, hasLength(1));
      final r = wire.requests.single;
      expect(r.method, 'PATCH');
      expect(r.path, 'clinic-portal/profile/');
      expect(r.data, isA<FormData>());
      expect(r.headers['Authorization'], 'Bearer disposable-access');
      final form = r.data as FormData;
      expect(form.fields, isEmpty);
      expect(form.files.single.key, 'video_ad_file');
      expect(form.files.single.value.contentType.toString(), 'video/mp4');
      expect(
        r.contentType,
        contains('multipart/form-data; boundary=${form.boundary}'),
      );
      final raw = wire.sent.single;
      expect(
        raw.length,
        int.parse('${r.headers[Headers.contentLengthHeader]}'),
      );
      expect(includesBytes(raw, clip.readAsBytesSync()), true);
      expect(
        utf8.decode(raw, allowMalformed: true),
        contains('name="video_ad_file"; filename="upload.mp4"'),
      );
      expect(
        utf8.decode(raw, allowMalformed: true),
        endsWith('--${form.boundary}--\r\n'),
      );
      expect(service.activeClinic.hasVideoAd, false);
      expect(
        service.activeClinic.coverImageUrl,
        'https://fixture.invalid/preserved-cover.png',
      );
    },
  );
  for (final reloadStatus in [200, 500]) {
    test(
      'PATCH200 with freshGET$reloadStatus requires persisted same media and never repeats upload',
      () async {
        final api = ApiClient(),
            old = ApiClient().dio.httpClientAdapter,
            service = ClinicPortalService();
        final wire = Wire(
          (r) => r.method == 'PATCH'
              ? f.body(profile('https://fixture.invalid/new-video.mp4'))
              : f.body(profile(), reloadStatus),
        );
        api.dio.httpClientAdapter = wire;
        service.resetTestingState();
        service.setCatalogRepositoryForTesting(
          ClinicCatalogRepository(apiClient: api),
        );
        service.setActiveClinicForTesting(ClinicModel.fromJson(profile()));
        addTearDown(() {
          api.dio.httpClientAdapter = old;
          service.resetTestingState();
        });
        await expectLater(
          service.updateShowcaseVideo(
            File('test/fixtures/clinic_media/short_showcase.mp4').absolute.path,
          ),
          throwsA(
            isA<ShowcaseVideoFailure>().having(
              (e) => e.stage,
              'stage',
              reloadStatus == 200
                  ? VideoSaveStage.persistence
                  : VideoSaveStage.reload,
            ),
          ),
        );
        expect(wire.requests.map((r) => r.method), ['PATCH', 'GET']);
        expect(service.activeClinic.hasVideoAd, false);
      },
    );
  }
  test(
    'Google suggestions use real formatted text if main text is empty; no native map needed',
    () async {
      final api = ApiClient(), old = ApiClient().dio.httpClientAdapter;
      final wire = Wire(
        (r) => f.body({
          'suggestions': [
            {
              'place_id': 'QA-Selected',
              'main_text': '',
              'secondary_text': 'QA Dubai',
              'formatted_text': 'Disposable Clinic, QA Dubai',
            },
          ],
          'attributions': [],
        }),
      );
      api.dio.httpClientAdapter = wire;
      addTearDown(() => api.dio.httpClientAdapter = old);
      final rows = await CurrentClinicGoogleBusinessRepository().autocomplete(
        'Disposable',
        sessionToken: '550e8400-e29b-41d4-a716-446655440000',
        languageCode: 'en',
      );
      expect(rows.single.name, 'Disposable Clinic, QA Dubai');
      expect(rows.single.address, 'QA Dubai');
      expect(
        wire.requests.single.path,
        'clinic-portal/profile/google-business/autocomplete/',
      );
    },
  );
  test(
    'actual nested no-verified-channel error stays localized without exposing body',
    () {
      final e = ApiException.fromDioError(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 400,
            data: {
              'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'Validation failed.',
                'fields': {
                  'code': ['NO_VERIFIED_DELIVERY_CHANNEL'],
                  'detail': ['Private delivery details'],
                },
              },
            },
          ),
        ),
      );
      expect(e.errorCode, 'NO_VERIFIED_DELIVERY_CHANNEL');
      expect(e.message, contains('No verified delivery channel'));
      expect(e.rawData, isNull);
      expect(e.message, isNot(contains('Private')));
    },
  );
}
