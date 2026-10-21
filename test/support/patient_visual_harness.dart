import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aesthetic_way/core/theme/app_theme.dart';

/// Test-only font ownership: never depend on a machine's Segoe UI/Roboto or
/// synthetic bold face. Both fixture files include Latin and Arabic glyphs.
Future<void> loadPatientVisualFonts() async {
  final regular = ByteData.sublistView(
    File('test/fixtures/fonts/DejaVuSans.ttf').readAsBytesSync(),
  );
  final bold = ByteData.sublistView(
    File('test/fixtures/fonts/DejaVuSans-Bold.ttf').readAsBytesSync(),
  );
  for (final entry in {
    'PatientDisplay': 'PlayfairDisplay.ttf',
    'PatientArabic': 'NotoSansArabic.ttf',
  }.entries) {
    final data = ByteData.sublistView(
      File('assets/fonts/patient/${entry.value}').readAsBytesSync(),
    );
    await (FontLoader(entry.key)..addFont(Future.value(data))).load();
  }
  for (final family in ['PatientPreview', 'serif']) {
    await (FontLoader(family)..addFont(Future.value(regular))).load();
  }
  await (FontLoader('PatientGolden')
        ..addFont(Future.value(regular))
        ..addFont(Future.value(bold)))
      .load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}

TextStyle? _font(TextStyle? style) => style?.copyWith(
  fontFamily: 'PatientGolden',
  fontFamilyFallback: const ['PatientGolden'],
);

ButtonStyle? _buttonFont(ButtonStyle? style) => style?.copyWith(
  textStyle: WidgetStateProperty.resolveWith(
    (states) => _font(style.textStyle?.resolve(states)),
  ),
);

/// A canonical Android patient presentation, regardless of the native renderer
/// or TargetPlatformVariant. Copying platform alone does not reconstruct
/// ThemeData's already-selected primary typography or button text styles.
ThemeData patientVisualTheme({required bool dark}) {
  final theme = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
  return theme.copyWith(
    platform: TargetPlatform.android,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    textTheme: theme.textTheme.apply(
      fontFamily: 'PatientGolden',
      fontFamilyFallback: const ['PatientGolden'],
    ),
    primaryTextTheme: theme.primaryTextTheme.apply(
      fontFamily: 'PatientGolden',
      fontFamilyFallback: const ['PatientGolden'],
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: _buttonFont(theme.elevatedButtonTheme.style),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _buttonFont(theme.outlinedButtonTheme.style),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: _buttonFont(theme.filledButtonTheme.style),
    ),
    textButtonTheme: TextButtonThemeData(
      style: _buttonFont(theme.textButtonTheme.style),
    ),
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: _font(theme.appBarTheme.titleTextStyle),
      toolbarTextStyle: _font(theme.appBarTheme.toolbarTextStyle),
    ),
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      labelStyle: _font(theme.inputDecorationTheme.labelStyle),
      hintStyle: _font(theme.inputDecorationTheme.hintStyle),
      errorStyle: _font(theme.inputDecorationTheme.errorStyle),
      helperStyle: _font(theme.inputDecorationTheme.helperStyle),
    ),
  );
}
