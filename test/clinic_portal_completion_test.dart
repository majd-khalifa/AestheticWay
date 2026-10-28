import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/services/local_media_cache.dart';
import 'package:aesthetic_way/core/theme/app_theme.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/widgets/clinic_catalog_cards.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/widgets/clinic_category_field.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/widgets/clinic_editorial_header.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_practitioners_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_treatments_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_offers_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_profile_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_dashboard_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_leads_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_lead_detail_screen.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/treatments/models/category_model.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';
import 'package:aesthetic_way/features/treatments/data/treatments_repository.dart';
import 'products_articles_live_test.dart' show FakeApiClient;

const _category = CategoryModel(
  id: 'category-a',
  nameEn: 'Skin care',
  nameAr: 'العناية بالبشرة',
  slug: 'skin-care',
);
const _remote = 'https://aestheticway.ae/media/new.png';

class _Catalog implements ClinicCatalogRepository {
  Completer<List<CategoryModel>>? listing;
  bool reject = false;
  String? categorySearch;
  @override
  Future<List<CategoryModel>> getCategories({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    categorySearch = search;
    return listing == null ? [] : listing!.future;
  }

  @override
  Future<ClinicModel> updateClinicProfile(
    Map<String, dynamic> data, {
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    if (reject) throw const ApiException(message: 'Failed');
    return ClinicModel.fromJson({
      'id': 'clinic-a',
      'name_en': 'Clinic',
      'name_ar': 'العيادة',
      'logo': _remote,
      'cover_image': null,
    });
  }

  @override
  Future<PractitionerModel> createPractitioner(
    Map<String, dynamic> data,
  ) async => PractitionerModel.fromJson({
    'id': 'doctor-a',
    'avatar_url': _remote,
    ...data,
    'avatar': null,
  });
  @override
  Future<void> deletePractitioner(String id) async {
    if (reject) throw const ApiException(message: 'Failed', statusCode: 500);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = ClinicPortalService();
  late _Catalog catalog;
  late Directory directory;
  late File image;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ApiConfig.resetBaseUrl();
    LocaleService().setLanguage(AppLanguage.english);
    service.resetTestingState();
    catalog = _Catalog();
    service.setCatalogRepositoryForTesting(catalog);
    directory = Directory.systemTemp.createTempSync('aw-local-media-');
    image = File('${directory.path}/photo.png')
      ..writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVR4nGN8ZuT2n4GBgYGJAQoAJKgCYaRJeyUAAAAASUVORK5CYII=',
        ),
      );
  });
  tearDown(() {
    service.resetTestingState();
    ApiConfig.resetBaseUrl();
    directory.deleteSync(recursive: true);
  });
  test(
    'production HTTP and duplicated media slashes become HTTPS, query bytes unchanged',
    () {
      expect(
        ApiConfig.resolveUrl(
          'http://aestheticway.ae//media//photo.png?sig=a%2Fb+z',
        ),
        'https://aestheticway.ae/media/photo.png?sig=a%2Fb+z',
      );
      expect(
        ApiConfig.resolveUrl('http://www.aestheticway.ae:80/media/a.png'),
        'https://www.aestheticway.ae/media/a.png',
      );
      expect(
        resolveNetworkImageUrl('media//a.png'),
        'https://aestheticway.ae/media/a.png',
      );
      expect(
        resolveNetworkImageUrl('/media//a.png'),
        'https://aestheticway.ae/media/a.png',
      );
      expect(
        resolveNetworkImageUrl('//media//a.png'),
        'https://aestheticway.ae/media/a.png',
      );
      const signed =
          'http://bucket.r2.dev//image%2Fname.png?X-Amz-Signature=A%2Fb&x=a+b';
      expect(ApiConfig.resolveUrl(signed), signed);
      expect(
        ApiConfig.resolveUrl('https://bucket.r2.dev/a.png?sig=a%2Fb'),
        'https://bucket.r2.dev/a.png?sig=a%2Fb',
      );
      ApiConfig.setBaseUrl('http://localhost:8000/api/v1/');
      expect(
        ApiConfig.resolveUrl('/media/a.png'),
        'http://localhost:8000/media/a.png',
      );
    },
  );
  test(
    'cache binds entity and both URL schemes; replacement, stale URL and missing file are safe',
    () {
      final cache = LocalMediaCache();
      expect(
        cache.remember(
          localPath: image.path,
          entityKey: 'clinic_logo_a',
          remoteUrl: 'http://aestheticway.ae/media/a.png',
        ),
        isTrue,
      );
      expect(cache.lookup(entityKey: 'clinic_logo_a'), image.path);
      expect(
        cache.lookup(remoteUrl: 'https://aestheticway.ae/media/a.png'),
        image.path,
      );
      expect(
        cache.lookup(remoteUrl: 'http://aestheticway.ae/media/a.png'),
        image.path,
      );
      expect(
        cache.lookup(
          entityKey: 'clinic_logo_a',
          remoteUrl: 'https://aestheticway.ae/media/other.png',
        ),
        isNull,
      );
      cache.remember(
        localPath: image.path,
        entityKey: 'clinic_logo_a',
        remoteUrl: _remote,
      );
      expect(
        cache.lookup(remoteUrl: 'https://aestheticway.ae/media/a.png'),
        isNull,
      );
      cache.remember(
        localPath: image.path,
        entityKey: 'product_a',
        remoteUrl:
            'https://cdn.example.com/photo.png?versionId=v1&X-Amz-Signature=old&X-Amz-Date=20261020',
      );
      expect(
        cache.lookup(
          entityKey: 'product_a',
          remoteUrl:
              'https://cdn.example.com/photo.png?versionId=v1&X-Amz-Signature=new&X-Amz-Date=20261021',
        ),
        image.path,
      );
      expect(
        cache.lookup(
          entityKey: 'product_a',
          remoteUrl:
              'https://cdn.example.com/photo.png?versionId=v2&X-Amz-Signature=new',
        ),
        isNull,
      );
      image.deleteSync();
      expect(cache.lookup(entityKey: 'clinic_logo_a'), isNull);
      expect(cache.lookup(remoteUrl: _remote), isNull);
    },
  );
  test(
    'cache is bounded, does not delete files, clears on logout and rejects old-session upload',
    () {
      final cache = LocalMediaCache();
      for (var i = 0; i < LocalMediaCache.maxEntries + 1; i++) {
        cache.remember(
          localPath: image.path,
          entityKey: 'offer_$i',
          remoteUrl: 'https://example.com/$i.png',
        );
      }
      expect(cache.lookup(entityKey: 'offer_0'), isNull);
      final epoch = cache.epoch;
      AuthState().logout();
      expect(
        cache.lookup(entityKey: 'offer_${LocalMediaCache.maxEntries}'),
        isNull,
      );
      expect(
        cache.remember(
          localPath: image.path,
          remoteUrl: _remote,
          expectedEpoch: epoch,
        ),
        isFalse,
      );
      expect(image.existsSync(), isTrue);
    },
  );
  test(
    'profile direct upload caches only acknowledged saves and clears explicit removal',
    () async {
      service.setActiveClinicForTesting(
        ClinicModel.fromJson({'id': 'clinic-a'}),
      );
      Future<void> save({bool remove = false}) => service.updateClinicProfile(
        nameAr: 'العيادة',
        nameEn: 'Clinic',
        descriptionAr: '',
        descriptionEn: '',
        phone: '',
        whatsapp: '',
        logo: remove ? null : image.path,
        clearLogo: remove,
      );
      catalog.reject = true;
      await expectLater(save(), throwsA(isA<ApiException>()));
      expect(
        LocalMediaCache().lookup(
          entityKey: LocalMediaCache.clinicLogo('clinic-a'),
        ),
        isNull,
      );
      catalog.reject = false;
      await save();
      expect(
        LocalMediaCache().lookup(
          entityKey: LocalMediaCache.clinicLogo('clinic-a'),
        ),
        image.path,
      );
      expect(LocalMediaCache().lookup(remoteUrl: _remote), image.path);
      await save(remove: true);
      expect(LocalMediaCache().lookup(remoteUrl: _remote), isNull);
    },
  );
  test(
    'failed deletes keep cached media; acknowledged deletes clear it',
    () async {
      final created = await service.createPractitioner({'avatar': image.path});
      final key = LocalMediaCache.entity('practitioner', created.id);
      expect(LocalMediaCache().lookup(entityKey: key), image.path);
      catalog.reject = true;
      await expectLater(
        service.deletePractitioner(created.id),
        throwsA(isA<ApiException>()),
      );
      expect(LocalMediaCache().lookup(entityKey: key), image.path);
      expect(
        service.clinicPractitioners.any((p) => p.id == created.id),
        isTrue,
      );
      catalog.reject = false;
      await service.deletePractitioner(created.id);
      expect(LocalMediaCache().lookup(entityKey: key), isNull);
      expect(image.existsSync(), isTrue);
    },
  );

  testWidgets(
    'LuxuryImage and LuxuryAvatar prefer cached files over a broken remote URL',
    (tester) async {
      final key = LocalMediaCache.entity('practitioner', 'a');
      LocalMediaCache().remember(
        localPath: image.path,
        entityKey: key,
        remoteUrl: _remote,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LuxuryImage(
                  imageUrl: _remote,
                  mediaCacheKey: key,
                  width: 68,
                  height: 68,
                ),
                LuxuryAvatar(imageUrl: _remote, mediaCacheKey: key),
              ],
            ),
          ),
        ),
      );
      for (final widget in tester.widgetList<Image>(find.byType(Image))) {
        final provider = widget.image is ResizeImage
            ? (widget.image as ResizeImage).imageProvider
            : widget.image;
        expect(provider, isA<FileImage>());
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  test(
    'unsupported category writes fail locally without probing public or clinic routes',
    () async {
      final paths = <String>[];
      final api = FakeApiClient(
        onGet: (_, _) => {},
        onPost: (path, data) {
          paths.add(path);
          return {};
        },
        onPatch: (path, data) {
          paths.add(path);
          return {};
        },
        onDelete: (path) {
          paths.add(path);
        },
      );
      final repo = ClinicCatalogRepository(apiClient: api);
      for (final write in [
        () => repo.createCategory(
          nameEn: ' skin care ',
          nameAr: ' عناية بالبشرة ',
        ),
        () =>
            repo.updateCategory(_category.id, nameEn: 'Skin', nameAr: 'البشرة'),
        () => repo.deleteCategory(_category.id),
        () => TreatmentsRepository(
          apiClient: api,
        ).createCategory(nameEn: 'Skin', nameAr: 'البشرة'),
      ]) {
        await expectLater(
          write(),
          throwsA(
            isA<ApiException>().having(
              (e) => e.errorCode,
              'contract guard',
              'CATEGORY_WRITES_UNSUPPORTED',
            ),
          ),
        );
      }
      expect(paths, isEmpty);
    },
  );
  test(
    'category read errors retain safe typed status/field feedback and never try writes',
    () async {
      for (final code in [400, 403, 404, 405, 409, 500]) {
        var reads = 0;
        final repo = ClinicCatalogRepository(
          apiClient: FakeApiClient(
            onGet: (_, _) {
              reads++;
              throw ApiException(
                message: 'Rejected',
                statusCode: code,
                fieldErrors: const {
                  'name_en': ['Invalid input'],
                },
              );
            },
          ),
        );
        await expectLater(
          repo.getCategories(),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'status', code)
                .having(
                  (e) => e.getFieldError('name_en'),
                  'safe field error',
                  'Invalid input',
                ),
          ),
        );
        expect(reads, 1);
      }
    },
  );
  test(
    'category search/pagination and existing records survive all blocked mutations',
    () async {
      Map<String, dynamic>? query;
      final repo = ClinicCatalogRepository(
        apiClient: FakeApiClient(
          onGet: (_, q) {
            query = q;
            return {'results': [], 'next': null};
          },
        ),
      );
      await repo.getCategories(page: 3, search: ' skin ');
      expect(query!['page'], 3);
      expect(query!['search'], 'skin');
      catalog.listing = Completer<List<CategoryModel>>()..complete([_category]);
      await service.loadCollection('categories');
      for (final write in [
        () => service.createCategory(nameEn: 'Skin', nameAr: 'البشرة'),
        () => service.updateCategory(
          _category.id,
          nameEn: 'Skin',
          nameAr: 'البشرة',
        ),
        () => service.deleteCategory(_category.id),
      ]) {
        await expectLater(write(), throwsA(isA<ApiException>()));
        expect(service.categories.single, _category);
      }
    },
  );
  testWidgets(
    'read-only category directory selects an existing UUID without add/edit/delete controls',
    (tester) async {
      catalog.listing = Completer<List<CategoryModel>>()..complete([_category]);
      await service.loadCollection('categories');
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setLocal) => ClinicCategoryField(
                categories: service.categories,
                value: selected,
                valueLabel: '',
                onChanged: (c) => setLocal(() => selected = c?.id),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Add Category'), findsNothing);
      await tester.tap(find.text('Browse all categories'));
      await tester.pumpAndSettle();
      expect(find.textContaining('shared across the platform'), findsOneWidget);
      expect(find.text('Add New Category'), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      await tester.tap(find.text(_category.nameEn).last);
      await tester.pumpAndSettle();
      expect(selected, _category.id);
      expect(service.categories.single, _category);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'closing category directory preserves a previously selected category',
    (tester) async {
      catalog.listing = Completer<List<CategoryModel>>()..complete([_category]);
      await service.loadCollection('categories');
      CategoryModel? selected = _category;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicCategoryField(
              categories: service.categories,
              value: selected.id,
              valueLabel: selected.nameEn,
              onChanged: (c) => selected = c,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Browse all categories'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(selected, _category);
      expect(tester.takeException(), isNull);
    },
  );
  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      testWidgets(
        'responsive clinic cards ${dark ? 'dark' : 'light'} ${ar ? 'ar' : 'en'}',
        (tester) async {
          LocaleService().setLanguage(
            ar ? AppLanguage.arabic : AppLanguage.english,
          );
          await tester.binding.setSurfaceSize(const Size(320, 1800));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final p = PractitionerModel.fromJson({
            'id': 'p-a',
            'name_en': 'Dr. Sarah Al Mansoori',
            'name_ar': 'د. سارة المنصوري',
            'title_en': 'Consultant Dermatologist',
            'title_ar': 'استشارية جلدية',
            'speciality_en': 'Dermatology',
            'speciality_ar': 'الجلدية',
            'bio_en': 'Individual care with extensive clinical experience.',
            'bio_ar': 'رعاية فردية وخبرة طبية واسعة.',
            'type': 'doctor',
          });
          final t = TreatmentModel.fromJson({
            'id': 't-a',
            'name_en': 'Medical HydraFacial',
            'name_ar': 'هيدرافاشيال طبي',
            'price': '850',
            'category_name_en': 'Skin Care',
            'category_name_ar': 'العناية بالبشرة',
            'description_en': 'A tailored skin treatment.',
            'description_ar': 'علاج مخصص للبشرة.',
            'practitioners': ['p-a'],
          });
          final o = OfferModel.fromJson({
            'id': 'o-a',
            'title_en': 'Summer Glow',
            'title_ar': 'نضارة الصيف',
            'original_price': '1000',
            'offer_price': '750',
            'starts_at': '2026-10-01T00:00:00Z',
            'ends_at': '2026-11-01T00:00:00Z',
          });
          var edits = 0, deletes = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 1800),
                  textScaler: TextScaler.linear(1.6),
                ),
                child: Directionality(
                  textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
                  child: Scaffold(
                    body: SingleChildScrollView(
                      child: Column(
                        children: [
                          ClinicPractitionerCard(
                            practitioner: p,
                            onEdit: () => edits++,
                            onDelete: () => deletes++,
                          ),
                          ClinicTreatmentCard(
                            treatment: t,
                            practitioners: [p],
                            onEdit: () {},
                            onDelete: () {},
                          ),
                          ClinicOfferCard(
                            offer: o,
                            onEdit: () {},
                            onDelete: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final photo = tester.widget<LuxuryImage>(
            find.descendant(
              of: find.byType(ClinicPractitionerCard),
              matching: find.byType(LuxuryImage),
            ),
          );
          expect(photo.width, 68);
          expect(photo.mediaCacheKey, 'practitioner_p-a');
          await tester.tap(find.text(ar ? 'تعديل' : 'Edit').first);
          await tester.tap(find.text(ar ? 'حذف' : 'Delete').first);
          expect(edits, 1);
          expect(deletes, 1);
          expect(
            find.text(ar ? 'استشارية جلدية' : 'Consultant Dermatologist'),
            findsOneWidget,
          );
          expect(find.text('850 AED'), findsOneWidget);
          expect(find.text(ar ? 'خصم 25٪' : '25% OFF'), findsOneWidget);
          expect(find.textContaining('DHA'), findsNothing);
          expect(find.textContaining('license_number'), findsNothing);
        },
      );
    }
  }
  testWidgets(
    'failed clinic cover keeps gradient rather than an extra emblem',
    (tester) async {
      final clinic = ClinicModel.fromJson({
        'id': 'a',
        'cover_image': 'https://example.com/missing.png',
        'logo': '',
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicEditorialHeader(clinic: clinic, onEdit: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final emblems = tester.widgetList<Image>(find.byType(Image)).where((w) {
        final provider = w.image is ResizeImage
            ? (w.image as ResizeImage).imageProvider
            : w.image;
        return provider is AssetImage &&
            provider.assetName == 'assets/images/aesthetic_way_logo.png';
      });
      expect(emblems, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  for (final dark in [false, true]) {
    testWidgets(
      'all clinic screens render with narrow enlarged text ${dark ? 'dark' : 'light'}',
      (tester) async {
        service.enableMockMode();
        final lead = service.clinicLeads.first;
        await tester.binding.setSurfaceSize(const Size(360, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final screens = <Widget>[
          const ClinicPractitionersScreen(),
          const ClinicTreatmentsScreen(),
          const ClinicOffersScreen(),
          const ClinicLeadsScreen(),
          ClinicLeadDetailScreen(lead: lead),
          const ClinicProfileScreen(),
          ClinicDashboardScreen(
            onNavigateToLeads: () {},
            onNavigateToOffers: () {},
          ),
        ];
        for (final screen in screens) {
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: screen,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType}',
          );
        }
      },
    );
  }
}
