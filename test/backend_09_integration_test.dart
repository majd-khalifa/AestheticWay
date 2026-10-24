import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/admin/data/admin_repository.dart';
import 'package:aesthetic_way/features/admin/models/admin_clinic_model.dart';
import 'package:aesthetic_way/features/admin/models/admin_dashboard_model.dart';
import 'package:aesthetic_way/features/admin/services/admin_review_service.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_clinic_reviews_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/widgets/admin_clinic_inspection.dart';
import 'package:aesthetic_way/features/clinic_portal/data/models/clinic_setup_checklist_model.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/widgets/clinic_setup_checklist_card.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/account_deletion_screen.dart';
import 'onboarding_review_workflows_test.dart' as f;
import 'support/patient_visual_harness.dart';
import 'support/settle_preview_images.dart';

const id = f.id;
const reason = 'Replace the QA cover and complete the Arabic address.';
Map<String, dynamic> row({
  String setup = 'submitted',
  String access = 'pending',
}) => {
  ...f.clinic(status: setup),
  'status': access,
  'moderation_notes': setup == 'rejected' ? reason : '',
  'subscription_tier': 'vip',
  'gallery_assets': <Object>[],
  'gallery_images': <Object>[],
  'practitioners': <Object>[],
  'treatments': <Object>[],
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  final api = ApiClient();
  late HttpClientAdapter original;
  late f.Adapter adapter;
  void use(FutureOr<ResponseBody> Function(RequestOptions) fn) {
    adapter = f.Adapter(fn);
    api.dio.httpClientAdapter = adapter;
  }

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    AuthState().login(name: 'QA', phone: '', role: 'super_admin');
    original = api.dio.httpClientAdapter;
    api.updateBaseUrl('https://fixture.invalid/api/v1/');
    use((_) => f.body({}));
    await LocaleService().setLanguage(AppLanguage.english);
  });
  tearDown(() async {
    api.dio.httpClientAdapter = original;
    api.updateBaseUrl(ApiConfig.defaultProductionBaseUrl);
    ApiConfig.resetBaseUrl();
    AuthState().logout();
    await TokenStorage().clear();
  });
  test(
    'server setup filtering retains pagination and never aliases account status',
    () async {
      use(
        (_) => f.body(
          f.page(
            [row()],
            count: 41,
            next: 'https://fixture.invalid/api/v1/admin/clinics/?page=3',
          ),
        ),
      );
      final rows = await AdminRepository(
        apiClient: api,
      ).getClinics(page: 2, setupStatus: 'submitted', status: 'pending');
      expect(
        adapter.requests.single.queryParameters,
        containsPair('setup_status', 'submitted'),
      );
      expect(
        adapter.requests.single.queryParameters,
        containsPair('status', 'pending'),
      );
      expect(adapter.requests.single.queryParameters, containsPair('page', 2));
      expect((rows as PageItems<AdminClinicModel>).total, 41);
      expect(rows.hasMore, isTrue);
    },
  );
  test(
    'submitted count is independent of pending activation and missing stays unknown',
    () {
      expect(
        AdminDashboardModel.fromJson({
          'pending_clinics': 99,
          'submitted_setup_count': 0,
        }).submittedSetupCount,
        0,
      );
      expect(
        AdminDashboardModel.fromJson({
          'pending_clinics': 99,
          'submitted_setup_count': 37,
        }).submittedSetupCount,
        37,
      );
      expect(
        AdminDashboardModel.fromJson({
          'pending_clinics': 99,
        }).submittedSetupCount,
        isNull,
      );
    },
  );
  test(
    'new private owner rejection fields survive parsing; old notes hidden after resubmission',
    () {
      final j = {...row(setup: 'rejected'), 'setup_rejection_reason': reason};
      expect(ClinicModel.fromJson(j).setupRejectionReason, reason);
      expect(
        ClinicSetupChecklistModel.fromJson(j).setupRejectionReason,
        reason,
      );
      expect(
        ClinicModel.fromJson({
          ...j,
          'setup_status': 'submitted',
        }).setupRejectionReason,
        isEmpty,
      );
    },
  );
  for (final action in ['approve', 'reject']) {
    test(
      '$action uses actual action acknowledgment then re-reads full detail and notifies decisions',
      () async {
        var state = 'submitted';
        var access = 'pending';
        final before = AdminRepository.clinicReviewDecisions.value;
        use((o) {
          if (o.method == 'POST') {
            state = action == 'approve' ? 'approved' : 'rejected';
            if (action == 'approve') access = 'active';
            return f.body({
              'status': 'success',
              'clinic_id': id,
              'setup_status': state,
              if (action == 'approve') 'new_status': 'active',
              if (action == 'reject') 'rejection_reason': reason,
            });
          }
          return f.body(row(setup: state, access: access));
        });
        final repo = AdminRepository(apiClient: api);
        final value = action == 'approve'
            ? await repo.approveClinicProfile(id)
            : await repo.rejectClinicSetup(id, reason);
        expect(value.setupStatus, state);
        expect(value.status, action == 'approve' ? 'active' : 'pending');
        expect(adapter.requests.where((r) => r.method == 'GET').length, 2);
        final post = adapter.requests.firstWhere((r) => r.method == 'POST');
        expect(
          post.path,
          'admin/clinics/$id/${action == 'approve' ? 'verify' : 'reject-setup'}/',
        );
        if (action == 'reject') expect(post.data, {'rejection_reason': reason});
        expect(
          AdminRepository.clinicReviewDecisions.value,
          greaterThan(before),
        );
      },
    );
    for (final state in ['draft', 'approved', 'rejected']) {
      test('$action refuses stale $state before a write', () async {
        use((_) => f.body(row(setup: state)));
        final repo = AdminRepository(apiClient: api);
        await expectLater(
          action == 'approve'
              ? repo.approveClinicProfile(id)
              : repo.rejectClinicSetup(id, reason),
          throwsA(isA<ApiException>()),
        );
        expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
      });
    }
    test('$action never treats a malformed 200 as success', () async {
      use(
        (o) => f.body(
          o.method == 'GET'
              ? row()
              : {
                  'status': 'success',
                  'clinic_id': 'foreign',
                  'setup_status': 'approved',
                },
        ),
      );
      final repo = AdminRepository(apiClient: api);
      await expectLater(
        action == 'approve'
            ? repo.approveClinicProfile(id)
            : repo.rejectClinicSetup(id, reason),
        throwsA(isA<ApiException>()),
      );
    });
  }
  for (final value in ['', '  ', 'x' * 1001]) {
    test(
      'reject requires a bounded nonempty reason length=${value.length}',
      () async {
        await expectLater(
          AdminRepository(apiClient: api).rejectClinicSetup(id, value),
          throwsA(isA<ApiException>()),
        );
        expect(adapter.requests, isEmpty);
      },
    );
  }
  test('patient cannot invoke either review action', () async {
    AuthState().login(name: 'QA', phone: '', role: 'patient');
    final repo = AdminRepository(apiClient: api);
    await expectLater(
      repo.rejectClinicSetup(id, reason),
      throwsA(isA<ApiException>()),
    );
    await expectLater(
      repo.approveClinicProfile(id),
      throwsA(isA<ApiException>()),
    );
    expect(adapter.requests, isEmpty);
  });
  for (final ar in [false, true]) {
    for (final code in [
      'INVALID_SETUP_TRANSITION',
      'CLINIC_NOT_SUBMITTED',
      'INCOMPLETE_ONBOARDING',
      'CLINIC_SETUP_INCOMPLETE',
      'ALREADY_APPROVED',
      'ALREADY_REVIEWED',
    ]) {
      test('localized conflict keeps safe machine code $code ar=$ar', () async {
        await LocaleService().setLanguage(
          ar ? AppLanguage.arabic : AppLanguage.english,
        );
        final o = RequestOptions(path: 'test');
        final e = ApiException.fromDioError(
          DioException(
            requestOptions: o,
            response: Response(
              requestOptions: o,
              statusCode: 409,
              data: {
                'error': {'code': code, 'message': 'Untrusted QA diagnostic'},
              },
            ),
            type: DioExceptionType.badResponse,
          ),
        );
        expect(e.errorCode, code);
        expect(e.message, isNot(contains('Untrusted')));
        expect(e.rawData, isNull);
        expect(e.originalBackendMessage, isNull);
      });
    }
  }
  test(
    'setup count refresh coalesces, invalidates pre-decision data and clears on logout',
    () async {
      final pending = Completer<ResponseBody>();
      final entered = Completer<void>();
      var reads = 0;
      use((o) {
        if (o.method == 'POST') return f.body({'status': 'success'});
        reads++;
        if (reads == 1) entered.complete();
        return reads == 1
            ? pending.future
            : f.body({'submitted_setup_count': 2});
      });
      final service = AdminReviewService.withRepository(
        f.Requests(),
        clinicRepository: AdminRepository(apiClient: api),
      );
      final old = service.refresh();
      final same = service.refresh();
      expect(identical(old, same), isTrue);
      await entered.future;
      await api.post(
        'admin/clinics/$id/reject-setup/',
        data: {'rejection_reason': reason},
      );
      AdminRepository.clinicReviewDecisions.value++;
      await service.refresh();
      expect(service.submittedClinics, 2);
      pending.complete(f.body({'submitted_setup_count': 90}));
      await old;
      expect(service.submittedClinics, 2);
      AuthState().logout();
      expect(service.submittedClinics, isNull);
      service.dispose();
    },
  );
  test(
    'inspection aliases use only actual fields and do not duplicate assets',
    () {
      final model = AdminClinicModel.fromJson({
        ...row(),
        'gallery_assets': [
          {
            'id': 'a',
            'url': 'https://fixture.invalid/a.png',
            'mime_type': 'image/png',
          },
          {
            'id': 'v',
            'url': 'https://fixture.invalid/v.mp4',
            'mime_type': 'video/mp4',
          },
        ],
        'gallery_images': ['https://fixture.invalid/other.png'],
        'practitioners': [
          {
            'id': 'p',
            'name_en': 'QA staff',
            'type': 'nurse',
            'avatar_url': '/media/portrait.png',
            'license_number': 'PRIVATE-QA',
          },
        ],
        'treatments': [
          {
            'id': 't',
            'name_en': 'QA treatment',
            'category_name': 'QA category',
            'is_active': false,
            'status': 'pending',
          },
        ],
      });
      expect(model.galleryAssets.map((a) => a.id), ['a']);
      expect(model.practitioners.single.type, 'nurse');
      expect(
        model.practitioners.single.avatar,
        endsWith('/media/portrait.png'),
      );
      expect(model.treatments.single.categoryName, 'QA category');
      expect(model.copyWith(status: 'active').practitioners.single.id, 'p');
    },
  );
  testWidgets(
    'rejection dialog requires reason, prevents duplicate writes and displays confirmed result',
    (tester) async {
      var state = 'submitted';
      var writes = 0;
      use((o) {
        if (o.method == 'POST') {
          writes++;
          expect(o.data, {'rejection_reason': reason});
          state = 'rejected';
          return f.body({
            'status': 'success',
            'clinic_id': id,
            'setup_status': state,
            'rejection_reason': reason,
          });
        }
        return f.body(row(setup: state));
      });
      await f.render(tester, const AdminClinicReviewDetail(clinicId: id));
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('reject-clinic-profile')),
        250,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('reject-clinic-profile')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reject-clinic-profile')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('confirm-clinic-rejection')),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byKey(const ValueKey('clinic-review-reason')),
        reason,
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('confirm-clinic-rejection')));
      await tester.pumpAndSettle();
      expect(writes, 1);
      expect(find.byKey(const ValueKey('reject-clinic-profile')), findsNothing);
      expect(find.text(reason), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.binding.setSurfaceSize(null);
    },
  );
  for (final status in [400, 401, 403, 409]) {
    test(
      'deletion rejection $status preserves current authenticated account',
      () async {
        AuthState().login(name: 'QA', phone: '', role: 'patient');
        use(
          (_) => f.body({
            'detail': 'Verification code rejected',
            'code': status == 409 ? 'SOLE_CLINIC_ADMIN' : 'VALIDATION_ERROR',
          }, status),
        );
        await expectLater(
          AuthRepository(apiClient: api).confirmAccountDeletion('000000'),
          throwsA(isA<ApiException>()),
        );
        if (status != 401) expect(AuthState().isLoggedIn, isTrue);
        expect(adapter.requests.length, 1);
      },
    );
  }
  testWidgets(
    'changing account clears the deletion OTP, consent and challenge',
    (tester) async {
      AuthState().login(name: 'QA', phone: '', role: 'patient');
      use(
        (_) =>
            f.body({'success': true, 'expires_in': 600, 'resend_cooldown': 60}),
      );
      await f.render(tester, const AccountDeletionScreen());
      await tester.tap(find.byKey(const ValueKey('deletion-request-code')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('deletion-code')),
        '000000',
      );
      await tester.tap(find.byKey(const ValueKey('deletion-consent')));
      await tester.pump();
      final controller = tester
          .widget<TextField>(find.byKey(const ValueKey('deletion-code')))
          .controller!;
      AuthState().login(
        name: 'Other QA',
        phone: 'other-fixture',
        role: 'patient',
      );
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
      expect(find.byKey(const ValueKey('deletion-confirm')), findsNothing);
      expect(adapter.requests.length, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      testWidgets(
        '09 source inspection and owner feedback renders dark=$dark ar=$ar',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(430, 1000);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final photo = File(
            'test/fixtures/media/fragrance_photo.jpg',
          ).absolute.uri.toString();
          final portrait = File(
            'test/fixtures/media/portrait_photo.png',
          ).absolute.uri.toString();
          final data = {
            ...row(),
            'cover_image': photo,
            'gallery_assets': [
              {'id': 'g1', 'url': photo, 'mime_type': 'image/jpeg'},
              {'id': 'g2', 'url': portrait, 'mime_type': 'image/png'},
            ],
            'practitioners': [
              {
                'id': 'p1',
                'name_en': 'Local QA practitioner',
                'name_ar': 'ممارس اختبار محلي',
                'type': 'doctor',
                'title_en': 'QA specialist',
                'title_ar': 'أخصائي اختبار',
                'speciality_en': 'Fixture specialty',
                'status': 'pending',
                'avatar_url': portrait,
                'license_number': 'PRIVATE-QA-LICENSE',
              },
            ],
            'treatments': [
              {
                'id': 't1',
                'name_en': 'Local QA treatment',
                'name_ar': 'علاج اختبار محلي',
                'category_name': 'Fixture category',
                'status': 'pending',
                'is_active': false,
              },
            ],
          };
          use((_) => f.body(data));
          await f.render(
            tester,
            const AdminClinicReviewDetail(clinicId: id),
            dark: dark,
            ar: ar,
          );
          await settlePreviewImages(tester);
          await f.capture(
            tester,
            'backend09_review_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          await tester.scrollUntilVisible(
            find.byType(AdminClinicInspection).first,
            200,
            scrollable: find
                .descendant(
                  of: find.byType(ListView),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.pumpAndSettle();
          await settlePreviewImages(tester);
          await f.capture(
            tester,
            'backend09_gallery_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          await f.render(
            tester,
            Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AdminClinicInspection(
                    clinic: AdminClinicModel.fromJson(data),
                    gallery: false,
                  ),
                ],
              ),
            ),
            dark: dark,
            ar: ar,
          );
          await settlePreviewImages(tester);
          expect(find.textContaining('PRIVATE-QA-LICENSE'), findsNothing);
          expect(
            find.text(ar ? 'ممارس اختبار محلي' : 'Local QA practitioner'),
            findsOneWidget,
          );
          await f.capture(
            tester,
            'backend09_content_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          AuthState().login(name: 'QA owner', phone: '', role: 'clinic_admin');
          await f.render(
            tester,
            Scaffold(
              body: ListView(
                children: [
                  ClinicSetupChecklistCard(
                    clinic: ClinicModel.fromJson({
                      ...data,
                      'setup_status': 'rejected',
                      'setup_rejection_reason': reason,
                    }),
                    checklist: ClinicSetupChecklistModel(
                      clinicId: id,
                      setupStatus: 'rejected',
                      setupRejectionReason: reason,
                      progressPercentage: 100,
                      isReadyForReview: true,
                      items: [
                        for (final key in [
                          'branding',
                          'details',
                          'branch',
                          'practitioner',
                          'treatment',
                        ])
                          ClinicSetupChecklistItem(
                            key: key,
                            titleEn: switch (key) {
                              'branding' => 'Clinic Branding (Logo & Cover)',
                              'details' =>
                                'Bilingual Bio & Contact Information',
                              'branch' => 'At least 1 Active Branch Location',
                              'practitioner' =>
                                'At least 1 Medical Practitioner',
                              _ => 'At least 1 Treatment Service',
                            },
                            titleAr: switch (key) {
                              'branding' =>
                                'الهوية البصرية (الشعار وصورة الغلاف)',
                              'details' =>
                                'الوصف التعريفي باللغتين ومعلومات الاتصال',
                              'branch' =>
                                'إضافة فرع واحد على الأقل مع خرائط جوجل',
                              'practitioner' => 'إضافة ممارس واحد على الأقل',
                              _ => 'إضافة خدمة أو علاج واحد على الأقل',
                            },
                            isCompleted: true,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            dark: dark,
            ar: ar,
          );
          expect(find.textContaining(reason), findsOneWidget);
          await f.capture(
            tester,
            'backend09_owner_feedback_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.binding.setSurfaceSize(null);
        },
      );
    }
  }
  for (final role in ['patient', 'clinic_admin']) {
    testWidgets(
      'private clinic inspection is hidden after role replacement: $role',
      (tester) async {
        await f.render(
          tester,
          Scaffold(
            body: AdminClinicInspection(
              clinic: AdminClinicModel.fromJson(row()),
            ),
          ),
        );
        expect(find.text('Saved clinic gallery'), findsOneWidget);
        AuthState().login(name: 'Other', phone: 'other-qa', role: role);
        await tester.pumpAndSettle();
        expect(find.text('Saved clinic gallery'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
      },
    );
  }
  for (final action in ['approve', 'reject']) {
    testWidgets(
      'review $action 409 refreshes truthful state and never claims successful action',
      (tester) async {
        var state = 'submitted';
        var writes = 0;
        use((o) {
          if (o.method == 'POST') {
            writes++;
            state = 'approved';
            return f.body({
              'error': {
                'code': 'INVALID_SETUP_TRANSITION',
                'message': 'Stale fixture state',
              },
            }, 409);
          }
          return f.body(
            row(
              setup: state,
              access: state == 'approved' ? 'active' : 'pending',
            ),
          );
        });
        await f.render(tester, const AdminClinicReviewDetail(clinicId: id));
        final key = ValueKey(
          action == 'approve'
              ? 'approve-clinic-profile'
              : 'reject-clinic-profile',
        );
        await tester.scrollUntilVisible(
          find.byKey(key),
          300,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(key));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(key));
        await tester.pumpAndSettle();
        if (action == 'reject') {
          await tester.enterText(
            find.byKey(const ValueKey('clinic-review-reason')),
            reason,
          );
          await tester.pump();
          await tester.tap(
            find.byKey(const ValueKey('confirm-clinic-rejection')),
          );
        } else {
          await tester.tap(find.text('Approve and activate'));
        }
        await tester.pumpAndSettle();
        expect(writes, 1);
        expect(find.byKey(key), findsNothing);
        await tester.scrollUntilVisible(
          find.textContaining('no longer submitted'),
          -400,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('no longer submitted'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
      },
    );
  }
  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      testWidgets('review inspection 320dp at 180 percent dark=$dark ar=$ar', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 1000);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final photo = File(
          'test/fixtures/media/portrait_photo.png',
        ).absolute.uri.toString();
        final c = AdminClinicModel.fromJson({
          ...row(),
          'gallery_assets': [
            {'id': 'g', 'url': photo, 'mime_type': 'image/png'},
          ],
          'practitioners': [
            {
              'id': 'p',
              'name_en': 'Long local QA practitioner name',
              'name_ar': 'اسم ممارس اختبار محلي طويل',
              'title_en': 'QA title',
              'type': 'nurse',
              'avatar_url': photo,
            },
          ],
          'treatments': [
            {
              'id': 't',
              'name_en': 'Local QA treatment',
              'category_name': 'Long fixture category',
              'status': 'pending',
            },
          ],
        });
        await f.render(
          tester,
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [AdminClinicInspection(clinic: c)],
              ),
            ),
          ),
          width: 320,
          dark: dark,
          ar: ar,
        );
        await settlePreviewImages(tester);
        await f.capture(
          tester,
          'backend09_narrow_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
      });
    }
  }
}
