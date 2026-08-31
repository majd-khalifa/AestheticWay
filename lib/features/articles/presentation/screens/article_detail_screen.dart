import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/data/mock_data.dart';
import 'package:aesthetic_way/features/articles/models/article_model.dart';
import 'package:aesthetic_way/features/practitioners/presentation/screens/practitioner_profile_screen.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';

/// Article Detail Screen with reading typography, doctor author info & direct consultation lead
class ArticleDetailScreen extends StatelessWidget {
  final ArticleModel article;

  const ArticleDetailScreen({super.key, required this.article});

  Future<void> _handleBookLead(BuildContext context) async {
    final mockData = MockDataService();
    final clinic = mockData.getClinicById(article.clinicId) ?? mockData.clinics.first;
    final doctor = mockData.getPractitionerById(article.authorDoctorId);

    final auth = await GuestAuthGuard.requireAuth(
      context,
      reasonTitle: LocaleService().tr('article_consult_author_btn'),
      reasonSubtitle: LocaleService().isArabic
          ? 'سجّل دخولك برقم الهاتف لحجز استشارة مع الطبيب الكاتب'
          : 'Login with phone number to request a consultation with the author doctor',
    );
    if (!auth) return;

    if (context.mounted) {
      Navigator.push(
        context,
        LuxuryPageRoute(
          page: AppointmentRequestScreen(
            clinic: clinic,
            preselectedPractitioner: doctor,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final mockData = MockDataService();
    final isDark = AppColors.isDark(context);
    final doctor = mockData.getPractitionerById(article.authorDoctorId);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        title: Text(
          loc.tr('category_articles_title'),
          style: AppTypography.screenTitle.copyWith(
            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
            fontSize: 15.5,
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
          // Cover Image
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              article.coverImageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 200,
                color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                child: const Center(
                  child: Icon(Icons.article_outlined, color: AppColors.accentChampagne, size: 48),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Category Badge & Reading Time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.15 : 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  loc.isArabic ? article.categoryAr : article.categoryEn,
                  style: const TextStyle(
                    color: AppColors.accentChampagne,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 14, color: AppColors.accentChampagne),
                  const SizedBox(width: 4),
                  Text(
                    loc.tr('article_read_time'),
                    style: TextStyle(color: AppColors.mutedText(context), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Article Title
          Text(
            loc.isArabic ? article.titleAr : article.titleEn,
            style: AppTypography.screenTitle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Doctor Author Card (Clickable to doctor profile)
          LuxuryCard(
            onTap: () {
              if (doctor != null) {
                Navigator.push(
                  context,
                  LuxuryPageRoute(page: PractitionerProfileScreen(practitioner: doctor)),
                );
              }
            },
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    article.authorDoctorAvatar,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 50,
                      height: 50,
                      color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                      child: const Icon(Icons.person_rounded, color: AppColors.accentChampagne),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            loc.tr('article_author_by'),
                            style: TextStyle(color: AppColors.mutedText(context), fontSize: 10.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            loc.isArabic ? article.authorDoctorNameAr : article.authorDoctorNameEn,
                            style: TextStyle(
                              color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loc.isArabic ? article.clinicNameAr : (article.clinicNameEn ?? article.clinicNameAr),
                        style: const TextStyle(color: AppColors.accentChampagne, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('yyyy/MM/dd').format(article.publishedAt),
                  style: TextStyle(color: AppColors.mutedText(context), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Article Body Card
          LuxuryCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.isArabic ? article.contentAr : article.contentEn,
                  style: AppTypography.bodyLarge.copyWith(
                    fontSize: 14,
                    height: 1.8,
                    color: isDark ? AppColors.silverSecondary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Lead Consultation Action Button
          SilverButton(
            label: loc.tr('article_consult_author_btn'),
            icon: Icons.calendar_month_outlined,
            isFullWidth: true,
            height: 48,
            onPressed: () => _handleBookLead(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
