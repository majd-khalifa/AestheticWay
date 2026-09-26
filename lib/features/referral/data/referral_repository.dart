import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../models/referral_model.dart';

/// Repository for Patient Referral & Rewards Program connected to Django API
class ReferralRepository {
  static final ReferralRepository _instance = ReferralRepository._internal();
  factory ReferralRepository() => _instance;
  ReferralRepository._internal();

  final ApiClient _api = ApiClient();

  /// Fetch authenticated patient's referral status, points, milestones and issued discount codes
  Future<PatientReferralStatusModel> getMyReferralStatus() async {
    final response = await _api.get(ApiConfig.referralStatus);
    final body = response.data;
    final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
    return PatientReferralStatusModel.fromJson(data as Map<String, dynamic>);
  }

  /// Collect a 15% discount code by consuming 500 points
  Future<CollectCodeResult> collectDiscountCode() async {
    final response = await _api.post(ApiConfig.referralCollect);
    final body = response.data;
    final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
    return CollectCodeResult.fromJson(data as Map<String, dynamic>);
  }

  /// Clinic Portal: Verify a patient's 15% referral discount code
  /// POST /api/v1/clinic-portal/discount-codes/verify/
  Future<Map<String, dynamic>> verifyClinicDiscountCode(String code) async {
    final response = await _api.post(
      ApiConfig.clinicDiscountVerify,
      data: {'code': code.trim()},
    );
    final body = response.data;
    final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// Clinic Portal: Redeem a patient's 15% referral discount code
  /// POST /api/v1/clinic-portal/discount-codes/redeem/
  Future<Map<String, dynamic>> redeemClinicDiscountCode(String code) async {
    final response = await _api.post(
      ApiConfig.clinicDiscountRedeem,
      data: {'code': code.trim()},
    );
    final body = response.data;
    final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }
}
