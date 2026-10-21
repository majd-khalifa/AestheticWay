import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/main.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/auth/session_changed_exception.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/network/api_transport_policy.dart';
import 'package:aesthetic_way/core/network/auth_interceptor.dart';
import 'package:aesthetic_way/core/services/media_file_policy.dart';
import 'package:aesthetic_way/core/services/media_payload_builder.dart';
import 'package:aesthetic_way/core/services/media_upload_service.dart';
import 'package:aesthetic_way/core/utils/maps_launcher.dart';
import 'package:aesthetic_way/features/admin/presentation/widgets/admin_clinic_editor.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/splash/presentation/screens/splash_screen.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.reply);
  final Future<ResponseBody> Function(RequestOptions) reply;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) => reply(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody _body(int status, Object data) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);
Map<String, dynamic> _user(String id, {String role = 'patient'}) => {
  'id': id,
  'full_name': 'Fixture $id',
  'phone': id == 'B' ? '+971501111112' : '+971501111111',
  'role': role,
  'is_verified': true,
};
Map<String, dynamic> _auth(String id) => {
  'user': _user(id),
  'access_token': 'fixture-access-$id',
  'refresh_token': 'fixture-refresh-$id',
};

class _Api implements ApiClient {
  _Api({this.getReply, this.postReply});
  Future<Object> Function(String)? getReply;
  Future<Object> Function(String)? postReply;
  final posts = <String>[];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async => Response<T>(
    data: await getReply!(path) as T,
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
  );
  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    posts.add(path);
    return Response<T>(
      data: await postReply!(path) as T,
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
    );
  }
}

