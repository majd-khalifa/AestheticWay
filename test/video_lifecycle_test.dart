import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:aesthetic_way/core/widgets/lazy_tab_stack.dart';
import 'package:aesthetic_way/features/home/presentation/widgets/featured_ads_carousel.dart';

class TrackingVideoPlatform extends VideoPlayerPlatform {
  int created = 0;
  bool delayInitialization = false;
  final calls = <String>[];
  final streams = <int, StreamController<VideoEvent>>{};
  @override
  Future<void> init() async {}
  @override
  Future<int> createWithOptions(VideoCreationOptions options) async {
    final id = created++;
    streams[id] = StreamController<VideoEvent>();
    if (!delayInitialization) {
      scheduleMicrotask(() => initialize(id));
    }
    return id;
  }

  void initialize(int id) => streams[id]!.add(
    VideoEvent(
      eventType: VideoEventType.initialized,
      size: const Size(640, 360),
      duration: const Duration(seconds: 30),
    ),
  );
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => streams[playerId]!.stream;
  @override
  Future<void> play(int playerId) async => calls.add('play:$playerId');
  @override
  Future<void> pause(int playerId) async => calls.add('pause:$playerId');
  @override
  Future<void> dispose(int playerId) async => calls.add('dispose:$playerId');
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Widget buildView(int playerId) => const ColoredBox(color: Colors.black);
}

void main() {
  late TrackingVideoPlatform fake;
  late VideoPlayerPlatform original;
  setUp(() {
    original = VideoPlayerPlatform.instance;
    fake = TrackingVideoPlatform();
    VideoPlayerPlatform.instance = fake;
  });
  tearDown(() async {
    VideoPlayerPlatform.instance = original;
    for (final stream in fake.streams.values) {
      await stream.close();
    }
  });
  testWidgets(
    'inactive slides allocate no codec, active slide pauses and disposes when tab hides',
    (tester) async {
      var active = false;
      var tab = true;
      late StateSetter change;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, state) {
              change = state;
              return TabActivity(active: tab, child: constSized(active));
            },
          ),
        ),
      );
      await tester.pump();
      expect(fake.created, 0);
      change(() => active = true);
      await tester.pumpAndSettle();
      expect(fake.created, 1);
      expect(fake.calls, contains('play:0'));
      change(() => tab = false);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      expect(fake.calls, containsAll(['pause:0', 'dispose:0']));
      change(() => tab = true);
      await tester.pumpAndSettle();
      expect(fake.created, 2);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(fake.calls, contains('dispose:1'));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(fake.created, 3);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      expect(fake.calls, contains('dispose:2'));
    },
  );
  testWidgets(
    'vertical offscreen slide releases controller and late initialization never plays',
    (tester) async {
      fake.delayInitialization = true;
      final scroll = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: ListView(
            controller: scroll,
            cacheExtent: 2000,
            children: [constSized(true), const SizedBox(height: 2000)],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(fake.created, 1);
      scroll.jumpTo(800);
      await tester.pump();
      fake.initialize(0);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      expect(fake.calls, isNot(contains('play:0')));
      expect(fake.calls, contains('dispose:0'));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      scroll.dispose();
    },
  );
}

Widget constSized(bool active) => SizedBox(
  height: 220,
  width: 320,
  child: FeaturedAdSlideMedia(
    imageUrl: null,
    videoUrl: 'https://test.invalid/clinic.mp4',
    isActive: active,
  ),
);
