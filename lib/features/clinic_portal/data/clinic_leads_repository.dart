import '../../../core/data/paged_collection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../appointment_lead/models/appointment_request_model.dart';
import 'models/clinic_dashboard_model.dart';
import 'models/clinic_badge_counts_model.dart';

/// Repository for Clinic Partner Leads Management & Telemetry Dashboard
class ClinicLeadsRepository {
  static final ClinicLeadsRepository _instance =
      ClinicLeadsRepository._internal();
  factory ClinicLeadsRepository({ApiClient? apiClient}) =>
      apiClient == null ? _instance : ClinicLeadsRepository._custom(apiClient);
  ClinicLeadsRepository._internal() : _api = ApiClient();
  ClinicLeadsRepository._custom(this._api);

  final ApiClient _api;

  /// Fetch clinic dashboard KPI overview
  Future<ClinicDashboardModel> getDashboard() async {
    final response = await _api.get(ApiConfig.clinicDashboard);
    final data = response.data as Map<String, dynamic>;
    return ClinicDashboardModel.fromJson(data);
  }

  /// Fetch lightweight badge counts from backend API (GET /api/v1/clinic-portal/badges/)
  Future<ClinicBadgeCountsModel> getBadgeCounts() async {
    final response = await _api.get(ApiConfig.clinicBadges);
    if (response.data is Map<String, dynamic>) {
      return ClinicBadgeCountsModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
    if (response.data is Map) {
      return ClinicBadgeCountsModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    }
    return ClinicBadgeCountsModel.zero();
  }

  /// Fetch incoming consultation leads for the authenticated clinic.
  /// Seamlessly supports both paginated envelope ({'results': [...], 'count': N})
  /// and direct list responses.
  Future<List<AppointmentRequestModel>> getLeads({
    int page = 1,
    int pageSize = 20,
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

    queryParams['page'] = page;
    queryParams['page_size'] = catalogPageSize;
    final response = await _api.get(
      ApiConfig.clinicLeads,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return PageItems<AppointmentRequestModel>.fromResponse(
      response.data,
      AppointmentRequestModel.fromJson,
      page: page,
    );
  }

  /// Fetch single lead detail by ID
  Future<AppointmentRequestModel> getLeadDetail(String id) async {
    final response = await _api.get(ApiConfig.clinicLeadDetail(id));
    return AppointmentRequestModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Update operational status of a consultation lead
  /// Backend supported values: 'new' | 'contacted' | 'closed'
  Future<AppointmentRequestModel> updateLeadStatus(
    String id,
    AppointmentLeadStatus newStatus, {
    AppointmentRequestModel? existingLead,
  }) async {
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

    final data = response.data as Map<String, dynamic>;
    const fullLeadFields = [
      'id',
      'patient_name',
      'patient_phone',
      'service_name',
      'created_at',
    ];
    if (fullLeadFields.any((field) => !data.containsKey(field))) {
      final existing = existingLead ?? await getLeadDetail(id);
      final returnedStatus = data['status'] == null
          ? newStatus
          : AppointmentRequestModel.fromJson(data).status;
      return existing.copyWith(status: returnedStatus);
    }
    return AppointmentRequestModel.fromJson(data);
  }

  /// Post internal operational note for a lead
  Future<ClinicInternalNote> addLeadNote(String id, String note) async {
    final response = await _api.post(
      ApiConfig.clinicLeadNotes(id),
      data: {'note': note.trim()},
    );

    return ClinicInternalNote.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ClinicInternalNote>> getLeadNotes(
    String id, {
    int page = 1,
  }) async {
    final response = await _api.get(
      ApiConfig.clinicLeadNotes(id),
      queryParameters: {'page': page, 'page_size': catalogPageSize},
    );
    return PageItems<ClinicInternalNote>.fromResponse(
      response.data,
      ClinicInternalNote.fromJson,
      page: page,
    );
  }
}
