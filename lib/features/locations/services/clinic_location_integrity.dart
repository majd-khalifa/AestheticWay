import '../data/uae_location_repository.dart';
import '../models/uae_location.dart';

/// A conservative textual consistency check, never a geocoder or polygon test.
/// Ambiguous mixed-city addresses still require the owner's entrance review.
abstract class ClinicLocationIntegrity {
  static bool emirateMatches(String city, String emirate) {
    final c = currentUaeCatalog.resolve(city);
    if (c == null) return false;
    final e = currentUaeCatalog.emirateFor(c);
    // Historical presentation IDs use ISO fragments AZ/FU; the verified API
    // uses AD/FJ. These are aliases, not additional locality records.
    final apiCode = switch (e.code.toLowerCase()) {
      'ae-az' => 'AD',
      'ae-fu' => 'FJ',
      _ => e.code.replaceFirst(RegExp(r'^ae-', caseSensitive: false), ''),
    };
    return [e.code, apiCode, e.nameEn, e.nameAr].any(
      (v) =>
          UaeLocationCatalog.normalize(v) ==
          UaeLocationCatalog.normalize(emirate),
    );
  }

  static String? issue({
    required String city,
    required String emirate,
    required String addressEn,
    required String addressAr,
    required bool arabic,
    bool requireKnownCity = true,
  }) {
    final c = currentUaeCatalog.resolve(city);
    if (c == null) {
      if (!requireKnownCity) return null;
      return arabic ? 'اختر مدينة من القائمة.' : 'Choose a catalog city.';
    }
    final parent = currentUaeCatalog.emirateFor(c);
    if (emirate.trim().isNotEmpty && !emirateMatches(city, emirate)) {
      return arabic
          ? 'المدينة والإمارة غير متطابقتين؛ صحّح الاختيار قبل الحفظ.'
          : 'City and emirate conflict. Correct the selection before saving.';
    }
    bool mentions(String address, String name) {
      String fold(String v) => v
          .replaceAll(RegExp('[أإآ]'), 'ا')
          .replaceAll(RegExp(r'[\u064B-\u065F\u0670ـ]'), '');
      final normalizedName = fold(name);
      final pattern = RegExp(r'[\u0600-\u06FF]').hasMatch(normalizedName)
          ? normalizedName
                .replaceAll(RegExp(r'\s+'), '')
                .split('')
                .map(RegExp.escape)
                .join(r'\s*')
          : RegExp.escape(normalizedName);
      return RegExp(
        r'(^|[^A-Za-z\u0600-\u06FF])' +
            pattern +
            r'(?=$|[^A-Za-z\u0600-\u06FF])',
        caseSensitive: false,
      ).hasMatch(fold(address));
    }

    for (final address in [addressEn, addressAr]) {
      if (address.isEmpty) continue;
      final found = currentUaeCatalog.emirates
          .where((e) => [e.nameEn, e.nameAr].any((n) => mentions(address, n)))
          .toList();
      if (found.isNotEmpty && !found.any((e) => e.code == parent.code)) {
        return arabic
            ? 'العنوان يشير إلى إمارة أخرى. راجع المدينة والعنوان والمدخل قبل التأكيد.'
            : 'The address names another emirate. Review the city, address and entrance before confirming.';
      }
    }
    return null;
  }
}
