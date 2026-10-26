import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/widgets/luxury_image_picker_field.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_media_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_media_screen.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'onboarding_review_workflows_test.dart' as f;
import 'clinic_media_contract_test.dart' as g;
import 'admin_media_polish_test.dart' show Wire;
import 'support/patient_visual_harness.dart';

class ReviewGallery extends g.Gallery {
  bool loseOnce = false, hideReads = false;
  int reads = 0;
  @override
  Future<List<ClinicGalleryAsset>> getGallery(
    String clinicId, {
    int page = 1,
  }) async {
    reads++;
    return hideReads ? [] : super.getGallery(clinicId, page: page);
  }

  @override
  Future<ClinicGalleryAsset> uploadGallery(
    String clinicId,
    String path, {
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    onSendProgress?.call(0, 100);
    final result = await super.uploadGallery(clinicId, path);
    onSendProgress?.call(100, 100);
    if (loseOnce && uploaded.length == 2) {
      loseOnce = false;
      throw const ApiException(
        message: 'Connection lost.',
        errorCode: 'CONNECTION_ERROR',
      );
    }
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  late ApiClient api;
  late HttpClientAdapter old;
  late ImagePickerPlatform previous;
  late g.Picker picker;
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
    api.dio.httpClientAdapter = f.Adapter(
      (r) => f.body({
        ...f.clinic(),
        'id': g.clinicId,
        'cover_image': 'https://fixture.invalid/independent-cover.png',
      }),
    );
    final s = ClinicPortalService()..resetTestingState();
    s.setCatalogRepositoryForTesting(ClinicCatalogRepository(apiClient: api));
    s.setActiveClinicForTesting(
      ClinicModel.fromJson({...f.clinic(), 'id': g.clinicId}),
    );
    previous = ImagePickerPlatform.instance;
    picker = g.Picker();
    ImagePickerPlatform.instance = picker;
  });
  tearDown(() {
    api.dio.httpClientAdapter = old;
    ImagePickerPlatform.instance = previous;
    ClinicPortalService().resetTestingState();
    AuthState().logout();
  });
  test(
    'PNG and JPEG stream real bytes and progress; fresh repository and deletion retain ownership',
    () async {
      final assets = <Map<String, dynamic>>[];
      final wire = Wire((r) {
        if (r.method == 'POST') {
          final id = assets.isEmpty ? g.assetId : f.proposalId;
          final mime = (r.data as FormData).files.single.value.contentType
              .toString();
          final d = {...g.asset(id: id), 'mime_type': mime};
          assets.add(d);
          return f.body(d, 201);
        }
        if (r.method == 'DELETE') {
          assets.removeWhere((d) => r.path.contains('${d['id']}'));
          return f.body({}, 204);
        }
        return f.body(f.page(assets));
      });
      api.dio.httpClientAdapter = wire;
      final repo = ClinicMediaRepository(apiClient: api);
      final progress = <int>[];
      for (final path in [
        g.fixture.path,
        File('test/fixtures/media/fragrance_photo.jpg').absolute.path,
      ]) {
        await repo.uploadGallery(
          g.clinicId,
          path,
          onSendProgress: (s, t) => progress.add(s),
        );
      }
      expect(wire.requests.where((r) => r.method == 'POST'), hasLength(2));
      expect(progress, isNotEmpty);
      expect((wire.requests.first.data as FormData).files.single.key, 'file');
      expect(wire.sent.first.length, greaterThan(g.fixture.lengthSync()));
      final fresh = await ClinicMediaRepository(
        apiClient: api,
      ).getGallery(g.clinicId);
      expect(fresh, hasLength(2));
      await repo.deleteGallery(g.clinicId, fresh.first);
      expect(await repo.getGallery(g.clinicId), hasLength(1));
      expect(
        wire.requests.every((r) => !r.path.contains('clinic-portal/profile')),
        true,
      );
    },
  );
  Future<void> select(WidgetTester t, ReviewGallery repo) async {
    await t.binding.setSurfaceSize(const Size(600, 1600));
    await t.pumpWidget(MaterialApp(home: ClinicMediaScreen(repository: repo)));
    await t.pumpAndSettle();
    await t.tap(find.byType(LuxuryImagePickerField).first);
    await t.pumpAndSettle();
    await t.tap(find.text('Choose from Gallery'));
    await t.pumpAndSettle();
  }

