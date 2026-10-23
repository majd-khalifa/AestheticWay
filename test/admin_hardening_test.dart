import 'package:aesthetic_way/features/admin/presentation/screens/admin_categories_screen.dart';
import 'package:aesthetic_way/features/treatments/data/category_repository.dart';
import 'package:aesthetic_way/features/treatments/models/category_model.dart';
import 'package:aesthetic_way/features/admin/presentation/widgets/admin_components.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show max, min;
import 'package:aesthetic_way/features/auth/presentation/screens/login_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/widgets/admin_password_reset_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/services/local_media_cache.dart';
import 'package:aesthetic_way/core/theme/app_theme.dart';
import 'package:aesthetic_way/core/utils/clinic_location.dart';
import 'package:aesthetic_way/core/utils/maps_launcher.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/core/widgets/luxury_image_picker_field.dart';
import 'package:aesthetic_way/core/widgets/luxury_phone_input_field.dart';
import 'package:aesthetic_way/features/admin/data/admin_repository.dart';
import 'package:aesthetic_way/features/admin/models/admin_analytics_model.dart';
import 'package:aesthetic_way/features/admin/models/admin_clinic_model.dart';
import 'package:aesthetic_way/features/admin/models/admin_dashboard_model.dart';
import 'package:aesthetic_way/features/admin/models/admin_lead_model.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_main_nav_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_clinics_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_clinic_detail_sheet.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_create_clinic_dialog.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_leads_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_lead_detail_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_offers_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_analytics_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_settings_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/widgets/admin_clinic_editor.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/articles/models/article_model.dart';
import 'products_articles_live_test.dart' show FakeApiClient;

const _remote = 'https://aestheticway.ae/media/new-admin-logo.png';
AdminClinicModel _clinic() => AdminClinicModel.fromJson({
  'id': 'clinic-a',
  'name_en': 'Lumiere Skin Clinic',
  'name_ar': 'عيادة لوميير للبشرة',
  'city': 'Abu Dhabi',
  'phone': '+442079460123',
  'whatsapp': '+971501234567',
  'status': 'active',
  'is_active': true,
  'subscription_tier': 'basic',
  'is_featured': false,
  'leads_count': 4,
  'branches_count': 1,
  'practitioners_count': 2,
  'offers_count': 1,
});
OfferModel _offer({String status = 'active'}) => OfferModel.fromJson({
  'id': 'offer-a',
  'title_en': 'Skin consultation',
  'title_ar': 'استشارة البشرة',
  'offer_price': '999',
  'original_price': '1499',
  'status': status,
  'is_active': status == 'active',
});
ProductModel _product({String status = 'active'}) => ProductModel.fromJson({
  'id': 'product-a',
  'name_en': 'Barrier serum',
  'name_ar': 'سيروم البشرة',
  'brand_name_en': 'Lumiere Labs',
  'brand_name_ar': 'مختبرات لوميير',
  'sponsor_company': 'Lumiere Medical Group',
  'price': '987.65',
  'status': status,
});
ArticleModel _article({String status = 'active'}) => ArticleModel.fromJson({
  'id': 'article-a',
  'title_en': 'Bio stimulater 21',
  'title_ar': 'العناية بالبشرة',
  'content_en': 'Original CMS content.',
  'status': status,
});
AdminLeadModel _lead() => AdminLeadModel.fromJson({
  'id': 'lead-a',
  'reference_code': 'AW-2026-1001',
  'status': 'new',
  'clinic': {
    'id': 'clinic-a',
    'name_en': 'Lumiere Skin Clinic',
    'name_ar': 'عيادة لوميير للبشرة',
  },
  'treatment': {'name_en': 'Skin consultation', 'name_ar': 'استشارة البشرة'},
  'patient_name': 'Nour',
  'patient_phone': '+442079460123',
  'notes': 'Please contact me.',
  'created_at': '2026-10-20T08:00:00Z',
});

class _Repository implements AdminRepository {
  List<AdminClinicModel> clinics = [_clinic()];
  List<OfferModel> offers = [_offer()];
  List<ProductModel> products = [_product()];
  List<ArticleModel> articles = [_article()];
  Completer<void>? mutation;
  Completer<Map<String, dynamic>>? provisioning;
  bool reject = false, wrongResult = false;
  int writes = 0, detailReads = 0, clinicReads = 0;
  Map<String, dynamic>? payload;
  @override
  Future<List<AdminClinicModel>> getClinics({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? tier,
    String? search,
  }) async {
    clinicReads++;
    return clinics;
  }

  @override
  Future<AdminClinicModel> getClinicDetail(String id) async {
    detailReads++;
    if (reject) throw const ApiException(message: 'Details unavailable');
    return clinics.firstWhere((c) => c.id == id);
  }

