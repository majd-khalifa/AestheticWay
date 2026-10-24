import '../../../locations/models/uae_location.dart';
import '../../../locations/presentation/uae_location_picker.dart';
import '../../../locations/data/uae_location_repository.dart';
import '../../../../core/utils/clinic_location.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';

/// Coordinates are only persisted after the user explicitly confirms the pin.
class ClinicLocationSelection {
  const ClinicLocationSelection({
    required this.city,
    required this.addressAr,
    required this.addressEn,
    required this.latitude,
    required this.longitude,
  });
  final String city, addressAr, addressEn;
  String get emirate => currentUaeCatalog.resolve(city) == null
      ? city
      : currentUaeCatalog.emirateFor(currentUaeCatalog.resolve(city)!).nameEn;
  final double latitude, longitude;
  String get googleMapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=${latitude.toStringAsFixed(7)},${longitude.toStringAsFixed(7)}';
  static bool validCoordinates(double lat, double lng) =>
      lat.isFinite &&
      lng.isFinite &&
      lat >= -90 &&
      lat <= 90 &&
      lng >= -180 &&
      lng <= 180 &&
      (lat != 0 || lng != 0);
}

String clinicLocationSummary(
  String city,
  String address, {
  required bool arabic,
}) => formatClinicLocation(city, address, arabic: arabic);

const _emirates = <String, (String, double, double)>{
  'Dubai': ('دبي', 25.2048, 55.2708),
  'Abu Dhabi': ('أبوظبي', 24.4539, 54.3773),
  'Sharjah': ('الشارقة', 25.3463, 55.4209),
  'Ajman': ('عجمان', 25.4052, 55.5136),
  'Ras Al Khaimah': ('رأس الخيمة', 25.7895, 55.9432),
  'Fujairah': ('الفجيرة', 25.1288, 56.3265),
  'Umm Al Quwain': ('أم القيوين', 25.5647, 55.5552),
};
const _districts = <String, List<(String, String, double, double)>>{
  'Dubai': [
    ('Dubai Healthcare City', 'مدينة دبي الطبية', 25.2315, 55.3242),
    ('Jumeirah', 'جميرا', 25.2105, 55.2531),
    ('Al Barsha', 'البرشاء', 25.1124, 55.2006),
  ],
  'Abu Dhabi': [
    ('Al Bateen', 'البطين', 24.4516, 54.3531),
    ('Khalifa City', 'مدينة خليفة', 24.4257, 54.6056),
  ],
  'Sharjah': [('Al Majaz', 'المجاز', 25.3248, 55.3937)],
  'Ajman': [('Al Nuaimiya', 'النعيمية', 25.3901, 55.4532)],
  'Ras Al Khaimah': [('Al Nakheel', 'النخيل', 25.7919, 55.9638)],
  'Fujairah': [('City Centre', 'وسط المدينة', 25.1288, 56.3265)],
  'Umm Al Quwain': [('Al Salamah', 'السلامة', 25.5398, 55.5513)],
};

Future<ClinicLocationSelection?> showClinicLocationSelector(
  BuildContext context, {
  required String city,
  required String addressAr,
  required String addressEn,
  required double latitude,
  required double longitude,
}) => showModalBottomSheet<ClinicLocationSelection>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppColors.surface(context),
  builder: (_) => _LocationSheet(
    city: city,
    addressAr: addressAr,
    addressEn: addressEn,
    latitude: latitude,
    longitude: longitude,
  ),
);

