import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_practitioners_screen.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'onboarding_review_workflows_test.dart' as f;
import 'support/patient_visual_harness.dart';
import 'clinic_media_contract_test.dart' show finishNativeWork;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  late ApiClient api;
  late HttpClientAdapter old;
  late ClinicCatalogRepository repo;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clear();
    AuthState().login(
      name: 'Disposable QA',
      phone: 'fixture',
      role: 'clinic_admin',
    );
    api = ApiClient();
    old = api.dio.httpClientAdapter;
    repo = ClinicCatalogRepository(apiClient: api);
    final service = ClinicPortalService()..resetTestingState();
    service.setCatalogRepositoryForTesting(repo);
    service.setActiveClinicForTesting(ClinicModel.fromJson(f.clinic()));
  });
  tearDown(() {
    api.dio.httpClientAdapter = old;
    ClinicPortalService().resetTestingState();
    AuthState().logout();
  });
  test(
    'blank API title stays blank through edit/serialization despite a long display specialty',
    () {
      final p = PractitionerModel.fromJson({
        'name_en': 'Disposable nurse',
        'name_ar': '',
        'type': 'nurse',
        'title_en': '',
        'title_ar': '',
        'speciality_en': 'x' * 120,
        'speciality_ar': '',
        'bio_en': 'Actual English',
        'bio_ar': '',
      });
      expect(
        p.classificationEn,
        'x' * 120,
        reason: 'Existing patient display fallback is preserved.',
      );
      expect(p.editableText('title_en', p.classificationEn ?? ''), '');
      expect(p.toPortalJson()['title_en'], '');
      expect(p.toPortalJson()['name_ar'], '');
      expect(p.toPortalJson()['bio_ar'], '');
      expect(p.copyWith(status: 'inactive').toPortalJson()['title_en'], '');
      expect(
        p.copyWith(classificationEn: 'Actual title').toPortalJson()['title_en'],
        'Actual title',
      );
    },
  );
  for (final type in ['doctor', 'nurse', 'licensed_professional']) {
    test(
      '$type without portrait creates, edits and survives a new repository read and page2',
      () async {
        final saved = <String, dynamic>{
          'id': f.proposalId,
          'name_en': 'Disposable',
          'name_ar': 'اختبار',
          'type': type,
          'status': 'active',
        };
        final wire = f.Adapter((r) {
          if (r.method != 'GET') {
            saved.addAll(Map<String, dynamic>.from(r.data as Map));
          }
          return f.body(
            r.method == 'GET' ? f.page([saved]) : saved,
            r.method == 'POST' ? 201 : 200,
          );
        });
        api.dio.httpClientAdapter = wire;
        expect((await repo.createPractitioner({...saved})).type.value, type);
        expect((wire.requests.first.data as Map).containsKey('avatar'), false);
        expect(
          (wire.requests.first.data as Map).containsKey('media_asset'),
          false,
        );
        await repo.updatePractitioner(f.proposalId, {'bio_en': 'Saved edit'});
        final fresh = await ClinicCatalogRepository(
          apiClient: api,
        ).getPractitioners(page: 2);
        expect(fresh.single.aboutEn, 'Saved edit');
        expect(wire.requests.last.queryParameters['page'], 2);
      },
    );
  }
  Future<Finder> open(WidgetTester t, {bool ar = false}) async {
    await f.render(t, const ClinicPractitionersScreen(), ar: ar);
    await t.tap(find.text(ar ? 'إضافة ممارس' : 'Add Practitioner').first);
    await t.pumpAndSettle();
    return find
        .descendant(of: find.byType(Form), matching: find.byType(Scrollable))
        .first;
  }

  Future<void> field(
    WidgetTester t,
    Finder scroll,
    String label,
    String value,
  ) async {
    final target = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
    );
    final p = t.state<ScrollableState>(scroll).position;
    for (var i = 0; i < 20 && target.evaluate().isEmpty; i++) {
      p.jumpTo((p.pixels + 180).clamp(0, p.maxScrollExtent));
      await t.pump();
    }
    await t.ensureVisible(target);
    await t.enterText(target, value);
  }

  testWidgets(
    'Nurse with no photo and120-character specialty does not invent an overlong title',
    (t) async {
      Map<String, dynamic>? stored;
      final wire = f.Adapter((r) {
        if (r.method != 'GET') {
          stored = {
            'id': f.proposalId,
            ...?stored,
            ...Map<String, dynamic>.from(r.data as Map),
          };
        }
        return f.body(
          r.method == 'GET' ? f.page(stored == null ? [] : [stored!]) : stored!,
          r.method == 'POST' ? 201 : 200,
        );
      });
      api.dio.httpClientAdapter = wire;
      final scroll = await open(t);
      await t.tap(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField).first,
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Nurse').last);
      await t.pumpAndSettle();
      await field(t, scroll, 'Full Name (English) *', 'Disposable nurse');
      await field(t, scroll, 'Full Name (Arabic, optional)', 'ممرض اختبار');
      await field(t, scroll, 'Specialty (English)', 'x' * 120);
      final p = t.state<ScrollableState>(scroll).position;
      for (var i = 0; i < 4; i++) {
        p.jumpTo(p.maxScrollExtent);
        await t.pump();
      }
      await t.tap(find.text('Save Practitioner'));
      await t.pumpAndSettle();
      final payload =
          wire.requests.singleWhere((r) => r.method == 'POST').data as Map;
      expect(payload['type'], 'nurse');
      expect(payload['title_en'], '');
      expect(payload['speciality_en'], 'x' * 120);
      expect(payload.containsKey('avatar'), false);
      expect(find.byType(Form), findsNothing);
      await t.ensureVisible(find.text('Edit'));
      await t.tap(find.text('Edit'));
      await t.pumpAndSettle();
      final title = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == 'Professional Title (English)',
      );
      await t.ensureVisible(title);
      expect(t.widget<TextField>(title).controller!.text, '');
      final editScroll = find
          .descendant(of: find.byType(Form), matching: find.byType(Scrollable))
          .first;
      await field(
        t,
        editScroll,
        'Bio (English)',
        'Persisted edited nursing bio',
      );
      final position = t.state<ScrollableState>(editScroll).position;
      for (var i = 0; i < 4; i++) {
        position.jumpTo(position.maxScrollExtent);
        await t.pump();
      }
      await t.tap(find.text('Update'));
      await t.pumpAndSettle();
      expect(
        (wire.requests.singleWhere((r) => r.method == 'PATCH').data
            as Map)['title_en'],
        '',
      );
      List<PractitionerModel>? readBack;
      final fresh = repo.getPractitioners().then((rows) => readBack = rows);
      await finishNativeWork(t, () => readBack != null);
      await fresh;
      expect(readBack!.single.aboutEn, 'Persisted edited nursing bio');

      await t.pumpWidget(const SizedBox());
      await t.binding.setSurfaceSize(null);
    },
  );
  for (final ar in [false, true]) {
    testWidgets(
      'field validation exposes HTTP400 safely and preserves entered names ar=$ar',
      (t) async {
        api.dio.httpClientAdapter = f.Adapter(
          (r) => r.method == 'POST'
              ? f.body({
                  'error': {
                    'code': 'VALIDATION_ERROR',
                    'message': 'One or more fields failed validation.',
                    'fields': {
                      'name_en': [
                        'Ensure this field has no more than 200 characters.',
                      ],
                      'type': ['"private-token-value" is not a valid choice.'],
                    },
                  },
                }, 400)
              : f.body(f.page([])),
        );
        final scroll = await open(t, ar: ar);
        await field(
          t,
          scroll,
          ar ? 'الاسم الكامل بالإنجليزية *' : 'Full Name (English) *',
          'Preserved nurse',
        );
        final p = t.state<ScrollableState>(scroll).position;
        for (var i = 0; i < 4; i++) {
          p.jumpTo(p.maxScrollExtent);
          await t.pump();
        }
        await t.tap(find.text(ar ? 'إضافة الممارس' : 'Save Practitioner'));
        await t.pumpAndSettle();
        p.jumpTo(0);
        await t.pumpAndSettle();
        expect(find.textContaining('HTTP 400'), findsOneWidget);
        expect(find.textContaining('private-token-value'), findsNothing);
        expect(find.byType(Form), findsOneWidget);
        await field(
          t,
          scroll,
          ar ? 'الاسم الكامل بالإنجليزية *' : 'Full Name (English) *',
          'Corrected nurse',
        );
        expect(find.text('Corrected nurse'), findsOneWidget);
        await t.pumpWidget(const SizedBox());
        await t.binding.setSurfaceSize(null);
      },
    );
  }
  test(
    'known field allowlist localizes enum and media errors without retaining raw values',
    () {
      final e = ApiException.fromDioError(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 400,
            data: {
              'type': ['"private-value" is not a valid choice.'],
              'media_asset': [
                'Invalid pk "private-value" - object does not exist.',
              ],
            },
          ),
        ),
      );
      expect(e.fieldErrors!.keys, containsAll(['type', 'media_asset']));
      expect(e.message, isNot(contains('private-value')));
    },
  );
}
