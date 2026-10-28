// Keep native credential-storage lifecycle in a dedicated widget-test isolate;
// repository contract tests separately exercise every success/failure role.
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/account_deletion_screen.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/login_screen.dart';

class _DeletionAdapter implements HttpClientAdapter {
  final paths = <String>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    paths.add(options.path);
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        if (options.path.endsWith('request/')) ...{
          'expires_in': 600,
          'resend_cooldown': 60,
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets(
    'confirmed server deletion clears private navigation and returns to Login',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      await TokenStorage().saveTokens(
        accessToken: 'local-qa-access',
        refreshToken: 'local-qa-refresh',
      );
      await TokenStorage().saveUser({'id': 'qa', 'role': 'patient'});
      AuthState().login(name: 'QA', phone: '', role: 'patient');
      final api = ApiClient();
      final original = api.dio.httpClientAdapter;
      final adapter = _DeletionAdapter();
      api.dio.httpClientAdapter = adapter;
      api.updateBaseUrl('https://fixture.invalid/api/v1/');
      addTearDown(() async {
        api.dio.httpClientAdapter = original;
        api.updateBaseUrl(ApiConfig.defaultProductionBaseUrl);
        ApiConfig.resetBaseUrl();
        await TokenStorage().clear();
        AuthState().logout();
      });
      await tester.binding.setSurfaceSize(const Size(430, 1000));
      await tester.pumpWidget(const MaterialApp(home: AccountDeletionScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('deletion-request-code')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('deletion-code')),
        '123456',
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('deletion-consent')),
        180,
        scrollable: find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.byKey(const ValueKey('deletion-consent')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('deletion-confirm')),
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('deletion-confirm')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('deletion-confirm')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('deletion-confirm')));
      await tester.pumpAndSettle();
      expect(adapter.paths, [
        'auth/me/deletion/request/',
        'auth/me/deletion/confirm/',
      ]);
      expect(find.byType(AccountDeletionScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(AuthState().isLoggedIn, isFalse);
      expect(TokenStorage().currentAccessToken, isNull);
      expect(TokenStorage().currentRefreshToken, isNull);
      expect(TokenStorage().getUser(), isNull);
      expect(
        Navigator.of(tester.element(find.byType(Scaffold).first)).canPop(),
        isFalse,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
}
