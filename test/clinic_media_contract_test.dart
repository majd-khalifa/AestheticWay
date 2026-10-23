import 'support/patient_visual_harness.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/luxury_image_picker_field.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_media_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_media_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'products_articles_live_test.dart' show FakeApiClient;
import 'video_lifecycle_test.dart' show TrackingVideoPlatform;
import 'support/settle_preview_images.dart';

const clinicId = '11111111-1111-4111-8111-111111111111';
const assetId = '22222222-2222-4222-8222-222222222222';
final fixture = File('test/fixtures/media/portrait_photo.png').absolute;
Map<String, dynamic> asset({
  String id = assetId,
  String clinic = clinicId,
  String mime = 'image/png',
}) => {
  'id': id,
  'clinic_id': clinic,
  'media_type': 'clinic_gallery',
  'mime_type': mime,
  'url': 'https://aestheticway.ae/media/$id.png',
};

class Picker extends ImagePickerPlatform {
  List<XFile> files = [];
  String? video;
  bool fail = false;
  int calls = 0;
  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    calls++;
    if (fail) throw StateError('permission denied');
    return files;
  }

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => files.firstOrNull;
  @override
  Future<XFile?> getVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) async => video == null ? null : XFile(video!);
}

class Gallery extends ClinicMediaRepository {
  final saved = <ClinicGalleryAsset>[];
  final uploaded = <String>[];
  bool reject = false;
  String? rejectPath;
  Completer<ClinicGalleryAsset>? pending;
  @override
  Future<List<ClinicGalleryAsset>> getGallery(
    String clinicId, {
    int page = 1,
  }) async => List.of(saved);
  @override
  Future<ClinicGalleryAsset> uploadGallery(String clinicId, String path) async {
    uploaded.add(path);
    if (reject || rejectPath == path) {
      throw const ApiException(message: 'Upload rejected', statusCode: 400);
    }
    if (pending != null) return pending!.future;
    final a = ClinicGalleryAsset(
      id: '$assetId-${uploaded.length}',
      clinicId: clinicId,
      url: path,
    );
    saved.add(a);
    return a;
  }

  @override
  Future<void> deleteGallery(String clinicId, ClinicGalleryAsset a) async {
    if (reject) {
      throw const ApiException(message: 'Removal rejected', statusCode: 403);
    }
    saved.removeWhere((x) => x.id == a.id);
  }
}

class ShortVideoPlatform extends TrackingVideoPlatform {
  final probed = Completer<void>();
  @override
  Future<void> dispose(int playerId) async {
    await super.dispose(playerId);
    if (playerId == 0 && !probed.isCompleted) probed.complete();
  }

  @override
  void initialize(int id) => streams[id]!.add(
    VideoEvent(
      eventType: VideoEventType.initialized,
      size: const Size(64, 64),
      duration: const Duration(seconds: 2),
    ),
  );
}

