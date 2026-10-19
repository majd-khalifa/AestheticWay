import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_image_picker_field.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/widgets/clinic_offer_editor.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/core/auth/session_changed_exception.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/services/media_upload_service.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_theme.dart';
import 'package:aesthetic_way/features/admin/data/admin_repository.dart';
import 'package:aesthetic_way/features/admin/models/admin_dashboard_model.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';
import 'package:aesthetic_way/features/auth/data/auth_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_leads_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/referral/data/referral_repository.dart';
import 'package:aesthetic_way/features/referral/models/referral_model.dart';
import 'package:aesthetic_way/features/referral/services/referral_service.dart';

class _Api implements ApiClient {
  dynamic result = <String, dynamic>{};
  final List<dynamic> patchBodies = [];
  final List<dynamic> postBodies = [];

  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    patchBodies.add(data);
    return Response<T>(
      data: result as T,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    postBodies.add(data);
    return Response<T>(
      data: result as T,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Uploader implements MediaUploadService {
  ApiException? failure;
  static const signedUrl =
      'https://storage.example/image.png?X-Amz-Signature=abc&X-Amz-Expires=600';

  @override
  Future<Map<String, dynamic>> uploadImage({
    required String filePath,
    required String mediaType,
    String? clinicId,
  }) async {
    if (failure != null) throw failure!;
    return {'id': 'asset-new', 'url': signedUrl};
  }
}

class _Catalog implements ClinicCatalogRepository {
  final pending = Completer<ClinicModel>();
  Map<String, dynamic>? payload;

  @override
  Future<ClinicModel> updateClinicProfile(Map<String, dynamic> data) {
    payload = data;
    return pending.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Admin implements AdminRepository {
  final pending = Completer<AdminDashboardModel>();
  @override
  Future<AdminDashboardModel> getDashboard() => pending.future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Referrals implements ReferralRepository {
  final pending = Completer<PatientReferralStatusModel>();
  @override
  Future<PatientReferralStatusModel> getMyReferralStatus() => pending.future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ClinicModel _clinic({String logo = 'https://storage.example/old.png'}) =>
    ClinicModel.fromJson({
      'id': 'clinic-a',
      'name_en': 'Original clinic',
      'name_ar': 'العيادة',
      'logo': logo,
      'cover_image': 'https://storage.example/cover.png',
      'description_en': 'Original English',
      'description_ar': 'الوصف',
    });

Future<void> _saveProfile(
  ClinicPortalService service, {
  String? logo,
  bool clearLogo = false,
}) => service.updateClinicProfile(
  nameAr: 'الجديد',
  nameEn: 'New clinic',
  descriptionAr: 'وصف جديد',
  descriptionEn: 'New English',
  phone: '+971501234567',
  whatsapp: '+971501234567',
  logo: logo,
  clearLogo: clearLogo,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ClinicPortalService().resetTestingState();
    AdminPortalService().resetTestingState();
    ReferralService().resetTestingState();
  });
  tearDown(() {
    ClinicPortalService().resetTestingState();
    AdminPortalService().resetTestingState();
    ReferralService().resetTestingState();
  });

  test(
    'international phone normalization retains +44, +33, +49 and UAE local numbers',
    () {
      const examples = {
        '+44 7911-123456': '+447911123456',
        '+33 6-12-34-56-78': '+33612345678',
        '+49 151-12345678': '+4915112345678',
        '0044 7911123456': '+447911123456',
        '0501234567': '+971501234567',
        '501234567': '+971501234567',
        '971501234567': '+971501234567',
        '+971 50 1234567': '+971501234567',
      };
      for (final entry in examples.entries) {
        expect(AuthRepository.normalizePhone(entry.key), entry.value);
      }
    },
  );

  test(
    'partial lead status response preserves all original lead details',
    () async {
      final api = _Api()..result = {'status': 'closed'};
      final existing = AppointmentRequestModel.fromJson({
        'id': 'lead-a',
        'patient_name': 'Mariam',
        'patient_phone': '+447911123456',
        'service_name': 'Skin consultation',
        'created_at': '2026-09-22T10:00:00Z',
        'reference_code': 'REQ-123',
        'clinic': 'clinic-a',
        'internal_notes': [
          {
            'id': 'note-a',
            'note': 'Call back',
            'created_at': '2026-09-22T10:00:00Z',
          },
        ],
      });
      final updated = await ClinicLeadsRepository(apiClient: api)
          .updateLeadStatus(
            existing.id,
            AppointmentLeadStatus.closed,
            existingLead: existing,
          );
      expect(updated.status, AppointmentLeadStatus.closed);
      expect(updated.id, existing.id);
      expect(updated.patientFullName, existing.patientFullName);
      expect(updated.patientPhone, existing.patientPhone);
      expect(updated.serviceNameAr, existing.serviceNameAr);
      expect(updated.createdAt, existing.createdAt);
      expect(updated.internalNotes, same(existing.internalNotes));
    },
  );

  test(
    'both product lead types parse without invented scheduling metadata',
    () {
      for (final type in ['product', 'product_inquiry']) {
        final lead = AppointmentRequestModel.fromJson({'lead_type': type});
        expect(lead.isProductInquiry, isTrue);
        expect(lead.serviceNameAr, 'استفسار عن منتج طبي');
        expect(lead.preferredDate, isNull);
        expect(lead.preferredTimeWindow, isNull);
        expect(lead.toCreatePayload()['lead_type'], 'product_inquiry');
        expect(lead.toCreatePayload()['preferred_time_window'], '');
        expect(lead.toCreatePayload(), isNot(contains('preferred_date')));
      }
    },
  );

  test(
    'upload failures propagate unchanged and prevent catalog PATCH',
    () async {
      final api = _Api();
      const failure = ApiException(
        message: 'Image exceeds size limit',
        statusCode: 400,
      );
      final uploader = _Uploader()..failure = failure;
      final repository = ClinicCatalogRepository(
        apiClient: api,
        mediaUploadService: uploader,
      );
      await expectLater(
        repository.updatePractitioner('p-a', {'avatar': '/selected/photo.png'}),
        throwsA(same(failure)),
      );
      expect(api.patchBodies, isEmpty);
    },
  );

  test(
    'new catalog image sends the uploaded URL and asset ID; removal clears both',
    () async {
      final api = _Api();
      final repository = ClinicCatalogRepository(
        apiClient: api,
        mediaUploadService: _Uploader(),
      );
      await repository.updatePractitioner('p-a', {
        'avatar': '/selected/photo.png',
      });
      expect(api.patchBodies.last, {
        'avatar': _Uploader.signedUrl,
        'media_asset': 'asset-new',
      });
      await repository.updatePractitioner('p-a', {'avatar': null});
      expect(api.patchBodies.last, {'avatar': null, 'media_asset': null});
    },
  );

  test(
    'profile repository preserves URL signatures, null removals and omitted media',
    () async {
      final api = _Api();
      final repository = ClinicCatalogRepository(
        apiClient: api,
        mediaUploadService: _Uploader(),
      );
      await repository.updateClinicProfile({
        'logo': _Uploader.signedUrl,
        'cover_image': null,
      });
      expect(api.patchBodies.last, {
        'logo': _Uploader.signedUrl,
        'cover_image': null,
      });
      await repository.updateClinicProfile({'name_en': 'Only text'});
      expect(api.patchBodies.last, {'name_en': 'Only text'});
    },
  );

  test(
    'profile can replace one local image and clear the other in a single JSON PATCH',
    () async {
      final directory = Directory.systemTemp.createTempSync('aw-media-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final image = File('${directory.path}/logo.png')
        ..writeAsBytesSync([1, 2, 3]);
      final api = _Api();
      final repository = ClinicCatalogRepository(
        apiClient: api,
        mediaUploadService: _Uploader(),
      );
      await repository.updateClinicProfile({
        'logo': image.path,
        'cover_image': null,
      });
      expect(api.patchBodies.single, {
        'logo': _Uploader.signedUrl,
        'cover_image': null,
      });
    },
  );

  test(
    'missing selected profile file fails instead of silently saving text',
    () async {
      final api = _Api();
      final repository = ClinicCatalogRepository(
        apiClient: api,
        mediaUploadService: _Uploader(),
      );
      await expectLater(
        repository.updateClinicProfile({
          'logo': '/missing/logo.png',
          'name_en': 'New',
        }),
        throwsA(isA<ApiException>()),
      );
      expect(api.patchBodies, isEmpty);
    },
  );

  test(
    'profile state commits only after success and signed URLs are unchanged',
    () async {
      final service = ClinicPortalService();
      final original = _clinic();
      service.setActiveClinicForTesting(original);
      final catalog = _Catalog();
      service.setCatalogRepositoryForTesting(catalog);
      final saving = _saveProfile(service, logo: '/selected/photo.png');
      expect(service.activeClinic, same(original));
      catalog.pending.complete(_clinic(logo: _Uploader.signedUrl));
      await saving;
      expect(service.activeClinic.logoUrl, _Uploader.signedUrl);
    },
  );

  test(
    'failed profile save leaves the original model intact and sends explicit null',
    () async {
      final service = ClinicPortalService();
      final original = _clinic();
      service.setActiveClinicForTesting(original);
      final catalog = _Catalog();
      service.setCatalogRepositoryForTesting(catalog);
      final saving = _saveProfile(service, clearLogo: true);
      expect(catalog.payload, containsPair('logo', null));
      final failed = expectLater(saving, throwsA(isA<ApiException>()));
      catalog.pending.completeError(
        const ApiException(message: 'Storage unavailable'),
      );
      await failed;
      expect(service.activeClinic, same(original));
    },
  );

  test('old clinic save cannot repopulate a cleared session', () async {
    final service = ClinicPortalService();
    service.setActiveClinicForTesting(_clinic());
    final catalog = _Catalog();
    service.setCatalogRepositoryForTesting(catalog);
    final saving = _saveProfile(service);
    final stale = expectLater(saving, throwsA(isA<SessionChangedException>()));
    service.clearSession();
    catalog.pending.complete(_clinic());
    await stale;
    expect(service.activeClinic.id, isNot('clinic-a'));
    expect(service.clinicLeads, isEmpty);
  });

  test(
    'old admin and referral responses cannot repopulate cleared sessions',
    () async {
      final repository = _Admin();
      final admin = AdminPortalService(repository: repository);
      final referrals = _Referrals();
      final referral = ReferralService()..setRepositoryForTesting(referrals);
      final adminLoading = admin.loadDashboard();
      final referralLoading = referral.loadReferralStatus();
      admin.clearSession();
      referral.clearSession();
      repository.pending.complete(const AdminDashboardModel(totalClinics: 999));
      referrals.pending.complete(
        PatientReferralStatusModel.fromJson({
          'referral_code': 'OLD',
          'current_points': 999,
        }),
      );
      await Future.wait([adminLoading, referralLoading]);
      expect(admin.dashboard.totalClinics, 0);
      expect(referral.statusModel, isNull);
      expect(referral.isLoading, isFalse);
      expect(referral.successfulInvites, 0);
      expect(referral.userReferralCode, isEmpty);
    },
  );

  test('logout clears all portals and local favorites', () async {
    final clinic = ClinicPortalService()..enableMockMode();
    final admin = AdminPortalService()..enableMockMode();
    final referral = ReferralService()
      ..enableMockMode(testInvites: 35, testPoints: 900);
    AuthState().login(name: 'Previous account', phone: '+971501234567');
    AuthState().toggleFavorite('clinic-private');
    await AuthRepository(apiClient: _Api()).logout();
    expect(clinic.clinicLeads, isEmpty);
    expect(clinic.clinicOffers, isEmpty);
    expect(admin.clinics, isEmpty);
    expect(admin.allProducts, isEmpty);
    expect(referral.statusModel, isNull);
    expect(referral.successfulInvites, 0);
    expect(referral.currentPoints, 0);
    expect(AuthState().favoriteClinicIds, isEmpty);
    expect(AuthState().isLoggedIn, isFalse);
  });

  testWidgets('offer editor prefills existing data and saves with PATCH', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    LocaleService().setLanguage(AppLanguage.english);
    final api = _Api()
      ..result = {'id': 'offer-a', 'title_en': 'Existing offer'};
    ClinicPortalService().setCatalogRepositoryForTesting(
      ClinicCatalogRepository(apiClient: api, mediaUploadService: _Uploader()),
    );
    final offer = OfferModel.fromJson({
      'id': 'offer-a',
      'title_en': 'Existing offer',
      'title_ar': 'العرض الحالي',
      'original_price': '400',
      'offer_price': '250',
      'description_en': 'Original terms',
      'description_ar': 'الشروط',
      'starts_at': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
      'ends_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'status': 'suspended',
      'is_active': false,
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showClinicOfferEditor(
                context,
                LocaleService(),
                existing: offer,
              ),
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    expect(find.text('Existing offer'), findsOneWidget);
    expect(find.text('Original terms'), findsOneWidget);
    final save = find.text(LocaleService().tr('clinic_offer_save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(api.postBodies, isEmpty);
    expect(api.patchBodies.single['title_en'], 'Existing offer');
    expect(api.patchBodies.single['status'], 'suspended');
    expect(api.patchBodies.single['is_active'], false);
    expect(api.patchBodies.single, isNot(contains('image')));
  });

  testWidgets('offer upload error stays visible inline and modal stays open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    LocaleService().setLanguage(AppLanguage.english);
    final api = _Api();
    final uploader = _Uploader()
      ..failure = const ApiException(
        message: 'Upload rejected: image is too large',
      );
    ClinicPortalService().setCatalogRepositoryForTesting(
      ClinicCatalogRepository(apiClient: api, mediaUploadService: uploader),
    );
    final offer = OfferModel.fromJson({
      'id': 'offer-a',
      'title_en': 'Existing offer',
      'title_ar': 'العرض الحالي',
      'original_price': '400',
      'offer_price': '250',
      'starts_at': DateTime.now().toIso8601String(),
      'ends_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showClinicOfferEditor(
                context,
                LocaleService(),
                existing: offer,
              ),
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    tester
        .widget<LuxuryImagePickerField>(find.byType(LuxuryImagePickerField))
        .onImageSelected('/selected/image.png');
    final save = find.text(LocaleService().tr('clinic_offer_save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, 1400));
    await tester.pumpAndSettle();
    expect(find.byType(LuxuryImagePickerField), findsOneWidget);
    expect(find.text('Upload rejected: image is too large'), findsOneWidget);
    expect(api.patchBodies, isEmpty);
    // Close the editor so its controller cleanup completes within the test.
    Navigator.of(tester.element(find.byType(LuxuryImagePickerField))).pop();
    await tester.pumpAndSettle();
  });

  test('subscription API values match Django choices', () {
    expect(SubscriptionTier.values.map((tier) => tier.apiValue), [
      'vip',
      'featured',
      'basic',
    ]);
  });

  test(
    'normal gold labels and input hints meet 4.5:1 on their theme surfaces',
    () {
      double contrast(Color foreground, Color background) {
        final fg = Color.alphaBlend(foreground, background).computeLuminance();
        final bg = background.computeLuminance();
        return fg > bg ? (fg + 0.05) / (bg + 0.05) : (bg + 0.05) / (fg + 0.05);
      }

      expect(
        contrast(AppColors.lightGoldText, AppColors.lightCardSurfaceHover),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColors.darkGold, AppColors.cardSurfaceHover),
        greaterThanOrEqualTo(4.5),
      );
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        expect(
          contrast(
            theme.inputDecorationTheme.hintStyle!.color!,
            theme.inputDecorationTheme.fillColor!,
          ),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );
}
