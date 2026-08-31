import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/theme/app_theme.dart';
import 'package:aesthetic_way/data/mock_data.dart';
import 'package:aesthetic_way/features/offers/presentation/screens/offers_screen.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';

void main() {
  setUp(() {
    AuthState().login(
      name: 'ماجد خليفة',
      phone: '+971 50 123 4567',
      email: 'majd@example.com',
    );
  });

  group('Dropdown Safety & Offer Lead Tests', () {
    final mockData = MockDataService();
    final testClinic = mockData.clinics.first;

    testWidgets('AppointmentRequestScreen handles arbitrary unlisted service name without DropdownButton crash', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));

      // Pass an unlisted service name that doesn't exist in the clinic's treatments
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: AppointmentRequestScreen(
            clinic: testClinic,
            preselectedServiceName: 'إجراء غير موجود نهائياً في قائمة العيادة',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure form renders without any DropdownButton value crash
      expect(find.byType(AppointmentRequestScreen), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
      expect(find.text('استشارة تجميلية وجلدية عامة'), findsOneWidget);
    });

    testWidgets('AppointmentRequestScreen renders Offer Summary Card when selectedOfferTitle is provided', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      const testOfferTitle = 'باكج نضارة البشرة الصيفي المتكامل';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: AppointmentRequestScreen(
            clinic: testClinic,
            selectedOfferTitle: testOfferTitle,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Offer Summary Card must be visible with offer title
      expect(find.text(testOfferTitle), findsOneWidget);
      expect(find.text('باقة العرض المختارة'), findsOneWidget);
      expect(find.byIcon(Icons.local_offer_outlined), findsWidgets);
    });

    testWidgets('OffersScreen claim button navigates cleanly to AppointmentRequestScreen without crash', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1800));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const OffersScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OffersScreen), findsOneWidget);

      // Find first "طلب بالعرض" button
      final claimButtons = find.text('طلب بالعرض');
      expect(claimButtons, findsWidgets);

      await tester.tap(claimButtons.first);
      await tester.pumpAndSettle();

      // Must have navigated to AppointmentRequestScreen with Offer Summary Card
      expect(find.byType(AppointmentRequestScreen), findsOneWidget);
      expect(find.text('باقة العرض المختارة'), findsOneWidget);
    });

    testWidgets('AppointmentRequestScreen successfully submits lead inquiry without full calendar booking', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1800));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: AppointmentRequestScreen(
            clinic: testClinic,
            selectedOfferTitle: 'عرض الهيدرافاشيال الفاخر',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check consent checkbox
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Tap submit button
      final submitBtn = find.text(LocaleService().tr('submit_lead_btn'));
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Mandatory success message must be present
      expect(find.text('تم إرسال طلبك وستتواصل العيادة معك'), findsOneWidget);
    });
  });
}
