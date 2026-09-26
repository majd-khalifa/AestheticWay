import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/core/utils/contact_launcher.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';

/// Clinic Lead Detail Screen for Reviewing Patient Inquiries, Contacting & Updating Status
class ClinicLeadDetailScreen extends StatefulWidget {
  final AppointmentRequestModel lead;

  const ClinicLeadDetailScreen({super.key, required this.lead});

  @override
  State<ClinicLeadDetailScreen> createState() => _ClinicLeadDetailScreenState();
}

class _ClinicLeadDetailScreenState extends State<ClinicLeadDetailScreen> {
  late AppointmentLeadStatus _currentStatus;
  late TextEditingController _notesController;
  bool _isUpdatingStatus = false;
  bool _isSavingNotes = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.lead.status;
    final existingNotes = ClinicPortalService().getInternalNotes(widget.lead.id);
    _notesController = TextEditingController(text: existingNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(AppointmentLeadStatus newStatus) async {
    if (_currentStatus == newStatus || _isUpdatingStatus) return;

    final loc = LocaleService();
    final prevStatus = _currentStatus;
    setState(() {
      _currentStatus = newStatus;
      _isUpdatingStatus = true;
    });

    try {
      await ClinicPortalService().updateLeadStatus(widget.lead.id, newStatus);
      if (!mounted) return;
      showAppSnackBar(
        context,
        loc.tr('clinic_status_updated'),
        type: AppSnackBarType.success,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentStatus = prevStatus;
      });
      showAppSnackBar(
        context,
        loc.isArabic ? 'فشل تحديث الحالة' : 'Failed to update status',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  Future<void> _saveInternalNotes() async {
    final noteText = _notesController.text.trim();
    if (noteText.isEmpty || _isSavingNotes) return;

    final loc = LocaleService();
    setState(() {
      _isSavingNotes = true;
    });

    try {
      await ClinicPortalService().saveInternalNotes(widget.lead.id, noteText);
      if (!mounted) return;
      showAppSnackBar(
        context,
        loc.tr('clinic_notes_saved'),
        type: AppSnackBarType.success,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        loc.isArabic ? 'فشل حفظ الملاحظة' : 'Failed to save note',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingNotes = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    String timeWindowText;
    switch (widget.lead.preferredTimeWindow) {
      case PreferredTimeWindow.morning:
        timeWindowText = loc.tr('time_morning');
        break;
      case PreferredTimeWindow.afternoon:
        timeWindowText = loc.tr('time_afternoon');
        break;
      case PreferredTimeWindow.evening:
        timeWindowText = loc.tr('time_evening');
        break;
    }

    return ListenableBuilder(
      listenable: loc,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Text(
              '${loc.tr('clinic_nav_leads')} • ${widget.lead.referenceCode}',
              style: AppTypography.screenTitle.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                fontSize: 15,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // Patient Header Card
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                          child: Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.lead.patientFullName,
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.lead.patientPhone,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentChampagne,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Direct Contact Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SilverButton(
                            label: loc.tr('clinic_lead_call'),
                            icon: Icons.phone_rounded,
                            height: 42,
                            onPressed: () {
                              ContactLauncher.makePhoneCall(widget.lead.patientPhone);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ContactLauncher.openWhatsApp(phoneNumber: widget.lead.patientPhone);
                            },
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                            label: Text(
                              loc.tr('clinic_lead_whatsapp'),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Request Summary Details Card
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tr('lead_summary_title'),
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.spa_outlined,
                      label: loc.tr('service_label'),
                      value: widget.lead.serviceNameAr,
                    ),
                    const Divider(height: 16),
                    _DetailRow(
                      icon: Icons.store_mall_directory_outlined,
                      label: loc.tr('branch_label'),
                      value: widget.lead.branchNameAr,
                    ),
                    if (widget.lead.practitionerNameAr != null) ...[
                      const Divider(height: 16),
                      _DetailRow(
                        icon: Icons.person_outline,
                        label: loc.tr('practitioner_label'),
                        value: widget.lead.practitionerNameAr!,
                      ),
                    ],
                    const Divider(height: 16),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: loc.tr('date_label'),
                      value: '${DateFormat('yyyy/MM/dd').format(widget.lead.preferredDate)} ($timeWindowText)',
                    ),
                    const Divider(height: 16),
                    _DetailRow(
                      icon: Icons.source_outlined,
                      label: loc.tr('ref_number'),
                      value: '${widget.lead.referenceCode} • ${loc.tr('clinic_lead_source')}',
                    ),
                    if (widget.lead.notes != null && widget.lead.notes!.isNotEmpty) ...[
                      const Divider(height: 16),
                      _DetailRow(
                        icon: Icons.notes_outlined,
                        label: loc.tr('notes_opt'),
                        value: widget.lead.notes!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Status Selector Card
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tr('clinic_change_status'),
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _StatusSelectChip(
                          label: loc.tr('clinic_lead_status_new'),
                          isSelected: _currentStatus == AppointmentLeadStatus.sent,
                          color: const Color(0xFFF59E0B),
                          onTap: _isUpdatingStatus ? () {} : () => _updateStatus(AppointmentLeadStatus.sent),
                        ),
                        const SizedBox(width: 8),
                        _StatusSelectChip(
                          label: loc.tr('clinic_lead_status_contacted'),
                          isSelected: _currentStatus == AppointmentLeadStatus.contacted,
                          color: const Color(0xFF3B82F6),
                          onTap: _isUpdatingStatus ? () {} : () => _updateStatus(AppointmentLeadStatus.contacted),
                        ),
                        const SizedBox(width: 8),
                        _StatusSelectChip(
                          label: loc.tr('clinic_lead_status_closed'),
                          isSelected: _currentStatus == AppointmentLeadStatus.closed,
                          color: const Color(0xFF10B981),
                          onTap: _isUpdatingStatus ? () {} : () => _updateStatus(AppointmentLeadStatus.closed),
                        ),
                      ],
                    ),
                    if (_isUpdatingStatus) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(
                        color: AppColors.accentChampagne,
                        backgroundColor: Colors.transparent,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Internal Clinic Notes Card
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tr('clinic_internal_notes'),
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    if (widget.lead.internalNotes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...widget.lead.internalNotes.map((n) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border(context), width: 0.6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  n.authorName,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentChampagne,
                                  ),
                                ),
                                Text(
                                  DateFormat('MM/dd HH:mm').format(n.createdAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.mutedText(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n.note,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: loc.tr('clinic_internal_notes_hint'),
                        hintStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(context), width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentChampagne, width: 1.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: loc.isArabic ? Alignment.centerLeft : Alignment.centerRight,
                      child: SilverButton(
                        label: loc.tr('clinic_save_notes'),
                        icon: Icons.save_outlined,
                        height: 38,
                        isLoading: _isSavingNotes,
                        onPressed: _saveInternalNotes,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.accentChampagne),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusSelectChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _StatusSelectChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.22) : (isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.border(context),
              width: isSelected ? 1.4 : 0.8,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isSelected ? color : AppColors.mutedText(context),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 11.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
