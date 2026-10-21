import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'dart:async';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_theme.dart';
import 'package:aesthetic_way/core/theme/patient_design.dart';
import 'package:aesthetic_way/core/theme/patient_theme_tokens.dart';
import 'package:aesthetic_way/core/widgets/patient_media_banner.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';
import 'package:aesthetic_way/features/auth/data/models/auth_models.dart';
import 'package:aesthetic_way/features/clinics/presentation/widgets/patient_clinic_gallery.dart';
import 'package:aesthetic_way/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/settle_preview_images.dart';

class _DelayedProfile implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  int calls = 0;
  Completer<UserModel> completion = Completer<UserModel>();
  @override
  Future<UserModel> getMe() {
    calls++;
    return completion.future;
  }
}

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'Patient visual tokens are scoped and preserve the global ${dark ? 'dark' : 'light'} portal theme',
      (tester) async {
        final theme = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
        Color? outside, inside;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) {
                outside = AppColors.bg(context);
                expect(
                  Theme.of(context).extension<PatientThemeTokens>(),
                  isNull,
                );
                return PatientDesign(
                  builder: (context) {
                    inside = AppColors.bg(context);
                    expect(
                      Theme.of(context).extension<PatientThemeTokens>(),
                      isNotNull,
                    );
                    expect(
                      PatientDesign.heading(context).fontFamily,
                      'PatientDisplay',
                    );
                    return const SizedBox();
                  },
                );
              },
            ),
          ),
        );
        expect(
          outside,
          dark ? AppColors.backgroundDeep : AppColors.lightBackground,
        );
        expect(
          inside,
          dark ? const Color(0xFF080F1A) : const Color(0xFFFBF9F5),
        );
      },
    );
  }
  testWidgets(
    'Real clinic gallery frames decode, thumbnail selection changes the primary image, missing media stays compact',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              child: PatientClinicGallery(
                images: [
                  'assets/images/onboarding/onboarding_1.jpeg',
                  'assets/images/onboarding/onboarding_2.webp',
                ],
              ),
            ),
          ),
        ),
      );
      await settlePreviewImages(tester);
      expect(find.text('1/2'), findsOneWidget);
      expect(
        tester.getSize(find.byType(PatientMediaBanner).first).height,
        closeTo(350 * 9 / 16, .1),
      );
      await tester.tap(find.bySemanticsLabel('Photo 2'));
      await tester.pumpAndSettle();
      await settlePreviewImages(tester);
      expect(find.text('2/2'), findsOneWidget);
      final actual = tester.widget<PatientMediaBanner>(
        find.byType(PatientMediaBanner).first,
      );
      expect(actual.source, 'assets/images/onboarding/onboarding_2.webp');
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PatientClinicGallery(images: [])),
        ),
      );
      expect(find.byType(Image), findsNothing);
      expect(
        tester.getSize(find.byType(PatientClinicGallery)).height,
        inInclusiveRange(48, 76),
      );
      expect(find.byType(PatientMediaFallback), findsOneWidget);
    },
  );
  testWidgets(
    'Profile refresh has immediate progress and coalesces duplicate taps',
    (tester) async {
      unawaited(LocaleService().setLanguage(AppLanguage.english));
      AuthState().login(name: 'Test account', phone: '+971501234567');
      final repo = _DelayedProfile();
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            onNavigateToRequests: () {},
            authRepository: repo,
          ),
        ),
      );
      expect(repo.calls, 1);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      final refresh = tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh;
      unawaited(refresh());
      unawaited(refresh());
      expect(repo.calls, 1);
      repo.completion.complete(
        UserModel.fromJson({
          'id': 'fixture',
          'full_name': 'Test account',
          'role': 'patient',
          'phone': '',
        }),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      repo.completion = Completer<UserModel>();
      await tester.tap(find.byIcon(Icons.refresh_rounded).first);
      await tester.tap(find.byIcon(Icons.refresh_rounded).first);
      expect(repo.calls, 2);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      repo.completion.complete(
        UserModel.fromJson({
          'id': 'fixture',
          'full_name': 'Test account',
          'role': 'patient',
          'phone': '',
        }),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
