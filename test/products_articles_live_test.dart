import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/theme/app_theme.dart';
import 'package:aesthetic_way/core/widgets/ltr_text_field.dart';
import 'package:aesthetic_way/core/widgets/luxury_image_picker_field.dart';
import 'package:aesthetic_way/features/articles/data/articles_repository.dart';
import 'package:aesthetic_way/features/articles/models/article_model.dart';
import 'package:aesthetic_way/features/articles/presentation/screens/article_detail_screen.dart';
import 'package:aesthetic_way/features/articles/presentation/screens/articles_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_profile_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/products/data/products_repository.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/products/presentation/screens/product_detail_screen.dart';
import 'package:aesthetic_way/features/products/presentation/screens/products_screen.dart';

class FakeApiClient implements ApiClient {
  @override
  late Dio dio = Dio();

  @override
  void updateBaseUrl(String newBaseUrl) {}

  final Map<String, dynamic> Function(String path, Map<String, dynamic>? query)
  onGet;
  final Map<String, dynamic> Function(String path, dynamic data)? onPost;
  final Map<String, dynamic> Function(String path, dynamic data)? onPatch;
  final void Function(String path)? onDelete;

  FakeApiClient({
    required this.onGet,
    this.onPost,
    this.onPatch,
    this.onDelete,
  });

  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final res = onPatch != null ? onPatch!(path, data) : <String, dynamic>{};
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: res as T,
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final res = onGet(path, queryParameters);
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: res as T,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final res = onPost != null ? onPost!(path, data) : <String, dynamic>{};
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 201,
      data: res as T,
    );
  }

  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    final res = onPatch != null ? onPatch!(path, data) : <String, dynamic>{};
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: res as T,
    );
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (onDelete != null) onDelete!(path);
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 204,
    );
  }
}

