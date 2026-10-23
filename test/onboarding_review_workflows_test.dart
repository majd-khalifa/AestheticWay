import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/theme/theme_service.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/onboarding/services/onboarding_service.dart';
import 'package:aesthetic_way/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/login_screen.dart';
import 'package:aesthetic_way/features/splash/presentation/screens/splash_screen.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';
import 'package:aesthetic_way/features/admin/services/admin_review_service.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';
import 'package:aesthetic_way/features/admin/data/admin_repository.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_main_nav_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_main_nav_screen.dart';
import 'package:aesthetic_way/features/navigation/main_nav_screen.dart';
import 'package:aesthetic_way/features/treatments/data/category_request_repository.dart';
import 'package:aesthetic_way/features/treatments/models/category_request_model.dart';
import 'package:aesthetic_way/main.dart';
import 'support/patient_visual_harness.dart';
import 'support/settle_preview_images.dart';
import 'clinic_media_contract_test.dart' show Gallery, Profile;
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/data/models/clinic_setup_checklist_model.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/widgets/clinic_setup_checklist_card.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_media_screen.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';

const id = '77777777-7777-4777-8777-777777777777';
const proposalId = '88888888-8888-4888-8888-888888888888';
Map<String, dynamic> clinic({String status = 'submitted'}) => {
  'id': id,
  'name_en': 'Local QA Clinic',
  'name_ar': 'عيادة اختبار محلي',
  'status': status == 'approved' ? 'active' : 'pending',
  'setup_status': status,
  'subscription_tier': 'vip',
  'description_en': 'Disposable profile fixture.',
  'description_ar': 'ملف اختبار محلي.',
  'phone': '',
  'email': '',
  'logo': '',
  'cover_image': '',
  'branches': [],
  'practitioners_count': 1,
  'treatments_count': 1,
  'submitted_for_review_at': '2026-10-23T10:00:00Z',
};
ResponseBody body(Object data, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);
Map<String, dynamic> page(List<Object> rows, {int? count, String? next}) => {
  'count': count ?? rows.length,
  'next': next,
  'results': rows,
};

class Adapter implements HttpClientAdapter {
  Adapter(this.reply);
  final FutureOr<ResponseBody> Function(RequestOptions) reply;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(o);
    return await reply(o);
  }

  @override
  void close({bool force = false}) {}
}

