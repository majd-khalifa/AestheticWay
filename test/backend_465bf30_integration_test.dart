import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';
import 'package:aesthetic_way/features/auth/data/models/auth_models.dart';
import 'package:aesthetic_way/features/auth/models/deletion_delivery.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/verify_registered_email_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/locations/data/nearby_clinics_repository.dart';
import 'package:aesthetic_way/features/locations/models/uae_location.dart';
import 'package:aesthetic_way/features/locations/services/patient_location_controller.dart';
import 'package:aesthetic_way/features/locations/presentation/nearby_clinics_screen.dart';
import 'admin_media_polish_test.dart' show Wire;
import 'onboarding_review_workflows_test.dart' as f;
import 'physical_qa_wire_test.dart' as video;
import 'uae_location_qa_test.dart' show LocationProvider;
import 'support/large_showcase_fixture.dart';
import 'support/patient_visual_harness.dart';

Map<String, dynamic> user({bool verified = false}) => {
  'id': 'disposable-patient',
  'full_name': 'Disposable QA',
  'phone': 'fixture',
  'email': 'disposable@example.invalid',
  'role': 'patient',
  'is_verified': true,
  'is_email_verified': verified,
};
Map<String, dynamic> nearby(String id, num km, String tier) => {
  ...f.clinic(status: 'approved'),
  'id': id,
  'subscription_tier': tier,
  'distance_km': km,
  'nearest_branch_id': 'branch-$id',
  'nearest_branch': {
    'id': 'branch-$id',
    'latitude': 25.101,
    'longitude': 55.201,
    'name_en': 'Closest branch',
    'name_ar': 'الفرع الأقرب',
    'address_en': 'Source branch address',
    'address_ar': 'عنوان الفرع',
  },
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    await LocaleService().setLanguage(AppLanguage.english);
    AuthState().login(name: 'Disposable QA', phone: 'fixture', role: 'patient');
  });
  tearDown(() => AuthState().logout());
  Wire wire(ResponseBody Function(RequestOptions) reply) {
    final api = ApiClient(), old = ApiClient().dio.httpClientAdapter;
    final adapter = Wire(reply);
    api.dio.httpClientAdapter = adapter;
    addTearDown(() => api.dio.httpClientAdapter = old);
    return adapter;
  }

  test(
    'email verification is independent of phone verification and persists in secure session cache',
    () async {
      expect(UserModel.fromJson(user()).isEmailVerified, false);
      wire((_) => f.body(user(verified: true)));
      final actual = await AuthRepository().getMe();
      expect(actual.isEmailVerified, true);
      expect(TokenStorage().getUser()!['is_email_verified'], true);
      expect(AuthState().isEmailVerified, true);
      await TokenStorage().saveTokens(
        accessToken: 'disposable-access',
        refreshToken: 'disposable-refresh',
      );
      // Simulate cold in-memory state while retaining the secure session cache.
      AuthState().login(
        name: 'Disposable QA',
        phone: 'fixture',
        role: 'patient',
      );
      expect(AuthState().isEmailVerified, false);
      await AuthState().restoreSession();
      expect(AuthState().isEmailVerified, true);
      AuthState().logout();
      expect(AuthState().isEmailVerified, false);
      expect(
        UserModel.fromJson({'is_email_verified': 'true'}).isEmailVerified,
        false,
      );
    },
  );
  test(
    'email-only deletion uses actual masked API channel without deriving contacts or claiming delivery',
    () {
      final d = DeletionDelivery.parse({
        'delivery_channel': 'email',
        'masked_destination': 'a***@example.com',
        'deliveries': [
          {'channel': 'email', 'masked_destination': 'a***@example.com'},
        ],
      });
      expect(d.single.channel, 'email');
      expect(d.single.destination, 'a***@example.com');
      expect(
        DeletionDelivery.parse({
          'delivery_channel': 'email',
          'masked_destination': 'raw@example.com',
        }),
        isEmpty,
      );
    },
  );
  for (final code in [
    'PLACES_PROVIDER_UNAVAILABLE',
    'STORAGE_ERROR',
    'PRIVATE_TRACEBACK',
  ]) {
    test('503 preserves only a source-confirmed safe API code: $code', () {
      final e = ApiException.fromDioError(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 503,
            data: {
              'error': {'code': code, 'message': 'Private provider payload'},
            },
          ),
        ),
      );
      expect(e.errorCode, code == 'PRIVATE_TRACEBACK' ? 'SERVER_ERROR' : code);
      expect(e.statusCode, 503);
      expect(e.rawData, isNull);
      expect(e.message, isNot(contains('Private')));
    });
  }
  test(
    'large genuine MP4 streams once, requires PATCH plus fresh GET, cold reload and null deletion preserve cover',
    () async {
      AuthState().login(name: 'QA', phone: 'fixture', role: 'clinic_admin');
      await TokenStorage().saveTokens(
        accessToken: 'disposable-access',
        refreshToken: 'disposable-refresh',
      );
      final dir = Directory.systemTemp.createTempSync('aw-large-video-');
      final file = File(
        '${dir.path}/${List.filled(8, 'android_camera').join('_')}.mp4',
      )..writeAsBytesSync(largeShowcaseBytes());
      addTearDown(() => dir.deleteSync(recursive: true));
      expect(file.lengthSync(), greaterThan(2621440));
      String? saved;
      final ack = Completer<void>(), fresh = Completer<ResponseBody>();
      var firstGet = true;
      final api = ApiClient(), old = ApiClient().dio.httpClientAdapter;
      final adapter = Wire((r) {
        if (r.method == 'PATCH') {
          saved = r.data is FormData
              ? 'https://fixture.invalid/clinics/videos/vip_saved.mp4'
              : null;
          if (!ack.isCompleted) ack.complete();
        }
        return f.body(video.profile(saved));
      });
      // Hold only the first post-write GET to prove acknowledgment is insufficient.
      final responses = f.Adapter((r) async {
        if (r.method == 'GET' && firstGet) {
          firstGet = false;
          return fresh.future;
        }
        return f.body(video.profile(saved));
      });
      // Use a wire subclass below so genuine multipart bytes are consumed too.
      final transport = _LargeWire(adapter, responses);
      api.dio.httpClientAdapter = transport;
      final service = ClinicPortalService()..resetTestingState();
      service.setCatalogRepositoryForTesting(
        ClinicCatalogRepository(apiClient: api),
      );
      service.setActiveClinicForTesting(ClinicModel.fromJson(video.profile()));
      addTearDown(() {
        api.dio.httpClientAdapter = old;
        service.resetTestingState();
      });
      var completed = false;
      final save = service
          .updateShowcaseVideo(file.path)
          .then((_) => completed = true);
      await ack.future;
      expect(completed, false);
      expect(service.activeClinic.hasVideoAd, false);
      fresh.complete(f.body(video.profile(saved)));
      await save;
      expect(completed, true);
      expect(service.activeClinic.videoUrl, saved);
      final sent = adapter.sent.single;
      final body = adapter.requests.single.data as FormData;
      expect(body.files.single.key, 'video_ad_file');
      expect(body.files.single.value.length, file.lengthSync());
      expect(body.files.single.value.contentType.toString(), 'video/mp4');
      expect(sent.length, greaterThan(file.lengthSync()));
      final payloadStart =
          String.fromCharCodes(sent.take(512)).indexOf('\r\n\r\n') + 4;
      expect(payloadStart, greaterThan(4));
      expect(
        sent.sublist(payloadStart, payloadStart + file.lengthSync()),
        orderedEquals(file.readAsBytesSync()),
      );
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer disposable-access',
      );
      expect(
        adapter.requests.single.contentType,
        contains('boundary=${body.boundary}'),
      );
      // A cold service/cache starts with no URL; the private GET supplies it.
      service.resetTestingState();
      service.setCatalogRepositoryForTesting(
        ClinicCatalogRepository(apiClient: api),
      );
      await service.refreshClinicProfile();
      expect(service.activeClinic.videoUrl, saved);
      final cover = service.activeClinic.coverImageUrl;
      await service.updateShowcaseVideo(null);
      expect(service.activeClinic.videoUrl, isNull);
      expect(service.activeClinic.coverImageUrl, cover);
      expect(adapter.requests.where((r) => r.method == 'PATCH'), hasLength(2));
      expect(adapter.requests.last.data, {'video_ad_file': null});
    },
  );
  test(
    'nearest branch identity and coordinate data never fall back to clinic headquarters',
    () async {
      wire(
        (_) => f.body({
          'results': [nearby('basic', .2, 'basic'), nearby('vip', 2, 'vip')],
          'count': 22,
          'next': 'https://untrusted.invalid/?page=2',
        }),
      );
      final p = await BackendNearbyClinicsRepository().getNearby(
        const PatientPosition(25.1, 55.2),
      );
      expect(p.items.map((r) => r.clinic.id), ['basic', 'vip']);
      expect(p.items.first.branchLocation!.latitude, 25.101);
      expect(p.items.first.branchNameEn, 'Closest branch');
      expect(p.total, 22);
      expect(p.hasMore, true);
    },
  );
  test(
    'canonical manual catalog query keeps complete numbered pages without distance or area claims',
    () async {
      final adapter = wire(
        (r) => f.body({
          'count': 21,
          'next': r.queryParameters['page'] == 1
              ? 'https://untrusted.invalid/?page=2'
              : null,
          'results': List.generate(
            r.queryParameters['page'] == 1 ? 20 : 1,
            (i) => {
              ...f.clinic(),
              'id': 'page-${r.queryParameters['page']}-$i',
              'distance_km': null,
            },
          ),
        }),
      );
      final query = NearbySearchQuery(
        locality: UaeLocality(const UaeCity('dubai', 'DU', 'Dubai', 'دبي')),
      );
      final repo = BackendNearbyClinicsRepository();
      final first = await repo.search(query);
      final second = await repo.search(query, page: 2);
      expect(first.items, hasLength(20));
      expect(first.total, 21);
      expect(first.hasMore, true);
      expect(second.items, hasLength(1));
      expect(second.hasMore, false);
      expect(first.items.every((r) => r.distanceKm == null), true);
      expect(adapter.requests.last.queryParameters, {
        'city': 'Dubai',
        'emirate': 'DU',
        'page': 2,
        'page_size': 20,
      });
      expect(
        adapter.requests.every((r) => r.path == 'home/nearby-clinics/'),
        true,
      );
    },
  );
  test(
    'branch without coordinates stays unmappable even when headquarters has coordinates',
    () async {
      final row = nearby('id', 1, 'basic');
      row['nearest_branch'] = <String, dynamic>{
        ...(row['nearest_branch'] as Map).cast<String, dynamic>(),
        'latitude': null,
      };
      row['latitude'] = 25.4;
      row['longitude'] = 55.5;
      wire(
        (_) => f.body({
          'results': [row],
          'next': null,
        }),
      );
      final page = await BackendNearbyClinicsRepository().getNearby(
        const PatientPosition(25.1, 55.2),
      );
      expect(page.items.single.branchLocation, isNull);
      expect(page.items.single.distanceKm, 1);
    },
  );
  for (final invalid in ['mismatch', 'missing']) {
    test(
      'rejects $invalid nearest-branch identity instead of sending HQ directions',
      () async {
        final row = nearby('id', 1, 'featured');
        row['nearest_branch'] = invalid == 'missing' ? null : {'id': 'other'};
        wire(
          (_) => f.body({
            'results': [row],
          }),
        );
        await expectLater(
          BackendNearbyClinicsRepository().getNearby(
            const PatientPosition(25.1, 55.2),
          ),
          throwsA(isA<ApiException>()),
        );
      },
    );
  }
  testWidgets(
    'registered email verification uses same current email, invalid OTP preserves input and durable flag is required',
    (tester) async {
      var verified = false, invalid = true;
      await TokenStorage().saveUser(user());
      final adapter = wire((r) {
        if (r.path.endsWith('request/')) {
          return f.body({'success': true, 'resend_cooldown': 60});
        }
        if (r.path.endsWith('confirm/')) {
          if (invalid) {
            return f.body({
              'error': {
                'code': 'VALIDATION_ERROR',
                'fields': {
                  'code': ['Invalid verification code.'],
                },
              },
            }, 400);
          }
          verified = true;
          return f.body({'success': true});
        }
        return f.body(user(verified: verified));
      });
      await tester.pumpWidget(
        const MaterialApp(home: VerifyRegisteredEmailScreen()),
      );
      await tester.tap(
        find.byKey(const ValueKey('email-verification-request')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Delivery is not confirmed'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('email-verification-code')),
        '123456',
      );
      await tester.tap(
        find.byKey(const ValueKey('email-verification-confirm')),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('email-verification-code')),
            )
            .controller!
            .text,
        '123456',
      );
      invalid = false;
      await tester.tap(
        find.byKey(const ValueKey('email-verification-confirm')),
      );
      await tester.pumpAndSettle();
      expect(AuthState().isEmailVerified, true);
      expect(
        adapter.requests.where((r) => r.path.endsWith('request/')).single.data,
        {'new_email': 'disposable@example.invalid'},
      );
      expect(
        adapter.requests.where((r) => r.path.contains('deletion')),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'email OTP acknowledgment cannot override a fresh unverified profile',
    (tester) async {
      await TokenStorage().saveUser(user());
      final adapter = wire(
        (r) => f.body(r.method == 'GET' ? user() : {'success': true}),
      );
      await tester.pumpWidget(
        const MaterialApp(home: VerifyRegisteredEmailScreen()),
      );
      await tester.tap(
        find.byKey(const ValueKey('email-verification-request')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('email-verification-code')),
        '123456',
      );
      await tester.tap(
        find.byKey(const ValueKey('email-verification-confirm')),
      );
      await tester.pumpAndSettle();
      expect(AuthState().isEmailVerified, false);
      expect(
        find.textContaining('Email verification was not confirmed'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('email-verification-code')),
        findsOneWidget,
      );
      expect(adapter.requests.last.method, 'GET');
      expect(adapter.requests.last.path, 'auth/me/');
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      testWidgets('enabled source-backed nearby list/map dark=$dark ar=$ar', (
        tester,
      ) async {
        final adapter = wire(
          (_) => f.body({
            'results': [nearby('basic', .2, 'basic')],
            'count': 1,
            'next': null,
          }),
        );
        final location = PatientLocationController(
          provider: LocationProvider(),
        );
        await location.useDeviceLocation();
        await f.render(
          tester,
          NearbyClinicsScreen(location: location),
          dark: dark,
          ar: ar,
        );
        await tester.pump(const Duration(milliseconds: 351));
        await tester.pumpAndSettle();
        expect(adapter.requests.any((r) => r.path == 'clinics/nearby/'), true);
        expect(
          find.textContaining(ar ? 'الفرع الأقرب' : 'Closest branch'),
          findsOneWidget,
        );
        expect(
          find.textContaining(ar ? 'غير متاح حالياً' : 'not available yet'),
          findsNothing,
        );
        await f.capture(
          tester,
          'nearby_enabled_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
        );
        await tester.tap(find.text(ar ? 'روابط الخرائط' : 'Map links'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            ar ? 'الموقع في خرائط Google' : 'Open location in Google Maps',
          ),
          findsOneWidget,
        );
        await f.capture(
          tester,
          'nearby_map_choices_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
        );
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
        location.dispose();
      });
    }
  }
}

class _LargeWire implements HttpClientAdapter {
  _LargeWire(this.writes, this.reads);
  final Wire writes;
  final f.Adapter reads;
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) => o.method == 'GET'
      ? reads.fetch(o, stream, cancel)
      : writes.fetch(o, stream, cancel);
  @override
  void close({bool force = false}) {}
}
