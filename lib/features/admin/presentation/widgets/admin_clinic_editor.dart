import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/local_media_cache.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/clinic_location.dart';
import '../../../../core/widgets/luxury_image_picker_field.dart';
import '../../../../core/widgets/luxury_phone_input_field.dart';
import '../../models/admin_clinic_model.dart';
import '../../../clinics/models/clinic_model.dart';
import '../../services/admin_portal_service.dart';
import 'admin_components.dart';

class AdminClinicEditor extends StatefulWidget {
  const AdminClinicEditor({super.key, this.clinic});
  final AdminClinicModel? clinic;
  @override
  State<AdminClinicEditor> createState() => _AdminClinicEditorState();
}

class _AdminClinicEditorState extends State<AdminClinicEditor> {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _fields = <String, TextEditingController>{};
  bool _busy = false, _showPassword = false, _handoff = false;
  bool _logoChanged = false, _coverChanged = false;
  bool _featured = false;
  String _city = 'Dubai', _tier = 'basic';
  String? _logo, _cover, _error;
  bool get _creating => widget.clinic == null;
  TextEditingController _field(String key) => _fields[key]!;
  @override
  void initState() {
    super.initState();
    final c = widget.clinic;
    final initial = {
      'name_en': c?.nameEn ?? '',
      'name_ar': c?.nameAr ?? '',
      'phone': c?.phone ?? '',
      'whatsapp': c?.whatsapp ?? '',
      'address_en': c?.addressEn ?? '',
      'address_ar': c?.addressAr ?? '',
      'email': c?.email ?? '',
      'admin_name': '',
      'admin_phone': '',
      'admin_email': '',
      'password': '',
    };
    for (final entry in initial.entries) {
      _fields[entry.key] = TextEditingController(text: entry.value);
    }
    _city = c == null ? 'Dubai' : c.city;
    _tier = c?.subscriptionTier.apiValue ?? 'basic';
    _featured = c?.isFeatured ?? false;
    if (_creating) _generatePassword();
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.clear();
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  void _generatePassword() {
    const alphabet =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%&*';
    final random = Random.secure();
    _field('password').text =
        'AW#${List.generate(13, (_) => alphabet[random.nextInt(alphabet.length)]).join()}';
  }

  String? _validateWholeForm() {
    if (_field('name_en').text.trim().isEmpty) {
      return adminText(
        'Enter the clinic name in English.',
        'أدخل اسم العيادة بالإنجليزية.',
      );
    }
    bool validPhone(String value) =>
        RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(value) &&
        LuxuryPhoneInputField.extractLocalDigits(value).length >= 7 &&
        LuxuryPhoneInputField.extractLocalDigits(value).length <= 10;
    if (!validPhone(_field('phone').text)) {
      return adminText(
        'Enter a valid clinic phone number.',
        'أدخل رقم هاتف صالحاً للعيادة.',
      );
    }
    if (_field('whatsapp').text.isNotEmpty &&
        !validPhone(_field('whatsapp').text)) {
      return adminText(
        'Enter a valid WhatsApp number.',
        'أدخل رقم واتساب صالحاً.',
      );
    }
    for (final key in ['email', if (_creating) 'admin_email']) {
      final value = _field(key).text.trim();
      if (value.isNotEmpty &&
          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
        return adminText(
          'Enter a valid email address.',
          'أدخل بريداً إلكترونياً صالحاً.',
        );
      }
    }
    if (_creating && _field('admin_name').text.trim().isEmpty) {
      return adminText(
        'Enter the administrator full name.',
        'أدخل اسم مسؤول العيادة.',
      );
    }
    if (_creating && !validPhone(_field('admin_phone').text)) {
      return adminText(
        'Enter a valid administrator login phone.',
        'أدخل رقم دخول صالحاً لمسؤول العيادة.',
      );
    }
    if (_creating && _field('password').text.length < 8) {
      return adminText(
        'Use at least 8 password characters.',
        'استخدم كلمة مرور من 8 أحرف على الأقل.',
      );
    }
    return null;
  }

  Future<void> _save() async {
    if (_busy || _handoff) return;
    final message = _validateWholeForm();
    final valid = _form.currentState!.validate();
    if (message != null || !valid) {
      setState(
        () => _error =
            message ??
            adminText('Please check the form.', 'يرجى مراجعة الحقول.'),
      );
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final payload = <String, dynamic>{
      for (final key in [
        'name_en',
        'name_ar',
        'address_en',
        'address_ar',
        'email',
      ])
        key: _field(key).text.trim(),
      'phone': LuxuryPhoneInputField.normalizeToE164(_field('phone').text),
      'whatsapp': LuxuryPhoneInputField.normalizeToE164(
        _field('whatsapp').text,
      ),
      'city': _city,
      'emirate': widget.clinic != null && _city == widget.clinic!.city
          ? widget.clinic!.emirate
          : _city,
      'subscription_tier': _tier,
      'is_featured': _featured,
      if (_logoChanged) 'logo': _logo,
      if (_coverChanged) 'cover_image': _cover,
      if (_creating)
        'admin_user': {
          'full_name': _field('admin_name').text.trim(),
          'phone': LuxuryPhoneInputField.normalizeToE164(
            _field('admin_phone').text,
          ),
          'email': _field('admin_email').text.trim(),
          'temporary_password': _field('password').text,
        },
    };
    try {
      final service = AdminPortalService();
      if (_creating) {
        final result = await service.createClinic(payload);
        if (!mounted) return;
        _field('password').clear();
        setState(() {
          _busy = false;
          _handoff = true;
        });
        await showAdminCredentials(context, result: result);
      } else {
        await service.updateClinic(widget.clinic!.id, payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error is ApiException
            ? error.message
            : adminText(
                'Could not save the clinic. Please retry.',
                'تعذر حفظ بيانات العيادة. حاول مجدداً.',
              );
      });
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Widget _textField(
    String key,
    String en,
    String ar, {
    bool required = false,
    bool rtl = false,
    bool email = false,
    int max = 200,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      key: ValueKey('admin-$key'),
      controller: _field(key),
      enabled: !_busy,
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      maxLength: max,
      keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: '${adminText(en, ar)}${required ? ' *' : ''}',
        counterText: '',
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) {
          return LocaleService().tr('clinic_validation_required');
        }
        if (email &&
            text.isNotEmpty &&
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
          return adminText(
            'Enter a valid email address.',
            'أدخل بريداً إلكترونياً صالحاً.',
          );
        }
        return null;
      },
    ),
  );
  @override
  Widget build(BuildContext context) {
    final c = widget.clinic;
    return PopScope(
      canPop: !_busy,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _form,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      controller: _scroll,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _creating
                                    ? adminText(
                                        'Provision New Partner Clinic',
                                        'إضافة عيادة شريكة جديدة',
                                      )
                                    : adminText(
                                        'Edit Clinic Details & Branding',
                                        'تعديل بيانات وهوية العيادة',
                                      ),
                                style: TextStyle(
                                  color: AppColors.text(context),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _busy
                                  ? null
                                  : () => Navigator.pop(context),
                              tooltip: adminText('Close', 'إغلاق'),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        if (_error != null)
                          AdminNotice(message: _error!, error: true),
                        AdminSectionTitle(
                          adminText('Clinic identity', 'هوية العيادة'),
                        ),
                        LayoutBuilder(
                          builder: (context, box) {
                            final logo = LuxuryImagePickerField(
                              label: adminText('Clinic Logo', 'شعار العيادة'),
                              initialUrl: c?.logo,
                              initialLocalPath: c == null
                                  ? null
                                  : LocalMediaCache().lookup(
                                      entityKey: LocalMediaCache.clinicLogo(
                                        c.id,
                                      ),
                                      remoteUrl: c.logo,
                                    ),
                              mediaCacheKey: c == null
                                  ? null
                                  : LocalMediaCache.clinicLogo(c.id),
                              height: 120,
                              fit: BoxFit.contain,
                              enabled: !_busy,
                              compactPlaceholder: true,
                              onImageSelected: (path) {
                                _logo = path;
                                _logoChanged = true;
                              },
                            );
                            final cover = LuxuryImagePickerField(
                              label: adminText('Cover Banner', 'صورة الغلاف'),
                              initialUrl: c?.coverImage,
                              initialLocalPath: c == null
                                  ? null
                                  : LocalMediaCache().lookup(
                                      entityKey: LocalMediaCache.clinicCover(
                                        c.id,
                                      ),
                                      remoteUrl: c.coverImage,
                                    ),
                              mediaCacheKey: c == null
                                  ? null
                                  : LocalMediaCache.clinicCover(c.id),
                              height: 120,
                              enabled: !_busy,
                              compactPlaceholder: true,
                              onImageSelected: (path) {
                                _cover = path;
                                _coverChanged = true;
                              },
                            );
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: logo),
                                const SizedBox(width: 12),
                                Expanded(flex: 3, child: cover),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        _textField(
                          'name_en',
                          'Clinic Name (English)',
                          'اسم العيادة بالإنجليزية',
                          required: true,
                        ),
                        _textField(
                          'name_ar',
                          'Clinic Name (Arabic)',
                          'اسم العيادة بالعربية',
                          rtl: true,
                        ),
                        AdminSectionTitle(
                          adminText(
                            'Official contact details',
                            'بيانات التواصل الرسمية',
                          ),
                        ),
                        LuxuryPhoneInputField(
                          fieldKey: const ValueKey('admin-clinic-phone'),
                          controller: _field('phone'),
                          labelText: adminText(
                            'Clinic Phone *',
                            'هاتف العيادة *',
                          ),
                          isRequired: true,
                          enabled: !_busy,
                        ),
                        const SizedBox(height: 14),
                        LuxuryPhoneInputField(
                          fieldKey: const ValueKey('admin-clinic-whatsapp'),
                          controller: _field('whatsapp'),
                          labelText: adminText(
                            'Clinic WhatsApp',
                            'واتساب العيادة',
                          ),
                          enabled: !_busy,
                        ),
                        const SizedBox(height: 14),
                        _textField(
                          'email',
                          'Clinic Email',
                          'البريد الإلكتروني للعيادة',
                          email: true,
                          max: 254,
                        ),
                        AdminSectionTitle(
                          adminText('Clinic address', 'عنوان العيادة'),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _city,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: adminText(
                              'City / Emirate',
                              'المدينة / الإمارة',
                            ),
                          ),
                          items: {...clinicCities.keys, _city}
                              .map(
                                (city) => DropdownMenuItem(
                                  value: city,
                                  child: Text(
                                    city.isEmpty
                                        ? adminText('Not provided', 'غير متوفر')
                                        : localizedClinicCity(
                                            city,
                                            arabic: LocaleService().isArabic,
                                          ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _busy
                              ? null
                              : (v) {
                                  if (v != null) setState(() => _city = v);
                                },
                        ),
                        const SizedBox(height: 14),
                        _textField(
                          'address_en',
                          'Address (English)',
                          'العنوان بالإنجليزية',
                          max: 500,
                        ),
                        _textField(
                          'address_ar',
                          'Address (Arabic)',
                          'العنوان بالعربية',
                          rtl: true,
                          max: 500,
                        ),
                        AdminNotice(
                          message: adminText(
                            'Address changes can be saved. Updating the location pin is currently unavailable here.',
                            'يمكن حفظ تعديل العنوان. تعديل دبوس الموقع غير متاح هنا حالياً.',
                          ),
                        ),
                        AdminSectionTitle(
                          adminText(
                            'Subscription & placement',
                            'الاشتراك والظهور',
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          key: const ValueKey('admin-tier'),
                          initialValue: _tier,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: adminText(
                              'Subscription Tier',
                              'فئة الاشتراك',
                            ),
                          ),
                          items: [
                            for (final (value, label) in [
                              ('basic', adminText('Basic', 'أساسي')),
                              ('featured', adminText('Featured', 'مميز')),
                              ('vip', adminText('VIP Platinum', 'بلاتيني VIP')),
                            ])
                              DropdownMenuItem(
                                value: value,
                                child: Text(label),
                              ),
                          ],
                          onChanged: _busy
                              ? null
                              : (v) {
                                  if (v != null) setState(() => _tier = v);
                                },
                        ),
                        SwitchListTile(
                          key: const ValueKey('admin-home-featured'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            adminText(
                              'Feature Clinic on Home Page',
                              'تمييز العيادة في الصفحة الرئيسية',
                            ),
                          ),
                          subtitle: Text(
                            adminText(
                              'Independent of the subscription tier.',
                              'إعداد مستقل عن فئة الاشتراك.',
                            ),
                          ),
                          value: _featured,
                          onChanged: _busy
                              ? null
                              : (v) => setState(() => _featured = v),
                        ),
                        if (_creating) ...[
                          AdminSectionTitle(
                            adminText(
                              'Initial Administrator Credentials',
                              'بيانات مسؤول العيادة الأول',
                            ),
                          ),
                          _textField(
                            'admin_name',
                            'Administrator Full Name',
                            'اسم المسؤول بالكامل',
                            required: true,
                          ),
                          LuxuryPhoneInputField(
                            fieldKey: const ValueKey('admin-login-phone'),
                            controller: _field('admin_phone'),
                            labelText: adminText(
                              'Admin Login Phone *',
                              'هاتف دخول المسؤول *',
                            ),
                            isRequired: true,
                            enabled: !_busy,
                          ),
                          const SizedBox(height: 14),
                          _textField(
                            'admin_email',
                            'Admin Email',
                            'البريد الإلكتروني للمسؤول',
                            email: true,
                            max: 254,
                          ),
                          TextFormField(
                            key: const ValueKey('admin-temporary-password'),
                            controller: _field('password'),
                            enabled: !_busy,
                            textDirection: TextDirection.ltr,
                            obscureText: !_showPassword,
                            autocorrect: false,
                            enableSuggestions: false,
                            maxLength: 128,
                            decoration: InputDecoration(
                              labelText: adminText(
                                'Temporary Password',
                                'كلمة المرور المؤقتة',
                              ),
                              counterText: '',
                              suffixIcon: IconButton(
                                onPressed: _busy
                                    ? null
                                    : () => setState(
                                        () => _showPassword = !_showPassword,
                                      ),
                                tooltip: adminText(
                                  'Show or hide password',
                                  'إظهار كلمة المرور أو إخفاؤها',
                                ),
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: (v) => (v?.length ?? 0) < 8
                                ? adminText(
                                    'Use at least 8 characters.',
                                    'استخدم 8 أحرف على الأقل.',
                                  )
                                : null,
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton.icon(
                              onPressed: _busy ? null : _generatePassword,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(
                                adminText('Auto-Generate', 'توليد تلقائي'),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const ValueKey('admin-save-clinic'),
                      onPressed:
                          _busy || _handoff || !AdminPortalService().canManage
                          ? null
                          : _save,
                      icon: _busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _busy
                              ? adminText('Saving…', 'جارٍ الحفظ…')
                              : _creating
                              ? adminText(
                                  'Provision Clinic & Administrator',
                                  'إنشاء العيادة وتفويض المسؤول',
                                )
                              : adminText('Save Changes', 'حفظ التعديلات'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secrets exist only in this transient dialog, never portal state or logs.
Future<void> showAdminCredentials(
  BuildContext context, {
  required Map<String, dynamic> result,
  bool reset = false,
}) async {
  final admin = result['admin_user'] is Map
      ? result['admin_user'] as Map
      : result;
  final clinic = result['clinic'] is Map ? result['clinic'] as Map : const {};
  final password = admin['temporary_password']?.toString() ?? '';
  final phone = (admin['phone'] ?? admin['admin_phone'])?.toString() ?? '';
  final name = (clinic['name_en'] ?? clinic['name_ar'])?.toString() ?? '';
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      scrollable: true,
      title: Text(
        reset
            ? adminText('Password Reset Complete', 'تم تعيين كلمة المرور')
            : adminText(
                'Clinic & Admin Provisioned',
                'تم إنشاء العيادة وحساب المسؤول',
              ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (name.isNotEmpty)
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (phone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SelectableText(phone, textDirection: TextDirection.ltr),
            ),
          if (password.isEmpty)
            AdminNotice(
              message: adminText(
                'The server did not return a temporary password. Use Reset Admin Password to obtain new credentials.',
                'لم يُرجع الخادم كلمة مرور مؤقتة. استخدم إعادة تعيين كلمة المرور للحصول على بيانات دخول جديدة.',
              ),
              error: true,
            )
          else ...[
            Text(
              adminText(
                'Securely hand these credentials to the clinic administrator.',
                'سلّم بيانات الدخول لمسؤول العيادة بطريقة آمنة.',
              ),
              style: TextStyle(color: AppColors.mutedText(ctx), height: 1.5),
            ),
            const SizedBox(height: 12),
            SelectableText(
              password,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: AppColors.text(ctx),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Clipboard.setData(
                ClipboardData(text: 'AESTHETIC WAY\n$name\n$phone\n$password'),
              ),
              icon: const Icon(Icons.copy),
              label: Text(
                adminText(
                  'Copy Credentials to Clipboard',
                  'نسخ بيانات الدخول للحافظة',
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(adminText('Done', 'تم')),
        ),
      ],
    ),
  );
}