class Requests implements CategoryRequestRepository {
  int calls = 0;
  Completer<List<CategoryRequestModel>>? pending;
  List<CategoryRequestModel> rows = PageItems([], hasMore: false, total: 0);
  @override
  Future<List<CategoryRequestModel>> list({
    bool admin = false,
    int page = 1,
    String? status,
  }) async {
    expect(admin, isTrue);
    expect(status, 'pending');
    calls++;
    return pending?.future ?? rows;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FailingStorage implements FlutterSecureStorage {
  @override
  dynamic noSuchMethod(Invocation i) {
    if (i.memberName == #read) return Future<String?>.value(null);
    return Future<void>.error(StateError('Synthetic storage write failure'));
  }
}

class DeferredStorage implements FlutterSecureStorage {
  final entered = Completer<void>(), release = Completer<void>();
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #write) {
      if (!entered.isCompleted) entered.complete();
      return release.future;
    }
    return Future<String?>.value(null);
  }
}

Future<void> render(
  WidgetTester tester,
  Widget screen, {
  bool dark = false,
  bool ar = false,
  double width = 430,
}) async {
  await LocaleService().setLanguage(
    ar ? AppLanguage.arabic : AppLanguage.english,
  );
  await tester.binding.setSurfaceSize(Size(width, 1000));
  await tester.pumpWidget(
    MaterialApp(
      theme: patientVisualTheme(dark: dark),
      builder: (_, child) => Directionality(
        textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
        child: RepaintBoundary(
          key: const ValueKey('review-capture'),
          child: child!,
        ),
      ),
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  const output = String.fromEnvironment('ONBOARDING_REVIEW_CAPTURE_DIR');
  if (output.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('review-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$output/$name.png');
    await f.parent.create(recursive: true);
    await f.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  final api = ApiClient();
  late HttpClientAdapter original;
  late Adapter adapter;
  void use(FutureOr<ResponseBody> Function(RequestOptions) reply) {
    adapter = Adapter(reply);
    api.dio.httpClientAdapter = adapter;
  }

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    AuthState().logout();
    AdminPortalService().resetTestingState();
    await OnboardingService().init();
    original = api.dio.httpClientAdapter;
    api.updateBaseUrl('https://fixture.invalid/api/v1/');
    use((_) => body(page([])));
    await LocaleService().setLanguage(AppLanguage.english);
  });
  tearDown(() async {
    api.dio.httpClientAdapter = original;
    await TokenStorage().clear();
    AuthState().logout();
    api.updateBaseUrl(ApiConfig.defaultProductionBaseUrl);
    ApiConfig.resetBaseUrl();
  });
  test(
    'empty device store defaults English/Light and introduction; completion survives a cold service',
    () async {
      const storage = FlutterSecureStorage();
      final onboarding = OnboardingService.withStorage(storage);
      final locale = LocaleService.withStorage(storage);
      final theme = ThemeService.withStorage(storage);
      await Future.wait([onboarding.init(), locale.init(), theme.init()]);
      expect(onboarding.hasSeenOnboarding, isFalse);
      expect(locale.currentLanguage, AppLanguage.english);
      expect(theme.themeMode, ThemeMode.light);
      await onboarding.completeOnboarding();
      final cold = OnboardingService.withStorage(storage);
      await cold.init();
      expect(cold.hasSeenOnboarding, isTrue);
      expect(await storage.read(key: OnboardingService.storageKey), 'true');
      onboarding.dispose();
      cold.dispose();
      locale.dispose();
      theme.dispose();
    },
  );
  test(
    'logout and account credential deletion preserve onboarding, language and theme; empty storage resets defaults',
    () async {
      const storage = FlutterSecureStorage();
      final onboarding = OnboardingService.withStorage(storage);
      final locale = LocaleService.withStorage(storage);
      final theme = ThemeService.withStorage(storage);
      await onboarding.completeOnboarding();
      await locale.setLanguage(AppLanguage.arabic);
      await theme.setThemeMode(ThemeMode.dark);
      await TokenStorage().saveTokens(accessToken: 'qa', refreshToken: 'qa');
      await TokenStorage().clear();
      AuthState().logout();
      final cold = OnboardingService.withStorage(storage);
      await cold.init();
      expect(cold.hasSeenOnboarding, isTrue);
      expect(await storage.read(key: LocaleService.storageKey), 'ar');
      expect(await storage.read(key: ThemeService.storageKey), 'dark');
      await storage.deleteAll();
      final fresh = OnboardingService.withStorage(storage);
      await fresh.init();
      expect(fresh.hasSeenOnboarding, isFalse);
      onboarding.dispose();
      cold.dispose();
      fresh.dispose();
      locale.dispose();
      theme.dispose();
    },
  );
  test(
    'failed onboarding write is reported and replay cannot reset durable completion',
    () async {
      final failed = OnboardingService.withStorage(FailingStorage());
      await failed.completeOnboarding();
      expect(failed.saveFailed, isTrue);
      final service = OnboardingService.withStorage(
        const FlutterSecureStorage(),
      );
      await service.completeOnboarding();
      await service.completeOnboarding();
      final cold = OnboardingService.withStorage(const FlutterSecureStorage());
      await cold.init();
      expect(cold.hasSeenOnboarding, isTrue);
      failed.dispose();
      service.dispose();
      cold.dispose();
    },
  );
  testWidgets(
    'skip persists introduction and cold splash opens Login without slides',
    (tester) async {
      await render(tester, const OnboardingScreen());
      await settlePreviewImages(tester);
      await capture(tester, 'onboarding_fresh_light_en');
      await tester.tap(find.byKey(const ValueKey('skip-introduction')));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        await const FlutterSecureStorage().read(
          key: OnboardingService.storageKey,
        ),
        'true',
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  for (final role in ['patient', 'clinic_admin', 'super_admin']) {
    testWidgets(
      '$role verified startup bypasses missing introduction flag; root logout goes straight to Login',
      (tester) async {
        AuthState().login(name: 'QA', phone: 'role-$role', role: role);
        final auth = AuthRepository(apiClient: api);
        use(
          (o) => o.path == ApiConfig.me
              ? body({
                  'id': id,
                  'full_name': 'QA',
                  'phone': 'role-$role',
                  'role': role,
                  'is_verified': true,
                })
              : body(page([])),
        );
        await render(tester, SplashScreen(authRepository: auth));
        await tester.pump(const Duration(milliseconds: 1700));
        await tester.pumpAndSettle();
        expect(find.byType(OnboardingScreen), findsNothing);
        expect(
          find.byType(
            role == 'patient'
                ? MainNavScreen
                : role == 'clinic_admin'
                ? ClinicMainNavScreen
                : AdminMainNavScreen,
          ),
          findsOneWidget,
        );
        expect(
          await const FlutterSecureStorage().read(
            key: OnboardingService.storageKey,
          ),
          'true',
        );
        await tester.pumpWidget(
          const AestheticWayApp(
            homeScreen: Scaffold(body: Text('private snapshot')),
          ),
        );
        await tester.pump();
        AuthState().logout();
        await tester.pumpWidget(const AestheticWayApp());
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(OnboardingScreen), findsNothing);
        expect(find.text('private snapshot'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
      },
    );
  }
  testWidgets(
    'failed/revoked session with missing introduction marker reaches Login and never sticks on splash',
    (tester) async {
      AuthState().login(name: 'QA', phone: 'qa', role: 'patient');
      use(
        (o) => body({
          'error': {'code': 'PERMISSION_DENIED', 'message': 'revoked'},
        }, 403),
      );
      await render(
        tester,
        SplashScreen(authRepository: AuthRepository(apiClient: api)),
      );
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(OnboardingScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  test(
    'pending count uses only server total, coalesces flights and rejects old-session completion',
    () async {
      AuthState().login(name: 'QA', phone: 'qa', role: 'super_admin');
      final repo = Requests()..pending = Completer();
      final counter = AdminReviewService.withRepository(repo);
      final one = counter.refresh(), two = counter.refresh();
      expect(identical(one, two), isTrue);
      expect(repo.calls, 1);
      repo.pending!.complete(PageItems([], hasMore: true, total: 47));
      await one;
      expect(counter.pendingCategories, 47);
      repo.pending = Completer();
      final late = counter.refresh();
      AuthState().logout();
      repo.pending!.complete(PageItems([], hasMore: false, total: 99));
      await late;
      expect(counter.pendingCategories, isNull);
      counter.dispose();
    },
  );
  test(
    'missing count metadata and denied roles never fabricate a zero',
    () async {
      AuthState().login(name: 'QA', phone: 'qa', role: 'super_admin');
      final repo = Requests()..rows = [];
      final counter = AdminReviewService.withRepository(repo);
      await counter.refresh();
      expect(counter.pendingCategories, isNull);
      AuthState().login(name: 'QA', phone: 'patient', role: 'patient');
      await counter.refresh();
      expect(repo.calls, 1);
      expect(counter.pendingCategories, isNull);
      counter.dispose();
    },
  );
  test(
    'setup verify sends exact contract, validates acknowledgment and refreshes complete profile',
    () async {
      AuthState().login(name: 'QA', phone: 'qa', role: 'super_admin');
      var approved = false;
      use((o) {
        if (o.method == 'POST') {
          approved = true;
          return body({
            'status': 'success',
            'clinic_id': id,
            'setup_status': 'approved',
            'new_status': 'active',
          });
        }
        return body(clinic(status: approved ? 'approved' : 'submitted'));
      });
      final result = await AdminRepository(
        apiClient: api,
      ).approveClinicProfile(id);
      expect(result.setupStatus, 'approved');
      expect(result.descriptionAr, 'ملف اختبار محلي.');
      expect(adapter.requests.first.path, 'admin/clinics/$id/');
      expect(adapter.requests.first.method, 'GET');
      expect(adapter.requests[1].path, 'admin/clinics/$id/verify/');
      expect(adapter.requests[1].data, {
        'reason': 'Clinic profile approved through platform review.',
      });
      expect(adapter.requests.last.method, 'GET');
      expect(adapter.requests.last.path, 'admin/clinics/$id/');
      AuthState().login(name: 'QA', phone: 'patient', role: 'patient');
      await expectLater(
        AdminRepository(apiClient: api).approveClinicProfile(id),
        throwsA(isA<ApiException>()),
      );
      expect(adapter.requests.length, 3);
    },
  );
  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      testWidgets(
        'review inbox, submitted profile and category discovery dark=$dark ar=$ar',
        (tester) async {
          AuthState().login(name: 'QA', phone: 'qa', role: 'super_admin');
          var approved = false;
          use((o) {
            if (o.path.endsWith('/verify/')) {
              approved = true;
              return body({
                'status': 'success',
                'clinic_id': id,
                'setup_status': 'approved',
                'new_status': 'active',
              });
            }
            if (o.path == 'admin/clinics/$id/') {
              return body(clinic(status: approved ? 'approved' : 'submitted'));
            }
            if (o.path == 'admin/clinics/') {
              return body(
                page(
                  [clinic(status: approved ? 'approved' : 'submitted')],
                  count: 21,
                  next: '?page=2',
                ),
              );
            }
            if (o.path.contains('category-requests')) {
              return body(page([], count: 6));
            }
            return body(page([]));
          });
          await render(
            tester,
            AdminDashboardScreen(
              onNavigateToClinics: () {},
              onNavigateToLeads: () {},
              onNavigateToAnalytics: () {},
            ),
            dark: dark,
            ar: ar,
          );
          expect(
            find.byKey(const ValueKey('admin-category-requests-quick-action')),
            findsOneWidget,
          );
          expect(
            find.text(ar ? 'قيد الانتظار: 6' : 'Pending: 6'),
            findsOneWidget,
          );
          await capture(
            tester,
            'admin_review_dashboard_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          await tester.tap(
            find.byKey(const ValueKey('admin-clinic-reviews-quick-action')),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(ar ? 'المرسلة (المحمّلة)' : 'Submitted (loaded)'),
            findsOneWidget,
          );
          expect(
            adapter.requests
                .where((r) => r.path == 'admin/clinics/')
                .last
                .queryParameters
                .containsKey('setup_status'),
            isFalse,
          );
          await capture(
            tester,
            'clinic_reviews_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          await tester.tap(
            find.text(ar ? 'عيادة اختبار محلي' : 'Local QA Clinic'),
          );
          await tester.pumpAndSettle();
          await capture(
            tester,
            'clinic_review_profile_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('approve-clinic-profile')),
            500,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(
            find.byKey(const ValueKey('approve-clinic-profile')),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(ar ? 'موافقة وتفعيل' : 'Approve and activate'),
            findsOneWidget,
          );
          await tester.tap(
            find.text(ar ? 'موافقة وتفعيل' : 'Approve and activate'),
          );
          await tester.pumpAndSettle();
          expect(approved, isTrue);
          expect(
            find.byKey(const ValueKey('approve-clinic-profile')),
            findsNothing,
          );
          expect(
            adapter.requests.where((r) => r.path.endsWith('/verify/')),
            hasLength(1),
          );
          await tester.pumpWidget(const SizedBox());
          await tester.binding.setSurfaceSize(null);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'pending count refreshes on entry, resume, pull and each moderation decision; never per build',
    (tester) async {
      AuthState().login(name: 'QA', phone: 'qa', role: 'super_admin');
      var total = 9, reads = 0;
      use((o) {
        if (o.path.contains('category-requests') && o.method == 'GET') {
          reads++;
          expectSync(o.queryParameters['status'], 'pending');
          return body(page([], count: total));
        }
        if (o.path.contains('category-requests') && o.method == 'POST') {
          total--;
          return body({
            'id': proposalId,
            'status': o.path.endsWith('/approve/') ? 'approved' : 'rejected',
          });
        }
        return body(page([]));
      });
      await render(
        tester,
        AdminDashboardScreen(
          onNavigateToClinics: () {},
          onNavigateToLeads: () {},
          onNavigateToAnalytics: () {},
        ),
      );
      expect(reads, 1);
      expect(find.text('Pending: 9'), findsOneWidget);
      await tester.pump();
      await tester.pump();
      expect(reads, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(reads, 2);
      final refreshed = tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pumpAndSettle();
      await refreshed;
      await tester.pumpAndSettle();
      expect(reads, 3);
      final repo = CategoryRequestRepository(apiClient: api);
      final approve = repo.review(proposalId, approve: true);
      await tester.pumpAndSettle();
      await approve;
      await tester.pumpAndSettle();
      expect(
        find.text('Pending: 8'),
        findsOneWidget,
        reason:
            'reads=$reads total=$total count=${AdminReviewService().pendingCategories} loading=${AdminReviewService().loading} error=${AdminReviewService().error} requests=${adapter.requests.map((r) => r.method + r.path).toList()}',
      );
      final reject = repo.review(
        proposalId,
        approve: false,
        reason: 'Use existing category',
      );
      await tester.pumpAndSettle();
      await reject;
      await tester.pumpAndSettle();
      expect(find.text('Pending: 7'), findsOneWidget);
      expect(reads, 5);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  test(
    'count failure is unknown, recoverable and never reports zero',
    () async {
      AuthState().login(name: 'QA', phone: 'qa', role: 'super_admin');
      use((_) => body({'detail': 'Synthetic rejected count request'}, 400));
      final counter = AdminReviewService.withRepository(
        CategoryRequestRepository(apiClient: api),
      );
      await counter.refresh();
      expect(counter.pendingCategories, isNull);
      expect(counter.error, isNotEmpty);
      use((_) => body(page([], count: 0)));
      await counter.refresh();
      expect(counter.pendingCategories, 0);
      expect(counter.error, isNull);
      counter.dispose();
    },
  );
  for (final state in ['draft', 'submitted', 'approved', 'rejected']) {
    for (final ar in [false, true]) {
      testWidgets(
        'clinic setup $state neutral copy and supported resubmit ar=$ar',
        (tester) async {
          AuthState().login(name: 'QA', phone: 'clinic', role: 'clinic_admin');
          final model = ClinicModel.fromJson(clinic(status: state));
          await render(
            tester,
            Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ClinicSetupChecklistCard(
                    clinic: model,
                    checklist: ClinicSetupChecklistModel(
                      clinicId: id,
                      setupStatus: state,
                      progressPercentage: 100,
                      isReadyForReview: true,
                      items: const [
                        ClinicSetupChecklistItem(
                          key: 'practitioners',
                          titleEn: 'At least 1 Licensed Medical Practitioner',
                          titleAr: 'إضافة ممارس مرخص',
                          isCompleted: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ar: ar,
            dark: ar,
          );
          expect(
            find.text(
              ar ? 'إضافة ممارس واحد على الأقل' : 'At Least One Practitioner',
            ),
            findsOneWidget,
          );
          expect(
            find.textContaining('Licensed Medical Practitioner'),
            findsNothing,
          );
          expect(find.textContaining('مرخص'), findsNothing);
          expect(
            find.text(
              ar
                  ? 'إرسال ملف العيادة للمراجعة'
                  : 'Submit Clinic Profile for Review',
            ),
            state == 'draft' || state == 'rejected'
                ? findsOneWidget
                : findsNothing,
          );
          if (state == 'rejected') {
            expect(
              find.textContaining(
                ar ? 'لا يعيد سبب الرفض' : 'does not return a rejection reason',
              ),
              findsOneWidget,
            );
          }
          if (state == 'submitted') {
            expect(
              find.text(ar ? 'قيد مراجعة المنصة' : 'Under Platform Review'),
              findsOneWidget,
            );
          }
          await capture(
            tester,
            'clinic_setup_${state}_${ar ? 'dark_ar' : 'light_en'}',
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.binding.setSurfaceSize(null);
        },
      );
    }
  }
  for (final eligible in [false, true]) {
    for (final ar in [false, true]) {
      testWidgets(
        'video entitlement is derived from the saved profile eligible=$eligible ar=$ar',
        (tester) async {
          AuthState().login(name: 'QA', phone: 'clinic', role: 'clinic_admin');
          final profile = Profile()
            ..current = ClinicModel.fromJson({
              ...clinic(),
              'subscription_tier': eligible ? 'vip' : 'basic',
              'cover_image': File(
                'test/fixtures/media/portrait_photo.png',
              ).absolute.uri.toString(),
            });
          final service = ClinicPortalService();
          service.resetTestingState();
          service.setCatalogRepositoryForTesting(profile);
          service.setActiveClinicForTesting(profile.current);
          await render(
            tester,
            ClinicMediaScreen(repository: Gallery()),
            ar: ar,
            dark: ar,
          );
          final button = find.text(
            ar ? 'اختيار فيديو من المعرض' : 'Select gallery video',
          );
          await tester.scrollUntilVisible(
            button,
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          if (eligible) {
            expect(
              tester
                  .widget<TextButton>(
                    find.ancestor(
                      of: button,
                      matching: find.byType(TextButton),
                    ),
                  )
                  .onPressed,
              isNotNull,
            );
            await settlePreviewImages(tester);
          } else {
            expect(
              tester
                  .widget<OutlinedButton>(
                    find.ancestor(
                      of: button,
                      matching: find.byType(OutlinedButton),
                    ),
                  )
                  .onPressed,
              isNull,
            );
            expect(
              find.textContaining(ar ? 'غير مفعّل' : 'not enabled'),
              findsOneWidget,
            );
          }
          expect(profile.patches, isEmpty);
          await capture(
            tester,
            'clinic_video_${eligible ? 'eligible' : 'ineligible'}_${ar ? 'dark_ar' : 'light_en'}',
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.binding.setSurfaceSize(null);
          service.resetTestingState();
        },
      );
    }
  }
  test(
    'stale or mismatched clinic review is rejected before mutation',
    () async {
      AuthState().login(name: 'QA', phone: 'qa', role: 'super_admin');
      use((o) => body(clinic(status: 'approved')));
      await expectLater(
        AdminRepository(apiClient: api).approveClinicProfile(id),
        throwsA(isA<ApiException>()),
      );
      expect(adapter.requests.every((o) => o.method == 'GET'), isTrue);
      use((o) => body({...clinic(), 'id': proposalId}));
      await expectLater(
        AdminRepository(apiClient: api).approveClinicProfile(id),
        throwsA(isA<ApiException>()),
      );
      expect(adapter.requests.every((o) => o.method == 'GET'), isTrue);
    },
  );
  for (final ar in [false, true]) {
    testWidgets(
      'narrow Android admin navigation retains all five destinations ar=$ar',
      (tester) async {
        AuthState().login(name: 'QA', phone: 'qa', role: 'super_admin');
        use((o) => body(page([], count: 3)));
        await render(
          tester,
          const AdminMainNavScreen(),
          ar: ar,
          dark: ar,
          width: 320,
        );
        for (final label
            in ar
                ? ['الرئيسية', 'العيادات', 'الطلبات', 'المحتوى', 'التحليلات']
                : ['Home', 'Clinics', 'Leads', 'Content', 'Insights']) {
          expect(find.text(label), findsWidgets);
        }
        await capture(
          tester,
          'admin_navigation_narrow_${ar ? 'dark_ar' : 'light_en'}',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
      },
    );
  }
  for (final replace in [false, true]) {
    test(
      'startup preference I/O cannot resurrect a logged-out or replaced identity replace=$replace',
      () async {
        await TokenStorage().saveTokens(
          accessToken: 'disposable-fixture',
          refreshToken: 'disposable-fixture',
        );
        await TokenStorage().saveUser({
          'id': id,
          'full_name': 'Old fixture',
          'role': 'clinic_admin',
          'phone': 'old',
        });
        final storage = DeferredStorage();
        final intro = OnboardingService.withStorage(storage);
        final restoring = AuthState().restoreSession(onboardingService: intro);
        await storage.entered.future;
        if (replace) {
          AuthState().login(name: 'Replacement', phone: 'new', role: 'patient');
        } else {
          AuthState().logout();
        }
        storage.release.complete();
        await restoring;
        expect(AuthState().isLoggedIn, replace);
        expect(AuthState().userPhone, replace ? 'new' : '');
        expect(AuthState().isClinicAdmin, isFalse);
        intro.dispose();
      },
    );
  }
}
