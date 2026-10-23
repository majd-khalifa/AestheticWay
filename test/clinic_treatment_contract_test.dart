import 'support/patient_visual_harness.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/widgets/clinic_category_manager.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/widgets/clinic_treatment_editor.dart';
import 'package:aesthetic_way/features/treatments/models/category_model.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'products_articles_live_test.dart' show FakeApiClient;

const category = CategoryModel(
  id: '11111111-1111-4111-8111-111111111111',
  nameEn: 'Skin care',
  nameAr: 'عناية بالبشرة',
  slug: 'skin-care',
);
TreatmentModel treatment() => TreatmentModel.fromJson({
  'id': '22222222-2222-4222-8222-222222222222',
  'category': category.id,
  'category_name': 'Skin care',
  'name_en': 'QA Treatment',
  'name_ar': 'إجراء اختبار',
  'price': '250.75',
  'status': 'suspended',
  'is_active': false,
  'practitioners': ['33333333-3333-4333-8333-333333333333'],
});

class Catalog implements ClinicCatalogRepository {
  final writes = <Map<String, dynamic>>[];
  Completer<TreatmentModel>? save;
  Completer<List<TreatmentModel>>? stale;
  bool reject = false;
  bool rejectDelete = false;
  @override
  Future<List<CategoryModel>> getCategories({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async => [category];
  @override
  Future<List<PractitionerModel>> getPractitioners({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async => [];
  @override
  Future<List<TreatmentModel>> getTreatments({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? category,
  }) async => stale == null ? [] : stale!.future;
  @override
  Future<TreatmentModel> createTreatment(Map<String, dynamic> data) async {
    writes.add(data);
    if (reject) {
      throw const ApiException(
        message: 'Invalid category',
        statusCode: 400,
        fieldErrors: {
          'category': ['Invalid choice'],
        },
      );
    }
    return save == null ? treatment() : save!.future;
  }

  @override
  Future<TreatmentModel> updateTreatment(
    String id,
    Map<String, dynamic> data,
  ) => createTreatment(data);
  @override
  Future<void> deleteTreatment(String id) async {
    if (rejectDelete) {
      throw const ApiException(message: 'Removal rejected', statusCode: 403);
    }
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  final service = ClinicPortalService();
  late Catalog catalog;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    LocaleService().setLanguage(AppLanguage.english);
    service.resetTestingState();
    catalog = Catalog();
    service.setCatalogRepositoryForTesting(catalog);
  });
  tearDown(() => service.resetTestingState());
  test(
    'repository never silently picks a category or clears omitted practitioner assignments',
    () async {
      final sent = <Map<String, dynamic>>[];
      var reads = 0;
      final repo = ClinicCatalogRepository(
        apiClient: FakeApiClient(
          onGet: (_, _) {
            reads++;
            return {};
          },
          onPost: (_, data) {
            sent.add(Map.from(data));
            return treatment().toPortalJson()..['id'] = treatment().id;
          },
          onPatch: (_, data) {
            sent.add(Map.from(data));
            return treatment().toPortalJson()..['id'] = treatment().id;
          },
        ),
      );
      await expectLater(
        repo.createTreatment({'name_en': 'QA'}),
        throwsA(isA<ApiException>()),
      );
      expect(reads, 0);
      expect(sent, isEmpty);
      await repo.updateTreatment(treatment().id, {'name_en': 'Updated'});
      expect(sent.single.containsKey('practitioners'), isFalse);
      expect(sent.single.containsKey('category'), isFalse);
      await repo.updateTreatment(treatment().id, {'practitioners': <String>[]});
      expect(sent.last['practitioners'], isEmpty);
    },
  );
  test(
    'acknowledged treatment survives an older GET; changed-session save cannot populate next clinic',
    () async {
      catalog.stale = Completer<List<TreatmentModel>>();
      final read = service.loadCollection('treatments');
      await service.createTreatment({'category': category.id, 'name_en': 'QA'});
      catalog.stale!.complete([]);
      await read;
      expect(service.clinicTreatments.single.id, treatment().id);
      catalog.save = Completer<TreatmentModel>();
      final save = service.createTreatment({
        'category': category.id,
        'name_en': 'Old account',
      });
      service.clearSession();
      final failure = expectLater(save, throwsA(anything));
      catalog.save!.complete(treatment());
      await failure;
      expect(service.clinicTreatments, isEmpty);
    },
  );
  test(
    'acknowledged deletion cannot be resurrected by an older GET; rejected deletion restores the row once',
    () async {
      await service.createTreatment({'category': category.id, 'name_en': 'QA'});
      catalog.stale = Completer<List<TreatmentModel>>();
      final read = service.loadCollection('treatments', refresh: true);
      await service.deleteTreatment(treatment().id);
      catalog.stale!.complete([treatment()]);
      await read;
      expect(service.clinicTreatments, isEmpty);
      catalog.stale = null;
      await service.createTreatment({'category': category.id, 'name_en': 'QA'});
      catalog.rejectDelete = true;
      await expectLater(
        service.deleteTreatment(treatment().id),
        throwsA(isA<ApiException>()),
      );
      expect(service.clinicTreatments.single.id, treatment().id);
    },
  );
  for (final dark in [false, true]) {
    for (final arabic in [false, true]) {
      testWidgets(
        'read-only category keyboard and treatment ${dark ? 'dark' : 'light'} ${arabic ? 'ar' : 'en'}',
        (tester) async {
          LocaleService().setLanguage(
            arabic ? AppLanguage.arabic : AppLanguage.english,
          );
          await tester.binding.setSurfaceSize(const Size(390, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final key = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: patientVisualTheme(dark: dark),
                builder: (context, child) => Directionality(
                  textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
                  child: child!,
                ),
                home: Directionality(
                  textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
                  child: Scaffold(
                    body: Builder(
                      builder: (context) => TextButton(
                        onPressed: () => showClinicCategoryManager(context),
                        child: const Text('Open'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          expect(find.text('Add Category'), findsNothing);
          expect(find.byIcon(Icons.delete_outline), findsNothing);
          const output = String.fromEnvironment('CLINIC_AUDIT_CAPTURE_DIR');
          Future<void> capture(String name) async {
            if (output.isEmpty) return;
            await tester.runAsync(() async {
              final image =
                  await (key.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage(pixelRatio: 1);
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              final file = File(
                '$output/${name}_${dark ? 'dark' : 'light'}_${arabic ? 'ar' : 'en'}.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(data!.buffer.asUint8List());
            });
          }

          await capture('after_categories');
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await capture('after_categories_keyboard');
          tester.view.resetViewInsets();
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          await tester.pumpWidget(
            RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: patientVisualTheme(dark: dark),
                builder: (context, child) => Directionality(
                  textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
                  child: child!,
                ),
                home: Directionality(
                  textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
                  child: Scaffold(
                    body: ClinicTreatmentEditor(existing: treatment()),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<TextFormField>(
                  find.byKey(const ValueKey('treatment-price')),
                )
                .controller!
                .text,
            '250.75',
          );
          await capture('after_treatment');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
  testWidgets(
    'treatment rejection retains input, category and practitioners; successful save omits moderation override',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(700, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(body: ClinicTreatmentEditor(existing: treatment())),
        ),
      );
      await tester.pumpAndSettle();
      final nameController = tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('treatment-name-en')),
          )
          .controller!;
      catalog.reject = true;
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('treatment-save')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('treatment-save')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Invalid category'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Invalid category'), findsOneWidget);
      expect(nameController.text, 'QA Treatment');
      expect(catalog.writes.single['category'], category.id);
      expect(
        catalog.writes.single['practitioners'],
        treatment().practitionerIds,
      );
      expect(catalog.writes.single.containsKey('status'), isFalse);
      expect(catalog.writes.single['is_active'], isFalse);
      expect(catalog.writes.single['price'], '250.75');
      catalog.save = Completer<TreatmentModel>();
      catalog.reject = false;
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('treatment-save')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('treatment-save')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('treatment-save')));
      await tester.pump();
      expect(catalog.writes, hasLength(2));
      catalog.save!.complete(treatment());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
