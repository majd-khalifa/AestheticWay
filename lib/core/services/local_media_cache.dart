import 'dart:io';
import 'package:flutter/foundation.dart';
import '../network/api_config.dart';

/// Session-only pointers to picked files. Never deletes or owns the source files.
/// Remote storage remains authoritative across devices and application restarts.
class LocalMediaCache extends ChangeNotifier {
  LocalMediaCache._();
  static final LocalMediaCache _instance = LocalMediaCache._();
  factory LocalMediaCache() => _instance;
  static const int maxEntries = 256;
  final _entities = <String, _LocalMedia>{};
  final _urls = <String, _LocalMedia>{};
  int _epoch = 0;
  int get epoch => _epoch;
  static String clinicLogo(String id) => 'clinic_logo_$id';
  static String clinicCover(String id) => 'clinic_cover_$id';
  static String entity(String kind, String id) => '${kind}_$id';

  bool remember({
    required String localPath,
    String? entityKey,
    String? remoteUrl,
    int? expectedEpoch,
  }) {
    if (expectedEpoch != null && expectedEpoch != _epoch) return false;
    late File file;
    try {
      final uri = Uri.tryParse(localPath);
      file = uri?.scheme == 'file' ? File.fromUri(uri!) : File(localPath);
      if (!file.existsSync()) return false;
    } on FileSystemException {
      return false;
    } on ArgumentError {
      return false;
    }
    final aliases = <String>{
      if (remoteUrl != null && remoteUrl.trim().isNotEmpty) remoteUrl.trim(),
      if (remoteUrl != null && remoteUrl.trim().isNotEmpty)
        ApiConfig.resolveUrl(remoteUrl),
    };
    if ((entityKey == null || entityKey.isEmpty) && aliases.isEmpty) {
      return false;
    }
    if (entityKey != null) _removeEntity(entityKey);
    final entry = _LocalMedia(file.path, aliases);
    if (entityKey != null && entityKey.isNotEmpty) _entities[entityKey] = entry;
    for (final url in aliases) {
      _urls.remove(url);
      _urls[url] = entry;
    }
    while (_entities.length > maxEntries) {
      _removeEntity(_entities.keys.first);
    }
    while (_urls.length > maxEntries * 2) {
      _urls.remove(_urls.keys.first);
    }
    notifyListeners();
    return true;
  }

  String? lookup({String? entityKey, String? remoteUrl}) {
    final url = remoteUrl == null || remoteUrl.trim().isEmpty
        ? null
        : ApiConfig.resolveUrl(remoteUrl);
    final direct = url == null ? null : _urls[url];
    final entity = entityKey == null ? null : _entities[entityKey];
    // A different server URL may represent a newer edit from another device.
    final entry =
        direct ??
        (entity != null &&
                (url == null ||
                    entity.urls.isEmpty ||
                    (entity.urls.contains(url) ||
                        entity.urls.any(
                          (prior) => _sameSignedObject(prior, url),
                        )))
            ? entity
            : null);
    if (entry == null) return null;
    if (File(entry.path).existsSync()) return entry.path;
    _urls.removeWhere((_, value) => identical(value, entry));
    _entities.removeWhere((_, value) => identical(value, entry));
    return null;
  }

  bool _sameSignedObject(String a, String b) {
    final left = Uri.tryParse(a), right = Uri.tryParse(b);
    if (left == null ||
        right == null ||
        left.scheme != right.scheme ||
        left.host != right.host ||
        left.port != right.port ||
        left.path != right.path) {
      return false;
    }
    bool signed(Uri uri) => uri.queryParameters.keys.any(
      (k) => k.toLowerCase() == 'x-amz-signature',
    );
    if (!signed(left) || !signed(right)) return false;
    Map<String, List<String>> identity(Uri uri) =>
        Map.of(uri.queryParametersAll)
          ..removeWhere((key, _) => key.toLowerCase().startsWith('x-amz-'));
    final x = identity(left), y = identity(right);
    return x.length == y.length &&
        x.entries.every((entry) => listEquals(entry.value, y[entry.key]));
  }

  void _removeEntity(String key) {
    final entry = _entities.remove(key);
    if (entry != null) _urls.removeWhere((_, value) => identical(value, entry));
  }

  void remove(String entityKey) {
    _removeEntity(entityKey);
    notifyListeners();
  }

  void clear() {
    ++_epoch;
    _entities.clear();
    _urls.clear();
    notifyListeners();
  }
}

class _LocalMedia {
  const _LocalMedia(this.path, this.urls);
  final String path;
  final Set<String> urls;
}
