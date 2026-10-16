/// Global API Configuration for AESTHETIC WAY
class ApiConfig {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String defaultProductionBaseUrl =
      'https://aestheticway.ae/api/v1/';
  static const String siteOrigin = 'https://aestheticway.ae';
  static String? _customBaseUrl;

  /// Configure a custom Base URL at runtime if needed (e.g. local dev override)
  static void setBaseUrl(String url) {
    _customBaseUrl = url.endsWith('/') ? url : '$url/';
  }

  /// Reset custom Base URL override
  static void resetBaseUrl() {
    _customBaseUrl = null;
  }

  /// Production-first Base URL:
  /// 1. Runtime override via [setBaseUrl]
  /// 2. Compile-time --dart-define=API_BASE_URL=...
  /// 3. Default production endpoint: https://aestheticway.ae/api/v1/
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!.endsWith('/')
          ? _customBaseUrl!
          : '$_customBaseUrl/';
    }
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl.endsWith('/') ? _envBaseUrl : '$_envBaseUrl/';
    }
    return defaultProductionBaseUrl;
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Auth Endpoints (Relative paths with trailing slash!)
  static const String register = 'auth/register/';
  static const String login = 'auth/login/';
  static const String verifyOtp = 'auth/verify-otp/';
  static const String resendOtp = 'auth/resend-otp/';
  static const String forgotPassword = 'auth/forgot-password/';
  static const String resetPassword = 'auth/reset-password/';
  static const String refresh = 'auth/refresh/';
  static const String logout = 'auth/logout/';
  static const String me = 'auth/me/';
  static const String authMe = me;
  static const String authPhoneChangeRequest = 'auth/me/phone/change/request/';
  static const String authPhoneChangeConfirm = 'auth/me/phone/change/confirm/';
  static const String authEmailChangeRequest = 'auth/me/email/change/request/';
  static const String authEmailChangeConfirm = 'auth/me/email/change/confirm/';

  // App Endpoints
  static const String supportInfo = 'app/support-info/';
  static const String appConfig = 'app/config/';

  // Discovery & Catalog Endpoints (Always with trailing slash!)
  static const String homeFeed = 'home/feed/';
  static const String clinics = 'clinics/';
  static String clinicDetail(String id) => 'clinics/$id/';
  static String clinicReviews(String id) => 'clinics/$id/reviews/';
  static String clinicReviewSubmit(String id) => 'clinics/$id/reviews/submit/';
  static const String practitioners = 'practitioners/';
  static String practitionerDetail(String id) => 'practitioners/$id/';
  static const String treatments = 'treatments/';
  static String treatmentDetail(String id) => 'treatments/$id/';
  static const String offers = 'offers/';
  static const String categories = 'categories/';
  static const String products = 'products/';
  static String productDetail(String id) => 'products/$id/';
  static const String articles = 'articles/';
  static String articleDetail(String id) => 'articles/$id/';

  // Leads & Appointment Endpoints (Always with trailing slash!)
  static const String leads = 'leads/';
  static const String myLeads = 'leads/my/';
  static const String myLeadsCount = 'leads/my/count/';
  static String leadDetail(String id) => 'leads/$id/';

  // Clinic Portal Endpoints (Always with trailing slash!)
  static const String clinicDashboard = 'clinic-portal/dashboard/';
  static const String clinicBadges = 'clinic-portal/badges/';
  static const String clinicProfile = 'clinic-portal/profile/';
  static const String clinicBranches = 'clinic-portal/branches/';
  static String clinicBranchDetail(String id) => 'clinic-portal/branches/$id/';
  static const String clinicSetupChecklist =
      'clinic-portal/profile/setup-checklist/';
  static const String clinicSubmitForReview =
      'clinic-portal/profile/submit-for-review/';
  static const String clinicLeads = 'clinic-portal/leads/';
  static String clinicLeadDetail(String id) => 'clinic-portal/leads/$id/';
  static String clinicLeadNotes(String id) => 'clinic-portal/leads/$id/notes/';
  static const String clinicPractitioners = 'clinic-portal/practitioners/';
  static String clinicPractitionerDetail(String id) =>
      'clinic-portal/practitioners/$id/';
  static const String clinicTreatments = 'clinic-portal/treatments/';
  static String clinicTreatmentDetail(String id) =>
      'clinic-portal/treatments/$id/';
  static const String clinicOffers = 'clinic-portal/offers/';
  static String clinicOfferDetail(String id) => 'clinic-portal/offers/$id/';
  static const String clinicProducts = 'clinic-portal/products/';
  static String clinicProductDetail(String id) => 'clinic-portal/products/$id/';
  static const String clinicArticles = 'clinic-portal/articles/';
  static String clinicArticleDetail(String id) => 'clinic-portal/articles/$id/';
  static const String clinicVerifyDiscountCode =
      'clinic-portal/discount-codes/verify/';
  static const String clinicDiscountVerify = clinicVerifyDiscountCode;
  static const String clinicRedeemDiscountCode =
      'clinic-portal/discount-codes/redeem/';
  static const String clinicDiscountRedeem = clinicRedeemDiscountCode;

  // Referral & Rewards Endpoints (Always with trailing slash!)
  static const String referralStatus = 'referral/my-status/';
  static const String referralCollect = 'referral/collect-code/';

  // Media & Binary Upload Endpoints (Always with trailing slash!)
  static const String mediaUpload = 'media/upload/';

  // Notifications & Device Push Endpoints (Always with trailing slash!)
  static const String notificationDevices = 'notifications/devices/';
  static String notificationDeviceDeactivate(String token) =>
      'notifications/devices/$token/';

  // Super Admin Portal Endpoints (Always with trailing slash!)
  static const String adminDashboard = 'admin/dashboard/';
  static const String adminClinics = 'admin/clinics/';
  static String adminClinicDetail(String id) => 'admin/clinics/$id/';
  static String adminClinicSuspend(String id) => 'admin/clinics/$id/suspend/';
  static String adminClinicActivate(String id) => 'admin/clinics/$id/activate/';
  static String adminClinicVerify(String id) => 'admin/clinics/$id/verify/';
  static String adminClinicResetPassword(String id) =>
      'admin/clinics/$id/reset-admin-password/';
  static const String adminLeads = 'admin/leads/';
  static String adminLeadDetail(String id) => 'admin/leads/$id/';
  static const String adminOffers = 'admin/offers/';
  static String adminOfferDetail(String id) => 'admin/offers/$id/';
  static String adminOfferApprove(String id) => 'admin/offers/$id/approve/';
  static String adminOfferReject(String id) => 'admin/offers/$id/reject/';
  static String adminOfferSuspend(String id) => 'admin/offers/$id/suspend/';
  static String adminOfferRestore(String id) => 'admin/offers/$id/restore/';

  static const String adminProducts = 'admin/products/';
  static String adminProductDetail(String id) => 'admin/products/$id/';
  static String adminProductApprove(String id) => 'admin/products/$id/approve/';
  static String adminProductReject(String id) => 'admin/products/$id/reject/';
  static String adminProductSuspend(String id) => 'admin/products/$id/suspend/';
  static String adminProductRestore(String id) => 'admin/products/$id/restore/';

  static const String adminArticles = 'admin/articles/';
  static String adminArticleDetail(String id) => 'admin/articles/$id/';
  static String adminArticleApprove(String id) => 'admin/articles/$id/approve/';
  static String adminArticleReject(String id) => 'admin/articles/$id/reject/';
  static String adminArticleSuspend(String id) => 'admin/articles/$id/suspend/';
  static String adminArticleRestore(String id) => 'admin/articles/$id/restore/';

  static const String adminAnalytics = 'admin/analytics/';
  static const String adminSettings = 'admin/settings/';
}
