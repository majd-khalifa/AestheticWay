import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/google_business/data/google_business_repository.dart';
import 'package:aesthetic_way/features/google_business/models/google_business.dart';
import 'package:aesthetic_way/features/google_business/services/google_business_controller.dart';
import 'package:aesthetic_way/features/google_business/presentation/google_business_screen.dart';
import 'onboarding_review_workflows_test.dart' as f;
import 'support/patient_visual_harness.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_profile_screen.dart'
    as portal;

const suggestion = GooglePlaceSuggestion(
  placeId: 'QA-Selected-Place',
  name: 'Disposable QA Clinic',
  address: 'QA street, Dubai',
);
GoogleBusinessPlace place({
  String id = 'QA-Selected-Place',
  String country = 'AE',
  String proof = 'disposable-server-proof',
}) => GoogleBusinessPlace(
  placeId: id,
  name: suggestion.name,
  address: suggestion.address,
  locality: 'Dubai',
  latitude: 25.1,
  longitude: 55.2,
  countryCode: country,
  selectionProof: proof,
);

class BusinessFixture extends GoogleBusinessRepository {
  GoogleBusinessAssociation state = const GoogleBusinessAssociation(
    clinicId: f.id,
    placeId: 'QA-Old-Place',
    syncStatus: 'synced',
  );
  GoogleBusinessCapabilities caps = const GoogleBusinessCapabilities(
    search: true,
    link: true,
    unlink: true,
  );
  final tokens = <String>[], detailTokens = <String>[], queries = <String>[];
  final links = <GoogleBusinessPlace>[];
  int gets = 0, unlinks = 0;
  bool persist = true, failGet = false;
  GoogleBusinessPlace selectedPlace = place();
  Completer<List<GooglePlaceSuggestion>>? suggestionsWait;
  Completer<GoogleBusinessAssociation>? writeWait;
  @override
  GoogleBusinessCapabilities get capabilities => caps;
  @override
  Future<GoogleBusinessAssociation> current() async {
    gets++;
    if (failGet) throw StateError('private server diagnostics');
    return state;
  }

  @override
  Future<List<GooglePlaceSuggestion>> autocomplete(
    String query, {
    required String sessionToken,
    required String languageCode,
  }) async {
    tokens.add(sessionToken);
    queries.add(query);
    if (suggestionsWait != null) return suggestionsWait!.future;
    return [suggestion];
  }

  @override
  Future<GoogleBusinessPlace> details(
    String placeId, {
    required String sessionToken,
    required String languageCode,
  }) async {
    detailTokens.add(sessionToken);
    return selectedPlace;
  }

  @override
  Future<GoogleBusinessAssociation> link(
    GoogleBusinessPlace place, {
    required String clinicId,
    required String expectedPlaceId,
  }) async {
    links.add(place);
    final ack = GoogleBusinessAssociation(
      clinicId: clinicId,
      placeId: place.placeId,
      syncStatus: 'pending',
    );
    if (persist) state = ack;
    return writeWait?.future ?? Future.value(ack);
  }

