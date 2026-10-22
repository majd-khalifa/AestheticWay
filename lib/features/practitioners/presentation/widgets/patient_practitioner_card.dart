import 'package:aesthetic_way/core/widgets/patient_image.dart';
import '../../../../core/theme/patient_design.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/widgets/practitioner_badge.dart';
import '../../../../core/widgets/async_action_button.dart';
import '../../models/practitioner_model.dart';

/// Reference 05: full-height portrait alongside identity and consultation.
/// IntrinsicHeight measures only this small card, never the scrolling directory.
class PatientPractitionerCard extends StatelessWidget {
  const PatientPractitionerCard({
    super.key,
    required this.practitioner,
    required this.onTap,
    this.onInquiry,
    this.onInquiryAction,
  });
  final PractitionerModel practitioner;
  final VoidCallback onTap;
  final VoidCallback? onInquiry;
  final AsyncPatientAction? onInquiryAction;
  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final p = practitioner;
    final clinic = loc.isArabic
        ? p.clinicNameAr
        : (p.clinicNameEn ?? p.clinicNameAr);
    final specialty = loc.isArabic ? p.specialtyAr : p.specialtyEn;
    Widget action() => onInquiryAction != null
        ? AsyncActionButton(
            label: loc.tr('request_consultation'),
            loadingLabel: loc.isArabic
                ? 'جارٍ فتح الاستشارة'
                : 'Opening consultation',
            onPressed: onInquiryAction,
          )
        : OutlinedButton(
            onPressed: onInquiry ?? onTap,
            child: Text(
              onInquiry != null
                  ? loc.tr('request_consultation')
                  : (loc.isArabic
                        ? 'الملف المهني'
                        : 'View professional profile'),
            ),
          );
    Widget details() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PractitionerBadge(type: p.type, hasKnownType: p.hasKnownType),
        ),
        const SizedBox(height: 8),
        Text(
          loc.isArabic ? p.nameAr : p.nameEn,
          style: PatientDesign.heading(context, size: 21),
        ),
        if (specialty.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              specialty,
              style: TextStyle(
                color: AppColors.goldText(context),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        if (clinic.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              clinic,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: AppColors.subtext(context),
              ),
            ),
          ),
        const SizedBox(height: 8),
        action(),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow =
            constraints.maxWidth < 290 &&
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        return LuxuryCard(
          onTap: onTap,
          padding: const EdgeInsets.all(10),
          borderRadius: 18,
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PatientImage(
                      imageUrl: p.avatarUrl,
                      height: 200,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(height: 12),
                    details(),
                  ],
                )
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth - 32) * .39,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 204),
                          child: PatientImage(
                            imageUrl: p.avatarUrl,
                            height: 204,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: details()),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
