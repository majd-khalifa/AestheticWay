import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/auth/session_snapshot.dart';
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

enum _LocationStep { emirate, city, area }

class _UaeLocationPickerState extends State<UaeLocationPicker> {
  UaeLocationCatalog? _catalog;
  String? _emirate, _error;
  UaeCity? _city;
  UaeArea? _area;
  _LocationStep _step = _LocationStep.emirate;
  String _query = '';
  bool _loading = true;
  final _search = TextEditingController();
  final _scroll = ScrollController();
  bool get ar => LocaleService().isArabic;
  String t(String en, String arabic) => ar ? arabic : en;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = await widget.repository.load();
      if (!mounted) return;
      setState(() {
        _catalog = c;
        _city = c.resolve(widget.selected);
        _emirate = _city?.emirateCode;
        _area = _city == null
            ? null
            : c.resolveArea(widget.selectedAreaCode, cityCode: _city!.code);
        _step = _city == null ? _LocationStep.emirate : _LocationStep.city;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = t('Locations could not load', 'تعذر تحميل المواقع'),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _go(_LocationStep step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      _query = '';
      _search.clear();
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _back() => _go(
    _step == _LocationStep.area ? _LocationStep.city : _LocationStep.emirate,
  );
  void _finish() {
    if (_city == null) return;
    Navigator.pop(
      context,
      widget.includeAreas ? UaeLocality(_city!, _area) : _city,
    );
  }

  bool _matches(String value) => UaeLocationCatalog.normalize(
    value,
  ).contains(UaeLocationCatalog.normalize(_query));

  Widget _choice({
    required String key,
    required String title,
    required bool selected,
    required VoidCallback onTap,
    String? subtitle,
    IconData icon = Icons.place_outlined,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected
                ? colors.primary
                : colors.outlineVariant.withValues(alpha: .5),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          key: ValueKey(key),
          selected: selected,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          leading: Icon(
            icon,
            color: selected
                ? colors.onPrimaryContainer
                : colors.onSurfaceVariant,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? colors.onPrimaryContainer : colors.onSurface,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle,
                  style: TextStyle(
                    color: selected
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                  ),
                ),
          trailing: Icon(
            selected ? Icons.check_circle : Icons.chevron_right,
            color: selected
                ? colors.onPrimaryContainer
                : colors.onSurfaceVariant,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _crumb(
    int index,
    String label,
    String? value,
    _LocationStep step,
    bool enabled,
  ) {
    final colors = Theme.of(context).colorScheme;
    final active = step == _step;
    return Expanded(
      child: Semantics(
        selected: active,
        child: InkWell(
          key: ValueKey('locality-step-${step.name}'),
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? () => _go(step) : null,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      active
                          ? Icons.radio_button_checked
                          : value != null
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                      size: 17,
                      color: active ? colors.primary : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '$index · $label',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  value ?? t('Choose', 'اختر'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _catalog;
    final emirate = c?.emirates.where((e) => e.code == _emirate).firstOrNull;
    final cities =
        c?.cities
            .where(
              (v) =>
                  (_emirate == null || v.emirateCode == _emirate) &&
                  _matches(
                    '${v.nameEn} ${v.nameAr} ${v.code} ${v.aliases.join(' ')}',
                  ),
            )
            .toList() ??
        [];
    final areas =
        c?.areas
            .where(
              (v) =>
                  v.cityCode == _city?.code &&
                  _matches(
                    '${v.nameEn} ${v.nameAr} ${v.code} ${v.aliases.join(' ')}',
                  ),
            )
            .toList() ??
        [];
    final emirates =
        c?.emirates
            .where((v) => _matches('${v.nameEn} ${v.nameAr} ${v.code}'))
            .toList() ??
        [];
    final heading = switch (_step) {
      _LocationStep.emirate => t('Choose an emirate', 'اختر الإمارة'),
      _LocationStep.city => t('Choose a city', 'اختر المدينة'),
      _LocationStep.area => t('Choose an area', 'اختر المنطقة'),
    };
    final rowCount = switch (_step) {
      _LocationStep.emirate => emirates.length,
      _LocationStep.city => cities.length,
      _LocationStep.area => areas.length + 1,
    };
    final emptyMessage =
        c == null || rowCount > (_step == _LocationStep.area ? 1 : 0)
        ? null
        : switch (_step) {
            _LocationStep.city => t(
              'No matching city in the available catalog',
              'لا توجد مدينة مطابقة ضمن القائمة المتاحة',
            ),
            _LocationStep.area => t(
              'No matching areas. You can select the whole city.',
              'لا توجد مناطق مطابقة. يمكنك اختيار المدينة كاملة.',
            ),
            _LocationStep.emirate => t(
              'No matching emirate',
              'لا توجد إمارة مطابقة',
            ),
          };
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final height = math.min(
      MediaQuery.sizeOf(context).height * .88,
      (250 + (_query.isEmpty ? rowCount : math.max(rowCount, 3)) * 80 + 100) *
              scale +
          MediaQuery.viewInsetsOf(context).bottom,
    );
    return PopScope(
      canPop: _step == _LocationStep.emirate,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: SizedBox(
        height: height,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  controller: _scroll,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 38,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (_step != _LocationStep.emirate)
                                  IconButton(
                                    key: const ValueKey('locality-back'),
                                    tooltip: t('Back', 'رجوع'),
                                    icon: const BackButtonIcon(),
                                    onPressed: _back,
                                  ),
                                Expanded(
                                  child: Text(
                                    t('Choose your location', 'اختر موقعك'),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ),
                                IconButton(
                                  tooltip: t('Close', 'إغلاق'),
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            if (c != null) ...[
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _crumb(
                                      1,
                                      t('Emirate', 'الإمارة'),
                                      emirate?.label(ar),
                                      _LocationStep.emirate,
                                      true,
                                    ),
                                    _crumb(
                                      2,
                                      t('City', 'المدينة'),
                                      _city?.label(ar),
                                      _LocationStep.city,
                                      _emirate != null,
                                    ),
                                    if (widget.includeAreas)
                                      _crumb(
                                        3,
                                        t('Area', 'المنطقة'),
                                        _area?.label(ar) ??
                                            (_city != null
                                                ? t('Whole city', 'كل المدينة')
                                                : null),
                                        _LocationStep.area,
                                        _city != null,
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                heading,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                key: const ValueKey('locality-search'),
                                controller: _search,
                                onChanged: (v) => setState(() => _query = v),
                                decoration: InputDecoration(
                                  labelText: switch (_step) {
                                    _LocationStep.emirate => t(
                                      'Search emirates',
                                      'البحث عن إمارة',
                                    ),
                                    _LocationStep.city => t(
                                      'Search cities',
                                      'البحث عن مدينة',
                                    ),
                                    _LocationStep.area => t(
                                      'Search areas',
                                      'البحث عن منطقة',
                                    ),
                                  },
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _query.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: t(
                                            'Clear search',
                                            'مسح البحث',
                                          ),
                                          icon: const Icon(Icons.close),
                                          onPressed: () => setState(() {
                                            _query = '';
                                            _search.clear();
                                          }),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (emptyMessage != null)
                                Semantics(
                                  liveRegion: true,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(emptyMessage),
                                  ),
                                ),
                              if (!c.authoritative)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    t(
                                      'Available catalog; some locations may be missing.',
                                      'الدليل المتاح قد لا يشمل بعض المواقع.',
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              if (widget.selected?.isNotEmpty == true &&
                                  c.resolve(widget.selected) == null)
                                Text(
                                  t(
                                    'Saved location: ${widget.selected}',
                                    'الموقع المحفوظ: ${widget.selected}',
                                  ),
                                ),
                            ],
                            if (_loading) const LinearProgressIndicator(),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.cloud_off_outlined,
                                      size: 32,
                                    ),
                                    Text(_error!),
                                    TextButton.icon(
                                      onPressed: _load,
                                      icon: const Icon(Icons.refresh),
                                      label: Text(t('Retry', 'إعادة المحاولة')),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (c != null && _step == _LocationStep.emirate)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList.builder(
                          itemCount: emirates.length,
                          itemBuilder: (_, i) {
                            final e = emirates[i];
                            return _choice(
                              key: 'locality-emirate-${e.code}',
                              title: e.label(ar),
                              selected: e.code == _emirate,
                              icon: Icons.location_city_outlined,
                              onTap: () {
                                if (_emirate != e.code) {
                                  _city = null;
                                  _area = null;
                                }
                                _emirate = e.code;
                                _go(_LocationStep.city);
                              },
                            );
                          },
                        ),
                      ),
                    if (c != null && _step == _LocationStep.city)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList.builder(
                          itemCount: cities.length,
                          itemBuilder: (_, i) {
                            final city = cities[i];
                            return _choice(
                              key: 'locality-city-${city.code}',
                              title: city.label(ar),
                              selected: city.code == _city?.code,
                              onTap: () {
                                if (_city?.code != city.code) _area = null;
                                _city = city;
                                _emirate = city.emirateCode;
                                if (!widget.includeAreas) {
                                  _finish();
                                } else {
                                  _go(_LocationStep.area);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    if (c != null && _step == _LocationStep.area) ...[
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: _choice(
                            key: 'locality-whole-city',
                            title: t(
                              'Whole city: ${_city!.nameEn}',
                              'كل مناطق ${_city!.nameAr}',
                            ),
                            selected: _area == null,
                            icon: Icons.location_city_outlined,
                            onTap: () => setState(() => _area = null),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList.builder(
                          itemCount: areas.length,
                          itemBuilder: (_, i) {
                            final area = areas[i];
                            return _choice(
                              key: 'locality-area-${area.code}',
                              title: area.label(ar),
                              selected: area.code == _area?.code,
                              onTap: () => setState(() => _area = area),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_city != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            UaeLocality(_city!, _area).label(ar),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      FilledButton.icon(
                        key: const ValueKey('locality-confirm'),
                        onPressed: _city == null ? null : _finish,
                        icon: const Icon(Icons.check),
                        label: Text(
                          _city == null
                              ? t(
                                  'Choose a city to continue',
                                  'اختر مدينة للمتابعة',
                                )
                              : t('Use location', 'استخدام الموقع'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable field for patient filters and authorized clinic/admin editors.
class UaeLocationField extends StatefulWidget {
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
  State<UaeLocationField> createState() => _UaeLocationFieldState();
}

class _UaeLocationFieldState extends State<UaeLocationField> {
  bool _opening = false;
  @override
  Widget build(BuildContext context) {
    final ar = LocaleService().isArabic;
    final value = widget.value, areaCode = widget.areaCode;
    final enabled = widget.enabled && !_opening, allowAll = widget.allowAll;
    final onChanged = widget.onChanged,
        onLocalityChanged = widget.onLocalityChanged;
    final city = currentUaeCatalog.resolve(value);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: !enabled
                ? null
                : () async {
                    if (_opening) return;
                    setState(() => _opening = true);
                    final session = SessionSnapshot();
                    try {
                      final locality = await showUaeLocalityPicker(
                        context,
                        selected: value,
                        areaCode: areaCode,
                      );
                      if (mounted && session.isCurrent && locality != null) {
                        if (onLocalityChanged != null) {
                          onLocalityChanged(locality);
                        } else {
                          onChanged(locality.city.nameEn);
                        }
                      }
                    } finally {
                      if (mounted) setState(() => _opening = false);
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
