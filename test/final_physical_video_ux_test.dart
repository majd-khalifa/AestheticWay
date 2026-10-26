import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/lazy_tab_stack.dart';
import 'package:aesthetic_way/core/widgets/patient_video.dart';
import 'package:aesthetic_way/features/home/presentation/widgets/featured_ads_carousel.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinic_profile_screen.dart';
import 'package:aesthetic_way/features/clinics/presentation/widgets/patient_clinic_gallery.dart';
import 'package:aesthetic_way/features/clinics/data/clinics_repository.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'support/patient_fixtures.dart';
import 'support/patient_visual_harness.dart';
import 'video_lifecycle_test.dart' show TrackingVideoPlatform;
import 'clinic_media_contract_test.dart' show finishNativeWork;

class ControlledVideo extends TrackingVideoPlatform {
  final sources = <DataSource>[];
  final positions = <int, Duration>{};
  final volumes = <double>[];
  @override
  Future<int> createWithOptions(VideoCreationOptions options) async {
    sources.add(options.dataSource);
    return super.createWithOptions(options);
  }

  @override
  Future<Duration> getPosition(int playerId) async =>
      positions[playerId] ?? Duration.zero;
  @override
  Future<void> seekTo(int playerId, Duration position) async {
    positions[playerId] = position;
    await super.seekTo(playerId, position);
  }

  @override
  Future<void> setVolume(int playerId, double volume) async =>
      volumes.add(volume);
  void buffering(int id, bool value) => streams[id]!.add(
    VideoEvent(
      eventType: value
          ? VideoEventType.bufferingStart
          : VideoEventType.bufferingEnd,
    ),
  );
  void complete(int id) =>
      streams[id]!.add(VideoEvent(eventType: VideoEventType.completed));
}

class ControlledPublicClinic extends ClinicsRepository {
  ControlledPublicClinic(this.clinic);
  final ClinicModel clinic;
  final pending = Completer<ClinicModel>();
  bool failure = false;
  @override
  Future<ClinicModel> getClinicDetail(String idOrSlug) =>
      failure ? Future.error(StateError('Not public')) : pending.future;
}

