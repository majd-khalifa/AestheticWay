// Synthetic transport records only; these are never shipped as patient content.
import 'dart:async';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/widgets/practitioner_badge.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';
import 'package:aesthetic_way/features/auth/data/models/auth_models.dart';
import 'package:aesthetic_way/features/profile/presentation/screens/profile_screen.dart';
import 'package:aesthetic_way/features/appointment_lead/data/leads_repository.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_success_screen.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/my_requests_screen.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/widgets/lead_rejection_notice.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/clinics/presentation/widgets/google_clinic_rating.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/patient_fixtures.dart';
import 'support/patient_visual_harness.dart';

const duplicateDetail =
    'A request for this service at this clinic was already submitted recently.';
ApiException rejection(Object body, {String? retryAfter}) =>
    ApiException.fromDioError(
      DioException.badResponse(
        statusCode: 429,
        requestOptions: RequestOptions(path: 'leads/'),
        response: Response(
          requestOptions: RequestOptions(path: 'leads/'),
          statusCode: 429,
          data: body,
          headers: Headers.fromMap({
            if (retryAfter != null) 'retry-after': [retryAfter],
          }),
        ),
      ),
    );
Map<String, dynamic> historyRow(int index, {String status = 'new'}) => {
  'id': 'test-lead-$index',
  'reference_code': '#REQ-$index',
  'status': status,
  'created_at': '2026-10-22T09:10:00Z',
  'clinic': patientClinicId,
  'clinic_summary': {
    'id': patientClinicId,
    'name_en': 'Source Clinic',
    'name_ar': 'عيادة المصدر',
  },
  'service_name': 'Submitted service',
  'treatment_summary': {
    'name_en': 'Source Treatment $index',
    'name_ar': 'علاج المصدر $index',
  },
  'practitioner_summary': {
    'name_en': 'Source Practitioner',
    'name_ar': 'ممارس المصدر',
    'type': 'doctor',
  },
};

class QaLeads extends LeadsRepository {
  final submissions = <Map<String, dynamic>>[];
  final reads = <(int, String?)>[];
  Completer<LeadSubmitResult>? pending;
  ApiException? failure;
  bool nextPageFails = false;
  bool empty = false;
  bool firstPageFails = false;
  @override
  Future<LeadSubmitResult> createLead(Map<String, dynamic> payload) async {
    submissions.add(Map.of(payload));
    if (pending != null) return pending!.future;
    if (failure != null) throw failure!;
    return LeadSubmitResult(
      success: true,
      leadReference: '#REQ-1',
      confirmationMessage: 'تم إرسال طلبك وستتواصل العيادة معك',
      createdAt: DateTime.utc(2026, 10, 22),
    );
  }

  @override
  Future<List<AppointmentRequestModel>> getMyLeads({
    int page = 1,
    String? status,
  }) async {
    reads.add((page, status));
    if (firstPageFails) {
      throw const ApiException(message: 'Unable to load requests');
    }
    if (empty) return PageItems([], hasMore: false, total: 0);
    if (page == 2 && nextPageFails) {
      throw const ApiException(message: 'Unable to load more');
    }
    final count = status == null ? 21 : 1;
    return PageItems(
      [
        for (
          var i = page == 1 ? 1 : 21;
          i <= (page == 1 ? (status == null ? 20 : 1) : 21);
          i++
        )
          AppointmentRequestModel.fromPatientJson(
            historyRow(i, status: status ?? 'new'),
          ),
      ],
      hasMore: page == 1 && status == null,
      total: count,
    );
  }
}

class QaAuth implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<UserModel> getMe() async => UserModel(
    id: 'test-patient',
    fullName: 'Test Patient',
    phone: '+971501234567',
    role: 'patient',
  );
}

