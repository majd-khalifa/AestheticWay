import 'package:flutter/material.dart';

/// Supported App Locales
enum AppLanguage {
  arabic('ar', 'العربية', TextDirection.rtl),
  english('en', 'English', TextDirection.ltr);

  final String code;
  final String label;
  final TextDirection direction;

  const AppLanguage(this.code, this.label, this.direction);
}

/// Global Localization & Language State Manager (Singleton + ChangeNotifier)
class LocaleService extends ChangeNotifier {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal();

  AppLanguage _currentLanguage = AppLanguage.arabic;

  AppLanguage get currentLanguage => _currentLanguage;
  bool get isArabic => _currentLanguage == AppLanguage.arabic;
  Locale get locale => Locale(_currentLanguage.code);
  TextDirection get textDirection => _currentLanguage.direction;

  void toggleLanguage() {
    _currentLanguage = _currentLanguage == AppLanguage.arabic ? AppLanguage.english : AppLanguage.arabic;
    notifyListeners();
  }

  void setLanguage(AppLanguage language) {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      notifyListeners();
    }
  }

  /// Translation Lookup Helper with Safe Fallback
  String tr(String key) {
    return _translations[key]?[_currentLanguage.code] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    // ==========================================
    // ONBOARDING FLOW
    // ==========================================
    'onboarding_title_1': {'ar': 'اكتشف نخبة العيادات', 'en': 'Discover Elite Clinics'},
    'onboarding_desc_1': {
      'ar': 'اكتشف أفضل عيادات التجميل والجلدية في الإمارات مع استعراض شامل للأطباء والخدمات المعتمدة.',
      'en': 'Discover top aesthetic and dermatology clinics in the UAE with comprehensive certified doctors and services.'
    },
    'onboarding_title_2': {'ar': 'قارن العروض الحصرية', 'en': 'Compare Exclusive Offers'},
    'onboarding_desc_2': {
      'ar': 'تصفح باقات وعروض التجميل المميزة واختر ما يناسبك بسهولة وشفافية تامة.',
      'en': 'Browse exclusive aesthetic packages and choose what suits you with complete clarity.'
    },
    'onboarding_title_3': {'ar': 'تواصل بثقة وسرية', 'en': 'Connect with Confidence'},
    'onboarding_desc_3': {
      'ar': 'أرسل طلب استشارة مجاني ودع فريق العيادة المختص يتواصل معك مباشرة لتنسيق كافة التفاصيل.',
      'en': 'Send a free consultation lead and let the clinic concierge contact you directly to coordinate all details.'
    },
    'onboarding_skip': {'ar': 'تخطي', 'en': 'Skip'},
    'onboarding_next': {'ar': 'التالي', 'en': 'Next'},
    'onboarding_start': {'ar': 'ابدأ الآن', 'en': 'Get Started'},

    // ==========================================
    // AUTHENTICATION FLOW
    // ==========================================
    'login_title': {'ar': 'تسجيل الدخول', 'en': 'Sign In'},
    'login_sub': {'ar': 'أهلاً بك مجدداً في منصة AESTHETIC WAY', 'en': 'Welcome back to AESTHETIC WAY'},
    'identifier_label': {'ar': 'رقم الهاتف أو البريد الإلكتروني', 'en': 'Phone Number or Email'},
    'identifier_hint': {'ar': '50 123 4567 أو name@domain.com', 'en': '50 123 4567 or name@domain.com'},
    'password_label': {'ar': 'كلمة المرور', 'en': 'Password'},
    'password_hint': {'ar': '••••••••', 'en': '••••••••'},
    'confirm_password_label': {'ar': 'تأكيد كلمة المرور', 'en': 'Confirm Password'},
    'forgot_password_link': {'ar': 'نسيت كلمة المرور؟', 'en': 'Forgot Password?'},
    'dont_have_account': {'ar': 'ليس لديك حساب؟', 'en': 'Don\'t have an account?'},
    'create_account_link': {'ar': 'إنشاء حساب جديد', 'en': 'Create Account'},
    'continue_as_guest': {'ar': 'المتابعة كزائر', 'en': 'Continue as Guest'},

    'register_title': {'ar': 'إنشاء حساب جديد', 'en': 'Create Account'},
    'register_sub': {'ar': 'انضم إلى مجتمع AESTHETIC WAY واستفد من تجربة مخصصة', 'en': 'Join AESTHETIC WAY and enjoy a tailored luxury experience'},
    'already_have_account': {'ar': 'لديك حساب بالفعل؟', 'en': 'Already have an account?'},
    'sign_in_link': {'ar': 'تسجيل الدخول', 'en': 'Sign In'},
    'terms_agreement': {
      'ar': 'أوافق على شروط الاستخدام وسياسة الخصوصية لمنصة Aesthetic Way',
      'en': 'I agree to the Terms of Use and Privacy Policy of Aesthetic Way'
    },

    'otp_title': {'ar': 'رمز التحقق (OTP)', 'en': 'Verification Code'},
    'otp_sub': {'ar': 'أرسلنا رمز التحقق المكون من 4 أرقام إلى', 'en': 'We sent a 4-digit verification code to'},
    'otp_box_hint': {'ar': 'أدخل الرمز المكون من 4 خانات', 'en': 'Enter the 4-digit code'},
    'resend_code': {'ar': 'إعادة إرسال الرمز', 'en': 'Resend Code'},
    'resend_in': {'ar': 'إعادة الإرسال خلال', 'en': 'Resend in'},
    'verify_and_continue': {'ar': 'تأكيد الرمز والمتابعة', 'en': 'Verify & Continue'},
    'otp_demo_note': {'ar': '💡 للتجربة السريعة: رمز التحقق هو 1234', 'en': '💡 Demo note: Test OTP code is 1234'},

    'forgot_title': {'ar': 'استعادة كلمة المرور', 'en': 'Forgot Password'},
    'forgot_sub': {'ar': 'أدخل رقم هاتفك أو بريدك المسجل لإرسال رمز التحقق والاستعادة', 'en': 'Enter your registered phone or email to receive a recovery code'},
    'send_reset_code': {'ar': 'إرسال رمز الاستعادة', 'en': 'Send Recovery Code'},
    'back_to_login': {'ar': 'العودة لتسجيل الدخول', 'en': 'Back to Sign In'},

    'reset_title': {'ar': 'تعيين كلمة المرور الجديدة', 'en': 'Set New Password'},
    'reset_sub': {'ar': 'أدخل كلمة مرور جديدة وقوية لتسجيل الدخول إلى حسابك', 'en': 'Enter a strong new password to access your account'},
    'new_password_label': {'ar': 'كلمة المرور الجديدة', 'en': 'New Password'},
    'confirm_new_password_label': {'ar': 'تأكيد كلمة المرور الجديدة', 'en': 'Confirm New Password'},
    'save_password_btn': {'ar': 'حفظ كلمة المرور والدخول', 'en': 'Save Password & Sign In'},
    'password_reset_success': {'ar': 'تم تحديث كلمة المرور بنجاح! يمكنك الآن تسجيل الدخول', 'en': 'Password reset successfully! You can now sign in'},

    // Validation Messages
    'val_identifier_required': {'ar': 'يرجى إدخال رقم الهاتف أو البريد الإلكتروني', 'en': 'Please enter phone number or email'},
    'val_name_required': {'ar': 'يرجى إدخال الاسم الكامل', 'en': 'Please enter your full name'},
    'val_phone_required': {'ar': 'يرجى إدخال رقم هاتف إماراتي صالح', 'en': 'Please enter a valid UAE phone number'},
    'val_email_invalid': {'ar': 'يرجى إدخال بريد إلكتروني صالح', 'en': 'Please enter a valid email address'},
    'val_password_short': {'ar': 'كلمة المرور يجب أن لا تقل عن 6 خانات', 'en': 'Password must be at least 6 characters'},
    'val_password_mismatch': {'ar': 'كلمات المرور غير متطابقة', 'en': 'Passwords do not match'},
    'val_terms_required': {'ar': 'يرجى الموافقة على شروط الاستخدام والخصوصية', 'en': 'Please agree to Terms of Use & Privacy Policy'},
    'val_otp_invalid': {'ar': 'رمز التحقق غير صحيح، يرجى إدخال 1234', 'en': 'Invalid code. Please enter 1234 for demo'},

    // Navigation
    'nav_home': {'ar': 'الرئيسية', 'en': 'Home'},
    'nav_clinics': {'ar': 'العيادات', 'en': 'Clinics'},
    'nav_requests': {'ar': 'طلباتي', 'en': 'Requests'},
    'nav_profile': {'ar': 'حسابي', 'en': 'Profile'},

    // Header & Search
    'search_hint': {'ar': 'ابحث عن عيادة، طبيب، علاج (بوتاكس، ليزر)...', 'en': 'Search clinic, doctor, treatment...'},
    'select_city': {'ar': 'اختر الإمارة', 'en': 'Select Emirate'},
    'city_all': {'ar': 'الكل (الإمارات)', 'en': 'All (UAE)'},
    'city_dubai': {'ar': 'دبي', 'en': 'Dubai'},
    'city_abudhabi': {'ar': 'أبوظبي', 'en': 'Abu Dhabi'},
    'filter_button': {'ar': 'فلترة', 'en': 'Filter'},

    // Badges & Labels
    'vip_partner': {'ar': '👑 شريك ماسي VIP', 'en': '👑 VIP Partner'},
    'featured_badge': {'ar': '✨ إعلان مميز', 'en': '✨ Featured'},
    'role_doctor': {'ar': 'طبيب', 'en': 'Doctor'},
    'role_nurse': {'ar': 'ممرض مرخص', 'en': 'Licensed Nurse'},
    'role_specialist': {'ar': 'أخصائي مرخص', 'en': 'Licensed Specialist'},
    'unit_km': {'ar': 'كم', 'en': 'km'},
    'currency_aed': {'ar': 'د.إ', 'en': 'AED'},
    'whatsapp_btn': {'ar': 'واتساب', 'en': 'WhatsApp'},
    'call_btn': {'ar': 'اتصال', 'en': 'Call'},
    'map_google': {'ar': 'خرائط Google', 'en': 'Google Maps'},
    'save_prefix': {'ar': 'خصم', 'en': 'SAVE'},
    'days_left': {'ar': 'أيام متبقية', 'en': 'days left'},
    'years_exp': {'ar': 'سنوات خبرة', 'en': 'years exp'},
    'procedures_title': {'ar': 'أبرز الإجراءات الطبية', 'en': 'Key Medical Procedures'},
    'languages_spoken': {'ar': 'اللغات', 'en': 'Languages'},
    'about_doctor': {'ar': 'نبذة عن الممارس', 'en': 'About Practitioner'},
    'duration_label': {'ar': 'المدة المتوقعة', 'en': 'Duration'},
    'downtime_label': {'ar': 'فترة التعافي', 'en': 'Downtime'},
    'target_area_label': {'ar': 'المنطقة المستهدفة', 'en': 'Target Area'},
    'available_in_clinics': {'ar': 'متوفر في', 'en': 'Available in'},
    'clinics_count_suffix': {'ar': 'عيادة مرخصة', 'en': 'licensed clinics'},
    'terms_conditions': {'ar': 'الشروط والأحكام', 'en': 'Terms & Conditions'},
    'valid_until': {'ar': 'صلاحية العرض', 'en': 'Validity'},

    // Featured Ads & Home Sections
    'featured_partners': {'ar': 'نخبة الشركاء والعيادات المميزة', 'en': 'Featured & VIP Elite Clinics'},
    'categories_title': {'ar': 'التصنيفات والخدمات', 'en': 'Categories & Services'},
    'nearby_title': {'ar': 'عيادات موثوقة في منطقتك', 'en': 'Verified Clinics Nearby'},
    'active_offers': {'ar': 'الباقات والعروض الحصرية', 'en': 'Exclusive Offers & Packages'},
    'view_map': {'ar': 'الخريطة', 'en': 'Map'},
    'map_view': {'ar': 'عرض الخريطة', 'en': 'Map View'},
    'directions': {'ar': 'الاتجاهات', 'en': 'Directions'},
    'contact_btn': {'ar': 'تواصل', 'en': 'Contact'},
    'request_appointment': {'ar': 'طلب موعد', 'en': 'Request Lead'},
    'request_consultation': {'ar': 'طلب موعد استشارة', 'en': 'Request Consultation'},

    // 8 OFFICIAL CATEGORIES
    'cat_all': {'ar': 'جميع الخدمات', 'en': 'All Services'},
    'cat_offers': {'ar': 'العروض', 'en': 'Offers'},
    'cat_treatments': {'ar': 'العلاجات', 'en': 'Treatments'},
    'cat_doctors': {'ar': 'الأطباء', 'en': 'Doctors'},
    'cat_skin_experts': {'ar': 'خبيرات البشرة', 'en': 'Skin Experts'},
    'cat_surgery': {'ar': 'الجراحة التجميلية', 'en': 'Plastic Surgery'},
    'cat_products': {'ar': 'المنتجات', 'en': 'Products'},
    'cat_articles': {'ar': 'المقالات', 'en': 'Articles'},
    'cat_clinics': {'ar': 'العيادات', 'en': 'Clinics'},

    // Clinic Profile Tabs & Details
    'tab_about': {'ar': 'نبذة والموقع', 'en': 'About & Map'},
    'tab_staff': {'ar': 'الكادر الطبي', 'en': 'Medical Staff'},
    'tab_treatments': {'ar': 'العلاجات والخدمات', 'en': 'Treatments'},
    'tab_offers': {'ar': 'العروض', 'en': 'Offers'},
    'tab_reviews': {'ar': 'التقييمات', 'en': 'Reviews'},
    'about_clinic': {'ar': 'عن العيادة', 'en': 'About Clinic'},
    'working_hours': {'ar': 'ساعات العمل', 'en': 'Working Hours'},
    'geo_location': {'ar': 'الموقع الجغرافي و Google Maps', 'en': 'Location & Google Maps'},
    'open_in_maps': {'ar': 'فتح في Google Maps', 'en': 'Open in Google Maps'},
    'branches_in_uae': {'ar': 'فروع العيادة في الإمارات', 'en': 'UAE Clinic Branches'},
    'request_with_doctor': {'ar': 'طلب موعد مع الممارس', 'en': 'Request Lead with Practitioner'},
    'offer_claim': {'ar': 'طلب بالعرض', 'en': 'Claim Offer'},
    'verified_visit': {'ar': 'زيارة موثقة', 'en': 'Verified Visit'},
    'reviews_summary': {'ar': 'تقييم Google موثوق مبني على زيارات المرضى', 'en': 'Verified Google rating based on patient visits'},
    'google_rating': {'ar': 'تقييم Google', 'en': 'Google Rating'},

    // Filter Sheet
    'filter_title': {'ar': 'تصفية وبحث متقدم', 'en': 'Advanced Filters'},
    'filter_city': {'ar': 'الإمارة / المدينة', 'en': 'Emirate / City'},
    'filter_specialty': {'ar': 'التخصص الطبي', 'en': 'Specialty'},
    'filter_practitioner_type': {'ar': 'نوع الممارس', 'en': 'Practitioner Type'},
    'filter_sort': {'ar': 'ترتيب النتائج', 'en': 'Sort By'},
    'sort_featured': {'ar': 'المميز والـ VIP أولاً', 'en': 'VIP & Featured First'},
    'sort_rating': {'ar': 'الأعلى تقييماً', 'en': 'Highest Rated'},
    'sort_distance': {'ar': 'الأقرب مسافة', 'en': 'Nearest Distance'},
    'apply_filters': {'ar': 'تطبيق الفلاتر', 'en': 'Apply Filters'},
    'reset_filters': {'ar': 'إعادة ضبط', 'en': 'Reset'},

    // Appointment Request (Lead Form) & Time Slots
    'lead_form_title': {'ar': 'طلب موعد استشارة', 'en': 'Request Consultation Lead'},
    'select_branch': {'ar': 'فرع العيادة المطلوب', 'en': 'Selected Branch'},
    'select_service': {'ar': 'الخدمة أو العلاج المطلوب', 'en': 'Requested Service'},
    'select_practitioner': {'ar': 'الممارس المفضل (اختياري)', 'en': 'Preferred Practitioner (Optional)'},
    'any_practitioner': {'ar': 'أي ممارس متاح في العيادة', 'en': 'Any available practitioner'},
    'preferred_datetime': {'ar': 'الموعد والفترة الزمنية المفضلة', 'en': 'Preferred Date & Time Window'},
    'time_morning': {'ar': 'صباحاً (9 ص - 1 م)', 'en': 'Morning (9 AM - 1 PM)'},
    'time_afternoon': {'ar': 'ظهراً (1 م - 5 م)', 'en': 'Afternoon (1 PM - 5 PM)'},
    'time_evening': {'ar': 'مساءً (5 م - 9 م)', 'en': 'Evening (5 PM - 9 PM)'},
    'period_morning': {'ar': 'صباحاً (9 ص - 1 م)', 'en': 'Morning (9 AM - 1 PM)'},
    'period_afternoon': {'ar': 'ظهراً (1 م - 5 م)', 'en': 'Afternoon (1 PM - 5 PM)'},
    'period_evening': {'ar': 'مساءً (5 م - 9 م)', 'en': 'Evening (5 PM - 9 PM)'},
    'contact_info_title': {'ar': 'بيانات التواصل / المريض', 'en': 'Contact Info'},
    'patient_details': {'ar': 'بيانات المريض / العميل', 'en': 'Patient Details'},
    'full_name': {'ar': 'الاسم الكامل', 'en': 'Full Name'},
    'name_hint': {'ar': 'أدخل اسمك الكامل', 'en': 'Enter your full name'},
    'phone_uae': {'ar': 'رقم الهاتف (الإمارات)', 'en': 'Phone Number (UAE)'},
    'phone_number': {'ar': 'رقم الهاتف (الإمارات)', 'en': 'Phone Number (UAE)'},
    'phone_hint': {'ar': '50 123 4567', 'en': '50 123 4567'},
    'email_address': {'ar': 'البريد الإلكتروني', 'en': 'Email Address'},
    'email_hint': {'ar': 'example@email.com', 'en': 'example@email.com'},
    'notes_opt': {'ar': 'ملاحظات إضافية (اختياري)', 'en': 'Notes (Optional)'},
    'notes_optional': {'ar': 'ملاحظات إضافية أو استفسار (اختياري)', 'en': 'Additional Notes / Questions (Optional)'},
    'notes_hint': {'ar': 'اكتب أي تفاصيل ترغب بمشاركتها مع العيادة...', 'en': 'Write any details you wish to share...'},
    'consent_text': {
      'ar': 'أوافق على مشاركة هذه البيانات مع العيادة المحددة للتواصل معي هاتفياً أو عبر الواتساب لتنسيق الاستشارة، وأقر بالاطلاع على شروط الاستخدام والخصوصية.',
      'en': 'I agree to share these details with the selected clinic to contact me via phone or WhatsApp to coordinate my consultation, and I accept the terms of use and privacy policy.'
    },
    'submit_lead_btn': {'ar': 'إرسال طلب الموعد للعيادة', 'en': 'Send Consultation Request'},

    // FROZEN STRICT SUCCESS COPY (Core Rule)
    'lead_success_title': {'ar': 'تم إرسال طلبك بنجاح!', 'en': 'Request Sent Successfully!'},
    'lead_success_body': {
      'ar': 'تم إرسال طلبك وستتواصل العيادة معك',
      'en': 'Your request has been sent and the clinic will contact you'
    },
    'lead_summary_title': {'ar': 'ملخص تفاصيل الطلب', 'en': 'Lead Request Summary'},
    'ref_number': {'ar': 'رقم المرجع', 'en': 'Reference No.'},
    'clinic_label': {'ar': 'العيادة', 'en': 'Clinic'},
    'branch_label': {'ar': 'الفرع', 'en': 'Branch'},
    'service_label': {'ar': 'الخدمة / الإجراء', 'en': 'Service / Treatment'},
    'practitioner_label': {'ar': 'الممارس الطبي', 'en': 'Practitioner'},
    'date_label': {'ar': 'التاريخ المفضل', 'en': 'Preferred Date'},
    'period_label': {'ar': 'الفترة', 'en': 'Time Window'},
    'patient_label': {'ar': 'المريض', 'en': 'Patient'},
    'phone_label': {'ar': 'الهاتف', 'en': 'Phone'},
    'open_maps_btn': {'ar': 'فتح موقع العيادة في Google Maps', 'en': 'Open Location in Google Maps'},
    'back_home': {'ar': 'العودة إلى الرئيسية', 'en': 'Back to Home'},

    // My Requests (Lead Tracking)
    'my_requests_title': {'ar': 'طلبات المواعيد والاستشارات', 'en': 'Appointment Leads'},
    'status_all': {'ar': 'الكل', 'en': 'All'},
    'status_sent': {'ar': 'تم الإرسال', 'en': 'Sent'},
    'status_contacted': {'ar': 'تم التواصل', 'en': 'Contacted'},
    'status_closed': {'ar': 'مكتمل / مغلق', 'en': 'Closed'},
    'no_requests': {'ar': 'لا توجد طلبات مواعيد مسجلة حالياً', 'en': 'No appointment leads yet'},
    'no_requests_sub': {'ar': 'تصفح العيادات وأرسل طلب استشارة لتظهر هنا', 'en': 'Explore clinics and request a lead to track it here'},
    'status_sent_label': {'ar': '🟡 بانتظار تواصل العيادة', 'en': '🟡 Awaiting Clinic Response'},
    'status_contacted_label': {'ar': '🔵 تم التواصل من العيادة', 'en': '🔵 Contacted by Clinic'},
    'status_closed_label': {'ar': '⚪ طلب مكتمل / منتهي', 'en': '⚪ Closed / Completed'},

    // Profile & Settings
    'profile_title': {'ar': 'حسابي وإعداداتي', 'en': 'My Profile & Settings'},
    'app_language': {'ar': 'لغة التطبيق', 'en': 'App Language'},
    'switch_language': {'ar': 'English ⇄', 'en': 'العربية ⇄'},
    'theme_title': {'ar': 'مظهر التطبيق', 'en': 'App Theme'},
    'theme_dark': {'ar': 'الوضع الداكن (Dark)', 'en': 'Dark Mode'},
    'theme_light': {'ar': 'الوضع الفاتح (Light)', 'en': 'Light Mode'},
    'theme_system': {'ar': 'تلقائي (حسب النظام)', 'en': 'System Mode'},
    'my_favs': {'ar': 'العيادات المفضلة', 'en': 'Favorite Clinics'},
    'privacy_terms': {'ar': 'الخصوصية والترخيص القانوني', 'en': 'Privacy & Legal Licensing'},
    'support_help': {'ar': 'الدعم والكونسيرج', 'en': 'Support & Concierge'},
    'guest_status': {'ar': 'زائر (تصفح فقط)', 'en': 'Guest User (Browse Mode)'},
    'logged_in_status': {'ar': 'مستخدم موثق', 'en': 'Verified Member'},
    'login_prompt': {'ar': 'سجّل رقمك لحفظ المفضلة ومتابعة الطلبات', 'en': 'Login to save favorites and track leads'},
    'login_btn': {'ar': 'تسجيل الدخول / إنشاء حساب', 'en': 'Login / Register'},
    'logout_btn': {'ar': 'تسجيل الخروج', 'en': 'Sign Out'},

    // Compliance & Privacy Modal Text
    'privacy_sheet_title': {'ar': 'الخصوصية والترخيص القانوني', 'en': 'Privacy & Legal Licensing'},
    'privacy_sheet_text': {
      'ar': 'منصة Aesthetic Way — رقم الترخيص: [LICENSE_PLACEHOLDER].\n\nتعتبر منصة Aesthetic Way أداة رقمية وتطبيقاً للربط والتسهيل بين المرضى والعملاء وبين العيادات والمراكز الطبية المعتمدة في دولة الإمارات العربية المتحدة. تتم كافة الاستشارات والتشخيصات والإجراءات الطبية والتواصل المباشر عبر الكوادر الطبية والعيادات المرخصة حصراً، وتلتزم المنصة بحماية وسرية بيانات المستخدمين.',
      'en': 'Aesthetic Way Platform — License: [LICENSE_PLACEHOLDER].\n\nAesthetic Way is a premier discovery and connection platform facilitating seamless appointment leads between patients and certified aesthetic medical clinics in the UAE. All medical consultations, assessments, and procedures are handled directly by the licensed clinic or medical practitioner. User privacy and data protection are strictly upheld.'
    },

    // Concierge & Support Sheet Text
    'concierge_title': {'ar': 'خدمة العملاء والكونسيرج', 'en': 'Concierge & Client Support'},
    'concierge_desc': {'ar': 'يسعد فريق كونسيرج Aesthetic Way بمساعدتك في اختيار أفضل العيادات والإجابة عن استفساراتك اليومية.', 'en': 'Our Aesthetic Way Concierge is delighted to assist you in discovering top clinics and answering your inquiries.'},
    'whatsapp_concierge': {'ar': 'محادثة فورية عبر الواتساب', 'en': 'Live Chat on WhatsApp'},
    'call_concierge': {'ar': 'الاتصال بالرقم المجاني الموحد', 'en': 'Call Free Support Line'},
    'contact_options_title': {'ar': 'خيارات التواصل المباشر مع العيادة', 'en': 'Direct Contact Options'},
    'reception_call': {'ar': 'اتصال فوري بالاستقبال', 'en': 'Call Reception'},
    'location_directions': {'ar': 'الاتجاهات عبر خرائط Google', 'en': 'Directions on Google Maps'},
    'license_verified': {'ar': 'ترخيص معتمد: [LICENSE_PLACEHOLDER]', 'en': 'Verified License: [LICENSE_PLACEHOLDER]'},
  };
}
