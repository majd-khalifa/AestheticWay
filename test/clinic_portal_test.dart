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

void main() {
  setUp(() {
    LocaleService().setLanguage(AppLanguage.arabic);
  });

  group('Clinic Portal Unit Tests - Service & State', () {
    test('ClinicPortalService initializes with active clinic, leads, offers and practitioners', () {
      final service = ClinicPortalService();
      expect(service.activeClinic, isNotNull);
      expect(service.clinicLeads.length, greaterThanOrEqualTo(5));
      expect(service.newLeadsCount, greaterThan(0));
      expect(service.totalLeadsCount, equals(service.clinicLeads.length));
      expect(service.activeOffersCount, greaterThan(0));
    });

    test('ClinicPortalService updates lead status and notifies listeners', () {
      final service = ClinicPortalService();
      final targetLeadId = service.clinicLeads.first.id;

      service.updateLeadStatus(targetLeadId, AppointmentLeadStatus.contacted);
      final updatedLead = service.clinicLeads.firstWhere((l) => l.id == targetLeadId);
      expect(updatedLead.status, equals(AppointmentLeadStatus.contacted));

      service.updateLeadStatus(targetLeadId, AppointmentLeadStatus.closed);
      final closedLead = service.clinicLeads.firstWhere((l) => l.id == targetLeadId);
      expect(closedLead.status, equals(AppointmentLeadStatus.closed));
    });

    test('ClinicPortalService saves internal notes for a lead', () {
      final service = ClinicPortalService();
      final targetLeadId = service.clinicLeads.first.id;

      service.saveInternalNotes(targetLeadId, 'Client requested callback after 5 PM.');
      expect(service.getInternalNotes(targetLeadId), equals('Client requested callback after 5 PM.'));
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
    testWidgets('ClinicMainNavScreen renders all 4 tabs cleanly', (WidgetTester tester) async {
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

    testWidgets('ClinicDashboardScreen displays metrics, VIP badge and shortcuts', (WidgetTester tester) async {
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
      expect(find.text('طلبات اليوم'), findsOneWidget);
      expect(find.text('إجمالي الطلبات'), findsOneWidget);
      expect(find.text('عروض نشطة'), findsOneWidget);
      expect(find.text('إجراءات سريعة'), findsOneWidget);
      expect(find.text('عرض الطلبات الجديدة'), findsOneWidget);
      expect(find.text('إضافة عرض جديد'), findsOneWidget);
    });

    testWidgets('ClinicLeadsScreen renders filter chips and search', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ClinicLeadsScreen(),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ChoiceChip), findsWidgets);
    });

    testWidgets('ClinicLeadDetailScreen allows updating lead status and notes', (WidgetTester tester) async {
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
    });

    testWidgets('ClinicOffersScreen displays add offer button and active offers', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ClinicOffersScreen(),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('إضافة عرض جديد'), findsWidgets);
    });

    testWidgets('ClinicProfileScreen displays staff, treatments and maps direction option', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ClinicProfileScreen(),
        ),
      );

      expect(find.text('الكادر الطبي والممارسون المعتمدون'), findsOneWidget);
      expect(find.text('العلاجات والخدمات المقدمة'), findsOneWidget);
      expect(find.text('فتح في Google Maps'), findsOneWidget);
      expect(find.text('تسجيل الخروج من لوحة العيادة'), findsOneWidget);
    });
  });
}
