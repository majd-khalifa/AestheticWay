import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// pumpAndSettle does not wait for asynchronous asset decoding. Wait for each
/// mounted provider's real decoded frame before comparing pixels; a bad fixture
/// fails rather than recording a blank image as the accepted golden.
Future<void> settlePreviewImages(WidgetTester tester) async {
  final providers = tester
      .widgetList<Image>(find.byType(Image))
      .map((w) => w.image)
      .toSet();
  await tester.runAsync(() async {
    for (final provider in providers) {
      final ready = Completer<void>();
      final stream = provider.resolve(ImageConfiguration.empty);
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (frame, sync) {
          if (!ready.isCompleted) ready.complete();
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
  });
  await tester.pumpAndSettle();
}
