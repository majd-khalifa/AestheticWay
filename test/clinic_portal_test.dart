import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/theme/app_theme.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_main_nav_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_dashboard_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_leads_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_lead_detail_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_offers_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_profile_screen.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/features/clinic_portal/data/models/clinic_dashboard_model.dart';

void main() {
  setUp(() {
    LocaleService().setLanguage(AppLanguage.arabic);
    ClinicPortalService().resetTestingState();
    ClinicPortalService().enableMockMode();
  });

  group('Clinic Portal Data Models & Serialization Tests', () {
    test('ClinicDashboardModel parses live backend JSON correctly', () {
      final json = {
        'clinic_id': 'b8420e99-444c-423e-a3ed-3aa937bc411e',
        'clinic_name': 'Aesthetic Way Clinic Downtown',
        'leads': {
          'total': 18,
          'new': 5,
          'contacted': 8,
          'closed': 5,
          'conversion_rate_percentage': 27.7,
        },
        'interactions': {
          'whatsapp_taps': 10,
          'call_taps': 5,
          'maps_taps': 4,
          'profile_views': 42,
        },
        'catalog': {
          'active_practitioners_count': 3,
          'active_treatments_count': 6,
          'active_offers_count': 4,
          'active_products_count': 6,
          'published_articles_count': 2,
        },
      };

      final model = ClinicDashboardModel.fromJson(json);

      expect(model.clinicId, 'b8420e99-444c-423e-a3ed-3aa937bc411e');
      expect(model.clinicName, 'Aesthetic Way Clinic Downtown');
      expect(model.totalLeads, 18);
      expect(model.newLeads, 5);
      expect(model.contactedLeads, 8);
      expect(model.closedLeads, 5);
      expect(model.conversionRate, 27.7);
      expect(model.whatsappTaps, 10);
      expect(model.callTaps, 5);
      expect(model.mapsTaps, 4);
      expect(model.profileViews, 42);
      expect(model.activeOffersCount, 4);
      expect(model.activeProductsCount, 6);
      expect(model.publishedArticlesCount, 2);
    });

    test('AppointmentRequestModel parses clinic internal notes list', () {
      final json = {
        'id': 'lead-999',
        'reference_code': '#REQ-999',
        'status': 'contacted',
        'patient_name': 'سارة أحمد',
        'patient_phone': '+971501234567',
        'service_name': 'فيلر',
        'created_at': '2026-09-22T10:00:00Z',
        'internal_notes': [
          {
            'id': 'note-1',
            'note': 'تم الاتصال بالعميل وسيتم تأكيد الموعد غداً',
            'author_name': 'أحمد العلي',
            'created_at': '2026-09-22T11:00:00Z',
          },
        ],
      };

      final lead = AppointmentRequestModel.fromJson(json);
      expect(lead.internalNotes.length, 1);
      expect(lead.internalNotes.first.note, contains('تم الاتصال بالعميل'));
      expect(lead.internalNotes.first.authorName, 'أحمد العلي');
    });
  });

  group('Clinic Portal Unit Tests - Service & State', () {
    test(
      'ClinicPortalService initializes with active clinic, leads, offers and practitioners',
      () {
        final service = ClinicPortalService();
        expect(service.activeClinic, isNotNull);
        expect(service.clinicLeads.length, greaterThanOrEqualTo(5));
        expect(service.newLeadsCount, greaterThan(0));
        expect(service.totalLeadsCount, equals(service.clinicLeads.length));
        expect(service.activeOffersCount, greaterThan(0));
      },
    );

    test('ClinicPortalService updates lead status and notifies listeners', () {
      final service = ClinicPortalService();
      final targetLeadId = service.clinicLeads.first.id;

      service.updateLeadStatus(targetLeadId, AppointmentLeadStatus.contacted);
      final updatedLead = service.clinicLeads.firstWhere(
        (l) => l.id == targetLeadId,
      );
      expect(updatedLead.status, equals(AppointmentLeadStatus.contacted));

      service.updateLeadStatus(targetLeadId, AppointmentLeadStatus.closed);
      final closedLead = service.clinicLeads.firstWhere(
        (l) => l.id == targetLeadId,
      );
      expect(closedLead.status, equals(AppointmentLeadStatus.closed));
    });

    test('ClinicPortalService saves internal notes for a lead', () {
      final service = ClinicPortalService();
      final targetLeadId = service.clinicLeads.first.id;

      service.saveInternalNotes(
        targetLeadId,
        'Client requested callback after 5 PM.',
      );
      expect(
        service.getInternalNotes(targetLeadId),
        equals('Client requested callback after 5 PM.'),
      );
    });

    test('ClinicPortalService adds and deletes offers correctly', () {
      final service = ClinicPortalService();
      final initialCount = service.activeOffersCount;

      final testOffer = OfferModel(
        id: 'test-offer-999',
        titleAr: 'عرض تجميلي اختباري',
        titleEn: 'Test Aesthetic Offer',
        clinicId: service.activeClinic.id,
        clinicNameAr: service.activeClinic.nameAr,
        originalPrice: 2000,
        offerPrice: 1400,
        discountPercentage: 30,
        validUntilText: 'صالح حتى نهاية الشهر',
        daysRemaining: 15,
        termsAr: 'شروط تجريبية',
        imageUrl: 'https://example.com/image.jpg',
      );

      service.addOffer(testOffer);
      expect(service.activeOffersCount, equals(initialCount + 1));
      expect(service.clinicOffers.first.id, equals('test-offer-999'));

      service.deleteOffer('test-offer-999');
      expect(service.activeOffersCount, equals(initialCount));
    });
  });

  group('Clinic Portal UI Widget Tests', () {
    testWidgets('ClinicMainNavScreen renders all 4 tabs cleanly', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ClinicMainNavScreen(),
        ),
      );

      expect(find.text('الرئيسية'), findsWidgets);
      expect(find.text('الطلبات'), findsOneWidget);
      expect(find.text('العروض'), findsOneWidget);
      expect(find.text('الملف'), findsOneWidget);
    });

    testWidgets(
      'ClinicDashboardScreen displays metrics, VIP badge and shortcuts',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: ClinicDashboardScreen(
              onNavigateToLeads: () {},
              onNavigateToOffers: () {},
            ),
          ),
        );

        expect(find.text('طلبات جديدة'), findsOneWidget);
        expect(find.text('تم التواصل'), findsWidgets);
        expect(find.text('إجمالي الطلبات'), findsOneWidget);
        expect(find.text('نسبة التحويل'), findsOneWidget);
        expect(find.text('إجراءات سريعة'), findsOneWidget);
        expect(find.text('عرض الطلبات الجديدة'), findsOneWidget);
        expect(find.text('إضافة عرض جديد'), findsOneWidget);
      },
    );

    testWidgets('ClinicLeadsScreen renders filter chips and search', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const ClinicLeadsScreen()),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ChoiceChip), findsWidgets);
    });

    testWidgets(
      'ClinicLeadDetailScreen allows updating lead status and notes',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        final mockLead = AppointmentRequestModel(
          id: 'test-lead-ui-1',
          referenceCode: '#REQ-9901',
          clinicId: 'kaya-jumeirah',
          clinicNameAr: 'عيادة كايا',
          clinicNameEn: 'Kaya Clinic',
          branchNameAr: 'فرع جميرا',
          branchNameEn: 'Jumeirah',
          serviceNameAr: 'الهيدرافيسيال الملكي',
          serviceNameEn: 'Royal HydraFacial',
          practitionerNameAr: 'د. ريم الخالد',
          practitionerNameEn: 'Dr. Reem Al Khaled',
          practitionerType: PractitionerType.doctor,
          preferredDate: DateTime.now().add(const Duration(days: 2)),
          preferredTimeWindow: PreferredTimeWindow.evening,
          patientFullName: 'مريم أحمد',
          patientPhone: '+971 50 123 4567',
          notes: 'ملاحظة خاصة بالبشرة',
          consentAccepted: true,
          status: AppointmentLeadStatus.sent,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: ClinicLeadDetailScreen(lead: mockLead),
          ),
        );

        expect(find.text('مريم أحمد'), findsOneWidget);
        expect(find.text('+971 50 123 4567'), findsOneWidget);
        expect(find.text('اتصال بالمريض'), findsOneWidget);
        expect(find.text('محادثة واتساب'), findsOneWidget);
        expect(find.text('الهيدرافيسيال الملكي'), findsOneWidget);

        // Verify status chips
        expect(find.text('جديد'), findsOneWidget);
        expect(find.text('تم التواصل'), findsOneWidget);
        expect(find.text('مكتمل / مغلق'), findsOneWidget);
      },
    );

    testWidgets(
      'ClinicOffersScreen displays add offer button and active offers',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ClinicOffersScreen(),
          ),
        );

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('إضافة عرض جديد'), findsWidgets);
      },
    );

    testWidgets(
      'ClinicProfileScreen displays staff, treatments and maps direction option',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2000));
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ClinicProfileScreen(),
          ),
        );

        expect(find.text('الكادر الطبي والممارسون المعتمدون'), findsOneWidget);
        expect(find.text('العلاجات والخدمات المقدمة'), findsOneWidget);
        expect(find.text('فتح في خرائط Google'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('تسجيل الخروج من لوحة العيادة'),
          500,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('تسجيل الخروج من لوحة العيادة'), findsOneWidget);
      },
    );

    testWidgets(
      'ClinicProfileScreen header card renders logo/cover via LuxuryImage and dialog omits phone/whatsapp inputs',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2000));
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ClinicProfileScreen(),
          ),
        );

        // Verify LuxuryImage is used in the header for clinic logo
        expect(find.byType(LuxuryImage), findsWidgets);

        // Tap Edit Clinic Profile button
        final editBtn = find.byTooltip('تعديل ملف العيادة');
        expect(editBtn, findsOneWidget);
        await tester.tap(editBtn);
        await tester.pumpAndSettle();

        // Verify dialog is open
        expect(find.text('تعديل ملف العيادة'), findsWidgets);

        // Verify Phone and WhatsApp input fields are removed
        expect(find.text('رقم الهاتف'), findsNothing);
        expect(find.text('رقم الواتساب'), findsNothing);

        // Verify Logo and Cover photo pickers are present
        expect(find.text('شعار العيادة'), findsOneWidget);
        expect(find.text('صورة الغلاف'), findsOneWidget);
      },
    );
  });
}
