import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/features/referral/models/referral_model.dart';
import 'package:aesthetic_way/features/referral/services/referral_service.dart';

/// Clinic Portal Screen: Verify and Redeem Patient 15% Referral Discount Codes
class ClinicVerifyCodeScreen extends StatefulWidget {
  final String clinicId;
  final String clinicName;

  const ClinicVerifyCodeScreen({
    super.key,
    this.clinicId = 'elegance-downtown',
    this.clinicName = 'مركز الأناقة الطبي للجلدية والتجميل',
  });

  @override
  State<ClinicVerifyCodeScreen> createState() => _ClinicVerifyCodeScreenState();
}

class _ClinicVerifyCodeScreenState extends State<ClinicVerifyCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  ReferralDiscountCode? _searchedCode;
  bool _hasSearched = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final query = _codeController.text.trim();
    if (query.isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final code = await ReferralService().verifyClinicCodeLive(query);
    if (!mounted) return;
    setState(() {
      _searchedCode = code;
      _hasSearched = true;
      _isSubmitting = false;
    });
  }

  Future<void> _markAsRedeemed(ReferralDiscountCode code) async {
    if (_isSubmitting) return;
    final loc = LocaleService();
    setState(() {
      _isSubmitting = true;
    });

    final success = await ReferralService().redeemClinicCodeLive(
      code: code.code,
      clinicId: widget.clinicId,
      clinicName: widget.clinicName,
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      if (success) {
        _searchedCode = ReferralService().verifyCode(code.code);
      }
    });

    if (success) {
      showAppSnackBar(
        context,
        loc.tr('clinic_code_redeemed_success'),
        type: AppSnackBarType.success,
      );
    } else {
      showAppSnackBar(
        context,
        loc.tr('clinic_code_invalid'),
        type: AppSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);
    final referralService = ReferralService();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        title: Text(
          loc.tr('clinic_verify_code_title'),
          style: AppTypography.screenTitle.copyWith(
            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
            fontSize: 16,
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
      body: ListenableBuilder(
        listenable: referralService,
        builder: (context, _) {
          final allCodes = referralService.allPlatformCodes;
          final redeemedInClinic = allCodes.where((c) => c.usedClinicId == widget.clinicId).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              // Search & Validator Card
              LuxuryCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.15 : 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.accentChampagne, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.tr('clinic_verify_code_title'),
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                loc.tr('clinic_verify_code_sub'),
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.mutedText(context),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Code Input Field
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeController,
                            style: TextStyle(
                              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: loc.tr('clinic_enter_code_hint'),
                              hintStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12.5),
                              prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.accentChampagne, size: 18),
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onSubmitted: (_) => _verifyCode(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _verifyCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentChampagne,
                            foregroundColor: const Color(0xFF070B16),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Icon(Icons.search_rounded, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search Result Container
              if (_hasSearched)
                if (_searchedCode == null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.4), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            loc.tr('clinic_code_invalid'),
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.errorRed,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  LuxuryCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _searchedCode!.code,
                                  style: AppTypography.heroTitle.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.accentChampagne,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'المريض: ${_searchedCode!.userName}',
                                  style: AppTypography.caption.copyWith(
                                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _searchedCode!.isAvailable
                                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                    : AppColors.border(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _searchedCode!.isAvailable
                                    ? loc.tr('code_status_available')
                                    : loc.tr('code_status_used'),
                                style: AppTypography.caption.copyWith(
                                  color: _searchedCode!.isAvailable
                                      ? const Color(0xFF10B981)
                                      : AppColors.mutedText(context),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 14),

                        // Discount details
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.percent_rounded, color: AppColors.accentChampagne, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  loc.tr('clinic_code_valid'),
                                  style: AppTypography.caption.copyWith(
                                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_searchedCode!.isAvailable)
                          SilverButton(
                            label: loc.tr('clinic_mark_used_btn'),
                            icon: Icons.check_circle_outline_rounded,
                            isFullWidth: true,
                            isLoading: _isSubmitting,
                            onPressed: _isSubmitting ? null : () => _markAsRedeemed(_searchedCode!),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'تم الاستخدام في: ${_searchedCode!.usedClinicName ?? "عيادة شريكة"}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.mutedText(context),
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

              const SizedBox(height: 20),

              // Recent Redeemed in this Clinic
              Text(
                'سجل الأكواد المستخدمة في العيادة',
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 10),

              if (redeemedInClinic.isEmpty)
                LuxuryCard(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'لم يتم تسجيل استخدام أي كود خصم في هذه العيادة بعد',
                      style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                    ),
                  ),
                )
              else
                ...redeemedInClinic.map((c) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border(context), width: 0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.code,
                              style: AppTypography.cardTitle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accentChampagne,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'المريض: ${c.userName}',
                              style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 11),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'خصم 15% مطبق',
                            style: AppTypography.caption.copyWith(
                              color: const Color(0xFF10B981),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
