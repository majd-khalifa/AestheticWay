import 'package:aesthetic_way/core/widgets/paged_entity_field.dart';
import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/features/practitioners/data/practitioners_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/theme/app_theme.dart';
import 'package:aesthetic_way/data/mock_data.dart';
import 'package:aesthetic_way/features/offers/presentation/screens/offers_screen.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/appointment_lead/data/leads_repository.dart';

void main() {
  setUp(() {
    LocaleService().setLanguage(AppLanguage.arabic);
    AuthState().login(
      name: 'ماجد خليفة',
      phone: '+971 50 123 4567',
      email: 'majd@example.com',
    );
  });

  group('Dropdown Safety & Offer Lead Tests', () {
    final mockData = MockDataService();
    final testClinic = mockData.clinics.first;

    testWidgets(
      'AppointmentRequestScreen handles arbitrary unlisted service name without DropdownButton crash',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));

        // Pass an unlisted service name that doesn't exist in the clinic's treatments
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: AppointmentRequestScreen(
              clinic: testClinic,
              preselectedServiceName:
                  'إجراء غير موجود نهائياً في قائمة العيادة',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Ensure form renders without any DropdownButton value crash
        expect(find.byType(AppointmentRequestScreen), findsOneWidget);
        expect(find.byType(DropdownButton<String>), findsNothing);
        expect(
          find.text('إجراء غير موجود نهائياً في قائمة العيادة'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AppointmentRequestScreen renders Offer Summary Card when selectedOfferTitle is provided',
      (WidgetTester tester) async {
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
      },
    );

    testWidgets(
      'OffersScreen claim button navigates cleanly to AppointmentRequestScreen without crash',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1800));

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: OffersScreen(initialOffers: MockDataService().offers),
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
      },
    );

    testWidgets(
      'AppointmentRequestScreen successfully submits lead inquiry without full calendar booking',
      (WidgetTester tester) async {
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
      },
    );

    testWidgets(
      'Practitioner dropdown safely renders, opens without assertion error, and supports null preference even with duplicate rawPractitioners',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1800));

        final clinicWithDuplicatePractitioners = ClinicModel(
          id: testClinic.id,
          nameAr: testClinic.nameAr,
          nameEn: testClinic.nameEn,
          descriptionAr: testClinic.descriptionAr,
          descriptionEn: testClinic.descriptionEn,
          coverImageUrl: testClinic.coverImageUrl,
          galleryImages: testClinic.galleryImages,
          logoUrl: testClinic.logoUrl,
          rating: testClinic.rating,
          reviewCount: testClinic.reviewCount,
          subscriptionTier: testClinic.subscriptionTier,
          city: testClinic.city,
          areaAr: testClinic.areaAr,
          addressAr: testClinic.addressAr,
          branches: testClinic.branches,
          rawPractitioners: [
            {
              'id': 'p-1',
              'name_ar': 'د. سارة المنصوري',
              'name_en': 'Dr. Sara Al Mansoori',
              'type': 'doctor',
            },
            // Duplicate with identical id to test deduplication safety
            {
              'id': 'p-1',
              'name_ar': 'د. سارة المنصوري (مكرر)',
              'name_en': 'Dr. Sara Al Mansoori (Duplicate)',
              'type': 'doctor',
            },
            {
              'id': 'p-2',
              'name_ar': 'د. أحمد خليل',
              'name_en': 'Dr. Ahmed Khalil',
              'type': 'doctor',
            },
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: AppointmentRequestScreen(
              clinic: clinicWithDuplicatePractitioners,
              practitionersRepository: FixturePractitionersRepository(
                clinicWithDuplicatePractitioners.rawPractitioners!,
              ),
              // Preselected practitioner with non-existent id
              preselectedPractitioner: const PractitionerModel(
                id: 'non-existent-p-99',
                nameAr: 'غير موجود',
                nameEn: 'Non Existent',
                type: PractitionerType.doctor,
                specialtyAr: 'جلدية',
                specialtyEn: 'Derma',
                classificationAr: 'استشاري',
                licenseAuthority: 'DHA',
                licenseNumber: '123',
                avatarUrl: '',
                yearsOfExperience: 5,
                rating: 5.0,
                reviewCount: 10,
                languages: ['ar'],
                clinicId: 'c1',
                clinicNameAr: 'ع1',
                procedures: [],
                aboutAr: '',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Ensure form renders without any DropdownButton assertion crash
        expect(find.byType(AppointmentRequestScreen), findsOneWidget);

        final practitionerField = find.byType(
          PagedEntityField<PractitionerModel>,
        );
        expect(practitionerField, findsOneWidget);
        await tester.tap(
          find.descendant(
            of: practitionerField,
            matching: find.byType(TextButton),
          ),
        );
        await tester.pumpAndSettle();
        // Duplicate source IDs render once; the clear preference remains available.
        expect(find.text('د. سارة المنصوري'), findsOneWidget);
        expect(find.text('د. أحمد خليل'), findsOneWidget);
        expect(
          find.text(LocaleService().tr('any_practitioner')),
          findsOneWidget,
        );
        await tester.tap(find.text('د. أحمد خليل'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<PagedEntityField<PractitionerModel>>(practitionerField)
              .value,
          'p-2',
        );
      },
    );

    testWidgets(
      'AppointmentRequestScreen displays exact Arabic message on 429 duplicate submission',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1800));

        final mockRepo = _Mock429LeadsRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: AppointmentRequestScreen(
              clinic: testClinic,
              leadsRepository: mockRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enter name and phone
        await tester.enterText(find.byType(TextFormField).first, 'مريض تجريبي');
        await tester.enterText(find.byType(TextFormField).at(1), '501234567');

        // Check consent
        final checkbox = find.byType(Checkbox);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        // Tap submit
        final submitBtn = find.text(LocaleService().tr('submit_lead_btn'));
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // Expect exact user-requested 429 duplicate message
        expect(
          find.text('تم إرسال طلب مشابه مؤخرًا. يرجى المحاولة بعد قليل'),
          findsOneWidget,
        );
      },
    );
  });
}

class _Mock429LeadsRepository extends LeadsRepository {
  @override
  Future<LeadSubmitResult> createLead(Map<String, dynamic> payload) async {
    throw ApiException(
      message:
          'A request for this service at this clinic was already submitted recently.',
      statusCode: 429,
    );
  }
}

class FixturePractitionersRepository extends PractitionersRepository {
  FixturePractitionersRepository(this.raw);
  final List<dynamic> raw;
  @override
  Future<List<PractitionerModel>> getPractitioners({
    int page = 1,
    int pageSize = 20,
    String? type,
    String? types,
    String? clinicId,
    String? city,
    String? search,
  }) async => PageItems(
    raw.whereType<Map<String, dynamic>>().map(PractitionerModel.fromJson),
    hasMore: false,
  );
}
