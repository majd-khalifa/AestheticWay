import 'package:aesthetic_way/core/widgets/luxury_phone_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/core/widgets/tier_badge.dart';
import 'package:aesthetic_way/core/widgets/luxury_image_picker_field.dart';
import 'package:aesthetic_way/core/widgets/ltr_text_field.dart';
import 'package:aesthetic_way/core/services/media_upload_service.dart';
import 'package:aesthetic_way/core/utils/maps_launcher.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/admin/models/admin_clinic_model.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';

/// Super Admin Modal Sheet for inspecting clinic engagement, metrics, status & maps linking
class AdminClinicDetailSheet extends StatelessWidget {
  final AdminClinicModel clinic;

  const AdminClinicDetailSheet({super.key, required this.clinic});

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final adminService = AdminPortalService();
    final isDark = AppColors.isDark(context);

    return ListenableBuilder(
      listenable: adminService,
      builder: (context, _) {
        final metric = adminService.getMetricForClinic(clinic.id);
        final isActive = metric?.isActive ?? true;
        final clinicOffers = adminService.allOffers.where((o) => o.clinicId == clinic.id).toList();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDeep : AppColors.lightCardSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.border(context), width: 0.8)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.mutedText(context).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Clinic Header Row
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        clinic.coverImageUrl,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 54,
                          height: 54,
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
                          const SizedBox(height: 4),
                          TierBadge(tier: clinic.subscriptionTier),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4 Clinic Catalog & Leads Counts (strictly from backend AdminClinicModel)
                Row(
                  children: [
                    Expanded(
                      child: _AdminMetricBox(
                        label: loc.tr('admin_table_leads'),
                        value: '${clinic.leadsCount}',
                        icon: Icons.mark_email_read_outlined,
                        isGold: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AdminMetricBox(
                        label: loc.tr('admin_clinic_branches'),
                        value: '${clinic.branchesCount}',
                        icon: Icons.store_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _AdminMetricBox(
                        label: loc.tr('admin_clinic_practitioners'),
                        value: '${clinic.practitionersCount}',
                        icon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AdminMetricBox(
                        label: loc.tr('admin_clinic_offers'),
                        value: '${clinic.offersCount}',
                        icon: Icons.local_offer_outlined,
                        iconColor: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status & Controls Box
                LuxuryCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.tr('admin_toggle_clinic_status'),
                            style: AppTypography.caption.copyWith(
                              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isActive ? loc.tr('admin_clinic_status_active') : loc.tr('admin_clinic_status_suspended'),
                            style: TextStyle(
                              color: isActive ? const Color(0xFF10B981) : AppColors.errorRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: isActive,
                        activeThumbColor: AppColors.accentChampagne,
                        onChanged: (val) {
                          adminService.toggleClinicStatus(clinic.id);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Open in Google Maps
                SilverButton(
                  label: loc.tr('open_in_maps'),
                  icon: Icons.directions_outlined,
                  height: 42,
                  isFullWidth: true,
                  onPressed: () {
                    MapsLauncher.openDirections(
                      latitude: clinic.latitude,
                      longitude: clinic.longitude,
                      destinationTitle: loc.isArabic ? clinic.nameAr : clinic.nameEn,
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Reset Admin Password
                OutlinedButton.icon(
                  icon: const Icon(Icons.lock_reset_rounded, size: 18, color: AppColors.accentChampagne),
                  label: Text(
                    loc.isArabic ? 'إعادة تعيين كلمة مرور المشرف' : 'Reset Admin Password',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.accentChampagne),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.accentChampagne, width: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size.fromHeight(42),
                  ),
                  onPressed: () => _handleResetPassword(context, loc, adminService),
                ),
                const SizedBox(height: 10),

                // Edit Clinic Details & Branding
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.silverPrimary),
                  label: Text(
                    loc.isArabic ? 'تعديل بيانات وهوية العيادة' : 'Edit Clinic Details & Branding',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border(context), width: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size.fromHeight(42),
                  ),
                  onPressed: () => _handleEditClinic(context, loc, adminService),
                ),
                const SizedBox(height: 14),

                // Associated Offers Section
                if (clinicOffers.isNotEmpty) ...[
                  Text(
                    '${loc.tr('clinic_nav_offers')} (${clinicOffers.length})',
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...clinicOffers.map((o) {
                    final isSuspended = adminService.isOfferSuspended(o.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border(context), width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                loc.isArabic ? o.titleAr : o.titleEn,
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              isSuspended ? loc.tr('admin_offer_suspended') : loc.tr('admin_offer_active'),
                              style: TextStyle(
                                fontSize: 10,
                                color: isSuspended ? AppColors.errorRed : const Color(0xFF10B981),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleResetPassword(
    BuildContext context,
    LocaleService loc,
    AdminPortalService adminService,
  ) {
    final passwordController = TextEditingController();
    final isDark = AppColors.isDark(context);
    String? resetErrorMessage;
    bool isResetting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.cardSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.lock_reset_rounded, color: AppColors.accentChampagne, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.isArabic ? 'إعادة تعيين كلمة مرور المشرف' : 'Reset Admin Password',
                  style: AppTypography.cardTitle.copyWith(
                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (resetErrorMessage != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          resetErrorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Text(
                loc.isArabic
                    ? 'سيتم توليد كلمة مرور مؤقتة جديدة لمسؤول هذه العيادة وإلغاء صلاحية الجلسات النشطة.'
                    : 'A new temporary password will be generated for the clinic admin and existing active sessions will be invalidated.',
                style: AppTypography.caption.copyWith(color: AppColors.mutedText(dialogCtx)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: loc.isArabic ? 'كلمة مرور مخصصة (اختياري)' : 'Custom Password (Optional)',
                  hintText: loc.isArabic ? 'اتركه فارغاً للتوليد التلقائي' : 'Leave blank to auto-generate',
                  prefixIcon: const Icon(Icons.key_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isResetting ? null : () => Navigator.pop(dialogCtx),
              child: Text(
                loc.isArabic ? 'إلغاء' : 'Cancel',
                style: TextStyle(color: AppColors.mutedText(dialogCtx)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentChampagne,
                foregroundColor: Colors.black,
              ),
              onPressed: isResetting
                  ? null
                  : () async {
                      setDialogState(() {
                        isResetting = true;
                        resetErrorMessage = null;
                      });
                      try {
                        final customPass = passwordController.text.trim();
                        final res = await adminService.resetClinicAdminPassword(
                          clinic.id,
                          customPassword: customPass.isNotEmpty ? customPass : null,
                        );
                        final newPass = res['temporary_password']?.toString() ??
                            (customPass.isNotEmpty ? customPass : 'AW#TempPass123!');

                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        if (context.mounted) {
                          _showNewPasswordModal(context, loc, newPass);
                        }
                      } catch (e) {
                        String cleanMsg;
                        if (e is ApiException) {
                          cleanMsg = e.message;
                        } else {
                          cleanMsg = ApiException.sanitizeRegulatoryCompliance(
                            e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', ''),
                          );
                        }
                        setDialogState(() {
                          resetErrorMessage = cleanMsg;
                          isResetting = false;
                        });
                      }
                    },
              child: isResetting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : Text(
                      loc.isArabic ? 'تأكيد التعيين' : 'Confirm Reset',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewPasswordModal(BuildContext context, LocaleService loc, String newPassword) {
    final isDark = AppColors.isDark(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
            const SizedBox(width: 8),
            Text(
              loc.isArabic ? 'تم تعيين كلمة المرور' : 'Password Reset Complete',
              style: AppTypography.cardTitle.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                fontSize: 15,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.isArabic
                  ? 'تم إنشاء كلمة مرور مؤقتة جديدة بنجاح. يرجى تزويد مشرف العيادة بها:'
                  : 'New temporary password generated successfully. Securely share it with the clinic administrator:',
              style: AppTypography.caption.copyWith(color: AppColors.mutedText(ctx)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDeep : AppColors.lightCardSurfaceHover,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(ctx), width: 0.8),
              ),
              child: SelectableText(
                newPassword,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.accentChampagne,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SilverButton(
              label: loc.isArabic ? 'نسخ كلمة المرور' : 'Copy Password',
              icon: Icons.copy_rounded,
              height: 40,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: newPassword));
                showAppSnackBar(
                  context,
                  loc.isArabic ? 'تم نسخ كلمة المرور' : 'Password copied to clipboard',
                  type: AppSnackBarType.success,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              loc.isArabic ? 'إغلاق' : 'Close',
              style: const TextStyle(color: AppColors.accentChampagne, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _handleEditClinic(
    BuildContext context,
    LocaleService loc,
    AdminPortalService adminService,
  ) {
    final isDark = AppColors.isDark(context);
    final formKey = GlobalKey<FormState>();

    final nameEnCtrl = TextEditingController(text: clinic.nameEn);
    final nameArCtrl = TextEditingController(text: clinic.nameAr);
    final phoneCtrl = TextEditingController(text: clinic.phone);
    final whatsappCtrl = TextEditingController(text: clinic.whatsapp);

    String selectedCity = clinic.city.isNotEmpty ? clinic.city : 'Dubai';
    String selectedTier = clinic.subscriptionTier.name;
    bool isFeatured = clinic.isFeatured;

    String? logoPath;
    String? coverPath;
    String? modalErrorMessage;
    bool isSubmitting = false;

    final List<String> cities = [
      'Dubai',
      'Abu Dhabi',
      'Sharjah',
      'Ajman',
      'Ras Al Khaimah',
      'Fujairah',
      'Umm Al Quwain',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(modalCtx).size.height * 0.88,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDeep : AppColors.lightCardSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppColors.border(modalCtx), width: 0.8)),
              ),
              child: Form(
                key: formKey,
                child: ListView(
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.mutedText(modalCtx).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loc.isArabic ? 'تعديل بيانات وهوية العيادة' : 'Edit Clinic Details & Branding',
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    if (modalErrorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                modalErrorMessage!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                              onPressed: () {
                                setModalState(() => modalErrorMessage = null);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Visual Branding Pickers
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: LuxuryImagePickerField(
                            label: loc.isArabic ? 'شعار العيادة' : 'Clinic Logo',
                            initialUrl: clinic.logo.isNotEmpty ? clinic.logo : null,
                            height: 120,
                            onImageSelected: (path) => logoPath = path,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: LuxuryImagePickerField(
                            label: loc.isArabic ? 'صورة الغلاف' : 'Cover Banner',
                            initialUrl: clinic.coverImage.isNotEmpty ? clinic.coverImage : null,
                            height: 120,
                            onImageSelected: (path) => coverPath = path,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Names
                    LtrTextFormField(
                      controller: nameEnCtrl,
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'اسم العيادة (إنجليزي)' : 'Clinic Name (English)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: nameArCtrl,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'اسم العيادة (عربي)' : 'Clinic Name (Arabic)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                    ),
                    const SizedBox(height: 10),

                    // Clinic Phone & WhatsApp with LuxuryPhoneInputField
                    LuxuryPhoneInputField(
                      controller: phoneCtrl,
                      labelText: loc.isArabic ? 'هاتف العيادة *' : 'Clinic Phone *',
                      isRequired: true,
                    ),
                    const SizedBox(height: 10),
                    LuxuryPhoneInputField(
                      controller: whatsappCtrl,
                      labelText: 'WhatsApp',
                      isRequired: false,
                    ),
                    const SizedBox(height: 10),

                    // City Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: cities.contains(selectedCity) ? selectedCity : cities.first,
                      dropdownColor: isDark ? AppColors.cardSurface : Colors.white,
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'المدينة' : 'City',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedCity = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Subscription Tier Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedTier,
                      dropdownColor: isDark ? AppColors.cardSurface : Colors.white,
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'فئة الاشتراك الإعلاني' : 'Subscription Tier',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'vip', child: Text('VIP Platinum')),
                        DropdownMenuItem(value: 'featured', child: Text('Featured')),
                        DropdownMenuItem(value: 'basic', child: Text('Basic')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedTier = val;
                            isFeatured = val != 'basic';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Is Featured switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.accentChampagne,
                      title: Text(
                        loc.isArabic ? 'تمييز العيادة في الصفحة الرئيسية' : 'Feature Clinic on Home Page',
                        style: TextStyle(
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: isFeatured,
                      onChanged: (val) => setModalState(() => isFeatured = val),
                    ),
                    const SizedBox(height: 18),

                    // Save Button
                    SilverButton(
                      label: loc.isArabic ? 'حفظ التعديلات' : 'Save Changes',
                      icon: Icons.check_circle_outline_rounded,
                      isFullWidth: true,
                      height: 46,
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => modalErrorMessage = null);
                              if (!formKey.currentState!.validate()) return;
                              final payload = <String, dynamic>{
                                'name_en': nameEnCtrl.text.trim(),
                                'name_ar': nameArCtrl.text.trim(),
                                'city': selectedCity,
                                'phone': phoneCtrl.text.trim(),
                                'whatsapp': whatsappCtrl.text.trim(),
                                'subscription_tier': selectedTier,
                                'is_featured': isFeatured,
                              };

                              setModalState(() => isSubmitting = true);

                              try {
                                if (logoPath != null && logoPath!.isNotEmpty && !logoPath!.startsWith('http')) {
                                  final res = await MediaUploadService().uploadImage(filePath: logoPath!, mediaType: 'clinic_logo');
                                  if (res['url'] != null) payload['logo'] = res['url'];
                                }

                                if (coverPath != null && coverPath!.isNotEmpty && !coverPath!.startsWith('http')) {
                                  final res = await MediaUploadService().uploadImage(filePath: coverPath!, mediaType: 'clinic_cover');
                                  if (res['url'] != null) payload['cover_image'] = res['url'];
                                }

                                await adminService.updateClinic(clinic.id, payload);
                                if (modalCtx.mounted) Navigator.pop(modalCtx);
                                if (context.mounted) {
                                  showAppSnackBar(
                                    context,
                                    loc.isArabic ? 'تم تحديث بيانات العيادة بنجاح' : 'Clinic updated successfully',
                                    type: AppSnackBarType.success,
                                  );
                                }
                              } catch (e) {
                                String cleanMsg;
                                if (e is ApiException) {
                                  cleanMsg = e.message;
                                } else {
                                  cleanMsg = ApiException.sanitizeRegulatoryCompliance(
                                    e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', ''),
                                  );
                                }
                                setModalState(() {
                                  modalErrorMessage = cleanMsg;
                                  isSubmitting = false;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isGold;
  final Color? iconColor;

  const _AdminMetricBox({
    required this.label,
    required this.value,
    required this.icon,
    this.isGold = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context), width: 0.8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor ?? (isGold ? AppColors.accentChampagne : AppColors.mutedText(context))),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 10.5),
              ),
              Text(
                value,
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isGold ? AppColors.accentChampagne : (isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
