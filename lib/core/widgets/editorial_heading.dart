import 'package:flutter/material.dart';
import '../localization/app_locale.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class EditorialHeading extends StatelessWidget {
  const EditorialHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });
  final String eyebrow;
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    final arabic = LocaleService().isArabic;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 18, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: arabic ? 0 : 1.8,
              height: 1.6,
              color: AppColors.goldText(context),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            title,
            style: TextStyle(
              fontFamily: arabic ? null : 'serif',
              fontSize: 28,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: AppColors.text(context),
            ),
          ),
          if (subtitle?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              subtitle!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.subtext(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
