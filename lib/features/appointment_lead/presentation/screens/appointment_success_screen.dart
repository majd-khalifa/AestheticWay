import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/app_brand_logo.dart';
import 'package:aesthetic_way/core/utils/maps_launcher.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';

/// Appointment Request Success Screen (Strict Frozen Copy & Dual-Theme Luxury Visual Finish)
class AppointmentSuccessScreen extends StatelessWidget {
  final AppointmentRequestModel request;
  final ClinicModel clinic;

  const AppointmentSuccessScreen({
    super.key,
    required this.request,
    required this.clinic,
  });

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);
    final clinicName = loc.isArabic ? clinic.nameAr : clinic.nameEn;
    final branchName = loc.isArabic ? request.branchNameAr : (request.branchNameEn ?? request.branchNameAr);
    final serviceName = loc.isArabic ? request.serviceNameAr : (request.serviceNameEn ?? request.serviceNameAr);
    final practitionerName = loc.isArabic
        ? request.practitionerNameAr
        : (request.practitionerNameEn ?? request.practitionerNameAr);
    final timeWindowLabel = loc.isArabic
        ? request.preferredTimeWindow.labelAr
        : request.preferredTimeWindow.labelEn;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: ListenableBuilder(
        listenable: loc,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: AppColors.bg(context),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // Success Animated Platinum Badge
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.primaryButtonFill : AppColors.primaryButtonFillLight,
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? AppColors.silverPrimary.withValues(alpha: 0.25)
                                  : Colors.black.withValues(alpha: 0.12),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 42,
                            color: isDark ? AppColors.backgroundDeep : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Official Brand Logo (Prominent Auth/Splash Standard Sizing)
                    const Center(
                      child: AppBrandLogo.auth(),
                    ),
                    const SizedBox(height: 16),

                    // Success Heading
                    Center(
                      child: Text(
                        loc.tr('lead_success_title'),
                        style: AppTypography.heroTitle.copyWith(
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // MANDATORY STRICT BODY WORDING (Frozen Rule)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.35 : 0.6),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'تم إرسال طلبك وستتواصل العيادة معك',
                            style: AppTypography.cardTitle.copyWith(
                              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (!loc.isArabic) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Your request has been sent and the clinic will contact you',
                              style: AppTypography.cardTitle.copyWith(
                                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            loc.isArabic
                                ? 'تم إرسال طلبك بنجاح إلى $clinicName. سيقوم فريق الاستقبال في العيادة بالتواصل معك قريباً عبر الهاتف أو الواتساب لمتابعة التفاصيل.'
                                : 'Your inquiry lead has been sent to $clinicName. The clinic reception will contact you shortly via phone or WhatsApp to assist you.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                              height: 1.5,
                              fontSize: 12.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lead Request Summary Card
                    LuxuryCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                loc.tr('lead_summary_title'),
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: AppColors.accentChampagne.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.accentChampagne.withValues(alpha: 0.6),
                                    width: 0.7,
                                  ),
                                ),
                                child: Text(
                                  request.referenceCode,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.accentChampagne,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(),
                          const SizedBox(height: 8),
                          _SummaryRow(label: loc.tr('clinic_label'), value: clinicName),
                          if (request.leadType != 'product' && branchName.trim().isNotEmpty)
                            _SummaryRow(label: loc.tr('branch_label'), value: branchName),
                          _SummaryRow(
                            label: request.leadType == 'product'
                                ? (loc.isArabic ? 'المنتج:' : 'Product:')
                                : loc.tr('service_label'),
                            value: serviceName,
                          ),
                          if (request.leadType != 'product' && practitionerName != null)
                            _SummaryRow(label: loc.tr('practitioner_label'), value: practitionerName),
                          if (request.leadType != 'product') ...[
                            _SummaryRow(
                              label: loc.tr('date_label'),
                              value: DateFormat('yyyy/MM/dd').format(request.preferredDate),
                            ),
                            _SummaryRow(
                              label: loc.tr('period_label'),
                              value: timeWindowLabel,
                            ),
                          ],
                          _SummaryRow(label: loc.tr('patient_label'), value: request.patientFullName),
                          _SummaryRow(label: loc.tr('phone_label'), value: request.patientPhone),
                          if (request.notes != null && request.notes!.trim().isNotEmpty)
                            _SummaryRow(
                              label: loc.isArabic ? 'الملاحظات:' : 'Notes:',
                              value: request.notes!.trim(),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons: Open Google Maps & Return Home
                    OutlinedButton.icon(
                      onPressed: () {
                        MapsLauncher.openMapLocation(
                          latitude: clinic.latitude,
                          longitude: clinic.longitude,
                          placeId: clinic.googlePlaceId,
                          placeName: loc.isArabic ? clinic.nameAr : clinic.nameEn,
                        );
                      },
                      icon: Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: isDark ? AppColors.silverSecondary : AppColors.lightTextPrimary,
                      ),
                      label: Text(
                        loc.tr('open_maps_btn'),
                        style: AppTypography.button.copyWith(
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border(context), width: 0.8),
                        backgroundColor: AppColors.surface(context),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    SilverButton(
                      label: loc.tr('back_home'),
                      icon: Icons.home_outlined,
                      isFullWidth: true,
                      height: 46,
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