class _LocationSheet extends StatefulWidget {
  const _LocationSheet({
    required this.city,
    required this.addressAr,
    required this.addressEn,
    required this.latitude,
    required this.longitude,
  });
  final String city, addressAr, addressEn;
  final double latitude, longitude;
  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  final _map = MapController();
  // A separate public client deliberately avoids the app's authentication interceptor.
  final _searchClient = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'User-Agent': 'AestheticWay/1.0 (https://aestheticway.ae)'},
    ),
  );
  final _query = TextEditingController();
  late final TextEditingController _addressAr, _addressEn;
  late String _city;
  String? _areaCode;
  late LatLng _point;
  bool _confirmed = false, _searching = false;
  String? _error;
  List<Map<String, dynamic>> _results = [];
  final _cancel = CancelToken();
  DateTime? _lastSearch;
  bool get _ar => LocaleService().isArabic;
  @override
  void initState() {
    super.initState();
    _city =
        currentUaeCatalog.resolve(widget.city)?.nameEn ??
        (widget.city.isNotEmpty ? widget.city : 'Dubai');
    _confirmed = ClinicLocationSelection.validCoordinates(
      widget.latitude,
      widget.longitude,
    );
    final e =
        _emirates[currentUaeCatalog.resolve(_city) == null
            ? _city
            : currentUaeCatalog
                  .emirateFor(currentUaeCatalog.resolve(_city)!)
                  .nameEn] ??
        _emirates['Dubai']!;
    _point = _confirmed
        ? LatLng(widget.latitude, widget.longitude)
        : LatLng(e.$2, e.$3);
    _addressAr = TextEditingController(text: widget.addressAr);
    _addressEn = TextEditingController(text: widget.addressEn);
  }

  @override
  void dispose() {
    _cancel.cancel();
    _searchClient.close(force: true);
    _map.dispose();
    _query.dispose();
    _addressAr.dispose();
    _addressEn.dispose();
    super.dispose();
  }

  void _select(LatLng point, {bool move = true}) {
    setState(() {
      _point = point;
      _confirmed = true;
      _error = null;
    });
    if (move) _map.move(point, 15);
  }

  void _localityChanged(UaeLocality value) {
    final e = _emirates[currentUaeCatalog.emirateFor(value.city).nameEn]!;
    setState(() {
      _city = value.city.nameEn;
      _areaCode = value.area?.code;
      _confirmed = false;
      _point = LatLng(e.$2, e.$3);
      _results = [];
      _addressEn.text = value.addressWithArea(_addressEn.text, arabic: false);
      _addressAr.text = value.addressWithArea(_addressAr.text, arabic: true);
    });
    _map.move(_point, 10);
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.isEmpty || _searching) return;
    final coordinates = q
        .split(RegExp(r'[,،\s]+'))
        .map(double.tryParse)
        .toList();
    if (coordinates.length == 2 &&
        coordinates.every((n) => n != null) &&
        ClinicLocationSelection.validCoordinates(
          coordinates[0]!,
          coordinates[1]!,
        )) {
      _select(LatLng(coordinates[0]!, coordinates[1]!));
      return;
    }
    // Explicit searches only; no autocomplete or background address uploads.
    if (_lastSearch != null &&
        DateTime.now().difference(_lastSearch!) < const Duration(seconds: 1)) {
      return;
    }
    _lastSearch = DateTime.now();
    setState(() {
      _searching = true;
      _error = null;
      _results = [];
    });
    try {
      final response = await _searchClient.get<List<dynamic>>(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': q,
          'format': 'jsonv2',
          'countrycodes': 'ae',
          'limit': 4,
          'accept-language': _ar ? 'ar' : 'en',
          'addressdetails': 1,
        },
        cancelToken: _cancel,
      );
      if (!mounted) return;
      setState(() {
        _results = (response.data ?? [])
            .map((v) => Map<String, dynamic>.from(v as Map))
            .toList();
        if (_results.isEmpty) {
          _error = _ar
              ? 'لم نجد المكان. اختر المنطقة واضبط الدبوس.'
              : 'No place found. Choose an area and adjust the pin.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = _ar
              ? 'تعذر البحث. اختر منطقة أو اضبط الدبوس على الخريطة.'
              : 'Search unavailable. Choose an area or adjust the map pin.',
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .9,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: ListView(
        key: const ValueKey('clinic-location-form'),
        children: [
          Text(
            _ar ? 'تحديد موقع العيادة' : 'Choose Clinic Location',
            style: TextStyle(
              color: AppColors.text(context),
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _ar
                ? 'اختر المنطقة ثم اضغط على الموقع الدقيق للعيادة على الخريطة.'
                : 'Choose an area, then tap the clinic’s exact position on the map.',
            style: TextStyle(color: AppColors.mutedText(context)),
          ),
          Text(
            _ar
                ? 'خريطة يدوية من OpenStreetMap؛ لا تربط نشاط Google ولا تتحقق منه.'
                : 'Manual OpenStreetMap map; this does not link or verify a Google Business.',
          ),
          const SizedBox(height: 16),
          UaeLocationField(
            value: _city,
            areaCode: _areaCode,
            onLocalityChanged: _localityChanged,
            allowAll: false,
            onChanged: (value) {
              final city = currentUaeCatalog.resolve(value);
              if (city == null) return;
              final e = _emirates[currentUaeCatalog.emirateFor(city).nameEn]!;
              setState(() {
                _city = city.nameEn;
                _confirmed = false;
                _point = LatLng(e.$2, e.$3);
                _results = [];
              });
              _map.move(_point, 10);
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: (_districts[_city] ?? [])
                .map(
                  (d) => ActionChip(
                    label: Text(_ar ? d.$2 : d.$1),
                    onPressed: () {
                      setState(() {
                        _confirmed = false;
                        _point = LatLng(d.$3, d.$4);
                      });
                      _map.move(_point, 14);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _query,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              labelText: _ar
                  ? 'ابحث عن مكان أو أدخل إحداثيات'
                  : 'Search place or enter coordinates',
              hintText: _ar
                  ? 'مدينة دبي الطبية أو 25.2315, 55.3242'
                  : 'Dubai Healthcare City or 25.2315, 55.3242',
              suffixIcon: IconButton(
                onPressed: _searching ? null : _search,
                tooltip: _ar ? 'بحث' : 'Search',
                icon: _searching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
              ),
            ),
          ),
          for (final result in _results)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                result['display_name']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              leading: const Icon(Icons.place_outlined),
              onTap: () {
                final lat = double.tryParse('${result['lat']}'),
                    lng = double.tryParse('${result['lon']}');
                if (lat == null ||
                    lng == null ||
                    !ClinicLocationSelection.validCoordinates(lat, lng)) {
                  return;
                }
                _select(LatLng(lat, lng));
                setState(() => _results = []);
              },
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _error!,
                style: TextStyle(color: AppColors.text(context)),
              ),
            ),
          const SizedBox(height: 12),
          ClinicMapPreview(
            latitude: _point.latitude,
            longitude: _point.longitude,
            height: 240,
            controller: _map,
            onTap: (point) => _select(point, move: false),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => setState(() => _confirmed = true),
            child: Text(
              _ar
                  ? 'تأكيد أن الدبوس هو موقع العيادة الدقيق'
                  : 'Confirm pin is the exact clinic location',
            ),
          ),
          Text(
            '${_point.latitude.toStringAsFixed(7)}, ${_point.longitude.toStringAsFixed(7)}',
            textDirection: TextDirection.ltr,
            style: TextStyle(color: AppColors.mutedText(context)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressAr,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              labelText: 'العنوان بالعربية',
              hintText: 'المنطقة، الشارع، المبنى، الطابق',
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressEn,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'Address (English)',
              hintText: 'Area, street, building, floor',
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: !_confirmed
                ? null
                : () => Navigator.pop(
                    context,
                    ClinicLocationSelection(
                      city: _city,
                      addressAr: _addressAr.text.trim(),
                      addressEn: _addressEn.text.trim(),
                      latitude: _point.latitude,
                      longitude: _point.longitude,
                    ),
                  ),
            icon: const Icon(Icons.check_rounded),
            label: Text(_ar ? 'اعتماد هذا الموقع' : 'Use This Location'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_ar ? 'إلغاء' : 'Cancel'),
          ),
        ],
      ),
    ),
  );
}

/// Interactive OSM tiles need no Google API key. Credits remain visible on-map.
class ClinicMapPreview extends StatelessWidget {
  const ClinicMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 140,
    this.controller,
    this.onTap,
  });
  final double latitude, longitude, height;
  final MapController? controller;
  final ValueChanged<LatLng>? onTap;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: SizedBox(
      height: height,
      child: FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: LatLng(latitude, longitude),
          initialZoom: 14,
          interactionOptions: InteractionOptions(
            flags: onTap == null
                ? InteractiveFlag.none
                : InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          onTap: (_, point) => onTap?.call(point),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'ae.aestheticway.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(latitude, longitude),
                width: 44,
                height: 44,
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF9F1239),
                  size: 40,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Material(
              color: AppColors.surface(context).withValues(alpha: .95),
              child: InkWell(
                onTap: () => launchUrl(
                  Uri.parse('https://www.openstreetmap.org/copyright'),
                  mode: LaunchMode.externalApplication,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Text(
                    '© OpenStreetMap contributors',
                    softWrap: true,
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
