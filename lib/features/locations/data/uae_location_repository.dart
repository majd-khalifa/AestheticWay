import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/uae_location.dart';

/// Source-verified public catalog contracts (backend401560b).
abstract class UaeLocationRepository {
  Future<UaeLocationCatalog> load();
}

/// Shared public catalog only; no user location, contact data or credentials.
UaeLocationCatalog get currentUaeCatalog =>
    ServerUaeLocationRepository.loaded ?? compatibilityUaeCatalog;

class ServerUaeLocationRepository implements UaeLocationRepository {
  const ServerUaeLocationRepository({ApiClient? api}) : _api = api;
  final ApiClient? _api;
  static UaeLocationCatalog? loaded;
  static Future<UaeLocationCatalog>? _flight;
  @override
  Future<UaeLocationCatalog> load() {
    if (_api != null) return _load(_api);
    if (loaded != null) return Future.value(loaded);
    return _flight ??= _load(ApiClient()).then(
      (value) {
        loaded = value;
        _flight = null;
        return value;
      },
      onError: (Object e, StackTrace st) {
        _flight = null;
        Error.throwWithStackTrace(e, st);
      },
    );
  }

  Future<List<Map<String, dynamic>>> _rows(ApiClient api, String path) async {
    final rows = <Map<String, dynamic>>[];
    for (var page = 1; page <= 20; page++) {
      final response = await api.get(
        'locations/$path/',
        queryParameters: page == 1 ? null : {'page': page, 'page_size': 200},
      );
      final data = response.data;
      final list = data is List
          ? data
          : data is Map
          ? data['results']
          : null;
      if (list is! List || list.any((v) => v is! Map)) {
        throw const ApiException(message: 'Invalid location catalog.');
      }
      rows.addAll(list.map((v) => Map<String, dynamic>.from(v as Map)));
      if (rows.length > 4000) {
        throw const ApiException(
          message: 'Location catalog exceeds supported size.',
        );
      }
      if (data is List || data['next'] == null) return rows;
      // Never follow an absolute next URL with authenticated headers.
      if (list.isEmpty) break;
    }
    throw const ApiException(
      message: 'Location pagination could not be verified.',
    );
  }

  Future<UaeLocationCatalog> _load(ApiClient? client) async {
    final api = client ?? ApiClient();
    final lists = await Future.wait([
      _rows(api, 'emirates'),
      _rows(api, 'cities'),
      _rows(api, 'areas'),
    ]);
    String requiredText(Map<String, dynamic> d, String k) {
      final v = d[k];
      if (v is! String || v.trim().isEmpty) {
        throw const ApiException(message: 'Incomplete location catalog.');
      }
      return v;
    }

    final emirates = [
      for (final d in lists[0])
        if (d['is_active'] == true)
          UaeEmirate(
            requiredText(d, 'emirate_code'),
            requiredText(d, 'name_en'),
            requiredText(d, 'name_ar'),
          ),
    ];
    final cities = [
      for (final d in lists[1])
        if (d['is_active'] == true)
          UaeCity(
            requiredText(d, 'city_code'),
            requiredText(d, 'emirate_code'),
            requiredText(d, 'name_en'),
            requiredText(d, 'name_ar'),
            [
              if (d['city_code'] == 'ruwais') ...[
                'al-dhannah',
                'Al Dhannah',
                'الظنة',
              ],
              ...?compatibilityUaeCatalog.resolve('${d['city_code']}')?.aliases,
            ],
          ),
    ];
    final byCity = {for (final c in cities) c.code: c};
    final areas = [
      for (final d in lists[2])
        if (d['is_active'] == true)
          UaeArea(
            requiredText(d, 'area_code'),
            requiredText(d, 'city_code'),
            requiredText(d, 'name_en'),
            requiredText(d, 'name_ar'),
          ),
    ];
    if (emirates.map((e) => e.code).toSet().length != emirates.length ||
        cities.map((e) => e.code).toSet().length != cities.length ||
        areas.map((a) => '${a.cityCode}:${a.code}').toSet().length !=
            areas.length ||
        cities.any((c) => !emirates.any((e) => e.code == c.emirateCode)) ||
        areas.any((a) => !byCity.containsKey(a.cityCode)) ||
        lists[2].any(
          (a) =>
              a['is_active'] == true &&
              byCity[a['city_code']]?.emirateCode != a['emirate_code'],
        )) {
      throw const ApiException(
        message: 'Location hierarchy could not be verified.',
      );
    }
    return UaeLocationCatalog(
      emirates,
      cities,
      areas: areas,
      authoritative: true,
    );
  }
}

