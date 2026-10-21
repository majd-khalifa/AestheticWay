import 'package:aesthetic_way/core/theme/patient_design.dart';
import '../../../../core/utils/entity_id.dart';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/features/treatments/data/treatments_repository.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';
import 'package:aesthetic_way/features/clinics/data/clinics_repository.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinic_profile_screen.dart';

/// Treatment / Procedure Detail Screen with full medical description & clinic booking lead
class TreatmentDetailScreen extends StatefulWidget {
  final TreatmentModel treatment;
  final TreatmentsRepository? treatmentsRepository;
  final ClinicsRepository? clinicsRepository;

  const TreatmentDetailScreen({
    super.key,
    required this.treatment,
    this.treatmentsRepository,
    this.clinicsRepository,
  });

  @override
  State<TreatmentDetailScreen> createState() => _TreatmentDetailScreenState();
}

class _TreatmentDetailScreenState extends State<TreatmentDetailScreen> {
  late final TreatmentsRepository _treatmentsRepository =
      widget.treatmentsRepository ?? TreatmentsRepository();
  late final ClinicsRepository _clinicsRepository =
      widget.clinicsRepository ?? ClinicsRepository();

  late TreatmentModel _treatment;
  List<ClinicModel> _availableClinics = [];
  bool _isLoading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _treatment = widget.treatment;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final detail = await _treatmentsRepository.getTreatmentDetail(
        widget.treatment.id,
      );
      if (!mounted) return;
      if (detail != null) setState(() => _treatment = detail);
      final clinicId = _treatment.clinicId;
      if (isEntityUuid(clinicId)) {
        final clinic = await _clinicsRepository.getClinicDetail(clinicId!);
        if (mounted) setState(() => _availableClinics = [clinic]);
      }
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
            preselectedTreatmentId: _treatment.id,
            preselectedServiceName: LocaleService().isArabic
                ? _treatment.nameAr
                : _treatment.nameEn,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PatientDesign(builder: _buildPatient);

  Widget _buildPatient(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);
    final primaryClinic = _availableClinics.firstOrNull;
    final clinicsToShow = _availableClinics;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        title: Text(
          loc.isArabic ? 'تفاصيل الإجراء' : 'Treatment details',
          style: AppTypography.screenTitle.copyWith(
            color: isDark
                ? AppColors.silverPrimary
                : AppColors.lightTextPrimary,
            fontSize: 15.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark
                ? AppColors.silverPrimary
                : AppColors.lightTextPrimary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Hero Cover Image
          LuxuryImage(
            imageUrl: _treatment.imageUrl,
            fallbackLogoUrl: _treatment.clinicLogoUrl,
            height: 200,
            width: double.infinity,
            borderRadius: BorderRadius.circular(18),
            placeholderIcon: Icons.medical_services_rounded,
            iconSize: 48,
          ),
          const SizedBox(height: 16),

          // Overview Card
          LuxuryCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentChampagne.withValues(
                      alpha: isDark ? 0.15 : 0.2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    loc.isArabic
                        ? _treatment.categoryAr
                        : _treatment.categoryEn,
                    style: TextStyle(
                      color: AppColors.goldText(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  loc.isArabic ? _treatment.nameAr : _treatment.nameEn,
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? AppColors.silverPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  (loc.isArabic
                          ? _treatment.descriptionAr
                          : _treatment.descriptionEn) ??
                      '',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 13,
                    color: AppColors.subtext(context),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Clinical Spec Parameters Card (Only render rows with live backend values)
          Builder(
            builder: (context) {
              final durationVal = _treatment.formattedDuration(loc.isArabic);
              final downtimeVal =
                  (loc.isArabic
                          ? _treatment.downtimeText
                          : (_treatment.downtimeTextEn ??
                                _treatment.downtimeText))
                      .trim();
              final targetAreaVal =
                  (loc.isArabic
                          ? _treatment.targetAreaAr
                          : (_treatment.targetAreaEn ??
                                _treatment.targetAreaAr))
                      .trim();
              final priceVal = _treatment.price != null && _treatment.price! > 0
                  ? '${_treatment.price!.toInt()} ${loc.tr("currency_aed")}'
                  : '';

              final rows = <Widget>[];
              if (durationVal.isNotEmpty) {
                rows.add(
                  _SpecRow(
                    icon: Icons.timer_outlined,
                    label: loc.tr('duration_label'),
                    value: durationVal,
                  ),
                );
              }
              if (priceVal.isNotEmpty) {
                if (rows.isNotEmpty) rows.add(const Divider(height: 20));
                rows.add(
                  _SpecRow(
                    icon: Icons.sell_outlined,
                    label: loc.isArabic
                        ? 'السعر الاسترشادي'
                        : 'Estimated Price',
                    value: priceVal,
                  ),
                );
              }
              if (downtimeVal.isNotEmpty) {
                if (rows.isNotEmpty) rows.add(const Divider(height: 20));
                rows.add(
                  _SpecRow(
                    icon: Icons.healing_outlined,
                    label: loc.tr('downtime_label'),
                    value: downtimeVal,
                  ),
                );
              }
              if (targetAreaVal.isNotEmpty) {
                if (rows.isNotEmpty) rows.add(const Divider(height: 20));
                rows.add(
                  _SpecRow(
                    icon: Icons.track_changes_outlined,
                    label: loc.tr('target_area_label'),
                    value: targetAreaVal,
                  ),
                );
              }

              if (rows.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: LuxuryCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: rows),
                ),
              );
            },
          ),

          // Available in Clinics Section
          Text(
            loc.isArabic
                ? 'العيادة الموفرة للإجراء'
                : 'Clinic providing this treatment',
            style: AppTypography.cardTitle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.accentChampagne,
                ),
              ),
            )
          else
            ...(clinicsToShow.map((clinic) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LuxuryCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LuxuryImage(
                          imageUrl: clinic.coverImageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          customPlaceholder: Container(
                            width: 50,
                            height: 50,
                            color: isDark
                                ? AppColors.cardSurfaceHover
                                : AppColors.lightCardSurfaceHover,
                            child: const Icon(
                              Icons.apartment_rounded,
                              color: AppColors.accentChampagne,
                            ),
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
                                color: isDark
                                    ? AppColors.silverPrimary
                                    : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${clinic.city} • ${loc.isArabic ? clinic.areaAr : clinic.areaEn}',
                              style: TextStyle(
                                color: AppColors.mutedText(context),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.accentChampagne,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            LuxuryPageRoute(
                              page: ClinicProfileScreen(clinic: clinic),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            })),

          const SizedBox(height: 16),

          if (_loadFailed || (!_isLoading && primaryClinic == null))
            TextButton.icon(
              onPressed: _loadDetails,
              icon: const Icon(Icons.sync),
              label: Text(
                loc.isArabic
                    ? 'العيادة غير متوفرة، أعد المحاولة'
                    : 'Clinic unavailable. Try again',
              ),
            ),
          // Primary Lead Action Button
          SilverButton(
            label: loc.tr('request_this_treatment'),
            icon: Icons.chat_bubble_outline,
            isFullWidth: true,
            height: 48,
            onPressed: primaryClinic == null
                ? null
                : () => _handleBookLead(context, primaryClinic),
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

  const _SpecRow({
    required this.icon,
    required this.label,
    required this.value,
  });

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
            color: isDark
                ? AppColors.silverPrimary
                : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}