  @override
  Future<List<OfferModel>> getOffers({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? clinicId,
    String? search,
  }) async => offers;
  @override
  Future<List<ProductModel>> getProducts({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? clinicId,
    String? search,
  }) async => products;
  @override
  Future<List<ArticleModel>> getArticles({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? clinicId,
    String? search,
  }) async => articles;
  @override
  Future<List<AdminLeadModel>> getLeads({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? clinicId,
    String? search,
  }) async => [_lead()];
  @override
  Future<AdminLeadModel> getLeadDetail(String id) async => _lead();
  @override
  Future<AdminDashboardModel> getDashboard() async => const AdminDashboardModel(
    totalClinics: 1,
    activeClinics: 0,
    totalLeads: 0,
    scheduledLeads: 999,
    leadsByStatus: {'contacted': 4},
    totalOffers: 12,
  );
  @override
  Future<AdminAnalyticsModel> getAnalytics({
    String? dateFrom,
    String? dateTo,
  }) async => const AdminAnalyticsModel();
  @override
  Future<AdminReferralAnalyticsModel> getReferralAnalytics() async =>
      const AdminReferralAnalyticsModel(
        successfulInvites: 3,
        pointsAwarded: 450,
      );
  Future<Map<String, dynamic>> _write(
    String kind,
    String id,
    String target,
  ) async {
    writes++;
    if (mutation != null) await mutation!.future;
    if (reject) {
      throw const ApiException(message: 'Rejected by server', statusCode: 503);
    }
    if (kind == 'clinic') {
      clinics = clinics
          .map(
            (c) => c.id == id
                ? c.copyWith(status: target, isActive: target == 'active')
                : c,
          )
          .toList();
    }
    if (kind == 'offer') {
      offers = offers
          .map((o) => o.copyWith(status: target, isActive: target == 'active'))
          .toList();
    }
    if (kind == 'product') {
      products = products
          .map(
            (o) => o.copyWith(
              status: target,
              isPublishedByAdmin: target == 'active',
            ),
          )
          .toList();
    }
    if (kind == 'article') {
      articles = articles
          .map(
            (o) => o.copyWith(
              status: target,
              isApprovedByAdmin: target == 'active',
            ),
          )
          .toList();
    }
    return {
      'new_status': wrongResult ? 'pending' : target,
      kind == 'clinic' ? 'clinic_id' : 'id': id,
    };
  }

  @override
  Future<Map<String, dynamic>> suspendClinic(String id, {String reason = ''}) =>
      _write('clinic', id, 'suspended');
  @override
  Future<Map<String, dynamic>> activateClinic(
    String id, {
    String reason = '',
  }) => _write('clinic', id, 'active');
  @override
  Future<Map<String, dynamic>> suspendOffer(String id, {String notes = ''}) =>
      _write('offer', id, 'suspended');
  @override
  Future<Map<String, dynamic>> approveOffer(String id, {String notes = ''}) =>
      _write('offer', id, 'active');
  @override
  Future<Map<String, dynamic>> suspendProduct(String id, {String notes = ''}) =>
      _write('product', id, 'suspended');
  @override
  Future<Map<String, dynamic>> approveProduct(String id, {String notes = ''}) =>
      _write('product', id, 'active');
  @override
  Future<Map<String, dynamic>> suspendArticle(String id, {String notes = ''}) =>
      _write('article', id, 'suspended');
  @override
  Future<Map<String, dynamic>> approveArticle(String id, {String notes = ''}) =>
      _write('article', id, 'active');
  @override
  Future<Map<String, dynamic>> createClinic(Map<String, dynamic> data) async {
    writes++;
    payload = Map.of(data);
    if (provisioning != null) return provisioning!.future;
    if (reject) {
      throw const ApiException(
        message: 'Duplicate administrator phone',
        statusCode: 400,
      );
    }
    return {
      'status': 'success',
      'clinic': {'id': 'new-clinic', 'name_en': data['name_en']},
      'admin_user': {
        'phone': (data['admin_user'] as Map)['phone'],
        'temporary_password': 'Server-issued-secret',
      },
    };
  }

  @override
  Future<AdminClinicModel> updateClinic(
    String id,
    Map<String, dynamic> data,
  ) async {
    writes++;
    payload = Map.of(data);
    if (mutation != null) await mutation!.future;
    if (reject) {
      throw const ApiException(message: 'Update rejected', statusCode: 400);
    }
    final updated = AdminClinicModel.fromJson({
      'id': id,
      'name_en': data['name_en'] ?? 'Updated Clinic',
      'name_ar': data['name_ar'] ?? 'العيادة',
      'city': data['city'] ?? 'Abu Dhabi',
      'status': 'active',
      'phone': data['phone'] ?? '+442079460123',
      'subscription_tier': data['subscription_tier'] ?? 'basic',
      'is_featured': data['is_featured'] ?? false,
      'logo': data.containsKey('logo') && data['logo'] != null ? _remote : null,
    });
    clinics = [updated];
    return updated;
  }

