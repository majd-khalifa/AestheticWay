import 'package:flutter/material.dart';
import '../../../../core/network/api_exception.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/clinic_portal/data/models/clinic_setup_checklist_model.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_practitioners_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_treatments_screen.dart';

/// Collapsible luxury setup & onboarding checklist card for Clinic Portal
class ClinicSetupChecklistCard extends StatefulWidget {
  final ClinicModel clinic;
  final ClinicSetupChecklistModel? checklist;
  final VoidCallback? onNavigateToProfile;

  const ClinicSetupChecklistCard({
    super.key,
    required this.clinic,
    this.checklist,
    this.onNavigateToProfile,
  });

  @override
  State<ClinicSetupChecklistCard> createState() =>
      _ClinicSetupChecklistCardState();
}

class _ClinicSetupChecklistCardState extends State<ClinicSetupChecklistCard> {
  bool _isExpanded = true;
  bool _isSubmitting = false;
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);
    final clinicService = ClinicPortalService();

    final setupStatus =
        widget.checklist?.setupStatus ?? widget.clinic.setupStatus;
    final isSubmitted = setupStatus == 'submitted';
    final isApproved = setupStatus == 'approved';
    final isRejected = setupStatus == 'rejected';
    final progress =
        widget.checklist?.progressPercentage ??
        _computeFallbackProgress(clinicService);
    final isReady =
        (widget.checklist?.isReadyForReview == true) &&
        (setupStatus == 'draft' || isRejected);

    return LuxuryCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSubmitted
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : AppColors.accentChampagne.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSubmitted
                        ? Icons.verified_outlined
                        : Icons.assignment_turned_in_rounded,
                    color: isSubmitted
                        ? const Color(0xFF10B981)
                        : AppColors.accentChampagne,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.isArabic
                            ? 'إعداد ملف العيادة'
                            : 'Clinic Profile Setup',
                        style: AppTypography.cardTitle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.silverPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isApproved
                            ? (loc.isArabic
                                  ? 'وافقت المنصة على الملف'
                                  : 'Profile approved by platform')
                            : isRejected
                            ? (loc.isArabic
                                  ? 'يحتاج الملف إلى تعديلات — راجع التفاصيل'
                                  : 'Profile changes requested — review details')
                            : isSubmitted
                            ? (loc.isArabic
                                  ? 'قيد مراجعة المنصة'
                                  : 'Under Platform Review')
                            : (loc.isArabic
                                  ? 'أكمل المتطلبات لنشر خدمات العيادة'
                                  : 'Complete items to publish clinic catalog'),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.mutedText(context),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSubmitted
                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                        : (isReady
                              ? AppColors.accentChampagne.withValues(alpha: 0.2)
                              : (isDark
                                    ? AppColors.cardSurfaceHover
                                    : AppColors.lightCardSurfaceHover)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSubmitted
                          ? const Color(0xFF10B981)
                          : (isReady
                                ? AppColors.accentChampagne
                                : AppColors.border(context)),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isApproved
                        ? (loc.isArabic ? 'مقبول' : 'Approved')
                        : isSubmitted
                        ? (loc.isArabic ? 'قيد المراجعة' : 'Under Review')
                        : isRejected
                        ? (loc.isArabic ? 'مرفوض' : 'Rejected')
                        : '$progress%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSubmitted
                          ? const Color(0xFF10B981)
                          : (isReady
                                ? AppColors.goldText(context)
                                : (isDark
                                      ? AppColors.silverPrimary
                                      : AppColors.lightTextPrimary)),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.mutedText(context),
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress / 100.0,
              minHeight: 6,
              backgroundColor: isDark
                  ? AppColors.cardSurfaceHover
                  : AppColors.lightCardSurfaceHover,
              valueColor: AlwaysStoppedAnimation<Color>(
                isSubmitted
                    ? const Color(0xFF10B981)
                    : AppColors.accentChampagne,
              ),
            ),
          ),

          // Expandable Checklist Content
          if (_isExpanded) ...[
            const SizedBox(height: 14),
            _buildChecklistRows(context, loc, clinicService),
            const SizedBox(height: 14),

            if (isRejected)
              _ReviewFeedback(
                ar: loc.isArabic,
                reason:
                    widget.checklist?.setupRejectionReason.isNotEmpty == true
                    ? widget.checklist!.setupRejectionReason
                    : widget.clinic.setupRejectionReason,
              ),
            if (isApproved)
              Text(
                loc.isArabic
                    ? 'وافقت المنصة على الملف. تفعيل الحساب والظهور العام يخضعان لحالتهما المنفصلة.'
                    : 'Profile approved by the platform. Account activation and public visibility retain their separate status.',
              ),
            TextButton.icon(
              onPressed: _isSubmitting || _isRefreshing
                  ? null
                  : () async {
                      setState(() => _isRefreshing = true);
                      try {
                        await clinicService.refreshClinicProfile();
                        await clinicService.loadSetupChecklist();
                      } catch (_) {
                        if (context.mounted) {
                          showAppSnackBar(
                            context,
                            loc.isArabic
                                ? 'تعذر تحديث حالة الملف. حاول مجدداً.'
                                : 'Could not refresh profile status. Try again.',
                            type: AppSnackBarType.error,
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isRefreshing = false);
                      }
                    },
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(
                loc.isArabic ? 'تحديث حالة المراجعة' : 'Refresh review status',
              ),
            ),
            // Already approved/submitted profiles are not resubmitted.
            if (isSubmitted)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.hourglass_top_rounded,
                      color: Color(0xFF10B981),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.isArabic
                            ? 'تم تقديم الملف — بانتظار اعتماد الإدارة'
                            : 'Profile Submitted — Awaiting Approval',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (!isApproved)
              SilverButton(
                label: _isSubmitting
                    ? (loc.isArabic ? 'جاري الإرسال...' : 'Submitting...')
                    : (loc.isArabic
                          ? 'إرسال ملف العيادة للمراجعة'
                          : 'Submit Clinic Profile for Review'),
                icon: Icons.send_rounded,
                height: 42,
                onPressed: (isReady && !_isSubmitting && !_isRefreshing)
                    ? () async {
                        setState(() => _isSubmitting = true);
                        try {
                          await clinicService.submitProfileForReview();
                          if (context.mounted) {
                            showAppSnackBar(
                              context,
                              loc.isArabic
                                  ? 'تم إرسال ملف العيادة لمراجعة المنصة'
                                  : 'Clinic profile submitted for platform review',
                              type: AppSnackBarType.success,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            showAppSnackBar(
                              context,
                              e.toString().replaceAll('Exception: ', ''),
                              type: AppSnackBarType.error,
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isSubmitting = false);
                        }
                      }
                    : null,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistRows(
    BuildContext context,
    LocaleService loc,
    ClinicPortalService clinicService,
  ) {
    if (widget.checklist != null && widget.checklist!.items.isNotEmpty) {
      return Column(
        children: widget.checklist!.items.map((item) {
          VoidCallback? action;
          String actionLabel = loc.isArabic ? 'إدارة' : 'Manage';
          if (item.key == 'branding' ||
              item.key == 'details' ||
              item.key == 'branch') {
            action = widget.onNavigateToProfile;
            actionLabel = loc.isArabic
                ? (item.isCompleted ? 'تعديل' : 'إكمال')
                : (item.isCompleted ? 'Edit' : 'Setup');
          } else if (item.key == 'practitioners') {
            action = () {
              Navigator.push(
                context,
                LuxuryPageRoute(page: const ClinicPractitionersScreen()),
              );
            };
            actionLabel = loc.isArabic ? '+ إضافة' : '+ Add';
          } else if (item.key == 'treatments') {
            action = () {
              Navigator.push(
                context,
                LuxuryPageRoute(page: const ClinicTreatmentsScreen()),
              );
            };
            actionLabel = loc.isArabic ? '+ إضافة' : '+ Add';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ChecklistTile(
              title: item.key == 'practitioners'
                  ? (loc.isArabic
                        ? 'إضافة ممارس واحد على الأقل'
                        : 'At Least One Practitioner')
                  : (loc.isArabic ? item.titleAr : item.titleEn),
              isDone: item.isCompleted,
              actionLabel: actionLabel,
              onAction: action,
            ),
          );
        }).toList(),
      );
    }

    final hasBranding =
        widget.clinic.logoUrl.isNotEmpty ||
        widget.clinic.coverImageUrl.isNotEmpty;
    final hasDetails =
        widget.clinic.descriptionAr.isNotEmpty ||
        widget.clinic.descriptionEn.isNotEmpty ||
        widget.clinic.nameEn.isNotEmpty;
    final hasBranch =
        clinicService.clinicBranches.isNotEmpty ||
        widget.clinic.branches.isNotEmpty ||
        widget.clinic.hasMapLocation;
    final hasPractitioner =
        clinicService.clinicPractitioners.isNotEmpty ||
        clinicService.activePractitionersCount > 0;
    final hasTreatment =
        clinicService.clinicTreatments.isNotEmpty ||
        clinicService.activeTreatmentsCount > 0;

    return Column(
      children: [
        _ChecklistTile(
          title: loc.isArabic
              ? 'الهوية البصرية والوصف التعريفي'
              : 'Clinic Branding & Bio Details',
          isDone: hasBranding && hasDetails,
          actionLabel: loc.isArabic ? 'تعديل' : 'Edit',
          onAction: widget.onNavigateToProfile,
        ),
        const SizedBox(height: 8),
        _ChecklistTile(
          title: loc.isArabic
              ? 'الفرع الرئيسي وموقع الخريطة'
              : 'Main Branch Location & Map',
          isDone: hasBranch,
          actionLabel: loc.isArabic ? 'إدارة' : 'Manage',
          onAction: widget.onNavigateToProfile,
        ),
        const SizedBox(height: 8),
        _ChecklistTile(
          title: loc.isArabic
              ? 'إضافة ممارس واحد على الأقل'
              : 'At Least One Practitioner',
          isDone: hasPractitioner,
          actionLabel: loc.isArabic ? '+ إضافة' : '+ Add',
          onAction: () {
            Navigator.push(
              context,
              LuxuryPageRoute(page: const ClinicPractitionersScreen()),
            );
          },
        ),
        const SizedBox(height: 8),
        _ChecklistTile(
          title: loc.isArabic
              ? 'إضافة خدمة أو علاج تجميلي واحد على الأقل'
              : 'At least 1 Treatment Service',
          isDone: hasTreatment,
          actionLabel: loc.isArabic ? '+ إضافة' : '+ Add',
          onAction: () {
            Navigator.push(
              context,
              LuxuryPageRoute(page: const ClinicTreatmentsScreen()),
            );
          },
        ),
      ],
    );
  }

  int _computeFallbackProgress(ClinicPortalService clinicService) {
    int count = 0;
    if (widget.clinic.logoUrl.isNotEmpty ||
        widget.clinic.coverImageUrl.isNotEmpty) {
      count++;
    }
    if (widget.clinic.descriptionAr.isNotEmpty ||
        widget.clinic.descriptionEn.isNotEmpty) {
      count++;
    }
    if (clinicService.clinicBranches.isNotEmpty ||
        widget.clinic.branches.isNotEmpty ||
        widget.clinic.hasMapLocation) {
      count++;
    }
    if (clinicService.clinicPractitioners.isNotEmpty ||
        clinicService.activePractitionersCount > 0) {
      count++;
    }
    if (clinicService.clinicTreatments.isNotEmpty ||
        clinicService.activeTreatmentsCount > 0) {
      count++;
    }
    return ((count / 5) * 100).round();
  }
}

class _ChecklistTile extends StatelessWidget {
  final String title;
  final bool isDone;
  final String actionLabel;
  final VoidCallback? onAction;

  const _ChecklistTile({
    required this.title,
    required this.isDone,
    required this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surfaceHover(context),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border(context), width: .8),
    ),
    child: LayoutBuilder(
      builder: (context, box) {
        final titleRow = Row(
          children: [
            Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              semanticLabel: LocaleService().isArabic
                  ? (isDone ? 'مكتمل' : 'غير مكتمل')
                  : (isDone ? 'Completed' : 'Incomplete'),
              size: 20,
              color: isDone
                  ? AppColors.positiveText(context)
                  : AppColors.mutedText(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
                  color: AppColors.text(context),
                ),
              ),
            ),
          ],
        );
        final action = onAction == null
            ? const SizedBox.shrink()
            : TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.goldText(context),
                  minimumSize: const Size(48, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: onAction,
                child: Text(actionLabel),
              );
        if (box.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.4) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleRow,
              if (onAction != null)
                Align(alignment: AlignmentDirectional.centerEnd, child: action),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: titleRow),
            if (onAction != null) ...[const SizedBox(width: 8), action],
          ],
        );
      },
    ),
  );
}

class _ReviewFeedback extends StatelessWidget {
  const _ReviewFeedback({required this.ar, required this.reason});
  final bool ar;
  final String reason;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      ApiException.sanitizeRegulatoryCompliance(
        reason.isNotEmpty
            ? (ar
                  ? 'ملاحظات المراجعة: $reason\nصحّح البيانات وأعد الإرسال عند اكتمال المتطلبات.'
                  : 'Review feedback: $reason\nCorrect the profile and resubmit when requirements are complete.')
            : (ar
                  ? 'يحتاج الملف إلى تعديلات. لم يُرفق سبب؛ راجع إدارة المنصة.'
                  : 'Profile changes are required. No reason was supplied; contact the platform team.'),
      ),
    ),
  );
}
