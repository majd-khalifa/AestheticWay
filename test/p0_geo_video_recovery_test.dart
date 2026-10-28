import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/widgets/patient_video.dart';
import 'package:aesthetic_way/features/home/presentation/screens/home_screen.dart';
import 'package:aesthetic_way/features/locations/services/clinic_location_integrity.dart';
import 'package:aesthetic_way/features/locations/data/uae_location_repository.dart';
import 'package:aesthetic_way/features/clinics/presentation/widgets/patient_clinic_card.dart';
import 'onboarding_review_workflows_test.dart' as f;
import 'video_lifecycle_test.dart' show TrackingVideoPlatform;
import 'support/patient_fixtures.dart';
import 'support/recovery_preview_fixtures.dart';
import 'support/patient_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    AuthState().login(name: 'Disposable QA', phone: 'fixture', role: 'patient');
  });
  tearDown(() => AuthState().logout());
  for (final ar in [false, true]) {
    test(
      'emirate/city and obvious bilingual address conflict is flagged; mixed road names are not geocoded ar=$ar',
      () {
        expect(
          ClinicLocationIntegrity.issue(
            city: 'Dubai',
            emirate: 'Abu Dhabi',
            addressEn: '',
            addressAr: '',
            arabic: ar,
          ),
          isNotNull,
        );
        expect(
          ClinicLocationIntegrity.issue(
            city: 'Dubai',
            emirate: 'DU',
            addressEn: '',
            addressAr: 'ابو ظبي',
            arabic: ar,
          ),
          isNotNull,
        );
        expect(
          ClinicLocationIntegrity.issue(
            city: 'Abu Dhabi',
            emirate: 'AD',
            addressEn: '',
            addressAr: 'ابو ظبي',
            arabic: ar,
          ),
          isNull,
        );
        expect(
          ClinicLocationIntegrity.issue(
            city: 'Dubai',
            emirate: 'Dubai',
            addressEn: 'Sharjah',
            addressAr: '',
            arabic: ar,
          ),
          isNotNull,
        );
        expect(
          ClinicLocationIntegrity.issue(
            city: 'Dubai',
            emirate: 'Dubai',
            addressEn: '',
            addressAr: 'الشارقة',
            arabic: ar,
          ),
          isNotNull,
        );
        expect(
          ClinicLocationIntegrity.issue(
            city: 'Dubai',
            emirate: 'Dubai',
            addressEn: 'Sharjah Road, Dubai',
            addressAr: '',
            arabic: ar,
          ),
          isNull,
        );
        expect(
          ClinicLocationIntegrity.issue(
            city: 'Al Ain',
            emirate: 'Abu Dhabi',
            addressEn: 'Abu Dhabi',
            addressAr: '',
            arabic: ar,
          ),
          isNull,
        );
      },
    );
  }
  testWidgets(
    'Home GPS grant makes the documented nearby call and renders only server distance',
    (t) async {
      final old = GeolocatorPlatform.instance;
      GeolocatorPlatform.instance = ForegroundGps();
      addTearDown(() => GeolocatorPlatform.instance = old);
      final api = ApiClient(), previous = ApiClient().dio.httpClientAdapter;
      final wire = f.Adapter((r) => f.body(homeGpsReply(r)));
      api.dio.httpClientAdapter = wire;
      addTearDown(() => api.dio.httpClientAdapter = previous);
      await f.render(t, const HomeScreen());
      final rootScroll = find
          .descendant(
            of: find.byType(CustomScrollView).first,
            matching: find.byType(Scrollable),
          )
          .first;
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('home-use-location')),
        200,
        scrollable: rootScroll,
      );
      await t.tap(find.byKey(const ValueKey('home-use-location')));
      await t.pumpAndSettle();
      await t.pump(const Duration(milliseconds: 351));
      await t.pumpAndSettle();
      final gps = wire.requests.singleWhere((r) => r.path == 'clinics/nearby/');
      expect(gps.queryParameters['latitude'], 25.1);
      expect(gps.queryParameters['longitude'], 55.2);
      expect(gps.queryParameters.containsKey('city'), false);
      await t.scrollUntilVisible(
        find.text('Approximately 2.4 km away'),
        250,
        scrollable: rootScroll,
      );
      expect(find.text('Near my current location'), findsOneWidget);
      expect(find.text('Approximately 2.4 km away'), findsOneWidget);
      expect(
        wire.requests.where((r) => r.path == 'home/nearby-clinics/'),
        isEmpty,
      );
      await t.pumpWidget(const SizedBox());
      await t.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'branch-filter mismatch remains honest and bilingual aliases avoid false warnings',
    (t) async {
      await f.render(
        t,
        Scaffold(
          body: PatientClinicCard(
            clinic: patientClinic(extra: {'city': 'Abu Dhabi'}),
            filterCity: 'Dubai',
            onTap: () {},
          ),
        ),
      );
      expect(find.textContaining('Primary city: Abu Dhabi'), findsOneWidget);
      await f.render(
        t,
        Scaffold(
          body: PatientClinicCard(
            clinic: patientClinic(),
            filterCity: 'دبي',
            onTap: () {},
          ),
        ),
      );
      expect(find.textContaining('Primary city:'), findsNothing);
      await t.pumpWidget(const SizedBox());
      await t.binding.setSurfaceSize(null);
    },
  );
  for (final accessible in [false, true]) {
    testWidgets(
      'minimal controls hide after3s only while playing, paused and accessible controls remain accessible=$accessible',
      (t) async {
        final previous = VideoPlayerPlatform.instance,
            video = TrackingVideoPlatform();
        VideoPlayerPlatform.instance = video;
        addTearDown(() async {
          VideoPlayerPlatform.instance = previous;
          for (final s in video.streams.values) {
            await s.close();
          }
        });
        await f.render(
          t,
          Builder(
            builder: (ctx) => MediaQuery(
              data: MediaQuery.of(
                ctx,
              ).copyWith(accessibleNavigation: accessible),
              child: const Scaffold(
                body: PatientVideo(
                  videoUrl: 'https://fixture.invalid/public.mp4',
                  autoplay: true,
                ),
              ),
            ),
          ),
        );
        final controls = find.byKey(const ValueKey('patient-video-controls'));
        await t.pump(const Duration(milliseconds: 3100));
        await t.pump(const Duration(milliseconds: 200));
        expect(t.widget<AnimatedOpacity>(controls).opacity, accessible ? 1 : 0);
        await t.tap(find.byType(PatientVideo));
        await t.pumpAndSettle();
        expect(t.widget<AnimatedOpacity>(controls).opacity, 1);
        await t.tap(find.byTooltip('Pause video'));
        await t.pumpAndSettle();
        await t.pump(const Duration(seconds: 5));
        expect(t.widget<AnimatedOpacity>(controls).opacity, 1);
        expect(video.calls, contains('pause:0'));
        await t.pumpWidget(const SizedBox());
        await t.pumpAndSettle();
        await t.binding.setSurfaceSize(null);
      },
    );
  }
  test(
    'catalog city normalization does not invent a location for unknown text',
    () {
      expect(currentUaeCatalog.resolve('دبي')!.nameEn, 'Dubai');
      expect(currentUaeCatalog.resolve('invented-locality'), isNull);
    },
  );
}
