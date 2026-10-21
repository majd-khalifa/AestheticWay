import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/features/appointment_lead/data/leads_repository.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';
import 'package:aesthetic_way/features/clinics/data/clinics_repository.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/referral/models/referral_model.dart';

const patientClinicId = '11111111-1111-4111-8111-111111111111';
const patientOfferId = '22222222-2222-4222-8222-222222222222';
ClinicModel patientClinic({Map<String, dynamic> extra = const {}}) =>
    ClinicModel.fromJson({
      'id': patientClinicId,
      'name_en': 'Fixture Medical Clinic',
      'name_ar': 'عيادة الاختبار الطبية',
      'city': 'Dubai',
      ...extra,
    });
PatientReferralStatusModel patientReferralStatus({
  int invites = 3,
  int points = 30,
}) => PatientReferralStatusModel.fromJson({
  'invite_link': 'https://aestheticway.ae/invite/fixture-token',
  'successful_invites_count': invites,
  'current_points': points,
  'milestones': {'20': invites >= 20, '35': invites >= 35, '50': invites >= 50},
});

class FixtureLeadsRepository extends LeadsRepository {
  Map<String, dynamic>? lastPayload;
  int calls = 0;
  @override
  Future<LeadSubmitResult> createLead(Map<String, dynamic> payload) async {
    calls++;
    lastPayload = Map.of(payload);
    return LeadSubmitResult(
      success: true,
      leadReference: 'FIXTURE-001',
      confirmationMessage: 'تم إرسال طلبك وستتواصل العيادة معك',
      createdAt: DateTime.utc(2026, 10, 20),
    );
  }

  @override
  Future<List<AppointmentRequestModel>> getMyLeads({
    String? status,
    int page = 1,
  }) async => PageItems([], hasMore: false, total: 0);
}

class FixtureClinicsRepository extends ClinicsRepository {
  FixtureClinicsRepository(this.clinic);
  final ClinicModel clinic;
  @override
  Future<ClinicModel> getClinicDetail(String idOrSlug) async => clinic;
}
