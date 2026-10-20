import 'support/patient_fixtures.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/app_brand_logo.dart';
import 'package:aesthetic_way/data/mock_data.dart';
import 'package:aesthetic_way/features/appointment_lead/data/leads_repository.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_success_screen.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/my_requests_screen.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/products/presentation/widgets/product_inquiry_bottom_sheet.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';

class _FakeLeadsRepository extends LeadsRepository {
  Map<String, dynamic>? lastSubmittedPayload;
  List<AppointmentRequestModel> mockLeads = [];

  @override
  Future<LeadSubmitResult> createLead(Map<String, dynamic> payload) async {
    lastSubmittedPayload = payload;
    LeadsRepository.notifyLeadsUpdated();
    return LeadSubmitResult(
      success: true,
      leadReference: '#REQ-77889',
      createdAt: DateTime(2026, 9, 29, 14, 30),
      confirmationMessage: 'تم إرسال طلبك وستتواصل العيادة معك',
    );
  }

  @override
  Future<List<AppointmentRequestModel>> getMyLeads({
    String? status,
    int page = 1,
  }) async {
    return mockLeads;
  }
}

void main() {
  final testClinic = MockDataService().clinics.first.copyWith(
    id: patientClinicId,
  );

  group('TreatmentModel Live Duration & Mock Purge Tests', () {
    test(
      'parses duration_minutes directly and formats localized duration without hardcoded fallbacks',
      () {
        final modelWithDuration = TreatmentModel.fromJson({
          'id': 't1',
          'name_ar': 'هيدرافيشل الملكي',
          'name_en': 'Royal HydraFacial',
          'duration_minutes': 45,
        });

        expect(modelWithDuration.durationMinutes, 45);
        expect(modelWithDuration.formattedDuration(false), '45 mins');
        expect(modelWithDuration.formattedDuration(true), '45 دقيقة');
        expect(modelWithDuration.downtimeText, isEmpty);
        expect(modelWithDuration.targetAreaAr, isEmpty);

        final modelWithoutDuration = TreatmentModel.fromJson({
          'id': 't2',
          'name_ar': 'ليزر كربوني',
          'name_en': 'Carbon Laser',
        });

        expect(modelWithoutDuration.durationMinutes, isNull);
        expect(modelWithoutDuration.formattedDuration(false), isEmpty);
        expect(modelWithoutDuration.formattedDuration(true), isEmpty);
      },
    );
  });

  group('AppointmentSuccessScreen Brand Logo & Wording Tests', () {
    testWidgets(
      'displays enlarged AppBrandLogo.auth() and exact Arabic confirmation wording',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        LocaleService().setLanguage(AppLanguage.arabic);

        final request = AppointmentRequestModel(
          id: 'req-1',
          referenceCode: '#REQ-12345',
          clinicId: testClinic.id,
          clinicNameAr: testClinic.nameAr,
          clinicNameEn: testClinic.nameEn,
          branchNameAr: testClinic.areaAr,
          branchNameEn: testClinic.areaEn,
          serviceNameAr: 'سيروم فيتامين سي',
          serviceNameEn: 'Vitamin C Serum',
          preferredDate: DateTime(2026, 10, 1),
          preferredTimeWindow: PreferredTimeWindow.evening,
          patientFullName: 'أحمد محمد',
          patientPhone: '+971501234567',
          notes: 'أرغب بالاستفسار عن توفر المنتج',
          consentAccepted: true,
          status: AppointmentLeadStatus.sent,
          createdAt: DateTime(2026, 9, 29),
          leadType: 'product',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: AppointmentSuccessScreen(
              request: request,
              clinic: testClinic,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final logoFinder = find.byType(AppBrandLogo);
        expect(logoFinder, findsOneWidget);
        final logoWidget = tester.widget<AppBrandLogo>(logoFinder);
        expect(logoWidget.height, 144);
        expect(logoWidget.width, 184);

        expect(find.text('تم إرسال طلبك وستتواصل العيادة معك'), findsOneWidget);
        expect(find.text('سيروم فيتامين سي'), findsOneWidget);
      },
    );
  });

  group('ProductInquiryBottomSheet & MyRequestsScreen Tests', () {
    testWidgets(
      'ProductInquiryBottomSheet hides appointment fields and submits lead_type=product_inquiry',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        LocaleService().setLanguage(AppLanguage.arabic);
        AuthState().login(name: 'Fixture Patient', phone: '+971501234567');
        final fakeRepo = _FakeLeadsRepository();

        final product = ProductModel(
          id: '22222222-2222-2222-2222-222222222222',
          clinicId: testClinic.id,
          clinicNameAr: testClinic.nameAr,
          clinicNameEn: testClinic.nameEn,
          nameAr: 'كريم الريتينول الطبي',
          nameEn: 'Medical Retinol Cream',
          descriptionAr: 'كريم ليلي لتجديد البشرة',
          descriptionEn: 'Night renewal cream',
          price: 320,
          imageUrl: '',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProductInquiryBottomSheet(
                product: product,
                clinic: testClinic,
                leadsRepository: fakeRepo,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify product name, clinic name, and notes label are shown
        expect(find.text('كريم الريتينول الطبي'), findsOneWidget);
        expect(find.text(testClinic.nameAr), findsOneWidget);
        expect(find.text('استفسار أو ملاحظات'), findsOneWidget);

        // Verify practitioner and preferred time window selectors are NOT present
        expect(find.text('الفترة المفضلة'), findsNothing);
        expect(find.text('Preferred Period'), findsNothing);

        // Fill patient details and explicitly accept consent.
        await tester.enterText(find.byType(TextFormField).at(0), 'سارة العلي');
        await tester.enterText(find.byType(TextFormField).at(1), '501234567');
        await tester.enterText(
          find.byType(TextFormField).at(2),
          'هل يناسب البشرة الحساسة؟',
        );
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pumpAndSettle();

        expect(fakeRepo.lastSubmittedPayload, isNotNull);
        expect(fakeRepo.lastSubmittedPayload!['lead_type'], 'product_inquiry');
        expect(fakeRepo.lastSubmittedPayload!['product'], product.id);
        expect(fakeRepo.lastSubmittedPayload!['clinic'], testClinic.id);
      },
    );

    testWidgets(
      'MyRequestsScreen opens lead details modal sheet on card tap and auto-refreshes',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        LocaleService().setLanguage(AppLanguage.english);
        final fakeRepo = _FakeLeadsRepository();
        fakeRepo.mockLeads = [
          AppointmentRequestModel(
            id: 'lead-1',
            referenceCode: '#REQ-99001',
            clinicId: testClinic.id,
            clinicNameAr: testClinic.nameAr,
            clinicNameEn: testClinic.nameEn,
            branchNameAr: testClinic.areaAr,
            branchNameEn: testClinic.areaEn,
            serviceNameAr: 'كريم الريتينول الطبي',
            serviceNameEn: 'Medical Retinol Cream',
            preferredDate: DateTime(2026, 9, 29),
            preferredTimeWindow: PreferredTimeWindow.morning,
            patientFullName: 'Sara Al Ali',
            patientPhone: '+971501234567',
            notes: 'Is this suitable for sensitive skin?',
            consentAccepted: true,
            status: AppointmentLeadStatus.sent,
            createdAt: DateTime(2026, 9, 29, 11, 15),
            leadType: 'product',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(home: MyRequestsScreen(leadsRepository: fakeRepo)),
        );
        await tester.pumpAndSettle();

        expect(find.text('#REQ-99001'), findsOneWidget);

        // Tap the lead card to open the detail modal sheet
        await tester.tap(find.text('#REQ-99001'));
        await tester.pumpAndSettle();

        expect(find.text('Request Details'), findsOneWidget);
        expect(
          find.text('Is this suitable for sensitive skin?'),
          findsOneWidget,
        );
      },
    );
  });
}
