/// Admin Dashboard Aggregates Model
class AdminDashboardModel {
  final int totalClinics;
  final int activeClinics;
  final int suspendedClinics;
  final int pendingClinics;
  final int totalPatients;
  final int totalPractitioners;
  final int totalTreatments;
  final int totalOffers;
  final int totalProducts;
  final int totalArticles;
  final int totalLeads;
  final int completedLeads;
  final int scheduledLeads;
  final Map<String, int> leadsByStatus;
  final double conversionPercentage;
  final int totalReferrals;
  final int totalRedeemedReferralCodes;
  final int totalAnalyticsEvents;
  final Map<String, int> activeSubscriptionTiers;
  final int featuredClinics;

  const AdminDashboardModel({
    this.totalClinics = 0,
    this.activeClinics = 0,
    this.suspendedClinics = 0,
    this.pendingClinics = 0,
    this.totalPatients = 0,
    this.totalPractitioners = 0,
    this.totalTreatments = 0,
    this.totalOffers = 0,
    this.totalProducts = 0,
    this.totalArticles = 0,
    this.totalLeads = 0,
    this.completedLeads = 0,
    this.scheduledLeads = 0,
    this.leadsByStatus = const {},
    this.conversionPercentage = 0.0,
    this.totalReferrals = 0,
    this.totalRedeemedReferralCodes = 0,
    this.totalAnalyticsEvents = 0,
    this.activeSubscriptionTiers = const {},
    this.featuredClinics = 0,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    Map<String, int> parseCountMap(dynamic raw) {
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), (v is num) ? v.toInt() : 0));
      }
      return {};
    }

    return AdminDashboardModel(
      totalClinics: (json['total_clinics'] as num?)?.toInt() ?? 0,
      activeClinics: (json['active_clinics'] as num?)?.toInt() ?? 0,
      suspendedClinics: (json['suspended_clinics'] as num?)?.toInt() ?? 0,
      pendingClinics: (json['pending_clinics'] as num?)?.toInt() ?? 0,
      totalPatients: (json['total_patients'] as num?)?.toInt() ?? 0,
      totalPractitioners: (json['total_practitioners'] as num?)?.toInt() ?? 0,
      totalTreatments: (json['total_treatments'] as num?)?.toInt() ?? 0,
      totalOffers: (json['total_offers'] as num?)?.toInt() ?? 0,
      totalProducts: (json['total_products'] as num?)?.toInt() ?? 0,
      totalArticles: (json['total_articles'] as num?)?.toInt() ?? 0,
      totalLeads: (json['total_leads'] as num?)?.toInt() ?? 0,
      completedLeads: (json['completed_leads'] as num?)?.toInt() ?? 0,
      scheduledLeads: (json['scheduled_leads'] as num?)?.toInt() ?? 0,
      leadsByStatus: parseCountMap(json['leads_by_status']),
      conversionPercentage: (json['conversion_percentage'] as num?)?.toDouble() ?? 0.0,
      totalReferrals: (json['total_referrals'] as num?)?.toInt() ?? 0,
      totalRedeemedReferralCodes: (json['total_redeemed_referral_codes'] as num?)?.toInt() ?? 0,
      totalAnalyticsEvents: (json['total_analytics_events'] as num?)?.toInt() ?? 0,
      activeSubscriptionTiers: parseCountMap(json['active_subscription_tiers']),
      featuredClinics: (json['featured_clinics'] as num?)?.toInt() ?? 0,
    );
  }
}
