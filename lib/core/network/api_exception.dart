import 'package:dio/dio.dart';
import '../localization/app_locale.dart';

/// Standard API Exception with localized error parsing and field-level breakdown
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final Map<String, List<String>>? fieldErrors;
  final String? originalBackendMessage;
  final dynamic rawData;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.fieldErrors,
    this.originalBackendMessage,
    this.rawData,
  });

  /// Get first error message for a specific field, if present
  String? getFieldError(String field) {
    if (fieldErrors == null || !fieldErrors!.containsKey(field)) return null;
    final list = fieldErrors![field];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  factory ApiException.fromDioError(DioException error) {
    int? statusCode = error.response?.statusCode;
    String? errorCode;
    String? rawBackendMsg;
    String message = LocaleService().isArabic
        ? 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.'
        : 'An unexpected error occurred. Please try again.';
    Map<String, List<String>>? fieldErrors;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        message: 'انتهت مهلة الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت.',
        statusCode: statusCode,
        errorCode: 'TIMEOUT',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return ApiException(
        message:
            'تعذر الاتصال بالخادم. تأكد من تشغيل السيرفر المحلي أو الاتصال بالشبكة.',
        statusCode: statusCode,
        errorCode: 'CONNECTION_ERROR',
      );
    }

    // Error bodies may echo patient notes, credentials or server tracebacks.
    // Never retain raw response payloads or expose 5xx/HTML diagnostics.
    if (statusCode != null && statusCode >= 500) {
      return ApiException(
        message: LocaleService().isArabic
            ? 'تعذر إتمام الطلب حالياً. حاول مجدداً لاحقاً.'
            : 'The service is temporarily unavailable. Please try again.',
        statusCode: statusCode,
        errorCode: 'SERVER_ERROR',
      );
    }
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      // 1. Standard AW backend format: {"error": {"code": "...", "message": "...", "fields": {...}}}
      if (data['error'] is Map<String, dynamic>) {
        final errObj = data['error'] as Map<String, dynamic>;
        errorCode = errObj['code']?.toString();
        rawBackendMsg = errObj['message']?.toString();

        if (errObj['fields'] is Map<String, dynamic>) {
          fieldErrors = _extractFieldErrors(
            errObj['fields'] as Map<String, dynamic>,
          );
        }

        if (fieldErrors != null && fieldErrors.isNotEmpty) {
          message = _formatFieldErrorsMessage(fieldErrors);
        } else if (rawBackendMsg != null && rawBackendMsg.isNotEmpty) {
          message = _localizeBackendMessage(rawBackendMsg);
        }
      }
      // 2. Direct fields map: {"fields": {...}}
      else if (data['fields'] is Map<String, dynamic>) {
        errorCode = data['code']?.toString() ?? 'VALIDATION_ERROR';
        rawBackendMsg = data['message']?.toString();
        fieldErrors = _extractFieldErrors(
          data['fields'] as Map<String, dynamic>,
        );
        message = _formatFieldErrorsMessage(fieldErrors);
      }
      // 3. Simple DRF detail: {"detail": "..."}
      else if (data['detail'] != null) {
        rawBackendMsg = data['detail'].toString();
        message = _localizeBackendMessage(rawBackendMsg);
        errorCode = data['code']?.toString();
      }
      // 4. Raw DRF serializer error map: {"field": ["msg1", ...]}
      else {
        rawBackendMsg = data['message']?.toString();
        final extracted = _extractFieldErrors(data);
        if (extracted.isNotEmpty) {
          fieldErrors = extracted;
          errorCode = 'VALIDATION_ERROR';
          message = _formatFieldErrorsMessage(extracted);
        } else if (rawBackendMsg != null) {
          message = _localizeBackendMessage(rawBackendMsg);
        }
      }
    } else if (data is String && data.isNotEmpty) {
      rawBackendMsg = data;
      message = _localizeBackendMessage(data);
    }

    // Special fallback for 422 Unprocessable Entity
    if (statusCode == 422 &&
        (message.contains('حدث خطأ غير متوقع') ||
            message.contains('unexpected error'))) {
      if (rawBackendMsg != null && rawBackendMsg.isNotEmpty) {
        message = _localizeBackendMessage(rawBackendMsg);
      } else {
        message = LocaleService().isArabic
            ? 'تعذر التحقق من البيانات المدخلة، يرجى التأكد من كود التحقق وإعادة المحاولة'
            : 'Unprocessable request. Please check the verification code and try again.';
      }
    }

    // Special fallback for 429 Too Many Requests / Duplicate Lead
    if (statusCode == 429) {
      if (rawBackendMsg != null && rawBackendMsg.isNotEmpty) {
        message = _localizeBackendMessage(rawBackendMsg);
      } else {
        message = LocaleService().isArabic
            ? 'تم إرسال طلب مشابه مؤخرًا. يرجى المحاولة بعد قليل'
            : 'A similar request was recently submitted. Please try again shortly.';
      }
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      errorCode:
          const {
            'VALIDATION_ERROR',
            'INVALID_TOKEN',
            'TOKEN_EXPIRED',
            'AUTHENTICATION_FAILED',
            'NOT_AUTHENTICATED',
            'PERMISSION_DENIED',
            'THROTTLED',
            'OTP_INVALID',
            'OTP_EXPIRED',
            'OTP_LOCKED',
            'OTP_RATE_LIMIT',
            'INVALID_CREDENTIALS',
            'DUPLICATE_LEAD',
            'CLINIC_SUSPENDED',
          }.contains(errorCode)
          ? errorCode
          : 'REQUEST_REJECTED',
      fieldErrors: fieldErrors,
      originalBackendMessage: null,
      rawData: null,
    );
  }

  static Map<String, List<String>> _extractFieldErrors(
    Map<String, dynamic> map,
  ) {
    final result = <String, List<String>>{};
    map.forEach((key, val) {
      if (_fieldDisplayName(key) ==
          (LocaleService().isArabic ? 'الحقل' : 'Field')) {
        return;
      }
      if (key == 'code' || key == 'message' || key == 'status_code') return;
      if (val is List) {
        final list = val
            .map((e) => _localizeBackendMessage(e.toString()))
            .toList();
        if (list.isNotEmpty) result[key] = list;
      } else if (val is String && val.isNotEmpty) {
        result[key] = [_localizeBackendMessage(val)];
      } else if (val is Map<String, dynamic>) {
        final sub = _extractFieldErrors(val);
        sub.forEach((subKey, subVal) {
          result['$key.$subKey'] = subVal;
        });
      }
    });
    return result;
  }

  static String _formatFieldErrorsMessage(Map<String, List<String>> fields) {
    final buffer = StringBuffer();
    fields.forEach((key, messages) {
      final fieldLabel = _fieldDisplayName(key);
      final combined = messages.join('، ');
      buffer.writeln('• $fieldLabel: $combined');
    });
    return buffer.toString().trim();
  }

  static String _fieldDisplayName(String key) {
    final isArabic = LocaleService().isArabic;
    switch (key.toLowerCase()) {
      case 'non_field_errors':
        return isArabic ? 'الطلب' : 'Request';
      case 'phone':
        return isArabic ? 'رقم الهاتف' : 'Phone Number';
      case 'password':
        return isArabic ? 'كلمة المرور' : 'Password';
      case 'email':
        return isArabic ? 'البريد الإلكتروني' : 'Email';
      case 'full_name':
        return isArabic ? 'الاسم الكامل' : 'Full Name';
      case 'referral_code':
        return isArabic ? 'كود الإحالة' : 'Referral Code';
      case 'otp_code':
        return isArabic ? 'رمز التحقق' : 'Verification Code';
      case 'clinic':
      case 'clinic_id':
        return isArabic ? 'العيادة' : 'Clinic';
      case 'branch':
      case 'branch_id':
        return isArabic ? 'الفرع' : 'Branch';
      case 'practitioner':
      case 'practitioner_id':
        return isArabic ? 'الممارس / الطبيب' : 'Practitioner';
      case 'treatment':
      case 'treatment_id':
        return isArabic ? 'العلاج' : 'Treatment';
      case 'offer':
      case 'offer_id':
        return isArabic ? 'العرض' : 'Offer';
      case 'service_name':
        return isArabic ? 'الخدمة' : 'Service';
      case 'consent_accepted':
        return isArabic ? 'الموافقة على مشاركة البيانات' : 'Consent';
      case 'preferred_time_window':
        return isArabic ? 'الفترة الزمنية المفضلة' : 'Preferred Time Window';
      case 'notes':
        return isArabic ? 'الملاحظات' : 'Notes';
      case 'name_en':
        return isArabic ? 'الاسم بالإنجليزية' : 'Name (English)';
      case 'name_ar':
        return isArabic ? 'الاسم بالعربية' : 'Name (Arabic)';
      case 'title_en':
        return isArabic ? 'المسمى الوظيفي بالإنجليزية' : 'Title (English)';
      case 'title_ar':
        return isArabic ? 'المسمى الوظيفي بالعربية' : 'Title (Arabic)';
      case 'speciality_en':
        return isArabic ? 'التخصص بالإنجليزية' : 'Speciality (English)';
      case 'speciality_ar':
        return isArabic ? 'التخصص بالعربية' : 'Speciality (Arabic)';
      case 'category':
      case 'category_id':
        return isArabic ? 'الفئة' : 'Category';
      case 'price':
        return isArabic ? 'السعر' : 'Price';
      case 'original_price':
        return isArabic ? 'السعر الأصلي' : 'Original Price';
      case 'offer_price':
        return isArabic ? 'سعر العرض' : 'Offer Price';
      case 'discount_percentage':
        return isArabic ? 'نسبة الخصم' : 'Discount Percentage';
      case 'starts_at':
        return isArabic ? 'تاريخ بدء العرض' : 'Start Date';
      case 'ends_at':
        return isArabic ? 'تاريخ انتهاء العرض' : 'End Date';
      case 'avatar':
        return isArabic ? 'الصورة الشخصية' : 'Avatar';
      case 'cover_image':
        return isArabic ? 'صورة الغلاف' : 'Cover Image';
      case 'logo':
        return isArabic ? 'شعار العيادة' : 'Clinic Logo';
      case 'image':
        return isArabic ? 'الصورة' : 'Image';
      case 'sponsor_company':
        return isArabic ? 'الشركة الراعية' : 'Sponsor Company';
      case 'brand_name_en':
        return isArabic
            ? 'اسم العلامة التجارية بالإنجليزية'
            : 'Brand Name (English)';
      case 'brand_name_ar':
        return isArabic
            ? 'اسم العلامة التجارية بالعربية'
            : 'Brand Name (Arabic)';
      case 'admin_user':
        return isArabic ? 'بيانات المشرف' : 'Admin User';
      case 'admin_user.full_name':
        return isArabic ? 'اسم المشرف' : 'Admin Name';
      case 'admin_user.phone':
        return isArabic ? 'رقم هاتف المشرف' : 'Admin Phone';
      case 'admin_user.email':
        return isArabic ? 'بريد المشرف' : 'Admin Email';
      case 'admin_user.temporary_password':
        return isArabic ? 'كلمة المرور المؤقتة للمشرف' : 'Temporary Password';
      case 'city':
        return isArabic ? 'المدينة' : 'City';
      case 'emirate':
        return isArabic ? 'الإمارة' : 'Emirate';
      case 'address_en':
        return isArabic ? 'العنوان بالإنجليزية' : 'Address (English)';
      case 'address_ar':
        return isArabic ? 'العنوان بالعربية' : 'Address (Arabic)';
      case 'description_en':
        return isArabic ? 'الوصف بالإنجليزية' : 'Description (English)';
      case 'description_ar':
        return isArabic ? 'الوصف بالعربية' : 'Description (Arabic)';
      case 'summary_en':
        return isArabic ? 'الملخص بالإنجليزية' : 'Summary (English)';
      case 'summary_ar':
        return isArabic ? 'الملخص بالعربية' : 'Summary (Arabic)';
      case 'content_en':
        return isArabic ? 'المحتوى بالإنجليزية' : 'Content (English)';
      case 'content_ar':
        return isArabic ? 'المحتوى بالعربية' : 'Content (Arabic)';
      case 'whatsapp':
        return isArabic ? 'رقم الواتساب' : 'WhatsApp Number';
      case 'website':
        return isArabic ? 'الموقع الإلكتروني' : 'Website';
      case 'is_main_branch':
        return isArabic ? 'الفرع الرئيسي' : 'Main Branch';
      case 'display_order':
        return isArabic ? 'ترتيب العرض' : 'Display Order';
      case 'subscription_tier':
        return isArabic ? 'باقة الاشتراك' : 'Subscription Tier';
      default:
        return isArabic ? 'الحقل' : 'Field';
    }
  }

  static String _localizeBackendMessage(String msg) {
    final lower = msg.toLowerCase();
    final isArabic = LocaleService().isArabic;

    // Common DRF validation message localizations
    if (lower.contains('this field is required') ||
        lower.contains('this field may not be null')) {
      return isArabic ? 'هذا الحقل مطلوب' : 'This field is required.';
    }
    if (lower.contains('this field may not be blank')) {
      return isArabic
          ? 'هذا الحقل لا يمكن تركه فارغاً'
          : 'This field may not be blank.';
    }
    if (lower.contains('not a file') ||
        lower.contains('submitted data was not a file')) {
      return isArabic
          ? 'الملف المرفق غير صالح، يرجى اختيار ملف صورة صحيح'
          : 'The submitted data was not a valid file.';
    }
    if (lower.contains('enter a valid url')) {
      return isArabic ? 'يرجى إدخال رابط إنترنت صالح' : 'Enter a valid URL.';
    }
    if (lower.contains('enter a valid date/time') ||
        lower.contains('enter a valid datetime') ||
        lower.contains('valid date')) {
      return isArabic
          ? 'يرجى إدخال تاريخ ووقت صالح'
          : 'Enter a valid date/time.';
    }
    if (lower.contains('cannot be earlier than') ||
        (lower.contains('end date') && lower.contains('start date'))) {
      return isArabic
          ? 'تاريخ نهاية العرض لا يمكن أن يكون قبل تاريخ البداية'
          : 'Offer end date cannot be earlier than start date.';
    }
    if (lower.contains('valid integer') || lower.contains('valid number')) {
      return isArabic
          ? 'يرجى إدخال رقم صحيح صالح'
          : 'A valid number is required.';
    }
    if (lower.contains('greater than or equal to 0')) {
      return isArabic
          ? 'يجب أن تكون القيمة أكبر من أو تساوي 0'
          : 'Value must be 0 or greater.';
    }
    if (lower.contains('no more than') && lower.contains('character')) {
      return isArabic
          ? 'تم تجاوز الحد الأقصى المسموح به لعدد الأحرف'
          : 'Exceeded maximum allowed characters.';
    }
    if (lower.contains('at least') && lower.contains('character')) {
      return isArabic
          ? 'عدد الأحرف أقل من الحد الأدنى المطلوب'
          : 'Fewer characters than minimum required.';
    }
    if (lower.contains('object does not exist') ||
        lower.contains('invalid pk')) {
      return isArabic
          ? 'العنصر المختار غير موجود أو تم حذفه'
          : 'Selected item does not exist.';
    }
    if (lower.contains('expected a list of items')) {
      return isArabic ? 'صيغة البيانات غير صحيحة' : 'Invalid data format.';
    }

    // If English mode, return friendly wording for 429 duplicate/rate limit
    if (!isArabic) {
      if (lower.contains('already submitted') ||
          lower.contains('too many requests') ||
          lower.contains('throttled')) {
        return 'A similar request was recently submitted. Please try again shortly.';
      }
      if (lower.contains('otp') || lower.contains('verification code')) {
        return 'Please check the verification code and try again.';
      }
      if (lower.contains('invalid credentials') ||
          lower.contains('no active account')) {
        return 'Unable to sign in. Check your credentials.';
      }
      return 'The request could not be accepted. Check the supplied information.';
    }

    // OTP errors (422 / 429)
    if (lower.contains('no active otp') ||
        (lower.contains('not found') && lower.contains('otp')) ||
        lower.contains('otp_not_found') ||
        lower.contains('no active otp found')) {
      return 'لا يوجد رمز تحقق نشط لهذا الرقم أو انتهت صلاحيته، يرجى طلب رمز جديد';
    }
    if (lower.contains('invalid otp') ||
        lower.contains('incorrect otp') ||
        lower.contains('otp_invalid')) {
      return 'رمز التحقق غير صحيح، يرجى التأكد وإعادة المحاولة';
    }
    if (lower.contains('expired') || lower.contains('otp_expired')) {
      return 'انتهت صلاحية رمز التحقق، يرجى طلب رمز جديد';
    }
    if (lower.contains('locked') ||
        lower.contains('too many failed') ||
        lower.contains('otp_locked')) {
      return 'تم قفل الحساب مؤقتاً لكثرة المحاولات الخاطئة، يرجى المحاولة بعد 30 دقيقة';
    }
    if (lower.contains('wait') &&
        (lower.contains('second') ||
            lower.contains('cooldown') ||
            lower.contains('otp_rate_limit'))) {
      return 'يرجى الانتظار قليلاً قبل طلب رمز تحقق جديد';
    }

    // Password validation errors
    if (lower.contains('too common') || lower.contains('commonly used')) {
      return 'كلمة المرور شائعة وسهلة التخمين، يرجى اختيار كلمة مرور قوية تضم أحرفاً وأرقاماً ورموزاً';
    }
    if (lower.contains('too short') || lower.contains('at least 8')) {
      return 'يجب ألا تقل كلمة المرور عن 8 أحرف';
    }
    if (lower.contains('entirely numeric')) {
      return 'كلمة المرور لا يمكن أن تتكون من أرقام فقط';
    }
    if (lower.contains('too similar')) {
      return 'كلمة المرور مشابهة جداً للاسم أو البريد الإلكتروني';
    }

    // Phone validation errors
    if (lower.contains('phone') &&
        (lower.contains('already exists') || lower.contains('exists'))) {
      return 'رقم الهاتف مسجل بالفعل في حساب آخر';
    }
    if (lower.contains('invalid phone') ||
        lower.contains('cannot parse phone')) {
      return 'صيغة رقم الهاتف غير صحيحة، يرجى إدخال رقم إماراتي صحيح';
    }

    // Email validation errors
    if (lower.contains('email') &&
        (lower.contains('already exists') || lower.contains('exists'))) {
      return 'البريد الإلكتروني مسجل بالفعل في حساب آخر';
    }
    if (lower.contains('valid email')) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }

    // Referral code validation errors
    if (lower.contains('referral') &&
        (lower.contains('invalid') || lower.contains('not found'))) {
      return 'كود الإحالة غير صالح أو غير موجود';
    }

    // Credentials / Login errors
    if (lower.contains('invalid credentials') ||
        lower.contains('no active account')) {
      return 'بيانات الدخول غير صحيحة، تأكد من رقم الهاتف/البريد وكلمة المرور';
    }

    if (lower.contains('user not found') || lower.contains('user_not_found')) {
      return 'المستخدم غير مسجل لدينا، تأكد من صحة رقم الهاتف';
    }

    if (lower.contains('one or more fields failed validation')) {
      return 'يرجى تصحيح أخطاء الحقول الموضحة أدناه';
    }

    // Lead & Appointment request errors
    if (lower.contains('already submitted recently') ||
        lower.contains('already submitted') ||
        lower.contains('similar request') ||
        (lower.contains('recent') && lower.contains('request'))) {
      return 'تم إرسال طلب مشابه مؤخرًا. يرجى المحاولة بعد قليل';
    }
    if (lower.contains('too many requests') ||
        lower.contains('throttled') ||
        lower.contains('request was throttled')) {
      return 'تم إرسال طلب مشابه مؤخرًا. يرجى المحاولة بعد قليل';
    }
    if (lower.contains('consent must be accepted') ||
        lower.contains('consent_accepted')) {
      return 'يرجى الموافقة على مشاركة البيانات مع العيادة لمتابعة الطلب';
    }
    if (lower.contains(
      'practitioner is not assigned to the selected treatment',
    )) {
      return 'الممارس المختار غير مخصص لتقديم هذا العلاج';
    }
    if (lower.contains('branch does not belong')) {
      return 'الفرع المختار لا يتبع لهذه العيادة';
    }
    if (lower.contains('offer is expired') ||
        lower.contains('not yet active')) {
      return 'هذا العرض غير متاح حالياً أو انتهت صلاحيته';
    }

    return 'تعذر قبول الطلب. يرجى التحقق من البيانات المدخلة.';
  }

  /// Compliance Sanitizer: Enforces product rule that no regulatory body names (DHA, DOH, MOHAP)
  /// or raw medical license numbers ever leak into patient UI error messages.
  static String sanitizeRegulatoryCompliance(String text) {
    if (text.isEmpty) return text;
    var sanitized = text.replaceAll(
      RegExp(r'\b(DHA|DOH|MOHAP)[-\s/][A-Z0-9-]+\b', caseSensitive: false),
      LocaleService().isArabic ? 'الترخيص الطبي' : 'medical license',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'\b(DHA|DOH|MOHAP)\b', caseSensitive: false),
      LocaleService().isArabic ? 'الجهة الطبية المختصة' : 'licensing authority',
    );
    return sanitized;
  }

  @override
  String toString() => 'ApiException($statusCode, code: $errorCode): $message';
}
