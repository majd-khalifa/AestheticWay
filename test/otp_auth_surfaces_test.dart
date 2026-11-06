import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/account_deletion_screen.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/register_screen.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/verify_registered_email_screen.dart';
import 'onboarding_review_workflows_test.dart' show Adapter, body;
import 'otp_email_release_test.dart' show mount, capture, finish;
import 'support/patient_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    AuthState().logout();
    await LocaleService().setLanguage(AppLanguage.english);
  });
  for (final ar in [false, true]) {
    for (final dark in [false, true]) {
      for (final entry in <String, Widget>{
        'registration': const RegisterScreen(),
        'reset': const ResetPasswordScreen(
          phone: '+971501234567',
          otpCode: '123456',
        ),
        'deletion': const AccountDeletionScreen(),
        'registered_email': const VerifyRegisteredEmailScreen(),
      }.entries) {
        testWidgets(
          '${entry.key} OTP surface ar=$ar dark=$dark at 320px/160%',
          (t) async {
            AuthState().login(name: 'Synthetic QA', phone: '', role: 'patient');
            final api = ApiClient(), old = ApiClient().dio.httpClientAdapter;
            final adapter = Adapter(
              (_) => body({
                'success': true,
                'expires_in': 600,
                'resend_cooldown': 60,
                'delivery_channel': 'email',
                'masked_destination': 's***@e***.invalid',
              }),
            );
            api.dio.httpClientAdapter = adapter;
            addTearDown(() => api.dio.httpClientAdapter = old);
            final key = GlobalKey();
            await mount(t, entry.value, ar: ar, dark: dark, boundary: key);
            expect(t.takeException(), isNull);
            expect(adapter.requests, isEmpty);
            if (entry.key == 'deletion') {
              final send = find.byKey(const ValueKey('deletion-request-code'));
              await t.scrollUntilVisible(
                send,
                160,
                scrollable: find
                    .descendant(
                      of: find.byType(ListView),
                      matching: find.byType(Scrollable),
                    )
                    .first,
              );
              await t.pumpAndSettle();
              await t.tap(send);
              await t.pumpAndSettle();
              expect(adapter.requests, hasLength(1));
              expect(adapter.requests.single.path, 'auth/me/deletion/request/');
              await t.scrollUntilVisible(
                find.textContaining('s***@e***.invalid'),
                160,
                scrollable: find
                    .descendant(
                      of: find.byType(ListView),
                      matching: find.byType(Scrollable),
                    )
                    .first,
              );
              await t.pumpAndSettle();
              expect(find.textContaining('s***@e***.invalid'), findsOneWidget);
              expect(
                find.textContaining(
                  ar ? 'لم يُؤكد الوصول' : 'Delivery is not confirmed',
                ),
                findsOneWidget,
              );
              await t.scrollUntilVisible(
                find.byKey(const ValueKey('deletion-code')),
                160,
                scrollable: find
                    .descendant(
                      of: find.byType(ListView),
                      matching: find.byType(Scrollable),
                    )
                    .first,
              );
              await t.pumpAndSettle();
              expect(
                find.byKey(const ValueKey('deletion-code')),
                findsOneWidget,
              );
            }
            if (entry.key == 'registered_email') {
              expect(
                find.byKey(const ValueKey('email-verification-request')),
                findsOneWidget,
              );
              expect(
                find.text(
                  ar ? 'توثيق البريد المسجل' : 'Verify registered email',
                ),
                findsOneWidget,
              );
            }
            expect(find.textContaining('SMS_PROVIDER'), findsNothing);
            expect(t.takeException(), isNull);
            await capture(
              t,
              key,
              '${entry.key}_${ar ? 'ar' : 'en'}_${dark ? 'dark' : 'light'}',
            );
            await finish(t);
            AuthState().logout();
          },
        );
      }
    }
  }
}
