/// Checklist item for clinic onboarding progress
class ClinicSetupChecklistItem {
  final String key;
  final String titleEn;
  final String titleAr;
  final bool isCompleted;
  final String route;

  const ClinicSetupChecklistItem({
    required this.key,
    required this.titleEn,
    required this.titleAr,
    required this.isCompleted,
    this.route = '',
  });

  factory ClinicSetupChecklistItem.fromJson(Map<String, dynamic> json) {
    return ClinicSetupChecklistItem(
      key: json['key']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? '',
      titleAr: json['title_ar'] ?? json['title_en'] ?? '',
      isCompleted: json['is_completed'] == true,
      route: json['route']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title_en': titleEn,
      'title_ar': titleAr,
      'is_completed': isCompleted,
      'route': route,
    };
  }
}

/// Dynamic onboarding & profile completion checklist model for Clinic Portal
class ClinicSetupChecklistModel {
  final String clinicId;
  final String setupStatus; // 'draft' | 'submitted' | 'approved' | 'rejected'
  final String setupRejectionReason;
  final int progressPercentage;
  final bool isReadyForReview;
  final List<ClinicSetupChecklistItem> items;

  const ClinicSetupChecklistModel({
    required this.clinicId,
    required this.setupStatus,
    this.setupRejectionReason = '',
    required this.progressPercentage,
    required this.isReadyForReview,
    this.items = const [],
  });

  factory ClinicSetupChecklistModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final parsedItems = rawItems
        .whereType<Map<String, dynamic>>()
        .map((i) => ClinicSetupChecklistItem.fromJson(i))
        .toList();

    return ClinicSetupChecklistModel(
      clinicId: json['clinic_id']?.toString() ?? '',
      setupStatus: json['setup_status']?.toString() ?? 'draft',
      setupRejectionReason: json['setup_status'] == 'rejected'
          ? (json['setup_rejection_reason'] ?? json['moderation_notes'] ?? '')
                .toString()
          : '',
      progressPercentage: (json['progress_percentage'] as num?)?.toInt() ?? 0,
      isReadyForReview: json['is_ready_for_review'] == true,
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clinic_id': clinicId,
      'setup_status': setupStatus,
      'setup_rejection_reason': setupRejectionReason,
      'progress_percentage': progressPercentage,
      'is_ready_for_review': isReadyForReview,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}
