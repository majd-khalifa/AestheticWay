/// Dashboard KPI metrics model matching GET /api/v1/clinic-portal/dashboard/
class ClinicDashboardModel {
  final String clinicId;
  final String clinicName;

  // Leads Metrics
  final int totalLeads;
  final int newLeads;
  final int contactedLeads;
  final int closedLeads;
  final double conversionRate;

  // Interactions / Telemetry
  final int whatsappTaps;
  final int callTaps;
  final int mapsTaps;
  final int profileViews;

  // Catalog
  final int activePractitionersCount;
  final int activeTreatmentsCount;
  final int activeOffersCount;
  final int activeProductsCount;
  final int publishedArticlesCount;

  const ClinicDashboardModel({
    required this.clinicId,
    required this.clinicName,
    required this.totalLeads,
    required this.newLeads,
    required this.contactedLeads,
    required this.closedLeads,
    required this.conversionRate,
    required this.whatsappTaps,
    required this.callTaps,
    required this.mapsTaps,
    required this.profileViews,
    required this.activePractitionersCount,
    required this.activeTreatmentsCount,
    required this.activeOffersCount,
    required this.activeProductsCount,
    required this.publishedArticlesCount,
  });

  factory ClinicDashboardModel.fromJson(Map<String, dynamic> json) {
    final leads = json['leads'] as Map<String, dynamic>? ?? {};
    final interactions = json['interactions'] as Map<String, dynamic>? ?? {};
    final catalog = json['catalog'] as Map<String, dynamic>? ?? {};

    return ClinicDashboardModel(
      clinicId: json['clinic_id']?.toString() ?? '',
      clinicName: json['clinic_name']?.toString() ?? '',
      totalLeads: (leads['total'] as num?)?.toInt() ?? 0,
      newLeads: (leads['new'] as num?)?.toInt() ?? 0,
      contactedLeads: (leads['contacted'] as num?)?.toInt() ?? 0,
      closedLeads: (leads['closed'] as num?)?.toInt() ?? 0,
      conversionRate: (leads['conversion_rate_percentage'] as num?)?.toDouble() ?? 0.0,
      whatsappTaps: (interactions['whatsapp_taps'] as num?)?.toInt() ?? 0,
      callTaps: (interactions['call_taps'] as num?)?.toInt() ?? 0,
      mapsTaps: (interactions['maps_taps'] as num?)?.toInt() ?? 0,
      profileViews: (interactions['profile_views'] as num?)?.toInt() ?? 0,
      activePractitionersCount: (catalog['active_practitioners_count'] as num?)?.toInt() ?? 0,
      activeTreatmentsCount: (catalog['active_treatments_count'] as num?)?.toInt() ?? 0,
      activeOffersCount: (catalog['active_offers_count'] as num?)?.toInt() ?? 0,
      activeProductsCount: (catalog['active_products_count'] as num?)?.toInt() ?? 0,
      publishedArticlesCount: (catalog['published_articles_count'] as num?)?.toInt() ?? 0,
    );
  }
}
