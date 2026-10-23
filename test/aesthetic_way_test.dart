import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aesthetic_way/features/onboarding/services/onboarding_service.dart';
import 'package:aesthetic_way/core/theme/app_theme.dart';
import 'package:aesthetic_way/core/widgets/tier_badge.dart';
import 'package:aesthetic_way/core/widgets/practitioner_badge.dart';
import 'package:aesthetic_way/core/widgets/app_brand_logo.dart';
import 'package:aesthetic_way/core/theme/theme_service.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_success_screen.dart';
import 'package:aesthetic_way/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/login_screen.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/register_screen.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/otp_screen.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:aesthetic_way/features/navigation/main_nav_screen.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:aesthetic_way/data/mock_data.dart';
import 'package:aesthetic_way/main.dart';

void main() {
  group('AESTHETIC WAY - Core Design System & Business Logic Tests', () {
    test('Subscription Tier Ads Priority', () {
      final mockData = MockDataService();
      final topAds = mockData.topCarouselAds;

      // Ensure VIP Platinum clinics appear first before Featured
      expect(topAds.isNotEmpty, isTrue);
      expect(
        topAds.first.subscriptionTier,
        equals(SubscriptionTier.vipPlatinum),
      );
      expect(
        topAds.any((c) => c.subscriptionTier == SubscriptionTier.basic),
        isFalse,
      );
    });

    test('Practitioner Classification and Licensing Authorities', () {
      final mockData = MockDataService();
      final practitioners = mockData.practitioners;

      // Verify all 3 required practitioner types exist
      expect(
        practitioners.any((p) => p.type == PractitionerType.doctor),
        isTrue,
      );
      expect(
        practitioners.any((p) => p.type == PractitionerType.nurse),
        isTrue,
      );
      expect(
        practitioners.any(
          (p) => p.type == PractitionerType.licensedProfessional,
        ),
        isTrue,
      );
    });

    test('ThemeService manages Light default, Dark, and System modes', () {
      final themeService = ThemeService();
      expect(themeService.themeMode, equals(ThemeMode.light));

      themeService.setThemeMode(ThemeMode.dark);
      expect(themeService.isDarkMode, isTrue);
      expect(themeService.isLightMode, isFalse);

      themeService.setThemeMode(ThemeMode.light);
      expect(themeService.isLightMode, isTrue);
      expect(themeService.isDarkMode, isFalse);

      themeService.setThemeMode(ThemeMode.system);
      expect(themeService.themeMode, equals(ThemeMode.system));

      // Reset to default light mode
      themeService.setThemeMode(ThemeMode.light);
    });

    testWidgets('TierBadge renders VIP and Featured properly', (
      WidgetTester tester,
    ) async {
      LocaleService().setLanguage(AppLanguage.arabic);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TierBadge(tier: SubscriptionTier.vipPlatinum),
                TierBadge(tier: SubscriptionTier.featured),
              ],
            ),
          ),
        ),
      );

      expect(find.text('بلاتيني VIP'), findsOneWidget);
      expect(find.text('إعلان مميز'), findsOneWidget);
    });

    testWidgets('PractitionerBadge renders distinct roles', (
      WidgetTester tester,
    ) async {
      LocaleService().setLanguage(AppLanguage.arabic);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PractitionerBadge(type: PractitionerType.doctor),
                PractitionerBadge(type: PractitionerType.nurse),
                PractitionerBadge(type: PractitionerType.licensedProfessional),
              ],
            ),
          ),
        ),
      );

      expect(find.text('طبيب'), findsOneWidget);
      expect(find.text('ممرض'), findsOneWidget);
      expect(find.text('أخصائي'), findsOneWidget);
    });

    testWidgets(
      'AppointmentRequestScreen renders cleanly in Dark and Light modes without raw keys',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final mockData = MockDataService();
        final clinic = mockData.clinics.first;
        final loc = LocaleService();
        loc.setLanguage(AppLanguage.arabic);

        // Test in Dark Theme
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: AppointmentRequestScreen(clinic: clinic),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        // Assert that raw translation keys DO NOT appear on screen
        expect(find.text('time_morning'), findsNothing);
        expect(find.text('time_afternoon'), findsNothing);
        expect(find.text('time_evening'), findsNothing);
        expect(find.text('contact_info_title'), findsNothing);
        expect(find.text('phone_uae'), findsNothing);
        expect(find.text('notes_opt'), findsNothing);

        // Assert that translated Arabic strings DO appear
        expect(find.text('طلب موعد استشارة'), findsOneWidget);
        expect(find.text('بيانات التواصل / المريض'), findsOneWidget);
        expect(find.text('رقم الهاتف'), findsOneWidget);
        expect(find.text('ملاحظات إضافية (اختياري)'), findsOneWidget);

        // Test in Light Theme
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            home: AppointmentRequestScreen(clinic: clinic),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('طلب موعد استشارة'), findsOneWidget);
        expect(find.text('بيانات التواصل / المريض'), findsOneWidget);
      },
    );

    testWidgets('Strict Success Screen Copy Compliance', (
      WidgetTester tester,
    ) async {
      final mockData = MockDataService();
      final clinic = mockData.clinics.first;
      final request = AppointmentRequestModel(
        id: '1',
        referenceCode: '#REQ-98241',
        clinicId: clinic.id,
        clinicNameAr: clinic.nameAr,
        branchNameAr: clinic.areaAr,
        serviceNameAr: 'حقن البوتوكس',
        preferredDate: DateTime(2026, 8, 25),
        preferredTimeWindow: PreferredTimeWindow.evening,
        patientFullName: 'مريم أحمد',
        patientPhone: '+971 50 123 4567',
        consentAccepted: true,
        status: AppointmentLeadStatus.sent,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AppointmentSuccessScreen(request: request, clinic: clinic),
        ),
      );

      // Verify STRICT MANDATORY text
      expect(find.text('تم إرسال طلبك وستتواصل العيادة معك'), findsOneWidget);
      expect(find.text('تم إرسال طلبك بنجاح!'), findsOneWidget);
      expect(
        find.textContaining('سيقوم فريق الاستقبال في العيادة بالتواصل معك'),
        findsOneWidget,
      );

      // Verify NEVER use booking confirmed
      expect(find.text('تم تأكيد الحجز'), findsNothing);
      expect(find.text('حجز مؤكد'), findsNothing);
      expect(find.text('دفع'), findsNothing);
      expect(find.text('سلة'), findsNothing);
    });

    // ==========================================
    // PHASE 2: ONBOARDING & AUTHENTICATION TESTS
    // ==========================================
    testWidgets(
      'OnboardingScreen renders 3 luxury slides and controls in Dark/Light',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final loc = LocaleService();
        loc.setLanguage(AppLanguage.arabic);

        await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
        await tester.pump(const Duration(milliseconds: 300));

        // Check Slide 1 content
        expect(find.text('عيادات التجميل والجلدية'), findsOneWidget);
        expect(find.text('تخطي'), findsOneWidget);
        expect(find.text('التالي'), findsOneWidget);
        expect(find.text('المتابعة كزائر'), findsNothing);

        // Tap Next to go to Slide 2
        await tester.tap(find.text('التالي'));
        await tester.pumpAndSettle();

        expect(find.text('استعراض العروض والباقات'), findsOneWidget);

        // Tap Next to go to Slide 3
        await tester.tap(find.text('التالي'));
        await tester.pumpAndSettle();

        expect(find.text('طلب تواصل واستشارة'), findsOneWidget);
        expect(find.text('ابدأ الآن'), findsOneWidget);
      },
    );

    testWidgets(
      'LoginScreen renders fields, links and confirms no guest bypass option',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final loc = LocaleService();
        loc.setLanguage(AppLanguage.arabic);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const LoginScreen(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('تسجيل الدخول'), findsWidgets);
        expect(find.text('رقم الهاتف'), findsWidgets);
        expect(find.text('البريد الإلكتروني'), findsWidgets);
        expect(find.text('كلمة المرور'), findsOneWidget);
        expect(find.text('نسيت كلمة المرور؟'), findsOneWidget);
        expect(find.text('إنشاء حساب جديد'), findsOneWidget);
        expect(find.text('المتابعة كزائر'), findsNothing);
        expect(find.byIcon(Icons.close_rounded), findsNothing);
      },
    );

    testWidgets('RegisterScreen renders all input fields and terms checkbox', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final loc = LocaleService();
      loc.setLanguage(AppLanguage.arabic);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const RegisterScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('إنشاء حساب جديد'), findsWidgets);
      expect(find.text('الاسم الكامل'), findsOneWidget);
      expect(find.text('رقم الهاتف'), findsOneWidget);
      expect(find.text('البريد الإلكتروني'), findsOneWidget);
      expect(find.text('كلمة المرور'), findsOneWidget);
      expect(find.text('تأكيد كلمة المرور'), findsOneWidget);
      expect(find.text('تسجيل الدخول'), findsOneWidget);
    });

    test(
      'AuthRepository.normalizePhone formats UAE numbers properly to E.164',
      () {
        expect(
          AuthRepository.normalizePhone('501234567'),
          equals('+971501234567'),
        );
        expect(
          AuthRepository.normalizePhone('0501234567'),
          equals('+971501234567'),
        );
        expect(
          AuthRepository.normalizePhone('50 123 4567'),
          equals('+971501234567'),
        );
        expect(
          AuthRepository.normalizePhone('050 123 4567'),
          equals('+971501234567'),
        );
        expect(
          AuthRepository.normalizePhone('+971501234567'),
          equals('+971501234567'),
        );
        expect(
          AuthRepository.normalizePhone('+971 50 123 4567'),
          equals('+971501234567'),
        );
        expect(
          AuthRepository.normalizePhone('971501234567'),
          equals('+971501234567'),
        );
        expect(
          AuthRepository.normalizePhone('00971501234567'),
          equals('+971501234567'),
        );
      },
    );

    test(
      'ApiException parses backend field errors and provides localized messages',
      () {
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/api/v1/auth/register/'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/auth/register/'),
            statusCode: 400,
            data: {
              'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'One or more fields failed validation.',
                'fields': {
                  'password': ['This password is too common.'],
                  'phone': [
                    'An account with this phone number already exists.',
                  ],
                },
              },
            },
          ),
        );

        final apiException = ApiException.fromDioError(dioException);
        expect(apiException.fieldErrors, isNotNull);
        expect(apiException.fieldErrors!.containsKey('password'), isTrue);
        expect(apiException.fieldErrors!.containsKey('phone'), isTrue);
        expect(apiException.message, contains('كلمة المرور'));
        expect(apiException.message, contains('رقم الهاتف'));
        expect(
          apiException.getFieldError('password'),
          contains('شائعة وسهلة التخمين'),
        );
        expect(apiException.getFieldError('phone'), contains('مسجل بالفعل'));
      },
    );

    testWidgets('OtpScreen renders 6 digit boxes, countdown, and dev hint', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final loc = LocaleService();
      loc.setLanguage(AppLanguage.arabic);

      await tester.pumpWidget(
        const MaterialApp(
          home: OtpScreen(
            purpose: OtpPurpose.registration,
            targetContact: '+971 50 123 4567',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('رمز التحقق (OTP)'), findsOneWidget);
      expect(find.text('+971 50 123 4567'), findsOneWidget);
      expect(find.text('تأكيد الرمز والمتابعة'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(6));
      expect(find.textContaining('Terminal'), findsOneWidget);
    });

    testWidgets('ForgotPasswordScreen and ResetPasswordScreen render cleanly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final loc = LocaleService();
      loc.setLanguage(AppLanguage.arabic);

      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('استعادة كلمة المرور'), findsOneWidget);
      expect(find.text('إرسال رمز الاستعادة'), findsOneWidget);
      expect(find.text('العودة لتسجيل الدخول'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: ResetPasswordScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('تعيين كلمة المرور الجديدة'), findsOneWidget);
      expect(find.text('كلمة المرور الجديدة'), findsOneWidget);
      expect(find.text('تأكيد كلمة المرور الجديدة'), findsOneWidget);
      expect(find.text('حفظ كلمة المرور والدخول'), findsOneWidget);
    });

    testWidgets(
      'App Launches and renders main navigation tabs and official logo',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const AestheticWayApp(homeScreen: MainNavScreen()),
        );
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(AppBrandLogo), findsWidgets);
        expect(find.text('الرئيسية'), findsOneWidget);
        expect(find.text('العيادات'), findsWidgets);
        expect(find.text('المنتجات'), findsWidgets);
        expect(find.text('العروض'), findsWidgets);
        expect(find.text('حسابي'), findsOneWidget);
      },
    );

    test('LocaleService toggles Arabic and English correctly', () {
      final loc = LocaleService();
      loc.setLanguage(AppLanguage.arabic);
      expect(loc.isArabic, isTrue);
      expect(loc.locale.languageCode, equals('ar'));
      expect(loc.textDirection, equals(TextDirection.rtl));
      expect(loc.tr('nav_home'), equals('الرئيسية'));

      loc.toggleLanguage();
      expect(loc.isArabic, isFalse);
      expect(loc.locale.languageCode, equals('en'));
      expect(loc.textDirection, equals(TextDirection.ltr));
      expect(loc.tr('nav_home'), equals('Home'));

      // Reset back to Arabic
      loc.setLanguage(AppLanguage.arabic);
    });

    testWidgets('SplashScreen auto-transitions smoothly to Onboarding/Home', (
      WidgetTester tester,
    ) async {
      // Explicitly model empty device storage instead of relying on earlier
      // tests' singleton state or an unavailable secure-storage platform.
      FlutterSecureStorage.setMockInitialValues({});
      await OnboardingService().init();
      await tester.pumpWidget(const AestheticWayApp());
      expect(find.byType(AppBrandLogo), findsOneWidget);

      // Advance time past splash duration (1600ms) + fade transition (400ms)
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();

      // Empty storage must show introduction before authentication.
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });
  });
}
