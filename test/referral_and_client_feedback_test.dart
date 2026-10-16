import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/utils/contact_launcher.dart';
import 'package:aesthetic_way/features/referral/models/referral_model.dart';
import 'package:aesthetic_way/features/referral/services/referral_service.dart';
import 'package:aesthetic_way/features/referral/presentation/screens/referral_screen.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/practitioners/presentation/screens/practitioner_profile_screen.dart';

void main() {
  setUp(() {
    LocaleService().setLanguage(AppLanguage.arabic);
  });

  group('Referral & Rewards System Unit Tests', () {
    late ReferralService referralService;

    setUp(() {
      referralService = ReferralService();
      referralService.resetTestingState();
      referralService.enableMockMode();
    });

    test('PatientReferralStatusModel and CollectCodeResult parse backend responses', () {
      final statusJson = {
        'referral_code': 'AW-ABC-123',
        'successful_invites_count': 35,
        'total_successful_invites': 35,
        'current_points': 275,
        'points_to_collect': 500,
        'can_collect_code': false,
        'points_expire': false,
        'milestones': {
          '20': true,
          '35': true,
          '50': false,
        },
        'discount_codes': [
          {
            'id': 'code-uuid-1',
            'code': 'AW-15-7890',
            'status': 'available',
            'created_at': '2026-09-22T10:00:00Z',
            'expires_at': '2026-12-21T10:00:00Z',
            'redeemed_at': null,
          }
        ]
      };

      final statusModel = PatientReferralStatusModel.fromJson(statusJson);
      expect(statusModel.referralCode, 'AW-ABC-123');
      expect(statusModel.successfulInvitesCount, 35);
      expect(statusModel.currentPoints, 275);
      expect(statusModel.canCollectCode, isFalse);
      expect(statusModel.milestones['20'], isTrue);
      expect(statusModel.milestones['50'], isFalse);
      expect(statusModel.discountCodes.length, 1);
      expect(statusModel.discountCodes.first.code, 'AW-15-7890');
      expect(statusModel.discountCodes.first.isAvailable, isTrue);

      final collectJson = {
        'success': true,
        'code': 'AW-15-NEW1',
        'expires_at': '2026-12-21T12:00:00Z',
        'remaining_points': 25,
      };

      final collectResult = CollectCodeResult.fromJson(collectJson);
      expect(collectResult.success, isTrue);
      expect(collectResult.code, 'AW-15-NEW1');
      expect(collectResult.remainingPoints, 25);
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

    test('Dynamic messages and progress calculation for all tiers (0, 3, 20, 35, 50)', () {
      // Tier 0: 0 invites
      expect(referralService.successfulInvites, 0);
      expect(referralService.nextMilestoneThreshold, 20);
      expect(referralService.remainingInvitesForNextMilestone, 20);
      expect(referralService.nextMilestoneProgressRatio, 0.0);
      expect(
        referralService.getMilestoneDynamicMessage(isArabic: true),
        '0 استخدموا كودك · باقي 20 دعوة للحصول على 100 نقطة',
      );
      expect(
        referralService.getMilestoneDynamicMessage(isArabic: false),
        '0 used your code · 20 more invites to earn 100 pts',
      );

      // Tier 1 (< 20): e.g. 3 invites
      referralService.addDemoInvites(3);
      expect(referralService.successfulInvites, 3);
      expect(referralService.nextMilestoneThreshold, 20);
      expect(referralService.remainingInvitesForNextMilestone, 17);
      expect(referralService.nextMilestoneProgressRatio, closeTo(3 / 20.0, 0.001));
      expect(
        referralService.getMilestoneDynamicMessage(isArabic: true),
        '3 استخدموا كودك · باقي 17 دعوة للحصول على 100 نقطة',
      );
      expect(
        referralService.getMilestoneDynamicMessage(isArabic: false),
        '3 used your code · 17 more invites to earn 100 pts',
      );

      // Tier 2 (20 <= count < 35): e.g. 20 invites
      referralService.addDemoInvites(17); // now 20
      expect(referralService.successfulInvites, 20);
      expect(referralService.nextMilestoneThreshold, 35);
      expect(referralService.remainingInvitesForNextMilestone, 15);
      expect(referralService.nextMilestoneProgressRatio, closeTo(20 / 35.0, 0.001));
      expect(
        referralService.getMilestoneDynamicMessage(isArabic: true),
        '20 دعوة ناجحة · باقي 15 دعوة للحصول على +175 نقطة',
      );
      expect(
        referralService.getMilestoneDynamicMessage(isArabic: false),
        '20 successful invites · 15 more invites to earn +175 pts',
      );

      // Tier 3 (35 <= count < 50): e.g. 35 invites
      referralService.addDemoInvites(15); // now 35
      expect(referralService.successfulInvites, 35);
      expect(referralService.nextMilestoneThreshold, 50);
      expect(referralService.remainingInvitesForNextMilestone, 15);
      expect(referralService.nextMilestoneProgressRatio, closeTo(35 / 50.0, 0.001));
      expect(
        referralService.getMilestoneDynamicMessage(isArabic: true),
        '35 دعوة ناجحة · باقي 15 دعوة للحصول على +250 نقطة',
      );
      expect(
        referralService.getMilestoneDynamicMessage(isArabic: false),
        '35 successful invites · 15 more invites to earn +250 pts',
      );

      // Tier 4 (count >= 50): e.g. 50 invites
      referralService.addDemoInvites(15); // now 50
      expect(referralService.successfulInvites, 50);
      expect(referralService.hasCompletedAllMilestones, isTrue);
      expect(referralService.remainingInvitesForNextMilestone, 0);
      expect(referralService.nextMilestoneProgressRatio, 1.0);
      expect(
        referralService.getMilestoneDynamicMessage(isArabic: true),
        'أكملت كل العتبات · يمكنك استبدال النقاط عند توفر 500+',
      );
      expect(
        referralService.getMilestoneDynamicMessage(isArabic: false),
        'All invite milestones completed · Redeem when you reach 500+ pts',
      );
    });

    test('Collecting 15% discount code generates AW-15-XXXX code', () async {
      // Add sufficient points to collect
      referralService.addDemoPoints(500);
      expect(referralService.canCollectDiscountCode, isTrue);

      final code = await referralService.collectDiscountCode(userName: 'سارة المنصوري');
      expect(code.code.startsWith('AW-15-'), isTrue);
      expect(code.discountPercent, 15.0);
      expect(code.status, ReferralCodeStatus.available);
      expect(code.isAvailable, isTrue);
      expect(referralService.userCodes.any((c) => c.code == code.code), isTrue);
    });

    test('Clinic code validation and redemption', () async {
      referralService.addDemoPoints(500);
      final newCode = await referralService.collectDiscountCode(userName: 'مريم الشامسي');

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
    testWidgets('ReferralScreen renders unified invite link and points progress', (WidgetTester tester) async {
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
      expect(find.textContaining('https://aestheticway.ae/invite/'), findsOneWidget);
      expect(find.text('نسخ الرابط'), findsWidgets);
      expect(find.text('مستويات النقاط والمكافآت'), findsOneWidget);
    });

    testWidgets('ReferralScreen renders dynamic banner and progress for small count (3 invites)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final service = ReferralService();
      service.resetTestingState();
      service.enableMockMode(testInvites: 3);

      await tester.pumpWidget(
        const MaterialApp(
          home: ReferralScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check dynamic message for 3 invites is rendered
      expect(find.text('3 استخدموا كودك · باقي 17 دعوة للحصول على 100 نقطة'), findsOneWidget);
      // Check 3 invites count and 20 next milestone are displayed
      expect(find.text('3'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('التقدم نحو العتبة التالية (3 / 20 دعوة)'), findsOneWidget);
      expect(find.text('15%'), findsOneWidget);
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

    test('ContactLauncher platform support phone number is +971581989252', () {
      expect(ContactLauncher.platformSupportPhone, '+971581989252');
      expect(ContactLauncher.platformSupportPhoneDisplay, contains('+971 58 198 9252'));
    });

    test('Referral texts emphasize inviting friends to download the app and non-expiring points', () {
      final loc = LocaleService();
      loc.setLanguage(AppLanguage.arabic);
      final referralSubAr = loc.tr('referral_sub');
      expect(referralSubAr.contains('تحميل التطبيق'), isTrue);
      expect(referralSubAr.contains('بدون انتهاء صلاحية'), isTrue);

      final referralRuleAr = loc.tr('referral_rule_note');
      expect(referralRuleAr.contains('تحميل تطبيق Aesthetic Way'), isTrue);
      expect(referralRuleAr.contains('لا تنتهي صلاحيتها'), isTrue);

      loc.setLanguage(AppLanguage.english);
      final referralSubEn = loc.tr('referral_sub');
      expect(referralSubEn.toLowerCase().contains('download the app'), isTrue);
      expect(referralSubEn.toLowerCase().contains('non-expiring'), isTrue);
    });
  });
}
