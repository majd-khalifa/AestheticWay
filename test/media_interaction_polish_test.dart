import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/widgets/async_action_button.dart';
import 'package:aesthetic_way/core/widgets/patient_media_banner.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/features/clinics/data/clinics_repository.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/clinics/presentation/widgets/patient_clinic_card.dart';
import 'package:aesthetic_way/features/home/data/models/home_feed_model.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/offers/data/offers_repository.dart';
import 'package:aesthetic_way/features/offers/presentation/screens/offers_screen.dart';
import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/features/offers/presentation/offer_actions.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';
import 'package:aesthetic_way/core/widgets/lazy_tab_stack.dart';
import 'package:aesthetic_way/core/widgets/luxury_loading_skeleton.dart';
import '../tool/media_contract_diagnostics.dart';
import 'support/patient_fixtures.dart';

class DelayedClinic extends ClinicsRepository {
  var result = Completer<ClinicModel>();
  int calls = 0;
  @override
  Future<ClinicModel> getClinicDetail(String idOrSlug) {
    calls++;
    return result.future;
  }
}

class FixtureOffers extends OffersRepository {
  FixtureOffers(this.offer);
  final OfferModel offer;
  @override
  Future<List<OfferModel>> getOffers({
    String? clinicId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async => PageItems([offer], hasMore: false, total: 1);
}

class DelayedOffers extends OffersRepository {
  final result = Completer<List<OfferModel>>();
  @override
  Future<List<OfferModel>> getOffers({
    String? clinicId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) => result.future;
}

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  final fixtureInterceptor = InterceptorsWrapper(
    onRequest: (options, handler) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: options.path == 'clinics/$patientClinicId/'
              ? {'id': patientClinicId, 'name_en': 'Fixture Medical Clinic'}
              : {'results': [], 'next': null, 'count': 0},
        ),
      );
    },
  );
  setUpAll(() => ApiClient().dio.interceptors.insert(0, fixtureInterceptor));
  tearDownAll(() => ApiClient().dio.interceptors.remove(fixtureInterceptor));
  setUp(() {
    LocaleService().setLanguage(AppLanguage.english);
    AuthState().login(name: 'Fixture', phone: '+971501234567');
  });

  testWidgets(
    'offers first fetch shows progress rather than a premature empty result',
    (tester) async {
      final offers = DelayedOffers();
      await tester.pumpWidget(
        MaterialApp(home: OffersScreen(repository: offers)),
      );
      await tester.pump();
      expect(find.byType(LuxuryListSkeleton), findsOneWidget);
      expect(find.text('No offers currently available'), findsNothing);
      offers.result.complete(PageItems([], hasMore: false, total: 0));
      await tester.pumpAndSettle();
      expect(find.byType(LuxuryListSkeleton), findsNothing);
      expect(find.text('No offers currently available'), findsOneWidget);
    },
  );

  test('video asset exposed as image is not mistaken for a poster', () {
    const url = 'https://cdn.invalid/ad.mp4?signature=unchanged%2Fvalue';
    final ad = FeaturedAdApiModel.fromJson({
      'media_type': 'video',
      'image_url': url,
      'video_url': url,
    });
    expect(ad.image, isEmpty);
    expect(ad.videoUrl, url);
    expect(
      FeaturedAdApiModel.fromJson({
        'media_type': 'video',
        'image_url': '/media/poster.png',
        'video_url': url,
      }).image,
      endsWith('/media/poster.png'),
    );
  });

  test(
    'redacted media diagnostics cannot disclose signed URLs or patient text',
    () {
      final output = jsonEncode(
        mediaDiagnostics({
          'id': 'secret-id',
          'notes': 'private patient text',
          'image_url':
              'https://private-host.invalid/private-name.png?signature=secret-token',
          'clinic': {'logo': '', 'name_en': 'Private clinic'},
        }),
      );
      for (final secret in [
        'secret-id',
        'patient',
        'private-host',
        'private-name',
        'secret-token',
        'Private clinic',
      ]) {
        expect(output, isNot(contains(secret)));
      }
      expect(output, contains('"has_query":true'));
      expect(output, contains('"supplied":false'));
    },
  );

  test('real cover wins, gallery is secondary, logo is never photography', () {
    expect(
      patientClinic(
        extra: {
          'cover_image': '/media/cover.png',
          'gallery_images': ['/media/gallery.png'],
        },
      ).primaryPhotoUrl,
      endsWith('/media/cover.png'),
    );
    expect(
      patientClinic(
        extra: {
          'gallery_images': ['/media/gallery.png'],
        },
      ).primaryPhotoUrl,
      endsWith('/media/gallery.png'),
    );
    expect(
      patientClinic(extra: {'logo': '/media/logo.png'}).primaryPhotoUrl,
      isEmpty,
    );
  });

  testWidgets(
    'busy control preserves dimensions, acknowledges immediately and guards pre-frame duplicate taps',
    (tester) async {
      final pending = Completer<void>();
      var calls = 0, other = 0;
      await tester.pumpWidget(
        app(
          Column(
            children: [
              AsyncActionButton(
                label: 'Request consultation',
                loadingLabel: 'Opening consultation',
                onPressed: (action) async {
                  calls++;
                  await action.wait(pending.future);
                },
              ),
              TextButton(
                onPressed: () => other++,
                child: const Text('Unrelated'),
              ),
            ],
          ),
        ),
      );
      final button = find.byType(FilledButton);
      final size = tester.getSize(button);
      final beforeFrameCallback = tester
          .widget<FilledButton>(button)
          .onPressed!;
      beforeFrameCallback();
      beforeFrameCallback();
      await tester.pump();
      expect(calls, 1);
      expect(tester.getSize(button), size);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Opening consultation'), findsOneWidget);
      await tester.tap(find.text('Unrelated'));
      expect(other, 1);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.getSize(button), size);
      semantics.dispose();
    },
  );

  testWidgets(
    'error is contextual and retry restores a successful local action',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        app(
          AsyncActionButton(
            label: 'Explore clinic',
            errorLabel: 'Clinic unavailable. Please try again.',
            onPressed: (_) async {
              if (++calls == 1) throw StateError('secret server payload');
            },
          ),
        ),
      );
      await tester.tap(find.text('Explore clinic'));
      await tester.pumpAndSettle();
      expect(
        find.text('Clinic unavailable. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('secret server payload'), findsNothing);
      await tester.tap(find.text('Explore clinic'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('Clinic unavailable. Please try again.'), findsNothing);
    },
  );

  for (final cancellation in ['account', 'dispose', 'api']) {
    testWidgets(
      '$cancellation cancellation suppresses stale navigation and error',
      (tester) async {
        final pending = Completer<void>();
        var navigated = false;
        await tester.pumpWidget(
          app(
            AsyncActionButton(
              label: 'Continue',
              onPressed: (action) async {
                await action.wait(pending.future);
                navigated = true;
              },
            ),
          ),
        );
        await tester.tap(find.text('Continue'));
        await tester.pump();
        if (cancellation == 'account') {
          AuthState().login(name: 'Other', phone: '+971509999999');
        }
        if (cancellation == 'dispose') {
          await tester.pumpWidget(app(const Text('Replacement')));
        }
        if (cancellation == 'api') {
          pending.completeError(
            const ApiException(message: '', isCancelled: true),
          );
        } else {
          pending.complete();
        }
        await tester.pumpAndSettle();
        expect(navigated, isFalse);
        expect(find.textContaining('Unable to complete'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final inquire in [false, true]) {
    testWidgets(
      'offer ${inquire ? 'inquiry' : 'exploration'} waits for clinic fetch before navigating once',
      (tester) async {
        final repository = DelayedClinic();
        final offer = OfferModel.fromJson({
          'id': patientOfferId,
          'clinic': {'id': patientClinicId},
        });
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => AsyncActionButton(
                  label: 'Explore',
                  onPressed: (action) => openOfferClinic(
                    context,
                    offer,
                    action,
                    repository,
                    inquire: inquire,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byType(FilledButton));
        await tester.tap(find.byType(FilledButton));
        await tester.pump();
        expect(repository.calls, 1);
        expect(find.text('Clinic profile'), findsNothing);
        repository.result.complete(patientClinic());
        await tester.pumpAndSettle();
        if (inquire) {
          expect(find.byType(AppointmentRequestScreen), findsOneWidget);
          final screen = tester.widget<AppointmentRequestScreen>(
            find.byType(AppointmentRequestScreen),
          );
          expect(screen.selectedOfferId, patientOfferId);
          expect(screen.clinic.id, patientClinicId);
        } else {
          expect(find.text('Clinic profile'), findsOneWidget);
        }
      },
    );
  }

  testWidgets(
    'leaving a tab cancels a mounted action before its navigation side effect',
    (tester) async {
      var active = true, navigated = false;
      late StateSetter change;
      final result = Completer<void>();
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, setter) {
              change = setter;
              return TabActivity(
                active: active,
                child: AsyncActionButton(
                  label: 'Open',
                  onPressed: (action) async {
                    await action.wait(result.future);
                    navigated = true;
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      change(() => active = false);
      await tester.pump();
      result.complete();
      await tester.pumpAndSettle();
      expect(navigated, isFalse);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'OffersScreen inquiry shows local progress through fetch failure, retry and lead navigation',
    (tester) async {
      final clinics = DelayedClinic();
      final offer = OfferModel.fromJson({
        'id': patientOfferId,
        'clinic': {'id': patientClinicId, 'name_en': 'Fixture Clinic'},
        'title_en': 'Skin consultation',
      });
      await tester.pumpWidget(
        MaterialApp(
          home: OffersScreen(
            repository: FixtureOffers(offer),
            clinicsRepository: clinics,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final inquiry = find.text(LocaleService().tr('offer_claim'));
      await tester.tap(inquiry);
      await tester.pump();
      expect(clinics.calls, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final semantics = tester.ensureSemantics();
      try {
        expect(find.bySemanticsLabel('Loading clinic'), findsOneWidget);
        final active = find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(AsyncActionButton),
        );
        expect(active, findsOneWidget);
        expect(
          find.descendant(of: active, matching: find.text('Loading clinic')),
          findsOneWidget,
        );
        expect(find.byType(AppointmentRequestScreen), findsNothing);
        clinics.result.completeError(
          const ApiException(message: 'Synthetic offline'),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Clinic unavailable. Please try again.'),
          findsOneWidget,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);
        clinics.result = Completer<ClinicModel>();
        await tester.tap(inquiry);
        await tester.pump();
        expect(clinics.calls, 2);
        clinics.result.complete(patientClinic());
        await tester.pumpAndSettle();
        expect(find.byType(AppointmentRequestScreen), findsOneWidget);
        expect(
          tester
              .widget<AppointmentRequestScreen>(
                find.byType(AppointmentRequestScreen),
              )
              .selectedOfferId,
          patientOfferId,
        );
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final width in [320.0, 600.0]) {
    testWidgets(
      'responsive actual photo frame at $width has 3:2 ratio, missing media collapses',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        const photo = 'assets/images/onboarding/onboarding_1.jpeg';
        // Warm the real provider outside the fake async clock; no mocked decoder.
        await tester.runAsync(() async {
          final complete = Completer<void>();
          final stream = resolveImageProvider(
            photo,
          )!.resolve(ImageConfiguration.empty);
          late ImageStreamListener listener;
          listener = ImageStreamListener(
            (_, _) {
              stream.removeListener(listener);
              complete.complete();
            },
            onError: (Object e, StackTrace? stack) => complete.completeError(e),
          );
          stream.addListener(listener);
          await complete.future;
        });
        await tester.pumpWidget(
          app(
            MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1200),
                textScaler: const TextScaler.linear(1.6),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      PatientClinicCard(
                        clinic: patientClinic(extra: {'cover_image': photo}),
                        onTap: () {},
                      ),
                      PatientClinicCard(clinic: patientClinic(), onTap: () {}),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final media = find.byType(PatientMediaBanner);
        final image = tester.getSize(media.first);
        expect(image.width / image.height, closeTo(1.5, .01));
        expect(tester.getSize(media.last).height, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
