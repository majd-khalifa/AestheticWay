import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  static const String storageKey = 'aw_pref_locale';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Default on first launch (when no saved preference exists) is English (LTR)
  AppLanguage _currentLanguage = AppLanguage.english;

  AppLanguage get currentLanguage => _currentLanguage;
  bool get isArabic => _currentLanguage == AppLanguage.arabic;
  bool get isEnglish => _currentLanguage == AppLanguage.english;
  Locale get locale => Locale(_currentLanguage.code);
  TextDirection get textDirection => _currentLanguage.direction;

  /// Restores persisted language choice; defaults to English (LTR) when unset.
  Future<void> init() async {
    try {
      final savedCode = await _storage.read(key: storageKey);
      if (savedCode == AppLanguage.arabic.code) {
        _currentLanguage = AppLanguage.arabic;
      } else if (savedCode == AppLanguage.english.code) {
        _currentLanguage = AppLanguage.english;
      } else {
        _currentLanguage = AppLanguage.english;
      }
      notifyListeners();
    } catch (_) {
      _currentLanguage = AppLanguage.english;
    }
  }

  Future<void> toggleLanguage() async {
    _currentLanguage = _currentLanguage == AppLanguage.arabic
        ? AppLanguage.english
        : AppLanguage.arabic;
    notifyListeners();
    await _persistLanguage(_currentLanguage);
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      notifyListeners();
    }
    await _persistLanguage(language);
  }

  Future<void> _persistLanguage(AppLanguage language) async {
    try {
      await _storage.write(key: storageKey, value: language.code);
    } catch (_) {}
  }

  /// Translation Lookup Helper with Safe Fallback
  String tr(String key) {
    return _translations[key]?[_currentLanguage.code] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'load_more': {'ar': 'عرض المزيد', 'en': 'Load more'},
    'view_all': {'ar': 'عرض الكل', 'en': 'View all'},
    'retry': {'ar': 'إعادة المحاولة', 'en': 'Retry'},

    'about_doctor_title': {
      'ar': 'عن الممارس الصحي',
      'en': 'About the Practitioner',
    },
    'performed_procedures_title': {
      'ar': 'العلاجات والإجراءات',
      'en': 'Treatments & Procedures',
    },
    'submitted_at': {'ar': 'تاريخ إرسال الطلب', 'en': 'Request Submitted'},
    'admin_clinic_search_hint': {
      'ar': 'ابحث باسم العيادة أو المعرّف (Slug)...',
      'en': 'Search by clinic name or slug...',
    },

    // ==========================================
    // ONBOARDING FLOW
    // ==========================================
    'onboarding_title_1': {
      'ar': 'عيادات التجميل والجلدية',
      'en': 'Aesthetic & Dermatology Clinics',
    },
    'onboarding_desc_1': {
      'ar':
          'عيادات التجميل والجلدية في الإمارات أصبحت بين يديك بالإضافة لكثير من الأطباء وخبراء البشرة',
      'en':
          'Aesthetic and dermatology clinics in the UAE are now at your fingertips, along with many doctors and skin experts',
    },
    'onboarding_title_2': {
      'ar': 'استعراض العروض والباقات',
      'en': 'Explore Offers & Packages',
    },
    'onboarding_desc_2': {
      'ar':
          'تصفح باقات وعروض التجميل المتاحة في العيادات مع تفاصيل واضحة للأسعار والخدمات.',
      'en':
          'Browse available aesthetic treatment packages with transparent pricing and service details.',
    },
    'onboarding_title_3': {
      'ar': 'طلب تواصل واستشارة',
      'en': 'Direct Lead Request',
    },
    'onboarding_desc_3': {
      'ar':
          'أرسل طلب استشارة بكل سهولة لتقوم العيادة المختارة بالتواصل معك مباشرة ومتابعة طلبك.',
      'en':
          'Send a consultation lead easily for the clinic team to contact you directly.',
    },
    'onboarding_skip': {'ar': 'تخطي', 'en': 'Skip'},
    'onboarding_next': {'ar': 'التالي', 'en': 'Next'},
    'onboarding_start': {'ar': 'ابدأ الآن', 'en': 'Get Started'},

    // ==========================================
    // AUTHENTICATION FLOW
    // ==========================================
    'login_title': {'ar': 'تسجيل الدخول', 'en': 'Sign In'},
    'login_sub': {
      'ar': 'أهلاً بك مجدداً في منصة AESTHETIC WAY',
      'en': 'Welcome back to AESTHETIC WAY',
    },
    'identifier_label': {
      'ar': 'رقم الهاتف أو البريد الإلكتروني',
      'en': 'Phone Number or Email',
    },
    'identifier_hint': {
      'ar': '50 123 4567 أو name@domain.com',
      'en': '50 123 4567 or name@domain.com',
    },
    'password_label': {'ar': 'كلمة المرور', 'en': 'Password'},
    'password_hint': {'ar': '••••••••', 'en': '••••••••'},
    'confirm_password_label': {
      'ar': 'تأكيد كلمة المرور',
      'en': 'Confirm Password',
    },
    'forgot_password_link': {
      'ar': 'نسيت كلمة المرور؟',
      'en': 'Forgot Password?',
    },
    'dont_have_account': {
      'ar': 'ليس لديك حساب؟',
      'en': 'Don\'t have an account?',
    },
    'create_account_link': {'ar': 'إنشاء حساب جديد', 'en': 'Create Account'},
    'continue_as_guest': {'ar': 'المتابعة كزائر', 'en': 'Continue as Guest'},

    'register_title': {'ar': 'إنشاء حساب جديد', 'en': 'Create Account'},
    'register_sub': {
      'ar': 'انضم إلى مجتمع AESTHETIC WAY واستفد من تجربة مخصصة',
      'en': 'Join AESTHETIC WAY and enjoy a tailored luxury experience',
    },
    'already_have_account': {
      'ar': 'لديك حساب بالفعل؟',
      'en': 'Already have an account?',
    },
    'sign_in_link': {'ar': 'تسجيل الدخول', 'en': 'Sign In'},
    'terms_agreement': {
      'ar': 'أوافق على شروط الاستخدام وسياسة الخصوصية لمنصة Aesthetic Way',
      'en': 'I agree to the Terms of Use and Privacy Policy of Aesthetic Way',
    },

    'otp_title': {'ar': 'رمز التحقق (OTP)', 'en': 'Verification Code'},
    'otp_sub': {
      'ar': 'أرسلنا رمز التحقق المكون من 4 أرقام إلى',
      'en': 'We sent a 4-digit verification code to',
    },
    'otp_box_hint': {
      'ar': 'أدخل الرمز المكون من 4 خانات',
      'en': 'Enter the 4-digit code',
    },
    'resend_code': {'ar': 'إعادة إرسال الرمز', 'en': 'Resend Code'},
    'resend_in': {'ar': 'إعادة الإرسال خلال', 'en': 'Resend in'},
    'verify_and_continue': {
      'ar': 'تأكيد الرمز والمتابعة',
      'en': 'Verify & Continue',
    },
    'otp_demo_note': {
      'ar': 'للتجربة السريعة: رمز التحقق هو 1234',
      'en': 'Demo note: Test OTP code is 1234',
    },

    'forgot_title': {'ar': 'استعادة كلمة المرور', 'en': 'Forgot Password'},
    'forgot_sub': {
      'ar': 'أدخل رقم هاتفك أو بريدك المسجل لإرسال رمز التحقق والاستعادة',
      'en': 'Enter your registered phone or email to receive a recovery code',
    },
    'send_reset_code': {
      'ar': 'إرسال رمز الاستعادة',
      'en': 'Send Recovery Code',
    },
    'back_to_login': {'ar': 'العودة لتسجيل الدخول', 'en': 'Back to Sign In'},

    'reset_title': {
      'ar': 'تعيين كلمة المرور الجديدة',
      'en': 'Set New Password',
    },
    'reset_sub': {
      'ar': 'أدخل كلمة مرور جديدة وقوية لتسجيل الدخول إلى حسابك',
      'en': 'Enter a strong new password to access your account',
    },
    'new_password_label': {'ar': 'كلمة المرور الجديدة', 'en': 'New Password'},
    'confirm_new_password_label': {
      'ar': 'تأكيد كلمة المرور الجديدة',
      'en': 'Confirm New Password',
    },
    'save_password_btn': {
      'ar': 'حفظ كلمة المرور والدخول',
      'en': 'Save Password & Sign In',
    },
    'password_reset_success': {
      'ar': 'تم تحديث كلمة المرور بنجاح! يمكنك الآن تسجيل الدخول',
      'en': 'Password reset successfully! You can now sign in',
    },

    // Validation Messages
    'val_identifier_required': {
      'ar': 'يرجى إدخال رقم الهاتف أو البريد الإلكتروني',
      'en': 'Please enter phone number or email',
    },
    'val_name_required': {
      'ar': 'يرجى إدخال الاسم الكامل',
      'en': 'Please enter your full name',
    },
    'val_phone_required': {
      'ar': 'يرجى إدخال رقم هاتف إماراتي صالح',
      'en': 'Please enter a valid UAE phone number',
    },
    'val_email_invalid': {
      'ar': 'يرجى إدخال بريد إلكتروني صالح',
      'en': 'Please enter a valid email address',
    },
    'val_password_short': {
      'ar': 'كلمة المرور يجب ألا تقل عن 8 أحرف',
      'en': 'Password must be at least 8 characters',
    },
    'val_password_mismatch': {
      'ar': 'كلمات المرور غير متطابقة',
      'en': 'Passwords do not match',
    },
    'val_terms_required': {
      'ar': 'يرجى الموافقة على شروط الاستخدام والخصوصية',
      'en': 'Please agree to Terms of Use & Privacy Policy',
    },
    'val_otp_invalid': {
      'ar': 'رمز التحقق غير صحيح، يرجى التأكد وإعادة المحاولة',
      'en': 'Invalid verification code, please check and try again',
    },

    // ==========================================
    // CLINIC PORTAL (ROLE العيادة)
    // ==========================================
    'clinic_portal_title': {
      'ar': 'لوحة تحكم الشريك والعيادة',
      'en': 'Clinic Partner Portal',
    },
    'clinic_login_btn': {
      'ar': 'دخول الشركاء والعيادات',
      'en': 'Clinic Partner Login',
    },
    'clinic_demo_login': {
      'ar': 'دخول تجريبي: عيادة كايا للجلدية',
      'en': 'Demo Clinic: Kaya Skin Clinic',
    },
    'clinic_nav_dashboard': {'ar': 'الرئيسية', 'en': 'Dashboard'},
    'clinic_nav_leads': {'ar': 'الطلبات', 'en': 'Leads'},
    'clinic_nav_offers': {'ar': 'العروض', 'en': 'Offers'},
    'clinic_nav_profile': {'ar': 'الملف', 'en': 'Profile'},

    'clinic_new_leads_count': {'ar': 'طلبات جديدة', 'en': 'New Leads'},
    'clinic_today_leads': {'ar': 'طلبات اليوم', 'en': 'Today\'s Leads'},
    'clinic_total_leads': {'ar': 'إجمالي الطلبات', 'en': 'Total Leads'},
    'clinic_active_offers_count': {'ar': 'عروض نشطة', 'en': 'Active Offers'},
    'clinic_sub_tier_label': {
      'ar': 'باقة الاشتراك الحالية',
      'en': 'Subscription Tier',
    },
    'clinic_quick_actions': {'ar': 'إجراءات سريعة', 'en': 'Quick Actions'},
    'clinic_btn_view_new_leads': {
      'ar': 'عرض الطلبات الجديدة',
      'en': 'View New Leads',
    },
    'clinic_btn_add_offer': {'ar': 'إضافة عرض جديد', 'en': 'Add New Offer'},
    'clinic_btn_edit_profile': {
      'ar': 'تعديل بيانات العيادة',
      'en': 'Edit Profile',
    },
    'clinic_recent_leads': {
      'ar': 'أحدث طلبات الاستشارة الواردة',
      'en': 'Recent Consultation Leads',
    },

    'clinic_lead_status_new': {'ar': 'جديد', 'en': 'New'},
    'clinic_lead_status_contacted': {'ar': 'تم التواصل', 'en': 'Contacted'},
    'clinic_lead_status_closed': {'ar': 'مكتمل / مغلق', 'en': 'Closed'},
    'clinic_lead_source': {
      'ar': 'المصدر: تطبيق AESTHETIC WAY',
      'en': 'Source: AESTHETIC WAY App',
    },
    'clinic_lead_call': {'ar': 'اتصال بالمريض', 'en': 'Call Patient'},
    'clinic_lead_whatsapp': {'ar': 'محادثة واتساب', 'en': 'WhatsApp Patient'},
    'clinic_change_status': {'ar': 'تغيير حالة الطلب', 'en': 'Change Status'},
    'clinic_internal_notes': {
      'ar': 'ملاحظات العيادة الداخلية',
      'en': 'Internal Clinic Notes',
    },
    'clinic_internal_notes_hint': {
      'ar':
          'اكتب ملاحظات داخلية لمتابعة هذا الطلب (مثل: تم الاتصال وتحديد موعد خارجي)...',
      'en': 'Write internal tracking notes for this lead...',
    },
    'clinic_save_notes': {'ar': 'حفظ الملاحظات', 'en': 'Save Notes'},
    'clinic_notes_saved': {
      'ar': 'تم حفظ الملاحظات بنجاح',
      'en': 'Notes saved successfully',
    },
    'clinic_status_updated': {
      'ar': 'تم تحديث حالة الطلب بنجاح',
      'en': 'Lead status updated successfully',
    },
    'clinic_no_leads': {
      'ar': 'لا توجد طلبات استشارة واردة في هذا القسم',
      'en': 'No incoming consultation leads in this section',
    },
    'clinic_no_offers': {
      'ar': 'لا توجد عروض مضافة حالياً',
      'en': 'No treatment offers added yet',
    },

    'clinic_add_offer_title': {
      'ar': 'إضافة باقة / عرض تجميلي',
      'en': 'Add Treatment Offer',
    },
    'clinic_edit_offer_title': {
      'ar': 'تعديل تفاصيل العرض',
      'en': 'Edit Offer Details',
    },
    'clinic_offer_title_field': {
      'ar': 'عنوان العرض / الباقة',
      'en': 'Offer Title',
    },
    'clinic_offer_desc_field': {
      'ar': 'وصف مختصر للشروط والمزايا',
      'en': 'Short Description & Terms',
    },
    'clinic_offer_original_price': {
      'ar': 'السعر الأصلي (د.إ)',
      'en': 'Original Price (AED)',
    },
    'clinic_offer_discount_price': {
      'ar': 'سعر العرض المخفض (د.إ)',
      'en': 'Offer Price (AED)',
    },
    'clinic_offer_validity': {
      'ar': 'تاريخ انتهاء العرض',
      'en': 'Expiry Date Text',
    },
    'clinic_offer_active_toggle': {
      'ar': 'حالة العرض (مفعّل ونشط للعامة)',
      'en': 'Offer Status (Active to Public)',
    },
    'clinic_offer_save': {'ar': 'حفظ ونشر العرض', 'en': 'Save & Publish Offer'},
    'clinic_offer_saved_success': {
      'ar': 'تم حفظ العرض بنجاح في المنصة',
      'en': 'Offer saved successfully',
    },

    'clinic_team_title': {
      'ar': 'الكادر الطبي والممارسون المعتمدون',
      'en': 'Medical Staff & Practitioners',
    },
    'clinic_add_practitioner': {
      'ar': 'إضافة ممارس طبي جديد',
      'en': 'Add Practitioner',
    },
    'clinic_practitioner_name': {
      'ar': 'اسم الطبيب / الممارس (إلزامي)',
      'en': 'Practitioner Name (Required)',
    },
    'clinic_practitioner_specialty': {
      'ar': 'التخصص الطبي الدقيق (إلزامي)',
      'en': 'Specialty (Required)',
    },
    'clinic_doctor_years_exp': {
      'ar': 'سنوات الخبرة (اختياري)',
      'en': 'Years of Experience (Optional)',
    },
    'clinic_doctor_languages': {
      'ar': 'اللغات (مثال: العربية، الإنجليزية)',
      'en': 'Languages (e.g. Arabic, English)',
    },
    'clinic_doctor_bio': {
      'ar': 'نبذة تعريفية موجزة',
      'en': 'Short Professional Bio',
    },
    'clinic_doctor_license_ref': {
      'ar': 'الرمز المرجعي للاعتماد بالمنصة',
      'en': 'Platform License Reference',
    },
    'clinic_doctor_avatar_opt': {
      'ar': 'الصورة الشخصية للطبيب',
      'en': 'Doctor Profile Photo',
    },
    'clinic_practitioner_saved': {
      'ar': 'تمت إضافة الممارس بنجاح',
      'en': 'Practitioner added successfully',
    },

    'clinic_services_title': {
      'ar': 'العلاجات والخدمات المقدمة',
      'en': 'Services & Treatments',
    },
    'clinic_add_service': {'ar': 'إضافة خدمة علاجية', 'en': 'Add Service'},
    'clinic_service_name': {
      'ar': 'اسم الخدمة / الإجراء (إلزامي)',
      'en': 'Service / Procedure Name (Required)',
    },
    'clinic_service_category': {'ar': 'تصنيف الخدمة', 'en': 'Service Category'},
    'clinic_service_price': {
      'ar': 'السعر التقديري (د.إ)',
      'en': 'Estimated Price (AED)',
    },
    'clinic_service_duration': {
      'ar': 'المدة التقريبية (بالدقائق)',
      'en': 'Duration (Minutes)',
    },
    'clinic_service_description': {
      'ar': 'وصف مختصر للخدمة والشروط',
      'en': 'Short Description & Terms',
    },
    'clinic_service_target_area': {
      'ar': 'المنطقة المستهدفة (مثال: الوجه)',
      'en': 'Target Area (e.g. Face)',
    },
    'clinic_service_recovery': {
      'ar': 'فترة التعافي (مثال: بدون فترة توقف)',
      'en': 'Downtime (e.g. Zero Downtime)',
    },
    'clinic_service_saved': {
      'ar': 'تمت إضافة الخدمة بنجاح',
      'en': 'Service added successfully',
    },
    'clinic_validation_required': {
      'ar': 'يرجى ملء الحقول المطلوبة بشكل صحيح',
      'en': 'Please fill required fields properly',
    },

    'clinic_maps_config': {
      'ar': 'موقع العيادة وربط Google Maps',
      'en': 'Google Maps & Location Linking',
    },
    'clinic_logout': {
      'ar': 'تسجيل الخروج من لوحة العيادة',
      'en': 'Sign Out of Clinic Portal',
    },
    'clinic_disclaimer': {
      'ar':
          'إشعار المنصة: منصة Aesthetic Way هي أداة ربط وتوليد طلبات تواصل (Leads) فقط، ولا تتضمن دفعات مالية للمرضى أو تأكيد حجز نهائي داخل التطبيق.',
      'en':
          'Platform Notice: Aesthetic Way is a discovery and lead-generation connection platform only, and does not handle patient payments or final booking confirmations.',
    },

    'open_full_login': {
      'ar': 'فتح صفحة الدخول الكاملة',
      'en': 'Open Full Login Screen',
    },

    // ==========================================
    // SUPER ADMIN PORTAL (إدارة المنصة)
    // ==========================================
    'admin_portal_title': {
      'ar': 'بوابة المشرف العام',
      'en': 'Super Admin Portal',
    },
    'admin_demo_login': {
      'ar': 'دخول تجريبي: مدير المنصة (Super Admin)',
      'en': 'Super Admin Demo Login',
    },
    'admin_title_dashboard': {'ar': 'لوحة القيادة', 'en': 'Dashboard'},
    'admin_title_clinics': {'ar': 'العيادات الشريكة', 'en': 'Partner Clinics'},
    'admin_title_leads': {
      'ar': 'الإشراف على الطلبات',
      'en': 'Leads Supervision',
    },
    'admin_title_catalog': {
      'ar': 'الكتالوج والمراجعة',
      'en': 'Catalog & Moderation',
    },
    'admin_title_analytics': {
      'ar': 'تحليلات المنصة',
      'en': 'Platform Analytics',
    },
    'admin_nav_dashboard': {'ar': 'الرئيسية', 'en': 'Dashboard'},
    'admin_nav_clinics': {'ar': 'العيادات', 'en': 'Clinics'},
    'admin_nav_leads': {'ar': 'الطلبات', 'en': 'Leads'},
    'admin_nav_offers': {'ar': 'العروض', 'en': 'Offers'},
    'admin_nav_analytics': {'ar': 'الإحصائيات', 'en': 'Analytics'},
    'admin_nav_settings': {'ar': 'الإعدادات', 'en': 'Settings'},

    'admin_total_app_opens': {'ar': 'مرات فتح التطبيق', 'en': 'App Opens'},
    'admin_active_users': {'ar': 'المستخدمون النشطون', 'en': 'Active Users'},
    'admin_total_leads': {'ar': 'إجمالي طلبات الاستشارة', 'en': 'Total Leads'},
    'admin_today_leads': {'ar': 'طلبات اليوم', 'en': 'Today\'s Leads'},
    'admin_active_clinics': {'ar': 'العيادات النشطة', 'en': 'Active Clinics'},
    'admin_whatsapp_taps': {'ar': 'تواصل عبر واتساب', 'en': 'WhatsApp Taps'},
    'admin_call_taps': {'ar': 'تواصل عبر الاتصال', 'en': 'Call Taps'},
    'admin_recent_activity': {
      'ar': 'سجل النشاط المباشر في المنصة',
      'en': 'Live Platform Activity',
    },
    'admin_all_clinics': {
      'ar': 'جميع العيادات المسجلة',
      'en': 'All Registered Clinics',
    },
    'admin_clinic_status_active': {'ar': 'نشطة ومفعلة', 'en': 'Active'},
    'admin_clinic_status_suspended': {'ar': 'موقوفة مؤقتاً', 'en': 'Suspended'},
    'admin_toggle_clinic_status': {
      'ar': 'تغيير حالة تفعيل العيادة',
      'en': 'Toggle Clinic Status',
    },
    'admin_clinic_details': {
      'ar': 'ملف وإحصائيات العيادة',
      'en': 'Clinic Profile & Metrics',
    },
    'admin_views_count': {
      'ar': 'مرات الظهور والمشاهدات',
      'en': 'App Views & Impressions',
    },
    'admin_leads_overview': {
      'ar': 'سجل طلبات الاستشارة العام (Leads Registry)',
      'en': 'Global Leads Registry',
    },
    'admin_filter_by_clinic': {
      'ar': 'تصفية حسب العيادة',
      'en': 'Filter by Clinic',
    },
    'admin_filter_all_clinics': {
      'ar': 'جميع العيادات (الكل)',
      'en': 'All Clinics',
    },
    'admin_lead_monitoring_note': {
      'ar':
          'وضع المراقبة والإشراف: تتيح اللوحة الإشراف على حجم تدفق الطلبات عبر العيادات دون التدخل في الجداول.',
      'en':
          'Supervision Mode: Monitor lead generation volume across clinics without booking intervention.',
    },
    'admin_lead_monitoring_banner': {
      'ar': 'للمراقبة فقط — إدارة التواصل تتم من حساب العيادة',
      'en': 'Monitoring only — clinic account handles patient contact',
    },
    'admin_lead_inspect_title': {
      'ar': 'تفاصيل طلب الاستشارة (إشراف)',
      'en': 'Lead Supervision Detail',
    },
    'admin_offers_moderation': {
      'ar': 'إشراف ومراجعة العروض التجميلية',
      'en': 'Offers Moderation',
    },
    'admin_offer_active': {
      'ar': 'منشور ونشط للعامة',
      'en': 'Published & Active',
    },
    'admin_offer_suspended': {
      'ar': 'موقوف من الإدارة',
      'en': 'Suspended by Admin',
    },
    'admin_suspend_offer_btn': {'ar': 'إيقاف نشر العرض', 'en': 'Suspend Offer'},
    'admin_activate_offer_btn': {
      'ar': 'إعادة تفعيل ونشر العرض',
      'en': 'Activate Offer',
    },
    'admin_analytics_title': {
      'ar': 'التحليلات ومعدلات تفاعل المرضى مع العيادات',
      'en': 'Clinic Engagement Analytics',
    },
    'admin_analytics_sub': {
      'ar':
          'إحصائيات تفاعل العملاء عبر الاتصال، الواتساب، وطلبات الاستشارة لكل عيادة',
      'en':
          'Detailed breakdown of patient engagement via Calls, WhatsApp and Leads per clinic',
    },
    'admin_table_clinic': {'ar': 'العيادة', 'en': 'Clinic'},
    'admin_table_views': {'ar': 'المشاهدات', 'en': 'Views'},
    'admin_table_leads': {'ar': 'الطلبات', 'en': 'Leads'},
    'admin_table_whatsapp': {'ar': 'واتساب', 'en': 'WhatsApp'},
    'admin_table_calls': {'ar': 'اتصال', 'en': 'Calls'},
    'admin_table_conversion': {'ar': 'معدل التفاعل', 'en': 'Engagement'},
    'admin_settings_title': {
      'ar': 'إعدادات المنصة والنظام',
      'en': 'Platform Settings',
    },
    'admin_logout': {
      'ar': 'تسجيل الخروج من لوحة الإدارة',
      'en': 'Sign Out of Admin Portal',
    },
    'admin_license_info': {
      'ar': 'الترخيص والبيانات القانونية',
      'en': 'Licensing & Legal Information',
    },
    'admin_total_events': {
      'ar': 'إجمالي الأحداث المسجلة',
      'en': 'Tracked Platform Events',
    },
    'admin_registered_patients': {
      'ar': 'المرضى المسجلين',
      'en': 'Registered Patients',
    },
    'admin_contacted_leads': {
      'ar': 'طلبات تم التواصل معها',
      'en': 'Contacted Leads',
    },
    'admin_completed_leads': {
      'ar': 'طلبات مغلقة ومكتملة',
      'en': 'Closed Leads',
    },
    'admin_active_offers_kpi': {'ar': 'العروض النشطة', 'en': 'Active Offers'},
    'admin_closure_rate': {'ar': 'معدل الإغلاق', 'en': 'Closure Rate'},
    'admin_maps_taps': {'ar': 'نقرات الخرائط', 'en': 'Maps Taps'},
    'admin_lead_submissions': {
      'ar': 'طلبات الاستشارة',
      'en': 'Leads Submitted',
    },
    'admin_clinic_views': {'ar': 'مشاهدات العيادات', 'en': 'Clinic Views'},
    'admin_clinic_branches': {'ar': 'الفروع', 'en': 'Branches'},
    'admin_clinic_practitioners': {'ar': 'الكادر الطبي', 'en': 'Practitioners'},
    'admin_clinic_offers': {'ar': 'العروض', 'en': 'Offers'},
    'admin_clinic_treatments': {'ar': 'العلاجات', 'en': 'Treatments'},
    'admin_clinic_products': {'ar': 'المنتجات', 'en': 'Products'},
    'admin_clinic_articles': {'ar': 'المقالات', 'en': 'Articles'},
    'admin_events_count': {'ar': 'إجمالي التفاعلات', 'en': 'Total Events'},

    // Navigation
    'nav_home': {'ar': 'الرئيسية', 'en': 'Home'},
    'nav_clinics': {'ar': 'العيادات', 'en': 'Clinics'},
    'nav_products': {'ar': 'المنتجات', 'en': 'Products'},
    'nav_offers': {'ar': 'العروض', 'en': 'Offers'},
    'nav_requests': {'ar': 'طلباتي', 'en': 'Requests'},
    'nav_profile': {'ar': 'حسابي', 'en': 'Profile'},

    // Header & Search
    'search_hint': {
      'ar': 'ابحث عن عيادة، منطقة، أو تخصص...',
      'en': 'Search clinic, area, or specialty...',
    },
    'select_city': {'ar': 'اختر الإمارة', 'en': 'Select Emirate'},
    'city_all': {'ar': 'الكل (الإمارات)', 'en': 'All (UAE)'},
    'city_dubai': {'ar': 'دبي', 'en': 'Dubai'},
    'city_abudhabi': {'ar': 'أبوظبي', 'en': 'Abu Dhabi'},
    'filter_button': {'ar': 'فلترة', 'en': 'Filter'},

    // Badges & Labels
    'vip_partner': {'ar': 'بلاتيني VIP', 'en': 'VIP Platinum'},
    'featured_badge': {'ar': 'إعلان مميز', 'en': 'Featured'},
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
    'procedures_title': {
      'ar': 'أبرز الإجراءات الطبية',
      'en': 'Key Medical Procedures',
    },
    'languages_spoken': {'ar': 'اللغات', 'en': 'Languages'},
    'about_doctor': {'ar': 'نبذة عن الممارس', 'en': 'About Practitioner'},
    'duration_label': {'ar': 'المدة المتوقعة', 'en': 'Duration'},
    'downtime_label': {'ar': 'فترة التعافي', 'en': 'Downtime'},
    'target_area_label': {'ar': 'المنطقة المستهدفة', 'en': 'Target Area'},
    'available_in_clinics': {'ar': 'متوفر في', 'en': 'Available in'},
    'clinics_count_suffix': {'ar': 'عيادة', 'en': 'clinics'},
    'terms_conditions': {'ar': 'الشروط والأحكام', 'en': 'Terms & Conditions'},
    'valid_until': {'ar': 'صلاحية العرض', 'en': 'Validity'},

    // Featured Ads & Home Sections
    'featured_partners': {'ar': 'العيادات المختارة', 'en': 'Featured Clinics'},
    'categories_title': {
      'ar': 'التصنيفات والخدمات',
      'en': 'Categories & Services',
    },
    'nearby_title': {'ar': 'اكتشف العيادات', 'en': 'Discover clinics'},
    'active_offers': {
      'ar': 'الباقات والعروض التجميلية',
      'en': 'Aesthetic Packages & Offers',
    },
    'view_map': {'ar': 'الخريطة', 'en': 'Map'},
    'map_view': {'ar': 'عرض الخريطة', 'en': 'Map View'},
    'directions': {'ar': 'الاتجاهات', 'en': 'Directions'},
    'contact_btn': {'ar': 'تواصل', 'en': 'Contact'},
    'request_appointment': {'ar': 'طلب موعد', 'en': 'Request Lead'},
    'request_consultation': {
      'ar': 'طلب موعد استشارة',
      'en': 'Request Consultation',
    },

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

    // Category Screen Titles
    'category_doctors_title': {
      'ar': 'الأطباء والاستشاريون',
      'en': 'Doctors & Consultants',
    },
    'category_skin_experts_title': {
      'ar': 'خبيرات البشرة والتمريض التجميلي',
      'en': 'Skin Experts & Aesthetic Therapists',
    },
    'category_plastic_surgery_title': {
      'ar': 'الجراحة التجميلية',
      'en': 'Plastic & Aesthetic Surgery',
    },
    'category_treatments_title': {
      'ar': 'العلاجات والإجراءات الطبية',
      'en': 'Treatments & Procedures',
    },
    'category_offers_title': {
      'ar': 'العروض والباقات التجميلية',
      'en': 'Aesthetic Offers & Packages',
    },
    'category_products_title': {
      'ar': 'المنتجات والمستحضرات الطبية',
      'en': 'Medical Products & Skincare',
    },
    'category_articles_title': {
      'ar': 'المقالات ودليل التوعية الطبية',
      'en': 'Medical Aesthetic Articles',
    },
    'category_clinics_title': {
      'ar': 'العيادات والمراكز المعتمدة',
      'en': 'Verified Clinics & Centers',
    },

    // Products Module
    'product_inquiry_btn': {
      'ar': 'طلب اهتمام / استفسار عن المنتج',
      'en': 'Product Inquiry / Request',
    },
    'product_inquiry_desc': {
      'ar':
          'سيتم إرسال اهتمامك إلى العيادة الموفرة للتواصل معك بخصوص تفاصيل وتوفر المنتج.',
      'en':
          'Your inquiry will be sent to the clinic to contact you regarding product details and availability.',
    },
    'product_inquiry_sent': {
      'ar': 'تم إرسال اهتمامك بالمنتج وستتواصل العيادة معك',
      'en':
          'Your product inquiry has been sent and the clinic will contact you',
    },
    'product_available': {
      'ar': 'متوفر في العيادة',
      'en': 'Available at Clinic',
    },
    'product_out_of_stock': {'ar': 'غير متوفر حالياً', 'en': 'Out of Stock'},
    'product_provided_by': {
      'ar': 'موفر من قبل عيادة',
      'en': 'Provided by Clinic',
    },
    'product_category_all': {'ar': 'جميع المنتجات', 'en': 'All Products'},
    'product_category_skincare': {'ar': 'عناية بالبشرة', 'en': 'Skincare'},
    'product_category_devices': {'ar': 'أجهزة منزلية', 'en': 'Home Devices'},
    'product_category_cosmeceuticals': {
      'ar': 'مستحضرات علاجية',
      'en': 'Cosmeceuticals',
    },
    'product_category_sunscreens': {
      'ar': 'واقيات شمس ومكملات',
      'en': 'Sun Care & Supplements',
    },
    'product_empty': {
      'ar': 'لا توجد منتجات مطابقة حالياً',
      'en': 'No products found',
    },
    'clinic_manage_products': {
      'ar': 'إدارة منتجات العيادة',
      'en': 'Manage Clinic Products',
    },
    'clinic_add_product': {'ar': 'إضافة منتج جديد', 'en': 'Add New Product'},
    'clinic_product_saved': {
      'ar': 'تم حفظ المنتج بنجاح',
      'en': 'Product saved successfully',
    },
    'clinic_product_name': {'ar': 'اسم المنتج', 'en': 'Product Name'},
    'clinic_product_category': {'ar': 'تصنيف المنتج', 'en': 'Product Category'},
    'clinic_product_price': {'ar': 'السعر (د.إ)', 'en': 'Price (AED)'},
    'clinic_product_orig_price': {
      'ar': 'السعر قبل الخصم (اختياري)',
      'en': 'Original Price (Optional)',
    },
    'clinic_product_description': {
      'ar': 'وصف المنتج ومكوناته',
      'en': 'Description & Key Ingredients',
    },
    'clinic_product_image': {
      'ar': 'صورة المنتج التجميلي',
      'en': 'Product Image',
    },
    'clinic_product_toggle_avail': {
      'ar': 'تبديل حالة التوفر',
      'en': 'Toggle Availability',
    },
    'admin_products_moderation': {
      'ar': 'إشراف ومراقبة المنتجات المعروضة',
      'en': 'Products Moderation',
    },
    'admin_suspend_product_btn': {
      'ar': 'إيقاف نشر المنتج',
      'en': 'Suspend Product',
    },
    'admin_activate_product_btn': {
      'ar': 'تفعيل ونشر المنتج',
      'en': 'Activate Product',
    },

    // Articles Module
    'article_author_by': {'ar': 'بقلم', 'en': 'Written by'},
    'article_read_time': {'ar': 'مدة القراءة: 3 دقائق', 'en': '3 min read'},
    'article_consult_author_btn': {
      'ar': 'طلب استشارة مع الكاتب / العيادة',
      'en': 'Request Consultation with Author',
    },
    'article_published_date': {'ar': 'تاريخ النشر', 'en': 'Published Date'},
    'article_category_all': {'ar': 'جميع المقالات', 'en': 'All Articles'},
    'article_category_glow': {
      'ar': 'نضارة وتجديد البشرة',
      'en': 'Skin Glow & Renewal',
    },
    'article_category_injectables': {
      'ar': 'الفيلر والبوتوكس',
      'en': 'Fillers & Botox',
    },
    'article_category_laser': {'ar': 'علاجات الليزر', 'en': 'Laser Treatments'},
    'article_category_surgery': {
      'ar': 'الجراحة التجميلية',
      'en': 'Plastic Surgery',
    },
    'article_empty': {
      'ar': 'لا توجد مقالات منشورة حالياً',
      'en': 'No articles found',
    },
    'clinic_manage_articles': {
      'ar': 'إدارة مقالات وأدلة العيادة',
      'en': 'Manage Clinic Articles',
    },
    'clinic_add_article': {
      'ar': 'كتابة ونشر مقال جديد',
      'en': 'Write & Publish Article',
    },
    'clinic_article_saved': {
      'ar': 'تم حفظ المقال بنجاح',
      'en': 'Article saved successfully',
    },
    'clinic_article_title': {'ar': 'عنوان المقال', 'en': 'Article Title'},
    'clinic_article_doctor_author': {
      'ar': 'الطبيب الكاتب (من طاقم العيادة)',
      'en': 'Author Doctor (Clinic Staff)',
    },
    'clinic_article_summary': {'ar': 'ملخص المقال', 'en': 'Article Summary'},
    'clinic_article_content': {
      'ar': 'محتوى المقال الكامل',
      'en': 'Full Article Content',
    },
    'clinic_article_category': {'ar': 'تصنيف المقال', 'en': 'Article Category'},
    'clinic_article_cover': {
      'ar': 'صورة غلاف المقال',
      'en': 'Article Cover Image',
    },
    'admin_articles_moderation': {
      'ar': 'إشراف ومراقبة المقالات المنشورة',
      'en': 'Articles Moderation',
    },
    'admin_suspend_article_btn': {
      'ar': 'إيقاف نشر المقال',
      'en': 'Suspend Article',
    },
    'admin_activate_article_btn': {
      'ar': 'إعادة نشر وتفعيل المقال',
      'en': 'Activate Article',
    },

    // Practitioners & Treatments Search & Filters
    'practitioners_search_hint': {
      'ar': 'ابحث باسم الطبيب، التخصص، أو العيادة...',
      'en': 'Search doctor name, specialty, or clinic...',
    },
    'treatments_search_hint': {
      'ar': 'ابحث عن علاج، إجراء، أو منطقة مستهدفة...',
      'en': 'Search treatment, procedure, or target area...',
    },
    'filter_all_roles': {'ar': 'الكل', 'en': 'All'},
    'filter_doctors': {'ar': 'الأطباء والاستشاريون', 'en': 'Doctors'},
    'filter_skin_experts': {'ar': 'خبيرات البشرة', 'en': 'Skin Experts'},
    'treatment_category_all': {'ar': 'جميع العلاجات', 'en': 'All Treatments'},
    'treatment_category_injectables': {
      'ar': 'علاجات الحقن',
      'en': 'Injectables',
    },
    'treatment_category_skincare': {'ar': 'عناية بالبشرة', 'en': 'Skincare'},
    'treatment_category_laser': {'ar': 'ليزر وبشرة', 'en': 'Laser & Skin'},
    'treatment_category_surgery': {
      'ar': 'جراحة تجميلية',
      'en': 'Plastic Surgery',
    },
    'treatment_category_body': {
      'ar': 'نحت وتنسيق القوام',
      'en': 'Body Contouring',
    },
    'request_this_treatment': {
      'ar': 'طلب استشارة لهذا العلاج',
      'en': 'Request Consultation for this Treatment',
    },
    'request_with_practitioner_btn': {
      'ar': 'طلب استشارة مع الممارس',
      'en': 'Request Consultation with Practitioner',
    },

    // Clinic Profile Tabs & Details
    'tab_about': {'ar': 'نبذة والموقع', 'en': 'About & Map'},
    'tab_staff': {'ar': 'الكادر الطبي', 'en': 'Medical Staff'},
    'tab_treatments': {'ar': 'العلاجات والخدمات', 'en': 'Treatments'},
    'tab_offers': {'ar': 'العروض', 'en': 'Offers'},
    'tab_reviews': {'ar': 'التقييمات', 'en': 'Reviews'},
    'about_clinic': {'ar': 'عن العيادة', 'en': 'About Clinic'},
    'working_hours': {'ar': 'ساعات العمل', 'en': 'Working Hours'},
    'geo_location': {
      'ar': 'الموقع الجغرافي و Google Maps',
      'en': 'Location & Google Maps',
    },
    'open_in_maps': {'ar': 'فتح في Google Maps', 'en': 'Open in Google Maps'},
    'branches_in_uae': {
      'ar': 'فروع العيادة في الإمارات',
      'en': 'UAE Clinic Branches',
    },
    'request_with_doctor': {
      'ar': 'طلب استشارة مع الممارس',
      'en': 'Request consultation',
    },
    'offer_claim': {'ar': 'طلب بالعرض', 'en': 'Inquire about offer'},
    'verified_visit': {'ar': 'زيارة موثقة', 'en': 'Verified Visit'},
    'reviews_summary': {'ar': 'تقييمات من Google', 'en': 'Ratings from Google'},
    'google_rating': {'ar': 'تقييم Google', 'en': 'Google Rating'},

    // Filter Sheet
    'filter_title': {'ar': 'تصفية وبحث متقدم', 'en': 'Advanced Filters'},
    'filter_city': {'ar': 'الإمارة / المدينة', 'en': 'Emirate / City'},
    'filter_specialty': {'ar': 'التخصص الطبي', 'en': 'Specialty'},
    'filter_practitioner_type': {
      'ar': 'نوع الممارس',
      'en': 'Practitioner Type',
    },
    'filter_sort': {'ar': 'ترتيب النتائج', 'en': 'Sort By'},
    'sort_featured': {
      'ar': 'المميز والـ VIP أولاً',
      'en': 'VIP & Featured First',
    },
    'sort_rating': {'ar': 'الأعلى تقييماً', 'en': 'Highest Rated'},
    'sort_distance': {'ar': 'الأقرب مسافة', 'en': 'Nearest Distance'},
    'apply_filters': {'ar': 'تطبيق الفلاتر', 'en': 'Apply Filters'},
    'reset_filters': {'ar': 'إعادة ضبط', 'en': 'Reset'},

    // Appointment Request (Lead Form) & Time Slots
    'lead_form_title': {
      'ar': 'طلب موعد استشارة',
      'en': 'Request Consultation Lead',
    },
    'select_branch': {'ar': 'فرع العيادة المطلوب', 'en': 'Selected Branch'},
    'select_service': {
      'ar': 'الخدمة أو العلاج المطلوب',
      'en': 'Requested Service',
    },
    'select_practitioner': {
      'ar': 'الممارس المفضل (اختياري)',
      'en': 'Preferred Practitioner (Optional)',
    },
    'any_practitioner': {
      'ar': 'أي ممارس متاح في العيادة',
      'en': 'Any available practitioner',
    },
    'preferred_datetime': {
      'ar': 'الموعد والفترة الزمنية المفضلة',
      'en': 'Preferred Date & Time Window',
    },
    'time_morning': {'ar': 'صباحاً (9 ص - 1 م)', 'en': 'Morning (9 AM - 1 PM)'},
    'time_afternoon': {
      'ar': 'ظهراً (1 م - 5 م)',
      'en': 'Afternoon (1 PM - 5 PM)',
    },
    'time_evening': {'ar': 'مساءً (5 م - 9 م)', 'en': 'Evening (5 PM - 9 PM)'},
    'period_morning': {
      'ar': 'صباحاً (9 ص - 1 م)',
      'en': 'Morning (9 AM - 1 PM)',
    },
    'period_afternoon': {
      'ar': 'ظهراً (1 م - 5 م)',
      'en': 'Afternoon (1 PM - 5 PM)',
    },
    'period_evening': {
      'ar': 'مساءً (5 م - 9 م)',
      'en': 'Evening (5 PM - 9 PM)',
    },
    'contact_info_title': {
      'ar': 'بيانات التواصل / المريض',
      'en': 'Contact Info',
    },
    'patient_details': {
      'ar': 'بيانات المريض / العميل',
      'en': 'Patient Details',
    },
    'full_name': {'ar': 'الاسم الكامل', 'en': 'Full Name'},
    'name_hint': {'ar': 'مثال: سارة المنصوري', 'en': 'e.g. Sarah Al Mansoori'},
    'phone_number': {'ar': 'رقم الهاتف', 'en': 'Phone number'},
    'phone_uae': {'ar': 'رقم الهاتف (الإمارات)', 'en': 'Phone Number (UAE)'},
    'phone_hint': {'ar': '50 123 4567', 'en': '50 123 4567'},
    'email_address': {'ar': 'البريد الإلكتروني', 'en': 'Email Address'},
    'email_hint': {'ar': 'name@example.com', 'en': 'name@example.com'},
    'notes_opt': {'ar': 'ملاحظات إضافية (اختياري)', 'en': 'Notes (Optional)'},
    'notes_optional': {
      'ar': 'ملاحظات إضافية أو استفسار (اختياري)',
      'en': 'Additional Notes / Questions (Optional)',
    },
    'notes_hint': {
      'ar': 'اكتب أي تفاصيل ترغب بمشاركتها مع العيادة...',
      'en': 'Write any details you wish to share...',
    },
    'consent_text': {
      'ar':
          'أوافق على مشاركة هذه البيانات مع العيادة المحددة للتواصل معي هاتفياً أو عبر الواتساب لتنسيق الاستشارة، وأقر بالاطلاع على شروط الاستخدام والخصوصية.',
      'en':
          'I agree to share these details with the selected clinic to contact me via phone or WhatsApp to coordinate my consultation, and I accept the terms of use and privacy policy.',
    },
    'submit_lead_btn': {
      'ar': 'إرسال طلب الموعد للعيادة',
      'en': 'Send Consultation Request',
    },

    // FROZEN STRICT SUCCESS COPY (Core Rule)
    'lead_success_title': {
      'ar': 'تم إرسال طلبك بنجاح!',
      'en': 'Request Sent Successfully!',
    },
    'lead_success_body': {
      'ar': 'تم إرسال طلبك وستتواصل العيادة معك',
      'en': 'Your request has been sent and the clinic will contact you',
    },
    'lead_summary_title': {
      'ar': 'ملخص تفاصيل الطلب',
      'en': 'Lead Request Summary',
    },
    'ref_number': {'ar': 'رقم المرجع', 'en': 'Reference No.'},
    'clinic_label': {'ar': 'العيادة', 'en': 'Clinic'},
    'branch_label': {'ar': 'الفرع', 'en': 'Branch'},
    'service_label': {'ar': 'الخدمة / الإجراء', 'en': 'Service / Treatment'},
    'practitioner_label': {'ar': 'الممارس الطبي', 'en': 'Practitioner'},
    'date_label': {'ar': 'التاريخ المفضل', 'en': 'Preferred Date'},
    'period_label': {'ar': 'الفترة', 'en': 'Time Window'},
    'patient_label': {'ar': 'المريض', 'en': 'Patient'},
    'phone_label': {'ar': 'الهاتف', 'en': 'Phone'},
    'open_maps_btn': {
      'ar': 'فتح موقع العيادة في Google Maps',
      'en': 'Open Location in Google Maps',
    },
    'back_home': {'ar': 'العودة إلى الرئيسية', 'en': 'Back to Home'},

    // My Requests (Lead Tracking)
    'my_requests_title': {
      'ar': 'طلبات المواعيد والاستشارات',
      'en': 'Appointment Leads',
    },
    'status_all': {'ar': 'الكل', 'en': 'All'},
    'status_sent': {'ar': 'تم الإرسال', 'en': 'Sent'},
    'status_contacted': {'ar': 'تم التواصل', 'en': 'Contacted'},
    'status_closed': {'ar': 'مكتمل / مغلق', 'en': 'Closed'},
    'no_requests': {
      'ar': 'لا توجد طلبات مواعيد مسجلة حالياً',
      'en': 'No appointment leads yet',
    },
    'no_requests_sub': {
      'ar': 'تصفح العيادات وأرسل طلب استشارة لتظهر هنا',
      'en': 'Explore clinics and request a lead to track it here',
    },
    'status_sent_label': {
      'ar': 'بانتظار تواصل العيادة',
      'en': 'Awaiting Clinic Response',
    },
    'status_contacted_label': {
      'ar': 'تم التواصل من العيادة',
      'en': 'Contacted by Clinic',
    },
    'status_closed_label': {
      'ar': 'طلب مكتمل / منتهي',
      'en': 'Closed / Completed',
    },

    // Profile & Settings
    'profile_title': {'ar': 'حسابي وإعداداتي', 'en': 'My Profile & Settings'},
    'app_language': {'ar': 'لغة التطبيق', 'en': 'App Language'},
    'switch_language': {'ar': 'English ⇄', 'en': 'العربية ⇄'},
    'theme_title': {'ar': 'مظهر التطبيق', 'en': 'App Theme'},
    'theme_dark': {'ar': 'الوضع الداكن (Dark)', 'en': 'Dark Mode'},
    'theme_light': {'ar': 'الوضع الفاتح (Light)', 'en': 'Light Mode'},
    'theme_system': {'ar': 'تلقائي (حسب النظام)', 'en': 'System Mode'},
    'my_favs': {'ar': 'العيادات المفضلة', 'en': 'Favorite Clinics'},
    'privacy_terms': {
      'ar': 'الخصوصية والشروط القانونية',
      'en': 'Privacy & Legal Terms',
    },
    'support_help': {'ar': 'الدعم وخدمة العملاء', 'en': 'Customer Support'},
    'guest_status': {'ar': 'زائر (تصفح فقط)', 'en': 'Guest User (Browse Mode)'},
    'logged_in_status': {'ar': 'مستخدم موثق', 'en': 'Verified Member'},
    'login_prompt': {
      'ar': 'سجّل رقمك لحفظ المفضلة ومتابعة الطلبات',
      'en': 'Login to save favorites and track leads',
    },
    'login_btn': {'ar': 'تسجيل الدخول / إنشاء حساب', 'en': 'Login / Register'},
    'logout_btn': {'ar': 'تسجيل الخروج', 'en': 'Sign Out'},

    // Compliance & Privacy Modal Text
    'privacy_sheet_title': {
      'ar': 'الخصوصية والشروط القانونية',
      'en': 'Privacy & Legal Terms',
    },
    'privacy_sheet_text': {
      'ar':
          'منصة Aesthetic Way — دليل واكتشاف العيادات الطبية والتجميلية في دولة الإمارات العربية المتحدة.\n\nتعتبر منصة Aesthetic Way أداة رقمية وتطبيقاً للربط والتسهيل بين العملاء وبين العيادات والمراكز الطبية المعتمدة في الدولة. تتم كافة الاستشارات والتشخيصات والإجراءات الطبية والتواصل المباشر عبر الكوادر الطبية والعيادات المرخصة حصراً، وتلتزم المنصة بحماية وسرية بيانات المستخدمين.',
      'en':
          'Aesthetic Way Platform — Discovery and connection platform for certified aesthetic clinics in the UAE.\n\nAesthetic Way facilitates seamless lead connection between users and certified aesthetic medical clinics in the UAE. All medical consultations, assessments, and procedures are handled directly by the licensed clinic or medical practitioner. User privacy and data protection are strictly upheld.',
    },

    // Customer Support Sheet Text
    'concierge_title': {'ar': 'الدعم وخدمة العملاء', 'en': 'Customer Support'},
    'concierge_desc': {
      'ar':
          'يسعد فريق خدمة عملاء Aesthetic Way بمساعدتك والإجابة عن استفساراتك حول استخدام المنصة والعيادات.',
      'en':
          'Our Aesthetic Way Customer Support team is delighted to assist you with inquiries regarding clinics and platform features.',
    },
    'whatsapp_concierge': {
      'ar': 'محادثة فورية عبر الواتساب',
      'en': 'Live Chat on WhatsApp',
    },
    'call_concierge': {
      'ar': 'الاتصال بخدمة العملاء',
      'en': 'Call Customer Support',
    },
    'contact_options_title': {
      'ar': 'خيارات التواصل المباشر مع العيادة',
      'en': 'Direct Contact Options',
    },
    'reception_call': {'ar': 'اتصال فوري بالاستقبال', 'en': 'Call Reception'},
    'location_directions': {
      'ar': 'الاتجاهات عبر خرائط Google',
      'en': 'Directions on Google Maps',
    },

    // ==========================================
    // REFERRAL & REWARDS SYSTEM (نظام الدعوات والمكافآت)
    // ==========================================
    'referral_nav_title': {
      'ar': 'برنامج المكافآت والدعوات',
      'en': 'Referrals & Rewards',
    },
    'referral_title': {
      'ar': 'برنامج الدعوات والمكافآت',
      'en': 'Referral & Rewards',
    },
    'referral_sub': {
      'ar':
          'شارك رابط دعوتك الشخصي وتابع الدعوات الناجحة والنقاط ومراحل التقدم.',
      'en':
          'Share your personal invitation link and track successful invitations, points and milestones.',
    },
    'referral_milestones_title': {
      'ar': 'مستويات النقاط والمكافآت',
      'en': 'Points & Milestones',
    },

    // Price Display Labels
    'original_price_label': {'ar': 'السعر الأصلي', 'en': 'Original Price'},
    'offer_price_label': {'ar': 'سعر العرض', 'en': 'Offer Price'},
    'savings_badge': {'ar': 'توفير', 'en': 'Save'},
  };
}
