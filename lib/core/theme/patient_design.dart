import 'package:flutter/material.dart';
import '../localization/app_locale.dart';
import 'patient_theme_tokens.dart';

/// Reference-locked patient presentation; no global theme or role changes.
class PatientDesign extends StatelessWidget {
  const PatientDesign({super.key, required this.builder});
  final WidgetBuilder builder;
  static TextStyle heading(BuildContext context, {double size = 23}) =>
      TextStyle(
        fontFamily: LocaleService().isArabic
            ? 'PatientArabic'
            : 'PatientDisplay',
        fontFamilyFallback: const ['PatientArabic'],
        fontSize: size,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      );
  @override
  Widget build(BuildContext context) {
    final inherited = Theme.of(context);
    if (inherited.extension<PatientThemeTokens>() != null) {
      return Builder(builder: builder);
    }
    final p = PatientThemeTokens(dark: inherited.brightness == Brightness.dark);
    const family = 'PatientArabic';
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
    );
    final scheme = inherited.colorScheme.copyWith(
      primary: p.gold,
      onPrimary: p.background,
      surface: p.surface,
      onSurface: p.text,
      onSurfaceVariant: p.muted,
      outline: p.border,
    );
    return Theme(
      data: inherited.copyWith(
        extensions: [...inherited.extensions.values, p],
        colorScheme: scheme,
        scaffoldBackgroundColor: p.background,
        textTheme: inherited.textTheme
            .apply(fontFamily: family, bodyColor: p.text, displayColor: p.text)
            .copyWith(
              headlineSmall: heading(context, size: 28).copyWith(color: p.text),
              titleLarge: heading(context).copyWith(color: p.text),
            ),
        appBarTheme: inherited.appBarTheme.copyWith(
          backgroundColor: p.background,
          foregroundColor: p.text,
          titleTextStyle: heading(context, size: 21).copyWith(color: p.text),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: p.goldFill,
            foregroundColor: const Color(0xFF171C26),
            minimumSize: const Size(48, 48),
            shape: shape,
            textStyle: TextStyle(
              fontFamily: family,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: p.text,
            side: BorderSide(color: p.border),
            minimumSize: const Size(48, 48),
            shape: shape,
          ),
        ),
        inputDecorationTheme: inherited.inputDecorationTheme.copyWith(
          fillColor: p.surface,
          labelStyle: TextStyle(color: p.muted, fontFamily: family),
          hintStyle: TextStyle(
            color: p.muted,
            fontSize: 13,
            fontFamily: family,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.gold, width: 1.5),
          ),
        ),
      ),
      child: Builder(builder: builder),
    );
  }
}