class Profile implements ClinicCatalogRepository {
  final patches = <Map<String, dynamic>>[];
  ClinicModel current = ClinicModel.fromJson({
    'id': clinicId,
    'name_en': 'QA Clinic',
    'name_ar': 'عيادة اختبار',
    'subscription_tier': 'vip',
    'cover_image': fixture.uri.toString(),
    'video_ad_file': 'https://aestheticway.ae/media/showcase.mp4',
  });
  @override
  Future<ClinicModel> getClinicProfile() async => current;
  @override
  Future<ClinicModel> updateClinicProfile(Map<String, dynamic> data) async {
    patches.add(data);
    current = ClinicModel.fromJson({
      'id': clinicId,
      'name_en': 'QA Clinic',
      'subscription_tier': 'vip',
      'cover_image': fixture.uri.toString(),
      'video_ad_file': data.containsKey('video_ad_file')
          ? data['video_ad_file']
          : current.videoUrl,
    });
    return current;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Flush genuine file/stream I/O and Flutter fake-time continuations together.
// Completion is asserted; this does not hide a stuck progress state.
Future<void> finishNativeWork(WidgetTester tester, bool Function() done) async {
  final deadline = Stopwatch()..start();
  while (!done() && deadline.elapsed < const Duration(seconds: 3)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(
    done(),
    isTrue,
    reason: 'Native file/stream work must finish, with no stuck loading state.',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  late Picker picker;
  late ImagePickerPlatform original;
  late Profile profile;
  final service = ClinicPortalService();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    LocaleService().setLanguage(AppLanguage.english);
    original = ImagePickerPlatform.instance;
    picker = Picker();
    ImagePickerPlatform.instance = picker;
    profile = Profile();
    service.resetTestingState();
    service.setCatalogRepositoryForTesting(profile);
    service.setActiveClinicForTesting(profile.current);
  });
  tearDown(() {
    ImagePickerPlatform.instance = original;
    service.resetTestingState();
  });
  test(
    'gallery records require image MIME, asset UUID and matching clinic; MP4 never enters image collection',
    () async {
      expect(ClinicGalleryAsset.fromJson(asset()).url, endsWith('.png'));
      expect(
        () => ClinicGalleryAsset.fromJson(asset(mime: 'video/mp4')),
        throwsA(isA<ApiException>()),
      );
      final repo = ClinicMediaRepository(
        apiClient: FakeApiClient(
          onGet: (_, q) => {
            'results': [asset(clinic: '33333333-3333-4333-8333-333333333333')],
            'next': null,
          },
        ),
      );
      await expectLater(
        repo.getGallery(clinicId),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        repo.deleteGallery('other', ClinicGalleryAsset.fromJson(asset())),
        throwsA(isA<ApiException>()),
      );
    },
  );
  test(
    'gallery list preserves server page envelope and uses only verified asset route',
    () async {
      String? path;
      Map<String, dynamic>? query;
      final repo = ClinicMediaRepository(
        apiClient: FakeApiClient(
          onGet: (p, q) {
            path = p;
            query = q;
            return {
              'results': [asset()],
              'count': 21,
              'next': '?page=2',
            };
          },
        ),
      );
      final result = await repo.getGallery(clinicId, page: 1);
      expect(path, 'media/');
      expect(query, {
        'media_type': 'clinic_gallery',
        'page': 1,
        'page_size': 20,
      });
      expect(result.single.id, assetId);
    },
  );
  test(
    'gallery upload sends real multipart bytes, type and clinic UUID and retains the returned asset ID',
    () async {
      FormData? uploaded;
      final repo = ClinicMediaRepository(
        apiClient: FakeApiClient(
          onGet: (_, _) => {},
          onPost: (path, data) {
            expect(path, 'media/upload/');
            uploaded = data as FormData;
            return asset();
          },
        ),
      );
      final saved = await repo.uploadGallery(clinicId, fixture.path);
      final form = uploaded!;
      expect(Map.fromEntries(form.fields), {
        'media_type': 'clinic_gallery',
        'clinic_id': clinicId,
      });
      expect(form.files.single.key, 'file');
      expect(form.files.single.value.contentType.toString(), 'image/png');
      final bytes = await form.files.single.value.finalize().fold<List<int>>(
        [],
        (all, chunk) => all..addAll(chunk),
      );
      expect(bytes, await fixture.readAsBytes());
      expect(saved.id, assetId);
      expect(saved.clinicId, clinicId);
      expect(saved.url, endsWith('$assetId.png'));
    },
  );
  testWidgets(
    'multi-select and camera callbacks append selected files without replacing an existing gallery',
    (tester) async {
      final selected = <String>[];
      picker.files = [
        XFile(fixture.path),
        XFile(File('test/fixtures/media/fragrance_photo.jpg').absolute.path),
      ];
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: LuxuryImagePickerField(
              label: 'Add gallery photos',
              onImageSelected: (_) {},
              onImagesSelected: selected.addAll,
            ),
          ),
        ),
      );
      await tester.tap(
        find
            .descendant(
              of: find.byType(LuxuryImagePickerField),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from Gallery'));
      await tester.pumpAndSettle();
      expect(picker.calls, 1);
      expect(selected, picker.files.map((f) => f.path));
      await tester.tap(
        find
            .descendant(
              of: find.byType(LuxuryImagePickerField),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take a Photo'));
      await tester.pumpAndSettle();
      expect(selected, [fixture.path, picker.files.last.path, fixture.path]);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'picker cancellation and denied permission preserve the pending selection',
    (tester) async {
      var callbacks = 0;
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: LuxuryImagePickerField(
              label: 'Gallery',
              onImageSelected: (_) {},
              onImagesSelected: (_) => callbacks++,
            ),
          ),
        ),
      );
      for (final denied in [false, true]) {
        picker.fail = denied;
        await tester.tap(
          find
              .descendant(
                of: find.byType(LuxuryImagePickerField),
                matching: find.byType(GestureDetector),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Choose from Gallery'));
        await tester.pumpAndSettle();
        expect(callbacks, 0);
      }
      expect(find.textContaining('Could not select an image'), findsOneWidget);
    },
  );
  for (final dark in [false, true]) {
    for (final arabic in [false, true]) {
      testWidgets(
        'gallery reopen and separate video poster ${dark ? 'dark' : 'light'} ${arabic ? 'ar' : 'en'}',
        (tester) async {
          LocaleService().setLanguage(
            arabic ? AppLanguage.arabic : AppLanguage.english,
          );
          await tester.binding.setSurfaceSize(const Size(390, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final gallery = Gallery()
            ..saved.add(
              ClinicGalleryAsset(
                id: assetId,
                clinicId: clinicId,
                url: fixture.path,
              ),
            )
            ..saved.add(
              ClinicGalleryAsset(
                id: '33333333-3333-4333-8333-333333333333',
                clinicId: clinicId,
                url: File(
                  'test/fixtures/media/fragrance_photo.jpg',
                ).absolute.path,
              ),
            );
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
                  child: ClinicMediaScreen(repository: gallery),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await settlePreviewImages(tester);
          expect(find.byType(LuxuryImage), findsWidgets);
          expect(tester.takeException(), isNull);
          const output = String.fromEnvironment('CLINIC_AUDIT_CAPTURE_DIR');
          Future<void> capture(String name) async {
            if (output.isEmpty) return;
            await tester.runAsync(() async {
              final im =
                  await (key.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage(pixelRatio: 1);
              final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
              im.dispose();
              final file = File(
                '$output/${name}_${dark ? 'dark' : 'light'}_${arabic ? 'ar' : 'en'}.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
            });
          }

          await capture('gallery');
          await tester.scrollUntilVisible(
            find.text(arabic ? 'فيديو عرض العيادة' : 'Clinic showcase video'),
            400,
          );
          await tester.pumpAndSettle();
          await settlePreviewImages(tester);
          await capture('showcase_video');
          final images = tester.widgetList<LuxuryImage>(
            find.byType(LuxuryImage),
          );
          expect(
            images.any((w) => w.imageUrl?.contains('.mp4') ?? false),
            isFalse,
          );
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
      );
    }
  }
  testWidgets(
    'rejected upload retains the queue, retry appends and reopening reloads saved assets',
    (tester) async {
      final gallery = Gallery()
        ..saved.add(
          ClinicGalleryAsset(
            id: assetId,
            clinicId: clinicId,
            url: fixture.path,
          ),
        );
      picker.files = [XFile(fixture.path)];
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(home: ClinicMediaScreen(repository: gallery)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LuxuryImagePickerField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from Gallery'));
      await tester.pumpAndSettle();
      gallery.reject = true;
      await tester.tap(find.text('Upload selected photos'));
      await tester.pumpAndSettle();
      expect(gallery.saved, hasLength(1));
      expect(find.textContaining('Upload rejected'), findsOneWidget);
      gallery.reject = false;
      await tester.tap(find.text('Upload selected photos'));
      await tester.pumpAndSettle();
      expect(gallery.saved, hasLength(2));
      expect(find.text('Upload selected photos'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(home: ClinicMediaScreen(repository: gallery)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Delete this photo'), findsNWidgets(2));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'partial gallery failure retries only remaining files and rapid taps cannot duplicate an in-flight upload',
    (tester) async {
      final second = File(
        'test/fixtures/media/fragrance_photo.jpg',
      ).absolute.path;
      final gallery = Gallery()..rejectPath = second;
      picker.files = [XFile(fixture.path), XFile(second)];
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(home: ClinicMediaScreen(repository: gallery)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LuxuryImagePickerField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from Gallery'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upload selected photos'));
      await tester.pumpAndSettle();
      expect(gallery.saved, hasLength(1));
      expect(gallery.uploaded, [fixture.path, second]);
      expect(find.text('Remove from upload queue'), findsOneWidget);
      gallery.rejectPath = null;
      gallery.pending = Completer<ClinicGalleryAsset>();
      await tester.tap(find.text('Upload selected photos'));
      await tester.pump();
      expect(find.text('Uploaded 0 of 1'), findsOneWidget);
      await tester.tap(find.text('Uploaded 0 of 1'));
      await tester.pump();
      expect(gallery.uploaded, [fixture.path, second, second]);
      final added = ClinicGalleryAsset(
        id: '33333333-3333-4333-8333-333333333333',
        clinicId: clinicId,
        url: second,
      );
      gallery.saved.add(added);
      gallery.pending!.complete(added);
      await tester.pumpAndSettle();
      expect(gallery.saved, hasLength(2));
      expect(find.text('Upload selected photos'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'select supported native video, preview, save, reopen and remove without changing the separate cover',
    (tester) async {
      final originalVideo = VideoPlayerPlatform.instance;
      final video = ShortVideoPlatform();
      VideoPlayerPlatform.instance = video;
      addTearDown(() async {
        VideoPlayerPlatform.instance = originalVideo;
        for (final stream in video.streams.values) {
          await stream.close();
        }
      });
      picker.video = File(
        'test/fixtures/clinic_media/short_showcase.mp4',
      ).absolute.path;
      await tester.binding.setSurfaceSize(const Size(600, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Future<void> mount() async {
        await tester.pumpWidget(
          MaterialApp(home: ClinicMediaScreen(repository: Gallery())),
        );
        await tester.pumpAndSettle();
      }

      await mount();
      await tester.scrollUntilVisible(find.text('Select gallery video'), 300);
      // File signature reads are genuine host I/O, outside Flutter fake time.
      await tester.tap(find.text('Select gallery video'));
      await finishNativeWork(tester, () => video.probed.isCompleted);
      await tester.pumpAndSettle();
      expect(find.text('Upload and save video'), findsOneWidget);
      await tester.tap(find.text('Preview video'));
      await tester.pumpAndSettle();
      expect(video.calls, contains('play:1'));
      final cover = profile.current.coverImageUrl;
      await tester.tap(find.text('Upload and save video'));
      await tester.pump();
      await finishNativeWork(
        tester,
        () => find.text('Upload and save video').evaluate().isEmpty,
      );
      await tester.pumpAndSettle();
      expect(profile.patches.single, {'video_ad_file': picker.video});
      expect(profile.current.coverImageUrl, cover);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await mount();
      expect(find.text('Upload and save video'), findsNothing);
      await tester.scrollUntilVisible(find.text('Remove saved video'), 300);
      await tester.tap(find.text('Remove saved video'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove').last);
      await tester.pumpAndSettle();
      expect(profile.patches.last, {'video_ad_file': null});
      expect(profile.current.videoUrl, isNull);
      expect(profile.current.coverImageUrl, cover);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    },
  );
  testWidgets(
    'saved video preview is lazy, uses a separate image poster and disposes after unmount',
    (tester) async {
      final originalVideo = VideoPlayerPlatform.instance;
      final video = TrackingVideoPlatform();
      VideoPlayerPlatform.instance = video;
      addTearDown(() async {
        VideoPlayerPlatform.instance = originalVideo;
        for (final stream in video.streams.values) {
          await stream.close();
        }
      });
      await tester.pumpWidget(
        MaterialApp(home: ClinicMediaScreen(repository: Gallery())),
      );
      await tester.pumpAndSettle();
      expect(video.created, 0);
      await tester.scrollUntilVisible(find.text('Preview video'), 400);
      await tester.tap(find.text('Preview video'));
      await tester.pumpAndSettle();
      expect(video.created, 1);
      expect(video.calls, contains('play:0'));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
      expect(video.calls, contains('dispose:0'));
    },
  );
}