class RecordingHistoryClient implements ApiClient {
  String? path;
  Map<String, dynamic>? query;
  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    this.path = path;
    query = queryParameters;
    return Response(
      requestOptions: RequestOptions(path: path),
      data:
          {
                'count': 1,
                'next': null,
                'results': [historyRow(1)],
              }
              as T,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> frame(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  bool ar = false,
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await LocaleService().setLanguage(
    ar ? AppLanguage.arabic : AppLanguage.english,
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: patientVisualTheme(dark: dark),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
          child: RepaintBoundary(
            key: const ValueKey('android-qa'),
            child: child!,
          ),
        ),
      ),
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  const output = String.fromEnvironment('ANDROID_QA_CAPTURE_DIR');
  if (output.isEmpty) return;
  await expectLater(
    find.byKey(const ValueKey('android-qa')),
    matchesGoldenFile(Uri.file('$output/$name.png')),
  );
}

Future<void> prepareForm(
  WidgetTester tester,
  QaLeads repo, {
  bool dark = false,
  bool ar = false,
}) async {
  await frame(
    tester,
    AppointmentRequestScreen(
      clinic: patientClinic(),
      leadsRepository: repo,
      preselectedServiceName: 'Selected service',
      preselectedTreatmentId: '77777777-7777-4777-8777-777777777777',
      preselectedPractitioner: PractitionerModel.fromJson({
        'id': '44444444-4444-4444-8444-444444444444',
        'clinic': patientClinicId,
        'name_en': 'Selected Practitioner',
        'name_ar': 'الممارس المختار',
        'type': 'doctor',
      }),
    ),
    dark: dark,
    ar: ar,
  );
  await tester.enterText(find.byType(TextFormField).first, 'Test Patient');
  await tester.enterText(find.byType(TextFormField).at(1), '501234567');
  await tester.enterText(
    find.byType(TextFormField).last,
    'Please retain this inquiry',
  );
  await tester.ensureVisible(find.byType(Checkbox));
  await tester.tap(find.byType(Checkbox));
  await tester.ensureVisible(find.text(LocaleService().tr('submit_lead_btn')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadPatientVisualFonts);
  setUp(() async {
    await LocaleService().setLanguage(AppLanguage.english);
    FlutterSecureStorage.setMockInitialValues({});
    AuthState().login(name: 'Test Patient', phone: '+971501234567');
  });
  tearDown(() => AuthState().logout());

  test(
    'ca15dc6 duplicate retains sanitized code but no raw error data or invented wait',
    () {
      final error = rejection({'detail': duplicateDetail});
      expect(error.errorCode, 'DUPLICATE_LEAD');
      expect(error.retryAfter, isNull);
      expect(error.rawData, isNull);
      expect(error.originalBackendMessage, isNull);
    },
  );
  test(
    'account throttle differs from duplicate and honors header plus numeric envelope delay',
    () {
      final error = rejection({
        'error': {
          'code': 'RATE_LIMIT_EXCEEDED',
          'message': 'Request was throttled.',
          'retry_after': 72.25,
        },
      }, retryAfter: '60');
      expect(error.errorCode, 'RATE_LIMIT_EXCEEDED');
      expect(error.retryAfter, const Duration(milliseconds: 72250));
      expect(error.message, isNot(contains('similar request')));
      final noWait = rejection({
        'error': {
          'code': 'RATE_LIMIT_EXCEEDED',
          'message': 'Request was throttled.',
          'retry_after': null,
        },
      });
      expect(noWait.errorCode, 'RATE_LIMIT_EXCEEDED');
      expect(noWait.retryAfter, isNull);
    },
  );
  testWidgets(
    'local backpressure estimate never masquerades as a server-requested wait',
    (tester) async {
      await frame(
        tester,
        Scaffold(
          body: LeadRejectionNotice(
            error: const ApiException(
              message: 'Please wait',
              statusCode: 429,
              errorCode: 'THROTTLED',
              retryAfter: Duration(seconds: 1),
              isLocalBackpressure: true,
            ),
            onViewRequests: () {},
          ),
        ),
      );
      expect(find.textContaining('server requested'), findsNothing);
      expect(find.textContaining('seconds'), findsNothing);
      expect(
        find.text(
          'This request could not be sent right now. Please wait before trying again; your form is unchanged.',
        ),
        findsOneWidget,
      );
    },
  );
  test('unknown 429 never infers a saved or duplicate lead', () {
    final error = rejection({'detail': 'Unrecognized server explanation'});
    expect(error.errorCode, isNot('DUPLICATE_LEAD'));
    expect(error.retryAfter, isNull);
  });
  for (final invalid in [-1, '30', double.nan, double.infinity]) {
    test(
      'invalid retry_after $invalid cannot manufacture waiting guidance',
      () {
        expect(
          rejection({
            'error': {'code': 'RATE_LIMIT_EXCEEDED', 'retry_after': invalid},
          }).retryAfter,
          isNull,
        );
      },
    );
  }
  test(
    'patient history retains server identity, localized fallback and no invented branch',
    () {
      final row = historyRow(
        7,
      )..['clinic_summary'] = {'name_ar': '', 'name_en': 'Source only English'};
      final lead = AppointmentRequestModel.fromPatientJson(row);
      expect(lead.clinicNameAr, 'Source only English');
      expect(lead.branchNameAr, isEmpty);
      expect(lead.branchNameEn, isEmpty);
      expect(lead.serviceNameEn, 'Source Treatment 7');
      expect(lead.practitionerNameEn, 'Source Practitioner');
      expect(lead.referenceCode, '#REQ-7');
      expect(lead.createdAt, DateTime.utc(2026, 10, 22, 9, 10));
    },
  );
  for (final entry in {
    'reference_code': '',
    'created_at': 'invalid',
    'status': 'booked',
    'id': '',
  }.entries) {
    test(
      'incomplete history ${entry.key} cannot turn into a fabricated sent request',
      () {
        expect(
          () => AppointmentRequestModel.fromPatientJson({
            ...historyRow(1),
            entry.key: entry.value,
          }),
          throwsFormatException,
        );
      },
    );
  }
  test(
    'history repository uses account-scoped endpoint and bounded page with no patient selector',
    () async {
      final client = RecordingHistoryClient();
      final result = await LeadsRepository(
        apiClient: client,
      ).getMyLeads(page: 2, status: 'contacted');
      expect(client.path, 'leads/my/');
      expect(client.query, {'page': 2, 'page_size': 20, 'status': 'contacted'});
      expect(result.single.status, AppointmentLeadStatus.sent);
      expect(result, isA<PageItems<AppointmentRequestModel>>());
    },
  );
  for (final id in [null, '', '   ']) {
    testWidgets('orphaned rating 4.9 / 1204 is hidden with Place ID $id', (
      tester,
    ) async {
      final clinic = patientClinic(
        extra: {
          'google_place_id': id,
          'google_rating': 4.9,
          'google_reviews_count': 1204,
        },
      );
      expect(clinic.hasGoogleRating, isFalse);
      await frame(tester, Scaffold(body: GoogleClinicRating(clinic: clinic)));
      expect(find.text('4.9'), findsNothing);
      expect(find.textContaining('1204'), findsNothing);
    });
  }
  testWidgets(
    'configured Google aggregates display unchanged and disappear on refreshed ID removal',
    (tester) async {
      final clinic = patientClinic(
        extra: {
          'google_place_id': 'test-configured-place',
          'google_rating': 4.9,
          'google_reviews_count': 1204,
        },
      );
      await frame(tester, Scaffold(body: GoogleClinicRating(clinic: clinic)));
      expect(find.text('4.9'), findsOneWidget);
      await frame(
        tester,
        Scaffold(
          body: GoogleClinicRating(
            clinic: ClinicModel.fromJson({
              'id': clinic.id,
              'google_place_id': '',
              'google_rating': 4.9,
              'google_reviews_count': 1204,
            }),
          ),
        ),
      );
      expect(find.text('4.9'), findsNothing);
    },
  );
  for (final ar in [false, true]) {
    testWidgets(
      'neutral practitioner labels preserve Doctor and API types ar=$ar',
      (tester) async {
        await frame(
          tester,
          Scaffold(
            body: Column(
              children: [
                for (final type in PractitionerType.values)
                  PractitionerBadge(type: type),
              ],
            ),
          ),
          ar: ar,
        );
        expect(find.text(ar ? 'طبيب' : 'Doctor'), findsOneWidget);
        expect(find.text(ar ? 'ممرض' : 'Nurse'), findsOneWidget);
        expect(find.text(ar ? 'أخصائي' : 'Specialist'), findsOneWidget);
        expect(find.textContaining('Licensed'), findsNothing);
        expect(find.textContaining('مرخص'), findsNothing);
        await capture(tester, 'roles_light_${ar ? 'ar' : 'en'}');
        expect(
          PractitionerType.licensedProfessional.value,
          'licensed_professional',
        );
      },
    );
  }
  testWidgets(
    'history normal back, detail summaries, immediate filters, pagination and refresh',
    (tester) async {
      final repo = QaLeads();
      await frame(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MyRequestsScreen(leadsRepository: repo),
                ),
              ),
              child: const Text('Open history'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open history'));
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);
      await capture(tester, 'history_navigation_light_en');
      expect(find.text('All'), findsOneWidget);
      expect(find.text('All (20)'), findsNothing);
      await tester.tap(find.text('Source Clinic').first);
      await tester.pumpAndSettle();
      expect(find.text('Source Treatment 1'), findsWidgets);
      expect(find.text('Source Practitioner'), findsWidgets);
      expect(find.text('Main Branch'), findsNothing);
      expect(find.textContaining('2026/10/22'), findsWidgets);
      Navigator.of(tester.element(find.text('Request Details'))).pop();
      await tester.pumpAndSettle();
      final list = find.byType(ListView).first;
      await tester.drag(list, const Offset(0, -10000));
      await tester.pumpAndSettle();
      expect(repo.reads, contains((2, null)));
      await tester.tap(find.text(LocaleService().tr('status_contacted')));
      await tester.pumpAndSettle();
      expect(repo.reads.last, (1, 'contacted'));
      final completedReads = repo.reads.length;
      await tester.tap(
        find.ancestor(
          of: find.text(LocaleService().tr('status_contacted')),
          matching: find.byType(ChoiceChip),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        repo.reads.length,
        completedReads,
        reason: 'Reselecting the active filter must not issue another GET.',
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('All (1)'), findsNothing);
      await tester.drag(find.byType(ListView).first, const Offset(0, 450));
      await tester.pumpAndSettle();
      expect(repo.reads.where((e) => e == (1, 'contacted')).length, 2);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Open history'), findsOneWidget);
    },
  );
  testWidgets(
    'repeated taps send once; rejection keeps all input and history back returns to form',
    (tester) async {
      final repo = QaLeads()..pending = Completer<LeadSubmitResult>();
      await prepareForm(tester, repo);
      final submit = find.text(LocaleService().tr('submit_lead_btn'));
      await tester.tap(submit);
      await tester.tap(submit);
      await tester.pump();
      expect(repo.submissions.length, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      repo.pending!.completeError(rejection({'detail': duplicateDetail}));
      await tester.pumpAndSettle();
      expect(find.byType(LeadRejectionNotice), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      // AppSnackBar uses an OverlayEntry with a Dismissible toast in this app.
      expect(find.byType(Dismissible), findsNothing);
      expect(find.byType(AppointmentSuccessScreen), findsNothing);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      final inputs = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .toList();
      expect(inputs.first.controller!.text, 'Test Patient');
      expect(inputs[1].controller!.text, '501234567');
      expect(inputs.last.controller!.text, 'Please retain this inquiry');
      await tester.tap(find.text('View My Requests'));
      await tester.pumpAndSettle();
      expect(find.byType(MyRequestsScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(AppointmentRequestScreen), findsOneWidget);
      repo.pending = null;
      repo.failure = rejection({
        'error': {
          'code': 'RATE_LIMIT_EXCEEDED',
          'message': 'Request was throttled.',
          'retry_after': 61,
        },
      });
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(repo.submissions.length, 2);
      expect(repo.submissions[1], repo.submissions[0]);
      expect(
        repo.submissions.last['treatment'],
        '77777777-7777-4777-8777-777777777777',
      );
      expect(
        repo.submissions.last['practitioner'],
        '44444444-4444-4444-8444-444444444444',
      );
      expect(repo.submissions.last['consent_accepted'], isTrue);
      expect(find.byType(LeadRejectionNotice), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      // AppSnackBar uses an OverlayEntry with a Dismissible toast in this app.
      expect(find.byType(Dismissible), findsNothing);
      expect(find.textContaining('61 seconds'), findsOneWidget);
      expect(find.textContaining('blocked as a repeat'), findsNothing);
    },
  );
  testWidgets(
    'success summary uses submitted values when editable fields change during flight',
    (tester) async {
      final repo = QaLeads()..pending = Completer<LeadSubmitResult>();
      await prepareForm(tester, repo);
      await tester.tap(find.text(LocaleService().tr('submit_lead_btn')));
      await tester.pump();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Edited while waiting',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'Unsubmitted newer notes',
      );
      repo.pending!.complete(
        LeadSubmitResult(
          success: true,
          leadReference: '#REQ-1',
          confirmationMessage: 'تم إرسال طلبك وستتواصل العيادة معك',
          createdAt: DateTime.utc(2026, 10, 22),
        ),
      );
      await tester.pumpAndSettle();
      final success = tester.widget<AppointmentSuccessScreen>(
        find.byType(AppointmentSuccessScreen),
      );
      expect(
        success.request.patientFullName,
        repo.submissions.single['patient_name'],
      );
      expect(success.request.notes, repo.submissions.single['notes']);
      expect(success.request.createdAt, DateTime.utc(2026, 10, 22));
      expect(success.request.referenceCode, '#REQ-1');
    },
  );
  testWidgets(
    'empty history can refresh and initial error recovers without fabricated records',
    (tester) async {
      final repo = QaLeads()..empty = true;
      await frame(tester, MyRequestsScreen(leadsRepository: repo));
      expect(find.text(LocaleService().tr('no_requests')), findsOneWidget);
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, 500),
      );
      await tester.pumpAndSettle();
      expect(repo.reads.length, 2);
      await tester.tap(find.text('Contacted'));
      await tester.pumpAndSettle();
      expect(find.text('No requests with this status'), findsOneWidget);
      expect(find.text('No consultation requests yet'), findsNothing);
      repo.empty = false;
      repo.firstPageFails = true;
      await tester.pumpWidget(const SizedBox.shrink());
      await frame(tester, MyRequestsScreen(leadsRepository: repo));
      expect(find.text('Unable to load requests'), findsOneWidget);
      repo.firstPageFails = false;
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Source Clinic'), findsWidgets);
      expect(find.text('Unable to load requests'), findsNothing);
    },
  );
  testWidgets(
    'failed next page preserves requests and retry appends without duplicates',
    (tester) async {
      final repo = QaLeads()..nextPageFails = true;
      await frame(tester, MyRequestsScreen(leadsRepository: repo));
      await tester.drag(find.byType(ListView).first, const Offset(0, -10000));
      await tester.pumpAndSettle();
      expect(find.text('Unable to load more'), findsOneWidget);
      expect(find.text('Source Clinic'), findsWidgets);
      repo.nextPageFails = false;
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(repo.reads.where((p) => p == (2, null)).length, 2);
      await tester.drag(find.byType(ListView).first, const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(find.textContaining('Source Treatment 21'), findsOneWidget);
      expect(find.textContaining('#REQ-'), findsNothing);
    },
  );
  testWidgets(
    'Profile exposes My Requests above its expanded editing form and navigates normally',
    (tester) async {
      final repo = QaLeads();
      await frame(
        tester,
        Builder(
          builder: (context) => ProfileScreen(
            authRepository: QaAuth(),
            onNavigateToRequests: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MyRequestsScreen(leadsRepository: repo),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('toggle_edit_profile_btn')));
      await tester.pumpAndSettle();
      final requests = find.text(LocaleService().tr('my_requests_title'));
      expect(
        tester.getTopLeft(requests).dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const Key('profile_full_name_field')))
              .dy,
        ),
      );
      await capture(tester, 'profile_edit_light_en');
      await tester.tap(requests);
      await tester.pumpAndSettle();
      expect(find.byType(MyRequestsScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.byKey(const Key('profile_full_name_field')), findsOneWidget);
    },
  );
  testWidgets(
    'confirmed success reaches account history and back returns to underlying route',
    (tester) async {
      final interceptor = InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'count': 1,
              'next': null,
              'results': [historyRow(1)],
            },
          ),
        ),
      );
      ApiClient().dio.interceptors.insert(0, interceptor);
      addTearDown(() => ApiClient().dio.interceptors.remove(interceptor));
      await frame(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AppointmentSuccessScreen(
                    request: AppointmentRequestModel.fromPatientJson(
                      historyRow(1),
                    ),
                    clinic: patientClinic(),
                  ),
                ),
              ),
              child: const Text('Underlying portal'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Underlying portal'));
      await tester.pumpAndSettle();
      final view = find.text('View My Requests');
      await tester.ensureVisible(view);
      await tester.tap(view);
      await tester.pumpAndSettle();
      expect(find.byType(MyRequestsScreen), findsOneWidget);
      expect(find.textContaining('Source Treatment 1'), findsOneWidget);
      expect(find.textContaining('#REQ-'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Underlying portal'), findsOneWidget);
    },
  );
  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      testWidgets(
        'Android-sized rejection and history dark=$dark ar=$ar at 160%',
        (tester) async {
          final repo = QaLeads()
            ..failure = rejection({'detail': duplicateDetail});
          await prepareForm(tester, repo, dark: dark, ar: ar);
          await tester.tap(find.text(LocaleService().tr('submit_lead_btn')));
          await tester.pumpAndSettle();
          expect(find.byType(LeadRejectionNotice), findsOneWidget);
          expect(find.byType(SnackBar), findsNothing);
          // AppSnackBar uses an OverlayEntry with a Dismissible toast in this app.
          expect(find.byType(Dismissible), findsNothing);
          await capture(
            tester,
            'rejection_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
          );
          await tester.pumpWidget(const SizedBox.shrink());
          await frame(
            tester,
            MyRequestsScreen(leadsRepository: repo),
            dark: dark,
            ar: ar,
            scale: 1.6,
          );
          expect(tester.takeException(), isNull);
          expect(find.textContaining('#REQ-'), findsNothing);
          await capture(
            tester,
            'history_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}_large_text',
          );
        },
      );
    }
  }
}
