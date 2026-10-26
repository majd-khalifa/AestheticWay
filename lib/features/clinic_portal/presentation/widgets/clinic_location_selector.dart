import '../../../locations/models/uae_location.dart';
import '../../data/clinic_address_search.dart';
import '../../../google_business/presentation/google_business_screen.dart';
import '../../../google_business/data/google_business_repository.dart';
import '../../../../core/auth/session_snapshot.dart';
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
      lat >= 22 &&
      lat <= 26.5 &&
      lng >= 51 &&
      lng <= 57 &&
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
Future<ClinicLocationSelection?> showClinicLocationSelector(
  BuildContext context, {
  required String city,
  required String addressAr,
  required String addressEn,
  required double latitude,
  required double longitude,
  ClinicAddressSearch? addressSearch,
  GoogleBusinessRepository? googleRepository,
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
    addressSearch: addressSearch,
    googleRepository: googleRepository,
  ),
);

class _LocationSheet extends StatefulWidget {
  const _LocationSheet({
    required this.city,
    required this.addressAr,
    required this.addressEn,
    required this.latitude,
    required this.longitude,
    this.addressSearch,
    this.googleRepository,
  });
  final ClinicAddressSearch? addressSearch;
  final GoogleBusinessRepository? googleRepository;
  final String city, addressAr, addressEn;
  final double latitude, longitude;
  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  final _map = MapController();
  late final _addresses = widget.addressSearch ?? ClinicAddressSearch();
  final _session = SessionSnapshot();
  final _latitude = TextEditingController(),
      _longitude = TextEditingController();
  bool _pointSelected = false;
  String? _notice;
  bool _missingEnglish = false, _missingArabic = false;
  final _query = TextEditingController();
  late final TextEditingController _addressAr, _addressEn;
  late String _city;
  String? _areaCode;
  late LatLng _point;
  bool _confirmed = false, _searching = false;
  String? _error;
  List<ClinicAddressResult> _results = [];
  final _cancel = CancelToken();
  DateTime? _lastSearch;
  bool get _ar => LocaleService().isArabic;
  @override
  void initState() {
    super.initState();
    _city = currentUaeCatalog.resolve(widget.city)?.nameEn ?? widget.city;
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
    _pointSelected = _confirmed;
    _latitude.text = _point.latitude.toStringAsFixed(7);
    _longitude.text = _point.longitude.toStringAsFixed(7);
    _addressAr = TextEditingController(text: widget.addressAr);
    _addressEn = TextEditingController(text: widget.addressEn);
  }

  @override
  void dispose() {
    _cancel.cancel();
    if (widget.addressSearch == null) _addresses.close();
    _latitude.dispose();
    _longitude.dispose();
    _map.dispose();
    _query.dispose();
    _addressAr.dispose();
    _addressEn.dispose();
    super.dispose();
  }