void main() {
  setUp(() {
    LocaleService().setLanguage(AppLanguage.arabic);
    ClinicPortalService().resetTestingState();
  });

  group('ProductModel & ArticleModel Serialization Tests', () {
    test(
      'ProductModel parses public and portal JSON and generates exact portal payload',
      () {
        final json = {
          'id': 'prod-uuid-1',
          'name_en': 'Hyaluronic Acid Serum',
          'name_ar': 'سيروم حمض الهيالورونيك',
          'description_en': 'Deep hydration serum',
          'description_ar': 'سيروم ترطيب عميق',
          'price': '250.00',
          'image_url': 'https://example.com/serum.jpg',
          'status': 'active',
          'is_active': true,
          'clinic': {
            'id': 'clinic-uuid-1',
            'name_en': 'Royal Derm Clinic',
            'name_ar': 'عيادة رويال ديرم',
            'city': 'Dubai',
          },
          'created_at': '2026-09-20T10:00:00Z',
        };

        final product = ProductModel.fromJson(json);
        expect(product.id, 'prod-uuid-1');
        expect(product.nameEn, 'Hyaluronic Acid Serum');
        expect(product.nameAr, 'سيروم حمض الهيالورونيك');
        expect(product.price, 250.0);
        expect(product.clinicId, 'clinic-uuid-1');
        expect(product.clinicNameAr, 'عيادة رويال ديرم');
        expect(product.isAvailable, isTrue);

        final portalPayload = product.toPortalJson();
        expect(portalPayload['name_en'], 'Hyaluronic Acid Serum');
        expect(portalPayload['name_ar'], 'سيروم حمض الهيالورونيك');
        expect(portalPayload.containsKey('price'), isFalse);
        expect(portalPayload['image'], 'https://example.com/serum.jpg');
        expect(portalPayload['is_active'], isTrue);
        expect(portalPayload.containsKey('category'), isFalse);
        expect(portalPayload.containsKey('original_price'), isFalse);
      },
    );

    test('ArticleModel parses public nested author and portal UUID author', () {
      final publicJson = {
        'id': 'art-uuid-1',
        'slug': 'benefits-of-hyaluronic-acid',
        'title_en': 'Benefits of Hyaluronic Acid',
        'title_ar': 'فوائد حمض الهيالورونيك',
        'content_en': 'Detailed medical skin guide.',
        'content_ar': 'دليل طبي مفصل للبشرة.',
        'cover_image_url': 'https://example.com/cover.jpg',
        'published_at': '2026-09-21T12:00:00Z',
        'clinic': {
          'id': 'clinic-uuid-1',
          'name_en': 'Royal Derm Clinic',
          'name_ar': 'عيادة رويال ديرم',
        },
        'author_practitioner': {
          'id': 'doc-uuid-1',
          'name_en': 'Dr. Layla',
          'name_ar': 'د. ليلى',
          'title_en': 'Dermatologist',
          'title_ar': 'طبيبة جلدية',
          'avatar_url': 'https://example.com/doc.jpg',
        },
      };

      final articlePublic = ArticleModel.fromJson(publicJson);
      expect(articlePublic.id, 'art-uuid-1');
      expect(articlePublic.slug, 'benefits-of-hyaluronic-acid');
      expect(articlePublic.authorDoctorId, 'doc-uuid-1');
      expect(articlePublic.authorDoctorNameEn, 'Dr. Layla');
      expect(articlePublic.authorDoctorNameAr, 'د. ليلى');

      final portalJson = {
        'id': 'art-uuid-2',
        'title_en': 'Laser Post-Care',
        'content_en': 'Use sunscreen daily.',
        'author_practitioner': 'doc-uuid-1',
        'is_published': false,
        'status': 'active',
      };

      final articlePortal = ArticleModel.fromJson(portalJson);
      expect(articlePortal.id, 'art-uuid-2');
      expect(articlePortal.authorDoctorId, 'doc-uuid-1');
      expect(articlePortal.isPublished, isFalse);

      final outPayload = articlePortal.toPortalJson();
      expect(outPayload['title_en'], 'Laser Post-Care');
      expect(outPayload['author_practitioner'], 'doc-uuid-1');
      expect(outPayload['is_published'], isFalse);
      expect(outPayload.containsKey('category'), isFalse);
      expect(outPayload.containsKey('summary'), isFalse);
    });
  });

  group('ProductsRepository & ArticlesRepository Live API Tests', () {
    test(
      'ProductsRepository fetches list and detail from /api/v1/products/',
      () async {
        String? capturedPath;
        Map<String, dynamic>? capturedQuery;

        final fakeClient = FakeApiClient(
          onGet: (path, query) {
            capturedPath = path;
            capturedQuery = query;
            if (path == 'products/') {
              return {
                'count': 1,
                'results': [
                  {
                    'id': 'p-101',
                    'name_en': 'SPF 50+ Sunblock',
                    'name_ar': 'واقي شمس 50+',
                    'price': '180.00',
                    'image_url': 'https://example.com/spf.jpg',
                  },
                ],
              };
            }
            return {
              'id': 'p-101',
              'name_en': 'SPF 50+ Sunblock',
              'name_ar': 'واقي شمس 50+',
              'price': '180.00',
            };
          },
        );

        final repo = ProductsRepository(apiClient: fakeClient);
        final list = await repo.getProducts(clinicId: 'c-1', search: 'SPF');
        expect(capturedPath, 'products/');
        expect(capturedQuery?['clinic_id'], 'c-1');
        expect(capturedQuery?['search'], 'SPF');
        expect(list.length, 1);
        expect(list.first.nameEn, 'SPF 50+ Sunblock');

        final detail = await repo.getProductDetail('p-101');
        expect(capturedPath, 'products/p-101/');
        expect(detail.id, 'p-101');
      },
    );

    test(
      'ArticlesRepository fetches list and detail from /api/v1/articles/',
      () async {
        String? capturedPath;
        Map<String, dynamic>? capturedQuery;

        final fakeClient = FakeApiClient(
          onGet: (path, query) {
            capturedPath = path;
            capturedQuery = query;
            if (path == 'articles/') {
              return {
                'count': 1,
                'results': [
                  {
                    'id': 'a-202',
                    'title_en': 'Hydration Tips',
                    'title_ar': 'نصائح الترطيب',
                    'content_en': 'Drink water and use HA serum.',
                    'slug': 'hydration-tips',
                  },
                ],
              };
            }
            return {
              'id': 'a-202',
              'title_en': 'Hydration Tips',
              'slug': 'hydration-tips',
            };
          },
        );

        final repo = ArticlesRepository(apiClient: fakeClient);
        final list = await repo.getArticles(
          practitionerId: 'doc-1',
          search: 'Hydration',
        );
        expect(capturedPath, 'articles/');
        expect(capturedQuery?['practitioner_id'], 'doc-1');
        expect(capturedQuery?['search'], 'Hydration');
        expect(list.length, 1);
        expect(list.first.slug, 'hydration-tips');

        final detail = await repo.getArticleDetail('hydration-tips');
        expect(capturedPath, 'articles/hydration-tips/');
        expect(detail.id, 'a-202');
      },
    );
  });

  group('ClinicPortalService Products & Articles CRUD Tests', () {
    test(
      'ClinicPortalService executes live create, update, toggle, and delete via ClinicCatalogRepository',
      () async {
        bool deleteProductCalled = false;
        bool deleteArticleCalled = false;

        final fakeClient = FakeApiClient(
          onGet: (path, _) => {'results': []},
          onPost: (path, data) {
            final body = data as Map<String, dynamic>;
            if (path == 'clinic-portal/products/') {
              return {
                'id': 'live-prod-1',
                'name_en': body['name_en'],
                'name_ar': body['name_ar'] ?? body['name_en'],
                'price': body['price'] ?? '200.00',
                'is_active': true,
                'status': 'active',
              };
            }
            return {
              'id': 'live-art-1',
              'title_en': body['title_en'],
              'title_ar': body['title_ar'] ?? body['title_en'],
              'content_en': body['content_en'] ?? '',
              'is_published': true,
              'status': 'active',
            };
          },
          onPatch: (path, data) {
            final body = data as Map<String, dynamic>;
            if (path.startsWith('clinic-portal/products/')) {
              return {
                'id': 'live-prod-1',
                'name_en': body['name_en'] ?? 'Updated Serum',
                'price': '200.00',
                'is_active': body['is_active'] ?? false,
                'status': 'active',
              };
            }
            return {
              'id': 'live-art-1',
              'title_en': body['title_en'] ?? 'Updated Article',
              'content_en': 'Body',
              'is_published': body['is_published'] ?? false,
              'status': 'active',
            };
          },
          onDelete: (path) {
            if (path == 'clinic-portal/products/live-prod-1/') {
              deleteProductCalled = true;
            }
            if (path == 'clinic-portal/articles/live-art-1/') {
              deleteArticleCalled = true;
            }
          },
        );

        final catalogRepo = ClinicCatalogRepository(apiClient: fakeClient);
        final service = ClinicPortalService();
        service.setCatalogRepositoryForTesting(catalogRepo);

        // Create Product
        final createdProd = await service.createProduct({
          'name_en': 'Retinol Night Cream',
          'price': '310.00',
        });
        expect(createdProd.id, 'live-prod-1');
        expect(
          service.clinicProducts.any((p) => p.id == 'live-prod-1'),
          isTrue,
        );

        // Toggle Product Availability
        await service.toggleProductAvailability('live-prod-1');
        final updatedProd = service.clinicProducts.firstWhere(
          (p) => p.id == 'live-prod-1',
        );
        expect(updatedProd.isAvailable, isFalse);

        // Delete Product
        await service.deleteProduct('live-prod-1');
        expect(deleteProductCalled, isTrue);
        expect(
          service.clinicProducts.any((p) => p.id == 'live-prod-1'),
          isFalse,
        );

        // Create Article
        final createdArt = await service.createArticle({
          'title_en': 'Retinol Guide',
          'content_en': 'Apply at night.',
        });
        expect(createdArt.id, 'live-art-1');
        expect(service.clinicArticles.any((a) => a.id == 'live-art-1'), isTrue);

        // Toggle Article Publish
        await service.toggleArticlePublish('live-art-1');
        final updatedArt = service.clinicArticles.firstWhere(
          (a) => a.id == 'live-art-1',
        );
        expect(updatedArt.isPublished, isFalse);

        // Delete Article
        await service.deleteArticle('live-art-1');
        expect(deleteArticleCalled, isTrue);
        expect(
          service.clinicArticles.any((a) => a.id == 'live-art-1'),
          isFalse,
        );
      },
    );

    test(
      'ClinicCatalogRepository strips empty price and transmits brand metadata',
      () async {
        Map<String, dynamic>? postedData;
        final fakeClient = FakeApiClient(
          onGet: (path, _) => {'results': []},
          onPost: (path, data) {
            postedData = data as Map<String, dynamic>;
            return {
              'id': 'brand-prod-99',
              'name_en': postedData?['name_en'],
              'brand_name_en': postedData?['brand_name_en'],
              'brand_name_ar': postedData?['brand_name_ar'],
              'sponsor_company': postedData?['sponsor_company'],
              'is_active': true,
            };
          },
        );
        final catalogRepo = ClinicCatalogRepository(apiClient: fakeClient);
        final created = await catalogRepo.createProduct({
          'name_en': 'C E Ferulic',
          'name_ar': 'سي إي فيروليك',
          'brand_name_en': 'SkinCeuticals',
          'brand_name_ar': 'سكين سوتيكالز',
          'sponsor_company': "L'Oreal Middle East",
          'price': '', // Empty price string from UI or omitted
          'is_active': true,
        });

        expect(created.id, 'brand-prod-99');
        expect(created.brandNameEn, 'SkinCeuticals');
        expect(created.brandNameAr, 'سكين سوتيكالز');
        expect(created.sponsorCompany, "L'Oreal Middle East");
        expect(postedData != null, isTrue);
        expect(postedData!.containsKey('price'), isFalse);
        expect(postedData!['brand_name_en'], 'SkinCeuticals');
        expect(postedData!['sponsor_company'], "L'Oreal Middle East");
      },
    );
  });

  group('Patient Discovery Screens & Clinic Form UI Tests', () {
    testWidgets(
      'ProductsScreen displays live products and ProductDetailScreen enforces inquiry-only',
      (tester) async {
        final fakeClient = FakeApiClient(
          onGet: (path, _) => {
            'results': [
              {
                'id': 'p-live-99',
                'brand_name_en': 'Fixture Brand',
                'brand_name_ar': 'علامة الاختبار',
                'name_en': 'Vitamin C Brightening Serum',
                'name_ar': 'سيروم فيتامين سي للنضارة',
                'description_en': 'Antioxidant medical serum',
                'description_ar': 'سيروم طبي مضاد للأكسدة',
                'price': '290.00',
                'is_active': true,
                'clinic': {
                  'id': 'c-99',
                  'name_en': 'Elite Aesthetics',
                  'name_ar': 'إيليت للتجميل',
                },
              },
            ],
          },
        );
        final repo = ProductsRepository(apiClient: fakeClient);

        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: ProductsScreen(repository: repo),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('سيروم فيتامين سي للنضارة'), findsOneWidget);
        expect(find.text('علامة الاختبار'), findsOneWidget);
        expect(find.text('إيليت للتجميل'), findsNothing);

        // Navigate to ProductDetailScreen
        await tester.tap(find.text('سيروم فيتامين سي للنضارة'));
        await tester.pumpAndSettle();

        expect(find.byType(ProductDetailScreen), findsOneWidget);
        expect(find.text('سيروم طبي مضاد للأكسدة'), findsOneWidget);
        // Verify brand showcase has no cart, checkout or direct contact; general inquiry is allowed.
        expect(find.byIcon(Icons.send_rounded), findsNothing);
        expect(find.byIcon(Icons.shopping_cart), findsNothing);
        expect(find.text('العلامة / الجهة الراعية'), findsOneWidget);
      },
    );

    testWidgets(
      'ArticlesScreen displays live articles and opens ArticleDetailScreen',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeClient = FakeApiClient(
          onGet: (path, _) => {
            'results': [
              {
                'id': 'a-live-99',
                'title_en': 'Laser Hair Removal Facts',
                'title_ar': 'حقائق إزالة الشعر بالليزر',
                'content_en': 'Safe for all skin types.',
                'content_ar':
                    'آمن لجميع أنواع البشرة عند اختيار الجهاز المناسب.',
                'published_at': '2026-09-20T10:00:00Z',
                'author_practitioner': {
                  'id': 'doc-99',
                  'name_en': 'Dr. Sara',
                  'name_ar': 'د. سارة',
                },
              },
            ],
          },
        );
        final repo = ArticlesRepository(apiClient: fakeClient);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: ArticlesScreen(repository: repo),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('حقائق إزالة الشعر بالليزر'), findsOneWidget);
        expect(find.text('د. سارة'), findsOneWidget);

        await tester.tap(find.text('حقائق إزالة الشعر بالليزر'));
        await tester.pumpAndSettle();

        expect(find.byType(ArticleDetailScreen), findsOneWidget);
        expect(
          find.text('آمن لجميع أنواع البشرة عند اختيار الجهاز المناسب.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ClinicProfileScreen Product & Article dialogs use LtrTextFormField for English fields',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 3200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        ClinicPortalService().enableMockMode();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(body: ClinicProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Scroll down to Products section and tap Add Product button
        final addProdTooltip = LocaleService().tr('clinic_add_product');
        final addProdBtn = find.byTooltip(addProdTooltip);
        await tester.scrollUntilVisible(
          addProdBtn,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(addProdBtn);
        await tester.pumpAndSettle();

        // Verify LtrTextFormField is present in Product form
        expect(find.byType(LtrTextFormField), findsWidgets);
        // Verify Price field is completely removed and brand metadata fields are present
        expect(find.textContaining('Price'), findsNothing);
        expect(find.textContaining('السعر'), findsNothing);
        expect(find.text('اسم العلامة التجارية بالإنجليزية'), findsOneWidget);
        expect(find.text('الشركة / الجهة الراعية'), findsOneWidget);
      },
    );

    testWidgets(
      'ClinicProfileScreen Product form displays inline error banner on failure without closing sheet',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 3200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeClient = FakeApiClient(
          onGet: (path, _) => {'results': []},
          onPost: (path, data) {
            throw DioException(
              requestOptions: RequestOptions(path: path),
              response: Response(
                requestOptions: RequestOptions(path: path),
                statusCode: 400,
                data: {
                  'name_en': ['A product with this name already exists.'],
                },
              ),
            );
          },
        );
        final catalogRepo = ClinicCatalogRepository(apiClient: fakeClient);
        final service = ClinicPortalService();
        service.setCatalogRepositoryForTesting(catalogRepo);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(body: ClinicProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final addProdTooltip = LocaleService().tr('clinic_add_product');
        final addProdBtn = find.byTooltip(addProdTooltip);
        await tester.scrollUntilVisible(
          addProdBtn,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(addProdBtn);
        await tester.pumpAndSettle();

        // Enter product name
        final nameEnFinder = find.byType(LtrTextFormField).first;
        await tester.enterText(nameEnFinder, 'Duplicate Serum');
        await tester.pumpAndSettle();

        // Tap submit button inside modal sheet
        final submitBtn = find.text('إضافة المنتج للإعلان');
        await tester.scrollUntilVisible(
          submitBtn,
          300,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // Modal bottom sheet must remain open (not popped)
        expect(nameEnFinder, findsOneWidget);
        // Inline Error Banner should be visible with error
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'ClinicProfileScreen Article form uses LuxuryImagePickerField and shows inline error on failure',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 3200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeClient = FakeApiClient(
          onGet: (path, _) => {'results': []},
          onPost: (path, data) {
            throw DioException(
              requestOptions: RequestOptions(path: path),
              response: Response(
                requestOptions: RequestOptions(path: path),
                statusCode: 400,
                data: {
                  'title_en': ['An article with this title already exists.'],
                },
              ),
            );
          },
        );
        final catalogRepo = ClinicCatalogRepository(apiClient: fakeClient);
        final service = ClinicPortalService();
        service.setCatalogRepositoryForTesting(catalogRepo);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(body: ClinicProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final addArtTooltip = LocaleService().tr('clinic_add_article');
        final addArtBtn = find.byTooltip(addArtTooltip);
        await tester.scrollUntilVisible(
          addArtBtn,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(addArtBtn);
        await tester.pumpAndSettle();

        // Verify LuxuryImagePickerField is present and no raw https:// URL field exists
        expect(find.byType(LuxuryImagePickerField), findsOneWidget);
        expect(find.textContaining('https://'), findsNothing);

        // Enter required fields
        final ltrFields = find.byType(LtrTextFormField);
        await tester.enterText(ltrFields.first, 'Duplicate Guide'); // Title EN
        await tester.enterText(
          ltrFields.last,
          'Article Content in English',
        ); // Content EN
        await tester.pumpAndSettle();

        // Tap submit button inside modal sheet
        final submitBtn = find.text('نشر / حفظ المقال');
        await tester.scrollUntilVisible(
          submitBtn,
          300,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // Modal bottom sheet must remain open (not popped)
        expect(find.byType(LuxuryImagePickerField), findsOneWidget);
        // Inline Error Banner should be visible with error
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      },
    );
  });
}
