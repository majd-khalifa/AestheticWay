import '../../../core/utils/entity_id.dart';
import '../../../core/data/paged_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';

/// Result returned from successful Lead creation
class LeadSubmitResult {
  final bool success;
  final String leadReference;
  final String confirmationMessage;
  final DateTime createdAt;

  const LeadSubmitResult({
    required this.success,
    required this.leadReference,
    required this.confirmationMessage,
    required this.createdAt,
  });

  factory LeadSubmitResult.fromJson(Map<String, dynamic> json) {
    final dt = DateTime.tryParse(json['created_at']?.toString() ?? '');
    if (dt == null) {
      throw const FormatException('Missing server request timestamp');
    }
    return LeadSubmitResult(
      success: json['success'] == true,
      leadReference: json['lead_reference']?.toString() ?? '',
      confirmationMessage:
          json['confirmation_message']?.toString() ??
          'Your request has been sent and the clinic will contact you',
      createdAt: dt,
    );
  }
}

/// Repository managing patient appointment inquiries (leads) and personal request history
class LeadsRepository {
  /// Global notifier triggered whenever a new lead is submitted or when the Requests tab gains focus.
  static final ValueNotifier<int> refreshNotifier = ValueNotifier<int>(0);

  static void notifyLeadsUpdated() {
    refreshNotifier.value++;
  }

  final ApiClient _apiClient;

  LeadsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Submits an appointment request (lead) to the backend
  Future<LeadSubmitResult> createLead(Map<String, dynamic> payload) async {
    if (!isEntityUuid(payload['clinic']?.toString()) &&
        !(payload['lead_type'] == 'product_inquiry' &&
            isEntityUuid(payload['product']?.toString()))) {
      throw const ApiException(
        message: 'A valid inquiry destination is required.',
        statusCode: 400,
      );
    }
    try {
      final response = await _apiClient.post(ApiConfig.leads, data: payload);

      final data = response.data as Map<String, dynamic>;
      final result = LeadSubmitResult.fromJson(data);
      if (!result.success || result.leadReference.trim().isEmpty) {
        throw const ApiException(
          message: 'The server did not confirm this request.',
        );
      }
      notifyLeadsUpdated();
      return result;
    } on ApiException {
      rethrow;
    } on DioException catch (dioErr) {
      throw ApiException.fromDioError(dioErr);
    } catch (_) {
      throw const ApiException(
        message: 'Unable to submit this inquiry. Please try again.',
      );
    }
  }

  /// Retrieves the list of personal appointment requests (leads) for the authenticated patient
  Future<List<AppointmentRequestModel>> getMyLeads({
    String? status,
    int page = 1,
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    queryParams['page'] = page;
    queryParams['page_size'] = catalogPageSize;

    try {
      final response = await _apiClient.get(
        ApiConfig.myLeads,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return PageItems<AppointmentRequestModel>.fromResponse(
        response.data,
        AppointmentRequestModel.fromPatientJson,
        page: page,
      );
    } on ApiException {
      rethrow;
    }
  }

  /// Retrieves a specific lead request detail by UUID
  Future<AppointmentRequestModel> getMyLeadDetail(String id) async {
    final cleanId = id.trim();
    if (!isEntityUuid(cleanId)) {
      throw const ApiException(
        message: 'A valid request ID is required.',
        statusCode: 400,
      );
    }
    final endpoint = ApiConfig.leadDetail(cleanId);

    final response = await _apiClient.get(endpoint);
    return AppointmentRequestModel.fromPatientJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Returns total count of leads submitted by the patient
  Future<int> getMyLeadsCount() async {
    try {
      final response = await _apiClient.get(ApiConfig.myLeadsCount);
      if (response.data is Map<String, dynamic>) {
        final count = response.data['count'];
        if (count is int) return count;
        if (count is String) return int.tryParse(count) ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
