import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/practitioner_badge.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/features/clinics/data/clinics_repository.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/practitioners/data/practitioners_repository.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinic_profile_screen.dart';

/// Practitioner Profile Screen (Doctors & Skin Experts) — Live API (/api/v1/practitioners/{uuid}/)
class PractitionerProfileScreen extends StatefulWidget {
  final PractitionerModel practitioner;
  final PractitionersRepository? practitionersRepository;
  final ClinicsRepository? clinicsRepository;

  const PractitionerProfileScreen({
    super.key,
    required this.practitioner,
    this.practitionersRepository,
    this.clinicsRepository,
  });

  @override
  State<PractitionerProfileScreen> createState() => _PractitionerProfileScreenState();
}

class _PractitionerProfileScreenState extends State<PractitionerProfileScreen> {
  late PractitionerModel _practitioner;
  ClinicModel? _clinic;
  bool _isLoadingClinic = false;

  @override
  void initState() {
    super.initState();
    _practitioner = widget.practitioner;
    _loadLiveDetails();
  }

  Future<void> _loadLiveDetails() async {
    final practRepo = widget.practitionersRepository ?? PractitionersRepository();
    final clinicsRepo = widget.clinicsRepository ?? ClinicsRepository();

    if (_practitioner.id.trim().isNotEmpty) {
      try {
        final fresh = await practRepo.getPractitionerDetail(_practitioner.id);
        if (mounted) {
          setState(() {
            _practitioner = fresh;
          });
        }
      } catch (_) {}
    }

    if (_practitioner.clinicId.trim().isNotEmpty) {
      if (mounted) {
        setState(() => _isLoadingClinic = true);
      }
      try {
        final clinic = await clinicsRepo.getClinicDetail(_practitioner.clinicId);
        if (mounted) {
          setState(() {
            _clinic = clinic;
            _isLoadingClinic = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isLoadingClinic = false);
        }
      }
    }
  }

  ClinicModel _buildFallbackClinic() {
    return ClinicModel(
      id: _practitioner.clinicId.isNotEmpty ? _practitioner.clinicId : 'clinic-id',
      nameAr: _practitioner.clinicNameAr.isNotEmpty
          ? _practitioner.clinicNameAr
          : (_practitioner.clinicNameEn ?? ''),
      nameEn: _practitioner.clinicNameEn ?? _practitioner.clinicNameAr,
      descriptionAr: '',
      descriptionEn: '',
      coverImageUrl: _practitioner.avatarUrl,
      galleryImages: const [],
      logoUrl: _practitioner.avatarUrl,
      rating: 4.9,
      reviewCount: 0,
      subscriptionTier: SubscriptionTier.basic,
      licenseAuthority: '',
      licenseNumber: '',
      city: 'Dubai',
      areaAr: 'دبي',
      areaEn: 'Dubai',
      addressAr: 'دبي',
      addressEn: 'Dubai',
      distanceKm: 0,
      mainPhone: '+971500000000',
      receptionPhone: '+971500000000',
      whatsapp: '+971500000000',
      latitude: 25.2048,
      longitude: 55.2708,
      workingHoursAr: '10:00 ص - 9:00 م',
      workingHoursEn: '10:00 AM - 9:00 PM',
      branches: const [],
      practitionerIds: [_practitioner.id],
      treatmentIds: const [],
      featuredOffers: const [],
    );
  }

  Future<void> _handleBookLead(BuildContext context) async {
    final auth = await GuestAuthGuard.requireAuth(
      context,
      reasonTitle: LocaleService().tr('request_with_doctor'),
      reasonSubtitle: LocaleService().isArabic
          ? 'سجّل دخولك برقم الهاتف لطلب استشارة مع الممارس'
          : 'Login with phone number to request a consultation lead with practitioner',
    );
    if (!auth || !context.mounted) return;

    final targetClinic = _clinic ?? _buildFallbackClinic();
    Navigator.push(
      context,
      LuxuryPageRoute(
        page: AppointmentRequestScreen(
          clinic: targetClinic,
          preselectedPractitioner: _practitioner,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);
    final clinicName = loc.isArabic
        ? (_clinic?.nameAr.isNotEmpty == true ? _clinic!.nameAr : _practitioner.clinicNameAr)
        : (_clinic?.nameEn.isNotEmpty == true ? _clinic!.nameEn : (_practitioner.clinicNameEn ?? _practitioner.clinicNameAr));

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        title: Text(
          loc.isArabic ? _practitioner.nameAr : _practitioner.nameEn,
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
          // Practitioner Hero Header (No license numbers shown per client rule)
          LuxuryCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _practitioner.avatarUrl,
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
                      PractitionerBadge(type: _practitioner.type),
                      const SizedBox(height: 6),
                      Text(
                        loc.isArabic ? _practitioner.nameAr : _practitioner.nameEn,
                        style: AppTypography.cardTitle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.isArabic ? _practitioner.specialtyAr : _practitioner.specialtyEn,
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
          if (clinicName.isNotEmpty)
            LuxuryCard(
              onTap: () {
                final target = _clinic ?? _buildFallbackClinic();
                Navigator.push(
                  context,
                  LuxuryPageRoute(page: ClinicProfileScreen(clinic: target)),
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
                          clinicName,
                          style: TextStyle(
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (_clinic != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${_clinic!.city} • ${loc.isArabic ? _clinic!.areaAr : _clinic!.areaEn}',
                            style: TextStyle(color: AppColors.mutedText(context), fontSize: 11),
                          ),
                        ] else if (_isLoadingClinic) ...[
                          const SizedBox(height: 2),
                          Text(
                            loc.isArabic ? 'جاري تحميل بيانات العيادة...' : 'Loading clinic details...',
                            style: TextStyle(color: AppColors.mutedText(context), fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.mutedText(context)),
                ],
              ),
            ),
          const SizedBox(height: 14),

          // About / Bio Section
          if ((loc.isArabic ? _practitioner.aboutAr : (_practitioner.aboutEn ?? _practitioner.aboutAr)).isNotEmpty) ...[
            LuxuryCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.tr('about_doctor_title'),
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.isArabic ? _practitioner.aboutAr : (_practitioner.aboutEn ?? _practitioner.aboutAr),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.mutedText(context),
                      height: 1.6,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Performed Procedures / Treatments
          if (_practitioner.procedures.isNotEmpty) ...[
            LuxuryCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.tr('performed_procedures_title'),
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (loc.isArabic
                            ? _practitioner.procedures
                            : (_practitioner.proceduresEn ?? _practitioner.procedures))
                        .map((proc) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border(context)),
                              ),
                              child: Text(
                                proc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.silverSecondary : AppColors.lightTextPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Lead Request CTA
          SilverButton(
            label: loc.tr('request_with_doctor'),
            icon: Icons.calendar_today_outlined,
            isFullWidth: true,
            onPressed: () => _handleBookLead(context),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
