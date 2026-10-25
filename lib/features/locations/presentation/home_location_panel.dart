import 'nearby_clinics_screen.dart';
import '../../../core/widgets/async_action_button.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/app_locale.dart';
import '../services/patient_location_controller.dart';
import 'uae_location_picker.dart';

class HomeLocationPanel extends StatelessWidget {
  const HomeLocationPanel({
    super.key,
    required this.controller,
    this.nearbySupported = false,
    this.showNearbyEntry = true,
  });
  final PatientLocationController controller;
  final bool nearbySupported, showNearbyEntry;
  @override
  Widget build(BuildContext context) {
    final ar = LocaleService().isArabic;
    String t(String en, String arabic) => ar ? arabic : en;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t('Find care in your area', 'اكتشف العيادات في منطقتك'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              t(
                'Use foreground location or select an emirate and city. Approximate location is enough; it is not saved to your profile.',
                'استخدم الموقع أثناء الاستخدام أو اختر الإمارة والمدينة. يكفي الموقع التقريبي ولا يُحفظ في ملفك.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            UaeLocationField(
              value: controller.city,
              areaCode: controller.areaCode,
              onLocalityChanged: controller.selectLocality,
              onChanged: controller.selectCity,
            ),
            OutlinedButton.icon(
              key: const ValueKey('home-use-location'),
              onPressed: controller.busy ? null : controller.useDeviceLocation,
              icon: controller.busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                controller.busy
                    ? t('Locating…', 'جارٍ تحديد الموقع…')
                    : t('Use my location', 'استخدام موقعي'),
              ),
            ),
            if (controller.areaCode != null)
              Text(
                t(
                  'Showing city results; area filtering is not available yet.',
                  'ستُعرض نتائج المدينة؛ ترشيح المنطقة غير متاح بعد.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (showNearbyEntry)
              AsyncActionButton(
                label: t(
                  'Nearby clinics · map & list',
                  'العيادات القريبة · خريطة وقائمة',
                ),
                icon: Icons.map_outlined,
                onPressed: (action) async => action.wait(
                  Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => NearbyClinicsScreen(location: controller),
                    ),
                  ),
                ),
              ),
            Semantics(
              liveRegion: true,
              child: Text(switch (controller.state) {
                PatientLocationState.denied => t(
                  'Location permission was denied. Choose a city instead.',
                  'لم يُسمح بالموقع. اختر مدينة بدلاً منه.',
                ),
                PatientLocationState.deniedForever => t(
                  'Location permission is disabled in Settings. You can continue by choosing a city.',
                  'إذن الموقع معطّل في الإعدادات. يمكنك المتابعة باختيار مدينة.',
                ),
                PatientLocationState.disabled => t(
                  'Location services are off. Choose a city or enable them in device settings.',
                  'خدمات الموقع متوقفة. اختر مدينة أو فعّلها من إعدادات الجهاز.',
                ),
                PatientLocationState.timeout => t(
                  'Location timed out. Try again or choose a city.',
                  'انتهت مهلة تحديد الموقع. أعد المحاولة أو اختر مدينة.',
                ),
                PatientLocationState.outsideCoverage => t(
                  'Location is outside the supported UAE coverage area. Select a UAE city.',
                  'الموقع خارج نطاق التغطية الإماراتي المدعوم. اختر مدينة إماراتية.',
                ),
                PatientLocationState.unavailable => t(
                  'Location could not be determined. Choose a city.',
                  'تعذر تحديد الموقع. اختر مدينة.',
                ),
                PatientLocationState.ready when nearbySupported => t(
                  'Approximate location is ready.',
                  'الموقع التقريبي جاهز.',
                ),
                _ =>
                  nearbySupported
                      ? t('Location is optional.', 'استخدام الموقع اختياري.')
                      : t(
                          'Distance-ranked results are awaiting server support. Browse by city; no distances are estimated.',
                          'النتائج المرتبة حسب المسافة بانتظار دعم الخادم. تصفح حسب المدينة؛ لا نعرض مسافات تقديرية.',
                        ),
              }, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
