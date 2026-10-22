import 'dart:io';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/patient_image.dart';
import 'package:aesthetic_way/core/widgets/patient_media_placeholder.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/products/presentation/widgets/brand_product_media.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/patient_visual_harness.dart';
import 'support/settle_expected_media_errors.dart';

void main() {
  late File broken;
  setUpAll(() async {
    await loadPatientVisualFonts();
    broken = File(
      'test/fixtures/media/intentionally_corrupt_image.fixture',
    ).absolute;
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  bool corrupt(ImageProvider p) => p is ResizeImage
      ? corrupt(p.imageProvider)
      : p is FileImage && p.file.absolute.uri == broken.absolute.uri;
  for (final category in PatientMediaCategory.values) {
    for (final dark in [false, true]) {
      for (final ar in [false, true]) {
        for (final frame in [
          const Size(48, 48),
          const Size(300, 180),
          const Size(120, 204),
        ]) {
          testWidgets(
            '${category.name} frame=$frame dark=$dark rtl=$ar real/missing/error',
            (tester) async {
              await tester.binding.setSurfaceSize(const Size(390, 844));
              addTearDown(() => tester.binding.setSurfaceSize(null));
              await LocaleService().setLanguage(
                ar ? AppLanguage.arabic : AppLanguage.english,
              );
              await tester.pumpWidget(
                MaterialApp(
                  theme: patientVisualTheme(dark: dark),
                  home: Directionality(
                    textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
                    child: Scaffold(
                      body: Column(
                        children: [
                          for (final source in [
                            File(
                              'test/fixtures/media/portrait_photo.png',
                            ).absolute.uri.toString(),
                            null,
                            broken.uri.toString(),
                          ])
                            PatientImage(
                              category: category,
                              imageUrl: source,
                              width: frame.width,
                              height: frame.height,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              expect(
                await settleExpectedMediaErrors(
                  tester,
                  isExpectedFailure: corrupt,
                ),
                1,
              );
              final slots = find.byType(PatientImage);
              for (final slot in [slots.at(0), slots.at(1), slots.at(2)]) {
                expect(tester.getSize(slot), frame);
              }
              final panels = tester
                  .widgetList<PatientMediaPlaceholder>(
                    find.byType(PatientMediaPlaceholder),
                  )
                  .toList();
              expect(panels.map((p) => p.category), [category, category]);
              expect(panels.map((p) => p.reason), [
                PatientMediaFallbackReason.missing,
                PatientMediaFallbackReason.loadFailed,
              ]);
              expect(
                find.bySemanticsLabel(
                  ar ? 'الصورة غير متوفرة' : 'Image unavailable',
                ),
                findsOneWidget,
              );
              expect(
                find.bySemanticsLabel(
                  ar ? 'تعذّر تحميل الصورة' : 'Image could not load',
                ),
                findsOneWidget,
              );
              final decoded = tester
                  .widget<RawImage>(find.byType(RawImage))
                  .image!;
              expect(decoded.width, greaterThan(0));
              expect(decoded.height, greaterThan(0));
              final real = tester.widget<Image>(
                find.descendant(of: slots.first, matching: find.byType(Image)),
              );
              expect(real.image, isA<ResizeImage>());
              expect(
                (real.image as ResizeImage).imageProvider,
                isA<FileImage>(),
              );
              final diagnostics = panels.last
                  .toDiagnosticsNode()
                  .toStringDeep();
              expect(diagnostics, contains('loadFailed'));
              expect(diagnostics, isNot(contains(broken.uri.toString())));
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
  for (final product in [false, true]) {
    testWidgets('known video stays outside image codecs product=$product', (
      tester,
    ) async {
      const source = 'https://media.invalid/clip.MP4?token=private-value';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              height: 200,
              child: product
                  ? BrandProductMedia(
                      product: ProductModel.fromJson({
                        'name_en': 'Test product',
                        'image_url': source,
                      }),
                    )
                  : const PatientImage(
                      category: PatientMediaCategory.clinicCover,
                      imageUrl: source,
                      width: 160,
                      height: 200,
                    ),
            ),
          ),
        ),
      );
      expect(find.byType(Image), findsNothing);
      final panel = tester.widget<PatientMediaPlaceholder>(
        find.byType(PatientMediaPlaceholder),
      );
      expect(panel.reason, PatientMediaFallbackReason.unsupportedSource);
      expect(
        panel.toDiagnosticsNode().toStringDeep(),
        isNot(contains('private-value')),
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'complete original vector family, light/dark and thumbnail/hero contact sheet',
    (tester) async {
      await LocaleService().setLanguage(AppLanguage.english);
      await tester.binding.setSurfaceSize(const Size(1000, 1910));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: const Key('family'),
              child: ColoredBox(
                color: const Color(0xFFF7F5F1),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'AESTHETIC WAY / ORIGINAL PLACEHOLDER ILLUSTRATIONS',
                        style: TextStyle(
                          fontFamily: 'PatientDisplay',
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Offline vector artwork • Light / Dark • Full frame / Portrait / Thumbnail • No real-world identity',
                        style: TextStyle(
                          fontFamily: 'PatientGolden',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final category in PatientMediaCategory.values) ...[
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontFamily: 'PatientGolden',
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (final dark in [false, true]) ...[
                              Theme(
                                data: patientVisualTheme(dark: dark),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: PatientMediaPlaceholder(
                                    category: category,
                                    width: 330,
                                    height: 170,
                                  ),
                                ),
                              ),
                              Theme(
                                data: patientVisualTheme(dark: dark),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: PatientMediaPlaceholder(
                                    category: category,
                                    width: 88,
                                    height: 170,
                                  ),
                                ),
                              ),
                              Theme(
                                data: patientVisualTheme(dark: dark),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: PatientMediaPlaceholder(
                                    category: category,
                                    width: 56,
                                    height: 56,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 18),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PatientMediaPlaceholder), findsNWidgets(48));
      expect(tester.takeException(), isNull);
      const output = String.fromEnvironment('PATIENT_FAMILY_CAPTURE_DIR');
      await expectLater(
        find.byKey(const Key('family')),
        matchesGoldenFile(
          output.isNotEmpty
              ? Uri.file('$output/placeholder_family.png')
              : Uri.parse(
                  'goldens/patient_category_placeholders_v4/${Platform.operatingSystem}/placeholder_family.png',
                ),
        ),
      );
    },
  );
}
