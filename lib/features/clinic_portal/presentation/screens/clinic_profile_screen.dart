import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/theme/theme_service.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/tier_badge.dart';
import 'package:aesthetic_way/core/widgets/practitioner_badge.dart';
import 'package:aesthetic_way/core/utils/maps_launcher.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/login_screen.dart';

/// Clinic Tab 4: Clinic Profile, Google Maps Linking, Medical Team & Services Manager
class ClinicProfileScreen extends StatelessWidget {
  const ClinicProfileScreen({super.key});

  void _showAddPractitionerDialog(BuildContext context, LocaleService loc) {
    final nameController = TextEditingController();
    final specialtyController = TextEditingController();
    PractitionerType selectedType = PractitionerType.doctor;
    final isDark = AppColors.isDark(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDeep : AppColors.lightCardSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppColors.border(ctx), width: 0.8)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.mutedText(ctx).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.tr('clinic_add_practitioner'),
                    style: AppTypography.cardTitle.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: loc.tr('clinic_practitioner_name'),
                      filled: true,
                      fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.accentChampagne, width: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: specialtyController,
                    style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: loc.tr('clinic_practitioner_specialty'),
                      filled: true,
                      fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.accentChampagne, width: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PractitionerType>(
                    initialValue: selectedType,
                    dropdownColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                      ),
                    ),
                    items: PractitionerType.values.map((type) {
                      String label;
                      switch (type) {
                        case PractitionerType.doctor:
                          label = loc.tr('role_doctor');
                          break;
                        case PractitionerType.nurse:
                          label = loc.tr('role_nurse');
                          break;
                        case PractitionerType.licensedProfessional:
                          label = loc.tr('role_specialist');
                          break;
                      }
                      return DropdownMenuItem(
                        value: type,
                        child: Text(label, style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setModalState(() {
                          selectedType = v;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  SilverButton(
                    label: loc.tr('clinic_add_practitioner'),
                    icon: Icons.check,
                    isFullWidth: true,
                    height: 44,
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) return;
                      final p = PractitionerModel(
                        id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
                        nameAr: nameController.text.trim(),
                        nameEn: nameController.text.trim(),
                        type: selectedType,
                        specialtyAr: specialtyController.text.trim().isEmpty ? 'استشاري جلدية وتجميل' : specialtyController.text.trim(),
                        specialtyEn: specialtyController.text.trim().isEmpty ? 'Dermatology & Aesthetic Specialist' : specialtyController.text.trim(),
                        classificationAr: 'ممارس طبي معتمد',
                        classificationEn: 'Certified Practitioner',
                        licenseAuthority: 'Medical Board',
                        licenseNumber: 'LIC-P-${DateTime.now().millisecondsSinceEpoch % 100000}',
                        avatarUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=300&q=80',
                        yearsOfExperience: 10,
                        rating: 4.9,
                        reviewCount: 45,
                        languages: const ['العربية', 'English'],
                        clinicId: ClinicPortalService().activeClinic.id,
                        clinicNameAr: ClinicPortalService().activeClinic.nameAr,
                        clinicNameEn: ClinicPortalService().activeClinic.nameEn,
                        procedures: const ['استشارة تجميلية', 'علاجات الليزر والنضارة'],
                        proceduresEn: const ['Aesthetic Consultation', 'Laser & Glow Protocols'],
                        aboutAr: 'كادر طبي معتمد ذو كفاءة وخبرة واسعة.',
                        aboutEn: 'Certified practitioner with comprehensive clinical experience.',
                      );
                      ClinicPortalService().addPractitioner(p);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.tr('clinic_practitioner_saved')), backgroundColor: AppColors.accentChampagne),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddServiceDialog(BuildContext context, LocaleService loc) {
    final nameController = TextEditingController();
    final isDark = AppColors.isDark(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDeep : AppColors.lightCardSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.border(ctx), width: 0.8)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.mutedText(ctx).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                loc.tr('clinic_add_service'),
                style: AppTypography.cardTitle.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameController,
                style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: loc.tr('clinic_service_name'),
                  filled: true,
                  fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accentChampagne, width: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SilverButton(
                label: loc.tr('clinic_add_service'),
                icon: Icons.check,
                isFullWidth: true,
                height: 44,
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  final t = TreatmentModel(
                    id: 'treat-${DateTime.now().millisecondsSinceEpoch}',
                    nameAr: nameController.text.trim(),
                    nameEn: nameController.text.trim(),
                    categoryAr: 'علاجات تجميلية',
                    categoryEn: 'Aesthetic Treatments',
                    descriptionAr: 'إجراء علاجي متقدم لصحة ونضارة البشرة.',
                    descriptionEn: 'Advanced clinical treatment for optimal skin radiance.',
                    durationText: '30 دقيقة',
                    durationTextEn: '30 mins',
                    downtimeText: 'بدون فترة تعافي',
                    downtimeTextEn: 'Zero Downtime',
                    targetAreaAr: 'الوجه والرقبة',
                    targetAreaEn: 'Face & Neck',
                    clinicsCount: 1,
                    imageUrl: 'https://images.unsplash.com/photo-1512290900672-1f02e604ec22?auto=format&fit=crop&w=800&q=80',
                  );
                  ClinicPortalService().addTreatment(t);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.tr('clinic_service_saved')), backgroundColor: AppColors.accentChampagne),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final themeService = ThemeService();
    final clinicService = ClinicPortalService();
    final isDark = AppColors.isDark(context);
    final clinic = clinicService.activeClinic;

    return ListenableBuilder(
      listenable: Listenable.merge([loc, themeService, clinicService]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Text(
              loc.tr('clinic_nav_profile'),
              style: AppTypography.screenTitle.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Clinic Overview Card
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            clinic.coverImageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 60,
                              height: 60,
                              color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                              child: const Icon(Icons.apartment_rounded, color: AppColors.accentChampagne),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.isArabic ? clinic.nameAr : clinic.nameEn,
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${clinic.city} • ${loc.isArabic ? clinic.areaAr : clinic.areaEn}',
                                style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                              ),
                              const SizedBox(height: 6),
                              TierBadge(tier: clinic.subscriptionTier),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      loc.isArabic ? clinic.descriptionAr : clinic.descriptionEn,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.mutedText(context),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Google Maps Location Card
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.map_outlined, color: AppColors.accentChampagne, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          loc.tr('clinic_maps_config'),
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loc.isArabic ? clinic.addressAr : clinic.addressEn,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 12.5,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SilverButton(
                      label: loc.tr('open_in_maps'),
                      icon: Icons.directions_outlined,
                      height: 38,
                      onPressed: () {
                        MapsLauncher.openDirections(
                          latitude: clinic.latitude,
                          longitude: clinic.longitude,
                          destinationTitle: loc.isArabic ? clinic.nameAr : clinic.nameEn,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Medical Staff Section
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.tr('clinic_team_title'),
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentChampagne, size: 20),
                          tooltip: loc.tr('clinic_add_practitioner'),
                          onPressed: () => _showAddPractitionerDialog(context, loc),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...clinicService.clinicPractitioners.map((p) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                p.avatarUrl,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 36,
                                  height: 36,
                                  color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                                  child: const Icon(Icons.person, size: 20, color: AppColors.accentChampagne),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.isArabic ? p.nameAr : p.nameEn,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    loc.isArabic ? p.specialtyAr : p.specialtyEn,
                                    style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            PractitionerBadge(type: p.type, showIcon: false),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Treatments / Services Section
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.tr('clinic_services_title'),
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentChampagne, size: 20),
                          tooltip: loc.tr('clinic_add_service'),
                          onPressed: () => _showAddServiceDialog(context, loc),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...clinicService.clinicTreatments.map((t) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.spa_outlined, size: 16, color: AppColors.accentChampagne),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                loc.isArabic ? t.nameAr : t.nameEn,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                            Text(
                              loc.isArabic ? t.durationText : (t.durationTextEn ?? t.durationText),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.accentChampagne,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Theme Switcher Tile
              LuxuryCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      themeService.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                      color: AppColors.accentChampagne,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.tr('theme_title'),
                        style: TextStyle(
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DropdownButton<ThemeMode>(
                      value: themeService.themeMode,
                      dropdownColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text(loc.tr('theme_dark'), style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text(loc.tr('theme_light'), style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text(loc.tr('theme_system'), style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) themeService.setThemeMode(mode);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Language Switcher Tile
              LuxuryCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.language_rounded, color: AppColors.accentChampagne),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.tr('app_language'),
                        style: TextStyle(
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => loc.toggleLanguage(),
                      child: Text(
                        loc.tr('switch_language'),
                        style: const TextStyle(color: AppColors.accentChampagne, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Logout Clinic Portal Button
              SilverButton(
                label: loc.tr('clinic_logout'),
                icon: Icons.logout_rounded,
                isFullWidth: true,
                height: 46,
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}