class _Upload implements MediaUploadService {
  final gate = Completer<Map<String, dynamic>>();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<Map<String, dynamic>> uploadImage({
    required String filePath,
    required String mediaType,
    String? clinicId,
  }) => gate.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final tokens = TokenStorage();
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    AuthState().logout();
    await tokens.clear();
    unawaited(LocaleService().setLanguage(AppLanguage.english));
  });
  tearDown(() async {
    AuthState().logout();
    await tokens.clear();
  });
  test(
    'API credentials are limited to the configured HTTPS origin and normalized prefix',
    () {
      const base = 'https://api.example.test/api/v1/';
      expect(
        ApiTransportPolicy.permits(Uri.parse('${base}leads/'), base),
        isTrue,
      );
      for (final url in [
        'http://api.example.test/api/v1/leads/',
        'https://other.example.test/api/v1/leads/',
        'https://api.example.test:444/api/v1/leads/',
        'https://api.example.test/api/v1/../../private/',
        'https://user:password@api.example.test/api/v1/leads/',
        'https://api.example.test/api/v1/leads/#fragment',
      ]) {
        expect(
          ApiTransportPolicy.permits(Uri.parse(url), base),
          isFalse,
          reason: url,
        );
      }
    },
  );
  test(
    'Cross-origin request is rejected before any token can reach an adapter',
    () async {
      await tokens.saveTokens(
        accessToken: 'fixture-access',
        refreshToken: 'fixture-refresh',
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1/'));
      var calls = 0;
      dio.httpClientAdapter = _Adapter((_) async {
        calls++;
        return _body(200, {});
      });
      dio.interceptors.add(AuthInterceptor(dio));
      await expectLater(
        dio.get('https://other.example.test/resource/'),
        throwsA(isA<DioException>()),
      );
      expect(calls, 0);
      dio.close();
    },
  );
  test(
    'Auth paths are exact; public login strips stale manually supplied headers and redirects stay disabled',
    () async {
      await tokens.saveTokens(
        accessToken: 'fixture-current',
        refreshToken: 'fixture-refresh',
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1/'));
      final seen = <RequestOptions>[];
      dio.httpClientAdapter = _Adapter((o) async {
        seen.add(o);
        return _body(200, {});
      });
      dio.interceptors.add(AuthInterceptor(dio));
      await dio.post(
        'auth/login/',
        options: Options(headers: {'authorization': 'Bearer fixture-older'}),
      );
      await dio.get('private/auth/login/');
      expect(
        seen.first.headers.keys.any((k) => k.toLowerCase() == 'authorization'),
        isFalse,
      );
      expect(seen.last.headers['Authorization'], 'Bearer fixture-current');
      expect(seen.every((o) => !o.followRedirects), isTrue);
      dio.close();
    },
  );
  test(
    'A late successful private response from Patient A is cancelled after session switching',
    () async {
      await tokens.saveTokens(
        accessToken: 'fixture-A',
        refreshToken: 'fixture-refresh-A',
      );
      final gate = Completer<void>(), started = Completer<void>();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1/'));
      dio.httpClientAdapter = _Adapter((o) async {
        started.complete();
        await gate.future;
        return _body(200, {'private_notes': 'Synthetic A note'});
      });
      dio.interceptors.add(AuthInterceptor(dio));
      final pending = expectLater(
        dio.get('leads/my/'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      await started.future;
      await tokens.clear();
      await tokens.saveTokens(
        accessToken: 'fixture-B',
        refreshToken: 'fixture-refresh-B',
      );
      gate.complete();
      await pending;
      expect(tokens.currentAccessToken, 'fixture-B');
      dio.close();
    },
  );
  test('A delayed getMe cannot reinstall Patient A under Patient B', () async {
    AuthState().login(name: 'Fixture A', phone: '+971501111111');
    final gate = Completer<Object>();
    final api = _Api(getReply: (_) => gate.future);
    final repo = AuthRepository(apiClient: api);
    final pending = expectLater(
      repo.getMe(),
      throwsA(isA<SessionChangedException>()),
    );
    await tokens.clear();
    AuthState().login(name: 'Fixture B', phone: '+971501111112');
    await tokens.saveUser(_user('B'));
    gate.complete(_user('A'));
    await pending;
    expect(AuthState().userName, 'Fixture B');
    expect(tokens.getUser()!['id'], 'B');
  });
  test('Delayed login after logout cannot resurrect a session', () async {
    final gate = Completer<Object>();
    final repo = AuthRepository(apiClient: _Api(postReply: (_) => gate.future));
    final pending = expectLater(
      repo.login(identifier: '+971501111111', password: 'fixture-password'),
      throwsA(isA<SessionChangedException>()),
    );
    await tokens.clear();
    AuthState().logout();
    gate.complete(_auth('A'));
    await pending;
    expect(AuthState().isLoggedIn, isFalse);
    expect(tokens.currentAccessToken, isNull);
  });
  test(
    'Only the most recent overlapping login can install credentials',
    () async {
      final a = Completer<Object>(), b = Completer<Object>();
      var count = 0;
      final repo = AuthRepository(
        apiClient: _Api(postReply: (_) => (count++ == 0 ? a : b).future),
      );
      final first = expectLater(
        repo.login(identifier: '+971501111111', password: 'fixture-password'),
        throwsA(isA<SessionChangedException>()),
      );
      final second = repo.login(
        identifier: '+971501111112',
        password: 'fixture-password',
      );
      b.complete(_auth('B'));
      await second;
      a.complete(_auth('A'));
      await first;
      expect(tokens.currentAccessToken, 'fixture-access-B');
      expect(AuthState().userName, 'Fixture B');
    },
  );
  test('Unknown-role authentication is never installed', () async {
    final response = _auth('A');
    response['user'] = _user('A', role: 'unexpected-role');
    final repo = AuthRepository(
      apiClient: _Api(postReply: (_) async => response),
    );
    await expectLater(
      repo.login(identifier: '+971501111111', password: 'fixture-password'),
      throwsA(isA<ApiException>()),
    );
    expect(tokens.currentAccessToken, isNull);
    expect(AuthState().isLoggedIn, isFalse);
  });
  test(
    'Role changes invalidate session snapshots and clear account favorites',
    () async {
      await tokens.saveUser(_user('A'));
      final before = tokens.sessionEpoch;
      AuthState().login(name: 'Fixture A', phone: '+971501111111');
      AuthState().toggleFavorite('fixture-clinic');
      await tokens.saveUser(_user('A', role: 'super_admin'));
      AuthState().login(
        name: 'Fixture Admin',
        phone: '+971501111111',
        role: 'super_admin',
      );
      expect(tokens.sessionEpoch, greaterThan(before));
      expect(AuthState().favoriteClinicIds, isEmpty);
      expect(
        () => tokens.getUser()!['role'] = 'patient',
        throwsUnsupportedError,
      );
    },
  );
  test(
    'Server errors and unknown validation values never retain or display raw PII/secrets',
    () {
      for (final arabic in [false, true]) {
        unawaited(
          LocaleService().setLanguage(
            arabic ? AppLanguage.arabic : AppLanguage.english,
          ),
        );
        for (final status in [400, 500]) {
          final error = ApiException.fromDioError(
            DioException(
              requestOptions: RequestOptions(path: 'auth/me/'),
              response: Response(
                requestOptions: RequestOptions(path: 'auth/me/'),
                statusCode: status,
                data: {
                  'detail':
                      'SyntheticPatient synthetic@example.test +971501111111 Bearer fixture-secret https://cdn.example.test/a?sig=fixture-secret',
                },
              ),
            ),
          );
          expect(error.toString(), isNot(contains('SyntheticPatient')));
          expect(error.toString(), isNot(contains('fixture-secret')));
          expect(error.toString(), isNot(contains('synthetic@example.test')));
          expect(error.toString(), isNot(contains('+971501111111')));
          expect(error.rawData, isNull);
          expect(error.originalBackendMessage, isNull);
        }
      }
    },
  );
  test(
    'Safe field validation remains actionable without echoing arbitrary field names',
    () {
      final error = ApiException.fromDioError(
        DioException(
          requestOptions: RequestOptions(path: 'auth/me/'),
          response: Response(
            requestOptions: RequestOptions(path: 'auth/me/'),
            statusCode: 400,
            data: {
              'full_name': ['This field is required.'],
              'SyntheticPatient': ['Synthetic private note'],
            },
          ),
        ),
      );
      expect(error.getFieldError('full_name'), 'This field is required.');
      expect(error.message, isNot(contains('SyntheticPatient')));
      expect(error.message, isNot(contains('Synthetic private note')));
      expect(
        error.fieldErrors?.containsKey('SyntheticPatient') ?? false,
        isFalse,
      );
    },
  );
  test(
    'Maps reject spoofed external hosts and encode source identifiers as query values',
    () {
      expect(
        MapsLauncher.verifiedPlaceUri(
          googleMapsUrl: 'https://google.com.evil.example.test/maps',
        ),
        isNull,
      );
      final uri = MapsLauncher.verifiedPlaceUri(
        placeId: 'fixture&redirect=https://other.example.test',
      );
      expect(uri!.host, 'www.google.com');
      expect(
        uri.queryParameters['query'],
        'fixture&redirect=https://other.example.test',
      );
    },
  );
  test(
    'Media preflight accepts genuine bytes with the correct MIME and rejects disguised content',
    () async {
      final dir = Directory.systemTemp.createTempSync('aw-security-media-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final good = File('${dir.path}/Synthetic private filename.png')
        ..writeAsBytesSync(
          File('assets/images/app_launcher_icon.png').readAsBytesSync(),
        );
      expect((await MediaFilePolicy.inspect(good.path)).mimeType, 'image/png');
      final bad = File('${dir.path}/not-an-image.png')
        ..writeAsStringSync('<script>synthetic</script>');
      await expectLater(
        MediaFilePolicy.inspect(bad.path),
        throwsA(isA<ApiException>()),
      );
      final big = File('${dir.path}/oversized.png');
      final handle = big.openSync(mode: FileMode.write);
      handle.truncateSync(5 * 1024 * 1024 + 1);
      handle.closeSync();
      await expectLater(
        MediaFilePolicy.inspect(big.path),
        throwsA(isA<ApiException>()),
      );
      final built = await MediaPayloadBuilder(
        MediaUploadService(),
      ).build({'logo': good.path}, fileKeys: ['logo']);
      expect(built, isA<FormData>());
      final file = (built as FormData).files.single.value;
      expect(file.filename, 'upload.png');
      expect(file.contentType!.mimeType, 'image/png');
    },
  );
  test(
    'Account switching during image preparation prevents the old catalog create from being sent',
    () async {
      final upload = _Upload();
      final api = _Api(postReply: (_) async => {});
      final repo = ClinicCatalogRepository(
        apiClient: api,
        mediaUploadService: upload,
      );
      final pending = expectLater(
        repo.createPractitioner({'avatar': 'fixture-picked.png'}),
        throwsA(isA<SessionChangedException>()),
      );
      AuthState().logout();
      upload.gate.complete({
        'id': 'fixture-asset',
        'url': 'https://cdn.example.test/new.png',
      });
      await pending;
      expect(api.posts, isEmpty);
    },
  );
  testWidgets(
    'Cached identity cannot enter a portal before live session validation',
    (tester) async {
      await tokens.saveUser(_user('A'));
      AuthState().login(name: 'Fixture A', phone: '+971501111111');
      final gate = Completer<Object>();
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            authRepository: AuthRepository(
              apiClient: _Api(getReply: (_) => gate.future),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1600));
      expect(find.byType(SplashScreen), findsOneWidget);
      gate.completeError(
        const ApiException(message: 'Synthetic revoked session'),
      );
      await tester.pump();
      expect(AuthState().isLoggedIn, isFalse);
      expect(tokens.currentAccessToken, isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'An old startup validation failure cannot log out a newer identity',
    (tester) async {
      await tokens.saveUser(_user('A'));
      AuthState().login(name: 'Fixture A', phone: '+971501111111');
      final gate = Completer<Object>();
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            authRepository: AuthRepository(
              apiClient: _Api(getReply: (_) => gate.future),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1600));
      await tokens.saveUser(_user('B'));
      AuthState().login(name: 'Fixture B', phone: '+971501111112');
      gate.completeError(
        const ApiException(message: 'Synthetic old-session failure'),
      );
      await tester.pump();
      expect(AuthState().isLoggedIn, isTrue);
      expect(AuthState().userName, 'Fixture B');
      expect(tokens.getUser()!['id'], 'B');
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Logout destroys private routes and dialogs in the real app root',
    (tester) async {
      AuthState().login(name: 'Fixture A', phone: '+971501111111');
      await tester.pumpWidget(
        const AestheticWayApp(homeScreen: Scaffold(body: Text('Fixture root'))),
      );
      final ctx = tester.element(find.text('Fixture root'));
      unawaited(
        Navigator.of(ctx).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                const Scaffold(body: Text('Private Patient A details')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Private Patient A details'), findsOneWidget);
      AuthState().logout();
      await tester.pumpAndSettle();
      expect(find.text('Private Patient A details'), findsNothing);
      expect(find.text('Fixture root'), findsOneWidget);
    },
  );
  testWidgets(
    'Temporary administrator credentials are hidden until explicitly revealed',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAdminCredentials(
                  context,
                  result: {
                    'admin_user': {
                      'phone': '+971501111111',
                      'temporary_password': 'fixture-temporary-secret',
                    },
                  },
                ),
                child: const Text('Open fixture'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open fixture'));
      await tester.pumpAndSettle();
      expect(find.text('fixture-temporary-secret'), findsNothing);
      await tester.tap(find.byTooltip('Reveal temporary password'));
      await tester.pump();
      expect(find.text('fixture-temporary-secret'), findsOneWidget);
    },
  );
}
