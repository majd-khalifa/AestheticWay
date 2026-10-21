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

  // Kept as disabled source-compatibility shims while Django retires these routes.
  Future<CollectCodeResult> collectDiscountCode() =>
      Future.error(UnsupportedError('Referral redemption has been retired'));
  Future<Map<String, dynamic>> verifyClinicDiscountCode(String code) =>
      Future.error(UnsupportedError('Referral redemption has been retired'));
  Future<Map<String, dynamic>> redeemClinicDiscountCode(String code) =>
      Future.error(UnsupportedError('Referral redemption has been retired'));
}
