import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Decode the *mounted* providers with their real configurations. A FileImage
/// load started during pumpWidget can be pending in FakeAsync. Resolving it in
/// runAsync alone just returns that same stalled completer from ImageCache.
/// Evict only pending keys, decode in the real zone, then use Flutter's cache
/// reassembly hook to reconnect ImageState to the decoded stream. No guessed
/// paths, resize dimensions, DPR or global cache clearing are involved.
Future<void> settlePreviewImages(WidgetTester tester) async {
  final mounted = [
    for (final element in find.byType(Image).evaluate())
      (
        element.widget as Image,
        createLocalImageConfiguration(
          element,
          size:
              (element.widget as Image).width != null &&
                  (element.widget as Image).height != null
              ? Size(
                  (element.widget as Image).width!,
                  (element.widget as Image).height!,
                )
              : null,
        ),
      ),
  ];
  final failure = await tester.runAsync<({Object error, StackTrace stack})?>(
    () async {
      try {
        final seen = <Object>{};
        for (final (image, configuration) in mounted) {
          final provider = image.image;
          final key = await provider.obtainKey(configuration);
          if (!seen.add(key)) continue;
          final cache = PaintingBinding.instance.imageCache;
          if (cache.statusForKey(key).pending) {
            cache.evict(key, includeLive: true);
          }
          final ready = Completer<void>();
          final stream = provider.resolve(configuration);
          late ImageStreamListener listener;
          listener = ImageStreamListener(
            (frame, sync) {
              try {
                if (frame.image.width <= 0 || frame.image.height <= 0) {
                  throw StateError('Decoded preview frame has no pixels.');
                }
                if (!ready.isCompleted) ready.complete();
              } catch (error, stack) {
                if (!ready.isCompleted) ready.completeError(error, stack);
              } finally {
                frame.dispose();
              }
            },
            onError: (Object error, StackTrace? stack) {
              if (!ready.isCompleted) ready.completeError(error, stack);
            },
          );
          stream.addListener(listener);
          try {
            await ready.future.timeout(const Duration(seconds: 3));
          } finally {
            stream.removeListener(listener);
          }
        }
        return null;
      } catch (error, stack) {
        return (error: error, stack: stack);
      }
    },
  );
  // Keep failures in the test zone, rather than leaving runAsync's exception
  // queue to fail a later takeException() with an unrelated source location.
  if (failure != null) Error.throwWithStackTrace(failure.error, failure.stack);
  final reassembled = tester.binding.reassembleApplication();
  await tester.pump();
  await reassembled;
  await tester.pumpAndSettle();
  for (final element in find.byType(Image).evaluate()) {
    final raw = find.descendant(
      of: find.byElementPredicate((candidate) => identical(candidate, element)),
      matching: find.byType(RawImage),
    );
    expect(
      raw,
      findsOneWidget,
      reason: 'Each preview Image must paint its decoded frame.',
    );
    expect(
      tester.widget<RawImage>(raw).image,
      isNotNull,
      reason: 'A pending or fallback-only preview must not be accepted.',
    );
  }
}
