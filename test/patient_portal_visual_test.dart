import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'support/settle_preview_images.dart';
import 'support/patient_visual_harness.dart';
import 'support/clinic_golden_geometry.dart';
import 'package:aesthetic_way/core/theme/app_theme.dart';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';
import 'package:aesthetic_way/features/articles/data/articles_repository.dart';
import 'package:aesthetic_way/features/articles/models/article_model.dart';
import 'package:aesthetic_way/features/articles/presentation/screens/article_detail_screen.dart';
import 'package:aesthetic_way/features/articles/presentation/screens/articles_screen.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';
import 'package:aesthetic_way/features/auth/data/models/auth_models.dart';
import 'package:aesthetic_way/features/clinics/data/clinics_repository.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinic_profile_screen.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinics_list_screen.dart';
import 'package:aesthetic_way/features/home/data/home_repository.dart';
import 'package:aesthetic_way/features/home/presentation/screens/home_screen.dart';
import 'package:aesthetic_way/features/offers/data/offers_repository.dart';
import 'package:aesthetic_way/features/offers/presentation/screens/offers_screen.dart';
import 'package:aesthetic_way/features/practitioners/data/practitioners_repository.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/practitioners/presentation/screens/practitioner_profile_screen.dart';
import 'package:aesthetic_way/features/practitioners/presentation/screens/practitioners_screen.dart';
import 'package:aesthetic_way/features/products/data/products_repository.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/products/presentation/widgets/product_inquiry_bottom_sheet.dart';
import 'package:aesthetic_way/features/products/presentation/screens/products_screen.dart';
import 'package:aesthetic_way/features/profile/presentation/screens/profile_screen.dart';
import 'package:aesthetic_way/features/referral/presentation/screens/referral_screen.dart';
import 'package:aesthetic_way/features/referral/services/referral_service.dart';
import 'package:aesthetic_way/features/treatments/data/treatments_repository.dart';
import 'package:aesthetic_way/features/treatments/presentation/screens/treatments_screen.dart';
import 'support/patient_fixtures.dart';

const _photo = 'assets/images/aesthetic_way_logo.png';
final _clinic = <String, dynamic>{
  'id': patientClinicId,
  'name_en': 'Fixture Medical Aesthetics & Dermatology Clinic',
  'name_ar': 'عيادة الاختبار للتجميل الطبي والأمراض الجلدية',
  'city': 'Dubai',
  'logo': _photo,
  'description_en': 'Medical information supplied by this fixture clinic.',
  'description_ar': 'معلومات طبية من عيادة اختبار اصطناعية.',
  'subscription_tier': 'featured',
  'google_rating': 4.7,
  'google_reviews_count': 125,
  'google_place_id': 'ChIJ-fixture',
  'branches': [
    for (var i = 1; i <= 2; i++)
      {
        'id': '33333333-3333-4333-8333-33333333333$i',
        'name_en': 'Fixture branch $i',
        'name_ar': 'فرع الاختبار $i',
      },
  ],
};
final _practitioner = <String, dynamic>{
  'id': '44444444-4444-4444-8444-444444444444',
  'clinic': _clinic,
  'type': 'nurse',
  'name_en': 'Fixture Practitioner',
  'name_ar': 'ممارس الاختبار',
  'avatar_url': _photo,
  'speciality_en': 'Dermatology nursing',
  'speciality_ar': 'تمريض الأمراض الجلدية',
  'bio_en': 'Source biography.',
  'bio_ar': 'السيرة الواردة من المصدر.',
};
final _offer = <String, dynamic>{
  'id': patientOfferId,
  'clinic': _clinic,
  'title_en': 'Fixture skin consultation offer',
  'title_ar': 'عرض اختبار للاستشارة الجلدية',
  'offer_price': '750',
  'original_price': '1000',
  'description_en': 'Actual fixture offer information',
  'description_ar': 'معلومات عرض الاختبار',
};
final _product = <String, dynamic>{
  'id': '55555555-5555-4555-8555-555555555555',
  'name_en': 'Fixture cosmetic serum',
  'name_ar': 'سيروم تجميلي للاختبار',
  'brand_name_en': 'Fixture Cosmetic Brand',
  'brand_name_ar': 'علامة تجميل للاختبار',
  'sponsor_company': 'Fixture sponsor',
  'description_en': 'Cosmetic brand showcase.',
  'description_ar': 'عرض علامة تجميل.',
  'image_url': _photo,
};
final _article = <String, dynamic>{
  'id': '66666666-6666-4666-8666-666666666666',
  'title_en': 'Understanding medical skin consultations',
  'title_ar': 'التعرف على الاستشارات الطبية للبشرة',
  'content_en':
      'This synthetic article demonstrates readable medical editorial content. It contains no real patient information.',
  'content_ar':
      'مقال اصطناعي يوضح عرض المحتوى الطبي المقروء دون أي بيانات لمرضى حقيقيين.',
  'clinic': _clinic,
  'author_practitioner': _practitioner,
  'published_at': '2026-10-20T12:00:00Z',
};

