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

  const ArticleDetailScreen({
    super.key,
    required this.article,
    this.clinicsRepository,
  });

  PractitionerModel? _resolveAuthorPractitioner() {
    if (article.authorDoctorNameEn.isNotEmpty ||
        article.authorDoctorNameAr.isNotEmpty) {
      return PractitionerModel(
        id: article.authorDoctorId.isNotEmpty
            ? article.authorDoctorId
            : 'doc-id',
        nameAr: article.authorDoctorNameAr.isNotEmpty
            ? article.authorDoctorNameAr
            : article.authorDoctorNameEn,
        nameEn: article.authorDoctorNameEn.isNotEmpty
            ? article.authorDoctorNameEn
            : article.authorDoctorNameAr,
        type: PractitionerType.doctor,
        specialtyAr: article.authorDoctorSpecialtyAr.isNotEmpty
            ? article.authorDoctorSpecialtyAr
            : 'استشاري طب تجميلي',
        specialtyEn: article.authorDoctorSpecialtyEn.isNotEmpty
            ? article.authorDoctorSpecialtyEn
            : 'Aesthetic Specialist',
        classificationAr: article.authorDoctorSpecialtyAr,
        classificationEn: article.authorDoctorSpecialtyEn,
        licenseAuthority: '',
        licenseNumber: '',
        avatarUrl: article.authorDoctorAvatar,
        yearsOfExperience: 10,
        rating: 4.9,
        reviewCount: 15,
        clinicId: article.clinicId,
        clinicNameAr: article.clinicNameAr,
        clinicNameEn: article.clinicNameEn,
        aboutAr: '',
        languages: const ['العربية', 'English'],
        procedures: const [],
      );
    }
    return null;
  }

  Future<ClinicModel> _resolveClinic() async {
    if (article.clinicId.trim().isNotEmpty) {
      try {
        final repo = clinicsRepository ?? ClinicsRepository();
        return await repo.getClinicDetail(article.clinicId);
      } catch (_) {}
    }

    if (article.clinicNameAr.isNotEmpty ||
        (article.clinicNameEn?.isNotEmpty ?? false)) {
      return ClinicModel(
        id: article.clinicId.isNotEmpty ? article.clinicId : 'clinic-id',
        nameAr: article.clinicNameAr.isNotEmpty
            ? article.clinicNameAr
            : (article.clinicNameEn ?? ''),
        nameEn: article.clinicNameEn ?? article.clinicNameAr,
        descriptionAr: '',
        descriptionEn: '',
        coverImageUrl: article.coverImageUrl,
        galleryImages: const [],
        logoUrl: article.coverImageUrl,
        rating: 4.9,
        reviewCount: 0,
        subscriptionTier: SubscriptionTier.basic,
        licenseAuthority: '',
        licenseNumber: '',
        city: 'Dubai',
        areaAr: 'دبي',
        areaEn: 'Dubai',
        addressAr: 'دبي',
        addressEn: 'Dubai',
        distanceKm: 0,
        mainPhone: '+971500000000',
        receptionPhone: '+971500000000',
        whatsapp: '+971500000000',
        latitude: 25.2048,
        longitude: 55.2708,
        workingHoursAr: '10:00 ص - 9:00 م',
        workingHoursEn: '10:00 AM - 9:00 PM',
        branches: const [],
        practitionerIds: const [],
        treatmentIds: const [],
        featuredOffers: const [],
      );
    }

    return const ClinicModel(
      id: 'clinic-id',
      nameAr: 'العيادة الطبية المعتمدة',
      nameEn: 'Accredited Medical Clinic',
      descriptionAr: '',
      descriptionEn: '',
      coverImageUrl: '',
      galleryImages: [],
      logoUrl: '',
      rating: 4.9,
      reviewCount: 0,
      subscriptionTier: SubscriptionTier.basic,
      city: 'Dubai',
      areaAr: 'دبي',
      areaEn: 'Dubai',
      addressAr: 'دبي',
      addressEn: 'Dubai',
    );
  }

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
    final doctor = _resolveAuthorPractitioner();

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
    final doctor = _resolveAuthorPractitioner();
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
                    : 'أستيتك واي')
              : (article.clinicNameEn ?? 'Aesthetic Way'));

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
          LuxuryImage(
            imageUrl: article.coverImageUrl,
            fallbackLogoUrl: article.clinicLogoUrl,
            height: 200,
            width: double.infinity,
            borderRadius: BorderRadius.circular(18),
            placeholderIcon: Icons.article_outlined,
            iconSize: 48,
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
                    loc.tr('article_read_time'),
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
            onTap: () {
              if (doctor != null) {
                Navigator.push(
                  context,
                  LuxuryPageRoute(
                    page: PractitionerProfileScreen(practitioner: doctor),
                  ),
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
                      color: isDark
                          ? AppColors.cardSurfaceHover
                          : AppColors.lightCardSurfaceHover,
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.accentChampagne,
                      ),
                    ),
                    cacheWidth: computeSafeCacheWidth(context, 400, null),
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
                    fontSize: 14,
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
