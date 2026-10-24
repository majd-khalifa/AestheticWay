import 'package:flutter/material.dart';
import '../../../core/localization/app_locale.dart';
import '../data/uae_location_repository.dart';
import '../models/uae_location.dart';

Future<UaeCity?> showUaeLocationPicker(
  BuildContext context, {
  String? selected,
  UaeLocationRepository repository = const BundledUaeLocationRepository(),
}) => showModalBottomSheet<UaeCity>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => UaeLocationPicker(selected: selected, repository: repository),
);

class UaeLocationPicker extends StatefulWidget {
  const UaeLocationPicker({
    super.key,
    this.selected,
    this.repository = const BundledUaeLocationRepository(),
  });
  final String? selected;
  final UaeLocationRepository repository;
  @override
  State<UaeLocationPicker> createState() => _UaeLocationPickerState();
}

class _UaeLocationPickerState extends State<UaeLocationPicker> {
  UaeLocationCatalog? _catalog;
  String? _emirate, _error;
  String _query = '';
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
                    ar ? 'الإمارة ثم المدينة' : 'Emirate, then city',
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
                        _query = '';
                        _search.clear();
                      }),
                    ),
                    TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        labelText: ar ? 'البحث عن مدينة' : 'Search cities',
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (c != null && cities.isEmpty)
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
            if (c != null)
              SliverList.builder(
                itemCount: cities.length,
                itemBuilder: (ctx, i) {
                  final city = cities[i];
                  return ListTile(
                    title: Text(city.label(ar)),
                    subtitle: Text(c.emirateFor(city).label(ar)),
                    selected: c.resolve(widget.selected)?.code == city.code,
                    onTap: () => Navigator.pop(context, city),
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
  });
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled, allowAll;
  @override
  Widget build(BuildContext context) {
    final ar = LocaleService().isArabic;
    final city = compatibilityUaeCatalog.resolve(value);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: !enabled
                ? null
                : () async {
                    final city = await showUaeLocationPicker(
                      context,
                      selected: value,
                    );
                    if (context.mounted && city != null) onChanged(city.nameEn);
                  },
            icon: const Icon(Icons.location_on_outlined),
            label: Text(
              city?.label(ar) ??
                  (compatibilityUaeCatalog.legacyCityQuery(value) ??
                      (ar ? 'كل الإمارات' : 'All Emirates')),
            ),
          ),
        ),
        if (allowAll && compatibilityUaeCatalog.legacyCityQuery(value) != null)
          IconButton(
            tooltip: ar ? 'كل الإمارات' : 'All Emirates',
            onPressed: enabled ? () => onChanged('All') : null,
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }
}
