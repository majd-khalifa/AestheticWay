import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/widgets/patient_media_placeholder.dart';

/// Real image streams must fail for the deliberately corrupt provider. Valid
/// images must still decode. No global error swallowing or placeholder success.
Future<int> settleExpectedMediaErrors(
  WidgetTester tester, {
  required bool Function(ImageProvider) isExpectedFailure,
}) async {
  final mounted = [
    for (final element in find.byType(Image).evaluate())
      (element.widget as Image, createLocalImageConfiguration(element)),
  ];
  var failures = 0;
  final unexpected = await tester.runAsync<({Object error, StackTrace stack})?>(
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
          final expected = isExpectedFailure(provider);
          final listener = ImageStreamListener(
            (frame, sync) {
              if (!ready.isCompleted) {
                if (expected) {
                  ready.completeError(
                    StateError('Corrupt fixture unexpectedly decoded.'),
                  );
                } else if (frame.image.width <= 0 || frame.image.height <= 0) {
                  ready.completeError(
                    StateError('Decoded frame has no pixels.'),
                  );
                } else {
                  ready.complete();
                }
              }
              frame.dispose();
            },
            onError: (Object error, StackTrace? stack) {
              if (ready.isCompleted) return;
              if (expected) {
                failures++;
                ready.complete();
              } else {
                ready.completeError(error, stack);
              }
            },
          );
          stream.addListener(listener);
          try {
            await ready.future.timeout(const Duration(seconds: 3));
          } finally {
            stream.removeListener(listener);
          }
        }
        // Failed decodes leave the cache. Reconnect ImageState in the real
        // zone and await its new shared error stream instead of starting that
        // uncached FileImage again inside FakeAsync.
        // Public widget-tree reassembly avoids the renderer's warm-up-frame
        // timer while retaining ImageState's real reconnect behavior.
        tester.binding.buildOwner!.reassemble(tester.binding.rootElement!);
        for (final (image, configuration) in mounted) {
          if (!isExpectedFailure(image.image)) continue;
          final stream = image.image.resolve(configuration);
          final failed = Completer<void>();
          final listener = ImageStreamListener(
            (frame, _) {
              frame.dispose();
              if (!failed.isCompleted) {
                failed.completeError(
                  StateError('Corrupt fixture decoded after reassembly.'),
                );
              }
            },
            onError: (Object error, StackTrace? stack) {
              if (!failed.isCompleted) failed.complete();
            },
          );
          stream.addListener(listener);
          try {
            await failed.future.timeout(const Duration(seconds: 3));
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
  if (unexpected != null) {
    Error.throwWithStackTrace(unexpected.error, unexpected.stack);
  }
  await tester.pumpAndSettle();
  for (final element in find.byType(Image).evaluate()) {
    final image = element.widget as Image;
    final slot = find.byElementPredicate(
      (candidate) => identical(candidate, element),
    );
    if (isExpectedFailure(image.image)) {
      expect(
        find.descendant(
          of: slot,
          matching: find.byType(PatientMediaPlaceholder),
        ),
        findsOneWidget,
        reason: 'The genuine decode failure must select the real fallback.',
      );
    } else {
      final raw = find.descendant(of: slot, matching: find.byType(RawImage));
      expect(raw, findsOneWidget);
      expect(tester.widget<RawImage>(raw).image, isNotNull);
    }
  }
  return failures;
}