class BundledUaeLocationRepository implements UaeLocationRepository {
  const BundledUaeLocationRepository();
  @override
  Future<UaeLocationCatalog> load() async => compatibilityUaeCatalog;
}

/// Compatibility seed, NOT an exhaustive list of UAE cities or districts.
/// Seven-emirate taxonomy: UAE Government /about-the-uae/the-seven-emirates.
/// Municipality/city IDs below are frontend identifiers pending Ali seed review.
const compatibilityUaeCatalog = UaeLocationCatalog(
  [
    UaeEmirate('ae-du', 'Dubai', 'دبي'),
    UaeEmirate('ae-az', 'Abu Dhabi', 'أبوظبي'),
    UaeEmirate('ae-sh', 'Sharjah', 'الشارقة'),
    UaeEmirate('ae-aj', 'Ajman', 'عجمان'),
    UaeEmirate('ae-rk', 'Ras Al Khaimah', 'رأس الخيمة'),
    UaeEmirate('ae-fu', 'Fujairah', 'الفجيرة'),
    UaeEmirate('ae-uq', 'Umm Al Quwain', 'أم القيوين'),
  ],
  [
    UaeCity('dubai', 'ae-du', 'Dubai', 'دبي'),
    UaeCity('hatta', 'ae-du', 'Hatta', 'حتا'),
    UaeCity('abu-dhabi', 'ae-az', 'Abu Dhabi', 'أبوظبي', [
      'Abudhabi',
      'Abu-Dhabi',
      'أبو ظبي',
    ]),
    UaeCity('al-ain', 'ae-az', 'Al Ain', 'العين', ['Al-Ain', 'Alain']),
    UaeCity('al-dhannah', 'ae-az', 'Al Dhannah', 'الظنة', ['Ruwais', 'الرويس']),
    UaeCity('sharjah', 'ae-sh', 'Sharjah', 'الشارقة'),
    UaeCity('khor-fakkan', 'ae-sh', 'Khor Fakkan', 'خورفكان', [
      'Khorfakkan',
      'خور فكان',
    ]),
    UaeCity('kalba', 'ae-sh', 'Kalba', 'كلباء'),
    UaeCity('dibba-al-hisn', 'ae-sh', 'Dibba Al Hisn', 'دبا الحصن'),
    UaeCity('ajman', 'ae-aj', 'Ajman', 'عجمان'),
    UaeCity('masfout', 'ae-aj', 'Masfout', 'مصفوت'),
    UaeCity('ras-al-khaimah', 'ae-rk', 'Ras Al Khaimah', 'رأس الخيمة', [
      'RAK',
      'Ras Al-Khaimah',
    ]),
    UaeCity('fujairah', 'ae-fu', 'Fujairah', 'الفجيرة'),
    UaeCity('dibba-al-fujairah', 'ae-fu', 'Dibba Al Fujairah', 'دبا الفجيرة'),
    UaeCity('umm-al-quwain', 'ae-uq', 'Umm Al Quwain', 'أم القيوين', [
      'UAQ',
      'Umm Al-Quwain',
    ]),
  ],
  areas: [
    UaeArea(
      'dubai-healthcare-city',
      'dubai',
      'Dubai Healthcare City',
      'مدينة دبي الطبية',
    ),
    UaeArea('jumeirah', 'dubai', 'Jumeirah', 'جميرا'),
    UaeArea('al-barsha', 'dubai', 'Al Barsha', 'البرشاء'),
    UaeArea('al-bateen', 'abu-dhabi', 'Al Bateen', 'البطين'),
    UaeArea('khalifa-city', 'abu-dhabi', 'Khalifa City', 'مدينة خليفة'),
    UaeArea('al-majaz', 'sharjah', 'Al Majaz', 'المجاز'),
    UaeArea('al-nuaimiya', 'ajman', 'Al Nuaimiya', 'النعيمية'),
    UaeArea('al-nakheel', 'ras-al-khaimah', 'Al Nakheel', 'النخيل'),
    UaeArea('al-salamah', 'umm-al-quwain', 'Al Salamah', 'السلامة'),
  ],
);