  @override
  Future<Map<String, dynamic>> resetClinicAdminPassword(
    String id, {
    String? customPassword,
  }) async {
    writes++;
    if (reject) throw const ApiException(message: 'Reset rejected');
    return {
      'temporary_password': 'Server-reset-secret',
      'admin_phone': '+442079460123',
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DeferredCategories extends CategoryRepository {
  final response = Completer<List<CategoryModel>>();
  @override
  Future<List<CategoryModel>> getAdminCategories({int page = 1}) =>
      response.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = AdminPortalService();
  late _Repository repository;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    AuthState().logout();
    AuthState().login(
      name: 'Admin',
      phone: '+971500000001',
      role: 'super_admin',
    );
    service.resetTestingState();
    LocalMediaCache().clear();
    LocaleService().setLanguage(AppLanguage.english);
    repository = _Repository();
    AdminPortalService(repository: repository);
  });
  tearDown(() {
    AppSnackBar.dismissCurrent();
    AuthState().logout();
    LocalMediaCache().clear();
  });
  Future<void> load() async {
    for (final key in ['clinics', 'offers', 'products', 'articles']) {
      await service.loadCollection(key);
    }
  }

  Future<bool> toggle(String kind) => kind == 'clinic'
      ? service.toggleClinicStatus('clinic-a')
      : service.setContentStatus(kind, '$kind-a', 'suspended');
  String state(String kind) => switch (kind) {
    'clinic' => service.clinics.first.status,
    'offer' => service.allOffers.first.status,
    'product' => service.allProducts.first.status,
    _ => service.allArticles.first.status,
  };

  test(
    'location labels deduplicate normalized bilingual city/area without invented neighborhoods',
    () {
      expect(formatClinicLocation('Dubai', ' dubai ', arabic: false), 'Dubai');
      expect(
        formatClinicLocation('Abu Dhabi', 'أبو ظبي', arabic: true),
        'أبوظبي',
      );
      expect(
        formatClinicLocation('Dubai', 'Jumeirah', arabic: false),
        'Dubai • Jumeirah',
      );
      expect(
        formatClinicLocation('', '', arabic: false),
        'Location not provided',
      );
    },
  );
  test(
    'unknown and invalid coordinates never become Dubai; valid clinic/main branch wins',
    () {
      for (final data in <Map<String, dynamic>>[
        {},
        {'latitude': null, 'longitude': null},
        {'latitude': 91, 'longitude': 55},
        {'latitude': 'NaN', 'longitude': 55},
        {'latitude': 0, 'longitude': 0},
      ]) {
        final c = AdminClinicModel.fromJson({'id': 'c', ...data});
        expect(c.latitude, isNull);
        expect(c.longitude, isNull);
        expect(c.hasVerifiedLocation, isFalse);
      }
      final c = AdminClinicModel.fromJson({
        'id': 'c',
        'latitude': '24.45',
        'longitude': '54.37',
        'video_ad_file': '/media/video.mp4',
        'branches': [
          {'latitude': 25, 'longitude': 55, 'is_active': true},
        ],
      });
      expect(c.latitude, 24.45);
      expect(c.longitude, 54.37);
      expect(c.copyWith(status: 'suspended').latitude, 24.45);
      expect(
        c.copyWith(status: 'suspended').videoAdFile,
        endsWith('/media/video.mp4'),
      );
      final b = AdminClinicModel.fromJson({
        'id': 'c',
        'branches': [
          {'latitude': 25, 'longitude': 55, 'is_active': false},
          {
            'latitude': 24.45,
            'longitude': 54.37,
            'is_active': true,
            'is_main_branch': true,
          },
        ],
      });
      expect(b.latitude, 24.45);
    },
  );
  test(
    'map URI prefers verified stored Google links, rejects spoofing and unknown destinations',
    () {
      expect(MapsLauncher.verifiedDirectionsUri(), isNull);
      expect(
        MapsLauncher.verifiedDirectionsUri(
          latitude: double.infinity,
          longitude: 55,
        ),
        isNull,
      );
      expect(
        MapsLauncher.verifiedDirectionsUri(
          googleMapsUrl: 'https://evil.example/maps',
        ),
        isNull,
      );
      expect(
        MapsLauncher.verifiedDirectionsUri(
          googleMapsUrl: 'https://google.com.evil/maps',
        ),
        isNull,
      );
      expect(
        MapsLauncher.verifiedDirectionsUri(
          latitude: 24.4,
          longitude: 54.3,
          googleMapsUrl: 'https://maps.app.goo.gl/example',
        )?.host,
        'maps.app.goo.gl',
      );
      expect(
        MapsLauncher.verifiedDirectionsUri(
          latitude: 24.4,
          longitude: 54.3,
        )?.queryParameters['destination'],
        '24.4,54.3',
      );
    },
  );
  test(
    'lead names use verified translations, honest fallback and nullable historical timestamps',
    () {
      final l = _lead();
      expect(l.localizedClinic(arabic: false), 'Lumiere Skin Clinic');
      expect(l.localizedService(arabic: true), 'استشارة البشرة');
      expect(l.localizedService(arabic: false), 'Skin consultation');
      final raw = AdminLeadModel.fromJson({
        'service_name': 'Original medical name 21',
        'created_at': 'invalid',
      });
      expect(raw.localizedService(arabic: false), 'Original medical name 21');
      expect(raw.createdAt, isNull);
    },
  );
  test(
    'contacted KPI uses contacted count, zero totals remain zero, closure denominator is safe',
    () async {
      await load();
      await service.loadDashboard();
      expect(service.dashboard.contactedLeads, 4);
      expect(service.dashboard.scheduledLeads, 999);
      expect(service.activeClinicsCount, 0);
      expect(service.totalLeadsCount, 0);
      expect(service.dashboard.closureRate, 0);
      expect(
        const AdminDashboardModel(totalLeads: 4, completedLeads: 1).closureRate,
        25,
      );
    },
  );
  test(
    'admin serializers missing status stay unknown; filtered status is reliable and search avoids broken server fields',
    () async {
      final queries = <String, Map<String, dynamic>>{};
      final api = FakeApiClient(
        onGet: (path, q) {
          queries[path] = Map.of(q ?? {});
          return {
            'results': [
              {
                'id': 'a',
                'name_en': 'Serum',
                'title_en': 'Article',
                'offer_price': '10',
              },
            ],
            'next': null,
          };
        },
      );
      final repo = AdminRepository(apiClient: api);
      expect((await repo.getProducts()).single.status, 'unknown');
      expect((await repo.getOffers()).single.status, 'unknown');
      expect(
        (await repo.getArticles(status: 'pending')).single.status,
        'pending',
      );
      expect(
        (await repo.getOffers(
          status: 'suspended',
          search: 'hello',
        )).single.isActive,
        isFalse,
      );
      await repo.getProducts(page: 2, search: 'Brand');
      await repo.getArticles(search: 'hello');
      expect(queries[ApiConfig.adminOffers]!.containsKey('search'), isFalse);
      expect(queries[ApiConfig.adminArticles]!.containsKey('search'), isFalse);
      expect(queries[ApiConfig.adminProducts]!['search'], 'Brand');
      expect(queries[ApiConfig.adminProducts]!['page'], 2);
      expect(queries[ApiConfig.adminProducts]!['page_size'], 20);
    },
  );
  test('brand showcase serialization never sends a legacy price', () {
    final p = _product();
    expect(p.price, 987.65);
    expect(p.toPortalJson().containsKey('price'), isFalse);
    expect(p.toPortalJson()['sponsor_company'], 'Lumiere Medical Group');
  });
  for (final kind in ['clinic', 'offer', 'product', 'article']) {
    test(
      '$kind mutations await confirmation, block duplicates, and preserve prior state on API failure',
      () async {
        await load();
        repository.mutation = Completer<void>();
        final first = toggle(kind);
        expect(service.isPending(kind, '$kind-a'), isTrue);
        expect(state(kind), 'active');
        expect(await toggle(kind), isFalse);
        expect(repository.writes, 1);
        repository.reject = true;
        repository.mutation!.complete();
        expect(await first, isFalse);
        expect(state(kind), 'active');
        expect(service.isPending(kind, '$kind-a'), isFalse);
        expect(service.writeError(kind, '$kind-a'), 'Rejected by server');
        repository.reject = false;
        repository.mutation = null;
        expect(await toggle(kind), isTrue);
        expect(state(kind), 'suspended');
      },
    );
  }
  test(
    'unverified mutation acknowledgements do not become a false success',
    () async {
      await load();
      repository.wrongResult = true;
      expect(await service.toggleClinicStatus('clinic-a'), isFalse);
      expect(service.clinics.first.status, 'active');
    },
  );
  test(
    'in-flight writes cannot repopulate a logged-out or switched-role session',
    () async {
      await load();
      repository.mutation = Completer<void>();
      final future = service.toggleProductModeration('product-a');
      AuthState().login(
        name: 'Patient',
        phone: '+971500000002',
        role: 'patient',
      );
      repository.mutation!.complete();
      expect(await future, isFalse);
      expect(service.allProducts, isEmpty);
      expect(service.canManage, isFalse);
    },
  );
  test(
    'patient and clinic admins cannot provision or mutate clinics',
    () async {
      for (final role in ['patient', 'clinic_admin']) {
        AuthState().login(name: 'Other', phone: '+971500000002', role: role);
        await expectLater(
          service.createClinic({}),
          throwsA(isA<ApiException>()),
        );
      }
      expect(repository.writes, 0);
    },
  );
  test(
    'admin image cache changes only after an acknowledged save; omitted images remain omitted',
    () async {
      final dir = Directory.systemTemp.createTempSync('aw-admin-cache-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/photo.png')
        ..writeAsBytesSync(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVR4nGN8ZuT2n4GBgYGJAQoAJKgCYaRJeyUAAAAASUVORK5CYII=',
          ),
        );
      repository.reject = true;
      await expectLater(
        service.updateClinic('clinic-a', {'logo': file.path}),
        throwsA(isA<ApiException>()),
      );
      expect(
        LocalMediaCache().lookup(
          entityKey: LocalMediaCache.clinicLogo('clinic-a'),
        ),
        isNull,
      );
      repository.reject = false;
      await service.updateClinic('clinic-a', {'logo': file.path});
      expect(LocalMediaCache().lookup(remoteUrl: _remote), file.path);
      await service.updateClinic('clinic-a', {'name_en': 'Text edit'});
      expect(repository.payload!.containsKey('logo'), isFalse);
      await service.updateClinic('clinic-a', {'logo': null});
      expect(
        LocalMediaCache().lookup(
          entityKey: LocalMediaCache.clinicLogo('clinic-a'),
        ),
        isNull,
      );
    },
  );
  test(
    'phone normalization preserves international prefixes and relevant national zeros',
    () {
      expect(
        LuxuryPhoneInputField.normalizeToE164('0501234567'),
        '+971501234567',
      );
      expect(
        LuxuryPhoneInputField.normalizeToE164('+44 (0)20 7946 0123'),
        '+442079460123',
      );
      expect(
        LuxuryPhoneInputField.normalizeToE164('0049 030 123456'),
        '+4930123456',
      );
      expect(
        LuxuryPhoneInputField.normalizeToE164('+39 06 69812345'),
        '+390669812345',
      );
      expect(
        LuxuryPhoneInputField.normalizeToE164(
          '7700900123',
          defaultDialCode: '+44',
        ),
        '+447700900123',
      );
      expect(kSupportedDialCodes.take(22).length, 22);
      expect(kSupportedDialCodes.any((c) => c.nameEn == 'Bulgaria'), isTrue);
    },
  );
  testWidgets(
    'product moderation shows genuine brand/sponsor identity and no retail amounts',
    (tester) async {
      await load();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AdminOffersScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();
      expect(find.text('Lumiere Labs'), findsOneWidget);
      expect(find.textContaining('Lumiere Medical Group'), findsOneWidget);
      expect(find.textContaining('987.65'), findsNothing);
      expect(find.textContaining('AED'), findsNothing);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsNothing);
      expect(find.text('Original CMS content.'), findsNothing);
    },
  );
  testWidgets(
    'admin lead supervision is localized, LTR for phones and has no contact or mutation controls',
    (tester) async {
      service.enableMockMode();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AdminLeadDetailScreen(lead: _lead()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Skin consultation'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('+442079460123')).textDirection,
        TextDirection.ltr,
      );
      expect(find.byType(Switch), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byIcon(Icons.call), findsNothing);
      expect(find.text('WhatsApp'), findsNothing);
    },
  );
  testWidgets(
    'credentials never invent a password when server response omits it',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAdminCredentials(
                  context,
                  result: {
                    'clinic': {'name_en': 'Clinic'},
                    'admin_user': {},
                  },
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('did not return a temporary password'),
        findsOneWidget,
      );
      expect(find.textContaining('AW#TempPass123!'), findsNothing);
      expect(find.text('Copy Credentials to Clipboard'), findsNothing);
    },
  );
  Future<void> openEditor(WidgetTester tester, {bool creating = false}) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                isDismissible: false,
                builder: (ctx) => SizedBox(
                  height: 1000,
                  child: AdminClinicEditor(clinic: creating ? null : _clinic()),
                ),
              ),
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String key, String value) async {
    final finder = find.byKey(ValueKey('admin-$key'));
    await tester.scrollUntilVisible(
      finder,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(finder, value);
  }

  testWidgets(
    'clinic editor preserves +44 and images, separates VIP from home placement, and stays open on failure',
    (tester) async {
      await openEditor(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('admin-tier')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('admin-tier')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('VIP Platinum').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('admin-home-featured')),
            )
            .value,
        isFalse,
      );
      repository.reject = true;
      await tester.tap(find.byKey(const ValueKey('admin-save-clinic')));
      await tester.pumpAndSettle();
      expect(find.text('Update rejected'), findsOneWidget);
      expect(find.byType(AdminClinicEditor), findsOneWidget);
      expect(repository.payload!['phone'], '+442079460123');
      expect(repository.payload!['subscription_tier'], 'vip');
      expect(repository.payload!['is_featured'], isFalse);
      expect(repository.payload!.containsKey('logo'), isFalse);
      expect(repository.payload!.containsKey('cover_image'), isFalse);
      repository.reject = false;
      await tester.tap(find.byKey(const ValueKey('admin-save-clinic')));
      await tester.pumpAndSettle();
      expect(find.byType(AdminClinicEditor), findsNothing);
      expect(service.clinicDetail('clinic-a')!.nameEn, 'Lumiere Skin Clinic');
    },
  );
  testWidgets(
    'offscreen empty fields prevent provisioning and do not send a request',
    (tester) async {
      await openEditor(tester, creating: true);
      await tester.drag(find.byType(ListView).first, const Offset(0, -1800));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('admin-save-clinic')));
      await tester.pumpAndSettle();
      expect(repository.writes, 0);
      expect(find.text('Enter the clinic name in English.'), findsOneWidget);
    },
  );
  testWidgets(
    'provisioning waits for the server, blocks repeated save and hands off only returned credentials',
    (tester) async {
      await openEditor(tester, creating: true);
      await enter(tester, 'name_en', 'New Clinic');
      await enter(tester, 'clinic-phone', '0501234567');
      await enter(tester, 'admin_name', 'Clinic Administrator');
      await enter(tester, 'login-phone', '0509876543');
      repository.provisioning = Completer<Map<String, dynamic>>();
      await tester.tap(find.byKey(const ValueKey('admin-save-clinic')));
      await tester.pump();
      expect(repository.writes, 1);
      expect(find.text('Clinic & Admin Provisioned'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('admin-save-clinic')),
            )
            .onPressed,
        isNull,
      );
      repository.provisioning!.complete({
        'status': 'success',
        'clinic': {'id': 'new-clinic', 'name_en': 'New Clinic'},
        'admin_user': {
          'phone': '+971509876543',
          'temporary_password': 'Server-issued-secret',
        },
      });
      await tester.pumpAndSettle();
      expect(find.text('Clinic & Admin Provisioned'), findsOneWidget);
      expect(find.text('Server-issued-secret'), findsNothing);
      await tester.tap(find.byTooltip('Reveal temporary password'));
      await tester.pump();
      expect(find.text('Server-issued-secret'), findsOneWidget);
      expect(
        (repository.payload!['admin_user'] as Map)['phone'],
        '+971509876543',
      );
      expect(repository.payload!['is_featured'], isFalse);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminClinicEditor), findsNothing);
    },
  );
  testWidgets(
    'native camera/gallery uses required image settings and renders a local contain preview',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync('aw-picker-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final file = File('${directory.path}/photo.png')
        ..writeAsBytesSync(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVR4nGN8ZuT2n4GBgYGJAQoAJKgCYaRJeyUAAAAASUVORK5CYII=',
          ),
        );
      const channel = MethodChannel('plugins.flutter.io/image_picker');
      Map<dynamic, dynamic>? arguments;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            arguments = call.arguments as Map;
            return file.path;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LuxuryImagePickerField(
              label: 'Clinic Logo',
              height: 160,
              fit: BoxFit.contain,
              onImageSelected: (v) => selected = v,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tap to upload photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from Gallery'));
      await tester.pumpAndSettle();
      expect(arguments!['maxWidth'], 1200);
      expect(arguments!['imageQuality'], 78);
      expect(selected, file.path);
      expect(
        tester.widget<Image>(find.byType(Image).first).fit,
        BoxFit.contain,
      );
      await tester.tap(find.byTooltip('Replace or remove photo'));
      await tester.pumpAndSettle();
      expect(find.text('Take a Photo'), findsOneWidget);
      await tester.tap(find.text('Take a Photo'));
      await tester.pumpAndSettle();
      expect(arguments!['source'], 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'analytics removes redemption metrics and shows real referral points without clipped KPI labels',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AdminAnalyticsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Redeemed Codes'), findsNothing);
      final title = tester.widget<Text>(find.text('Tracked Platform Events'));
      expect(title.maxLines, isNull);
      expect(title.overflow, isNull);
      await tester.scrollUntilVisible(
        find.text('Points Awarded'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('450'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    },
  );
  testWidgets(
    'pending or missing clinic location never enables navigation to default coordinates',
    (tester) async {
      service.enableMockMode();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AdminClinicDetailSheet(clinic: _clinic())),
        ),
      );
      await tester.pumpAndSettle();
      final label = find.text('Verified map location unavailable');
      await tester.scrollUntilVisible(
        label,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      final button = find.ancestor(
        of: label,
        matching: find.byType(OutlinedButton),
      );
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
    },
  );
  testWidgets(
    'dashboard notice clears the navigation bar, tabs retain state, and back returns to dashboard',
    (tester) async {
      service.enableMockMode();
      await tester.binding.setSurfaceSize(const Size(390, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AdminMainNavScreen(),
        ),
      );
      await tester.pumpAndSettle();
      final notice = find.byKey(const ValueKey('admin-supervision-notice'));
      await tester.scrollUntilVisible(
        notice,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      final nav = find.byWidget(scaffold.bottomNavigationBar!);
      expect(
        tester.getBottomLeft(notice).dy,
        lessThanOrEqualTo(tester.getTopLeft(nav).dy),
      );
      await tester.tap(find.text('Clinics').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Lumiere');
      await tester.tap(find.text('Leads').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clinics').last);
      await tester.pumpAndSettle();
      expect(find.text('Lumiere'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AdminDashboardScreen), findsOneWidget);
    },
  );
  testWidgets(
    'tier filtering searches the full server dataset with one debounce and preserves page size',
    (tester) async {
      final requests = <Map<String, dynamic>>[];
      final api = FakeApiClient(
        onGet: (path, query) {
          final q = Map<String, dynamic>.of(query ?? {});
          requests.add(q);
          return {
            'count': q['tier'] == 'vip' ? 1 : 40,
            'next': q['tier'] == 'vip' ? null : '?page=2',
            'results': q['tier'] == 'vip'
                ? [
                    {
                      'id': 'remote-vip',
                      'name_en': 'Remote VIP match',
                      'city': 'Dubai',
                      'status': 'active',
                      'subscription_tier': 'vip',
                    },
                  ]
                : List.generate(
                    20,
                    (i) => {
                      'id': 'basic-$i',
                      'name_en': 'Clinic $i',
                      'city': 'Dubai',
                      'status': 'active',
                      'subscription_tier': 'basic',
                    },
                  ),
          };
        },
      );
      AdminPortalService(repository: AdminRepository(apiClient: api));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AdminClinicsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(requests, hasLength(1));
      await tester.enterText(find.byType(TextField), 'R');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'Remote');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('VIP Platinum').first);
      await tester.pump(const Duration(milliseconds: 349));
      expect(requests, hasLength(1));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(requests, hasLength(2));
      expect(requests.last['tier'], 'vip');
      expect(requests.last['page'], 1);
      expect(requests.last['page_size'], 20);
      expect(requests.last['search'], 'Remote');
      expect(find.text('Remote VIP match'), findsOneWidget);
    },
  );
  testWidgets(
    'password reset remains open on failure and stops progress before showing returned credentials',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) =>
                      const AdminPasswordResetDialog(clinicId: 'clinic-a'),
                ),
                child: const Text('Reset'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      repository.reject = true;
      await tester.tap(find.text('Confirm Reset'));
      await tester.pumpAndSettle();
      expect(find.text('Reset rejected'), findsOneWidget);
      repository.reject = false;
      await tester.tap(find.text('Confirm Reset'));
      await tester.pumpAndSettle();
      expect(find.text('Server-reset-secret'), findsNothing);
      await tester.tap(find.byTooltip('Reveal temporary password'));
      await tester.pump();
      expect(find.text('Server-reset-secret'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminPasswordResetDialog), findsNothing);
    },
  );
  testWidgets('admin status text meets AA contrast in both themes', (
    tester,
  ) async {
    for (final dark in [false, true]) {
      final theme = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Material(
              color: theme.cardColor,
              child: const Column(
                children: [
                  AdminStatusBadge(status: 'active'),
                  AdminStatusBadge(status: 'suspended'),
                  AdminStatusBadge(status: 'pending'),
                  AdminStatusBadge(status: 'contacted'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final element in find.byType(AdminStatusBadge).evaluate()) {
        final finder = find.byWidget(element.widget);
        final text = tester.widget<Text>(
          find.descendant(of: finder, matching: find.byType(Text)),
        );
        final container = tester.widget<Container>(
          find.descendant(of: finder, matching: find.byType(Container)),
        );
        final fill = (container.decoration as BoxDecoration).color!;
        final background = Color.alphaBlend(
              fill,
              theme.cardColor,
            ).computeLuminance(),
            foreground = text.style!.color!.computeLuminance();
        final ratio =
            (max(background, foreground) + .05) /
            (min(background, foreground) + .05);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${text.data}, dark=$dark',
        );
      }
    }
  });
  testWidgets(
    'a role/session change removes nested admin routes and patient details',
    (tester) async {
      service.enableMockMode();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AdminMainNavScreen(initialIndex: 1),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AdminClinicCard).first);
      await tester.pumpAndSettle();
      expect(find.byType(AdminClinicDetailSheet), findsOneWidget);
      AuthState().login(
        name: 'Patient',
        phone: '+971500000009',
        role: 'patient',
      );
      await tester.pumpAndSettle();
      expect(find.byType(AdminClinicDetailSheet), findsNothing);
      expect(find.byType(AdminMainNavScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );
  testWidgets('double back exits only within two seconds on dashboard', (
    tester,
  ) async {
    service.enableMockMode();
    var exits = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemNavigator.pop') exits++;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const AdminMainNavScreen()),
    );
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 2100));
    expect(exits, 0);
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 100));
    expect(exits, 0);
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 100));
    expect(exits, 1);
  });
  testWidgets(
    'Add Clinic floating action leaves the final clinic card unobscured',
    (tester) async {
      service.enableMockMode();
      await tester.binding.setSurfaceSize(const Size(320, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final id = service.clinics.last.id;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AdminClinicsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      final card = find.byKey(ValueKey('admin-clinic-$id'));
      await tester.scrollUntilVisible(
        card,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(card).dy,
        lessThanOrEqualTo(
          tester.getTopLeft(find.byType(FloatingActionButton)).dy,
        ),
      );
    },
  );
  testWidgets(
    'clinic provisioning remains usable above keyboard and bottom safe area',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.4),
              viewInsets: const EdgeInsets.only(bottom: 300),
              padding: const EdgeInsets.only(bottom: 24),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AdminCreateClinicDialog.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .getBottomLeft(find.byKey(const ValueKey('admin-save-clinic')))
            .dy,
        lessThanOrEqualTo(400),
      );
    },
  );
  test(
    'dashboard recent activity stays global without resetting the leads tab filter',
    () async {
      final queries = <Map<String, dynamic>>[];
      final api = FakeApiClient(
        onGet: (path, q) {
          if (path == ApiConfig.adminLeads) {
            queries.add(Map.of(q ?? {}));
            return {
              'results': [
                {
                  'id': q?['clinic'] == null
                      ? 'global-request'
                      : 'filtered-request',
                  'clinic': {'id': 'clinic-a'},
                },
              ],
              'next': null,
            };
          }
          return {};
        },
      );
      AdminPortalService(repository: AdminRepository(apiClient: api));
      await service.loadLeads(clinicId: 'clinic-a');
      await service.loadOverview();
      expect(service.allLeads.single.id, 'filtered-request');
      expect(service.recentLeads.single.id, 'global-request');
      expect(service.collection('leads').query['clinic'], 'clinic-a');
      expect(queries, hasLength(2));
    },
  );

  for (final ar in [false, true]) {
    testWidgets(
      'Admin AppBar follows all five tabs and locale ${ar ? 'ar' : 'en'}',
      (tester) async {
        service.enableMockMode();
        LocaleService().setLanguage(
          ar ? AppLanguage.arabic : AppLanguage.english,
        );
        await tester.binding.setSurfaceSize(const Size(320, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.4)),
              child: Directionality(
                textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
                child: child!,
              ),
            ),
            home: const AdminMainNavScreen(),
          ),
        );
        for (final (nav, title) in [
          ('admin_nav_dashboard', 'admin_title_dashboard'),
          ('admin_nav_clinics', 'admin_title_clinics'),
          ('admin_nav_leads', 'admin_title_leads'),
          ('admin_nav_offers', 'admin_title_catalog'),
          ('admin_nav_analytics', 'admin_title_analytics'),
        ]) {
          await tester.tap(find.text(LocaleService().tr(nav)).last);
          await tester.pumpAndSettle();
          final actual = find.descendant(
            of: find.byType(AppBar),
            matching: find.text(LocaleService().tr(title)),
          );
          expect(actual, findsOneWidget);
          final text = tester.widget<Text>(actual);
          expect(text.overflow, isNot(TextOverflow.ellipsis));
          expect(tester.takeException(), isNull);
          expect(
            tester.getBottomLeft(actual).dy,
            lessThanOrEqualTo(tester.getBottomLeft(find.byType(AppBar)).dy),
          );
        }
      },
    );
  }
  test(
    'shared categories read preserves treatment taxonomy and only calls the verified public GET',
    () async {
      final requests = <Map<String, dynamic>>[];
      final api = FakeApiClient(
        onGet: (path, query) {
          expect(path, ApiConfig.categories);
          requests.add(Map.of(query ?? {}));
          return {
            'count': 21,
            'next': null,
            'results': [
              {
                'id': 'treatment-category',
                'name_en': 'Laser',
                'name_ar': 'ليزر',
                'slug': 'laser',
                'icon': 'https://aestheticway.ae/media/laser.png',
                'display_order': 3,
              },
            ],
          };
        },
        onPost: (_, _) => throw StateError('No category write is supported'),
      );
      final rows = await CategoryRepository(
        apiClient: api,
      ).getCategories(page: 2, search: ' laser ');
      expect(rows.single.nameAr, 'ليزر');
      expect(rows.single.slug, 'laser');
      expect(rows.single.displayOrder, 3);
      expect(rows.single.icon, contains('/laser.png'));
      expect(requests.single, {'page': 2, 'page_size': 20, 'search': 'laser'});
    },
  );
  testWidgets(
    'Admin treatment categories use paged authenticated management and separate brand taxonomy',
    (tester) async {
      final requests = <Map<String, dynamic>>[];
      var writes = 0;
      final api = FakeApiClient(
        onGet: (path, query) {
          expect(path, CategoryRepository.adminPath);
          final q = Map<String, dynamic>.of(query ?? {});
          requests.add(q);
          final index = q['page'] as int;
          return {
            'count': 21,
            'next': index == 1 ? '?page=2' : null,
            'results': index == 1
                ? List.generate(
                    20,
                    (i) => {
                      'id': 'category-$i',
                      'name_en': 'Treatment $i',
                      'name_ar': 'علاج $i',
                    },
                  )
                : [
                    {
                      'id': 'category-20',
                      'name_en': 'Final treatment',
                      'name_ar': 'العلاج الأخير',
                    },
                  ],
          };
        },
        onPost: (_, _) {
          writes++;
          return {};
        },
        onPatch: (_, _) {
          writes++;
          return {};
        },
        onDelete: (_) {
          writes++;
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AdminCategoriesScreen(
            repository: CategoryRepository(apiClient: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Treatment categories'), findsOneWidget);
      expect(
        find.textContaining('brand-product categories are separate'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Add Category'),
            )
            .onPressed,
        isNotNull,
      );
      expect(requests, hasLength(1));
      expect(requests.single['page_size'], 20);
      final scroll = find.byType(CustomScrollView);
      for (var i = 0; i < 14 && requests.length < 2; i++) {
        await tester.drag(scroll, const Offset(0, -700));
        await tester.pumpAndSettle();
      }
      expect(requests.last['page'], 2);
      await tester.scrollUntilVisible(
        find.text('Final treatment'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Edit').last)
            .onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Delete').last)
            .onPressed,
        isNotNull,
      );
      expect(writes, 0);
    },
  );
  testWidgets(
    'Admin category load errors can retry without invoking clinic writes',
    (tester) async {
      var fail = true, reads = 0;
      final api = FakeApiClient(
        onGet: (path, q) {
          expect(path, CategoryRepository.adminPath);
          reads++;
          if (fail) throw const ApiException(message: 'Categories unavailable');
          return {
            'next': null,
            'results': [
              {'id': 'ok', 'name_en': 'Recovered category'},
            ],
          };
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: AdminCategoriesScreen(
            repository: CategoryRepository(apiClient: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Categories unavailable'), findsWidgets);
      fail = false;
      await tester.tap(find.text('Retry').first);
      await tester.pump();
      expect(reads, 1); // Immediate taps respect the read-failure backoff.
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Retry').first);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Recovered category'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(reads, 2);
      expect(find.text('Recovered category'), findsOneWidget);
    },
  );
  testWidgets(
    'category read completion cannot restore data after an Admin role change',
    (tester) async {
      final repo = _DeferredCategories();
      await tester.pumpWidget(
        MaterialApp(home: AdminCategoriesScreen(repository: repo)),
      );
      await tester.pump();
      AuthState().login(
        name: 'Patient',
        phone: '+442079460123',
        role: 'patient',
      );
      await tester.pump();
      repo.response.complete([
        const CategoryModel(
          id: 'late',
          nameEn: 'Late category',
          nameAr: 'متأخر',
          slug: 'late',
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Late category'), findsNothing);
      expect(find.text('Super Admin access is required.'), findsOneWidget);
    },
  );
  testWidgets(
    'independent product authoring never sends an unsupported or clinic-scoped write',
    (tester) async {
      await load();
      await tester.pumpWidget(MaterialApp(home: const AdminOffersScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('admin-add-brand-product')),
            )
            .onPressed,
        isNull,
      );
      final inspect = find.text('Inspect content');
      await tester.scrollUntilVisible(
        inspect.hitTestable(),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(inspect);
      await tester.pumpAndSettle();
      final archive = find.text('Archive Brand Product');
      await tester.scrollUntilVisible(
        archive,
        400,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Edit Brand Product'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Archive Brand Product'),
            )
            .onPressed,
        isNull,
      );
      expect(repository.writes, 0);
      expect(find.textContaining('987.65'), findsNothing);
      expect(find.textContaining('AED'), findsNothing);
    },
  );
  for (final empty in [false, true]) {
    testWidgets(
      'clinic Offers section remains fully reachable with safe area and ${empty ? 'empty' : 'loaded'} records',
      (tester) async {
        if (empty) repository.offers = [];
        await tester.binding.setSurfaceSize(const Size(320, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.4),
                padding: const EdgeInsets.only(bottom: 34),
              ),
              child: child!,
            ),
            home: Scaffold(body: AdminClinicDetailSheet(clinic: _clinic())),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('admin-clinic-view-offers')),
        );
        await tester.pumpAndSettle();
        final heading = find.descendant(
          of: find.byType(AdminSectionTitle),
          matching: find.text('Offers'),
        );
        final viewport = find.byKey(
          const ValueKey('admin-clinic-detail-scroll'),
        );
        expect(
          tester.getTopLeft(heading).dy,
          greaterThanOrEqualTo(tester.getTopLeft(viewport).dy),
        );
        expect(
          tester.getBottomLeft(heading).dy,
          lessThanOrEqualTo(tester.getBottomLeft(viewport).dy),
        );
        expect(
          find.text(empty ? 'No offers for this clinic.' : 'Skin consultation'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    for (final dark in [false, true]) {
      for (final ar in [false, true]) {
        testWidgets(
          'all admin screens fit ${width.toInt()}px ${dark ? 'dark' : 'light'} ${ar ? 'ar' : 'en'} at increased text size',
          (tester) async {
            service.enableMockMode();
            LocaleService().setLanguage(
              ar ? AppLanguage.arabic : AppLanguage.english,
            );
            await tester.binding.setSurfaceSize(Size(width, 1100));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final screens = <Widget>[
              AdminDashboardScreen(
                onNavigateToClinics: () {},
                onNavigateToLeads: () {},
                onNavigateToAnalytics: () {},
              ),
              const AdminClinicsScreen(),
              const AdminLeadsScreen(),
              AdminLeadDetailScreen(lead: _lead()),
              const AdminOffersScreen(),
              const AdminAnalyticsScreen(),
              const AdminSettingsScreen(),
              AdminCategoriesScreen(
                repository: CategoryRepository(
                  apiClient: FakeApiClient(
                    onGet: (_, _) => {'results': <dynamic>[], 'next': null},
                  ),
                ),
              ),
              AdminClinicDetailSheet(clinic: _clinic()),
              const Scaffold(body: AdminCreateClinicDialog()),
              const AdminMainNavScreen(),
            ];
            for (final screen in screens) {
              await tester.pumpWidget(
                MaterialApp(
                  theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(1.4)),
                    child: Directionality(
                      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
                      child: child!,
                    ),
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
  }
}
