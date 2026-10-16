import 'package:aesthetic_way/core/widgets/luxury_phone_input_field.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/core/widgets/ltr_text_field.dart';
import 'package:aesthetic_way/core/widgets/luxury_image_picker_field.dart';
import 'package:aesthetic_way/core/services/media_upload_service.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';

/// Modal dialog for Super Admin to provision a new Clinic and its initial Administrator
class AdminCreateClinicDialog extends StatefulWidget {
  const AdminCreateClinicDialog({super.key});

  static Future<void> show(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.92,
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDeep : AppColors.lightCardSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.border(ctx), width: 0.8)),
        ),
        child: const AdminCreateClinicDialog(),
      ),
    );
  }

  @override
  State<AdminCreateClinicDialog> createState() => _AdminCreateClinicDialogState();
}

class _AdminCreateClinicDialogState extends State<AdminCreateClinicDialog> {
  final _formKey = GlobalKey<FormState>();

  // Clinic fields
  final _nameEnController = TextEditingController();
  final _nameArController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressEnController = TextEditingController();
  final _addressArController = TextEditingController();

  String? _logoPath;
  String? _coverPath;

  String _selectedCity = 'Dubai';
  String _selectedTier = 'vip';

  // Admin user fields
  final _adminNameController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _tempPasswordController = TextEditingController();

  bool _isSubmitting = false;
  String? _modalErrorMessage;

  final List<String> _cities = [
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Ajman',
    'Ras Al Khaimah',
    'Fujairah',
    'Umm Al Quwain',
  ];

  final List<Map<String, String>> _tiers = [
    {'value': 'vip', 'labelEn': 'VIP Platinum (Top Carousel)', 'labelAr': 'بلاتيني VIP (أعلى الواجهة)'},
    {'value': 'featured', 'labelEn': 'Featured (Secondary Tier)', 'labelAr': 'مميز Featured (الأولوية الثانية)'},
    {'value': 'basic', 'labelEn': 'Basic (Standard Listing)', 'labelAr': 'أساسي Basic (دليل فقط)'},
  ];

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressEnController.dispose();
    _addressArController.dispose();
    _adminNameController.dispose();
    _adminPhoneController.dispose();
    _adminEmailController.dispose();
    _tempPasswordController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%&*';
    final random = Random.secure();
    final password = List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
    setState(() {
      _tempPasswordController.text = 'AW#$password';
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _modalErrorMessage = null;
    });

    final payload = <String, dynamic>{
      'name_en': _nameEnController.text.trim(),
      'name_ar': _nameArController.text.trim(),
      'city': _selectedCity,
      'emirate': _selectedCity,
      'address_en': _addressEnController.text.trim(),
      'address_ar': _addressArController.text.trim(),
      'phone': _phoneController.text.trim(),
      'whatsapp': _whatsappController.text.trim(),
      'subscription_tier': _selectedTier,
      'is_featured': _selectedTier != 'basic',
      'admin_user': {
        'full_name': _adminNameController.text.trim(),
        'phone': _adminPhoneController.text.trim(),
        'email': _adminEmailController.text.trim(),
        'temporary_password': _tempPasswordController.text.trim(),
      },
    };

    if (_logoPath != null && _logoPath!.isNotEmpty) {
      try {
        final res = await MediaUploadService().uploadImage(
          filePath: _logoPath!,
          mediaType: 'clinic_logo',
        );
        if (res['url'] != null) {
          payload['logo'] = res['url'];
        }
      } catch (_) {
        payload['logo'] = _logoPath;
      }
    }

    if (_coverPath != null && _coverPath!.isNotEmpty) {
      try {
        final res = await MediaUploadService().uploadImage(
          filePath: _coverPath!,
          mediaType: 'clinic_cover',
        );
        if (res['url'] != null) {
          payload['cover_image'] = res['url'];
        }
      } catch (_) {
        payload['cover_image'] = _coverPath;
      }
    }

