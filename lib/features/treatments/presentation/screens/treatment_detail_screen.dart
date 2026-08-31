import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/widgets/before_after_preview.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/data/mock_data.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinic_profile_screen.dart';

/// Treatment / Procedure Detail Screen with full medical description & clinic booking lead
class TreatmentDetailScreen extends StatelessWidget {
  final TreatmentModel treatment;

  const TreatmentDetailScreen({super.key, required this.treatment});

  Future<void> _handleBookLead(BuildContext context, ClinicModel clinic) async {
    final auth = await GuestAuthGuard.requireAuth(
      context,
      reasonTitle: LocaleService().tr('request_this_treatment'),
      reasonSubtitle: LocaleService().isArabic
          ? 'سجّل دخولك برقم الهاتف لإرسال طلب استشارة لهذا الإجراء'
          : 'Login with phone number to submit your consultation request',
    );
    if (!auth) return;

    if (context.mounted) {
      Navigator.push(
        context,
        LuxuryPageRoute(
          page: AppointmentRequestScreen(
            clinic: clinic,
            preselectedServiceName: LocaleService().isArabic ? treatment.nameAr : treatment.nameEn,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final mockData = MockDataService();
    final isDark = AppColors.isDark(context);

    // Associated clinics providing this treatment
    final availableClinics = mockData.clinics.where((c) => c.treatmentIds.contains(treatment.id)).toList();
    final fallbackClinic = availableClinics.isNotEmpty ? availableClinics.first : mockData.clinics.first;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        title: Text(
          loc.isArabic ? treatment.nameAr : treatment.nameEn,
          style: AppTypography.screenTitle.copyWith(
            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
            fontSize: 15.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Hero Cover Image
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              treatment.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 200,
                color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                child: const Center(
                  child: Icon(Icons.medical_services_rounded, color: AppColors.accentChampagne, size: 48),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Overview Card
          LuxuryCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.15 : 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    loc.isArabic ? treatment.categoryAr : treatment.categoryEn,
                    style: const TextStyle(
                      color: AppColors.accentChampagne,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  loc.isArabic ? treatment.nameAr : treatment.nameEn,
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  (loc.isArabic ? treatment.descriptionAr : treatment.descriptionEn) ?? '',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 13,
                    color: AppColors.mutedText(context),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Clinical Spec Parameters Card
          LuxuryCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _SpecRow(
                  icon: Icons.timer_outlined,
                  label: loc.tr('duration_label'),
                  value: (loc.isArabic ? treatment.durationText : (treatment.durationTextEn ?? treatment.durationText)),
                ),
                const Divider(height: 20),
                _SpecRow(
                  icon: Icons.healing_outlined,
                  label: loc.tr('downtime_label'),
                  value: (loc.isArabic ? treatment.downtimeText : (treatment.downtimeTextEn ?? treatment.downtimeText)),
                ),
                const Divider(height: 20),
                _SpecRow(
                  icon: Icons.track_changes_outlined,
                  label: loc.tr('target_area_label'),
                  value: (loc.isArabic ? treatment.targetAreaAr : (treatment.targetAreaEn ?? treatment.targetAreaAr)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Before & After Clinical Results Showcase
          BeforeAfterPreview(
            beforeImageUrl: 'https://images.unsplash.com/photo-1512290900672-1f02e604ec22?auto=format&fit=crop&w=600&q=80',
            afterImageUrl: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=600&q=80',
            titleAr: 'نتائج سريرية تجريبية للإجراء',
            titleEn: 'Sample Clinical Outcomes',
            subtitleAr: 'بعد جلستين',
            subtitleEn: 'After 2 sessions',
          ),
          const SizedBox(height: 16),

          // Available in Clinics Section
          Text(
            loc.isArabic ? 'العيادات المعتمدة الموفرة للإجراء' : 'Accredited Clinics Providing this Procedure',
            style: AppTypography.cardTitle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...((availableClinics.isNotEmpty ? availableClinics : [fallbackClinic]).map((clinic) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LuxuryCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        clinic.coverImageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 50,
                          height: 50,
                          color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                          child: const Icon(Icons.apartment_rounded, color: AppColors.accentChampagne),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.isArabic ? clinic.nameAr : clinic.nameEn,
                            style: TextStyle(
                              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${clinic.city} • ${loc.isArabic ? clinic.areaAr : clinic.areaEn}',
                            style: TextStyle(color: AppColors.mutedText(context), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.accentChampagne),
                      onPressed: () {
                        Navigator.push(
                          context,
                          LuxuryPageRoute(page: ClinicProfileScreen(clinic: clinic)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          })),

          const SizedBox(height: 16),

          // Primary Lead Action Button
          SilverButton(
            label: loc.tr('request_this_treatment'),
            icon: Icons.calendar_month_outlined,
            isFullWidth: true,
            height: 48,
            onPressed: () => _handleBookLead(context, fallbackClinic),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SpecRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accentChampagne),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: AppColors.mutedText(context), fontSize: 12.5),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}
