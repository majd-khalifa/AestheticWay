/// Stable presentation IDs, not backend foreign keys. Labels never become IDs.
class UaeEmirate {
  const UaeEmirate(this.code, this.nameEn, this.nameAr);
  final String code, nameEn, nameAr;
  String label(bool arabic) => arabic ? nameAr : nameEn;
}

class UaeCity {
  const UaeCity(
    this.code,
    this.emirateCode,
    this.nameEn,
    this.nameAr, [
    this.aliases = const [],
  ]);
  final String code, emirateCode, nameEn, nameAr;
  final List<String> aliases;
  String label(bool arabic) => arabic ? nameAr : nameEn;
}

class UaeLocationCatalog {
  const UaeLocationCatalog(
    this.emirates,
    this.cities, {
    this.authoritative = false,
  });
  final List<UaeEmirate> emirates;
  final List<UaeCity> cities;

  /// Only a reviewed backend catalog can declare comprehensive coverage.
  final bool authoritative;
  static String normalize(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll(RegExp(r'[\s_\-]+'), '');
  UaeCity? resolve(String? value) {
    final key = normalize(value ?? '');
    for (final c in cities) {
      if ([
        c.code,
        c.nameEn,
        c.nameAr,
        ...c.aliases,
      ].any((v) => normalize(v) == key)) {
        return c;
      }
    }
    return null;
  }

  UaeEmirate emirateFor(UaeCity city) =>
      emirates.firstWhere((e) => e.code == city.emirateCode);

  /// 09f49bb supports case-insensitive free-text city, not canonical IDs.
  String? legacyCityQuery(String? value) {
    if (value == null ||
        value.trim().isEmpty ||
        ['all', 'الكل'].contains(value.trim().toLowerCase())) {
      return null;
    }
    return resolve(value)?.nameEn ?? value.trim();
  }
}
