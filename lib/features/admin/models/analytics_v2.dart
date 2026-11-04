import '../../../core/analytics/analytics_ids.dart' show isAnalyticsUuid;
import 'admin_reporting_period.dart';

const analyticsMetricKeys = [
  'clinic_views',
  'whatsapp_taps',
  'call_taps',
  'maps_taps',
  'lead_submissions',
];

Never _invalid() =>
    throw const FormatException('Invalid Analytics v2 contract');
Map<String, dynamic> _map(Object? v) =>
    v is Map<String, dynamic> ? v : _invalid();
int _number(Object? v) => v is int && v >= 0 ? v : _invalid();
int? _nullable(Object? v) => v == null ? null : _number(v);
String _text(Object? v) => v is String ? v : _invalid();
DateTime _instant(Object? v) {
  final value = _text(v);
  if (!RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(value)) _invalid();
  return DateTime.parse(value).toUtc();
}

class AnalyticsV2Query {
  AnalyticsV2Query({
    required this.from,
    required this.to,
    this.search = '',
    this.page = 1,
    this.pageSize = 20,
    this.includeDeleted = false,
    this.seriesPage = 1,
    this.seriesPageSize = 31,
    this.compare = false,
  }) {
    final first = AdminReportingPeriod.parse(from);
    final last = AdminReportingPeriod.parse(to);
    final days = DateTime.utc(
      last.year,
      last.month,
      last.day,
    ).difference(DateTime.utc(first.year, first.month, first.day)).inDays;
    if (days < 0 ||
        days >= 366 ||
        first.year < 2000 ||
        last.year > 9998 ||
        search.length > 120 ||
        page < 1 ||
        pageSize < 1 ||
        pageSize > 100 ||
        seriesPage < 1 ||
        seriesPageSize < 1 ||
        seriesPageSize > 100) {
      throw const FormatException('Invalid Analytics v2 filters');
    }
  }
  factory AnalyticsV2Query.initial() {
    final today = AdminReportingPeriod.dubaiToday();
    return AnalyticsV2Query(
      from: AdminReportingPeriod.format(
        today.subtract(const Duration(days: 30)),
      ),
      to: AdminReportingPeriod.format(today),
    );
  }
  final String from, to, search;
  final int page, pageSize, seriesPage, seriesPageSize;
  final bool includeDeleted, compare;
  Map<String, dynamic> get parameters => {
    'date_from': from,
    'date_to': to,
    'search': search,
    'page': page,
    'page_size': pageSize,
    'include_deleted': includeDeleted,
    'series_page': seriesPage,
    'series_page_size': seriesPageSize,
    'compare': compare,
  };
  AnalyticsV2Query copyWith({
    String? from,
    String? to,
    String? search,
    int? page,
    bool? includeDeleted,
    int? seriesPage,
    bool? compare,
  }) => AnalyticsV2Query(
    from: from ?? this.from,
    to: to ?? this.to,
    search: search ?? this.search,
    page: page ?? this.page,
    pageSize: pageSize,
    includeDeleted: includeDeleted ?? this.includeDeleted,
    seriesPage: seriesPage ?? this.seriesPage,
    seriesPageSize: seriesPageSize,
    compare: compare ?? this.compare,
  );
  DateTime get start =>
      DateTime.parse('${from}T00:00:00Z').subtract(const Duration(hours: 4));
  DateTime get end => DateTime.parse(
    '${to}T00:00:00Z',
  ).add(const Duration(days: 1)).subtract(const Duration(hours: 4));
}

enum AnalyticsCoverage { complete, partial, unavailable }

AnalyticsCoverage _coverage(Object? value) => switch (_map(value)['state']) {
  'complete' => AnalyticsCoverage.complete,
  'partial' => AnalyticsCoverage.partial,
  'unavailable' => AnalyticsCoverage.unavailable,
  _ => _invalid(),
};

class AnalyticsMetric {
  const AnalyticsMetric(this.count, this.recorded, this.trusted, this.coverage);
  factory AnalyticsMetric.parse(
    Object? count,
    Object? recorded,
    Object? trusted,
    Object? coverage,
  ) {
    final state = _coverage(coverage);
    final value = _nullable(count);
    return AnalyticsMetric(
      state == AnalyticsCoverage.complete ? value : null,
      _number(recorded),
      _number(trusted),
      state,
    );
  }
  final int? count;
  final int recorded, trusted;
  final AnalyticsCoverage coverage;
}

class AnalyticsV2Metrics {
  AnalyticsV2Metrics.fromJson(Map<String, dynamic> json) {
    final counts = _map(json['counts']);
    final raw = _map(json['recorded_counts']);
    final trusted = _map(json['trusted_recorded_counts']);
    final coverage = _map(json['coverage']);
    values = Map.unmodifiable({
      for (final k in analyticsMetricKeys)
        k: AnalyticsMetric.parse(counts[k], raw[k], trusted[k], coverage[k]),
    });
    recordedTotal = _number(json['recorded_total_events']);
    final allKnown = values.values.every((m) => m.count != null);
    final wireTotal = _nullable(json['total_events']);
    total = allKnown ? wireTotal : null;
    if (total != null &&
        total != values.values.fold<int>(0, (n, m) => n + m.count!)) {
      _invalid();
    }
    if (recordedTotal != values.values.fold<int>(0, (n, m) => n + m.recorded)) {
      _invalid();
    }
    // This source contract deliberately does not provide a unique-user estimate.
    if (json['unique_authenticated_accounts'] != null) _invalid();
  }
  late final Map<String, AnalyticsMetric> values;
  late final int recordedTotal;
  late final int? total;
}

