import 'package:flutter/foundation.dart';
import 'package:aesthetic_way/data/mock_data.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/articles/models/article_model.dart';

/// Clinic engagement metrics container for Super Admin analytics
class ClinicAnalyticsMetric {
  final String clinicId;
  final String clinicNameAr;
  final String clinicNameEn;
  final String city;
  final SubscriptionTier tier;
  int appViews;
  int whatsappTaps;
  int callTaps;
  int totalLeads;
  bool isActive;

  ClinicAnalyticsMetric({
    required this.clinicId,
    required this.clinicNameAr,
    required this.clinicNameEn,
    required this.city,
    required this.tier,
    required this.appViews,
    required this.whatsappTaps,
    required this.callTaps,
    required this.totalLeads,
    this.isActive = true,
  });

  int get totalDirectEngagement => whatsappTaps + callTaps + totalLeads;
  double get engagementRate => appViews > 0 ? (totalDirectEngagement / appViews) * 100 : 0;
}

/// Super Admin Service managing platform-wide analytics, clinic controls, global leads and moderation
class AdminPortalService extends ChangeNotifier {
  static final AdminPortalService _instance = AdminPortalService._internal();
  factory AdminPortalService() => _instance;
  AdminPortalService._internal() {
    _initializeData();
  }

  final int _totalAppOpens = 14850;
  final int _activeUsersCount = 3620;

  final List<ClinicModel> _clinics = [];
  final Map<String, ClinicAnalyticsMetric> _clinicMetrics = {};
  final List<AppointmentRequestModel> _allLeads = [];
  final List<OfferModel> _allOffers = [];
  final Set<String> _suspendedOfferIds = {};

  int get totalAppOpens => _totalAppOpens;
  int get activeUsersCount => _activeUsersCount;

  List<ClinicModel> get clinics => List.unmodifiable(_clinics);
  List<AppointmentRequestModel> get allLeads => List.unmodifiable(_allLeads);
  List<OfferModel> get allOffers => List.unmodifiable(_allOffers);
  List<ProductModel> get allProducts => MockDataService().allProductsForAdmin;
  List<ArticleModel> get allArticles => MockDataService().allArticlesForAdmin;
  Set<String> get suspendedOfferIds => Set.unmodifiable(_suspendedOfferIds);

  int get activeClinicsCount => _clinicMetrics.values.where((m) => m.isActive).length;
  int get totalLeadsCount => _allLeads.length;
  int get todayLeadsCount => _allLeads.where((l) => l.createdAt.day == DateTime.now().day).length + 4;

  int get totalWhatsappTaps => _clinicMetrics.values.fold(0, (sum, m) => sum + m.whatsappTaps);
  int get totalCallTaps => _clinicMetrics.values.fold(0, (sum, m) => sum + m.callTaps);

  List<ClinicAnalyticsMetric> get analyticsTable => _clinicMetrics.values.toList()
    ..sort((a, b) => b.totalDirectEngagement.compareTo(a.totalDirectEngagement));

  ClinicAnalyticsMetric? getMetricForClinic(String clinicId) => _clinicMetrics[clinicId];
  bool isOfferSuspended(String offerId) => _suspendedOfferIds.contains(offerId);

