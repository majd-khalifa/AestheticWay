import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'support/settle_preview_images.dart';
import 'support/patient_visual_harness.dart';

/// Deterministically reproduces a pending FakeAsync file load on every host.
/// Bytes still come from the real native filesystem and Flutter's real decoder.
class _DeferredFile implements File {
  _DeferredFile(this.file);
  final File file;
  @override
  String get path => file.path;
  @override
  Future<int> length() async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return file.length();
  }

  @override
  Future<Uint8List> readAsBytes() => file.readAsBytes();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'mixed Windows separators change FileImage keys despite referring to the same path',
    () async {
      const raw = r'C:\fixture root\test/fixtures/media/photo.png';
      final canonical = Uri.file(raw, windows: true).toFilePath(windows: true);
      expect(canonical, r'C:\fixture root\test\fixtures\media\photo.png');
      final warm = await FileImage(
        File(raw),
      ).obtainKey(ImageConfiguration.empty);
      final mounted = await FileImage(
        File(canonical),
      ).obtainKey(ImageConfiguration.empty);
      expect(warm, isNot(mounted));
    },
  );

  test(
    'ResizeImage cache keys include dimensions and policy, not just the file',
    () async {
      final file = FileImage(File('test/fixtures/media/packaging_fixture.png'));
      Future<Object> key(ResizeImage image) =>
          image.obtainKey(ImageConfiguration.empty);
      final mounted = await key(
        ResizeImage(
          file,
          width: 171,
          height: 200,
          policy: ResizeImagePolicy.fit,
        ),
      );
      expect(
        mounted,
        isNot(
          await key(
            ResizeImage(
              file,
              width: 172,
              height: 200,
              policy: ResizeImagePolicy.fit,
            ),
          ),
        ),
      );
      expect(
        mounted,
        isNot(await key(ResizeImage(file, width: 171, height: 200))),
      );
    },
  );

  for (final dpr in [1.0, 1.25, 2.75, 3.0]) {
    for (final width in [137.0, 211.3]) {
      testWidgets(
        'cold file-URI pixels settle at DPR $dpr, width $width without prewarm',
        (tester) async {
          final directory = Directory.systemTemp.createTempSync('aw frame ');
          final file = File(
            '${directory.path}${Platform.pathSeparator}صورة # fixture.png',
          );
          file.writeAsBytesSync(
            File('test/fixtures/media/packaging_fixture.png').readAsBytesSync(),
          );
          addTearDown(() => directory.deleteSync(recursive: true));
          final resolved = resolveImageProvider(file.uri.toString());
          expect(resolved, isA<FileImage>());
          expect((resolved as FileImage).file.path, file.path);
          late ResizeImage mounted;
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(800, 600),
                  devicePixelRatio: dpr,
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: width,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        mounted = ResizeImage(
                          FileImage(_DeferredFile(resolved.file)),
                          width: (constraints.maxWidth * dpr).round(),
                          height: (240 * dpr).round(),
                          policy: ResizeImagePolicy.fit,
                        );
                        return Image(
                          image: mounted,
                          width: constraints.maxWidth,
                          height: 240,
                          errorBuilder: (_, _, _) =>
                              const Text('Unexpected fallback'),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
          final key = await mounted.obtainKey(ImageConfiguration.empty);
          expect(
            PaintingBinding.instance.imageCache.statusForKey(key).pending,
            isTrue,
          );
          await settlePreviewImages(tester);
          final raw = tester.widget<RawImage>(find.byType(RawImage));
          expect(raw.image, isNotNull);
          expect(raw.image!.width, inInclusiveRange(1, (width * dpr).round()));
          expect(raw.image!.height, inInclusiveRange(1, (240 * dpr).round()));
          expect(find.text('Unexpected fallback'), findsNothing);
          expect(
            PaintingBinding.instance.imageCache.statusForKey(key).pending,
            isFalse,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  testWidgets(
    'corrupt file fails genuine decoding instead of accepting its fallback',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync('aw corrupt ');
      final file = File('${directory.path}${Platform.pathSeparator}invalid.png')
        ..writeAsStringSync('not PNG bytes');
      addTearDown(() => directory.deleteSync(recursive: true));
      await tester.pumpWidget(
        MaterialApp(
          home: Image.file(
            file,
            errorBuilder: (_, _, _) => const Text('Fallback'),
          ),
        ),
      );
      await expectLater(settlePreviewImages(tester), throwsA(isA<Exception>()));
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'golden typography pins primary and button fonts as well as body fonts',
    () {
      for (final dark in [false, true]) {
        final theme = patientVisualTheme(dark: dark);
        expect(theme.textTheme.bodyMedium!.fontFamily, 'PatientGolden');
        expect(theme.primaryTextTheme.bodyMedium!.fontFamily, 'PatientGolden');
        expect(
          theme.elevatedButtonTheme.style!.textStyle!.resolve({})!.fontFamily,
          'PatientGolden',
        );
        expect(
          theme.outlinedButtonTheme.style!.textStyle!.resolve({})!.fontFamily,
          'PatientGolden',
        );
        expect(theme.visualDensity, VisualDensity.standard);
        expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
      }
    },
  );
}
