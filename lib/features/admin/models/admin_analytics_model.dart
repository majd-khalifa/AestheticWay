import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';

int? _count(dynamic value) {
  final parsed = value is int ? value : int.tryParse('$value');
  return parsed != null && parsed >= 0 ? parsed : null;
}

class AdminDailyEventCount {
  const AdminDailyEventCount(this.date, this.count);
  final String date;
  final int? count;
}

/// Clinic engagement breakdown entry in analytics
class AdminClinicEngagementEntry {
  final String clinicId;
  final String clinicName;
  final String? localizedNameAr;
  final bool hasTier;
  final int eventsCount;
  final bool hasEventCount;
  final int views;
  final int whatsappTaps;
  final int callTaps;
  final int leads;
  final String city;
  final SubscriptionTier tier;
  final bool isActive;

  const AdminClinicEngagementEntry({
    required this.clinicId,
    required this.clinicName,
    this.localizedNameAr,
    this.hasTier = false,
    this.eventsCount = 0,
    this.hasEventCount = true,
    this.views = 0,
    this.whatsappTaps = 0,
    this.callTaps = 0,
    this.leads = 0,
    this.city = '',
    this.tier = SubscriptionTier.basic,
    this.isActive = true,
  });

  String get clinicNameAr => localizedNameAr?.trim().isNotEmpty == true
      ? localizedNameAr!
      : clinicName;
  String get clinicNameEn => clinicName;
  int get appViews => views;
  int get totalLeads => leads;
  int get totalDirectEngagement => whatsappTaps + callTaps + leads;
  double get engagementRate =>
      appViews > 0 ? (totalDirectEngagement / appViews) * 100 : 0.0;

  factory AdminClinicEngagementEntry.fromJson(Map<String, dynamic> json) {
    SubscriptionTier tier = SubscriptionTier.basic;
    final rawTier =
        json['tier']?.toString().toLowerCase() ??
        json['subscription_tier']?.toString().toLowerCase() ??
        '';
    if (rawTier == 'vip' || rawTier == 'vipplatinum') {
      tier = SubscriptionTier.vipPlatinum;
    } else if (rawTier == 'featured') {
      tier = SubscriptionTier.featured;
    }

    return AdminClinicEngagementEntry(
      clinicId: json['clinic_id']?.toString() ?? '',
      localizedNameAr: json['clinic_name_ar']?.toString(),
      hasTier: json['tier'] != null || json['subscription_tier'] != null,
      clinicName:
          json['clinic_name']?.toString() ?? json['name']?.toString() ?? '',
      eventsCount: _count(json['events_count'] ?? json['event_count']) ?? 0,
      hasEventCount:
          _count(json['events_count'] ?? json['event_count']) != null,
      views:
          (json['views'] as num?)?.toInt() ??
          (json['app_views'] as num?)?.toInt() ??
          0,
      whatsappTaps: (json['whatsapp_taps'] as num?)?.toInt() ?? 0,
      callTaps: (json['call_taps'] as num?)?.toInt() ?? 0,
      leads:
          (json['leads'] as num?)?.toInt() ??
          (json['leads_count'] as num?)?.toInt() ??
          0,
      city: json['city']?.toString() ?? '',
      tier: tier,
      isActive: json['is_active'] != false,
    );
  }
}

/// Platform-wide analytics metrics model for Super Admin
class AdminAnalyticsModel {
  static const metricKeys = {
    'total_events',
    'app_opens',
    'clinic_views',
    'whatsapp_taps',
    'call_taps',
    'maps_taps',
    'lead_submissions',
  };
  final String? dateFrom;
  final String? dateTo;
  final int totalEvents;
  final int appOpens;
  final int clinicViews;
  final int whatsappTaps;
  final int callTaps;
  final int mapsTaps;
  final int leadSubmissions;
  final List<AdminClinicEngagementEntry> clinicEngagement;
  final Set<String> availableMetrics;
  final List<AdminDailyEventCount> dailyTrends;

  /// Null means absent/invalid, never a verified zero.
  int? recordedCount(String key) => !availableMetrics.contains(key)
      ? null
      : switch (key) {
          'total_events' => totalEvents,
          'app_opens' => appOpens,
          'clinic_views' => clinicViews,
          'whatsapp_taps' => whatsappTaps,
          'call_taps' => callTaps,
          'maps_taps' => mapsTaps,
          'lead_submissions' => leadSubmissions,
          _ => null,
        };

  const AdminAnalyticsModel({
    this.dateFrom,
    this.dateTo,
    this.totalEvents = 0,
    this.appOpens = 0,
    this.clinicViews = 0,
    this.whatsappTaps = 0,
    this.callTaps = 0,
    this.mapsTaps = 0,
    this.leadSubmissions = 0,
    this.clinicEngagement = const [],
    this.availableMetrics = metricKeys,
    this.dailyTrends = const [],
  });

  factory AdminAnalyticsModel.fromJson(Map<String, dynamic> json) {
    List<AdminClinicEngagementEntry> parsedEngagement = [];
    if (json['clinic_engagement'] is List) {
      parsedEngagement = (json['clinic_engagement'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => AdminClinicEngagementEntry.fromJson(e))
          .toList();
    }

    return AdminAnalyticsModel(
      dateFrom: json['date_from']?.toString(),
      dateTo: json['date_to']?.toString(),
      totalEvents: _count(json['total_events']) ?? 0,
      appOpens: _count(json['app_opens']) ?? 0,
      clinicViews: _count(json['clinic_views']) ?? 0,
      whatsappTaps: _count(json['whatsapp_taps']) ?? 0,
      callTaps: _count(json['call_taps']) ?? 0,
      mapsTaps: _count(json['maps_taps']) ?? 0,
      leadSubmissions: _count(json['lead_submissions']) ?? 0,
      clinicEngagement: parsedEngagement,
      availableMetrics: Set.unmodifiable(
        metricKeys.where((key) => _count(json[key]) != null),
      ),
      dailyTrends: List.unmodifiable([
        if (json['daily_trends'] is List)
          for (final row in json['daily_trends'])
            if (row is Map && row['date'] is String)
              AdminDailyEventCount(row['date'], _count(row['total_events'])),
      ]),
    );
  }
}

/// Verified GET /admin/analytics/referrals/ aggregates. No coupon UI or writes.
class AdminReferralAnalyticsModel {
  const AdminReferralAnalyticsModel({
    this.successfulInvites = 0,
    this.pointsAwarded = 0,
  });
  final int successfulInvites, pointsAwarded;
  factory AdminReferralAnalyticsModel.fromJson(Map<String, dynamic> json) =>
      AdminReferralAnalyticsModel(
        successfulInvites:
            int.tryParse('${json['total_successful_invites']}') ?? 0,
        pointsAwarded: int.tryParse('${json['total_points_awarded']}') ?? 0,
      );
}
