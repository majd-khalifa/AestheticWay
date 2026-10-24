import '../models/uae_location.dart';

/// Replace with source-verified server implementation when Ali supplies a catalog.
/// No assumed /locations/ route, network geocoder or patient coordinates.
abstract class UaeLocationRepository {
  Future<UaeLocationCatalog> load();
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
