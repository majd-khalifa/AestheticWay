/// Model representing lightweight badge counts for the Clinic Portal navigation shell and dashboard
class ClinicBadgeCountsModel {
  final int newRequests;
  final int unreadRequests;
  final int contactedRequests;
  final int closedRequests;
  final int totalRequests;

  const ClinicBadgeCountsModel({
    this.newRequests = 0,
    this.unreadRequests = 0,
    this.contactedRequests = 0,
    this.closedRequests = 0,
    this.totalRequests = 0,
  });

  factory ClinicBadgeCountsModel.zero() => const ClinicBadgeCountsModel();

  factory ClinicBadgeCountsModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return ClinicBadgeCountsModel(
      newRequests: parseInt(json['new_requests']),
      unreadRequests: parseInt(json['unread_requests'] ?? json['new_requests']),
      contactedRequests: parseInt(json['contacted_requests']),
      closedRequests: parseInt(json['closed_requests']),
      totalRequests: parseInt(json['total_requests']),
    );
  }

  Map<String, dynamic> toJson() => {
    'new_requests': newRequests,
    'unread_requests': unreadRequests,
    'contacted_requests': contactedRequests,
    'closed_requests': closedRequests,
    'total_requests': totalRequests,
  };
}
