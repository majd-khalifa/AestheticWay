import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/services/local_media_cache.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/account_deletion_screen.dart';
import 'package:aesthetic_way/features/treatments/data/category_repository.dart';
import 'package:aesthetic_way/features/treatments/data/category_request_repository.dart';
import 'package:aesthetic_way/features/treatments/presentation/category_requests_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_categories_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/widgets/clinic_treatment_editor.dart';
import 'support/patient_visual_harness.dart';

const _category = {
  'id': '11111111-1111-4111-8111-111111111111',
  'name_en': 'QA taxonomy',
  'name_ar': 'تصنيف اختبار',
  'slug': 'qa-taxonomy',
  'display_order': 7,
  'is_active': true,
};
const _request = {
  'id': '22222222-2222-4222-8222-222222222222',
  'name_en': 'QA category request',
  'name_ar': 'طلب تصنيف اختبار',
  'clinic_name': 'Local QA fixture',
  'status': 'pending',
};
ResponseBody _body(Object? data, [int status = 200]) => ResponseBody.fromString(
  data == null ? '' : jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);
Object _page(List<Object> rows, {String? next, int? count}) => {
  'count': count ?? rows.length,
  'next': next,
  'results': rows,
};
Object _error(String code) => {
  'error': {
    'code': code,
    'message': 'Server body must not leak any sensitive input',
  },
};

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final FutureOr<ResponseBody> Function(RequestOptions) respond;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    return await respond(options);
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _identity(String role, {String id = 'local-qa'}) async {
  await TokenStorage().saveTokens(
    accessToken: 'qa-access',
    refreshToken: 'qa-refresh',
  );
  await TokenStorage().saveUser({'id': id, 'phone': '', 'role': role});
  AuthState().login(name: 'Local QA', phone: id, role: role);
}

