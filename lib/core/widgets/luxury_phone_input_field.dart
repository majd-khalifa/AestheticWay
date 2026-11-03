import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import '../utils/international_phone.dart';

/// Supported GCC and international dial codes
class CountryDialCode {
  final String flag;
  final String dialCode;
  final String nameAr;
  final String nameEn;

  const CountryDialCode({
    required this.flag,
    required this.dialCode,
    required this.nameAr,
    required this.nameEn,
  });

  IsoCode get isoCode => IsoCode.values.byName(
    String.fromCharCodes(flag.runes.map((r) => r - 0x1f1e6 + 65)),
  );
}

const List<CountryDialCode> kSupportedDialCodes = [
  // 1. All 22 Arab League Countries (UAE +971 is primary default)
  CountryDialCode(
    flag: '🇦🇪',
    dialCode: '+971',
    nameAr: 'الإمارات العربية المتحدة',
    nameEn: 'United Arab Emirates',
  ),
  CountryDialCode(
    flag: '🇸🇦',
    dialCode: '+966',
    nameAr: 'المملكة العربية السعودية',
    nameEn: 'Saudi Arabia',
  ),
  CountryDialCode(
    flag: '🇰🇼',
    dialCode: '+965',
    nameAr: 'الكويت',
    nameEn: 'Kuwait',
  ),
  CountryDialCode(
    flag: '🇶🇦',
    dialCode: '+974',
    nameAr: 'قطر',
    nameEn: 'Qatar',
  ),
  CountryDialCode(
    flag: '🇧🇭',
    dialCode: '+973',
    nameAr: 'البحرين',
    nameEn: 'Bahrain',
  ),
  CountryDialCode(
    flag: '🇴🇲',
    dialCode: '+968',
    nameAr: 'عُمان',
    nameEn: 'Oman',
  ),
  CountryDialCode(
    flag: '🇪🇬',
    dialCode: '+20',
    nameAr: 'مصر',
    nameEn: 'Egypt',
  ),
  CountryDialCode(
    flag: '🇯🇴',
    dialCode: '+962',
    nameAr: 'الأردن',
    nameEn: 'Jordan',
  ),
  CountryDialCode(
    flag: '🇱🇧',
    dialCode: '+961',
    nameAr: 'لبنان',
    nameEn: 'Lebanon',
  ),
  CountryDialCode(
    flag: '🇸🇾',
    dialCode: '+963',
    nameAr: 'سوريا',
    nameEn: 'Syria',
  ),
  CountryDialCode(
    flag: '🇮🇶',
    dialCode: '+964',
    nameAr: 'العراق',
    nameEn: 'Iraq',
  ),
  CountryDialCode(
    flag: '🇵🇸',
    dialCode: '+970',
    nameAr: 'فلسطين',
    nameEn: 'Palestine',
  ),
  CountryDialCode(
    flag: '🇾🇪',
    dialCode: '+967',
    nameAr: 'اليمن',
    nameEn: 'Yemen',
  ),
  CountryDialCode(
    flag: '🇱🇾',
    dialCode: '+218',
    nameAr: 'ليبيا',
    nameEn: 'Libya',
  ),
  CountryDialCode(
    flag: '🇹🇳',
    dialCode: '+216',
    nameAr: 'تونس',
    nameEn: 'Tunisia',
  ),
  CountryDialCode(
    flag: '🇩🇿',
    dialCode: '+213',
    nameAr: 'الجزائر',
    nameEn: 'Algeria',
  ),
  CountryDialCode(
    flag: '🇲🇦',
    dialCode: '+212',
    nameAr: 'المغرب',
    nameEn: 'Morocco',
  ),
  CountryDialCode(
    flag: '🇸🇩',
    dialCode: '+249',
    nameAr: 'السودان',
    nameEn: 'Sudan',
  ),
  CountryDialCode(
    flag: '🇲🇷',
    dialCode: '+222',
    nameAr: 'موريتانيا',
    nameEn: 'Mauritania',
  ),
  CountryDialCode(
    flag: '🇸🇴',
    dialCode: '+252',
    nameAr: 'الصومال',
    nameEn: 'Somalia',
  ),
  CountryDialCode(
    flag: '🇩🇯',
    dialCode: '+253',
    nameAr: 'جيبوتي',
    nameEn: 'Djibouti',
  ),
  CountryDialCode(
    flag: '🇰🇲',
    dialCode: '+269',
    nameAr: 'جزر القمر',
    nameEn: 'Comoros',
  ),

  // 2. Major European Countries
  CountryDialCode(
    flag: '🇬🇧',
    dialCode: '+44',
    nameAr: 'المملكة المتحدة',
    nameEn: 'United Kingdom',
  ),
  CountryDialCode(
    flag: '🇩🇪',
    dialCode: '+49',
    nameAr: 'ألمانيا',
    nameEn: 'Germany',
  ),
  CountryDialCode(
    flag: '🇫🇷',
    dialCode: '+33',
    nameAr: 'فرنسا',
    nameEn: 'France',
  ),
  CountryDialCode(
    flag: '🇮🇹',
    dialCode: '+39',
    nameAr: 'إيطاليا',
    nameEn: 'Italy',
  ),
  CountryDialCode(
    flag: '🇪🇸',
    dialCode: '+34',
    nameAr: 'إسبانيا',
    nameEn: 'Spain',
  ),
  CountryDialCode(
    flag: '🇨🇭',
    dialCode: '+41',
    nameAr: 'سويسرا',
    nameEn: 'Switzerland',
  ),
  CountryDialCode(
    flag: '🇳🇱',
    dialCode: '+31',
    nameAr: 'هولندا',
    nameEn: 'Netherlands',
  ),
  CountryDialCode(
    flag: '🇹🇷',
    dialCode: '+90',
    nameAr: 'تركيا',
    nameEn: 'Turkey',
  ),
  CountryDialCode(
    flag: '🇸🇪',
    dialCode: '+46',
    nameAr: 'السويد',
    nameEn: 'Sweden',
  ),
  CountryDialCode(
    flag: '🇳🇴',
    dialCode: '+47',
    nameAr: 'النرويج',
    nameEn: 'Norway',
  ),
  CountryDialCode(
    flag: '🇩🇰',
    dialCode: '+45',
    nameAr: 'الدنمارك',
    nameEn: 'Denmark',
  ),
  CountryDialCode(
    flag: '🇫🇮',
    dialCode: '+358',
    nameAr: 'فنلندا',
    nameEn: 'Finland',
  ),
  CountryDialCode(
    flag: '🇦🇹',
    dialCode: '+43',
    nameAr: 'النمسا',
    nameEn: 'Austria',
  ),
  CountryDialCode(
    flag: '🇧🇪',
    dialCode: '+32',
    nameAr: 'بلجيكا',
    nameEn: 'Belgium',
  ),
  CountryDialCode(
    flag: '🇮🇪',
    dialCode: '+353',
    nameAr: 'أيرلندا',
    nameEn: 'Ireland',
  ),
  CountryDialCode(
    flag: '🇵🇹',
    dialCode: '+351',
    nameAr: 'البرتغال',
    nameEn: 'Portugal',
  ),
  CountryDialCode(
    flag: '🇬🇷',
    dialCode: '+30',
    nameAr: 'اليونان',
    nameEn: 'Greece',
  ),
  CountryDialCode(
    flag: '🇵🇱',
    dialCode: '+48',
    nameAr: 'بولندا',
    nameEn: 'Poland',
  ),
  CountryDialCode(
    flag: '🇨🇿',
    dialCode: '+420',
    nameAr: 'التشيك',
    nameEn: 'Czech Republic',
  ),
  CountryDialCode(
    flag: '🇷🇴',
    dialCode: '+40',
    nameAr: 'رومانيا',
    nameEn: 'Romania',
  ),
  CountryDialCode(
    flag: '🇭🇺',
    dialCode: '+36',
    nameAr: 'المجر',
    nameEn: 'Hungary',
  ),
  CountryDialCode(
    flag: '🇨🇾',
    dialCode: '+357',
    nameAr: 'قبرص',
    nameEn: 'Cyprus',
  ),
  CountryDialCode(
    flag: '🇷🇺',
    dialCode: '+7',
    nameAr: 'روسيا',
    nameEn: 'Russia',
  ),

  CountryDialCode(
    flag: '🇦🇱',
    dialCode: '+355',
    nameAr: 'ألبانيا',
    nameEn: 'Albania',
  ),
  CountryDialCode(
    flag: '🇦🇩',
    dialCode: '+376',
    nameAr: 'أندورا',
    nameEn: 'Andorra',
  ),
  CountryDialCode(
    flag: '🇧🇾',
    dialCode: '+375',
    nameAr: 'بيلاروس',
    nameEn: 'Belarus',
  ),
  CountryDialCode(
    flag: '🇧🇦',
    dialCode: '+387',
    nameAr: 'البوسنة والهرسك',
    nameEn: 'Bosnia and Herzegovina',
  ),
  CountryDialCode(
    flag: '🇧🇬',
    dialCode: '+359',
    nameAr: 'بلغاريا',
    nameEn: 'Bulgaria',
  ),
  CountryDialCode(
    flag: '🇭🇷',
    dialCode: '+385',
    nameAr: 'كرواتيا',
    nameEn: 'Croatia',
  ),
  CountryDialCode(
    flag: '🇪🇪',
    dialCode: '+372',
    nameAr: 'إستونيا',
    nameEn: 'Estonia',
  ),
  CountryDialCode(
    flag: '🇮🇸',
    dialCode: '+354',
    nameAr: 'آيسلندا',
    nameEn: 'Iceland',
  ),
  CountryDialCode(
    flag: '🇱🇻',
    dialCode: '+371',
    nameAr: 'لاتفيا',
    nameEn: 'Latvia',
  ),
  CountryDialCode(
    flag: '🇱🇮',
    dialCode: '+423',
    nameAr: 'ليختنشتاين',
    nameEn: 'Liechtenstein',
  ),
  CountryDialCode(
    flag: '🇱🇹',
    dialCode: '+370',
    nameAr: 'ليتوانيا',
    nameEn: 'Lithuania',
  ),
  CountryDialCode(
    flag: '🇱🇺',
    dialCode: '+352',
    nameAr: 'لوكسمبورغ',
    nameEn: 'Luxembourg',
  ),
  CountryDialCode(
    flag: '🇲🇹',
    dialCode: '+356',
    nameAr: 'مالطا',
    nameEn: 'Malta',
  ),
  CountryDialCode(
    flag: '🇲🇩',
    dialCode: '+373',
    nameAr: 'مولدوفا',
    nameEn: 'Moldova',
  ),
  CountryDialCode(
    flag: '🇲🇨',
    dialCode: '+377',
    nameAr: 'موناكو',
    nameEn: 'Monaco',
  ),
  CountryDialCode(
    flag: '🇲🇪',
    dialCode: '+382',
    nameAr: 'الجبل الأسود',
    nameEn: 'Montenegro',
  ),
  CountryDialCode(
    flag: '🇲🇰',
    dialCode: '+389',
    nameAr: 'مقدونيا الشمالية',
    nameEn: 'North Macedonia',
  ),
  CountryDialCode(
    flag: '🇸🇲',
    dialCode: '+378',
    nameAr: 'سان مارينو',
    nameEn: 'San Marino',
  ),
  CountryDialCode(
    flag: '🇷🇸',
    dialCode: '+381',
    nameAr: 'صربيا',
    nameEn: 'Serbia',
  ),
  CountryDialCode(
    flag: '🇸🇰',
    dialCode: '+421',
    nameAr: 'سلوفاكيا',
    nameEn: 'Slovakia',
  ),
  CountryDialCode(
    flag: '🇸🇮',
    dialCode: '+386',
    nameAr: 'سلوفينيا',
    nameEn: 'Slovenia',
  ),
  CountryDialCode(
    flag: '🇺🇦',
    dialCode: '+380',
    nameAr: 'أوكرانيا',
    nameEn: 'Ukraine',
  ),
  CountryDialCode(
    flag: '🇽🇰',
    dialCode: '+383',
    nameAr: 'كوسوفو',
    nameEn: 'Kosovo',
  ),

  // 3. North America
  CountryDialCode(
    flag: '🇺🇸',
    dialCode: '+1',
    nameAr: 'الولايات المتحدة',
    nameEn: 'United States',
  ),
  CountryDialCode(
    flag: '🇨🇦',
    dialCode: '+1',
    nameAr: 'كندا',
    nameEn: 'Canada',
  ),
];

