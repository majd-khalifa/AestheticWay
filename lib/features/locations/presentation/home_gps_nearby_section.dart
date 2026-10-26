import 'package:flutter/material.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/widgets/async_action_button.dart';
import '../../../core/widgets/lazy_tab_stack.dart';
import '../../clinics/models/clinic_model.dart';
import '../../clinics/presentation/widgets/patient_clinic_card.dart';
import '../data/nearby_clinics_repository.dart';
import '../services/nearby_discovery_controller.dart';
import '../services/patient_location_controller.dart';
import 'nearby_clinics_screen.dart';

/// GPS results never come from the city's Home feed. The full list retains
/// backend pagination; the Home preview shows the first five in server order.
class HomeGpsNearbySection extends StatefulWidget {
  const HomeGpsNearbySection({
    super.key,
    required this.location,
    required this.onClinicTap,
    this.repository,
  });
  final PatientLocationController location;
  final ValueChanged<ClinicModel> onClinicTap;
  final NearbyClinicsRepository? repository;
  @override
  State<HomeGpsNearbySection> createState() => _HomeGpsNearbySectionState();
}

class _HomeGpsNearbySectionState extends State<HomeGpsNearbySection> {
  late final _repository =
      widget.repository ?? BackendNearbyClinicsRepository();
  late final _discovery = NearbyDiscoveryController(
    widget.location,
    _repository,
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _discovery.setActive(
      TabActivity.isActive(context) &&
          (ModalRoute.isCurrentOf(context) ?? true),
    );
  }

  @override
  void dispose() {
    _discovery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _discovery,
    builder: (context, _) {
      final ar = LocaleService().isArabic, page = _discovery.paging;
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ar ? 'بالقرب من موقعي الحالي' : 'Near my current location',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (page.isLoading) const LinearProgressIndicator(),
            if (page.error != null) Text(page.error!),
            if (page.isLoaded && page.items.isEmpty && page.error == null)
              Text(
                ar
                    ? 'لا توجد عيادات متاحة ضمن النطاق.'
                    : 'No eligible clinics were returned within the radius.',
              ),
            if (page.error != null)
              TextButton(
                onPressed: _discovery.refresh,
                child: Text(ar ? 'إعادة المحاولة' : 'Retry'),
              ),
            if (page.items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final row in page.items.take(5))
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 12),
                          child: SizedBox(
                            width: (MediaQuery.sizeOf(context).width * .72)
                                .clamp(230, 330),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                PatientClinicCard(
                                  clinic: row.clinic,
                                  compact: true,
                                  distanceLabel: _discovery.distanceLabel(row),
                                  onTap: () => widget.onClinicTap(row.clinic),
                                ),
                                if (row.branchId != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      '${ar ? 'المسافة إلى الفرع الأقرب' : 'Distance to nearest branch'}${(ar ? row.branchNameAr : row.branchNameEn)?.isNotEmpty == true ? ': ${ar ? row.branchNameAr : row.branchNameEn}' : ''}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
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
            AsyncActionButton(
              label: ar
                  ? 'عرض جميع العيادات القريبة'
                  : 'View all nearby clinics',
              onPressed: (action) => action.wait(
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NearbyClinicsScreen(
                      location: widget.location,
                      repository: _repository,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
