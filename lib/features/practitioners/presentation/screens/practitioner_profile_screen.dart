import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/practitioner_badge.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/data/mock_data.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinic_profile_screen.dart';

/// Practitioner Profile Screen (Doctors & Skin Experts)
class PractitionerProfileScreen extends StatelessWidget {
  final PractitionerModel practitioner;

  const PractitionerProfileScreen({super.key, required this.practitioner});

  Future<void> _handleBookLead(BuildContext context) async {
    final mockData = MockDataService();
    final clinic = mockData.getClinicById(practitioner.clinicId) ?? mockData.clinics.first;

    final auth = await GuestAuthGuard.requireAuth(
      context,
      reasonTitle: LocaleService().tr('request_with_doctor'),
      reasonSubtitle: LocaleService().isArabic
          ? 'سجّل دخولك برقم الهاتف لطلب استشارة مع الممارس'
          : 'Login with phone number to request a consultation lead with practitioner',
    );
    if (!auth) return;

    if (context.mounted) {
      Navigator.push(
        context,
        LuxuryPageRoute(
          page: AppointmentRequestScreen(
            clinic: clinic,
            preselectedPractitioner: practitioner,
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
    final clinic = mockData.getClinicById(practitioner.clinicId);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        title: Text(
          loc.isArabic ? practitioner.nameAr : practitioner.nameEn,
          style: AppTypography.screenTitle.copyWith(
            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
            fontSize: 16,
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
          // Practitioner Hero Header
          LuxuryCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    practitioner.avatarUrl,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 76,
                      height: 76,
                      color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                      child: const Icon(Icons.person_rounded, size: 36, color: AppColors.accentChampagne),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PractitionerBadge(type: practitioner.type),
                      const SizedBox(height: 6),
                      Text(
                        loc.isArabic ? practitioner.nameAr : practitioner.nameEn,
                        style: AppTypography.cardTitle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.isArabic ? practitioner.specialtyAr : practitioner.specialtyEn,
                        style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Practicing Clinic Link Card
          if (clinic != null)
            LuxuryCard(
              onTap: () {
                Navigator.push(
                  context,
                  LuxuryPageRoute(page: ClinicProfileScreen(clinic: clinic)),
                );
              },
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.apartment_rounded, color: AppColors.accentChampagne, size: 20),
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
                        const SizedBox(height: 2),
                        Text(
                          '${clinic.city} • ${loc.isArabic ? clinic.areaAr : clinic.areaEn}',
                          style: TextStyle(color: AppColors.mutedText(context), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.accentChampagne),
                ],
              ),
            ),
          const SizedBox(height: 14),

          // Professional Bio Card
          LuxuryCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.tr('about_doctor'),
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (loc.isArabic ? practitioner.aboutAr : practitioner.aboutEn) ?? '',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 12.5,
                    color: AppColors.mutedText(context),
                    height: 1.55,
                  ),
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.language_rounded, size: 16, color: AppColors.accentChampagne),
                    const SizedBox(width: 8),
                    Text(
                      '${loc.tr("languages_spoken")}: ${practitioner.languages.join(" • ")}',
                      style: TextStyle(color: AppColors.mutedText(context), fontSize: 11.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Key Clinical Procedures Card
          LuxuryCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.tr('procedures_title'),
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (loc.isArabic ? practitioner.procedures : (practitioner.proceduresEn ?? practitioner.procedures)).map((proc) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border(context), width: 0.8),
                      ),
                      child: Text(
                        proc,
                        style: TextStyle(
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Lead Consultation Action Button
          SilverButton(
            label: loc.tr('request_with_doctor'),
            icon: Icons.calendar_month_outlined,
            isFullWidth: true,
            height: 48,
            onPressed: () => _handleBookLead(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