Future<void> _render(
  WidgetTester tester,
  Widget screen, {
  bool dark = false,
  bool ar = false,
}) async {
  await LocaleService().setLanguage(
    ar ? AppLanguage.arabic : AppLanguage.english,
  );
  await tester.binding.setSurfaceSize(const Size(430, 1000));
  await tester.pumpWidget(
    MaterialApp(
      theme: patientVisualTheme(dark: dark),
      builder: (_, child) => Directionality(
        textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
        child: RepaintBoundary(
          key: const ValueKey('integration-render'),
          child: child!,
        ),
      ),
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  const dir = String.fromEnvironment('FINAL_INTEGRATION_CAPTURE_DIR');
  if (dir.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('integration-render')),
  );
  await tester.runAsync(() async {
    final pixels = await boundary.toImage(pixelRatio: 1);
    final bytes = await pixels.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$dir/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    pixels.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  final api = ApiClient();
  late HttpClientAdapter original;
  late _Adapter adapter;
  void use(FutureOr<ResponseBody> Function(RequestOptions) reply) {
    adapter = _Adapter(reply);
    api.dio.httpClientAdapter = adapter;
  }

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    original = api.dio.httpClientAdapter;
    api.updateBaseUrl('https://fixture.invalid/api/v1/');
    await TokenStorage().clear();
    AuthState().logout();
    await _identity('clinic_admin');
    await LocaleService().setLanguage(AppLanguage.english);
  });
  tearDown(() async {
    api.dio.httpClientAdapter = original;
    await TokenStorage().clear();
    AuthState().logout();
    api.updateBaseUrl(ApiConfig.defaultProductionBaseUrl);
    ApiConfig.resetBaseUrl();
  });
  test(
    '1f1e4bf clinic request uses only bilingual names and paged own-clinic reads',
    () async {
      use(
        (o) => o.method == 'GET'
            ? _body(_page([_request], next: '?page=2', count: 21))
            : _body(_request, 201),
      );
      final repo = CategoryRequestRepository();
      final rows = await repo.list(page: 1);
      expect(rows.single.status, 'pending');
      expect(
        adapter.requests.single.path,
        CategoryRequestRepository.clinicPath,
      );
      expect(adapter.requests.single.queryParameters, {
        'page': 1,
        'page_size': 20,
      });
      await repo.submit(nameEn: ' QA ', nameAr: ' اختبار ');
      expect(adapter.requests.last.method, 'POST');
      expect(adapter.requests.last.data, {
        'name_en': 'QA',
        'name_ar': 'اختبار',
      });
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer qa-access',
      );
      expect(adapter.requests.last.contentType, contains('application/json'));
    },
  );
  test(
    'admin CRUD has its own route, preserves server slug and archives through PATCH',
    () async {
      await _identity('super_admin');
      use(
        (o) => o.method == 'GET'
            ? _body(_page([_category]))
            : o.method == 'DELETE'
            ? _body(null, 204)
            : _body({..._category, 'is_active': false}),
      );
      final repo = CategoryRepository();
      expect(
        (await repo.getAdminCategories(page: 2)).single.slug,
        'qa-taxonomy',
      );
      final saved = await repo.saveAdminCategory(
        id: _category['id'] as String,
        nameEn: ' Renamed ',
        nameAr: ' معدّل ',
        displayOrder: 9,
        isActive: false,
      );
      expect(saved.isActive, isFalse);
      final request = adapter.requests.last;
      expect(request.method, 'PATCH');
      expect(
        request.path,
        '${CategoryRepository.adminPath}${_category['id']}/',
      );
      expect(request.data, {
        'name_en': 'Renamed',
        'name_ar': 'معدّل',
        'display_order': 9,
        'is_active': false,
      });
      for (final forbidden in ['slug', 'icon', 'clinic', 'clinic_id']) {
        expect((request.data as Map).containsKey(forbidden), isFalse);
      }
      await repo.saveAdminCategory(
        nameEn: 'New',
        nameAr: '',
        displayOrder: 0,
        isActive: true,
      );
      expect(adapter.requests.last.method, 'POST');
      await repo.deleteAdminCategory(_category['id'] as String);
      expect(adapter.requests.last.method, 'DELETE');
    },
  );
  test(
    'admin moderation uses status query and exact rejection_reason payload',
    () async {
      await _identity('super_admin');
      use(
        (o) => o.method == 'GET'
            ? _body(_page([_request]))
            : _body({
                ..._request,
                'status': 'approved',
                'resolved_category_id': _category['id'],
              }),
      );
      final repo = CategoryRequestRepository();
      await repo.list(admin: true, status: 'pending', page: 2);
      expect(adapter.requests.single.queryParameters, {
        'page': 2,
        'page_size': 20,
        'status': 'pending',
      });
      expect(
        (await repo.review(_request['id']!, approve: true)).resolvedCategoryId,
        _category['id'],
      );
      expect(
        adapter.requests.last.path,
        '${CategoryRequestRepository.adminPath}${_request['id']}/approve/',
      );
      expect(adapter.requests.last.data, isEmpty);
      await repo.review(
        _request['id']!,
        approve: false,
        reason: ' Duplicate taxonomy ',
      );
      expect(adapter.requests.last.data, {
        'rejection_reason': 'Duplicate taxonomy',
      });
      expect(adapter.requests.last.path, endsWith('/reject/'));
    },
  );
  test(
    'patient/clinic cannot invoke admin category APIs; patient cannot request taxonomy',
    () async {
      use((_) => throw StateError('No transport allowed'));
      for (final role in ['patient', 'clinic_admin', 'clinic_staff']) {
        await _identity(role);
        await expectLater(
          CategoryRepository().getAdminCategories(),
          throwsA(isA<ApiException>()),
        );
        await expectLater(
          CategoryRepository().saveAdminCategory(
            nameEn: 'x',
            nameAr: '',
            displayOrder: 0,
            isActive: true,
          ),
          throwsA(isA<ApiException>()),
        );
        await expectLater(
          CategoryRepository().deleteAdminCategory('id'),
          throwsA(isA<ApiException>()),
        );
        await expectLater(
          CategoryRequestRepository().review('id', approve: true),
          throwsA(isA<ApiException>()),
        );
      }
      await _identity('patient');
      await expectLater(
        CategoryRequestRepository().submit(nameEn: 'x', nameAr: ''),
        throwsA(isA<ApiException>()),
      );
      expect(adapter.requests, isEmpty);
    },
  );
  for (final code in [
    'CATEGORY_ALREADY_EXISTS',
    'DUPLICATE_CATEGORY_REQUEST',
    'CATEGORY_IN_USE',
    'LAST_SUPER_ADMIN',
    'SOLE_CLINIC_ADMIN',
  ]) {
    test(
      '$code retains safe structured meaning without raw backend input',
      () async {
        use(
          (_) => _body(
            _error(code),
            code == 'CATEGORY_IN_USE' || code == 'DUPLICATE_CATEGORY_REQUEST'
                ? 409
                : 400,
          ),
        );
        try {
          await api.post('qa/');
          fail('Expected rejection');
        } on ApiException catch (e) {
          expect(e.errorCode, code);
          expect(e.message, isNot(contains('sensitive')));
          expect(e.rawData, isNull);
          expect(e.originalBackendMessage, isNull);
        }
      },
    );
  }
  for (final role in ['patient', 'clinic_admin', 'super_admin']) {
    test(
      '$role confirmed deletion sends OTP + refresh and clears identity/private media',
      () async {
        await _identity(role);
        use(
          (o) => _body(
            o.path.endsWith('request/')
                ? {'success': true, 'expires_in': 600, 'resend_cooldown': 60}
                : {'success': true},
          ),
        );
        final repo = AuthRepository();
        final mediaEpoch = LocalMediaCache().epoch;
        expect(
          LocalMediaCache().remember(
            localPath: 'test/fixtures/clinic_media/short_showcase.mp4',
            entityKey: 'private-qa-media',
          ),
          isTrue,
        );
        final challenge = await repo.requestAccountDeletion();
        expect(challenge['expires_in'], 600);
        expect(adapter.requests.single.data, isEmpty);
        await repo.confirmAccountDeletion(' 123456 ');
        expect(adapter.requests.last.path, 'auth/me/deletion/confirm/');
        expect(adapter.requests.last.data, {
          'code': '123456',
          'refresh_token': 'qa-refresh',
        });
        expect(TokenStorage().currentAccessToken, isNull);
        expect(TokenStorage().currentRefreshToken, isNull);
        expect(TokenStorage().getUser(), isNull);
        expect(AuthState().isLoggedIn, isFalse);
        expect(LocalMediaCache().epoch, greaterThan(mediaEpoch));
        expect(LocalMediaCache().lookup(entityKey: 'private-qa-media'), isNull);
      },
    );
  }
  for (final reason in [
    'invalid',
    'expired',
    'LAST_SUPER_ADMIN',
    'SOLE_CLINIC_ADMIN',
    'network',
    'false-success',
  ]) {
    test(
      'deletion $reason does not clear the account or retry automatically',
      () async {
        use((o) {
          if (reason == 'network') {
            throw DioException(
              requestOptions: o,
              type: DioExceptionType.connectionError,
            );
          }
          if (reason == 'false-success') return _body({'success': false});
          if (reason == 'invalid' || reason == 'expired') {
            return _body({
              'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'Validation failed',
                'fields': {
                  'code': [
                    reason == 'expired'
                        ? 'Verification code has expired.'
                        : 'Invalid verification code.',
                  ],
                },
              },
            }, 400);
          }
          return _body({
            'success': false,
            'code': reason,
            'detail': 'private clinic name',
          }, 400);
        });
        await expectLater(
          AuthRepository().confirmAccountDeletion('123456'),
          throwsA(isA<ApiException>()),
        );
        expect(adapter.requests, hasLength(1));
        expect(AuthState().isLoggedIn, isTrue);
        expect(TokenStorage().currentAccessToken, 'qa-access');
      },
    );
  }
  test(
    'late deletion success cannot clear a newly signed-in account',
    () async {
      final pending = Completer<ResponseBody>();
      use((_) => pending.future);
      final result = AuthRepository().confirmAccountDeletion('123456');
      await Future<void>.delayed(Duration.zero);
      await _identity('patient', id: 'replacement');
      pending.complete(_body({'success': true}));
      await expectLater(result, throwsA(anything));
      expect(AuthState().userPhone, 'replacement');
      expect(TokenStorage().currentAccessToken, 'qa-access');
    },
  );
  testWidgets(
    'request navigation preserves treatment names and decimal input without creating a category',
    (tester) async {
      use(
        (o) => _body(_page(o.path == ApiConfig.categories ? [_category] : [])),
      );
      ClinicPortalService().resetTestingState();
      await _render(tester, const Scaffold(body: ClinicTreatmentEditor()));
      await tester.enterText(
        find.byKey(const ValueKey('treatment-name-en')),
        'Retain draft',
      );
      await tester.enterText(
        find.byKey(const ValueKey('treatment-price')),
        '250.75',
      );
      await tester.ensureVisible(find.text('Browse all categories'));
      await tester.tap(find.text('Browse all categories'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Category requests / Request a category'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Retain draft'), findsOneWidget);
      expect(find.text('250.75'), findsOneWidget);
      expect(adapter.requests.where((r) => r.method != 'GET'), isEmpty);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'Admin category edit retains validation errors, then archives through a single PATCH',
    (tester) async {
      await _identity('super_admin');
      var writes = 0;
      use((o) {
        if (o.method == 'GET') return _body(_page([_category]));
        writes++;
        return writes == 1
            ? _body({
                'error': {
                  'code': 'VALIDATION_ERROR',
                  'message': 'failed',
                  'fields': {
                    'name_en': [
                      'A category with this English name already exists.',
                    ],
                  },
                },
              }, 400)
            : _body({..._category, 'is_active': false});
      });
      await _render(tester, const AdminCategoriesScreen());
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('category-name-en')),
        'Renamed draft',
      );
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('category-save')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('English name already exists'),
        findsOneWidget,
      );
      expect(find.text('Renamed draft'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('category-save')));
      await tester.pumpAndSettle();
      expect(writes, 2);
      expect(adapter.requests.where((r) => r.method == 'PATCH').last.data, {
        'name_en': 'Renamed draft',
        'name_ar': 'تصنيف اختبار',
        'display_order': 7,
        'is_active': false,
      });
      expect(
        adapter.requests.where((r) => r.method == 'PATCH').last.path,
        startsWith(CategoryRepository.adminPath),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'clinic rejected category proposal preserves both names, guards duplicates and stays pending',
    (tester) async {
      final pending = Completer<ResponseBody>();
      use((o) => o.method == 'GET' ? _body(_page([_request])) : pending.future);
      await _render(tester, const CategoryRequestsScreen());
      await tester.tap(find.byKey(const ValueKey('request-new-category')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('category-name-en')),
        'QA duplicate',
      );
      await tester.enterText(
        find.byKey(const ValueKey('category-name-ar')),
        'طلب مكرر',
      );
      await tester.tap(find.byKey(const ValueKey('category-save')));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('category-save')))
            .onPressed,
        isNull,
      );
      pending.complete(_body(_error('DUPLICATE_CATEGORY_REQUEST'), 409));
      await tester.pumpAndSettle();
      expect(find.text('QA duplicate'), findsOneWidget);
      expect(find.text('طلب مكرر'), findsOneWidget);
      expect(find.textContaining('already pending'), findsOneWidget);
      expect(adapter.requests.where((o) => o.method == 'POST'), hasLength(1));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Pending approval'), findsOneWidget);
      await _capture(tester, 'clinic_category_requests_light_en');
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'deletion form preserves OTP/intent after invalid response and shows one notice',
    (tester) async {
      final pending = Completer<ResponseBody>();
      use(
        (o) => o.path.endsWith('request/')
            ? _body({'success': true, 'expires_in': 600, 'resend_cooldown': 60})
            : pending.future,
      );
      await _render(tester, const AccountDeletionScreen());
      await tester.tap(find.byKey(const ValueKey('deletion-request-code')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('deletion-code')),
        '123456',
      );
      await tester.tap(find.byKey(const ValueKey('deletion-consent')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('deletion-confirm')),
      );
      await tester.tap(find.byKey(const ValueKey('deletion-confirm')));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('deletion-confirm')),
            )
            .onPressed,
        isNull,
      );
      pending.complete(
        _body({
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': 'failed',
            'fields': {
              'code': ['Invalid verification code.'],
            },
          },
        }, 400),
      );
      await tester.pumpAndSettle();
      expect(find.text('123456'), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('deletion-consent')),
            )
            .value,
        isTrue,
      );
      expect(
        find.textContaining('verification code is invalid'),
        findsOneWidget,
      );
      expect(AuthState().isLoggedIn, isTrue);
      expect(
        adapter.requests.where((r) => r.path.endsWith('confirm/')),
        hasLength(1),
      );
      await _capture(tester, 'account_deletion_light_en');
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      testWidgets(
        'admin category CRUD and request moderation render dark=$dark ar=$ar',
        (tester) async {
          await _identity('super_admin');
          var rejected = false;
          use((o) {
            if (o.path == CategoryRepository.adminPath) {
              return _body(_page([_category]));
            }
            if (o.method == 'GET') {
              return _body(_page(rejected ? [] : [_request]));
            }
            if (o.path.endsWith('reject/')) {
              rejected = true;
              return _body({..._request, 'status': 'rejected'});
            }
            return _body(_error('CATEGORY_IN_USE'), 409);
          });
          await _render(
            tester,
            const AdminCategoriesScreen(),
            dark: dark,
            ar: ar,
          );
          expect(find.text(ar ? 'تعديل' : 'Edit'), findsOneWidget);
          await _capture(
            tester,
            'admin_categories_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          await tester.tap(
            find.text(ar ? 'طلبات التصنيفات' : 'Category requests'),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(ar ? 'الطلبات المعلقة: 1' : 'Pending requests: 1'),
            findsOneWidget,
          );
          await _capture(
            tester,
            'admin_category_requests_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          await tester.tap(find.text(ar ? 'رفض' : 'Reject'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('category-rejection-reason')),
            'Please use existing taxonomy.',
          );
          await tester.tap(find.text(ar ? 'تأكيد' : 'Confirm'));
          await tester.pumpAndSettle();
          expect(
            adapter.requests
                .where((r) => r.path.endsWith('/reject/'))
                .single
                .data,
            {'rejection_reason': 'Please use existing taxonomy.'},
          );
          expect(
            find.text(ar ? 'الطلبات المعلقة: 0' : 'Pending requests: 0'),
            findsOneWidget,
          );
          await tester.pumpWidget(const SizedBox());
          await tester.binding.setSurfaceSize(null);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
