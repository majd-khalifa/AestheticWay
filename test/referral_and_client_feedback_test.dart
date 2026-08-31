import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/before_after_preview.dart';
import 'package:aesthetic_way/features/referral/models/referral_model.dart';
import 'package:aesthetic_way/features/referral/services/referral_service.dart';
import 'package:aesthetic_way/features/referral/presentation/screens/referral_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_verify_code_screen.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/practitioners/presentation/screens/practitioner_profile_screen.dart';

void main() {
  group('Referral & Rewards System Unit Tests', () {
    late ReferralService referralService;

    setUp(() {
      referralService = ReferralService();
    });

    test('Milestones have correct 3 thresholds and cumulative points', () {
      expect(ReferralService.milestones.length, 3);
      expect(ReferralService.milestones[0].requiredInvites, 20);
      expect(ReferralService.milestones[0].pointsAwarded, 100);

      expect(ReferralService.milestones[1].requiredInvites, 35);
      expect(ReferralService.milestones[1].pointsAwarded, 175);

      expect(ReferralService.milestones[2].requiredInvites, 50);
      expect(ReferralService.milestones[2].pointsAwarded, 250);
    });

    test('Cumulative points threshold calculation: 50 invites yields 525 points (>= 500)', () {
      // Reaching 50 invites yields 100 + 175 + 250 = 525 points
      referralService.addDemoInvites(50);
      expect(referralService.successfulInvites >= 50, isTrue);
      expect(referralService.currentPoints >= 500, isTrue);
      expect(referralService.canCollectDiscountCode, isTrue);
    });

    test('Collecting 15% discount code generates AW-15-XXXX code', () {
      // Add sufficient points to collect
      referralService.addDemoPoints(500);
      expect(referralService.canCollectDiscountCode, isTrue);

      final code = referralService.collectDiscountCode(userName: 'سارة المنصوري');
      expect(code.code.startsWith('AW-15-'), isTrue);
      expect(code.discountPercent, 15.0);
      expect(code.status, ReferralCodeStatus.available);
      expect(code.isAvailable, isTrue);
      expect(referralService.userCodes.any((c) => c.code == code.code), isTrue);
    });

    test('Clinic code validation and redemption', () {
      referralService.addDemoPoints(500);
      final newCode = referralService.collectDiscountCode(userName: 'مريم الشامسي');

      // Verify code
      final verified = referralService.verifyCode(newCode.code);
      expect(verified, isNotNull);
      expect(verified!.isAvailable, isTrue);

      // Redeem code at clinic
      final redeemed = referralService.redeemCode(
        code: newCode.code,
        clinicId: 'elegance-downtown',
        clinicName: 'مركز الأناقة الطبي للجلدية والتجميل',
      );
      expect(redeemed, isTrue);

      final afterRedeem = referralService.verifyCode(newCode.code);
      expect(afterRedeem!.status, ReferralCodeStatus.used);
      expect(afterRedeem.isUsed, isTrue);
      expect(afterRedeem.isAvailable, isFalse);
      expect(afterRedeem.usedClinicId, 'elegance-downtown');

      // Cannot re-redeem already used code
      final secondAttempt = referralService.redeemCode(
        code: newCode.code,
        clinicId: 'elegance-downtown',
        clinicName: 'مركز الأناقة الطبي للجلدية والتجميل',
      );
      expect(secondAttempt, isFalse);
    });
  });

  group('Client Feedback Cleansing & Exact Copy Tests', () {
    test('Onboarding Slide 1 has verbatim client Arabic & English text', () {
      final loc = LocaleService();
      expect(
        loc.tr('onboarding_desc_1'),
        'عيادات التجميل والجلدية في الإمارات أصبحت بين يديك بالإضافة لكثير من الأطباء وخبراء البشرة',
      );

      loc.setLanguage(AppLanguage.english);
      expect(
        loc.tr('onboarding_desc_1'),
        'Aesthetic and dermatology clinics in the UAE are now at your fingertips, along with many doctors and skin experts',
      );
      loc.setLanguage(AppLanguage.arabic);
    });

    test('Nearby clinics title is renamed to العيادات القريبة منك / Clinics near you', () {
      final loc = LocaleService();
      expect(loc.tr('nearby_title'), 'العيادات القريبة منك');

      loc.setLanguage(AppLanguage.english);
      expect(loc.tr('nearby_title'), 'Clinics near you');
      loc.setLanguage(AppLanguage.arabic);
    });

    test('Support is renamed to الدعم وخدمة العملاء / Customer Support (No Concierge in main label)', () {
      final loc = LocaleService();
      expect(loc.tr('support_help'), 'الدعم وخدمة العملاء');

      loc.setLanguage(AppLanguage.english);
      expect(loc.tr('support_help'), 'Customer Support');
      loc.setLanguage(AppLanguage.arabic);
    });
  });

  group('Referral and Before/After Widget Tests', () {
    testWidgets('ReferralScreen renders copyable code and points progress', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ReferralScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('برنامج الدعوات والمكافآت'), findsWidgets);
      expect(find.text('AW-DUBAI-88'), findsOneWidget);
      expect(find.text('نسخ الكود'), findsWidgets);
      expect(find.text('مستويات النقاط والمكافآت'), findsOneWidget);
    });

    testWidgets('ClinicVerifyCodeScreen verifies and displays 15% discount note', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ClinicVerifyCodeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('التحقق من كود الخصم (15%)'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('BeforeAfterPreview widget renders before and after labels cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BeforeAfterPreview(
              beforeImageUrl: 'https://images.unsplash.com/photo-1512290900672-1f02e604ec22?auto=format&fit=crop&w=600&q=80',
              afterImageUrl: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=600&q=80',
              titleAr: 'نتائج نضارة الوجه',
              titleEn: 'Facial Glow Outcomes',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('نتائج نضارة الوجه'), findsOneWidget);
      expect(find.text('قبل'), findsOneWidget);
      expect(find.text('بعد'), findsOneWidget);
    });

    testWidgets('Practitioner profile does not display license badges or numbers', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      const mockPractitioner = PractitionerModel(
        id: 'dr-test',
        clinicId: 'elegance-downtown',
        clinicNameAr: 'مركز الأناقة الطبي للجلدية والتجميل',
        nameAr: 'د. سارة المنصوري',
        nameEn: 'Dr. Sarah Al Mansoori',
        classificationAr: 'استشارية جلدية وتجميل',
        type: PractitionerType.doctor,
        specialtyAr: 'جلدية وعلاجات الليزر',
        specialtyEn: 'Dermatology & Laser',
        licenseAuthority: 'DHA',
        licenseNumber: 'LIC-DHA-999888',
        rating: 4.9,
        reviewCount: 88,
        yearsOfExperience: 12,
        languages: ['العربية', 'English'],
        procedures: ['حقن الفيلر', 'البوتوكس'],
        avatarUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=300&q=80',
        aboutAr: 'خبرة متقدمة في علاجات البشرة والنضارة.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: PractitionerProfileScreen(practitioner: mockPractitioner),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('د. سارة المنصوري'), findsWidgets);
      expect(find.text('LIC-DHA-999888'), findsNothing);
      expect(find.textContaining('ترخيص'), findsNothing);
    });
  });
}