  testWidgets(
    'missing local file never POSTs or pretends an uncertain server save; queue action stays visible',
    (t) async {
      final wire = Wire(
        (r) => f.body(
          r.path == 'media/' ? f.page([]) : {...f.clinic(), 'id': g.clinicId},
        ),
      );
      api.dio.httpClientAdapter = wire;
      picker.files = [
        XFile(
          '${Directory.systemTemp.path}/aw-missing-image-does-not-exist.jpg',
        ),
      ];
      await t.binding.setSurfaceSize(const Size(430, 900));
      await t.pumpWidget(const MaterialApp(home: ClinicMediaScreen()));
      await t.pumpAndSettle();
      await t.tap(find.byType(LuxuryImagePickerField).first);
      await t.pumpAndSettle();
      await t.tap(find.text('Choose from Gallery'));
      await t.pumpAndSettle();
      expect(
        t.getRect(find.text('Upload selected photos')).bottom,
        lessThan(900),
      );
      await t.tap(find.text('Upload selected photos'));
      await g.finishNativeWork(
        t,
        () => find
            .textContaining('Please select the media file again.')
            .evaluate()
            .isNotEmpty,
      );
      await t.pumpAndSettle();
      expect(wire.requests.where((r) => r.method == 'POST'), isEmpty);
      expect(find.text('Review saved images'), findsNothing);
      expect(
        find.textContaining('Please select the media file again.'),
        findsOneWidget,
      );
      await t.pumpWidget(const SizedBox());
      await t.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'lost second response blocks blind reupload; refresh and discard stored duplicate sends no third POST',
    (t) async {
      final repo = ReviewGallery()..loseOnce = true;
      picker.files = [
        XFile(g.fixture.path),
        XFile(File('test/fixtures/media/fragrance_photo.jpg').absolute.path),
      ];
      await select(t, repo);
      await t.tap(find.text('Upload selected photos'));
      await t.pumpAndSettle();
      expect(repo.uploaded, hasLength(2));
      expect(repo.saved, hasLength(2));
      expect(find.text('Remove from upload queue'), findsOneWidget);
      await t.tap(find.text('Upload selected photos'), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(repo.uploaded, hasLength(2));
      await t.tap(find.text('Refresh saved images'));
      await t.pumpAndSettle();
      expect(repo.reads, greaterThan(1));
      await t.tap(find.text('Remove from upload queue'));
      await t.pumpAndSettle();
      expect(repo.uploaded, hasLength(2));
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(
        MaterialApp(home: ClinicMediaScreen(repository: repo)),
      );
      await t.pumpAndSettle();
      expect(find.text('Delete this photo'), findsNWidgets(2));
      expect(
        ClinicPortalService().activeClinic.coverImageUrl,
        'https://fixture.invalid/independent-cover.png',
      );
      await t.pumpWidget(const SizedBox());
      await t.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'acknowledged file remains visible with honest pending-verification state when fresh read is stale',
    (t) async {
      final repo = ReviewGallery()..hideReads = true;
      picker.files = [XFile(g.fixture.path)];
      await select(t, repo);
      await t.tap(find.text('Upload selected photos'));
      await t.pumpAndSettle();
      expect(repo.uploaded, hasLength(1));
      expect(find.text('Awaiting saved-gallery verification'), findsOneWidget);
      expect(find.text('Remove from upload queue'), findsNothing);
      repo.hideReads = false;
      await t.tap(find.text('Refresh saved images'));
      await t.pumpAndSettle();
      expect(find.text('Awaiting saved-gallery verification'), findsNothing);
      expect(repo.uploaded, hasLength(1));
      await t.pumpWidget(const SizedBox());
      await t.binding.setSurfaceSize(null);
    },
  );
}
