import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cross-host layout/style contract, in addition to each host's exact pixels.
/// 1/16 dp avoids native font-layout rounding boundaries (measured 1/64 dp
/// drift for one Arabic CTA with identical font/SDK). Exact native raster checks
/// still detect every pixel difference; this is only the extra shared-layout guard.
/// raster comparisons themselves have no tolerance.
Map<String, Object?> clinicGoldenGeometry(WidgetTester tester) {
  double q(double value) => (value * 16).round() / 16;
  List<double> rect(Element element) {
    final bounds = tester.getRect(
      find.byElementPredicate((e) => identical(e, element)),
    );
    return [q(bounds.left), q(bounds.top), q(bounds.width), q(bounds.height)];
  }

  return {
    'viewport': [390, 844],
    'text': [
      for (final element in find.byType(Text).evaluate())
        () {
          final widget = element.widget as Text;
          final style = DefaultTextStyle.of(element).style.merge(widget.style);
          return {
            'text': widget.data ?? widget.textSpan?.toPlainText(),
            'rect': rect(element),
            'family': style.fontFamily,
            'weight': style.fontWeight?.value,
            'size': style.fontSize,
            'height': style.height,
            'spacing': style.letterSpacing,
            'color': style.color?.toARGB32(),
            'direction':
                (widget.textDirection ?? Directionality.of(element)).name,
          };
        }(),
    ],
    'icons': [
      for (final element in find.byType(Icon).evaluate())
        () {
          final widget = element.widget as Icon;
          final theme = IconTheme.of(element);
          return {
            'glyph': widget.icon?.codePoint,
            'family': widget.icon?.fontFamily,
            'rect': rect(element),
            'size': widget.size ?? theme.size,
            'color': (widget.color ?? theme.color)?.toARGB32(),
          };
        }(),
    ],
  };
}

void expectClinicGoldenGeometry(WidgetTester tester, String name) {
  final actual = clinicGoldenGeometry(tester);
  const capture = String.fromEnvironment('PATIENT_GOLDEN_CAPTURE_DIR');
  final expected = File(
    'test/goldens/patient_reference_fidelity_v2/geometry/$name.json',
  );
  if (capture.isNotEmpty) {
    final output = File.fromUri(Directory(capture).uri.resolve('$name.json'));
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(actual)}\n',
    );
  } else {
    expect(
      actual,
      jsonDecode(expected.readAsStringSync()),
      reason:
          'Common clinic geometry and styles must match on every native host.',
    );
  }
}
