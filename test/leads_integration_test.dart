import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/theme/app_theme.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';
import 'package:aesthetic_way/features/appointment_lead/data/leads_repository.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/my_requests_screen.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';
import 'package:aesthetic_way/core/widgets/luxury_phone_input_field.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';

void main() {
  setUp(() {
    LocaleService().setLanguage(AppLanguage.arabic);
    AuthState().login(
      name: 'سارة المنصوري',
      phone: '+971 50 987 6543',
      email: 'sara@example.com',
    );
  });

  group('Appointment Lead Model & Serialization Tests', () {
    test('AppointmentRequestModel parses backend response correctly', () {
      final backendJson = {
        'id': 'lead-uuid-101',
        'reference_code': '#REQ-77889',
        'status': 'new',
        'lead_type': 'general',
        'service_name': 'استشارة تجميلية وجلدية عامة',
        'patient_name': 'سارة المنصوري',
        'patient_phone': '+971509876543',
        'preferred_time_window': 'evening',
        'notes': 'يفضل استشارة حول نضارة البشرة',
        'created_at': '2026-09-22T10:00:00Z',
        'clinic': 'c-uuid-1',
        'clinic_summary': {
          'id': 'c-uuid-1',
          'name_ar': 'عيادة دبي الفاخرة',
          'name_en': 'Dubai Luxury Clinic',
          'phone': '+97143001122',
          'whatsapp': '+971501112233',
        },
        'branch': 'b-uuid-1',
        'branch_summary': {
          'id': 'b-uuid-1',
          'name_ar': 'فرع الجميرا',
          'name_en': 'Jumeirah Branch',
        },
        'practitioner': 'p-uuid-1',
        'practitioner_summary': {
          'id': 'p-uuid-1',
          'name_ar': 'د. ريم المهيري',
          'name_en': 'Dr. Reem Al-Muhairi',
          'type': 'doctor',
        },
      };

      final model = AppointmentRequestModel.fromJson(backendJson);

      expect(model.id, 'lead-uuid-101');
      expect(model.referenceCode, '#REQ-77889');
      expect(model.status, AppointmentLeadStatus.sent);
      expect(model.preferredTimeWindow, PreferredTimeWindow.evening);
      expect(model.clinicNameAr, 'عيادة دبي الفاخرة');
      expect(model.branchNameAr, 'فرع الجميرا');
      expect(model.practitionerNameAr, 'د. ريم المهيري');
      expect(model.clinicPhone, '+97143001122');
      expect(model.clinicWhatsapp, '+971501112233');
    });

    test('Status mapping handles new, contacted, closed properly', () {
      final jsonSent = {'status': 'new'};
      final jsonContacted = {'status': 'contacted'};
      final jsonClosed = {'status': 'closed'};

      expect(AppointmentRequestModel.fromJson(jsonSent).status, AppointmentLeadStatus.sent);
      expect(AppointmentRequestModel.fromJson(jsonContacted).status, AppointmentLeadStatus.contacted);
      expect(AppointmentRequestModel.fromJson(jsonClosed).status, AppointmentLeadStatus.closed);
    });

    test('toCreatePayload formats fields correctly for backend API', () {
      final request = AppointmentRequestModel(
        id: '1',
        referenceCode: '#REQ-12345',
        clinicId: '550e8400-e29b-41d4-a716-446655440000',
        clinicNameAr: 'عيادة النور',
        branchId: '660e8400-e29b-41d4-a716-446655440000',
        branchNameAr: 'الفرع الرئيسي',
        serviceNameAr: 'جلسة ليزر كانديلا',
        practitionerId: '770e8400-e29b-41d4-a716-446655440000',
        preferredDate: DateTime.now().add(const Duration(days: 2)),
        preferredTimeWindow: PreferredTimeWindow.morning,
        patientFullName: 'ماجد خليفة',
        patientPhone: '+971501234567',
        notes: 'يرجى التواصل صباحاً',
        consentAccepted: true,
        status: AppointmentLeadStatus.sent,
        createdAt: DateTime.now(),
      );

      final payload = request.toCreatePayload();

      expect(payload['clinic'], '550e8400-e29b-41d4-a716-446655440000');
      expect(payload['branch'], '660e8400-e29b-41d4-a716-446655440000');
      expect(payload['practitioner'], '770e8400-e29b-41d4-a716-446655440000');
      expect(payload['consent_accepted'], isTrue);
      expect(payload['service_name'], 'جلسة ليزر كانديلا');
      expect(payload['patient_phone'], '+971501234567');
      expect(payload['preferred_time_window'], '');
      expect(payload['notes'], 'يرجى التواصل صباحاً');
    });

    test('LeadSubmitResult parses backend 201 response', () {
      final json = {
        'success': true,
        'lead_reference': '#REQ-98765',
        'confirmation_message': 'Your request has been sent and the clinic will contact you',
        'created_at': '2026-09-22T12:00:00Z',
      };

      final result = LeadSubmitResult.fromJson(json);

      expect(result.success, isTrue);
      expect(result.leadReference, '#REQ-98765');
      expect(result.confirmationMessage, contains('clinic will contact you'));
    });
  });

  group('MyRequestsScreen UI Tests', () {
    testWidgets('MyRequestsScreen renders with filter chips and handles empty state', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MyRequestsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MyRequestsScreen), findsOneWidget);
      expect(find.text(LocaleService().tr('my_requests_title')), findsOneWidget);
      expect(find.text(LocaleService().tr('status_sent')), findsOneWidget);
      expect(find.text(LocaleService().tr('status_contacted')), findsOneWidget);
      expect(find.text(LocaleService().tr('status_closed')), findsOneWidget);
    });
  });

  group('AppointmentRequestScreen Live Lead Binding Tests', () {
    testWidgets('AppointmentRequestScreen initializes with clinic treatments and submits without mock data', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1800));

      const testClinic = ClinicModel(
        id: 'clinic-mock-id',
        nameAr: 'عيادة النخبة التجميلية',
        nameEn: 'Elite Aesthetic Clinic',
        descriptionAr: 'عيادة متخصصة',
        descriptionEn: 'Specialized clinic',
        coverImageUrl: 'https://example.com/cover.jpg',
        galleryImages: [],
        logoUrl: '',
        rating: 4.9,
        reviewCount: 45,
        subscriptionTier: SubscriptionTier.vipPlatinum,
        city: 'Dubai',
        areaAr: 'داون تاون دبي',
        addressAr: 'بوليفارد برج خليفة',
        branches: [
          ClinicBranch(
            id: 'b-1',
            nameAr: 'فرع داون تاون',
            nameEn: 'Downtown Branch',
            areaAr: 'داون تاون',
            areaEn: 'Downtown',
            addressAr: 'شارع الشيخ محمد بن راشد',
            addressEn: 'Sheikh Mohammed Bin Rashid Blvd',
            phone: '+97141234567',
            distanceKm: 0.0,
            latitude: 25.1972,
            longitude: 55.2744,
          ),
        ],
        rawTreatments: [
          {
            'id': 't-101',
            'name_ar': 'جلسة تنظيف البشرة العميق',
            'name_en': 'Deep Skin Cleansing',
          },
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AppointmentRequestScreen(
            clinic: testClinic,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check that dropdown contains general consultation and clinic treatment
      expect(find.byType(AppointmentRequestScreen), findsOneWidget);
      expect(find.text('استشارة تجميلية وجلدية عامة'), findsOneWidget);

      // Verify UAE phone input is rendered with LuxuryPhoneInputField
      expect(find.byType(LuxuryPhoneInputField), findsOneWidget);
      expect(find.text('+971'), findsOneWidget);

      // Accept consent
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Submit lead
      final submitButton = find.text(LocaleService().tr('submit_lead_btn'));
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Ensure mandatory frozen wording is displayed on success screen
      expect(find.text('تم إرسال طلبك وستتواصل العيادة معك'), findsOneWidget);
    });
  });
}