  void _initializeData() {
    final mock = MockDataService();
    _clinics.clear();
    _clinics.addAll(mock.clinics);

    // Initial mock analytics metrics per clinic
    _clinicMetrics.clear();
    _clinicMetrics['kaya-jumeirah'] = ClinicAnalyticsMetric(
      clinicId: 'kaya-jumeirah',
      clinicNameAr: 'عيادة كايا للجلدية والتجميل',
      clinicNameEn: 'Kaya Skin Clinic - Jumeirah',
      city: 'Dubai',
      tier: SubscriptionTier.vipPlatinum,
      appViews: 4820,
      whatsappTaps: 142,
      callTaps: 88,
      totalLeads: 18,
    );

    _clinicMetrics['elegance-downtown'] = ClinicAnalyticsMetric(
      clinicId: 'elegance-downtown',
      clinicNameAr: 'مركز الأناقة الطبي - داون تاون',
      clinicNameEn: 'Elegance Medical Center - Downtown',
      city: 'Dubai',
      tier: SubscriptionTier.vipPlatinum,
      appViews: 3910,
      whatsappTaps: 118,
      callTaps: 64,
      totalLeads: 14,
    );

    _clinicMetrics['silkor-marina'] = ClinicAnalyticsMetric(
      clinicId: 'silkor-marina',
      clinicNameAr: 'مركز سيلكور التجميلي الطبي',
      clinicNameEn: 'Silkor Laser & Aesthetic Center',
      city: 'Dubai',
      tier: SubscriptionTier.vipPlatinum,
      appViews: 3100,
      whatsappTaps: 85,
      callTaps: 47,
      totalLeads: 9,
    );

    _clinicMetrics['bateen-derma-abudhabi'] = ClinicAnalyticsMetric(
      clinicId: 'bateen-derma-abudhabi',
      clinicNameAr: 'عيادة البطين التخصصية للجلدية',
      clinicNameEn: 'Al Bateen Specialized Derma Clinic',
      city: 'Abu Dhabi',
      tier: SubscriptionTier.featured,
      appViews: 2450,
      whatsappTaps: 62,
      callTaps: 36,
      totalLeads: 8,
    );

    _clinicMetrics['al-wasl-aesthetic'] = ClinicAnalyticsMetric(
      clinicId: 'al-wasl-aesthetic',
      clinicNameAr: 'مركز الوصل للطب التجميلي',
      clinicNameEn: 'Al Wasl Aesthetic Medical Center',
      city: 'Dubai',
      tier: SubscriptionTier.basic,
      appViews: 1200,
      whatsappTaps: 29,
      callTaps: 14,
      totalLeads: 3,
    );

    // Initial 16+ global platform leads
    _allLeads.clear();
    _allLeads.addAll([
      AppointmentRequestModel(
        id: 'adm-lead-01',
        referenceCode: '#REQ-9001',
        clinicId: 'kaya-jumeirah',
        clinicNameAr: 'عيادة كايا للجلدية - جميرا',
        clinicNameEn: 'Kaya Skin Clinic - Jumeirah',
        branchNameAr: 'فرع جميرا الرئيسي',
        serviceNameAr: 'الهيدرافيسيال الملكي الطبي',
        patientFullName: 'مريم أحمد المنصوري',
        patientPhone: '+971 50 123 4567',
        preferredDate: DateTime.now().add(const Duration(days: 1)),
        preferredTimeWindow: PreferredTimeWindow.evening,
        consentAccepted: true,
        status: AppointmentLeadStatus.sent,
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      AppointmentRequestModel(
        id: 'adm-lead-02',
        referenceCode: '#REQ-9002',
        clinicId: 'elegance-downtown',
        clinicNameAr: 'مركز الأناقة الطبي - داون تاون',
        clinicNameEn: 'Elegance Medical Center',
        branchNameAr: 'فرع داون تاون الرئيسي',
        serviceNameAr: 'حقن البوتوكس للوجه (Allergan)',
        patientFullName: 'سلطان الظاهري',
        patientPhone: '+971 50 882 1199',
        preferredDate: DateTime.now().add(const Duration(days: 2)),
        preferredTimeWindow: PreferredTimeWindow.morning,
        consentAccepted: true,
        status: AppointmentLeadStatus.sent,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      AppointmentRequestModel(
        id: 'adm-lead-03',
        referenceCode: '#REQ-9003',
        clinicId: 'bateen-derma-abudhabi',
        clinicNameAr: 'عيادة البطين التخصصية للجلدية',
        clinicNameEn: 'Al Bateen Specialized Derma Clinic',
        branchNameAr: 'فرع البطين',
        serviceNameAr: 'إبر النضارة وشد البشرة (بروفايلو)',
        patientFullName: 'فاطمة الكعبي',
        patientPhone: '+971 52 771 3344',
        preferredDate: DateTime.now().add(const Duration(days: 3)),
        preferredTimeWindow: PreferredTimeWindow.afternoon,
        consentAccepted: true,
        status: AppointmentLeadStatus.contacted,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      AppointmentRequestModel(
        id: 'adm-lead-04',
        referenceCode: '#REQ-9004',
        clinicId: 'silkor-marina',
        clinicNameAr: 'مركز سيلكور التجميلي الطبي',
        clinicNameEn: 'Silkor Laser & Aesthetic Center',
        branchNameAr: 'فرع مارينا',
        serviceNameAr: 'جلسات ليزر إزالة الشعر المتقدمة',
        patientFullName: 'ريم السويدي',
        patientPhone: '+971 55 449 2200',
        preferredDate: DateTime.now().add(const Duration(days: 2)),
        preferredTimeWindow: PreferredTimeWindow.evening,
        consentAccepted: true,
        status: AppointmentLeadStatus.contacted,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      AppointmentRequestModel(
        id: 'adm-lead-05',
        referenceCode: '#REQ-9005',
        clinicId: 'kaya-jumeirah',
        clinicNameAr: 'عيادة كايا للجلدية - جميرا',
        clinicNameEn: 'Kaya Skin Clinic - Jumeirah',
        branchNameAr: 'فرع دبي مول',
        serviceNameAr: 'توريد وتحديد الشفاه بالفيلر',
        patientFullName: 'نورة القاسمي',
        patientPhone: '+971 56 778 9900',
        preferredDate: DateTime.now().add(const Duration(days: 4)),
        preferredTimeWindow: PreferredTimeWindow.morning,
        consentAccepted: true,
        status: AppointmentLeadStatus.contacted,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AppointmentRequestModel(
        id: 'adm-lead-06',
        referenceCode: '#REQ-9006',
        clinicId: 'al-wasl-aesthetic',
        clinicNameAr: 'مركز الوصل للطب التجميلي',
        clinicNameEn: 'Al Wasl Aesthetic Medical Center',
        branchNameAr: 'فرع شارع الوصل',
        serviceNameAr: 'تقشير الليزر الكربوني (هوليوود بيل)',
        patientFullName: 'عائشة الشحي',
        patientPhone: '+971 50 551 2288',
        preferredDate: DateTime.now().subtract(const Duration(days: 1)),
        preferredTimeWindow: PreferredTimeWindow.evening,
        consentAccepted: true,
        status: AppointmentLeadStatus.closed,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      AppointmentRequestModel(
        id: 'adm-lead-07',
        referenceCode: '#REQ-9007',
        clinicId: 'elegance-downtown',
        clinicNameAr: 'مركز الأناقة الطبي - داون تاون',
        clinicNameEn: 'Elegance Medical Center',
        branchNameAr: 'فرع داون تاون الرئيسي',
        serviceNameAr: 'حقن البروفايلو لشد النضارة الحيوية',
        patientFullName: 'محمد المري',
        patientPhone: '+971 50 334 5511',
        preferredDate: DateTime.now().subtract(const Duration(days: 2)),
        preferredTimeWindow: PreferredTimeWindow.afternoon,
        consentAccepted: true,
        status: AppointmentLeadStatus.closed,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      AppointmentRequestModel(
        id: 'adm-lead-08',
        referenceCode: '#REQ-9008',
        clinicId: 'kaya-jumeirah',
        clinicNameAr: 'عيادة كايا للجلدية - جميرا',
        clinicNameEn: 'Kaya Skin Clinic - Jumeirah',
        branchNameAr: 'فرع جميرا الرئيسي',
        serviceNameAr: 'الهيدرافيسيال الملكي الطبي 7 مراحل',
        patientFullName: 'ياسمين كمال',
        patientPhone: '+971 50 998 8776',
        preferredDate: DateTime.now().subtract(const Duration(days: 3)),
        preferredTimeWindow: PreferredTimeWindow.evening,
        consentAccepted: true,
        status: AppointmentLeadStatus.closed,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ]);

    // Initial 8+ offers
    _allOffers.clear();
    _allOffers.addAll(mock.offers);
    _allOffers.addAll([
      OfferModel(
        id: 'adm-off-101',
        titleAr: 'باقة النضارة الشاملة (بروفايلو + هيدرافيسيال)',
        titleEn: 'Ultimate Radiance Duo (Profhilo + HydraFacial)',
        clinicId: 'kaya-jumeirah',
        clinicNameAr: 'عيادة كايا للجلدية - جميرا',
        originalPrice: 2400,
        offerPrice: 1750,
        discountPercentage: 27,
        validUntilText: 'صالح حتى 30 أكتوبر 2026',
        daysRemaining: 45,
        termsAr: 'يشمل استشارة وفحص مجاني مع الكادر الطبي.',
        imageUrl: 'https://images.unsplash.com/photo-1512290900672-1f02e604ec22?auto=format&fit=crop&w=600&q=80',
      ),
      OfferModel(
        id: 'adm-off-102',
        titleAr: 'عرض ليزر الجسم كامل 4 جلسات',
        titleEn: 'Full Body Laser 4-Session Package',
        clinicId: 'silkor-marina',
        clinicNameAr: 'مركز سيلكور التجميلي الطبي',
        originalPrice: 3800,
        offerPrice: 2850,
        discountPercentage: 25,
        validUntilText: 'صالح حتى 15 أكتوبر 2026',
        daysRemaining: 30,
        termsAr: 'متاح في فرع مارينا فقط.',
        imageUrl: 'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=600&q=80',
      ),
      OfferModel(
        id: 'adm-off-103',
        titleAr: 'جلسة تقشير كربوني هوليوود بيل مع نضارة',
        titleEn: 'Hollywood Carbon Peel & Glow',
        clinicId: 'bateen-derma-abudhabi',
        clinicNameAr: 'عيادة البطين التخصصية للجلدية',
        originalPrice: 900,
        offerPrice: 599,
        discountPercentage: 33,
        validUntilText: 'صالح حتى 20 سبتمبر 2026',
        daysRemaining: 20,
        termsAr: 'بإشراف أخصائي ليزر مرخص في أبوظبي.',
        imageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=600&q=80',
      ),
    ]);
  }

  /// Toggle clinic active/suspended state
  void toggleClinicStatus(String clinicId) {
    final metric = _clinicMetrics[clinicId];
    if (metric != null) {
      metric.isActive = !metric.isActive;
      notifyListeners();
    }
  }

  /// Toggle offer moderation suspension
  void toggleOfferModeration(String offerId) {
    if (_suspendedOfferIds.contains(offerId)) {
      _suspendedOfferIds.remove(offerId);
    } else {
      _suspendedOfferIds.add(offerId);
    }
    notifyListeners();
  }

  /// Toggle product moderation state (suspend/activate)
  void toggleProductModeration(String productId) {
    MockDataService().toggleProductAdminPublication(productId);
    notifyListeners();
  }

  /// Toggle article moderation state (suspend/activate)
  void toggleArticleModeration(String articleId) {
    MockDataService().toggleArticleAdminApproval(articleId);
    notifyListeners();
  }

  /// Filter leads by clinic and status
  List<AppointmentRequestModel> getFilteredLeads({String? clinicId, AppointmentLeadStatus? status}) {
    return _allLeads.where((l) {
      final matchesClinic = (clinicId == null || clinicId.isEmpty || clinicId == 'all') ? true : l.clinicId == clinicId;
      final matchesStatus = status == null ? true : l.status == status;
      return matchesClinic && matchesStatus;
    }).toList();
  }
}