Widget carousel() => Scaffold(
  body: SingleChildScrollView(
    child: FeaturedAdsCarousel(
      ads: [
        patientClinic(
          extra: {
            'subscription_tier': 'vip',
            'video_url': 'https://fixture.invalid/public-showcase.mp4',
          },
        ),
        patientClinic(
          extra: {
            'id': 'second-clinic',
            'name_en': 'Second fixture',
            'subscription_tier': 'basic',
          },
        ),
      ],
      onClinicTap: (_) {},
      onContactTap: (_) {},
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  late ControlledVideo video;
  late VideoPlayerPlatform old;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    AuthState().login(name: 'Disposable QA', phone: 'fixture', role: 'patient');
    await LocaleService().setLanguage(AppLanguage.english);
    old = VideoPlayerPlatform.instance;
    video = ControlledVideo();
    VideoPlayerPlatform.instance = video;
  });
  tearDown(() async {
    VideoPlayerPlatform.instance = old;
    for (final stream in video.streams.values) {
      await stream.close();
    }
    AuthState().logout();
  });
  Future<void> mount(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(
      MaterialApp(theme: patientVisualTheme(dark: false), home: widget),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  testWidgets(
    'decoder failure preserves poster, retry creates one fresh player and logout releases it',
    (tester) async {
      await mount(
        tester,
        const Scaffold(
          body: PatientVideo(
            videoUrl: 'https://fixture.invalid/public.mp4',
            autoplay: true,
          ),
        ),
      );
      video.streams[0]!.addError(
        PlatformException(
          code: 'VideoError',
          message: 'private decoder details',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Video could not load. You can retry.'), findsOneWidget);
      expect(find.textContaining('private decoder'), findsNothing);
      await finishNativeWork(tester, () => video.calls.contains('dispose:0'));
      expect(video.calls, contains('dispose:0'));
      await tester.tap(find.byTooltip('Retry video'));
      await tester.pumpAndSettle();
      expect(video.created, 2);
      expect(video.calls, contains('play:1'));
      AuthState().logout();
      await tester.pumpAndSettle();
      await finishNativeWork(tester, () => video.calls.contains('dispose:1'));
      expect(video.calls, contains('dispose:1'));
      expect(tester.takeException(), isNull);
      await unmount(tester);
    },
  );
  testWidgets('explicitly unpublished detail never mounts patient video', (
    tester,
  ) async {
    final clinic = patientClinic(
      extra: {
        'setup_status': 'submitted',
        'video_url': 'https://fixture.invalid/public.mp4',
      },
    );
    final repo = ControlledPublicClinic(clinic)..pending.complete(clinic);
    await mount(
      tester,
      ClinicProfileScreen(clinic: clinic, clinicsRepository: repo),
    );
    expect(find.byType(PatientVideo), findsNothing);
    expect(video.created, 0);
    await unmount(tester);
  });
  testWidgets(
    '4-second boundary cannot advance a playing video;15s completion advances exactly once',
    (tester) async {
      await mount(tester, carousel());
      expect(find.text('1 / 2'), findsOneWidget);
      expect(video.created, 1);
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 650));
      expect(find.text('1 / 2'), findsOneWidget);
      video.positions[0] = const Duration(seconds: 14);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('1 / 2'), findsOneWidget);
      video.positions[0] = const Duration(seconds: 15);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);
      expect(video.calls, contains('pause:0'));
      expect(video.calls, isNot(contains('seek:0:0')));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('2 / 2'), findsOneWidget);
      await unmount(tester);
    },
  );
  testWidgets(
    'buffering holds slide across4s and manual pause never triggers a transition',
    (tester) async {
      await mount(tester, carousel());
      video.buffering(0, true);
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(find.text('1 / 2'), findsOneWidget);
      video.buffering(0, false);
      await tester.pump();
      await tester.tap(find.byTooltip('Pause video').first);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 16));
      await tester.pump();
      expect(find.text('1 / 2'), findsOneWidget);
      expect(video.created, 1);
      expect(video.calls, isNot(contains('dispose:0')));
      await unmount(tester);
    },
  );
  testWidgets(
    'image-only slide advances once at4s and manual swipe interrupts playback',
    (tester) async {
      await mount(tester, carousel());
      await tester.drag(find.byType(PageView), const Offset(-650, 0));
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      expect(video.calls, contains('dispose:0'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 650));
      expect(find.text('1 / 2'), findsOneWidget);
      await unmount(tester);
    },
  );
  testWidgets(
    'reduced motion never auto-advances even after explicitly played video completes',
    (tester) async {
      await mount(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: carousel(),
          ),
        ),
      );
      expect(video.created, 0);
      await tester.tap(find.byTooltip('Play video').first);
      await tester.pumpAndSettle();
      video.complete(0);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 16));
      expect(find.text('1 / 2'), findsOneWidget);
      await unmount(tester);
    },
  );
  testWidgets(
    'navigation, background and tab changes release codec and preserve a user pause',
    (tester) async {
      bool active = true;
      late StateSetter change;
      await mount(
        tester,
        StatefulBuilder(
          builder: (context, set) {
            change = set;
            return TabActivity(active: active, child: carousel());
          },
        ),
      );
      await tester.tap(find.byTooltip('Pause video').first);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('1 / 2'), findsOneWidget);
      change(() => active = false);
      await tester.pumpAndSettle();
      expect(video.calls, contains('pause:0'));
      change(() => active = true);
      await tester.pumpAndSettle();
      expect(
        video.created,
        1,
        reason: 'An explicit pause must not restart a hidden codec.',
      );
      final context = tester.element(find.byType(FeaturedAdsCarousel));
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Other route')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      Navigator.of(tester.element(find.text('Other route'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);
      await unmount(tester);
    },
  );
  testWidgets(
    'public detail ACK required; gallery retains photos and video supports mute/fullscreen/back',
    (tester) async {
      final clinic = patientClinic(
        extra: {
          'video_url': 'https://fixture.invalid/real-public.mp4',
          'gallery_images': ['assets/images/aesthetic_way_logo.png'],
        },
      );
      final repo = ControlledPublicClinic(clinic);
      await tester.pumpWidget(
        MaterialApp(
          home: ClinicProfileScreen(clinic: clinic, clinicsRepository: repo),
        ),
      );
      await tester.pump();
      expect(find.byType(PatientVideo), findsNothing);
      repo.pending.complete(clinic);
      await tester.pumpAndSettle();
      expect(find.byType(PatientVideo), findsOneWidget);
      expect(video.created, 0, reason: 'Patient detail playback is opt-in.');
      await tester.tap(find.byTooltip('Play video'));
      await tester.pumpAndSettle();
      expect(
        video.sources.single.uri,
        'https://fixture.invalid/real-public.mp4',
      );
      await tester.tap(find.byTooltip('Unmute video'));
      await tester.pump();
      expect(video.volumes.last, 1);
      await tester.tap(find.byTooltip('Full screen'));
      await tester.pumpAndSettle();
      expect(find.text('Clinic video'), findsOneWidget);
      expect(video.created, 2);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(PatientClinicGallery), findsOneWidget);
      expect(find.byTooltip('Play video'), findsOneWidget);
      await unmount(tester);
    },
  );
  for (final media in [
    '',
    'file:///private.mp4',
    'https://fixture.invalid/a.jpg',
  ]) {
    testWidgets(
      'absent/invalid public video never creates a media player: $media',
      (tester) async {
        final clinic = patientClinic(extra: {'video_url': media});
        final repo = ControlledPublicClinic(clinic)..failure = media.isEmpty;
        if (!repo.failure) repo.pending.complete(clinic);
        await mount(
          tester,
          ClinicProfileScreen(clinic: clinic, clinicsRepository: repo),
        );
        expect(find.byType(PatientVideo), findsNothing);
        expect(video.created, 0);
        await unmount(tester);
      },
    );
  }
}
