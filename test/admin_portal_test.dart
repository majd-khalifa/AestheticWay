import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/theme/app_theme.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_main_nav_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_clinics_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_leads_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_offers_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_analytics_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_lead_detail_screen.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';

void main() {
  setUp(() {
    LocaleService().setLanguage(AppLanguage.arabic);
  });

  group('Super Admin Unit Tests - Service & State', () {
    test('AdminPortalService initializes global metrics, clinics, leads, and offers', () {
      final service = AdminPortalService();
      expect(service.totalAppOpens, greaterThan(10000));
      expect(service.activeUsersCount, greaterThan(1000));
      expect(service.clinics.length, greaterThanOrEqualTo(5));
      expect(service.allLeads.length, greaterThanOrEqualTo(8));
      expect(service.allOffers.length, greaterThanOrEqualTo(5));
      expect(service.activeClinicsCount, greaterThan(0));
      expect(service.totalWhatsappTaps, greaterThan(0));
      expect(service.totalCallTaps, greaterThan(0));
    });

    test('AdminPortalService toggles clinic active and suspended status', () {
      final service = AdminPortalService();
      final clinicId = 'kaya-jumeirah';

      final initialStatus = service.getMetricForClinic(clinicId)?.isActive ?? true;
      service.toggleClinicStatus(clinicId);
      expect(service.getMetricForClinic(clinicId)?.isActive, equals(!initialStatus));

      service.toggleClinicStatus(clinicId);
      expect(service.getMetricForClinic(clinicId)?.isActive, equals(initialStatus));
    });

    test('AdminPortalService toggles offer moderation status', () {
      final service = AdminPortalService();
      final offerId = 'adm-off-101';

      expect(service.isOfferSuspended(offerId), isFalse);
      service.toggleOfferModeration(offerId);
      expect(service.isOfferSuspended(offerId), isTrue);
      service.toggleOfferModeration(offerId);
      expect(service.isOfferSuspended(offerId), isFalse);
    });

    test('AdminPortalService filters leads by clinic and status correctly', () {
      final service = AdminPortalService();
      final all = service.getFilteredLeads();
      expect(all.length, equals(service.allLeads.length));

      final kayaLeads = service.getFilteredLeads(clinicId: 'kaya-jumeirah');
      expect(kayaLeads.every((l) => l.clinicId == 'kaya-jumeirah'), isTrue);

      final sentLeads = service.getFilteredLeads(status: AppointmentLeadStatus.sent);
      expect(sentLeads.every((l) => l.status == AppointmentLeadStatus.sent), isTrue);
    });

    test('AdminPortalService calculates sorted analytics table', () {
      final service = AdminPortalService();
      final table = service.analyticsTable;
      expect(table, isNotEmpty);
      expect(table.first.totalDirectEngagement, greaterThanOrEqualTo(table.last.totalDirectEngagement));
    });
  });

  group('Super Admin UI Widget Tests', () {
    testWidgets('AdminMainNavScreen renders all 5 bottom tabs and title cleanly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AdminMainNavScreen(),
        ),
      );

      expect(find.text('الرئيسية'), findsWidgets);
      expect(find.text('العيادات'), findsWidgets);
      expect(find.text('الطلبات'), findsWidgets);
      expect(find.text('العروض'), findsWidgets);
      expect(find.text('الإحصائيات'), findsWidgets);
    });

    testWidgets('AdminDashboardScreen renders all 6 KPI cards and live activity', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: AdminDashboardScreen(
            onNavigateToClinics: () {},
            onNavigateToLeads: () {},
            onNavigateToAnalytics: () {},
          ),
        ),
      );

      expect(find.text('مرات فتح التطبيق'), findsOneWidget);
      expect(find.text('العيادات الشريكة'), findsOneWidget);
      expect(find.text('إجمالي طلبات الاستشارة'), findsOneWidget);
      expect(find.text('طلبات اليوم'), findsOneWidget);
      expect(find.text('تواصل عبر واتساب'), findsOneWidget);
      expect(find.text('تواصل عبر الاتصال'), findsOneWidget);
      expect(find.text('سجل النشاط المباشر في المنصة'), findsOneWidget);
    });

    testWidgets('AdminClinicsScreen renders clinics list and search bar', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AdminClinicsScreen(),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('جميع الباقات'), findsOneWidget);
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('AdminLeadsScreen renders clinic dropdown selector and leads', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AdminLeadsScreen(),
        ),
      );

      expect(find.byType(DropdownButton<String?>), findsOneWidget);
      expect(find.byType(ChoiceChip), findsWidgets);
    });

    testWidgets('AdminOffersScreen renders moderation controls', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AdminOffersScreen(),
        ),
      );

      expect(find.text('العروض'), findsWidgets);
      expect(find.text('المنتجات'), findsWidgets);
      expect(find.text('المقالات'), findsWidgets);
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('AdminAnalyticsScreen renders detailed clinic engagement breakdown', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AdminAnalyticsScreen(),
        ),
      );

      expect(find.text('التحليلات ومعدلات تفاعل المرضى مع العيادات'), findsOneWidget);
      expect(find.text('المشاهدات'), findsWidgets);
      expect(find.text('الطلبات'), findsWidgets);
      expect(find.text('واتساب'), findsWidgets);
      expect(find.text('اتصال'), findsWidgets);
      expect(find.text('معدل التفاعل'), findsWidgets);
    });

    testWidgets('AdminLeadDetailScreen renders supervision monitoring banner and no clinic note editors', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      final testLead = AdminPortalService().allLeads.first;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: AdminLeadDetailScreen(lead: testLead),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('للمراقبة فقط — إدارة التواصل تتم من حساب العيادة'), findsOneWidget);
      expect(find.text(testLead.patientFullName), findsOneWidget);
      expect(find.text('ملاحظات العيادة الداخلية'), findsNothing);
      expect(find.text('تغيير حالة الطلب'), findsNothing);
    });
  });
}
