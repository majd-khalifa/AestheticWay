import 'package:flutter/material.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/utils/maps_launcher.dart';
import '../../../core/widgets/async_action_button.dart';
import '../../../core/widgets/pagination_footer.dart';
import '../../appointment_lead/presentation/screens/appointment_request_screen.dart';
import '../../clinics/presentation/screens/clinics_list_screen.dart';
import '../../clinics/presentation/screens/clinic_profile_screen.dart';
import '../../clinics/presentation/widgets/patient_clinic_card.dart';
import '../data/nearby_clinics_repository.dart';
import '../services/nearby_discovery_controller.dart';
import '../services/patient_location_controller.dart';
import 'home_location_panel.dart';
import '../../../core/theme/app_colors.dart';

typedef NearbyGoogleMapBuilder =
    Widget Function(BuildContext, List<NearbyClinic>);

class NearbyClinicsScreen extends StatefulWidget {
  const NearbyClinicsScreen({
    super.key,
    this.location,
    this.repository,
    this.mapBuilder,
  });
  final PatientLocationController? location;
  final NearbyClinicsRepository? repository;
  final NearbyGoogleMapBuilder? mapBuilder;
  @override
  State<NearbyClinicsScreen> createState() => _NearbyClinicsScreenState();
}

class _NearbyClinicsScreenState extends State<NearbyClinicsScreen>
    with WidgetsBindingObserver {
  late final _location = widget.location ?? PatientLocationController();
  late final _repository =
      widget.repository ?? BackendNearbyClinicsRepository();
  late final _discovery = NearbyDiscoveryController(_location, _repository);
  bool _map = false, _opening = false;
  bool get ar => LocaleService().isArabic;
  String t(String en, String arabic) => ar ? arabic : en;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _discovery;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _discovery.setActive(false);
      _location.releasePosition();
    } else {
      _location.revalidatePermission();
      _discovery.setActive(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _discovery.dispose();
    if (widget.location == null) _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      _location,
      _discovery.paging,
      LocaleService(),
    ]),
    builder: (context, _) {
      final page = _discovery.paging, rows = page.items;
      return Scaffold(
        appBar: AppBar(title: Text(t('Nearby clinics', 'العيادات القريبة'))),
        body: !_discovery.allowed
            ? Center(
                child: Text(t('Sign in to continue.', 'سجّل الدخول للمتابعة.')),
              )
            : RefreshIndicator(
                onRefresh: _discovery.refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: 28 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  children: [
                    HomeLocationPanel(
                      controller: _location,
                      nearbySupported: _repository.supported,
                      showNearbyEntry: false,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            liveRegion: true,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _location.position != null
                                    ? t(
                                        'Near my current location',
                                        'بالقرب من موقعي الحالي',
                                      )
                                    : _location.locality != null
                                    ? t(
                                        'Browsing clinics in ${_location.locality!.city.nameEn}',
                                        'تصفح عيادات ${_location.locality!.city.nameAr}',
                                      )
                                    : t(
                                        'Choose where to explore',
                                        'اختر مكان البحث',
                                      ),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ),
                          SegmentedButton<bool>(
                            segments: [
                              ButtonSegment(
                                value: false,
                                icon: const Icon(Icons.list),
                                label: Text(t('List', 'قائمة')),
                              ),
                              ButtonSegment(
                                value: true,
                                icon: const Icon(Icons.map_outlined),
                                label: Text(
                                  widget.mapBuilder == null
                                      ? t('Map links', 'روابط الخرائط')
                                      : t('Map', 'خريطة'),
                                ),
                              ),
                            ],
                            selected: {_map},
                            onSelectionChanged: (s) =>
                                setState(() => _map = s.single),
                          ),
                          const SizedBox(height: 12),
                          if (_repository.supported &&
                              _location.position == null &&
                              _location.locality != null)
                            Text(
                              t(
                                'City results · distances require device location. The selected area is retained but is not a server filter.',
                                'نتائج المدينة · المسافات تتطلب موقع الجهاز. نحتفظ بالمنطقة المحددة دون ترشيح خادمي بها.',
                              ),
                            ),
                          if (!_repository.supported)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  t(
                                    'Nearby search is not available yet. The service must confirm approved clinic visibility before it can be enabled. Browse the city directory instead; no nearest distances are estimated.',
                                    'البحث عن الأقرب غير متاح حالياً. يجب أن تتحقق الخدمة من ظهور العيادات المعتمدة قبل تفعيله. تصفح دليل المدينة؛ لا نقدّر مسافات الأقرب.',
                                  ),
                                ),
                              ),
                            ),
                          AsyncActionButton(
                            label: t(
                              'Browse city directory',
                              'تصفح دليل المدينة',
                            ),
                            onPressed: (action) async => action.wait(
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClinicsListScreen(
                                    initialCity: _location.city,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_repository.supported && page.isLoading)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: LinearProgressIndicator(),
                            ),
                          if (_repository.supported &&
                              page.isLoaded &&
                              rows.isEmpty &&
                              page.error == null)
                            Text(
                              t(
                                'No eligible clinics were returned for this location. Choose another area or refresh.',
                                'لم تُرجع الخدمة عيادات متاحة لهذا الموقع. اختر منطقة أخرى أو حدّث.',
                              ),
                            ),
                          if (_map && rows.isNotEmpty) ...[
                            if (widget.mapBuilder != null)
                              SizedBox(
                                height: 260,
                                child: widget.mapBuilder!(
                                  context,
                                  rows
                                      .where((r) => r.branchLocation != null)
                                      .toList(growable: false),
                                ),
                              )
                            else
                              Text(
                                t(
                                  'Choose a confirmed location to open in Google Maps.',
                                  'اختر موقعاً مؤكداً لفتحه في خرائط Google.',
                                ),
                              ),
                            for (final row in rows.where(
                              (r) => r.branchLocation != null,
                            ))
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        ar
                                            ? row.clinic.nameAr
                                            : row.clinic.nameEn,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      if (_branchLabel(row).isNotEmpty)
                                        Text(_branchLabel(row)),
                                      if (_discovery
                                          .distanceLabel(row)
                                          .isNotEmpty)
                                        _distanceBadge(row),
                                      AsyncActionButton(
                                        label: t(
                                          'Open location in Google Maps',
                                          'فتح الموقع في خرائط Google',
                                        ),
                                        icon: Icons.directions_outlined,
                                        onPressed: (_) async {
                                          final p = row.branchLocation!;
                                          if (!await MapsLauncher.openVerifiedLocation(
                                            latitude: p.latitude,
                                            longitude: p.longitude,
                                          )) {
                                            throw StateError(
                                              t(
                                                'Directions unavailable',
                                                'تعذر فتح الاتجاهات',
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (rows.any((r) => r.branchLocation == null))
                              Text(
                                t(
                                  'Some returned locations have no confirmed map coordinates. Use the list to view those clinics.',
                                  'بعض المواقع لا تحتوي إحداثيات مؤكدة. اعرض هذه العيادات في القائمة.',
                                ),
                              ),
                          ],
                          if (!_map)
                            for (final row in rows)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    PatientClinicCard(
                                      clinic: row.clinic,
                                      distanceLabel: _discovery.distanceLabel(
                                        row,
                                      ),
                                      onTap: () async {
                                        if (_opening) return;
                                        _opening = true;
                                        try {
                                          await Navigator.push<void>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ClinicProfileScreen(
                                                    clinic: row.clinic,
                                                  ),
                                            ),
                                          );
                                        } finally {
                                          _opening = false;
                                        }
                                      },
                                    ),
                                    if (_branchLabel(row).isNotEmpty)
                                      Text(_branchLabel(row)),
                                    AsyncActionButton(
                                      label: t(
                                        'Request consultation',
                                        'طلب استشارة',
                                      ),
                                      onPressed: (action) async => action.wait(
                                        Navigator.push<void>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AppointmentRequestScreen(
                                                  clinic: row.clinic,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          if (_repository.supported && _discovery.canQuery)
                            PaginationFooter(
                              loading: page.isLoading || page.isLoadingMore,
                              hasMore: page.hasMore,
                              error: page.error,
                              onLoadMore: page.loadMore,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      );
    },
  );

  String _branchLabel(NearbyClinic row) {
    if (row.branchId == null) return '';
    final name = ar ? row.branchNameAr : row.branchNameEn;
    final address = ar ? row.branchAddressAr : row.branchAddressEn;
    return [
      name,
      address,
    ].whereType<String>().where((v) => v.trim().isNotEmpty).join(' · ');
  }

  Widget _distanceBadge(NearbyClinic row) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accentChampagne.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.goldText(context).withValues(alpha: .5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.near_me_outlined,
              size: 17,
              color: AppColors.goldText(context),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                _discovery.distanceLabel(row),
                style: TextStyle(
                  color: AppColors.text(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
