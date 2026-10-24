import 'package:flutter/material.dart';
import '../../../core/localization/app_locale.dart';
import '../data/uae_location_repository.dart';
import '../models/uae_location.dart';

Future<UaeCity?> showUaeLocationPicker(
  BuildContext context, {
  String? selected,
  UaeLocationRepository repository = const ServerUaeLocationRepository(),
}) => showModalBottomSheet<UaeCity>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => UaeLocationPicker(selected: selected, repository: repository),
);

Future<UaeLocality?> showUaeLocalityPicker(
  BuildContext context, {
  String? selected,
  String? areaCode,
  UaeLocationRepository repository = const ServerUaeLocationRepository(),
}) => showModalBottomSheet<UaeLocality>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => UaeLocationPicker(
    selected: selected,
    selectedAreaCode: areaCode,
    includeAreas: true,
    repository: repository,
  ),
);

class UaeLocationPicker extends StatefulWidget {
  const UaeLocationPicker({
    super.key,
    this.selected,
    this.selectedAreaCode,
    this.includeAreas = false,
    this.repository = const ServerUaeLocationRepository(),
  });
  final String? selected;
  final String? selectedAreaCode;
  final bool includeAreas;
  final UaeLocationRepository repository;
  @override
  State<UaeLocationPicker> createState() => _UaeLocationPickerState();
}

class _UaeLocationPickerState extends State<UaeLocationPicker> {
  UaeLocationCatalog? _catalog;
  String? _emirate, _error;
  String _query = '';
  UaeCity? _city;
  final _search = TextEditingController();
  bool get ar => LocaleService().isArabic;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final c = await widget.repository.load();
      if (mounted) {
        setState(() {
          _catalog = c;
          _emirate = c.resolve(widget.selected)?.emirateCode;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = ar ? 'تعذر تحميل المواقع' : 'Locations could not load',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _catalog;
    final cities =
        c?.cities
            .where(
              (v) =>
                  (_emirate == null || v.emirateCode == _emirate) &&
                  UaeLocationCatalog.normalize(
                    '${v.nameEn} ${v.nameAr} ${v.aliases.join(' ')}',
                  ).contains(UaeLocationCatalog.normalize(_query)),
            )
            .toList() ??
        [];
    final areas =
        c?.areas
            .where(
              (a) =>
                  a.cityCode == _city?.code &&
                  UaeLocationCatalog.normalize(
                    '${a.nameEn} ${a.nameAr} ${a.aliases.join(' ')}',
                  ).contains(UaeLocationCatalog.normalize(_query)),
            )
            .toList() ??
        [];
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .82,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.includeAreas
                        ? (ar
                              ? 'الإمارة، المدينة، المنطقة'
                              : 'Emirate, city, area')
                        : (ar ? 'الإمارة ثم المدينة' : 'Emirate, then city'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (c == null && _error == null)
                    const LinearProgressIndicator(),
                  if (_error != null)
                    TextButton(
                      onPressed: _load,
                      child: Text(
                        '$_error · ${ar ? 'إعادة المحاولة' : 'Retry'}',
                      ),
                    ),
                  if (c != null) ...[
                    if (!c.authoritative)
                      Text(
                        ar
                            ? 'مدن متاحة للاختيار؛ القائمة ليست شاملة. الأحياء تُضاف في العنوان.'
                            : 'Available cities; this list is not exhaustive. Districts belong in the address.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    DropdownButtonFormField<String>(
                      initialValue: _emirate,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: ar ? 'الإمارة' : 'Emirate',
                      ),
                      items: c.emirates
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.code,
                              child: Text(e.label(ar)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _emirate = v;
                        _city = null;
                        _query = '';
                        _search.clear();
                      }),
                    ),
                    TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        labelText: _city == null
                            ? (ar ? 'البحث عن مدينة' : 'Search cities')
                            : (ar ? 'البحث عن منطقة' : 'Search areas'),
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (c != null && _city == null && cities.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    ar
                        ? 'لا توجد مدينة مطابقة ضمن القائمة المتاحة'
                        : 'No matching city in the available catalog',
                  ),
                ),
              ),
            if (c != null && _city == null)
              SliverList.builder(
                itemCount: cities.length,
                itemBuilder: (ctx, i) {
                  final city = cities[i];
                  return ListTile(
                    title: Text(city.label(ar)),
                    subtitle: Text(c.emirateFor(city).label(ar)),
                    selected: c.resolve(widget.selected)?.code == city.code,
                    onTap: () {
                      if (!widget.includeAreas) {
                        Navigator.pop(context, city);
                      } else {
                        setState(() {
                          _city = city;
                          _query = '';
                          _search.clear();
                        });
                      }
                    },
                  );
                },
              ),
            if (_city != null)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _city = null;
                        _query = '';
                        _search.clear();
                      }),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(ar ? 'تغيير المدينة' : 'Change city'),
                    ),
                    ListTile(
                      title: Text(
                        ar
                            ? 'كل مناطق ${_city!.nameAr}'
                            : 'Whole city: ${_city!.nameEn}',
                      ),
                      onTap: () => Navigator.pop(context, UaeLocality(_city!)),
                    ),
                    if (areas.isEmpty)
                      Text(
                        ar
                            ? 'لا توجد مناطق مطابقة في القائمة الجزئية المتاحة. يمكنك اختيار المدينة.'
                            : 'No matching areas in this partial catalog. You can select the whole city.',
                      ),
                  ],
                ),
              ),
            if (_city != null)
              SliverList.builder(
                itemCount: areas.length,
                itemBuilder: (_, i) {
                  final area = areas[i];
                  return ListTile(
                    title: Text(area.label(ar)),
                    subtitle: Text(_city!.label(ar)),
                    selected: area.code == widget.selectedAreaCode,
                    onTap: () =>
                        Navigator.pop(context, UaeLocality(_city!, area)),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Reusable field for patient filters and authorized clinic/admin editors.
class UaeLocationField extends StatelessWidget {
  const UaeLocationField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.allowAll = true,
    this.areaCode,
    this.onLocalityChanged,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled, allowAll;
  final String? areaCode;
  final ValueChanged<UaeLocality>? onLocalityChanged;
  @override
  Widget build(BuildContext context) {
    final ar = LocaleService().isArabic;
    final city = currentUaeCatalog.resolve(value);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: !enabled
                ? null
                : () async {
                    final locality = await showUaeLocalityPicker(
                      context,
                      selected: value,
                      areaCode: areaCode,
                    );
                    if (context.mounted && locality != null) {
                      if (onLocalityChanged != null) {
                        onLocalityChanged!(locality);
                      } else {
                        onChanged(locality.city.nameEn);
                      }
                    }
                  },
            icon: const Icon(Icons.location_on_outlined),
            label: Text(
              (city == null
                      ? null
                      : UaeLocality(
                          city,
                          currentUaeCatalog.resolveArea(
                            areaCode,
                            cityCode: city.code,
                          ),
                        ).label(ar)) ??
                  (currentUaeCatalog.legacyCityQuery(value) ??
                      (ar ? 'كل الإمارات' : 'All Emirates')),
            ),
          ),
        ),
        if (allowAll && currentUaeCatalog.legacyCityQuery(value) != null)
          IconButton(
            tooltip: ar ? 'كل الإمارات' : 'All Emirates',
            onPressed: enabled ? () => onChanged('All') : null,
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }
}