  void _select(LatLng point, {bool move = true}) {
    if (!ClinicAddressResult.withinUae(point.latitude, point.longitude)) {
      setState(
        () => _error = _ar
            ? 'اختر إحداثيات داخل الإمارات بترتيب خط العرض ثم خط الطول.'
            : 'Choose UAE coordinates in latitude, longitude order.',
      );
      return;
    }
    setState(() {
      _point = point;
      _confirmed = false;
      _pointSelected = true;
      _latitude.text = point.latitude.toStringAsFixed(7);
      _longitude.text = point.longitude.toStringAsFixed(7);
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
      _pointSelected = false;
      _latitude.text = _point.latitude.toStringAsFixed(7);
      _longitude.text = _point.longitude.toStringAsFixed(7);
      _notice = _ar
          ? 'راجع العنوان بعد تغيير المنطقة؛ احتُفظ بالنص السابق.'
          : 'Review the address after changing locality; your existing text was retained.';
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
    if (coordinates.length == 2 && coordinates.every((n) => n != null)) {
      setState(
        () => _error = _ar
            ? 'الإحداثيات خارج الإمارات أو معكوسة.'
            : 'Coordinates are outside UAE or reversed.',
      );
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
      final rows = await _addresses.search(
        q,
        language: _ar ? 'ar' : 'en',
        cancelToken: _cancel,
      );
      if (!mounted || !_session.isCurrent || q != _query.text.trim()) return;
      setState(() {
        _results = rows;
        if (_results.isEmpty) {
          _error = _ar
              ? 'لم نجد عنواناً. ابحث عن اسم العيادة عبر Google Business أو اضبط المدخل يدوياً.'
              : 'No address found. Search clinic names through Google Business, or choose the entrance manually.';
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

  Future<void> _applyAddress(ClinicAddressResult result) async {
    if (!_session.isCurrent) return;
    final catalog = currentUaeCatalog;
    final city = catalog.resolve(result.city);
    final selected = catalog.resolve(_city);
    final emirate = catalog.emirates
        .where(
          (e) => [e.code, e.nameEn, e.nameAr].any(
            (v) =>
                UaeLocationCatalog.normalize(v) ==
                UaeLocationCatalog.normalize(result.emirate),
          ),
        )
        .firstOrNull;
    if (emirate != null &&
        ((city != null && city.emirateCode != emirate.code) ||
            (city == null && selected?.emirateCode != emirate.code))) {
      setState(
        () => _error = _ar
            ? 'عنوان النتيجة لا يطابق الإمارة المختارة. راجع الإمارة والمدينة أولاً.'
            : 'The result does not match the selected emirate. Review the emirate and city first.',
      );
      return;
    }
    final replace =
        (_addressEn.text.trim().isNotEmpty &&
            result.addressEn.isNotEmpty &&
            _addressEn.text.trim() != result.addressEn) ||
        (_addressAr.text.trim().isNotEmpty &&
            result.addressAr.isNotEmpty &&
            _addressAr.text.trim() != result.addressAr) ||
        (city != null && city.code != selected?.code);
    if (replace) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          scrollable: true,
          title: Text(
            _ar ? 'مراجعة العنوان المقترح' : 'Review proposed address',
          ),
          content: Text(
            '${result.title}\n\n${_ar ? 'هل تريد استبدال النص المتوفر وتحديث المدينة المطابقة؟ ستبقى اللغة غير المتوفرة كما هي للمراجعة.' : 'Replace available address text and update a matching catalog city? Unavailable language text is retained for review.'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_ar ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_ar ? 'استخدام العنوان' : 'Use address'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted || !_session.isCurrent) return;
    }
    _select(LatLng(result.latitude, result.longitude));
    setState(() {
      if (city != null && city.code != selected?.code) {
        _city = city.nameEn;
        _areaCode = null;
      }
      if (result.addressEn.isNotEmpty) _addressEn.text = result.addressEn;
      if (result.addressAr.isNotEmpty) _addressAr.text = result.addressAr;
      _missingEnglish = result.addressEn.isEmpty;
      _missingArabic = result.addressAr.isEmpty;
      _notice = _ar
          ? 'العنوان من OpenStreetMap. راجع المدينة والنص باللغتين، ثم أكّد المدخل.'
          : 'Address from OpenStreetMap. Review the city and both language fields, then confirm the entrance.';
      _results = [];
    });
  }

  Future<void> _confirmPin() async {
    final city = currentUaeCatalog.resolve(_city);
    if (!_pointSelected || city == null || !_session.isCurrent) {
      setState(
        () => _error = _ar
            ? 'اختر المدينة من القائمة واضبط المدخل أولاً.'
            : 'Choose a catalog city and select the entrance first.',
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(_ar ? 'تأكيد المدخل الدقيق' : 'Confirm exact entrance'),
        content: Text(
          '${city.label(_ar)} · ${currentUaeCatalog.emirateFor(city).label(_ar)}\n${_point.latitude.toStringAsFixed(7)}, ${_point.longitude.toStringAsFixed(7)}\n\n${_ar ? 'أكّد أن هذا المدخل يقع في المدينة والإمارة المختارتين. لا يغيّر هذا تأكيد نشاط Google.' : 'Confirm this entrance belongs to the selected city and emirate. This does not change or verify Google Business identity.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_ar ? 'تأكيد المدخل' : 'Confirm entrance'),
          ),
        ],
      ),
    );
    if (mounted && _session.isCurrent && ok == true) {
      setState(() => _confirmed = true);
    }
  }

  void _previewCoordinates() {
    final lat = double.tryParse(_latitude.text.trim()),
        lng = double.tryParse(_longitude.text.trim());
    if (lat == null ||
        lng == null ||
        !ClinicAddressResult.withinUae(lat, lng)) {
      setState(
        () => _error = _ar
            ? 'أدخل خط العرض ثم خط الطول داخل الإمارات.'
            : 'Enter valid UAE latitude, then longitude.',
      );
      return;
    }
    _select(LatLng(lat, lng));
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _ar ? 'هوية النشاط التجاري' : 'Business identity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    _ar
                        ? 'لأسماء العيادات المنسوخة من خرائط Google استخدم البحث الموثق. لا يغيّر الربط دبوس المدخل.'
                        : 'For clinic names copied from Google Maps, use verified business search. Linking does not move the entrance pin.',
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.business_outlined),
                    label: Text(
                      _ar
                          ? 'البحث في Google Business'
                          : 'Search Google Business',
                    ),
                    onPressed: _searching
                        ? null
                        : () async {
                            await Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GoogleBusinessScreen(
                                  repository: widget.googleRepository,
                                  initialQuery: _query.text,
                                  searchCity: _city,
                                ),
                              ),
                            );
                            if (mounted && _session.isCurrent) {
                              setState(
                                () => _notice = _ar
                                    ? 'احتُفظ بمسودة المدخل؛ ارتباط Google مستقل.'
                                    : 'Your entrance draft is preserved; Google linking is separate.',
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          UaeLocationField(
            value: _city,
            areaCode: _areaCode,
            onLocalityChanged: _localityChanged,
            allowAll: false,
            onChanged: (value) {
              final city = currentUaeCatalog.resolve(value);
              if (city == null) return;
              _localityChanged(UaeLocality(city));
            },
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('clinic-address-search'),
            controller: _query,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              labelText: _ar
                  ? 'بحث عنوان مستقل · OpenStreetMap'
                  : 'Independent address search · OpenStreetMap',
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
              key: ValueKey('clinic-address-result-${result.title}'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                result.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              leading: const Icon(Icons.place_outlined),
              onTap: () => _applyAddress(result),
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
            key: const ValueKey('clinic-entrance-map'),
            latitude: _point.latitude,
            longitude: _point.longitude,
            height: 240,
            controller: _map,
            onTap: (point) => _select(point, move: false),
          ),
          const SizedBox(height: 12),
          Text(
            _ar ? 'تصحيح المدخل يدوياً' : 'Correct the entrance manually',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('clinic-pin-latitude'),
                  controller: _latitude,
                  textDirection: TextDirection.ltr,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  onChanged: (_) => setState(() {
                    _confirmed = false;
                    _pointSelected = false;
                  }),
                  decoration: InputDecoration(
                    labelText: _ar ? 'خط العرض' : 'Latitude',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: const ValueKey('clinic-pin-longitude'),
                  controller: _longitude,
                  textDirection: TextDirection.ltr,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  onChanged: (_) => setState(() {
                    _confirmed = false;
                    _pointSelected = false;
                  }),
                  decoration: InputDecoration(
                    labelText: _ar ? 'خط الطول' : 'Longitude',
                  ),
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: _previewCoordinates,
            icon: const Icon(Icons.location_on_outlined),
            label: Text(_ar ? 'مراجعة الإحداثيات' : 'Review coordinates'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: !_pointSelected ? null : _confirmPin,
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
            key: const ValueKey('clinic-address-ar'),
            controller: _addressAr,
            onChanged: (_) => setState(() => _missingArabic = false),
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              labelText: 'العنوان بالعربية',
              hintText: 'المنطقة، الشارع، المبنى، الطابق',
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
          ),
          if (_missingArabic)
            Text(
              _ar
                  ? 'العنوان العربي غير متوفر في النتيجة؛ أدخله أو راجع النص الحالي.'
                  : 'Arabic address was not provided; enter it or review existing text.',
            ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('clinic-address-en'),
            controller: _addressEn,
            onChanged: (_) => setState(() => _missingEnglish = false),
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'Address (English)',
              hintText: 'Area, street, building, floor',
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
          ),
          if (_missingEnglish)
            Text(
              _ar
                  ? 'العنوان الإنجليزي غير متوفر في النتيجة؛ أدخله أو راجع النص الحالي.'
                  : 'English address was not provided; enter it or review existing text.',
            ),
          if (_notice != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Semantics(liveRegion: true, child: Text(_notice!)),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: !_confirmed || !_session.isCurrent
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
          // The editor owns this controller for its entire draft. Retain the
          // map while address fields scroll offscreen; dispose with the sheet.
          keepAlive: controller != null,
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
