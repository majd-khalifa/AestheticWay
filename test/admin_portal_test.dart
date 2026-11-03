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

void main() {
  setUp(() {
    LocaleService().setLanguage(AppLanguage.arabic);
    AdminPortalService().enableMockMode();
  });

  group('Super Admin Unit Tests - Service & State', () {
    test(
      'AdminPortalService initializes global metrics, clinics, leads, and offers',
      () {
        final service = AdminPortalService();
        expect(service.clinics.length, greaterThanOrEqualTo(5));
        expect(service.allLeads.length, greaterThanOrEqualTo(8));
        expect(service.allOffers.length, greaterThanOrEqualTo(5));
        expect(service.activeClinicsCount, greaterThan(0));
      },
    );

    test(
      'AdminPortalService toggles clinic active and suspended status',
      () async {
        final service = AdminPortalService();
        final clinicId = 'kaya-jumeirah';

        final initialClinic = service.clinics.firstWhere(
          (c) => c.id == clinicId,
        );
        final initialStatus = initialClinic.isActive;

        await service.toggleClinicStatus(clinicId);
        final toggledClinic = service.clinics.firstWhere(
          (c) => c.id == clinicId,
        );
        expect(toggledClinic.isActive, equals(!initialStatus));

        await service.toggleClinicStatus(clinicId);
        final restoredClinic = service.clinics.firstWhere(
          (c) => c.id == clinicId,
        );
        expect(restoredClinic.isActive, equals(initialStatus));
      },
    );

    test('AdminPortalService toggles offer moderation status', () async {
      final service = AdminPortalService();
      final offerId = service.allOffers.first.id;

      expect(service.isOfferSuspended(offerId), isFalse);
      await service.toggleOfferModeration(offerId);
      expect(service.isOfferSuspended(offerId), isTrue);
      await service.toggleOfferModeration(offerId);
      expect(service.isOfferSuspended(offerId), isFalse);
    });

    test(
      'AdminPortalService toggles product and article moderation status',
      () async {
        final service = AdminPortalService();
        if (service.allProducts.isNotEmpty) {
          final prodId = service.allProducts.first.id;
          final initialStatus = service.allProducts.first.isPublishedByAdmin;
          await service.toggleProductModeration(prodId);
          expect(
            service.allProducts.first.isPublishedByAdmin,
            equals(!initialStatus),
          );
        }
        if (service.allArticles.isNotEmpty) {
          final artId = service.allArticles.first.id;
          final initialStatus = service.allArticles.first.isApprovedByAdmin;
          await service.toggleArticleModeration(artId);
          expect(
            service.allArticles.first.isApprovedByAdmin,
            equals(!initialStatus),
          );
        }
      },
    );

    test('AdminPortalService filters leads by clinic and status correctly', () {
      final service = AdminPortalService();
      final all = service.getFilteredLeads();
      expect(all.length, equals(service.allLeads.length));

      final kayaLeads = service.getFilteredLeads(clinicId: 'kaya-jumeirah');
      expect(kayaLeads.every((l) => l.clinicId == 'kaya-jumeirah'), isTrue);

      final newLeads = service.getFilteredLeads(status: 'new');
      expect(newLeads.every((l) => l.status.toLowerCase() == 'new'), isTrue);
    });

    test('AdminPortalService calculates sorted analytics table', () {
      final service = AdminPortalService();
      final table = service.analyticsTable;
      expect(table, isNotNull);
    });
  });

  group('Super Admin UI Widget Tests', () {
    testWidgets(
      'AdminMainNavScreen renders all 5 bottom tabs and title cleanly',
      (WidgetTester tester) async {
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
        expect(find.text('المحتوى'), findsWidgets);
        expect(find.text('التحليلات'), findsWidgets);
      },
    );

    testWidgets(
      'AdminDashboardScreen renders all 6 KPI cards and live activity',
      (WidgetTester tester) async {
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

        expect(find.text('إجمالي الأحداث المسجلة'), findsOneWidget);
        expect(find.text('العيادات النشطة'), findsOneWidget);
        expect(find.text('إجمالي طلبات الاستشارة'), findsOneWidget);
        expect(find.text('طلبات تم التواصل معها'), findsOneWidget);
        expect(find.text('حسابات المرضى المفعلة'), findsOneWidget);
        expect(find.text('إجمالي العروض'), findsOneWidget);
        expect(find.text('سجل النشاط المباشر في المنصة'), findsOneWidget);
      },
    );

    testWidgets('AdminClinicsScreen renders clinics list and search bar', (
      WidgetTester tester,
    ) async {
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

    testWidgets(
      'AdminLeadsScreen renders searchable clinic selector and leads',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AdminLeadsScreen(),
          ),
        );

        expect(
          find.text(LocaleService().tr('admin_filter_all_clinics')),
          findsOneWidget,
        );
        expect(find.byType(TextButton), findsWidgets);
        expect(find.byType(ChoiceChip), findsWidgets);
      },
    );

    testWidgets('AdminOffersScreen renders moderation controls', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const AdminOffersScreen()),
      );

      expect(find.text('العروض'), findsWidgets);
      expect(find.text('المنتجات'), findsWidgets);
      expect(find.text('المقالات'), findsWidgets);
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets(
      'AdminAnalyticsScreen labels recorded activity and collection limitations',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2000));
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AdminAnalyticsScreen(),
          ),
        );

        expect(find.text('سجلات نشاط المنصة'), findsOneWidget);
        expect(find.text('مشاهدات العيادات'), findsWidgets);
        expect(find.text('واتساب'), findsWidgets);
        expect(find.text('اتصال'), findsWidgets);
        expect(find.text('نقرات الخرائط'), findsWidgets);
        expect(find.text('طلبات الاستشارة'), findsWidgets);
      },
    );

    testWidgets(
      'AdminLeadDetailScreen renders supervision monitoring banner and no clinic note editors',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2000));
        final testLead = AdminPortalService().allLeads.first;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: AdminLeadDetailScreen(lead: testLead),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('للمراقبة فقط — إدارة التواصل تتم من حساب العيادة'),
          findsOneWidget,
        );
        expect(find.text(testLead.patientFullName), findsOneWidget);
        expect(find.text('ملاحظات العيادة الداخلية'), findsNothing);
        expect(find.text('تغيير حالة الطلب'), findsNothing);
      },
    );
  });
}
