import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/otp_screen.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/reset_password_screen.dart';
import 'onboarding_review_workflows_test.dart' show Adapter, body;
import 'support/patient_visual_harness.dart';

const phone = '+971501234567'; // Synthetic; every HTTP request is intercepted.

Future<void> mount(
  WidgetTester tester,
  Widget screen, {
  bool ar = false,
  bool dark = false,
  GlobalKey? boundary,
}) async {
  unawaited(
    LocaleService().setLanguage(ar ? AppLanguage.arabic : AppLanguage.english),
  );
  await tester.binding.setSurfaceSize(const Size(320, 800));
  await tester.pumpWidget(
    RepaintBoundary(
      key: boundary,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: patientVisualTheme(dark: dark),
        locale: Locale(ar ? 'ar' : 'en'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  const dir = String.fromEnvironment('OTP_RELEASE_CAPTURE_DIR');
  if (dir.isEmpty) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(dir).create(recursive: true);
    await File('$dir/$name.png').writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> finish(WidgetTester tester) async {
  AppSnackBar.dismissCurrent();
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 4));
  await tester.binding.setSurfaceSize(null);
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
  Adapter wire(FutureOr<ResponseBody> Function(RequestOptions) reply) {
    final api = ApiClient(), old = ApiClient().dio.httpClientAdapter;
    final adapter = Adapter(reply);
    api.dio.httpClientAdapter = adapter;
    addTearDown(() => api.dio.httpClientAdapter = old);
    return adapter;
  }

  for (final ar in [false, true]) {
    for (final dark in [false, true]) {
      for (final purpose in OtpPurpose.values) {
        testWidgets(
          'email OTP purpose ${purpose.name} ar=$ar dark=$dark at 320px/160%',
          (t) async {
            final adapter = wire(
              (_) => throw StateError('Rendering must not request an OTP'),
            );
            final key = GlobalKey();
            await mount(
              t,
              OtpScreen(
                purpose: purpose,
                targetContact: phone,
                userEmail: 'private@example.invalid',
              ),
              ar: ar,
              dark: dark,
              boundary: key,
            );
            expect(find.byType(TextFormField), findsNWidgets(6));
            expect(find.text(phone), findsNothing);
            expect(find.text('private@example.invalid'), findsNothing);
            expect(find.textContaining('Terminal'), findsNothing);
            expect(find.textContaining('SMS_PROVIDER'), findsNothing);
            expect(
              find.text(
                LocaleService().tr(
                  purpose == OtpPurpose.passwordReset
                      ? 'otp_reset_sub'
                      : 'otp_sub',
                ),
              ),
              findsOneWidget,
            );
            expect(adapter.requests, isEmpty);
            final instruction = find.text(
              LocaleService().tr(
                purpose == OtpPurpose.passwordReset
                    ? 'otp_reset_sub'
                    : 'otp_sub',
              ),
            );
            expect(
              t.renderObject<RenderParagraph>(instruction).didExceedMaxLines,
              isFalse,
            );
            expect(t.takeException(), isNull);
            await capture(
              t,
              key,
              'otp_${purpose.name}_${ar ? 'ar' : 'en'}_${dark ? 'dark' : 'light'}',
            );
            await finish(t);
          },
        );
      }
      testWidgets(
        'recovery email instructions and phone identifier ar=$ar dark=$dark',
        (t) async {
          final adapter = wire(
            (_) => body({'message': 'Legacy server wording: sent to phone'}),
          );
          final key = GlobalKey();
          await mount(
            t,
            const ForgotPasswordScreen(),
            ar: ar,
            dark: dark,
            boundary: key,
          );
          expect(find.text(LocaleService().tr('forgot_sub')), findsOneWidget);
          expect(find.textContaining('SMS'), findsNothing);
          expect(find.textContaining('WhatsApp'), findsNothing);
          expect(find.textContaining('واتساب'), findsNothing);
          expect(
            t
                .renderObject<RenderParagraph>(
                  find.text(LocaleService().tr('forgot_sub')),
                )
                .didExceedMaxLines,
            isFalse,
          );
          expect(t.takeException(), isNull);
          await capture(
            t,
            key,
            'recovery_${ar ? 'ar' : 'en'}_${dark ? 'dark' : 'light'}',
          );
          await t.enterText(find.byType(TextFormField).first, '501234567');
          final send = find.byType(SilverButton);
          await t.ensureVisible(send);
          await t.tap(send);
          await t.pumpAndSettle();
          expect(adapter.requests, hasLength(1));
          expect(adapter.requests.single.path, ApiConfig.forgotPassword);
          expect(adapter.requests.single.data, {'phone': phone});
          expect(find.byType(OtpScreen), findsOneWidget);
          expect(
            find.text(LocaleService().tr('otp_reset_requested')),
            findsOneWidget,
          );
          expect(
            find.text('Legacy server wording: sent to phone'),
            findsNothing,
          );
          expect(
            t.widget<OtpScreen>(find.byType(OtpScreen)).targetContact,
            phone,
          );
          expect(t.takeException(), isNull);
          await finish(t);
        },
      );
    }
    for (final purpose in OtpPurpose.values) {
      testWidgets(
        'email resend preserves purpose, identifier and cooldown ar=$ar ${purpose.name}',
        (t) async {
          final pending = Completer<ResponseBody>();
          final adapter = wire((_) => pending.future);
          await mount(
            t,
            OtpScreen(purpose: purpose, targetContact: phone),
            ar: ar,
          );
          expect(find.text(LocaleService().tr('resend_code')), findsNothing);
          await t.pump(const Duration(seconds: 61));
          await t.pump();
          final resend = find.text(LocaleService().tr('resend_code'));
          await t.ensureVisible(resend);
          await t.tap(resend);
          await t.pump(const Duration(milliseconds: 100));
          await t.tap(resend);
          await t.pump();
          expect(adapter.requests, hasLength(1));
          expect(adapter.requests.single.path, ApiConfig.resendOtp);
          expect(adapter.requests.single.data, {
            'phone': phone,
            'purpose': purpose.toApiPurpose(),
          });
          pending.complete(body({'expires_in': 600, 'resend_cooldown': 60}));
          await t.pumpAndSettle();
          expect(
            find.text(
              LocaleService().tr(
                purpose == OtpPurpose.passwordReset
                    ? 'otp_reset_requested'
                    : 'otp_email_resend',
              ),
            ),
            findsOneWidget,
          );
          expect(find.text(LocaleService().tr('resend_code')), findsNothing);
          expect(find.textContaining('إلى هاتفك'), findsNothing);
          await finish(t);
        },
      );
    }
    testWidgets(
      'failed email resend never announces success or bypasses API backpressure ar=$ar',
      (t) async {
        var fail = true;
        final adapter = wire((_) {
          final failure = body({
            'error': {
              'code': 'OTP_DELIVERY_FAILED',
              'message': 'Failed to deliver verification email',
            },
          }, 503);
          // Explicit service Retry-After keeps this deterministic on slow hosts.
          failure.headers['retry-after'] = ['120'];
          return fail
              ? failure
              : body({'expires_in': 600, 'resend_cooldown': 60});
        });
        await mount(
          t,
          const OtpScreen(
            purpose: OtpPurpose.registration,
            targetContact: phone,
          ),
          ar: ar,
        );
        await t.pump(const Duration(seconds: 61));
        await t.pump();
        final resend = find.text(LocaleService().tr('resend_code'));
        await t.ensureVisible(resend);
        await t.tap(resend);
        await t.pumpAndSettle();
        expect(adapter.requests, hasLength(1));
        expect(find.text(LocaleService().tr('otp_email_resend')), findsNothing);
        expect(find.text(LocaleService().tr('resend_code')), findsOneWidget);
        expect(find.byType(OtpScreen), findsOneWidget);
        fail = false;
        await t.tap(resend);
        await t.pumpAndSettle();
        // An explicit immediate retry still obeys the existing service cooldown.
        expect(adapter.requests, hasLength(1));
        expect(find.text(LocaleService().tr('otp_email_resend')), findsNothing);
        expect(
          find.text(
            ar
                ? 'يرجى الانتظار قليلاً قبل المحاولة مرة أخرى.'
                : 'Please wait a moment before trying again.',
          ),
          findsOneWidget,
        );
        await finish(t);
      },
    );
    testWidgets(
      'validation errors preserve six digits; reset request uses phone ar=$ar',
      (t) async {
        var accepted = false;
        final adapter = wire(
          (_) => accepted
              ? body({'message': 'OTP verified'})
              : body({
                  'error': {
                    'code': 'OTP_INVALID',
                    'message': 'Invalid OTP code',
                  },
                }, 422),
        );
        await mount(
          t,
          const OtpScreen(
            purpose: OtpPurpose.passwordReset,
            targetContact: phone,
          ),
          ar: ar,
        );
        final verify = find.byType(SilverButton);
        await t.ensureVisible(verify);
        await t.tap(verify);
        await t.pumpAndSettle();
        expect(adapter.requests, isEmpty);
        expect(
          find.text(
            ar
                ? 'يرجى إدخال كود التحقق المكون من 6 أرقام'
                : 'Please enter the 6-digit verification code',
          ),
          findsOneWidget,
        );
        for (var i = 0; i < 6; i++) {
          await t.enterText(find.byType(TextFormField).at(i), '${i + 1}');
        }
        await t.pumpAndSettle();
        expect(adapter.requests, hasLength(1));
        expect(adapter.requests.single.path, ApiConfig.verifyOtp);
        expect(adapter.requests.single.data, {
          'phone': phone,
          'otp_code': '123456',
          'purpose': 'password_reset',
        });
        expect(find.byType(ResetPasswordScreen), findsNothing);
        expect(
          find.text(
            ar
                ? 'رمز التحقق غير صحيح، يرجى التأكد وإعادة المحاولة'
                : 'Please check the verification code and try again.',
          ),
          findsOneWidget,
        );
        for (var i = 0; i < 6; i++) {
          expect(
            t
                .widget<TextFormField>(find.byType(TextFormField).at(i))
                .controller!
                .text,
            '${i + 1}',
          );
        }
        accepted = true;
        await t.ensureVisible(verify);
        await t.tap(verify);
        await t.pumpAndSettle();
        expect(adapter.requests, hasLength(2));
        expect(find.byType(ResetPasswordScreen), findsOneWidget);
        final reset = t.widget<ResetPasswordScreen>(
          find.byType(ResetPasswordScreen),
        );
        expect(reset.phone, phone);
        expect(reset.otpCode, '123456');
        expect(AuthState().isLoggedIn, isFalse);
        expect(t.takeException(), isNull);
        await finish(t);
      },
    );
  }
}
