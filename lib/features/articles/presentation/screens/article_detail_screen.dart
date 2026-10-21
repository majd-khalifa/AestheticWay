import '../../../../core/widgets/patient_media_banner.dart';
import '../../../../core/utils/entity_id.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../practitioners/data/practitioners_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/features/articles/models/article_model.dart';
import 'package:aesthetic_way/features/clinics/data/clinics_repository.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/practitioners/presentation/screens/practitioner_profile_screen.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_request_screen.dart';

/// Article Detail Screen with reading typography, doctor author info & direct consultation lead
class ArticleDetailScreen extends StatelessWidget {
  final ArticleModel article;
  final ClinicsRepository? clinicsRepository;
  final PractitionersRepository? practitionersRepository;

  const ArticleDetailScreen({
    super.key,
    required this.article,
    this.clinicsRepository,
    this.practitionersRepository,
  });

  Future<PractitionerModel?> _resolveAuthorPractitioner() async {
    if (!isEntityUuid(article.authorDoctorId)) return null;
    try {
      final author =
          await (practitionersRepository ?? PractitionersRepository())
              .getPractitionerDetail(article.authorDoctorId);
      return author.clinicId == article.clinicId ? author : null;
    } catch (_) {
      return null;
    }
  }

  Future<ClinicModel?> _resolveClinic() async {
    if (!isEntityUuid(article.clinicId)) return null;
    try {
      return await (clinicsRepository ?? ClinicsRepository()).getClinicDetail(
        article.clinicId,
      );
    } catch (_) {
      return null;
    }
  }

  void _unavailable(BuildContext context) => showAppSnackBar(
    context,
    LocaleService().isArabic
        ? 'تعذر التحقق من الكاتب والعيادة. حاول مجدداً.'
        : 'Author or clinic unavailable. Please try again.',
    type: AppSnackBarType.error,
  );

  Future<void> _handleBookLead(BuildContext context) async {
    final auth = await GuestAuthGuard.requireAuth(
      context,
      reasonTitle: LocaleService().tr('article_consult_author_btn'),
      reasonSubtitle: LocaleService().isArabic
          ? 'سجّل دخولك برقم الهاتف لحجز استشارة مع الطبيب الكاتب'
          : 'Login with phone number to request a consultation with the author doctor',
    );
    if (!auth || !context.mounted) return;

    final clinic = await _resolveClinic();
    final doctor = await _resolveAuthorPractitioner();

    if (!context.mounted) return;
    if (clinic == null || doctor == null) {
      _unavailable(context);
      return;
    }
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
    final isDark = AppColors.isDark(context);
    final categoryLabel = loc.isArabic
        ? article.categoryAr
        : article.categoryEn;
    final authorName = loc.isArabic
        ? article.authorDoctorNameAr
        : article.authorDoctorNameEn;
    final displayAuthor = authorName.isNotEmpty
        ? authorName
        : (loc.isArabic
              ? (article.clinicNameAr.isNotEmpty
                    ? article.clinicNameAr
                    : 'الكاتب غير محدد')
              : (article.clinicNameEn ?? 'Author not provided'));

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        title: Text(
          loc.tr('category_articles_title'),
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
          // Cover Image
          PatientMediaBanner(
            source: article.coverImageUrl,
            height: 190,
            borderRadius: BorderRadius.circular(18),
          ),
          const SizedBox(height: 16),

          // Category Badge & Reading Time
          Row(
            children: [
              if (categoryLabel.isNotEmpty)
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
                    categoryLabel,
                    style: TextStyle(
                      color: AppColors.goldText(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppColors.accentChampagne,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${((loc.isArabic ? article.contentAr : article.contentEn).split(RegExp(r"\s+")).where((word) => word.isNotEmpty).length / 180).ceil().clamp(1, 999)} ${loc.isArabic ? 'دقيقة قراءة' : 'min read'}',
                    style: TextStyle(
                      color: AppColors.mutedText(context),
                      fontSize: 11,
                    ),
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
              color: isDark
                  ? AppColors.silverPrimary
                  : AppColors.lightTextPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Doctor Author Card (Clickable to doctor profile)
          LuxuryCard(
            onTap: !isEntityUuid(article.authorDoctorId)
                ? null
                : () async {
                    final doctor = await _resolveAuthorPractitioner();
                    if (!context.mounted) return;
                    if (doctor == null) {
                      _unavailable(context);
                      return;
                    }
                    Navigator.push(
                      context,
                      LuxuryPageRoute(
                        page: PractitionerProfileScreen(practitioner: doctor),
                      ),
                    );
                  },
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LuxuryImage(
                    imageUrl: article.authorDoctorAvatar,
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
                        Icons.person_rounded,
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
                      Row(
                        children: [
                          Text(
                            loc.tr('article_author_by'),
                            style: TextStyle(
                              color: AppColors.mutedText(context),
                              fontSize: 10.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              displayAuthor,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.silverPrimary
                                    : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (article.clinicNameAr.isNotEmpty ||
                          (article.clinicNameEn?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 2),
                        Text(
                          loc.isArabic
                              ? article.clinicNameAr
                              : (article.clinicNameEn ?? article.clinicNameAr),
                          style: TextStyle(
                            color: AppColors.goldText(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (article.hasPublicationDate)
                  Text(
                    DateFormat('yyyy/MM/dd').format(article.publishedAt),
                    style: TextStyle(
                      color: AppColors.mutedText(context),
                      fontSize: 10,
                    ),
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
                    fontSize: 16,
                    height: 1.8,
                    color: isDark
                        ? AppColors.silverSecondary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Lead Consultation Action Button
          SilverButton(
            label: loc.tr('article_consult_author_btn'),
            icon: Icons.chat_bubble_outline,
            isFullWidth: true,
            height: 48,
            onPressed:
                isEntityUuid(article.clinicId) &&
                    isEntityUuid(article.authorDoctorId)
                ? () => _handleBookLead(context)
                : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
