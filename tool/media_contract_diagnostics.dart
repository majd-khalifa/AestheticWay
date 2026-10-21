// Run: dart run tool/media_contract_diagnostics.dart redacted-response.json
// Local opt-in diagnostic. Never prints URLs, hosts, paths, IDs or query values.
import 'dart:convert';
import 'dart:io';
import 'package:aesthetic_way/core/network/api_config.dart';

Map<String, Object> describeMedia(Object? raw) {
  final value = raw is String ? raw.trim() : '';
  final resolved = ApiConfig.resolveUrl(value);
  final uri = Uri.tryParse(resolved);
  return {
    'supplied': value.isNotEmpty,
    'kind': value.isEmpty
        ? 'absent'
        : value.startsWith('assets/')
        ? 'asset'
        : RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value)
        ? 'windows_file'
        : value.startsWith('file:') ||
              value.startsWith('/') && !value.startsWith('/media/')
        ? 'local_or_root_relative'
        : 'network_or_storage',
    'resolved_http':
        uri?.hasAuthority == true && ['http', 'https'].contains(uri?.scheme),
    'has_query': uri?.hasQuery ?? false,
  };
}

Object mediaDiagnostics(Object? data) {
  const fields = {
    'logo',
    'logo_url',
    'cover_image',
    'cover_image_url',
    'image',
    'image_url',
    'avatar',
    'avatar_url',
    'video_url',
    'video_ad_file',
  };
  if (data is List) return data.map(mediaDiagnostics).toList();
  if (data is Map) {
    return <String, Object>{
      for (final field in fields)
        if (data.containsKey(field)) field: describeMedia(data[field]),
      for (final field in [
        'results',
        'clinic',
        'featured_ads',
        'nearby_clinics',
        'active_offers',
      ])
        if (data[field] is List || data[field] is Map)
          field: mediaDiagnostics(data[field]),
    };
  }
  return <String, Object>{};
}

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/media_contract_diagnostics.dart response.json',
    );
    exitCode = 64;
    return;
  }
  try {
    final data = jsonDecode(File(args.single).readAsStringSync());
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert(mediaDiagnostics(data)),
    );
  } catch (_) {
    stderr.writeln('Unable to inspect response. Check the local JSON file.');
    exitCode = 65;
  }
}
