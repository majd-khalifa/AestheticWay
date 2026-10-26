import 'dart:io';
import 'package:flutter_map/flutter_map.dart';

/// No tile fixture or live request: Flutter tests retain their HTTP400 boundary.
/// Own the native cache explicitly so Windows file locks and path_provider
/// plugins do not leak into otherwise pure widget renders.
class OfflineMapTestCache {
  final directory = Directory.systemTemp.createTempSync('aw-offline-map-');
  late final BuiltInMapCachingProvider provider;
  OfflineMapTestCache() {
    provider = BuiltInMapCachingProvider.getOrCreateInstance(
      cacheDirectory: directory.path,
      maxCacheSize: null,
      readOnly: true,
    );
  }
  Future<void> close() async {
    await provider.destroy();
    if (directory.existsSync()) await directory.delete(recursive: true);
  }
}