class _Client implements ApiClient {
  bool fail = false, empty = false;
  Completer<Map<String, dynamic>>? pending;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (pending != null) {
      return Response<T>(
        data: await pending!.future as T,
        requestOptions: RequestOptions(path: path),
      );
    }
    if (fail) throw const ApiException(message: 'Fixture network failure');
    final Object body;
    if (path == 'home/feed/') {
      body = {
        'featured_ads': [
          {'id': 'ad', 'clinic': _clinic, 'subscription_tier': 'featured'},
        ],
        'nearby_clinics': [_clinic],
        'active_offers': [_offer],
      };
    } else if (path == 'auth/me/') {
      body = {
        'id': 'fixture-patient',
        'full_name': 'Fixture Patient',
        'phone': '+971501234567',
        'role': 'patient',
        'is_verified': false,
      };
    } else if (path == 'clinics/$patientClinicId/') {
      body = _clinic;
    } else if (path.startsWith('practitioners/') && path != 'practitioners/') {
      body = _practitioner;
    } else {
      body = {
        'count': empty ? 0 : 1,
        'next': null,
        'results': empty
            ? []
            : switch (path) {
                'clinics/' => [_clinic],
                'practitioners/' => [_practitioner],
                'offers/' => [_offer],
                'products/' => [_product],
                'articles/' => [_article],
                _ => [],
              },
      };
    }
    return Response<T>(
      data: body as T,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }
}

class _Auth implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<UserModel> getMe() async => UserModel.fromJson({
    'id': 'fixture',
    'full_name': 'Fixture Patient',
    'phone': '+971501234567',
    'role': 'patient',
    'is_verified': false,
  });
}

Widget _app(
  Widget screen,
  bool dark,
  bool arabic, {
  double scale = 1.6,
  bool canonical = false,
}) {
  final theme = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
  return MaterialApp(
    theme: canonical
        ? patientVisualTheme(dark: dark)
        : theme.copyWith(
            platform: TargetPlatform.android,
            visualDensity: VisualDensity.standard,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            textTheme: theme.textTheme.apply(fontFamily: 'PatientPreview'),
            appBarTheme: theme.appBarTheme.copyWith(
              titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
                fontFamily: 'PatientPreview',
              ),
            ),
          ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: Directionality(
        textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
    ),
    home: screen,
  );
}

