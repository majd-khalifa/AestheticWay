import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/utils/international_phone.dart';
import 'package:aesthetic_way/core/widgets/luxury_phone_input_field.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';
import 'package:aesthetic_way/features/auth/data/models/auth_models.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/register_screen.dart';
import 'support/patient_visual_harness.dart';

class Wire implements HttpClientAdapter {
  Wire(this.reply);
  final FutureOr<ResponseBody> Function(RequestOptions) reply;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? cancel,
  ) async {
    requests.add(o);
    return reply(o);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody body(int status, Object data) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);
ApiException rejection(int status, Object data) => ApiException.fromDioError(
  DioException(
    requestOptions: RequestOptions(path: 'auth/register/'),
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: RequestOptions(path: 'auth/register/'),
      statusCode: status,
      data: data,
    ),
  ),
);
final samples =
    (jsonDecode(
              File(
                'test/fixtures/international_phone_examples.json',
              ).readAsStringSync(),
            )['countries']
            as List)
        .cast<Map<String, dynamic>>();
String example(String iso) =>
    samples.firstWhere((r) => r['iso'] == iso)['e164'] as String;

class ControlledRegistration implements AuthRepository {
  final pending = Completer<RegisterResponse>();
  int calls = 0;
  String? submittedPhone;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<RegisterResponse> register({
    required String fullName,
    required String phone,
    required String password,
    String? email,
    String? referralCode,
  }) {
    calls++;
    submittedPhone = phone;
    return pending.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    AuthState().logout();
    await LocaleService().setLanguage(AppLanguage.english);
  });
  Wire wire(FutureOr<ResponseBody> Function(RequestOptions) reply) {
    final api = ApiClient(), old = ApiClient().dio.httpClientAdapter;
    final adapter = Wire(reply);
    api.dio.httpClientAdapter = adapter;
    addTearDown(() => api.dio.httpClientAdapter = old);
    return adapter;
  }

  test(
    'all available country selectors normalize and validate standard international and national examples',
    () {
      expect(samples.length, kSupportedDialCodes.length);
      for (final row in samples) {
        final country = IsoCode.values.byName(row['iso'] as String);
        final e164 = row['e164'] as String;
        expect(
          LuxuryPhoneInputField.extractCountry(e164).isoCode,
          country,
          reason:
              'Shared calling codes must resolve the actual numbering region',
        );
        expect(
          InternationalPhone.normalize(e164, country: country),
          e164,
          reason: country.name,
        );
        expect(
          InternationalPhone.normalize(row['national'], country: country),
          e164,
          reason: country.name,
        );
        expect(
          InternationalPhone.issue(e164, country: country),
          isNull,
          reason: country.name,
        );
      }
    },
  );
  test(
    'Arabic/Persian digits, explicit exit codes and significant Italian zero remain canonical',
    () {
      expect(
        InternationalPhone.normalize('٠٩٤٤٥٦٧٨٩٠', country: IsoCode.SY),
        '+963944567890',
      );
      expect(
        InternationalPhone.normalize('۰۹۴۴۵۶۷۸۹۰', country: IsoCode.SY),
        '+963944567890',
      );
      expect(InternationalPhone.normalize('00963 944 567890'), '+963944567890');
      expect(InternationalPhone.normalize('+39 06 69812345'), '+390669812345');
      expect(InternationalPhone.issue('+963123'), isNotNull);
      expect(
        InternationalPhone.issue('+963not-a-number'),
        PhoneNumberIssue.format,
      );
      expect(
        InternationalPhone.issue('+963${'9' * 18}'),
        PhoneNumberIssue.length,
      );
    },
  );
  for (final arabic in [false, true]) {
    for (final dark in [false, true]) {
      testWidgets(
        'country selection and complete German paste are lossless ar=$arabic dark=$dark',
        (tester) async {
          await LocaleService().setLanguage(
            arabic ? AppLanguage.arabic : AppLanguage.english,
          );
          final controller = TextEditingController();
          addTearDown(controller.dispose);
          final form = GlobalKey<FormState>();
          await tester.pumpWidget(
            MaterialApp(
              theme: patientVisualTheme(dark: dark),
              home: Scaffold(
                body: Form(
                  key: form,
                  child: LuxuryPhoneInputField(
                    controller: controller,
                    isRequired: true,
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('+971'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(TextField),
            ),
            'Syria',
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.widgetWithText(ListTile, arabic ? 'سوريا' : 'Syria'),
          );
          await tester.pumpAndSettle();
          expect(find.text('+963'), findsOneWidget);
          await tester.enterText(find.byType(TextFormField), '٠٩٤٤٥٦٧٨٩٠');
          expect(controller.text, '+963944567890');
          expect(form.currentState!.validate(), isTrue);
          tester.testTextInput.updateEditingValue(
            const TextEditingValue(
              text: '٠٩٤٤٥٦٧٨٩٠',
              selection: TextSelection.collapsed(offset: 4),
            ),
          );
          await tester.pump();
          expect(
            tester
                .widget<EditableText>(find.byType(EditableText))
                .controller
                .selection
                .extentOffset,
            4,
            reason: 'Normalizing Arabic digits must preserve the edit position',
          );
          final german = example('DE');
          await tester.enterText(find.byType(TextFormField), german);
          await tester.pump();
          expect(controller.text, german);
          expect(find.text('+49'), findsOneWidget);
          expect(form.currentState!.validate(), isTrue);
          final input = tester.widget<TextFormField>(
            find.byType(TextFormField),
          );
          expect(input.controller!.text.length, greaterThan(10));
          expect(
            find.byType(EditableText).evaluate().single.widget is EditableText,
            isTrue,
          );
          expect(
            tester
                .widget<EditableText>(find.byType(EditableText))
                .textDirection,
            TextDirection.ltr,
          );
          await tester.enterText(find.byType(TextFormField), '9' * 19);
          await tester.pump();
          expect(input.controller!.text, '9' * 19);
          expect(form.currentState!.validate(), isFalse);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  test(
    'real registration wire uses canonical Syrian phone and required normalized email, acknowledges only 201',
    () async {
      final adapter = wire(
        (o) => body(201, {
          'user_id': '00000000-0000-4000-8000-000000000001',
          'message': 'Account created. Please verify your email address.',
          'expires_in': 300,
        }),
      );
      final result = await AuthRepository().register(
        fullName: 'Synthetic QA',
        phone: example('SY'),
        password: 'Synthetic!Qa917x',
        email: ' QA@EXAMPLE.TEST ',
      );
      expect(result.userId, isNotEmpty);
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, ApiConfig.register);
      expect(request.data['phone'], example('SY'));
      expect(request.data['email'], 'qa@example.test');
      expect((request.data as Map).containsKey('role'), isFalse);
      expect((request.data as Map).containsKey('referral_code'), isFalse);
      expect(TokenStorage().currentAccessToken, isNull);
    },
  );
  test('invalid local registration input never sends a request', () async {
    final adapter = wire((o) => body(201, {}));
    for (final args in [
      (phone: '+963123', email: 'qa@example.test'),
      (phone: example('SY'), email: ''),
      (phone: example('SY'), email: 'invalid'),
    ]) {
      await expectLater(
        AuthRepository().register(
          fullName: 'Synthetic QA',
          phone: args.phone,
          password: 'Synthetic!Qa917x',
          email: args.email,
        ),
        throwsA(isA<ApiException>()),
      );
    }
    expect(adapter.requests, isEmpty);
  });
  test(
    'actual HTTP400 validation retains status/code/field names without retaining the response body',
    () async {
      wire(
        (o) => body(400, {
          'error': {
            'code': 'VALIDATION_ERROR',
            'fields': {
              'phone': ['An account with this phone number already exists.'],
              'email': ['An account with this email already exists.'],
            },
          },
        }),
      );
      try {
        await AuthRepository().register(
          fullName: 'Synthetic QA',
          phone: example('SY'),
          password: 'Synthetic!Qa917x',
          email: 'qa@example.test',
        );
        fail('A rejected request must not succeed');
      } on ApiException catch (error) {
        expect(error.statusCode, 400);
        expect(error.errorCode, 'VALIDATION_ERROR');
        expect(error.fieldErrors!.keys, unorderedEquals(['phone', 'email']));
        expect(error.getFieldError('phone'), contains('already exists'));
        expect(error.rawData, isNull);
        expect(error.originalBackendMessage, isNull);
      }
    },
  );
  test(
    'connection failure and timeout have distinct localized safe meanings',
    () async {
      for (final arabic in [false, true]) {
        await LocaleService().setLanguage(
          arabic ? AppLanguage.arabic : AppLanguage.english,
        );
        final messages = <String>[];
        for (final type in [
          DioExceptionType.connectionError,
          DioExceptionType.receiveTimeout,
        ]) {
          final error = ApiException.fromDioError(
            DioException(
              requestOptions: RequestOptions(path: 'auth/register/'),
              type: type,
              error: 'synthetic-secret-must-not-escape',
            ),
          );
          expect(error.message, isNot(contains('synthetic-secret')));
          expect(error.statusCode, isNull);
          expect(error.rawData, isNull);
          messages.add(error.message);
        }
        expect(messages.toSet().length, 2);
      }
    },
  );
  test(
    'a 200 or missing user acknowledgment cannot produce registration success',
    () async {
      var status = 200;
      final adapter = wire((o) => body(status, {}));
      for (final code in [200, 201]) {
        status = code;
        await expectLater(
          AuthRepository().register(
            fullName: 'Synthetic QA',
            phone: example('SY'),
            password: 'Synthetic!Qa917x',
            email: 'qa@example.test',
          ),
          throwsA(isA<ApiException>()),
        );
      }
      expect(adapter.requests.length, 2);
    },
  );
  for (final arabic in [false, true]) {
    test(
      'known registration field errors remain distinct without echoing values ar=$arabic',
      () async {
        await LocaleService().setLanguage(
          arabic ? AppLanguage.arabic : AppLanguage.english,
        );
        final invalid = rejection(400, {
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': 'One or more fields failed validation.',
            'fields': {
              'phone': ['Invalid phone number: +963123'],
              'email': ['Enter a valid email address.'],
            },
          },
        });
        final duplicate = rejection(400, {
          'error': {
            'code': 'VALIDATION_ERROR',
            'fields': {
              'phone': ['An account with this phone number already exists.'],
              'email': ['An account with this email already exists.'],
            },
          },
        });
        expect(invalid.statusCode, 400);
        expect(invalid.errorCode, 'VALIDATION_ERROR');
        expect(
          invalid.getFieldError('phone'),
          isNot(duplicate.getFieldError('phone')),
        );
        expect(
          invalid.getFieldError('email'),
          isNot(duplicate.getFieldError('email')),
        );
        expect(invalid.message, isNot(contains('+963123')));
        expect(invalid.rawData, isNull);
        expect(invalid.originalBackendMessage, isNull);
        final unknown = rejection(400, {
          'error': {
            'fields': {
              'phone': ['private-unknown@example.test secret note'],
            },
          },
        });
        expect(unknown.message, isNot(contains('private-unknown')));
        expect(
          rejection(401, {'detail': 'private unknown'}).message,
          isNot(invalid.message),
        );
        expect(
          rejection(403, {'detail': 'private unknown'}).message,
          isNot(invalid.message),
        );
        expect(
          rejection(429, {'detail': 'Request was throttled.'}).statusCode,
          429,
        );
        expect(
          rejection(500, {'trace': 'private'}).message,
          isNot(contains('private')),
        );
      },
    );
  }
  testWidgets(
    'registration requires email before POST and preserves rejected input while guarding duplicate submission',
    (tester) async {
      final repository = ControlledRegistration();
      await tester.binding.setSurfaceSize(const Size(430, 1500));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: patientVisualTheme(dark: false),
          home: RegisterScreen(repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(5));
      await tester.enterText(fields.at(0), 'Synthetic QA');
      await tester.enterText(fields.at(1), example('SY'));
      await tester.enterText(fields.at(3), 'Synthetic!Qa917x');
      await tester.enterText(fields.at(4), 'Synthetic!Qa917x');
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      final submit = find.byType(SilverButton).first;
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      expect(find.text('Email address is required'), findsOneWidget);
      expect(repository.calls, 0);
      await tester.ensureVisible(fields.at(2));
      await tester.enterText(fields.at(2), 'qa@example.test');
      tester.testTextInput.hide();
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pump();
      await tester.tap(submit);
      await tester.pump();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      expect(tester.state<FormState>(find.byType(Form)).validate(), isTrue);
      expect(repository.calls, 1);
      expect(repository.submittedPhone, example('SY'));
      repository.pending.completeError(
        rejection(400, {
          'error': {
            'code': 'VALIDATION_ERROR',
            'fields': {
              'email': ['An account with this email already exists.'],
            },
          },
        }),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(fields.at(0)).controller!.text,
        'Synthetic QA',
      );
      expect(
        tester.widget<TextFormField>(fields.at(2)).controller!.text,
        'qa@example.test',
      );
      expect(
        find.text('An account with this email address already exists.'),
        findsWidgets,
      );
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
