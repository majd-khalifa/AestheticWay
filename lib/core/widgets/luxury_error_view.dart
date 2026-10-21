import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';

/// Luxury Medical Error & Retry Display
class LuxuryErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  final IconData icon;

  const LuxuryErrorView({
    super.key,
    this.message,
    required this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF161E2E)
                    : const Color(0xFFE2E8F0),
                border: Border.all(
                  color: AppColors.border(context),
                  width: 1.2,
                ),
              ),
              child: Icon(icon, size: 28, color: AppColors.accentChampagne),
            ),
            const SizedBox(height: 16),
            Text(
              loc.isArabic ? 'تعذر تحميل البيانات' : 'Unable to load data',
              style: AppTypography.screenTitle.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.text(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message ??
                  (loc.isArabic
                      ? 'يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً'
                      : 'Please check your internet connection and try again'),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.subtext(context),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SilverButton(
              label: loc.isArabic ? 'إعادة المحاولة' : 'Try Again',
              icon: Icons.refresh_rounded,
              variant: SilverButtonVariant.secondary,
              isFullWidth: false,
              height: 42,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
