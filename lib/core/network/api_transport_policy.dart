/// Credentials belong only to the configured HTTPS API origin and path prefix.
/// Media/CDN URLs use separate unauthenticated image providers.
abstract class ApiTransportPolicy {
  static bool permits(Uri target, String configuredBase) {
    final base = Uri.tryParse(configuredBase);
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        target.scheme != 'https' ||
        target.userInfo.isNotEmpty ||
        target.hasFragment ||
        target.origin != base.origin) {
      return false;
    }
    final prefix = base.path.endsWith('/') ? base.path : '${base.path}/';
    return target.normalizePath().path.startsWith(prefix);
  }
}
