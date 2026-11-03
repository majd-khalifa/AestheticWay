import 'package:phone_numbers_parser/phone_numbers_parser.dart';

enum PhoneNumberIssue { required, length, format }

/// Numbering-plan validation, not proof of assignment, reachability or ownership.
abstract final class InternationalPhone {
  static String asciiDigits(String value) => String.fromCharCodes(
    value.runes.map((rune) {
      if (rune >= 0x660 && rune <= 0x669) return 48 + rune - 0x660;
      if (rune >= 0x6f0 && rune <= 0x6f9) return 48 + rune - 0x6f0;
      return rune;
    }),
  );

  static PhoneNumber _parse(String value, IsoCode country) {
    final ascii = asciiDigits(value).trim();
    if (!RegExp(r'^[+0-9\s().-]+$').hasMatch(ascii)) {
      throw const FormatException('Invalid phone characters');
    }
    return PhoneNumber.parse(ascii, callerCountry: country);
  }

  static String normalize(String value, {IsoCode country = IsoCode.AE}) {
    final ascii = asciiDigits(value).trim();
    if (ascii.isEmpty) return '';
    try {
      return _parse(ascii, country).international;
    } catch (_) {
      // Keep invalid/oversized input intact so validation can reject it. Never
      // silently turn a truncated or guessed number into a valid submission.
      return ascii;
    }
  }

  static PhoneNumberIssue? issue(
    String value, {
    IsoCode country = IsoCode.AE,
    bool required = false,
  }) {
    final ascii = asciiDigits(value).trim();
    if (ascii.isEmpty) return required ? PhoneNumberIssue.required : null;
    try {
      final parsed = _parse(ascii, country);
      if (parsed.international.length > 16 || !parsed.isValidLength()) {
        return PhoneNumberIssue.length;
      }
      return parsed.isValid() ? null : PhoneNumberIssue.format;
    } catch (_) {
      return ascii.replaceAll(RegExp(r'\D'), '').length > 15
          ? PhoneNumberIssue.length
          : PhoneNumberIssue.format;
    }
  }

  static String localDigits(String value, {IsoCode country = IsoCode.AE}) {
    try {
      return _parse(value, country).nsn;
    } catch (_) {
      return asciiDigits(value).replaceAll(RegExp(r'\D'), '');
    }
  }

  /// The counter is advisory; overlength edits are preserved and rejected by
  /// validation. UAE still displays a 10-digit local limit including trunk 0.
  static int inputLimit(IsoCode country) {
    if (country == IsoCode.AE) return 10;
    final codeLength = PhoneNumber(
      isoCode: country,
      nsn: '',
    ).countryCode.length;
    var longest = 0;
    for (var length = 1; length <= 15 - codeLength; length++) {
      if (PhoneNumber(isoCode: country, nsn: '1' * length).isValidLength()) {
        longest = length;
      }
    }
    return longest == 0 ? 15 - codeLength : longest + 1;
  }
}
