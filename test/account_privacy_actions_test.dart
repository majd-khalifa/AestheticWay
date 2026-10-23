import 'dart:async';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/account_privacy_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  for (final ar in [false, true]) {
    testWidgets('public legal links and genuine deletion entry ar=$ar', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({});
      await LocaleService().setLanguage(
        ar ? AppLanguage.arabic : AppLanguage.english,
      );
      AuthState().login(name: 'QA', phone: '', role: 'patient');
      addTearDown(() => AuthState().logout());
      final calls = <Uri>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'launch') {
          calls.add(Uri.parse((call.arguments as Map)['url'] as String));
          return true;
        }
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
              child: const AccountPrivacyActions(),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('account-privacy-privacy')));
      await tester.pumpAndSettle();
      expect(calls.single.toString(), 'https://aestheticway.ae/privacy/');
      await tester.tap(find.byKey(const ValueKey('account-privacy-terms')));
      await tester.pumpAndSettle();
      expect(calls.last.toString(), 'https://aestheticway.ae/terms/');
      await tester.tap(find.byKey(const ValueKey('account-privacy-deletion')));
      await tester.pumpAndSettle();
      expect(calls, hasLength(2));
      expect(
        find.text(ar ? 'حذف الحساب نهائي' : 'Account deletion is permanent'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('deletion-request-code')),
        findsOneWidget,
      );
      expect(
        calls,
        hasLength(2),
      ); // No mailto or destructive API call on entry.
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'native launch shows immediate feedback, guards duplicate taps and recovers from failure',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      await LocaleService().setLanguage(AppLanguage.english);
      final pending = Completer<bool>();
      var launches = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'launch') {
          launches++;
          return pending.future;
        }
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AccountPrivacyActions())),
      );
      final link = find.byKey(const ValueKey('account-privacy-privacy'));
      await tester.tap(link);
      await tester.pump();
      expect(find.text('Opening…'), findsOneWidget);
      await tester.tap(link);
      await tester.pump();
      expect(launches, 1);
      pending.complete(false);
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not open the link'), findsOneWidget);
      expect(tester.widget<TextButton>(link).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );
}