  @override
  Future<GoogleBusinessAssociation> unlink({
    required String clinicId,
    required String expectedPlaceId,
  }) async {
    unlinks++;
    state = GoogleBusinessAssociation(
      clinicId: clinicId,
      syncStatus: 'not_configured',
    );
    return state;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  setUp(() async {
    await LocaleService().setLanguage(AppLanguage.english);
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    AuthState().login(
      name: 'Disposable QA',
      phone: 'fixture-owner',
      role: 'clinic_admin',
    );
  });
  tearDown(() => AuthState().logout());
  Future<void> search(WidgetTester tester, GoogleBusinessController c) async {
    c.queryChanged('Disposable QA');
    await tester.pump(const Duration(milliseconds: 351));
  }

  testWidgets(
    'similar names never auto-select or link without explicit identity confirmation',
    (tester) async {
      final repo = BusinessFixture();
      final controller = GoogleBusinessController(repo);
      await controller.reload();
      await search(tester, controller);
      expect(controller.suggestions, hasLength(1));
      expect(controller.selected, isNull);
      expect(await controller.saveLink(), false);
      expect(repo.links, isEmpty);
      await controller.select(controller.suggestions.single);
      expect(controller.confirmed, false);
      expect(await controller.saveLink(), false);
      controller.confirmIdentity(true);
      expect(await controller.saveLink(), true);
      expect(repo.links.single.placeId, suggestion.placeId);
      expect(controller.association!.syncStatus, 'pending');
      controller.dispose();
    },
  );
  testWidgets(
    'Autocomplete New session is shared across queries and details then retired',
    (tester) async {
      final repo = BusinessFixture();
      final controller = GoogleBusinessController(repo);
      await controller.reload();
      controller.queryChanged('One');
      await tester.pump(const Duration(milliseconds: 351));
      controller.queryChanged('Two');
      await tester.pump(const Duration(milliseconds: 351));
      expect(repo.tokens[0], repo.tokens[1]);
      expect(
        repo.tokens[0],
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      await controller.select(controller.suggestions.single);
      expect(repo.detailTokens.single, repo.tokens[0]);
      controller.queryChanged('Three');
      await tester.pump(const Duration(milliseconds: 351));
      expect(repo.tokens.last, isNot(repo.tokens.first));
      controller.cancelSelection();
      controller.queryChanged('Four');
      await tester.pump(const Duration(milliseconds: 351));
      expect(repo.tokens.last, isNot(repo.tokens[2]));
      controller.dispose();
    },
  );
  testWidgets('350ms debounce does not request every keystroke', (
    tester,
  ) async {
    final r = BusinessFixture();
    final v = GoogleBusinessController(r);
    await v.reload();
    v.queryChanged('A');
    v.queryChanged('Ab');
    v.queryChanged('Abc');
    await tester.pump(const Duration(milliseconds: 349));
    expect(r.tokens, isEmpty);
    await tester.pump(const Duration(milliseconds: 2));
    expect(r.queries, ['Abc']);
    v.dispose();
  });
  for (final mismatch in ['wrongId', 'wrongCountry', 'noProof']) {
    testWidgets('incorrect business protection $mismatch', (tester) async {
      final r = BusinessFixture()
        ..selectedPlace = place(
          id: mismatch == 'wrongId' ? 'QA-Different-Place' : suggestion.placeId,
          country: mismatch == 'wrongCountry' ? 'GB' : 'AE',
          proof: mismatch == 'noProof' ? '' : 'disposable-proof',
        );
      final c = GoogleBusinessController(r);
      await c.reload();
      await search(tester, c);
      await c.select(c.suggestions.single);
      c.confirmIdentity(true);
      expect(await c.saveLink(), false);
      expect(r.links, isEmpty);
      c.dispose();
    });
  }
  testWidgets(
    'write succeeds only after matching fresh GET; failed verification blocks resend',
    (tester) async {
      final r = BusinessFixture()..persist = false;
      final c = GoogleBusinessController(r);
      await c.reload();
      await search(tester, c);
      await c.select(c.suggestions.single);
      c.confirmIdentity(true);
      expect(await c.saveLink(), false);
      expect(c.association!.placeId, 'QA-Old-Place');
      expect(c.needsRefresh, true);
      expect(await c.saveLink(), false);
      expect(r.links, hasLength(1));
      await c.reload();
      expect(c.needsRefresh, false);
      c.dispose();
    },
  );
  testWidgets(
    'duplicate saves share one write and an account switch rejects completion',
    (tester) async {
      final r = BusinessFixture()
        ..writeWait = Completer<GoogleBusinessAssociation>();
      final c = GoogleBusinessController(r);
      await c.reload();
      await search(tester, c);
      await c.select(c.suggestions.single);
      c.confirmIdentity(true);
      final pending = c.saveLink();
      expect(await c.saveLink(), false);
      expect(r.links, hasLength(1));
      AuthState().login(
        name: 'Other QA',
        phone: 'other-fixture',
        role: 'clinic_admin',
      );
      r.writeWait!.complete(r.state);
      expect(await pending, false);
      expect(c.association, isNull);
      c.dispose();
    },
  );
  testWidgets(
    'late search response after cancel/dispose cannot populate results',
    (tester) async {
      final r = BusinessFixture()
        ..suggestionsWait = Completer<List<GooglePlaceSuggestion>>();
      final c = GoogleBusinessController(r);
      await c.reload();
      c.queryChanged('Disposable');
      await tester.pump(const Duration(milliseconds: 351));
      c.cancelSelection();
      r.suggestionsWait!.complete([suggestion]);
      await tester.pump();
      expect(c.suggestions, isEmpty);
      c.dispose();
    },
  );
  for (final role in ['patient', 'super_admin', 'clinic_staff']) {
    test('role $role cannot invoke clinic Google association writes', () async {
      AuthState().login(name: 'QA', phone: 'fixture-$role', role: role);
      final api = ApiClient(), old = ApiClient().dio.httpClientAdapter;
      final wire = f.Adapter((r) => f.body({}));
      api.dio.httpClientAdapter = wire;
      addTearDown(() => api.dio.httpClientAdapter = old);
      final repository = CurrentClinicGoogleBusinessRepository();
      await expectLater(
        repository.current(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403)),
      );
      expect(wire.requests, isEmpty);
    });
  }
  test(
    '401560b unlink uses atomic POST with expected identity, never manual pin/media',
    () async {
      final api = ApiClient(), old = ApiClient().dio.httpClientAdapter;
      String id = 'QA-Old-Place';
      final wire = f.Adapter((r) {
        if (r.method == 'POST') id = '';
        return f.body({
          ...f.clinic(),
          'google_place_id': id,
          'google_maps_url': '',
          'google_sync_status': id.isEmpty ? 'not_configured' : 'pending',
        });
      });
      api.dio.httpClientAdapter = wire;
      addTearDown(() => api.dio.httpClientAdapter = old);
      final repo = CurrentClinicGoogleBusinessRepository(
        catalog: ClinicCatalogRepository(apiClient: api),
      );
      expect(repo.capabilities.search, true);
      expect(repo.capabilities.link, true);
      final c = GoogleBusinessController(repo);
      await c.reload();
      expect(await c.unlink(), true);
      expect(wire.requests.map((r) => r.method), ['GET', 'GET', 'POST', 'GET']);
      expect(wire.requests.singleWhere((r) => r.method == 'POST').data, {
        'expected_current_place_id': 'QA-Old-Place',
      });
      expect(c.association!.linked, false);
      c.dispose();
    },
  );
  test('stale expected Place ID refuses unlink before PATCH', () async {
    final api = ApiClient(), old = ApiClient().dio.httpClientAdapter;
    final wire = f.Adapter(
      (r) => f.body({
        ...f.clinic(),
        'google_place_id': 'QA-Changed',
        'google_sync_status': 'pending',
      }),
    );
    api.dio.httpClientAdapter = wire;
    addTearDown(() => api.dio.httpClientAdapter = old);
    final repo = CurrentClinicGoogleBusinessRepository(
      catalog: ClinicCatalogRepository(apiClient: api),
    );
    await expectLater(
      repo.unlink(clinicId: f.id, expectedPlaceId: 'QA-Old'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)),
    );
    expect(wire.requests.where((r) => r.method == 'PATCH'), isEmpty);
  });
  test(
    'private Google sync fields parse and survive unrelated profile copies',
    () {
      final c = ClinicModel.fromJson({
        'google_place_id': 'QA-Place',
        'google_sync_status': 'pending',
        'google_last_synced_at': '2026-10-24T10:00:00Z',
      });
      expect(c.copyWith(nameEn: 'Changed').googleSyncStatus, 'pending');
      expect(
        c.copyWith(city: 'Dubai').googleLastSyncedAt,
        DateTime.utc(2026, 10, 24, 10),
      );
    },
  );
  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      testWidgets(
        'Google association unavailable/linked state dark=$dark ar=$ar',
        (tester) async {
          final r = BusinessFixture()
            ..caps = const GoogleBusinessCapabilities(unlink: true);
          await f.render(
            tester,
            GoogleBusinessScreen(repository: r, onEditManualPin: () async {}),
            dark: dark,
            ar: ar,
          );
          expect(
            tester
                .widget<TextField>(
                  find.byKey(const ValueKey('google-business-query')),
                )
                .enabled,
            false,
          );
          expect(r.tokens, isEmpty);
          expect(
            find.textContaining(
              ar
                  ? 'البحث عن نشاط Google غير متاح'
                  : 'Google Business search is not available',
            ),
            findsOneWidget,
          );
          await f.capture(
            tester,
            'google_association_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.binding.setSurfaceSize(null);
        },
      );
      testWidgets('explicit Google selection preview dark=$dark ar=$ar', (
        tester,
      ) async {
        final r = BusinessFixture();
        await f.render(
          tester,
          GoogleBusinessScreen(repository: r),
          dark: dark,
          ar: ar,
        );
        await tester.enterText(
          find.byKey(const ValueKey('google-business-query')),
          'Disposable',
        );
        await tester.pump(const Duration(milliseconds: 351));
        await tester.tap(find.text(suggestion.name));
        await tester.pumpAndSettle();
        expect(r.links, isEmpty);
        expect(find.text(suggestion.address), findsOneWidget);
        await tester.ensureVisible(
          find.byKey(const ValueKey('google-business-identity-confirm')),
        );
        await f.capture(
          tester,
          'google_selection_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
      });
    }
  }
  testWidgets(
    'manual pin save preserves the stored Google identity and business URL',
    (tester) async {
      final api = ApiClient(), service = ClinicPortalService();
      final old = api.dio.httpClientAdapter;
      final data = <String, dynamic>{
        ...f.clinic(),
        'google_place_id': 'QA-Preserved-Place',
        'google_maps_url':
            'https://www.google.com/maps/search/?api=1&query_place_id=QA-Preserved-Place',
        'latitude': 25.1,
        'longitude': 55.2,
      };
      final wire = f.Adapter((r) {
        if (r.method == 'PATCH') {
          data.addAll(Map<String, dynamic>.from(r.data as Map));
        }
        return f.body(data);
      });
      api.dio.httpClientAdapter = wire;
      service.resetTestingState();
      service.setCatalogRepositoryForTesting(
        ClinicCatalogRepository(apiClient: api),
      );
      service.setActiveClinicForTesting(ClinicModel.fromJson(data));
      addTearDown(() {
        api.dio.httpClientAdapter = old;
        service.resetTestingState();
      });
      await f.render(tester, const portal.ClinicProfileScreen());
      await tester.scrollUntilVisible(find.text('Update Location'), 300);
      await tester.tap(find.text('Update Location'));
      // Parent CTA intentionally spins until the modal returns: settle the
      // transition without waiting for that live progress animation to stop.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final field = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == 'Search place or enter coordinates',
      );
      await tester.ensureVisible(field);
      await tester.enterText(field, '25.11, 55.21');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Use This Location'),
        240,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('clinic-location-form')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Use This Location'));
      await tester.pumpAndSettle();
      final patch =
          wire.requests.singleWhere((r) => r.method == 'PATCH').data as Map;
      expect(patch.containsKey('google_place_id'), false);
      expect(patch.containsKey('google_maps_url'), false);
      expect(data['google_place_id'], 'QA-Preserved-Place');
      expect(service.activeClinic.googlePlaceId, 'QA-Preserved-Place');
      expect(service.activeClinic.latitude, 25.11);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  for (final status in GoogleBusinessVerification.values) {
    testWidgets(
      'business verification state remains separate from ratings sync: $status',
      (tester) async {
        final repo = BusinessFixture()
          ..state = GoogleBusinessAssociation(
            clinicId: f.id,
            placeId: 'QA-Place',
            syncStatus: 'synced',
            verification: status,
          );
        await f.render(tester, GoogleBusinessScreen(repository: repo));
        expect(find.textContaining('Ratings synchronized'), findsOneWidget);
        if (status == GoogleBusinessVerification.pending) {
          expect(
            find.textContaining('verification is pending'),
            findsOneWidget,
          );
        }
        if (status == GoogleBusinessVerification.notProvided) {
          expect(
            find.textContaining('Ownership verification is not supplied'),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
      },
    );
  }
  for (final ar in [false, true]) {
    testWidgets(
      'Google Business page fits 320dp with 180 percent text ar=$ar',
      (tester) async {
        final repo = BusinessFixture()
          ..caps = const GoogleBusinessCapabilities(unlink: true);
        await f.render(
          tester,
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 1000),
              textScaler: TextScaler.linear(1.8),
            ),
            child: GoogleBusinessScreen(repository: repo),
          ),
          width: 320,
          ar: ar,
        );
        expect(tester.takeException(), isNull);
        await f.capture(tester, 'google_scaled_${ar ? 'ar' : 'en'}');
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
      },
    );
  }
  testWidgets(
    'session token expires under local policy and language switch cancels stale suggestions',
    (tester) async {
      var now = DateTime.utc(2026, 10, 24);
      final repo = BusinessFixture();
      final c = GoogleBusinessController(repo, now: () => now);
      await c.reload();
      await search(tester, c);
      final first = repo.tokens.single;
      now = now.add(const Duration(minutes: 3));
      await search(tester, c);
      expect(repo.tokens.last, isNot(first));
      await LocaleService().setLanguage(AppLanguage.arabic);
      expect(c.suggestions, isEmpty);
      await search(tester, c);
      expect(repo.tokens.last, isNot(repo.tokens[1]));
      c.dispose();
    },
  );
}