/// Reusable Luxury Phone Input Field
/// - Forces TextDirection.ltr so numbers never scramble in Arabic RTL mode
/// - Prefix country dial code selector defaulting to UAE (🇦🇪 +971)
/// - Uses country-aware numbering validation; never truncates pasted numbers
/// - Automatically normalizes E.164 and strips leading zeros (e.g. 0501234567 -> +971501234567)
class LuxuryPhoneInputField extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String? labelText;
  final String? hintText;
  final bool isRequired;
  final bool readOnly;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final String defaultDialCode;
  final Key? fieldKey;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const LuxuryPhoneInputField({
    super.key,
    this.controller,
    this.initialValue,
    this.labelText,
    this.hintText,
    this.isRequired = false,
    this.readOnly = false,
    this.enabled = true,
    this.onChanged,
    this.validator,
    this.defaultDialCode = '+971',
    this.fieldKey,
    this.suffixIcon,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  /// Internal helper to sort dial codes by length descending for greedy matching
  static List<CountryDialCode> get _sortedDialCodes {
    final list = List<CountryDialCode>.from(kSupportedDialCodes);
    list.sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
    return list;
  }

  /// Static helper to normalize any phone string and country code into standard E.164
  static String normalizeToE164(
    String rawInput, {
    String defaultDialCode = '+971',
  }) {
    return InternationalPhone.normalize(
      rawInput,
      country: extractCountry(
        rawInput,
        defaultDialCode: defaultDialCode,
      ).isoCode,
    );
  }

  static String extractLocalDigits(
    String rawInput, {
    String defaultDialCode = '+971',
  }) {
    return InternationalPhone.localDigits(
      rawInput,
      country: extractCountry(
        rawInput,
        defaultDialCode: defaultDialCode,
      ).isoCode,
    );
  }

  /// Extracts dial code from raw input if matched, otherwise returns defaultDialCode
  static CountryDialCode extractCountry(
    String rawInput, {
    String defaultDialCode = '+971',
  }) {
    final cleaned = InternationalPhone.asciiDigits(
      rawInput,
    ).replaceAll(RegExp(r'[^\d+]'), '').trim();
    // Calling codes can be shared (for example US/Canada +1). A complete,
    // valid number identifies its numbering region; partial edits still use
    // the longest calling-code match below.
    final international = cleaned.startsWith('00')
        ? '+${cleaned.substring(2)}'
        : cleaned;
    if (international.startsWith('+')) {
      try {
        final parsed = PhoneNumber.parse(international);
        if (parsed.isValid()) {
          for (final country in kSupportedDialCodes) {
            if (country.isoCode == parsed.isoCode) return country;
          }
        }
      } catch (_) {
        // Invalid/partial input is validated by the field, never logged.
      }
    }
    for (final country in _sortedDialCodes) {
      final code = country.dialCode;
      final codeNoPlus = code.replaceFirst('+', '');
      if (cleaned.startsWith(code) || cleaned.startsWith('00$codeNoPlus')) {
        return country;
      }
    }
    return kSupportedDialCodes.firstWhere(
      (c) => c.dialCode == defaultDialCode,
      orElse: () => kSupportedDialCodes.first,
    );
  }

  @override
  State<LuxuryPhoneInputField> createState() => _LuxuryPhoneInputFieldState();
}

class _LuxuryPhoneInputFieldState extends State<LuxuryPhoneInputField> {
  late CountryDialCode _selectedCountry;
  late final TextEditingController _localController;
  bool _isInternalController = false;
  bool _processingLocalEdit = false;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialValue ?? widget.controller?.text ?? '';
    _selectedCountry = LuxuryPhoneInputField.extractCountry(
      initial,
      defaultDialCode: widget.defaultDialCode,
    );

    final localDigits = LuxuryPhoneInputField.extractLocalDigits(
      initial,
      defaultDialCode: _selectedCountry.dialCode,
    );
    _localController = TextEditingController(text: localDigits);
    _isInternalController = true;

    // Sync external controller if present
    _syncExternalController(localDigits);

    _localController.addListener(_handleLocalTextChanged);
  }

  @override
  void didUpdateWidget(covariant LuxuryPhoneInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null &&
        widget.controller != oldWidget.controller) {
      final text = widget.controller!.text;
      _selectedCountry = LuxuryPhoneInputField.extractCountry(
        text,
        defaultDialCode: widget.defaultDialCode,
      );
      final localDigits = LuxuryPhoneInputField.extractLocalDigits(
        text,
        defaultDialCode: _selectedCountry.dialCode,
      );
      if (localDigits != _localController.text) {
        _localController.text = localDigits;
      }
    }
  }

  @override
  void dispose() {
    _localController.removeListener(_handleLocalTextChanged);
    if (_isInternalController) {
      _localController.dispose();
    }
    super.dispose();
  }

  void _handleLocalTextChanged() {
    if (_processingLocalEdit) return;
    _processingLocalEdit = true;
    try {
      var local = _localController.text;
      if (local.startsWith('+') || local.startsWith('00')) {
        final country = LuxuryPhoneInputField.extractCountry(local);
        final digits = LuxuryPhoneInputField.extractLocalDigits(local);
        setState(() => _selectedCountry = country);
        _localController.value = TextEditingValue(
          text: digits,
          selection: TextSelection.collapsed(offset: digits.length),
        );
        local = digits;
      }
      _syncExternalController(local);
    } finally {
      _processingLocalEdit = false;
    }
  }

  void _syncExternalController(String localDigits) {
    final fullNumber = InternationalPhone.normalize(
      localDigits,
      country: _selectedCountry.isoCode,
    );

    if (widget.controller != null && widget.controller!.text != fullNumber) {
      widget.controller!.text = fullNumber;
    }
    widget.onChanged?.call(fullNumber);
  }

  Future<void> _showCountryPicker() async {
    if (widget.readOnly || !widget.enabled) return;
    final selected = await showModalBottomSheet<CountryDialCode>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface(context),
      builder: (_) => _CountryCodeSheet(selected: _selectedCountry),
    );
    if (!mounted || selected == null || !widget.enabled) return;
    setState(() => _selectedCountry = selected);
    _syncExternalController(_localController.text);
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    final defaultLabel = loc.tr('phone_number');
    final effectiveLabel = widget.labelText ?? defaultLabel;
    final effectiveHint = widget.hintText ?? '50 123 4567';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextFormField(
        key: widget.fieldKey,
        controller: _localController,
        focusNode: widget.focusNode,
        keyboardType: TextInputType.phone,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
        readOnly: widget.readOnly,
        enabled: widget.enabled,
        maxLength: InternationalPhone.inputLimit(_selectedCountry.isoCode),
        maxLengthEnforcement: MaxLengthEnforcement.none,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted,
        inputFormatters: [
          TextInputFormatter.withFunction((oldValue, newValue) {
            final text = InternationalPhone.asciiDigits(
              newValue.text,
            ).replaceAll(RegExp(r'[^0-9+]'), '');
            final international = text.startsWith('00')
                ? '+${text.substring(2)}'
                : text;
            if (international.startsWith('+') &&
                !kSupportedDialCodes.any(
                  (c) => international.startsWith(c.dialCode),
                )) {
              return oldValue;
            }
            if (text.contains('+') && !text.startsWith('+')) return oldValue;
            if (text == newValue.text) return newValue;
            int offset(int original) {
              if (original < 0) return text.length;
              final prefix = newValue.text.substring(
                0,
                original.clamp(0, newValue.text.length),
              );
              return InternationalPhone.asciiDigits(
                prefix,
              ).replaceAll(RegExp(r'[^0-9+]'), '').length;
            }

            return TextEditingValue(
              text: text,
              selection: TextSelection(
                baseOffset: offset(newValue.selection.baseOffset),
                extentOffset: offset(newValue.selection.extentOffset),
              ),
            );
          }),
        ],
        style: TextStyle(
          color: widget.readOnly
              ? AppColors.mutedText(context)
              : (isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
        decoration: InputDecoration(
          counterText: '',
          labelText: effectiveLabel,
          hintText: effectiveHint,
          hintStyle: TextStyle(
            color: AppColors.text(context).withValues(alpha: 0.68),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
          labelStyle: TextStyle(
            color: AppColors.mutedText(context),
            fontSize: 12.5,
          ),
          floatingLabelStyle: TextStyle(
            color: isDark ? AppColors.silverPrimary : AppColors.primarySoftNavy,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: widget.readOnly
              ? (isDark ? AppColors.cardSurface : AppColors.lightBackgroundAlt)
              : (isDark
                    ? AppColors.cardSurfaceHover
                    : AppColors.lightCardSurfaceHover),
          prefixIcon: InkWell(
            onTap: widget.readOnly ? null : _showCountryPicker,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: AppColors.border(context).withValues(alpha: 0.8),
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedCountry.flag,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _selectedCountry.dialCode,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.silverPrimary
                          : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (!widget.readOnly && widget.enabled) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 18,
                      color: AppColors.mutedText(context),
                    ),
                  ],
                ],
              ),
            ),
          ),
          suffixIcon:
              widget.suffixIcon ??
              (widget.readOnly
                  ? Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: AppColors.mutedText(context),
                    )
                  : null),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.border(context),
              width: 0.8,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark
                  ? AppColors.silverPrimary
                  : AppColors.primarySoftNavy,
              width: 1.4,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.errorRed, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.errorRed, width: 1.4),
          ),
        ),
        validator: (val) {
          if (widget.readOnly) return widget.validator?.call(val);
          final issue = InternationalPhone.issue(
            val ?? '',
            country: _selectedCountry.isoCode,
            required: widget.isRequired,
          );
          if (issue == PhoneNumberIssue.required) {
            return loc.tr('val_phone_required');
          }
          if (issue == PhoneNumberIssue.length) {
            return loc.isArabic
                ? 'عدد الأرقام غير صالح للدولة المختارة. تحقق من الرقم كاملاً.'
                : 'Invalid number length for the selected country. Check the complete number.';
          }
          if (issue != null) {
            return loc.isArabic
                ? 'أدخل رقم هاتف صالحاً للدولة المختارة.'
                : 'Enter a valid phone number for the selected country.';
          }
          return widget.validator?.call(val);
        },
      ),
    );
  }
}

