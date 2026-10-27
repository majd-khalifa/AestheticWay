import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/services/local_media_cache.dart';
import 'package:aesthetic_way/core/services/media_operation_trace.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/portal_media_frame.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_image_picker_field.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_media_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/clinics/presentation/widgets/google_clinic_rating.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_media_repository.dart';
import 'package:aesthetic_way/features/google_business/models/google_business.dart';
import 'package:aesthetic_way/features/google_business/presentation/google_business_screen.dart';
import 'clinic_media_contract_test.dart' as g;
import 'admin_media_polish_test.dart' as media;
import 'google_business_readiness_test.dart' as business;
import 'onboarding_review_workflows_test.dart' as f;
import 'support/patient_visual_harness.dart';
import 'support/settle_preview_images.dart';

class ReturningPicker extends g.Picker {
  final result = Completer<List<XFile>>();
  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) => result.future;
}

class LifecycleProfile extends g.Profile {
  Completer<ClinicModel>? hold;
  int reads = 0;
  @override
  Future<ClinicModel> getClinicProfile() async {
    reads++;
    return hold?.future ?? current;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  testWidgets(
    'Android picker return cannot discard gallery selection during profile refresh',
    (t) async {
      FlutterSecureStorage.setMockInitialValues({});
      AuthState().login(
        name: 'Disposable QA',
        phone: 'fixture',
        role: 'clinic_admin',
      );
      final service = ClinicPortalService()..resetTestingState();
      final profile = LifecycleProfile();
      service.setCatalogRepositoryForTesting(profile);
      service.setActiveClinicForTesting(profile.current);
      final previous = ImagePickerPlatform.instance;
      final picker = ReturningPicker();
      ImagePickerPlatform.instance = picker;
      addTearDown(() async {
        if (profile.hold case final pending? when !pending.isCompleted) {
          pending.complete(profile.current);
        }
        ImagePickerPlatform.instance = previous;
        service.resetTestingState();
        AuthState().logout();
        await t.binding.setSurfaceSize(null);
      });
      await t.binding.setSurfaceSize(const Size(600, 1600));
      await t.pumpWidget(
        MaterialApp(home: ClinicMediaScreen(repository: g.Gallery())),
      );
      await t.pumpAndSettle();
      await t.tap(find.byType(LuxuryImagePickerField).first);
      await t.pumpAndSettle();
      await t.tap(find.text('Choose from Gallery'));
      await t.pump();
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await t.pump();
      profile.hold = Completer<ClinicModel>();
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      picker.result.complete([XFile(g.fixture.path)]);
      await t.pump();
      profile.hold!.complete(profile.current);
      await t.pumpAndSettle();
      expect(find.text('Remove from upload queue'), findsOneWidget);
      expect(find.text('Upload selected photos'), findsOneWidget);
      expect(profile.reads, 1);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pumpAndSettle();
      expect(profile.reads, 2); // Normal foreground refresh remains enabled.
      expect(t.takeException(), isNull);
    },
  );
  galleryAndRatingContracts();
}

void galleryAndRatingContracts() {
  group('c25e901 gallery and rating contract recovery', () {
    final api = ApiClient();
    late HttpClientAdapter original;
    late ImagePickerPlatform oldPicker;
    late String oldBase;
    late media.Wire wire;
    late g.Picker picker;
    late List<Map<String, dynamic>> saved;
    bool profileMissing = false;
    int? galleryFailure, profileFailure;
    int uploadStatus = 201;
    Map<String, dynamic>? ackOverride;
    Completer<ResponseBody>? heldGallery;
    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      await TokenStorage().clear();
      await LocaleService().setLanguage(AppLanguage.english);
      AuthState().login(
        name: 'Disposable QA',
        phone: 'fixture',
        role: 'clinic_admin',
      );
      original = api.dio.httpClientAdapter;
      oldBase = api.dio.options.baseUrl;
      api.updateBaseUrl('https://fixture.invalid/api/v1/');
      oldPicker = ImagePickerPlatform.instance;
      picker = g.Picker()..files = [XFile(g.fixture.path)];
      ImagePickerPlatform.instance = picker;
      saved = [];
      profileMissing = false;
      galleryFailure = profileFailure = null;
      uploadStatus = 201;
      ackOverride = null;
      heldGallery = null;
      wire = media.Wire((r) {
        if (r.method == 'POST') {
          final data = ackOverride ?? g.asset();
          if (uploadStatus == 201) saved.add(data);
          return f.body(data, uploadStatus);
        }
        if (r.path == 'media/') {
          if (heldGallery != null) return heldGallery!.future;
          if (saved.isNotEmpty && galleryFailure != null) {
            return f.body({
              'error': {
                'code': 'PERMISSION_DENIED',
                'message': 'Private diagnostic must not leak',
              },
            }, galleryFailure!);
          }
          return f.body(f.page(saved));
        }
        if (saved.isNotEmpty && profileFailure != null) {
          return f.body({
            'error': {
              'code': 'PERMISSION_DENIED',
              'message': 'Private diagnostic must not leak',
            },
          }, profileFailure!);
        }
        return f.body({
          ...f.clinic(),
          'id': g.clinicId,
          'gallery_images': profileMissing
              ? []
              : saved.map((a) => a['url']).toList(),
        });
      });
      api.dio.httpClientAdapter = wire;
      final service = ClinicPortalService()..resetTestingState();
      service.setCatalogRepositoryForTesting(
        ClinicCatalogRepository(apiClient: api),
      );
      service.setActiveClinicForTesting(
        ClinicModel.fromJson({...f.clinic(), 'id': g.clinicId}),
      );
      LocalMediaCache().clear();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    });
    tearDown(() {
      api.dio.httpClientAdapter = original;
      api.updateBaseUrl(oldBase);
      ImagePickerPlatform.instance = oldPicker;
      debugNetworkImageHttpClientProvider = null;
      LocalMediaCache().clear();
      ClinicPortalService().resetTestingState();
      AuthState().logout();
    });
    test(
      'real multipart bytes, boundary, fields and 201 acknowledgment are retained',
      () async {
        final trace = MediaOperationTrace();
        final asset = await ClinicMediaRepository(
          apiClient: api,
        ).uploadGallery(g.clinicId, g.fixture.path, trace: trace);
        final request = wire.requests.single;
        expect(request.method, 'POST');
        expect(request.path, 'media/upload/');
        expect(
          request.contentType,
          startsWith('multipart/form-data; boundary='),
        );
        final form = request.data as FormData;
        expect(Map.fromEntries(form.fields), {
          'media_type': 'clinic_gallery',
          'clinic_id': g.clinicId,
        });
        expect(form.files.single.key, 'file');
        expect(form.files.single.value.contentType.toString(), 'image/png');
        expect(
          wire.sent.single,
          containsAllInOrder(g.fixture.readAsBytesSync()),
        );
        expect(asset.id, g.assetId);
        expect(trace.uploadHttpStatus, 201);
        expect(trace.assetAcknowledged, true);
        expect(trace.stage, MediaOperationStage.acknowledgment);
      },
    );
    for (final c in [
      (202, <String, dynamic>{}, 'not_created'),
      (201, <String, dynamic>{'id': g.assetId}, 'incomplete'),
      (201, {...g.asset(), 'mime_type': 'video/mp4'}, 'video_not_image'),
      (201, {...g.asset(), 'clinic_id': f.id}, 'foreign_clinic'),
    ]) {
      test(
        'invalid upload acknowledgment preserves actual HTTP status: ${c.$3}',
        () async {
          uploadStatus = c.$1;
          ackOverride = c.$2;
          final trace = MediaOperationTrace();
          await expectLater(
            ClinicMediaRepository(
              apiClient: api,
            ).uploadGallery(g.clinicId, g.fixture.path, trace: trace),
            throwsA(
              isA<ApiException>()
                  .having((e) => e.statusCode, 'status', c.$1)
                  .having((e) => e.errorCode, 'code', 'INVALID_MEDIA_ACK'),
            ),
          );
          expect(trace.assetAcknowledged, false);
          expect(trace.stage, MediaOperationStage.acknowledgment);
          expect(trace.uploadHttpStatus, c.$1);
          expect(wire.requests, hasLength(1));
        },
      );
    }
    test(
      'safe support facts do not expose unrecognized codes, fields or response values',
      () {
        final trace = MediaOperationTrace()
          ..failed(
            const ApiException(
              message: 'sensitive-raw-message',
              statusCode: 400,
              errorCode: 'unexpected-sensitive-code',
              fieldErrors: {
                'file': ['sensitive-filename'],
                'patient_phone': ['private-number'],
              },
            ),
          );
        expect(trace.supportDetails, contains('HTTP=400'));
        expect(trace.supportDetails, contains('fields=file'));
        expect(trace.supportDetails, contains('UNRECOGNIZED_API_CODE'));
        for (final secret in [
          'sensitive-',
          'patient_phone',
          'private-number',
        ]) {
          expect(trace.supportDetails, isNot(contains(secret)));
        }
      },
    );
    for (final failure in [
      (400, 'VALIDATION_ERROR'),
      (403, 'PERMISSION_DENIED'),
      (500, 'SERVER_ERROR'),
      (503, 'STORAGE_ERROR'),
    ]) {
      test(
        'upload rejection reports actual status/code/field without POST retry: ${failure.$1}',
        () async {
          uploadStatus = failure.$1;
          ackOverride = {
            'error': {
              'code': failure.$2,
              'message': 'sensitive-backend-body',
              'fields': {
                'file': [
                  'The uploaded file is not a valid image or is corrupted.',
                ],
              },
            },
          };
          final trace = MediaOperationTrace();
          await expectLater(
            ClinicMediaRepository(
              apiClient: api,
            ).uploadGallery(g.clinicId, g.fixture.path, trace: trace),
            throwsA(
              isA<ApiException>().having(
                (e) => e.statusCode,
                'actual HTTP',
                failure.$1,
              ),
            ),
          );
          expect(trace.httpStatus, failure.$1);
          expect(trace.uploadHttpStatus, failure.$1);
          expect(trace.code, failure.$2);
          if (failure.$1 < 500) expect(trace.fields, ['file']);
          expect(trace.assetAcknowledged, false);
          expect(trace.stage, MediaOperationStage.multipartUpload);
          expect(
            trace.supportDetails,
            isNot(contains('sensitive-backend-body')),
          );
          expect(wire.requests.where((r) => r.method == 'POST'), hasLength(1));
        },
      );
    }
    Future<void> selectAndUpload(WidgetTester t) async {
      await t.binding.setSurfaceSize(const Size(600, 1800));
      await t.pumpWidget(const MaterialApp(home: ClinicMediaScreen()));
      await t.pumpAndSettle();
      await t.tap(find.byType(LuxuryImagePickerField).first);
      await t.pumpAndSettle();
      await t.tap(find.text('Choose from Gallery'));
      await t.pumpAndSettle();
      await t.tap(find.text('Upload selected photos'));
      await g.finishNativeWork(t, () => saved.isNotEmpty);
      await t.pumpAndSettle();
    }

    Future<void> details(WidgetTester t) async {
      final toggle = find.byKey(const ValueKey('gallery-support-details'));
      await t.ensureVisible(toggle);
      await t.tap(toggle);
      await t.pumpAndSettle();
    }

    testWidgets(
      'manual fresh-read locks mutation until completion; its optimistic state cannot verify a later POST',
      (t) async {
        await t.binding.setSurfaceSize(const Size(600, 1800));
        await t.pumpWidget(const MaterialApp(home: ClinicMediaScreen()));
        await t.pumpAndSettle();
        await t.tap(find.byType(LuxuryImagePickerField).first);
        await t.pumpAndSettle();
        await t.tap(find.text('Choose from Gallery'));
        await t.pumpAndSettle();
        heldGallery = Completer<ResponseBody>();
        await t.ensureVisible(find.text('Refresh saved images'));
        await t.tap(find.text('Refresh saved images'));
        await t.pump();
        final save = find.widgetWithText(
          SilverButton,
          'Upload selected photos',
        );
        expect(t.widget<SilverButton>(save).onPressed, isNull);
        expect(wire.requests.where((r) => r.method == 'POST'), isEmpty);
        heldGallery!.complete(f.body(f.page([])));
        heldGallery = null;
        await t.pumpAndSettle();
        expect(t.widget<SilverButton>(save).onPressed, isNotNull);
        await t.tap(save);
        await g.finishNativeWork(t, () => saved.isNotEmpty);
        await t.pumpAndSettle();
        await details(t);
        expect(
          find.textContaining('gallery_read=verified; profile_read=verified'),
          findsOneWidget,
        );
        expect(wire.requests.where((r) => r.path == 'media/').length, 3);
        expect(wire.requests.where((r) => r.method == 'POST'), hasLength(1));
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await t.binding.setSurfaceSize(null);
      },
    );

    testWidgets(
      '201 plus gallery read does not falsely confirm a missing profile association; refresh recovers without POST replay',
      (t) async {
        profileMissing = true;
        await selectAndUpload(t);
        expect(
          find.textContaining('fresh clinic profile has not confirmed'),
          findsOneWidget,
        );
        await details(t);
        expect(find.textContaining('upload_HTTP=201'), findsOneWidget);
        expect(
          find.textContaining(
            'asset_ack=yes; gallery_read=verified; profile_read=unconfirmed',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('PROFILE_GALLERY_UNCONFIRMED'),
          findsOneWidget,
        );
        profileMissing = false;
        await t.ensureVisible(find.text('Refresh saved images'));
        await t.tap(find.text('Refresh saved images'));
        await t.pumpAndSettle();
        expect(
          find.textContaining('fresh clinic profile has not confirmed'),
          findsNothing,
        );
        expect(
          find.text('Saved gallery records and clinic profile verified.'),
          findsOneWidget,
        );
        expect(wire.requests.where((r) => r.method == 'POST'), hasLength(1));
        expect(wire.requests.any((r) => r.method == 'PATCH'), false);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await t.binding.setSurfaceSize(null);
      },
    );
    for (final where in ['gallery', 'profile']) {
      testWidgets(
        'read-back HTTP403 keeps upload acknowledgment separate: $where',
        (t) async {
          if (where == 'gallery') {
            galleryFailure = 403;
          } else {
            profileFailure = 403;
          }
          await selectAndUpload(t);
          await details(t);
          expect(
            find.textContaining('stage=${where}Read; HTTP=403'),
            findsOneWidget,
          );
          expect(find.textContaining('upload_HTTP=201'), findsOneWidget);
          expect(find.textContaining('asset_ack=yes'), findsOneWidget);
          expect(find.textContaining('Private diagnostic'), findsNothing);
          expect(wire.requests.where((r) => r.method == 'POST'), hasLength(1));
          expect(find.text('Remove from upload queue'), findsNothing);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
          await t.binding.setSurfaceSize(null);
        },
      );
    }
    testWidgets(
      'gallery remote verification does not disguise HTTP403 with the remembered local file; retry genuinely decodes',
      (t) async {
        const url = 'https://fixture.invalid/diagnostic-image.png';
        LocalMediaCache().remember(localPath: g.fixture.path, remoteUrl: url);
        expect(resolveImageProvider(url), isA<FileImage>());
        expect(
          resolveImageProvider(url, allowLocalCache: false),
          isA<NetworkImage>(),
        );
        final images = media.Images()..status = 403;
        debugNetworkImageHttpClientProvider = () => images;
        await t.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: PortalMediaFrame(
                  imageUrl: url,
                  height: 240,
                  verifyRemoteDelivery: true,
                ),
              ),
            ),
          ),
        );
        await g.finishNativeWork(
          t,
          () => find.text('Image unavailable').evaluate().isNotEmpty,
        );
        expect(images.requests, 1);
        expect(
          find.textContaining('stage=imageLoad; HTTP=403'),
          findsOneWidget,
        );
        images.status = 200;
        images.bytes = g.fixture.readAsBytesSync();
        await t.tap(find.text('Retry'));
        await t.pumpAndSettle();
        await settlePreviewImages(t);
        expect(find.text('Image unavailable'), findsNothing);
        final decoded = t.widget<RawImage>(find.byType(RawImage).first).image;
        expect(decoded, isNotNull);
        expect(decoded!.width, greaterThan(0));
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        debugNetworkImageHttpClientProvider = null;
      },
    );
    for (final dark in [false, true]) {
      for (final ar in [false, true]) {
        testWidgets(
          'gallery rejection diagnostics preserve the native queue dark=$dark ar=$ar',
          (t) async {
            uploadStatus = 400;
            ackOverride = {
              'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'One or more fields failed validation.',
                'fields': {
                  'file': [
                    'The uploaded file is not a valid image or is corrupted.',
                  ],
                },
              },
            };
            await f.render(t, const ClinicMediaScreen(), dark: dark, ar: ar);
            await t.tap(find.byType(LuxuryImagePickerField).first);
            await t.pumpAndSettle();
            await t.tap(
              find.text(ar ? 'اختيار من معرض الصور' : 'Choose from Gallery'),
            );
            await t.pumpAndSettle();
            await t.tap(
              find.text(ar ? 'رفع الصور المحددة' : 'Upload selected photos'),
            );
            await g.finishNativeWork(
              t,
              () => wire.requests.any((r) => r.method == 'POST'),
            );
            await t.pumpAndSettle();
            await details(t);
            expect(
              find.textContaining('stage=multipartUpload; HTTP=400'),
              findsOneWidget,
            );
            expect(
              find.textContaining('code=VALIDATION_ERROR; fields=file'),
              findsOneWidget,
            );
            expect(
              find.textContaining('asset_ack=unconfirmed'),
              findsOneWidget,
            );
            expect(
              find.text(
                ar ? 'إزالة من قائمة الرفع' : 'Remove from upload queue',
              ),
              findsOneWidget,
            );
            await f.capture(
              t,
              'c25e901_gallery_rejection_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
            );
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox());
            await t.binding.setSurfaceSize(null);
          },
        );
        testWidgets(
          'Google real-field rendering and pending explanation dark=$dark ar=$ar',
          (t) async {
            final clinic = ClinicModel.fromJson({
              ...f.clinic(),
              'google_place_id': 'offline-clinic-place',
              'google_rating': '4.60',
              'google_reviews_count': 42,
            });
            await f.render(
              t,
              Scaffold(body: GoogleClinicRating(clinic: clinic)),
              dark: dark,
              ar: ar,
            );
            expect(find.text('4.6'), findsOneWidget);
            expect(find.text('Google'), findsOneWidget);
            expect(find.textContaining('42'), findsOneWidget);
            await f.capture(
              t,
              'c25e901_rating_valid_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
            );
            for (final data in [
              {
                ...f.clinic(),
                'google_place_id': 'offline-pending',
                'google_rating': null,
                'google_reviews_count': 0,
              },
              {
                ...f.clinic(),
                'google_place_id': '',
                'google_rating': 4.6,
                'google_reviews_count': 42,
              },
              {
                ...f.clinic(),
                'google_place_id': 'offline-invalid',
                'google_rating': 'NaN',
                'google_reviews_count': 42,
              },
            ]) {
              await f.render(
                t,
                Scaffold(
                  body: GoogleClinicRating(clinic: ClinicModel.fromJson(data)),
                ),
                dark: dark,
                ar: ar,
              );
              expect(find.text('Google'), findsNothing);
            }
            final repo = business.BusinessFixture()
              ..state = const GoogleBusinessAssociation(
                clinicId: g.clinicId,
                placeId: 'offline-pending',
                syncStatus: 'pending',
                verification: GoogleBusinessVerification.verified,
              );
            await f.render(
              t,
              GoogleBusinessScreen(repository: repo),
              dark: dark,
              ar: ar,
            );
            expect(
              find.textContaining(
                ar
                    ? 'التحديث يعيد قراءة الحالة ولا يبدأ المزامنة'
                    : 'Refresh reloads the status; it does not start a sync',
              ),
              findsOneWidget,
            );
            await f.capture(
              t,
              'c25e901_rating_pending_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
            );
            await t.ensureVisible(
              find.text(ar ? 'تحديث الارتباط' : 'Refresh association'),
            );
            await t.tap(
              find.text(ar ? 'تحديث الارتباط' : 'Refresh association'),
            );
            await t.pumpAndSettle();
            expect(repo.gets, 2);
            expect(repo.links, isEmpty);
            expect(repo.queries, isEmpty);
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox());
            await t.binding.setSurfaceSize(null);
          },
        );
      }
    }
  });
}
