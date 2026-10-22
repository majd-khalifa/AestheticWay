import 'package:aesthetic_way/main.dart';
import 'dart:async';
import 'dart:io';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/preferences/persistent_preference.dart';
import 'package:aesthetic_way/core/theme/theme_service.dart';
import 'package:aesthetic_way/core/widgets/patient_media_banner.dart';
import 'package:aesthetic_way/core/widgets/patient_media_placeholder.dart';
import 'package:aesthetic_way/core/widgets/preference_save_status.dart';
import 'package:aesthetic_way/features/clinics/presentation/widgets/patient_clinic_card.dart';
import 'package:aesthetic_way/features/clinics/presentation/widgets/patient_clinic_gallery.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/offers/presentation/widgets/patient_offer_card.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/practitioners/presentation/widgets/patient_practitioner_card.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/products/presentation/widgets/brand_product_media.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/patient_fixtures.dart';
import 'support/patient_visual_harness.dart';
import 'support/settle_preview_images.dart';

void main() {
  setUpAll(loadPatientVisualFonts);
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });
  test(
    'fresh storage and unsupported saved values default to English and Light',
    () async {
      for (final values in [
        <String, String>{},
        {
          LocaleService.storageKey: 'invalid',
          ThemeService.storageKey: 'invalid',
        },
      ]) {
        FlutterSecureStorage.setMockInitialValues(values);
        final locale = LocaleService.withStorage(const FlutterSecureStorage());
        final theme = ThemeService.withStorage(const FlutterSecureStorage());
        await Future.wait([locale.init(), theme.init()]);
        expect(locale.currentLanguage, AppLanguage.english);
        expect(theme.themeMode, ThemeMode.light);
        locale.dispose();
        theme.dispose();
      }
    },
  );
  for (final language in AppLanguage.values) {
    for (final mode in ThemeMode.values) {
      test(
        'cold restart restores ${language.code} and ${mode.name}, logout keeps preferences',
        () async {
          final locale = LocaleService.withStorage(
            const FlutterSecureStorage(),
          );
          final theme = ThemeService.withStorage(const FlutterSecureStorage());
          await locale.setLanguage(language);
          await theme.setThemeMode(mode);
          locale.dispose();
          theme.dispose();
          await TokenStorage().clear();
          final restartedLocale = LocaleService.withStorage(
            const FlutterSecureStorage(),
          );
          final restartedTheme = ThemeService.withStorage(
            const FlutterSecureStorage(),
          );
          await Future.wait([restartedLocale.init(), restartedTheme.init()]);
          expect(restartedLocale.currentLanguage, language);
          expect(restartedTheme.themeMode, mode);
          expect(restartedLocale.textDirection, language.direction);
          restartedLocale.dispose();
          restartedTheme.dispose();
        },
      );
    }
  }
  for (final stored in [false, true]) {
    testWidgets(
      'root first frame restores preferences; fresh install ignores dark host stored=$stored',
      (tester) async {
        FlutterSecureStorage.setMockInitialValues(
          stored
              ? {
                  LocaleService.storageKey: 'ar',
                  ThemeService.storageKey: 'dark',
                }
              : {},
        );
        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await Future.wait([LocaleService().init(), ThemeService().init()]);
        await tester.pumpWidget(
          const AestheticWayApp(
            homeScreen: Scaffold(body: Text('preference probe')),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.text('preference probe'));
        expect(
          Localizations.localeOf(context).languageCode,
          stored ? 'ar' : 'en',
        );
        expect(
          Directionality.of(context),
          stored ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(
          Theme.of(context).brightness,
          stored ? Brightness.dark : Brightness.light,
        );
      },
    );
  }
  test(
    'rapid settings changes serialize storage writes and restore the final choice',
    () async {
      final first = Completer<void>();
      final writes = <String>[];
      String? saved;
      final pref = PersistentPreference<String>(
        defaultValue: 'en',
        read: () async => saved,
        decode: (v) => v ?? 'en',
        encode: (v) => v,
        write: (v) async {
          writes.add(v);
          if (writes.length == 1) await first.future;
          saved = v;
        },
      );
      final a = pref.setValue('ar');
      final b = pref.setValue('en');
      final c = pref.setValue('ar');
      expect(pref.value, 'ar');
      await Future<void>.delayed(Duration.zero);
      expect(writes, ['ar']);
      expect(pref.isSaving, isTrue);
      first.complete();
      await Future.wait([a, b, c]);
      expect(writes, ['ar', 'en', 'ar']);
      expect(saved, 'ar');
      await pref.restore();
      expect(pref.value, 'ar');
      expect(pref.isSaving, isFalse);
      pref.dispose();
    },
  );
  test(
    'a late restore cannot overwrite a preference chosen during startup',
    () async {
      final gate = Completer<String?>();
      final pref = PersistentPreference<String>(
        defaultValue: 'en',
        read: () => gate.future,
        decode: (v) => v ?? 'en',
        encode: (v) => v,
        write: (_) async {},
      );
      final restoring = pref.restore();
      await Future<void>.delayed(Duration.zero);
      await pref.setValue('ar');
      gate.complete('en');
      await restoring;
      expect(pref.value, 'ar');
      pref.dispose();
    },
  );
  testWidgets(
    'saving failures are visible and an explicit retry persists the choice',
    (tester) async {
      var fail = true;
      String? saved;
      final pref = PersistentPreference<String>(
        defaultValue: 'en',
        read: () async => saved,
        decode: (v) => v ?? 'en',
        encode: (v) => v,
        write: (v) async {
          if (fail) throw StateError('synthetic failure');
          saved = v;
        },
      );
      await LocaleService().setLanguage(AppLanguage.english);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PreferenceSaveStatus(
              listenable: pref,
              saving: () => pref.isSaving,
              failed: () => pref.saveFailed,
              onRetry: pref.retrySave,
            ),
          ),
        ),
      );
      await pref.setValue('ar');
      await tester.pumpAndSettle();
      expect(saved, isNull);
      expect(
        find.text('Could not save this preference on the device.'),
        findsOneWidget,
      );
      expect(pref.value, 'ar');
      fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(saved, 'ar');
      expect(find.text('Retry'), findsNothing);
      pref.dispose();
    },
  );
  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      testWidgets(
        'placeholder geometry, semantics and real decode dark=$dark rtl=$ar',
        (tester) async {
          await LocaleService().setLanguage(
            ar ? AppLanguage.arabic : AppLanguage.english,
          );
          await tester.binding.setSurfaceSize(const Size(390, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            MaterialApp(
              theme: patientVisualTheme(dark: dark),
              home: Directionality(
                textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
                child: Scaffold(
                  body: Column(
                    children: [
                      const PatientMediaBanner(
                        category: PatientMediaCategory.clinicCover,
                        source: 'assets/images/onboarding/onboarding_1.jpeg',
                        aspectRatio: 3 / 2,
                      ),
                      const PatientMediaBanner(
                        category: PatientMediaCategory.clinicCover,
                        source: null,
                        aspectRatio: 3 / 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await settlePreviewImages(tester);
          final frames = find.byType(PatientMediaBanner);
          expect(tester.getSize(frames.first), tester.getSize(frames.last));
          final raw = tester.widget<RawImage>(find.byType(RawImage));
          expect(raw.image, isNotNull);
          expect(raw.image!.width, greaterThan(0));
          expect(raw.image!.height, greaterThan(0));
          expect(find.byType(PatientMediaPlaceholder), findsOneWidget);
          expect(
            find.bySemanticsLabel(
              ar ? 'الصورة غير متوفرة' : 'Image unavailable',
            ),
            findsOneWidget,
          );
          await LocaleService().setLanguage(
            ar ? AppLanguage.english : AppLanguage.arabic,
          );
          await tester.pumpAndSettle();
          expect(
            find.bySemanticsLabel(
              ar ? 'Image unavailable' : 'الصورة غير متوفرة',
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('decode failure retains exactly the same media frame', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('aw-polish-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final corrupt = File('${dir.path}/broken.png')..writeAsBytesSync([1, 2, 3]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PatientMediaBanner(
            category: PatientMediaCategory.clinicCover,
            source: corrupt.path,
            height: 190,
          ),
        ),
      ),
    );
    for (
      var i = 0;
      i < 30 && find.byType(PatientMediaPlaceholder).evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(find.byType(PatientMediaPlaceholder), findsOneWidget);
    expect(tester.getSize(find.byType(PatientMediaBanner)).height, 190);
    expect(tester.takeException(), isNull);
  });
  for (final kind in [
    'clinic',
    'practitioner',
    'product',
    'offer',
    'gallery',
  ]) {
    testWidgets('$kind real and missing media preserve card composition', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const photo = 'assets/images/onboarding/onboarding_1.jpeg';
      Widget card(bool real) => switch (kind) {
        'clinic' => PatientClinicCard(
          clinic: patientClinic(extra: {if (real) 'cover_image': photo}),
          onTap: () {},
        ),
        'practitioner' => PatientPractitionerCard(
          practitioner: PractitionerModel.fromJson({
            'name_en': 'Test Practitioner',
            'type': 'doctor',
            if (real) 'avatar_url': photo,
          }),
          onTap: () {},
        ),
        'product' => BrandProductMedia(
          product: ProductModel.fromJson({
            'name_en': 'Test Product',
            if (real) 'image_url': photo,
          }),
        ),
        'offer' => PatientOfferCard(
          offer: OfferModel.fromJson({
            'title_en': 'Test offer',
            if (real) 'image_url': photo,
          }),
        ),
        _ => PatientClinicGallery(images: real ? [photo] : []),
      };
      await LocaleService().setLanguage(AppLanguage.english);
      Future<Size> measure(bool real) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: 350,
                  child: RepaintBoundary(
                    key: const ValueKey('card'),
                    child: card(real),
                  ),
                ),
              ),
            ),
          ),
        );
        if (real) await settlePreviewImages(tester);
        return tester.getSize(find.byKey(const ValueKey('card')));
      }

      final genuine = await measure(true);
      final missing = await measure(false);
      expect(missing, genuine);
      expect(find.byType(PatientMediaPlaceholder), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