void main() {
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await loadPatientVisualFonts();
  });
  tearDown(() {
    ReferralService().resetTestingState();
  });
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    for (final dark in [false, true]) {
      for (final arabic in [false, true]) {
        testWidgets(
          'Patient screens ${width.toInt()}dp ${dark ? 'dark' : 'light'} ${arabic ? 'ar' : 'en'} at 160% text',
          (tester) async {
            await tester.binding.setSurfaceSize(Size(width, 1000));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            unawaited(
              LocaleService().setLanguage(
                arabic ? AppLanguage.arabic : AppLanguage.english,
              ),
            );
            AuthState().login(name: 'Fixture Patient', phone: '+971501234567');
            ReferralService().enableMockMode(
              testStatus: patientReferralStatus(),
            );
            final client = _Client();
            final clinics = ClinicsRepository(apiClient: client),
                practitioners = PractitionersRepository(apiClient: client);
            final treatments = TreatmentsRepository(apiClient: client),
                offers = OffersRepository(apiClient: client);
            final screens = <Widget>[
              HomeScreen(repository: HomeRepository(apiClient: client)),
              ClinicsListScreen(repository: clinics),
              ProductsScreen(repository: ProductsRepository(apiClient: client)),
              OffersScreen(repository: offers, clinicsRepository: clinics),
              PractitionersScreen(repository: practitioners),
              PractitionerProfileScreen(
                practitioner: PractitionerModel.fromJson(_practitioner),
                practitionersRepository: practitioners,
                clinicsRepository: clinics,
              ),
              TreatmentsScreen(repository: treatments),
              ArticlesScreen(repository: ArticlesRepository(apiClient: client)),
              ArticleDetailScreen(
                article: ArticleModel.fromJson(_article),
                clinicsRepository: clinics,
                practitionersRepository: practitioners,
              ),
              ClinicProfileScreen(
                clinic: ClinicModel.fromJson(_clinic),
                clinicsRepository: clinics,
                practitionersRepository: practitioners,
                treatmentsRepository: treatments,
                offersRepository: offers,
              ),
              AppointmentRequestScreen(
                clinic: ClinicModel.fromJson(_clinic),
                treatmentsRepository: treatments,
                practitionersRepository: practitioners,
              ),
              ReferralScreen(),
              ProfileScreen(
                onNavigateToRequests: () {},
                authRepository: _Auth(),
              ),
            ];
            for (final screen in screens) {
              await tester.pumpWidget(_app(screen, dark, arabic));
              await tester.pumpAndSettle();
              final error = tester.takeException();
              if (error is FlutterError) {
                debugPrint(
                  error.diagnostics.map((n) => n.toStringDeep()).join('\n'),
                );
              }
              expect(error, isNull, reason: '${screen.runtimeType} initial');
              final scroll = find.byType(Scrollable).first;
              await tester.drag(scroll, const Offset(0, -1800));
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: '${screen.runtimeType} scrolled',
              );
              await tester.pumpWidget(const SizedBox.shrink());
            }
          },
        );
      }
    }
  }
  for (final dark in [false, true]) {
    for (final arabic in [false, true]) {
      for (final host in [TargetPlatform.android, TargetPlatform.windows]) {
        testWidgets(
          'Clinic profile golden ${dark ? 'dark' : 'light'} ${arabic ? 'ar' : 'en'} host ${host.name}',
          (tester) async {
            tester.view.devicePixelRatio = 3;
            tester.view.physicalSize = const Size(1170, 2532);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPhysicalSize);
            await tester.binding.setSurfaceSize(const Size(390, 844));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            unawaited(
              LocaleService().setLanguage(
                arabic ? AppLanguage.arabic : AppLanguage.english,
              ),
            );
            final client = _Client();
            final screen = ClinicProfileScreen(
              clinic: ClinicModel.fromJson(_clinic),
              clinicsRepository: ClinicsRepository(apiClient: client),
              practitionersRepository: PractitionersRepository(
                apiClient: client,
              ),
              treatmentsRepository: TreatmentsRepository(apiClient: client),
              offersRepository: OffersRepository(apiClient: client),
            );
            await tester.pumpWidget(
              _app(screen, dark, arabic, scale: 1, canonical: true),
            );
            await tester.pumpAndSettle();
            await settlePreviewImages(tester);
            expectClinicGoldenGeometry(
              tester,
              'patient_clinic_${dark ? 'dark' : 'light'}_${arabic ? 'ar' : 'en'}',
            );
            await expectLater(
              find.byType(Scaffold),
              matchesGoldenFile(
                const String.fromEnvironment(
                      'PATIENT_GOLDEN_CAPTURE_DIR',
                    ).isEmpty
                    ? Uri.parse(
                        'goldens/patient_placeholders_v3/${Platform.operatingSystem}/patient_clinic_${dark ? 'dark' : 'light'}_${arabic ? 'ar' : 'en'}.png',
                      )
                    : Directory(
                        const String.fromEnvironment(
                          'PATIENT_GOLDEN_CAPTURE_DIR',
                        ),
                      ).uri.resolve(
                        'patient_clinic_${dark ? 'dark' : 'light'}_${arabic ? 'ar' : 'en'}.png',
                      ),
              ),
            );
            await tester.tap(find.text(LocaleService().tr('tab_staff')));
            await tester.pumpAndSettle();
            expect(
              find.text(arabic ? 'ممارس الاختبار' : 'Fixture Practitioner'),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            await tester.ensureVisible(
              find.text(LocaleService().tr('tab_offers')),
            );
            await tester.tap(find.text(LocaleService().tr('tab_offers')));
            await tester.pumpAndSettle();
            expect(
              find.text(
                arabic
                    ? 'عرض اختبار للاستشارة الجلدية'
                    : 'Fixture skin consultation offer',
              ),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          },
          variant: TargetPlatformVariant({host}),
        );
      }
    }
  }
  testWidgets(
    'Practitioner lookup failures cannot fabricate a clinic; retry restores the genuine destination',
    (tester) async {
      unawaited(LocaleService().setLanguage(AppLanguage.english));
      final client = _Client()..fail = true;
      await tester.pumpWidget(
        _app(
          PractitionerProfileScreen(
            practitioner: PractitionerModel.fromJson(_practitioner),
            practitionersRepository: PractitionersRepository(apiClient: client),
            clinicsRepository: ClinicsRepository(apiClient: client),
          ),
          false,
          false,
          scale: 1,
        ),
      );
      await tester.pumpAndSettle();
      final retry = find.text('Clinic details unavailable. Try again');
      expect(retry, findsOneWidget);
      final request = find.text(LocaleService().tr('request_with_doctor'));
      final button = find.ancestor(
        of: request,
        matching: find.byType(FilledButton),
      );
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(find.textContaining('+971500000000'), findsNothing);
      client.fail = false;
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
      expect(find.text('Clinic details unavailable. Try again'), findsNothing);
    },
  );
  testWidgets(
    'Clinic staff API failure stays an error and retries to actual records',
    (tester) async {
      unawaited(LocaleService().setLanguage(AppLanguage.english));
      final client = _Client()..fail = true;
      await tester.pumpWidget(
        _app(
          ClinicProfileScreen(
            clinic: ClinicModel.fromJson(_clinic),
            clinicsRepository: ClinicsRepository(apiClient: client),
            practitionersRepository: PractitionersRepository(apiClient: client),
          ),
          false,
          false,
          scale: 1,
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(LocaleService().tr('tab_staff')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(LocaleService().tr('tab_staff')));
      await tester.pumpAndSettle();
      expect(find.text('No medical staff published'), findsNothing);
      expect(find.text('Could not load. Try again'), findsOneWidget);
      client.fail = false;
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Could not load. Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Fixture Practitioner'), findsOneWidget);
      expect(find.text('Could not load. Try again'), findsNothing);
    },
  );
  testWidgets(
    'Independent product inquiry has no price and requires explicit consent',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      unawaited(LocaleService().setLanguage(AppLanguage.english));
      AuthState().login(name: 'Fixture Patient', phone: '+971501234567');
      final leads = FixtureLeadsRepository();
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: ProductInquiryBottomSheet(
              product: ProductModel.fromJson({..._product, 'price': '999.00'}),
              leadsRepository: leads,
            ),
          ),
          false,
          false,
          scale: 1,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('999'), findsNothing);
      expect(find.textContaining('AED'), findsNothing);
      expect(find.byIcon(Icons.calendar_month_outlined), findsNothing);
      final submit = find.text(LocaleService().tr('submit_lead_btn'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(leads.calls, 0);
      expect(
        find.text(
          'Please accept consent to share your contact details for this inquiry',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(leads.calls, 1);
      expect(leads.lastPayload!['product'], _product['id']);
      expect(leads.lastPayload!.containsKey('clinic'), isFalse);
      expect(find.text('تم إرسال طلبك وستتواصل العيادة معك'), findsOneWidget);
    },
  );

  testWidgets(
    'Directory loading, error, retry and genuine empty results remain distinct',
    (tester) async {
      unawaited(LocaleService().setLanguage(AppLanguage.english));
      final client = _Client()..pending = Completer<Map<String, dynamic>>();
      await tester.pumpWidget(
        _app(
          ClinicsListScreen(repository: ClinicsRepository(apiClient: client)),
          false,
          false,
          scale: 1,
        ),
      );
      await tester.pump();
      expect(find.text('No clinics available'), findsNothing);
      client.pending!.completeError(
        const ApiException(message: 'Fixture network failure'),
      );
      client.pending = null;
      client.fail = true;
      await tester.pumpAndSettle();
      expect(find.text('Unable to load data'), findsOneWidget);
      expect(find.text('No clinics available'), findsNothing);
      client.fail = false;
      client.empty = true;
      await tester.tap(find.text('Try Again'));
      await tester.pump();
      expect(find.text('Unable to load data'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      expect(find.text('No clinics available'), findsOneWidget);
      expect(find.text('Unable to load data'), findsNothing);
    },
  );
}
