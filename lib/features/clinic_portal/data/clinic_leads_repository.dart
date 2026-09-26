import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../appointment_lead/models/appointment_request_model.dart';
import 'models/clinic_dashboard_model.dart';

/// Repository for Clinic Partner Leads Management & Telemetry Dashboard
class ClinicLeadsRepository {
  static final ClinicLeadsRepository _instance = ClinicLeadsRepository._internal();
  factory ClinicLeadsRepository() => _instance;
  ClinicLeadsRepository._internal();

  final ApiClient _api = ApiClient();

  /// Fetch clinic dashboard KPI overview
  Future<ClinicDashboardModel> getDashboard() async {
    final response = await _api.get(ApiConfig.clinicDashboard);
    final data = response.data as Map<String, dynamic>;
    return ClinicDashboardModel.fromJson(data);
  }

  /// Fetch incoming consultation leads for the authenticated clinic
  Future<List<AppointmentRequestModel>> getLeads({
    String? status,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      queryParams['status'] = status.toLowerCase();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _api.get(
      ApiConfig.clinicLeads,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final rawData = response.data;
    List<dynamic> items = [];
    if (rawData is Map<String, dynamic> && rawData.containsKey('results')) {
      items = rawData['results'] as List<dynamic>? ?? [];
    } else if (rawData is List) {
      items = rawData;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((item) => AppointmentRequestModel.fromJson(item))
        .toList();
  }

  /// Fetch single lead detail by ID
  Future<AppointmentRequestModel> getLeadDetail(String id) async {
    final response = await _api.get(ApiConfig.clinicLeadDetail(id));
    return AppointmentRequestModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update operational status of a consultation lead
  /// Backend supported values: 'new' | 'contacted' | 'closed'
  Future<AppointmentRequestModel> updateLeadStatus(
    String id,
    AppointmentLeadStatus newStatus,
  ) async {
    String statusStr;
    switch (newStatus) {
      case AppointmentLeadStatus.sent:
        statusStr = 'new';
        break;
      case AppointmentLeadStatus.contacted:
        statusStr = 'contacted';
        break;
      case AppointmentLeadStatus.closed:
        statusStr = 'closed';
        break;
    }

    final response = await _api.patch(
      ApiConfig.clinicLeadDetail(id),
      data: {'status': statusStr},
    );

    return AppointmentRequestModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Post internal operational note for a lead
  Future<ClinicInternalNote> addLeadNote(String id, String note) async {
    final response = await _api.post(
      ApiConfig.clinicLeadNotes(id),
      data: {'note': note.trim()},
    );

    return ClinicInternalNote.fromJson(response.data as Map<String, dynamic>);
  }
}