class _CountryCodeSheet extends StatefulWidget {
  const _CountryCodeSheet({required this.selected});
  final CountryDialCode selected;
  @override
  State<_CountryCodeSheet> createState() => _CountryCodeSheetState();
}

class _CountryCodeSheetState extends State<_CountryCodeSheet> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService(), query = _search.text.toLowerCase().trim();
    final countries = kSupportedDialCodes
        .where(
          (c) => '${c.nameEn} ${c.nameAr} ${c.dialCode}'.toLowerCase().contains(
            query,
          ),
        )
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.viewInsetsOf(context).bottom + 8,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.isArabic ? 'اختر رمز الدولة' : 'Select Country Code',
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: loc.isArabic ? 'إغلاق' : 'Close',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                decoration: InputDecoration(
                  labelText: loc.isArabic
                      ? 'البحث باسم الدولة أو رمزها'
                      : 'Search country or dial code',
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: countries.length,
                  itemBuilder: (context, index) {
                    final c = countries[index];
                    return ListTile(
                      minTileHeight: 56,
                      leading: Text(
                        c.flag,
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: Text(loc.isArabic ? c.nameAr : c.nameEn),
                      trailing: Text(
                        c.dialCode,
                        textDirection: TextDirection.ltr,
                      ),
                      selected: c == widget.selected,
                      onTap: () => Navigator.pop(context, c),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
