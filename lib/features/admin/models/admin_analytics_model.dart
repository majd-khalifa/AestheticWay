import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';

/// Clinic engagement breakdown entry in analytics
class AdminClinicEngagementEntry {
  final String clinicId;
  final String clinicName;
  final int eventsCount;
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
    this.eventsCount = 0,
    this.views = 0,
    this.whatsappTaps = 0,
    this.callTaps = 0,
    this.leads = 0,
    this.city = 'Dubai',
    this.tier = SubscriptionTier.basic,
    this.isActive = true,
  });

  String get clinicNameAr => clinicName;
  String get clinicNameEn => clinicName;
  int get appViews => views > 0 ? views : eventsCount;
  int get totalLeads => leads;
  int get totalDirectEngagement => whatsappTaps + callTaps + leads;
  double get engagementRate => appViews > 0 ? (totalDirectEngagement / appViews) * 100 : 0.0;

  factory AdminClinicEngagementEntry.fromJson(Map<String, dynamic> json) {
    SubscriptionTier tier = SubscriptionTier.basic;
    final rawTier = json['tier']?.toString().toLowerCase() ?? json['subscription_tier']?.toString().toLowerCase() ?? '';
    if (rawTier == 'vip' || rawTier == 'vipplatinum') {
      tier = SubscriptionTier.vipPlatinum;
    } else if (rawTier == 'featured') {
      tier = SubscriptionTier.featured;
    }

    return AdminClinicEngagementEntry(
      clinicId: json['clinic_id']?.toString() ?? '',
      clinicName: json['clinic_name']?.toString() ?? json['name']?.toString() ?? '',
      eventsCount: (json['events_count'] as num?)?.toInt() ?? (json['event_count'] as num?)?.toInt() ?? 0,
      views: (json['views'] as num?)?.toInt() ?? (json['app_views'] as num?)?.toInt() ?? 0,
      whatsappTaps: (json['whatsapp_taps'] as num?)?.toInt() ?? 0,
      callTaps: (json['call_taps'] as num?)?.toInt() ?? 0,
      leads: (json['leads'] as num?)?.toInt() ?? (json['leads_count'] as num?)?.toInt() ?? 0,
      city: json['city']?.toString() ?? 'Dubai',
      tier: tier,
      isActive: json['is_active'] != false,
    );
  }
}

/// Platform-wide analytics metrics model for Super Admin
class AdminAnalyticsModel {
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
      totalEvents: (json['total_events'] as num?)?.toInt() ?? 0,
      appOpens: (json['app_opens'] as num?)?.toInt() ?? 0,
      clinicViews: (json['clinic_views'] as num?)?.toInt() ?? 0,
      whatsappTaps: (json['whatsapp_taps'] as num?)?.toInt() ?? 0,
      callTaps: (json['call_taps'] as num?)?.toInt() ?? 0,
      mapsTaps: (json['maps_taps'] as num?)?.toInt() ?? 0,
      leadSubmissions: (json['lead_submissions'] as num?)?.toInt() ?? 0,
      clinicEngagement: parsedEngagement,
    );
  }
}