class AnalyticsV2Clinic {
  AnalyticsV2Clinic.fromJson(Map<String, dynamic> json)
    : id = _text(json['clinic_id']),
      nameEn = _text(json['name_en']),
      nameAr = _text(json['name_ar']),
      status = _text(json['status']),
      setupStatus = _text(json['setup_status']),
      tier = _text(json['subscription_tier']),
      deleted = json['is_deleted'] == true,
      metrics = AnalyticsV2Metrics.fromJson(json) {
    if (!isAnalyticsUuid(id) || json['is_deleted'] is! bool) _invalid();
  }
  final String id, nameEn, nameAr, status, setupStatus, tier;
  final bool deleted;
  final AnalyticsV2Metrics metrics;
  String name(bool arabic) =>
      arabic && nameAr.trim().isNotEmpty ? nameAr : nameEn;
}

class AnalyticsV2Metadata {
  AnalyticsV2Metadata.fromJson(
    Map<String, dynamic> json,
    AnalyticsV2Query query,
  ) : from = _text(json['date_from']),
      to = _text(json['date_to']),
      start = _instant(json['start_utc']),
      end = _instant(json['end_utc_exclusive']),
      generated = _instant(json['generated_at']),
      appOpens = _appMetric(json) {
    if (json['schema_version'] != 2 ||
        json['timezone'] != 'Asia/Dubai' ||
        from != query.from ||
        to != query.to ||
        start != query.start ||
        end != query.end) {
      _invalid();
    }
  }
  static AnalyticsMetric _appMetric(Map<String, dynamic> json) {
    final app = _map(_map(json['platform'])['app_opens']);
    return AnalyticsMetric.parse(
      app['count'],
      app['recorded_count'],
      app['trusted_recorded_count'],
      app['coverage'],
    );
  }

  final String from, to;
  final DateTime start, end, generated;
  final AnalyticsMetric appOpens;
}

class AnalyticsV2Page {
  AnalyticsV2Page.fromJson(Map<String, dynamic> json, AnalyticsV2Query query)
    : metadata = AnalyticsV2Metadata.fromJson(json, query),
      count = _number(json['count']),
      clinics = List.unmodifiable(
        (json['results'] as List).map(
          (r) => AnalyticsV2Clinic.fromJson(_map(r)),
        ),
      ),
      hasNext = json['next'] != null {
    if (clinics.length > query.pageSize ||
        clinics.map((c) => c.id).toSet().length != clinics.length ||
        (hasNext && json['next'] is! String) ||
        hasNext != (query.page * query.pageSize < count)) {
      _invalid();
    }
  }
  final AnalyticsV2Metadata metadata;
  final int count;
  final List<AnalyticsV2Clinic> clinics;

  /// Only a pagination signal: response URLs are never followed with credentials.
  final bool hasNext;
}

class AnalyticsV2Day {
  AnalyticsV2Day.fromJson(Map<String, dynamic> json)
    : date = _text(json['date']),
      metrics = AnalyticsV2Metrics.fromJson(json) {
    AdminReportingPeriod.parse(date);
  }
  final String date;
  final AnalyticsV2Metrics metrics;
}

class AnalyticsV2Detail {
  AnalyticsV2Detail.fromJson(
    Map<String, dynamic> json,
    AnalyticsV2Query query,
    String clinicId,
  ) : metadata = AnalyticsV2Metadata.fromJson(json, query),
      clinic = AnalyticsV2Clinic.fromJson(_map(json['result'])) {
    if (clinic.id != clinicId) _invalid();
    final series = _map(json['daily_series']);
    days = List.unmodifiable(
      (series['results'] as List).map((v) => AnalyticsV2Day.fromJson(_map(v))),
    );
    dayCount = _number(series['count']);
    seriesPage = _number(series['page']);
    seriesPageSize = _number(series['page_size']);
    if (seriesPage != query.seriesPage ||
        seriesPageSize != query.seriesPageSize ||
        days.length > seriesPageSize ||
        days.map((d) => d.date).toSet().length != days.length ||
        days.any(
          (d) =>
              d.date.compareTo(query.from) < 0 ||
              d.date.compareTo(query.to) > 0,
        )) {
      _invalid();
    }
    final previous = json['comparison'];
    if (previous != null) {
      final data = _map(previous);
      if (!query.compare ||
          _instant(data['end_utc_exclusive']) != query.start ||
          _instant(data['start_utc']) !=
              query.start.subtract(query.end.difference(query.start))) {
        _invalid();
      }
      comparison = AnalyticsV2Clinic.fromJson(_map(data['result']));
      if (comparison!.id != clinicId) _invalid();
    }
  }
  final AnalyticsV2Metadata metadata;
  final AnalyticsV2Clinic clinic;
  late final List<AnalyticsV2Day> days;
  late final int dayCount, seriesPage, seriesPageSize;
  AnalyticsV2Clinic? comparison;
  bool get hasMoreDays => seriesPage * seriesPageSize < dayCount;
}
