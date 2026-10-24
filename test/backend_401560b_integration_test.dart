import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';
import 'package:aesthetic_way/features/auth/models/deletion_delivery.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/account_deletion_screen.dart';
import 'package:aesthetic_way/features/google_business/data/google_business_repository.dart';
import 'package:aesthetic_way/features/google_business/services/google_business_controller.dart';
import 'package:aesthetic_way/features/google_business/models/google_business.dart';
import 'package:aesthetic_way/features/google_business/presentation/google_business_screen.dart';
import 'package:aesthetic_way/features/locations/data/uae_location_repository.dart';
import 'package:aesthetic_way/features/locations/models/uae_location.dart';
import 'package:aesthetic_way/features/locations/presentation/uae_location_picker.dart';
import 'package:aesthetic_way/features/locations/data/nearby_clinics_repository.dart';
import 'package:aesthetic_way/features/locations/services/patient_location_controller.dart';
import 'package:aesthetic_way/features/clinic_portal/services/showcase_video_change.dart';
import 'onboarding_review_workflows_test.dart' as f;
import 'support/patient_visual_harness.dart';

const token = '550e8400-e29b-41d4-a716-446655440000';
const placeId = 'QA-Exact-Place';
Map<String, dynamic> details() => {
  'place_id': placeId,
  'display_name': 'Disposable integration clinic',
  'formatted_address': 'QA address, Dubai, UAE',
  'locality': 'Dubai',
  'country_code': 'AE',
  'latitude': 25.11,
  'longitude': 55.21,
  'google_maps_url':
      'https://www.google.com/maps/search/?api=1&query=$placeId&query_place_id=$placeId',
  'selection_proof': 'disposable-single-use-proof',
  'proof_expires_in': 300,
};
Map<String, dynamic> profile([String id = '']) => {
  ...f.clinic(),
  'google_place_id': id,
  'google_link_status': id.isEmpty ? 'unlinked' : 'linked_verified_place',
  'google_sync_status': id.isEmpty ? 'not_configured' : 'pending',
};
Map<String, dynamic> get catalog =>
    jsonDecode(
          File(
            'test/fixtures/backend_401560b_locations.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;
Future<void> searchReady(GoogleBusinessController c) async {
  final done = Completer<void>();
  void changed() {
    if (!c.searching && c.hasSearched && !done.isCompleted) done.complete();
  }

  c.addListener(changed);
  c.queryChanged('Disposable');
  try {
    await done.future.timeout(const Duration(seconds: 5));
  } finally {
    c.removeListener(changed);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    AuthState().login(
      name: 'Disposable QA',
      phone: 'fixture-only',
      role: 'clinic_admin',
    );
    ServerUaeLocationRepository.loaded = null;
  });
  tearDown(() {
    AuthState().logout();
    ServerUaeLocationRepository.loaded = null;
  });
  f.Adapter wire(Future<ResponseBody> Function(RequestOptions) fn) {
    final api = ApiClient(), old = ApiClient().dio.httpClientAdapter;
    final adapter = f.Adapter(fn);
    api.dio.httpClientAdapter = adapter;
    addTearDown(() => api.dio.httpClientAdapter = old);
    return adapter;
  }

  test(
    'real adapter search/details/link/unlink uses source keys, CAS, same token, ACK plus fresh GET',
    () async {
      String linked = '';
      final adapter = wire((r) async {
        if (r.path.endsWith('autocomplete/')) {
          return f.body({
            'suggestions': [
              {
                'place_id': placeId,
                'main_text': 'Disposable integration clinic',
                'secondary_text': 'QA Dubai',
              },
            ],
            'attributions': [],
          });
        }
        if (r.path.endsWith('details/')) return f.body(details());
        if (r.path.endsWith('link/') && !r.path.endsWith('unlink/')) {
          linked = placeId;
          return f.body(profile(linked));
        }
        if (r.path.endsWith('unlink/')) {
          linked = '';
          return f.body(profile());
        }
        return f.body(profile(linked));
      });
      final c = GoogleBusinessController(
        CurrentClinicGoogleBusinessRepository(),
      );
      addTearDown(c.dispose);
      await c.reload();
      await searchReady(c);
      expect(c.suggestions.single.name, 'Disposable integration clinic');
      await c.select(c.suggestions.single);
      expect(await c.saveLink(), false);
      c.confirmIdentity(true);
      expect(await c.saveLink(), true);
      expect(c.association!.verification, GoogleBusinessVerification.verified);
      expect(await c.unlink(), true);
      expect(c.association!.linked, false);
      final posts = adapter.requests.where((r) => r.method == 'POST').toList();
      expect(posts.map((r) => r.path), [
        'clinic-portal/profile/google-business/autocomplete/',
        'clinic-portal/profile/google-business/details/',
        'clinic-portal/profile/google-business/link/',
        'clinic-portal/profile/google-business/unlink/',
      ]);
      expect(posts[0].data['session_token'], posts[1].data['session_token']);
      expect(posts[2].data, {
        'place_id': placeId,
        'selection_proof': 'disposable-single-use-proof',
        'expected_current_place_id': '',
        'google_maps_url': details()['google_maps_url'],
      });
      expect(posts[3].data, {'expected_current_place_id': placeId});
      expect(adapter.requests.where((r) => r.method == 'PATCH'), isEmpty);
      expect(adapter.requests.last.method, 'GET');
    },
  );
  for (final code in [
    'INVALID_OR_EXPIRED_SELECTION_PROOF',
    'STALE_GOOGLE_ASSOCIATION',
  ]) {
    test(
      '$code keeps refresh gate and never replays a consumed proof',
      () async {
        final adapter = wire((r) async {
          if (r.path.endsWith('autocomplete/')) {
            return f.body({
              'suggestions': [
                {
                  'place_id': placeId,
                  'main_text': 'QA',
                  'secondary_text': 'Dubai',
                },
              ],
            });
          }
          if (r.path.endsWith('details/')) return f.body(details());
          if (r.path.endsWith('link/')) {
            return f.body({
              'error': {'code': code, 'message': 'Rejected disposable proof'},
            }, code.startsWith('STALE') ? 409 : 400);
          }
          return f.body(profile());
        });
        final c = GoogleBusinessController(
          CurrentClinicGoogleBusinessRepository(),
        );
        addTearDown(c.dispose);
        await c.reload();
        await searchReady(c);
        await c.select(c.suggestions.single);
        c.confirmIdentity(true);
        expect(await c.saveLink(), false);
        expect(c.needsRefresh, true);
        expect(await c.saveLink(), false);
        expect(
          adapter.requests.where((r) => r.path.endsWith('link/')),
          hasLength(1),
        );
        expect(
          c.error,
          contains(
            code.startsWith('STALE') ? 'changed elsewhere' : 'already used',
          ),
        );
      },
    );
  }
  test(
    'proof expiry requires new Details without sending a mutation',
    () async {
      final adapter = wire((r) async {
        if (r.path.endsWith('autocomplete/')) {
          return f.body({
            'suggestions': [
              {
                'place_id': placeId,
                'main_text': 'QA',
                'secondary_text': 'Dubai',
              },
            ],
          });
        }
        if (r.path.endsWith('details/')) {
          return f.body({...details(), 'proof_expires_in': 1});
        }
        return f.body(profile());
      });
      var now = DateTime.utc(2026, 10, 25);
      final c = GoogleBusinessController(
        CurrentClinicGoogleBusinessRepository(),
        now: () => now,
      );
      addTearDown(c.dispose);
      await c.reload();
      await searchReady(c);
      await c.select(c.suggestions.single);
      c.confirmIdentity(true);
      now = now.add(const Duration(seconds: 2));
      c.confirmIdentity(true);
      expect(c.proofExpired, true);
      expect(c.confirmed, false);
      expect(await c.saveLink(), false);
      expect(adapter.requests.where((r) => r.path.endsWith('link/')), isEmpty);
    },
  );
  test(
    'bare-list server catalog preserves stable codes and valid parents',
    () async {
      final data = catalog;
      final adapter = wire((r) async => f.body(data[r.path.split('/')[1]]));
      final c = await ServerUaeLocationRepository(api: ApiClient()).load();
      expect(c.emirates, hasLength(7));
      expect(c.cities, hasLength(23));
      expect(c.areas, hasLength(50));
      expect(c.resolve('al-dhannah')!.code, 'ruwais');
      expect(c.resolve('dibba-al-hisn')!.emirateCode, 'SH');
      expect(c.resolve('dibba-al-fujairah')!.emirateCode, 'FU');
      expect(
        c.areas.every((a) => c.cities.any((v) => v.code == a.cityCode)),
        true,
      );
      expect(adapter.requests, hasLength(3));
    },
  );
  test(
    'catalog rejects a cross-emirate area and does not fall back to fake options',
    () async {
      final data = catalog;
      (data['areas'] as List).first['emirate_code'] = 'FU';
      wire((r) async => f.body(data[r.path.split('/')[1]]));
      await expectLater(
        ServerUaeLocationRepository(api: ApiClient()).load(),
        throwsA(isA<ApiException>()),
      );
    },
  );
  test(
    'catalog follows numbered bounded pages without requesting foreign next URL',
    () async {
      final data = catalog;
      final adapter = wire((r) async {
        final name = r.path.split('/')[1];
        final rows = data[name] as List;
        return f.body({
          'results': r.queryParameters['page'] == 2
              ? rows.skip(1).toList()
              : rows.take(1).toList(),
          'next': r.queryParameters['page'] == 2
              ? null
              : 'https://untrusted.invalid/steal',
        });
      });
      final c = await ServerUaeLocationRepository(api: ApiClient()).load();
      expect(c.cities, hasLength(23));
      expect(adapter.requests, hasLength(6));
      expect(adapter.requests.every((r) => !r.path.startsWith('http')), true);
    },
  );
  test(
    'nearby transport preserves server order, kilometres, branch identity and pagination',
    () async {
      final adapter = wire(
        (r) async => f.body({
          'count': 21,
          'next': 'https://untrusted.invalid/?page=2',
          'results': [
            {
              ...f.clinic(),
              'id': 'near-basic',
              'subscription_tier': 'basic',
              'distance_km': 0.48,
              'nearest_branch_id': 'nearest-branch',
              'latitude': 25.11,
              'longitude': 55.21,
            },
            {
              ...f.clinic(),
              'id': 'far-vip',
              'subscription_tier': 'vip',
              'distance_km': 2.5,
              'nearest_branch_id': null,
              'latitude': 25.12,
              'longitude': 55.22,
            },
          ],
        }),
      );
      final repo = BackendNearbyClinicsRepository();
      expect(
        repo.supported,
        false,
        reason: '401560b exposes draft profiles; production query stays gated.',
      );
      final p = await repo.search(
        const NearbySearchQuery(origin: PatientPosition(25.1, 55.2)),
        page: 2,
      );
      expect(p.items.map((r) => r.clinic.id), ['near-basic', 'far-vip']);
      expect(p.items.first.distanceKm, .48);
      expect(p.items.first.branchId, 'nearest-branch');
      expect(p.items.first.branchLocation, isNull);
      expect(p.items.last.branchLocation, isNotNull);
      expect(p.hasMore, true);
      expect(p.reference, NearbyDistanceReference.device);
      expect(adapter.requests.single.path, 'clinics/nearby/');
      expect(adapter.requests.single.queryParameters, {
        'page': 2,
        'page_size': 20,
        'latitude': 25.1,
        'longitude': 55.2,
        'radius_km': 50,
      });
    },
  );
  test(
    'manual nearby uses city without guessed coordinates or unsupported area fields',
    () async {
      final adapter = wire(
        (r) async => f.body({
          'count': 1,
          'next': null,
          'results': [
            {...f.clinic(), 'distance_km': null},
          ],
        }),
      );
      final p = await BackendNearbyClinicsRepository().search(
        NearbySearchQuery(
          locality: UaeLocality(compatibilityUaeCatalog.resolve('Dubai')!),
        ),
      );
      expect(p.items.single.distanceKm, isNull);
      expect(p.reference, NearbyDistanceReference.manualLocality);
      expect(adapter.requests.single.path, 'home/nearby-clinics/');
      expect(adapter.requests.single.queryParameters, {
        'page': 1,
        'page_size': 20,
        'city': 'Dubai',
      });
    },
  );
  for (final data in [
    {'distance': 999},
    {'distance_km': -2},
    {'distance_km': '0.48'},
  ]) {
    test('nearby rejects ambiguous/malformed distance $data', () async {
      wire(
        (r) async => f.body({
          'results': [
            {...f.clinic(), ...data},
          ],
          'next': null,
        }),
      );
      await expectLater(
        BackendNearbyClinicsRepository().search(
          const NearbySearchQuery(origin: PatientPosition(25.1, 55.2)),
        ),
        throwsA(isA<ApiException>()),
      );
    });
  }
  test(
    'OTP destinations use actual successful deliveries and discard raw contacts',
    () {
      final rows = DeletionDelivery.parse({
        'delivery_channel': 'sms',
        'masked_destination': '+971***111',
        'deliveries': [
          {'channel': 'email', 'masked_destination': 'q***@example.invalid'},
          {'channel': 'sms', 'masked_destination': '+971501234567'},
        ],
      });
      expect(rows, hasLength(1));
      expect(rows.single.channel, 'email');
      expect(rows.single.destination, 'q***@example.invalid');
      expect(
        DeletionDelivery.parse({
          'delivery_channel': 'sms',
          'masked_destination': '+971501234567',
        }),
        isEmpty,
      );
    },
  );
  for (final status in [400, 403, 413, 429, 500, 503]) {
    test('video HTTP$status has actionable stage-specific safe feedback', () {
      final failure = ShowcaseVideoFailure(
        VideoSaveStage.upload,
        cause: ApiException(
          message: 'hidden server diagnostics',
          statusCode: status,
        ),
      );
      expect(failure.message, contains('HTTP $status'));
      expect(failure.message, contains('selection is preserved'));
      expect(
        failure.message,
        contains(
          status == 400
              ? 'limits'
              : status == 403
              ? 'VIP'
              : status == 413
              ? 'upload size'
              : status == 429
              ? 'cooldown'
              : 'temporarily unavailable',
        ),
      );
      expect(failure.message, isNot(contains('hidden')));
    });
  }
  test(
    'sole-admin resolution metadata is allowlisted without retaining PII',
    () {
      final e = ApiException.fromDioError(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 400,
            data: {
              'code': 'SOLE_CLINIC_ADMIN',
              'detail': 'Blocked',
              'resolution_options': [
                'transfer_ownership',
                'deactivate_clinic',
                'unexpected-secret',
              ],
            },
          ),
        ),
      );
      expect(e.resolutionOptions, ['transfer_ownership', 'deactivate_clinic']);
      expect(e.rawData, isNull);
    },
  );
  test(
    'administrator exit never mutates until explicitly invoked, then checks ACK',
    () async {
      final adapter = wire(
        (r) async =>
            f.body({'status': 'success', 'new_admin_user_id': f.proposalId}),
      );
      final repo = AuthRepository();
      expect(adapter.requests, isEmpty);
      await repo.resolveClinicDeletion(newAdminUserId: f.proposalId);
      expect(
        adapter.requests.single.path,
        'clinic-portal/profile/transfer-ownership/',
      );
      expect(adapter.requests.single.data, {'new_admin_user_id': f.proposalId});
      expect(AuthState().isLoggedIn, true);
    },
  );
  testWidgets(
    'sole-admin deactivation requires typed confirmation and consent; cancel sends no mutation',
    (tester) async {
      final adapter = wire(
        (r) async => f.body({
          'success': false,
          'code': 'SOLE_CLINIC_ADMIN',
          'detail': 'Blocked',
          'resolution_options': ['deactivate_clinic', 'transfer_ownership'],
        }, 400),
      );
      await f.render(tester, const AccountDeletionScreen());
      await tester.tap(find.byKey(const ValueKey('deletion-request-code')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Review clinic deactivation'),
        200,
      );
      await f.capture(tester, 'sole_admin_resolution_light_en');
      await tester.tap(find.text('Review clinic deactivation'));
      // Parent progress remains active until the dialog returns. Settle only
      // its known route transition, then assert the actual confirmation controls.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final confirm = find.widgetWithText(
        FilledButton,
        'Confirm clinic change',
      );
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('clinic-deletion-resolution-input')),
        'DEACTIVATE',
      );
      await tester.pump(const Duration(milliseconds: 240));
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await f.capture(tester, 'clinic_deactivation_confirmation_light_en');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(adapter.requests, hasLength(1));
      expect(AuthState().isLoggedIn, true);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'explicit confirmed deactivation checks authoritative suspended ACK and never automatically deletes account',
    (tester) async {
      final adapter = wire(
        (r) async => r.path.endsWith('deactivate-clinic/')
            ? f.body({'status': 'success', 'clinic_status': 'suspended'})
            : f.body({
                'success': false,
                'code': 'SOLE_CLINIC_ADMIN',
                'detail': 'Blocked',
                'resolution_options': ['deactivate_clinic'],
              }, 400),
      );
      await f.render(tester, const AccountDeletionScreen());
      await tester.tap(find.byKey(const ValueKey('deletion-request-code')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Review clinic deactivation'),
        200,
      );
      await tester.tap(find.text('Review clinic deactivation'));
      // Parent progress remains active until the dialog returns. Settle only
      // its known route transition, then assert the actual confirmation controls.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(
        find.byKey(const ValueKey('clinic-deletion-resolution-input')),
        'DEACTIVATE',
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Confirm clinic change'),
      );
      await tester.pumpAndSettle();
      expect(adapter.requests.map((r) => r.path), [
        'auth/me/deletion/request/',
        'clinic-portal/profile/deactivate-clinic/',
      ]);
      expect(AuthState().isLoggedIn, true);
      expect(find.textContaining('Clinic change confirmed'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  test(
    'video timeout advises fresh verification and keeps ambiguous receipt semantics',
    () {
      final e = ShowcaseVideoFailure(
        VideoSaveStage.upload,
        cause: const ApiException(message: 'hidden', errorCode: 'TIMEOUT'),
      );
      expect(e.message, contains('may have completed saving'));
      expect(e.receipt, isNull);
    },
  );
  test(
    'Google link rejects an ACK without selected-place verification',
    () async {
      wire((r) async => f.body(profile()));
      final repo = CurrentClinicGoogleBusinessRepository();
      final p = GoogleBusinessPlace(
        placeId: placeId,
        name: 'QA',
        address: 'Dubai',
        locality: 'Dubai',
        latitude: 25.1,
        longitude: 55.2,
        countryCode: 'AE',
        selectionProof: 'QA-proof',
      );
      await expectLater(
        repo.link(p, clinicId: f.id, expectedPlaceId: ''),
        throwsA(isA<ApiException>()),
      );
    },
  );
  test('new Google errors retain only safe codes and no raw diagnostics', () {
    for (final code in [
      'NO_VERIFIED_DELIVERY_CHANNEL',
      'STALE_GOOGLE_ASSOCIATION',
      'INVALID_OR_EXPIRED_SELECTION_PROOF',
      'UNVERIFIED_GOOGLE_PLACE_ID',
    ]) {
      final e = ApiException.fromDioError(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 400,
            data: {
              'error': {'code': code, 'message': 'Rejected'},
            },
          ),
        ),
      );
      expect(e.errorCode, code);
      expect(e.rawData, isNull);
      expect(e.originalBackendMessage, isNull);
    }
  });
  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      testWidgets(
        '401560b business and canonical locality screens dark=$dark ar=$ar',
        (tester) async {
          final data = catalog;
          wire((r) async {
            if (r.path.startsWith('locations/')) {
              return f.body(data[r.path.split('/')[1]]);
            }
            if (r.path.endsWith('autocomplete/')) {
              return f.body({
                'suggestions': [
                  {
                    'place_id': placeId,
                    'main_text': 'Disposable integration clinic',
                    'secondary_text': 'QA Dubai',
                  },
                ],
              });
            }
            if (r.path.endsWith('details/')) return f.body(details());
            return f.body(profile(placeId));
          });
          await f.render(
            tester,
            const GoogleBusinessScreen(),
            dark: dark,
            ar: ar,
          );
          expect(
            find.byKey(const ValueKey('google-business-query')),
            findsOneWidget,
          );
          expect(
            find.textContaining(
              ar ? 'لا يثبت ملكية' : 'does not prove ownership',
            ),
            findsOneWidget,
          );
          await f.capture(
            tester,
            'business_401560b_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          await tester.enterText(
            find.byKey(const ValueKey('google-business-query')),
            'Disposable',
          );
          await tester.pump(const Duration(milliseconds: 351));
          await tester.ensureVisible(
            find.text('Disposable integration clinic'),
          );
          await tester.tap(find.text('Disposable integration clinic'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.byKey(const ValueKey('google-business-identity-confirm')),
          );
          await f.capture(
            tester,
            'business_details_401560b_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          await f.render(
            tester,
            const Scaffold(
              body: UaeLocationPicker(selected: 'Dubai', includeAreas: true),
            ),
            dark: dark,
            ar: ar,
          );
          expect(find.text(ar ? 'دبي' : 'Dubai'), findsWidgets);
          await f.capture(
            tester,
            'localities_401560b_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          await f.render(
            tester,
            const AccountDeletionScreen(),
            dark: dark,
            ar: ar,
          );
          // Supply a real-shape accepted OTP request without claiming delivery.
          ApiClient().dio.httpClientAdapter = f.Adapter(
            (r) => f.body({
              'success': true,
              'delivery_channel': 'sms',
              'masked_destination': '+971******567',
              'deliveries': [
                {'channel': 'sms', 'masked_destination': '+971******567'},
              ],
              'expires_in': 600,
              'resend_cooldown': 60,
            }),
          );
          await tester.tap(find.byKey(const ValueKey('deletion-request-code')));
          await tester.pumpAndSettle();
          expect(find.textContaining('+971******567'), findsOneWidget);
          await f.capture(
            tester,
            'otp_destination_401560b_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.binding.setSurfaceSize(null);
        },
      );
    }
  }
}
