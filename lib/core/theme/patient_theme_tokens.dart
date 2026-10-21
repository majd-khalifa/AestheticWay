import 'package:flutter/material.dart';

/// Present only below PatientDesign. Other portals retain their existing theme.
@immutable
class PatientThemeTokens extends ThemeExtension<PatientThemeTokens> {
  const PatientThemeTokens({required this.dark});
  final bool dark;
  Color get background =>
      dark ? const Color(0xFF080F1A) : const Color(0xFFFBF9F5);
  Color get surface => dark ? const Color(0xFF111A29) : Colors.white;
  Color get subtle => dark ? const Color(0xFF182234) : const Color(0xFFF3EEE7);
  Color get text => dark ? const Color(0xFFF8F6F2) : const Color(0xFF171C26);
  Color get muted => dark ? const Color(0xFFB5BDCB) : const Color(0xFF626875);
  Color get border => dark ? const Color(0xFF303B4C) : const Color(0xFFE8E2D9);
  Color get gold => dark ? const Color(0xFFE6BE7D) : const Color(0xFF86602D);
  Color get goldFill => const Color(0xFFE3BB7E);
  @override
  PatientThemeTokens copyWith({bool? dark}) =>
      PatientThemeTokens(dark: dark ?? this.dark);
  @override
  PatientThemeTokens lerp(covariant PatientThemeTokens? other, double t) =>
      t < .5 ? this : other ?? this;
}
