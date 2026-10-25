import 'dart:io';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/auth/token_storage.dart';
import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_media_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'clinic_media_contract_test.dart'
    show Gallery, ShortVideoPlatform, finishNativeWork;
import 'admin_media_polish_test.dart' show ObservedPicker, Wire;
import 'onboarding_review_workflows_test.dart' as f;
import 'support/patient_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPatientVisualFonts);
  for (final dark in [false, true]) {
    for (final ar in [false, true]) {
      testWidgets('actual video upload HTTP500 placement dark=$dark ar=$ar', (
        tester,
      ) async {
        FlutterSecureStorage.setMockInitialValues({});
        await TokenStorage().clear();
        AuthState().login(
          name: 'Disposable QA',
          phone: 'fixture',
          role: 'clinic_admin',
        );
        final api = ApiClient(), service = ClinicPortalService();
        final old = api.dio.httpClientAdapter;
        final oldPicker = ImagePickerPlatform.instance,
            oldVideo = VideoPlayerPlatform.instance;
        final picker = ObservedPicker()
          ..video = File(
            'test/fixtures/clinic_media/short_showcase.mp4',
          ).absolute.path;
        final video = ShortVideoPlatform();
        ImagePickerPlatform.instance = picker;
        VideoPlayerPlatform.instance = video;
        var patchSeen = false;
        final wire = Wire((o) {
          if (o.method == 'PATCH') {
            patchSeen = true;
            return f.body({
              'error': {'code': 'INTERNAL_SERVER_ERROR'},
            }, 500);
          }
          return f.body({
            ...f.clinic(),
            'subscription_tier': 'vip',
            'video_ad_file': null,
          });
        });
        api.dio.httpClientAdapter = wire;
        service.resetTestingState();
        service.setCatalogRepositoryForTesting(
          ClinicCatalogRepository(apiClient: api),
        );
        addTearDown(() async {
          api.dio.httpClientAdapter = old;
          ImagePickerPlatform.instance = oldPicker;
          VideoPlayerPlatform.instance = oldVideo;
          for (final stream in video.streams.values) {
            await stream.close();
          }
          service.resetTestingState();
          AuthState().logout();
          await TokenStorage().clear();
        });
        await f.render(
          tester,
          ClinicMediaScreen(repository: Gallery()),
          dark: dark,
          ar: ar,
        );
        await tester.ensureVisible(
          find.text(ar ? 'اختيار فيديو من المعرض' : 'Select gallery video'),
        );
        await tester.tap(
          find.text(ar ? 'اختيار فيديو من المعرض' : 'Select gallery video'),
        );
        await finishNativeWork(tester, () => video.probed.isCompleted);
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.text(ar ? 'رفع وحفظ الفيديو' : 'Upload and save video'),
        );
        await tester.tap(
          find.text(ar ? 'رفع وحفظ الفيديو' : 'Upload and save video'),
        );
        await finishNativeWork(
          tester,
          () =>
              patchSeen &&
              find
                  .text(ar ? 'جارٍ معالجة الوسائط…' : 'Processing media…')
                  .evaluate()
                  .isEmpty,
        );
        await tester.pumpAndSettle();
        expect(wire.requests.where((r) => r.method == 'PATCH'), hasLength(1));
        expect(
          find.text(ar ? 'إلغاء اختيار الفيديو' : 'Discard selected video'),
          findsOneWidget,
        );
        expect(service.activeClinic.hasVideoAd, false);
        expect(
          find.byKey(const ValueKey('video-local-preview-not-saved')),
          findsOneWidget,
        );
        expect(
          find.textContaining('Saved video change verified.'),
          findsNothing,
        );
        expect(
          tester
              .widget<SilverButton>(
                find.byWidgetPredicate(
                  (w) =>
                      w is SilverButton &&
                      w.label ==
                          (ar ? 'رفع وحفظ الفيديو' : 'Upload and save video'),
                ),
              )
              .onPressed,
          isNull,
        );
        final failure = tester.widget<Text>(
          find.byKey(const ValueKey('video-operation-error')),
        );
        expect(failure.data, contains('HTTP 500'));
        expect(failure.data, isNot(contains('INTERNAL_SERVER_ERROR')));
        await tester.pump(const Duration(seconds: 30));
        expect(
          wire.requests.where((r) => r.method == 'PATCH'),
          hasLength(1),
          reason: 'No non-idempotent automatic retry.',
        );
        await tester.ensureVisible(
          find.text(ar ? 'فيديو عرض العيادة' : 'Clinic showcase video'),
        );
        await f.capture(
          tester,
          'video_upload_http500_${dark ? 'dark' : 'light'}_${ar ? 'ar' : 'en'}',
        );
        await tester.pumpWidget(const SizedBox());
        await tester.binding.setSurfaceSize(null);
      });
    }
  }
}
