import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/theme/app_theme.dart';
import 'package:aesthetic_way/core/widgets/ltr_text_field.dart';
import 'package:aesthetic_way/core/widgets/luxury_phone_input_field.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';
import 'package:aesthetic_way/features/profile/presentation/screens/profile_screen.dart';

class FakeProfileApiClient implements ApiClient {
  @override
  late Dio dio = Dio();

  @override
  void updateBaseUrl(String newBaseUrl) {}

  final Map<String, dynamic> Function(String path, Map<String, dynamic>? query) onGet;
  final Map<String, dynamic> Function(String path, dynamic data)? onPatch;
  final Map<String, dynamic> Function(String path, dynamic data)? onPost;

  FakeProfileApiClient({
    required this.onGet,
    this.onPatch,
    this.onPost,
  });

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final res = onGet(path, queryParameters);
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: res as T,
    );
  }

  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final res = onPatch != null ? onPatch!(path, data) : <String, dynamic>{};
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: res as T,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final res = onPost != null ? onPost!(path, data) : <String, dynamic>{};
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: res as T,
    );
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final res = onPatch != null ? onPatch!(path, data) : <String, dynamic>{};
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: res as T,
    );
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 204,
    );
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    LocaleService().setLanguage(AppLanguage.arabic);
    AuthState().logout();
  });

  group('Patient Profile Live API & AuthRepository Tests', () {
    test('AuthState starts clean with no hardcoded demo name or phone', () {
      final auth = AuthState();
      expect(auth.isLoggedIn, isFalse);
      expect(auth.userName, isEmpty);
      expect(auth.userPhone, isEmpty);
      expect(auth.userEmail, isEmpty);
      expect(auth.favoriteClinicIds, isEmpty);
    });

    test('AuthRepository getMe and updateMe hit /auth/me/ and sync AuthState', () async {
      String? lastGetPath;
      String? lastPatchPath;
      Map<String, dynamic>? lastPatchData;

      final fakeClient = FakeProfileApiClient(
        onGet: (path, _) {
          lastGetPath = path;
          return {
            'id': 'u-patient-1',
            'full_name': 'نورة المنصوري',
            'phone': '+971509876543',
            'email': 'noura@aestheticway.ae',
            'role': 'patient',
            'is_verified': true,
            'device_platform': 'ios',
            'created_at': '2026-09-01T10:00:00Z',
          };
        },
        onPatch: (path, data) {
          lastPatchPath = path;
          lastPatchData = Map<String, dynamic>.from(data as Map);
          return {
            'id': 'u-patient-1',
            'full_name': lastPatchData!['full_name'],
            'phone': lastPatchData!['phone'] ?? '+971509876543',
            'email': lastPatchData!['email'],
            'role': 'patient',
            'is_verified': true,
            'device_platform': 'ios',
            'created_at': '2026-09-01T10:00:00Z',
          };
        },
      );

      final repo = AuthRepository(apiClient: fakeClient);

      final user = await repo.getMe();
      expect(lastGetPath, 'auth/me/');
      expect(user.fullName, 'نورة المنصوري');
      expect(user.phone, '+971509876543');
      expect(user.email, 'noura@aestheticway.ae');
      expect(user.isVerified, isTrue);
      expect(AuthState().isLoggedIn, isTrue);
      expect(AuthState().userName, 'نورة المنصوري');
      expect(AuthState().isVerified, isTrue);

      final updated = await repo.updateMe(
        fullName: 'نورة المنصوري الهاشمي',
        email: 'Noura.Updated@AestheticWay.ae',
        phone: '0501112233',
      );
      expect(lastPatchPath, 'auth/me/');
      expect(lastPatchData!['full_name'], 'نورة المنصوري الهاشمي');
      expect(lastPatchData!['email'], 'noura.updated@aestheticway.ae');
      expect(lastPatchData!['phone'], '+971501112233');
      expect(updated.fullName, 'نورة المنصوري الهاشمي');
      expect(AuthState().userName, 'نورة المنصوري الهاشمي');
      expect(AuthState().userPhone, '+971501112233');

      // Clearing email sends null to respect unique_email_when_not_null constraint
      await repo.updateMe(
        fullName: 'نورة المنصوري الهاشمي',
        email: '   ',
      );
      expect(lastPatchData!['email'], isNull);
    });

    testWidgets('ProfileScreen loads live profile, uses LtrTextFormField for email/phone, and saves via PATCH', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Map<String, dynamic>? savedPayload;

      final fakeClient = FakeProfileApiClient(
        onGet: (path, _) => {
          'id': 'u-patient-2',
          'full_name': 'ريم الكعبي',
          'phone': '+971523334455',
          'email': 'reem@uae.ae',
          'role': 'patient',
          'is_verified': true,
          'created_at': '2026-09-15T08:00:00Z',
        },
        onPatch: (path, data) {
          savedPayload = Map<String, dynamic>.from(data as Map);
          return {
            'id': 'u-patient-2',
            'full_name': savedPayload!['full_name'],
            'phone': savedPayload!['phone'],
            'email': savedPayload!['email'],
            'role': 'patient',
            'is_verified': true,
            'created_at': '2026-09-15T08:00:00Z',
          };
        },
      );

      final repo = AuthRepository(apiClient: fakeClient);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ProfileScreen(
            onNavigateToRequests: () {},
            authRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify live user details are displayed
      expect(find.text('ريم الكعبي'), findsOneWidget);
      expect(find.text('+971523334455'), findsOneWidget);
      expect(find.text('reem@uae.ae'), findsOneWidget);

      // Open Edit Profile section
      await tester.tap(find.byKey(const Key('toggle_edit_profile_btn')));
      await tester.pumpAndSettle();

      // Verify phone and email fields are readOnly
      final phoneField = tester.widget<LuxuryPhoneInputField>(find.byType(LuxuryPhoneInputField));
      expect(phoneField.readOnly, isTrue);

      final emailField = tester.widget<LtrTextFormField>(find.byType(LtrTextFormField));
      expect(emailField.readOnly, isTrue);
      expect(find.byKey(const Key('profile_contact_readonly_note')), findsOneWidget);

      // Edit full_name
      await tester.enterText(
        find.byKey(const Key('profile_full_name_field')),
        'ريم الكعبي المحدثة',
      );

      // Tap Save Changes
      final saveBtn = find.widgetWithText(GestureDetector, 'حفظ التعديلات').first;
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(savedPayload, isNotNull);
      expect(savedPayload!['full_name'], 'ريم الكعبي المحدثة');
      expect(savedPayload!.containsKey('phone'), isFalse);
      expect(savedPayload!.containsKey('email'), isFalse);
      expect(find.text('ريم الكعبي المحدثة'), findsOneWidget);
    });

    testWidgets('ProfileScreen shows error state and recovers on Retry', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool shouldFail = true;
      final fakeClient = FakeProfileApiClient(
        onGet: (path, _) {
          if (shouldFail) {
            throw const ApiException(message: 'فشل الاتصال بالخادم', statusCode: 500);
          }
          return {
            'id': 'u-patient-3',
            'full_name': 'خالد السويدي',
            'phone': '+971556667788',
            'email': 'khaled@uae.ae',
            'role': 'patient',
            'is_verified': true,
          };
        },
      );

      final repo = AuthRepository(apiClient: fakeClient);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ProfileScreen(
            onNavigateToRequests: () {},
            authRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('فشل الاتصال بالخادم'), findsOneWidget);

      // Flip shouldFail and tap Retry
      shouldFail = false;
      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pumpAndSettle();

      expect(find.text('خالد السويدي'), findsOneWidget);
    });
  });
}
