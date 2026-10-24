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
    this.areas = const [],
  });
  final List<UaeEmirate> emirates;
  final List<UaeCity> cities;
  final List<UaeArea> areas;
  UaeArea? resolveArea(String? value, {required String cityCode}) {
    for (final a in areas) {
      if (a.cityCode == cityCode &&
          [
            a.code,
            a.nameEn,
            a.nameAr,
            ...a.aliases,
          ].any((s) => normalize(s) == normalize(value ?? ''))) {
        return a;
      }
    }
    return null;
  }

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

class UaeArea {
  const UaeArea(
    this.code,
    this.cityCode,
    this.nameEn,
    this.nameAr, [
    this.aliases = const [],
  ]);
  final String code, cityCode, nameEn, nameAr;
  final List<String> aliases;
  String label(bool arabic) => arabic ? nameAr : nameEn;
}

/// Presentation selection only. Canonical server foreign keys are not assumed.
class UaeLocality {
  UaeLocality(this.city, [this.area]) {
    if (area != null && area!.cityCode != city.code) {
      throw ArgumentError('Area does not belong to city');
    }
  }
  final UaeCity city;
  final UaeArea? area;
  String label(bool arabic) =>
      [city.label(arabic), if (area != null) area!.label(arabic)].join(' • ');
  String addressWithArea(String existing, {required bool arabic}) {
    if (area == null ||
        UaeLocationCatalog.normalize(
          existing,
        ).contains(UaeLocationCatalog.normalize(area!.label(arabic)))) {
      return existing;
    }
    return [
      area!.label(arabic),
      if (existing.trim().isNotEmpty) existing.trim(),
    ].join(' • ');
  }
}
