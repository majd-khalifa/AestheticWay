import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../clinics/models/clinic_model.dart';
import '../../../clinics/presentation/widgets/patient_clinic_card.dart';

/// Nearby Verified Clinics Section with Breathable Luxury Cards & Dual-Theme Adaptation
class NearbyClinicsSection extends StatelessWidget {
  final List<ClinicModel> clinics;
  final ValueChanged<ClinicModel> onClinicTap;
  final ValueChanged<ClinicModel> onRequestTap;
  final ValueChanged<ClinicModel> onContactTap;

  const NearbyClinicsSection({
    super.key,
    required this.clinics,
    required this.onClinicTap,
    required this.onRequestTap,
    required this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    if (clinics.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loc.isArabic ? 'اكتشف العيادات' : 'Discover clinics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (final clinic in clinics)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PatientClinicCard(
                clinic: clinic,
                onTap: () => onClinicTap(clinic),
                onRequest: () => onRequestTap(clinic),
                onContact: () => onContactTap(clinic),
              ),
            ),
        ],
      ),
    );
  }
}