    try {
      final res = await AdminPortalService().createClinic(payload);
      if (mounted) {
        Navigator.pop(context); // Close create dialog
        _showCredentialHandoffDialog(
          context,
          clinicName: _nameEnController.text.trim(),
          adminPhone: _adminPhoneController.text.trim(),
          tempPassword: _tempPasswordController.text.trim(),
          result: res,
        );
      }
    } catch (e) {
      if (mounted) {
        String cleanMsg;
        if (e is ApiException) {
          cleanMsg = e.message;
        } else {
          cleanMsg = ApiException.sanitizeRegulatoryCompliance(
            e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', ''),
          );
        }
        setState(() {
          _modalErrorMessage = cleanMsg;
          _isSubmitting = false;
        });
      }
    }
  }

  void _showCredentialHandoffDialog(
    BuildContext context, {
    required String clinicName,
    required String adminPhone,
    required String tempPassword,
    required Map<String, dynamic> result,
  }) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    final actualPhone = (result['admin_user'] is Map && result['admin_user']['phone'] != null)
        ? result['admin_user']['phone'].toString()
        : adminPhone;
    final actualPassword = (result['admin_user'] is Map &&
            result['admin_user']['temporary_password'] != null &&
            result['admin_user']['temporary_password'].toString().isNotEmpty)
        ? result['admin_user']['temporary_password'].toString()
        : tempPassword;
    final actualClinic = (result['clinic'] is Map && result['clinic']['name_en'] != null)
        ? result['clinic']['name_en'].toString()
        : clinicName;

    final credentialsText = '''
AESTHETIC WAY — Partner Clinic Credentials
Clinic: $actualClinic
Login Phone: $actualPhone
Temporary Password: $actualPassword
Portal: Mobile App (Clinic Partner Portal)
''';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc.isArabic ? 'تم إنشاء العيادة وبيانات المشرف' : 'Clinic & Admin Provisioned',
                style: AppTypography.cardTitle.copyWith(
                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.isArabic
                  ? 'تم إنشاء حساب العيادة بنجاح. يرجى نسخ بيانات الدخول المؤقتة وتسليمها لمسؤول العيادة بأمان:'
                  : 'Clinic provisioned successfully. Copy and securely transmit these initial login credentials to the clinic administrator:',
              style: AppTypography.caption.copyWith(color: AppColors.mutedText(ctx)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDeep : AppColors.lightCardSurfaceHover,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(ctx), width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${loc.isArabic ? "العيادة" : "Clinic"}: $actualClinic',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${loc.isArabic ? "الهاتف" : "Login Phone"}: $actualPhone',
                    style: TextStyle(fontSize: 12, color: AppColors.mutedText(ctx)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${loc.isArabic ? "كلمة المرور المؤقتة" : "Temp Password"}: ',
                        style: TextStyle(fontSize: 12, color: AppColors.mutedText(ctx)),
                      ),
                      Expanded(
                        child: Text(
                          actualPassword,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentChampagne, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SilverButton(
              label: loc.isArabic ? 'نسخ بيانات الدخول للحافظة' : 'Copy Credentials to Clipboard',
              icon: Icons.copy_rounded,
              height: 42,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: credentialsText));
                showAppSnackBar(
                  context,
                  loc.isArabic ? 'تم نسخ بيانات الدخول' : 'Credentials copied to clipboard',
                  type: AppSnackBarType.success,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              loc.isArabic ? 'إغلاق' : 'Done',
              style: const TextStyle(color: AppColors.accentChampagne, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.mutedText(context).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Dialog Header
            Row(
              children: [
                const Icon(Icons.add_business_rounded, color: AppColors.accentChampagne, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.isArabic ? 'إضافة وتفويض عيادة طبية جديدة' : 'Provision New Partner Clinic',
                    style: AppTypography.cardTitle.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.mutedText(context),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20),
            if (_modalErrorMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _modalErrorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                      onPressed: () {
                        setState(() => _modalErrorMessage = null);
                      },
                    ),
                  ],
                ),
              ),
            ],

            // Scrollable Form Body
            Expanded(
              child: ListView(
                children: [
                  // SECTION 1: CLINIC DETAILS
                  _SectionHeader(title: loc.isArabic ? '1. بيانات العيادة الطبية' : '1. Clinic Profile & Regulatory'),
                  const SizedBox(height: 12),

                  // Visual Branding (Logo & Cover Photo)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LuxuryImagePickerField(
                          label: loc.isArabic ? 'شعار العيادة' : 'Clinic Logo',
                          height: 120,
                          onImageSelected: (path) => _logoPath = path,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LuxuryImagePickerField(
                          label: loc.isArabic ? 'صورة الغلاف' : 'Cover Banner',
                          height: 120,
                          onImageSelected: (path) => _coverPath = path,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Name EN
                  LtrTextFormField(
                    controller: _nameEnController,
                    style: TextStyle(color: AppColors.text(context), fontSize: 13),
                    decoration: InputDecoration(
                      labelText: loc.isArabic ? 'اسم العيادة بالإنجليزية *' : 'Clinic Name (English) *',
                      hintText: 'e.g. Cosmeceutical Elite Clinic',
                      prefixIcon: const Icon(Icons.apartment_rounded, color: AppColors.accentChampagne, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                  ),
                  const SizedBox(height: 10),

                  // Name AR
                  TextFormField(
                    controller: _nameArController,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(color: AppColors.text(context), fontSize: 13),
                    decoration: InputDecoration(
                      labelText: loc.isArabic ? 'اسم العيادة بالعربية *' : 'Clinic Name (Arabic) *',
                      hintText: 'مثال: عيادة النخبة للتجميل الطبي',
                      prefixIcon: const Icon(Icons.apartment_rounded, color: AppColors.accentChampagne, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                  ),
                  const SizedBox(height: 10),

                  // City Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCity,
                    dropdownColor: isDark ? AppColors.cardSurface : Colors.white,
                    decoration: InputDecoration(
                      labelText: loc.isArabic ? 'المدينة / الإمارة *' : 'City / Emirate *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _cities.map((city) => DropdownMenuItem(value: city, child: Text(city, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCity = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  // Clinic Phone & WhatsApp with LuxuryPhoneInputField
                  LuxuryPhoneInputField(
                    controller: _phoneController,
                    labelText: loc.isArabic ? 'هاتف العيادة *' : 'Clinic Phone *',
                    isRequired: true,
                  ),
                  const SizedBox(height: 10),
                  LuxuryPhoneInputField(
                    controller: _whatsappController,
                    labelText: 'WhatsApp',
                    isRequired: false,
                  ),
                  const SizedBox(height: 10),

                  // Subscription Tier Selector
                  DropdownButtonFormField<String>(
                    initialValue: _selectedTier,
                    dropdownColor: isDark ? AppColors.cardSurface : Colors.white,
                    decoration: InputDecoration(
                      labelText: loc.isArabic ? 'باقة الاشتراك (أولوية الظهور) *' : 'Subscription Tier (Priority) *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _tiers
                        .map((t) => DropdownMenuItem(
                              value: t['value'],
                              child: Text(
                                loc.isArabic ? t['labelAr']! : t['labelEn']!,
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTier = val);
                    },
                  ),
                  const SizedBox(height: 20),

                  // SECTION 2: ADMINISTRATOR CREDENTIALS
                  _SectionHeader(title: loc.isArabic ? '2. بيانات مسؤول العيادة (بيانات الدخول)' : '2. Initial Administrator Credentials'),
                  const SizedBox(height: 10),

                  // Admin Name
                  TextFormField(
                    controller: _adminNameController,
                    style: TextStyle(color: AppColors.text(context), fontSize: 13),
                    decoration: InputDecoration(
                      labelText: loc.isArabic ? 'اسم المسؤول بالكامل *' : 'Administrator Full Name *',
                      hintText: loc.isArabic ? 'مثال: د. سارة المنصوري' : 'e.g. Dr. Sarah Al Mansoori',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.accentChampagne, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                  ),
                  const SizedBox(height: 10),

                  // Admin Phone (+971...) with LuxuryPhoneInputField
                  LuxuryPhoneInputField(
                    controller: _adminPhoneController,
                    labelText: loc.isArabic ? 'رقم هاتف الدخول (اسم المستخدم) *' : 'Admin Login Phone *',
                    isRequired: true,
                  ),
                  const SizedBox(height: 10),

                  // Admin Email
                  LtrTextFormField(
                    controller: _adminEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: AppColors.text(context), fontSize: 13),
                    decoration: InputDecoration(
                      labelText: loc.isArabic ? 'البريد الإلكتروني' : 'Admin Email',
                      hintText: 'admin@clinic.ae',
                      prefixIcon: const Icon(Icons.email_outlined, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Temp Password with Auto-Generate Button
                  Row(
                    children: [
                      Expanded(
                        child: LtrTextFormField(
                          controller: _tempPasswordController,
                          style: TextStyle(color: AppColors.text(context), fontSize: 13),
                          decoration: InputDecoration(
                            labelText: loc.isArabic ? 'كلمة المرور المؤقتة *' : 'Temporary Password *',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.accentChampagne, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) => (val == null || val.trim().length < 6) ? loc.tr('clinic_validation_required') : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: _generatePassword,
                        tooltip: loc.isArabic ? 'توليد تلقائي' : 'Auto-Generate',
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        ),
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.accentChampagne, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Submit Button
            const SizedBox(height: 10),
            SilverButton(
              label: _isSubmitting
                  ? (loc.isArabic ? 'جاري إنشاء العيادة...' : 'Provisioning Clinic...')
                  : (loc.isArabic ? 'تأكيد إنشاء العيادة وتفويض المسؤول' : 'Provision Clinic & Administrator'),
              icon: Icons.check_circle_outline_rounded,
              isFullWidth: true,
              height: 48,
              onPressed: _isSubmitting ? null : _submitForm,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Text(
      title,
      style: AppTypography.cardTitle.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
      ),
    );
  }
}
