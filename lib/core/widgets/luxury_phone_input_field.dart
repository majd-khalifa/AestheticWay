import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';

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
/// - Enforces maxLength: 10 digits after country code (digits only)
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
  static String normalizeToE164(String rawInput, {String defaultDialCode = '+971'}) {
    var cleaned = rawInput.replaceAll(RegExp(r'[^\d+]'), '').trim();
    if (cleaned.isEmpty) return '';

    // Check if starts with a known country code (longest match first)
    for (final country in _sortedDialCodes) {
      final code = country.dialCode;
      final codeNoPlus = code.replaceFirst('+', '');
      if (cleaned.startsWith(code)) {
        var local = cleaned.substring(code.length);
        while (local.startsWith('0')) {
          local = local.substring(1);
        }
        return '$code$local';
      } else if (cleaned.startsWith('00$codeNoPlus')) {
        var local = cleaned.substring(('00$codeNoPlus').length);
        while (local.startsWith('0')) {
          local = local.substring(1);
        }
        return '$code$local';
      } else if (cleaned.startsWith(codeNoPlus) && cleaned.length > codeNoPlus.length + 6) {
        var local = cleaned.substring(codeNoPlus.length);
        while (local.startsWith('0')) {
          local = local.substring(1);
        }
        return '$code$local';
      }
    }

    // Fallback: strip leading zeros and prefix defaultDialCode
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }
    while (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    return '$defaultDialCode$cleaned';
  }

  /// Extracts the local digits (stripping dial code and leading zero)
  static String extractLocalDigits(String rawInput) {
    var cleaned = rawInput.replaceAll(RegExp(r'[^\d+]'), '').trim();
    if (cleaned.isEmpty) return '';

    for (final country in _sortedDialCodes) {
      final code = country.dialCode;
      final codeNoPlus = code.replaceFirst('+', '');
      if (cleaned.startsWith(code)) {
        cleaned = cleaned.substring(code.length);
        break;
      } else if (cleaned.startsWith('00$codeNoPlus')) {
        cleaned = cleaned.substring(('00$codeNoPlus').length);
        break;
      } else if (cleaned.startsWith(codeNoPlus) && cleaned.length > codeNoPlus.length + 6) {
        cleaned = cleaned.substring(codeNoPlus.length);
        break;
      }
    }

    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }
    while (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    return cleaned;
  }

  /// Extracts dial code from raw input if matched, otherwise returns defaultDialCode
  static CountryDialCode extractCountry(String rawInput, {String defaultDialCode = '+971'}) {
    final cleaned = rawInput.replaceAll(RegExp(r'[^\d+]'), '').trim();
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

  @override
  void initState() {
    super.initState();

    final initial = widget.initialValue ?? widget.controller?.text ?? '';
    _selectedCountry = LuxuryPhoneInputField.extractCountry(
      initial,
      defaultDialCode: widget.defaultDialCode,
    );

    final localDigits = LuxuryPhoneInputField.extractLocalDigits(initial);
    _localController = TextEditingController(text: localDigits);
    _isInternalController = true;

    // Sync external controller if present
    _syncExternalController(localDigits);

    _localController.addListener(_handleLocalTextChanged);
  }

  @override
  void didUpdateWidget(covariant LuxuryPhoneInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller != oldWidget.controller) {
      final text = widget.controller!.text;
      final localDigits = LuxuryPhoneInputField.extractLocalDigits(text);
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
    final local = _localController.text;
    _syncExternalController(local);
  }

  void _syncExternalController(String localDigits) {
    var digits = localDigits.replaceAll(RegExp(r'\D'), '');
    while (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    final fullNumber = digits.isEmpty ? '' : '${_selectedCountry.dialCode}$digits';

    if (widget.controller != null && widget.controller!.text != fullNumber) {
      widget.controller!.text = fullNumber;
    }
    widget.onChanged?.call(fullNumber);
  }

  void _showCountryPicker() {
    if (widget.readOnly || !widget.enabled) return;

    final loc = LocaleService();
    final isDark = AppColors.isDark(context);
    final searchCtrl = TextEditingController();
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final q = searchQuery.toLowerCase().trim();
            final filteredCodes = kSupportedDialCodes.where((c) {
              if (q.isEmpty) return true;
              return c.nameAr.toLowerCase().contains(q) ||
                  c.nameEn.toLowerCase().contains(q) ||
                  c.dialCode.contains(q);
            }).toList();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetCtx).size.height * 0.75,
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                border: Border.all(
                  color: AppColors.accentChampagne.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border(sheetCtx),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.public_rounded, color: AppColors.accentChampagne, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          loc.isArabic ? 'اختر رمز الدولة' : 'Select Country Code',
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search Input Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: (val) {
                        setSheetState(() {
                          searchQuery = val;
                        });
                      },
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: loc.isArabic
                            ? 'ابحث باسم الدولة أو رمز الاتصال...'
                            : 'Search country name or dial code...',
                        hintStyle: TextStyle(
                          color: AppColors.text(sheetCtx).withValues(alpha: 0.68),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.accentChampagne),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () {
                                  searchCtrl.clear();
                                  setSheetState(() {
                                    searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.border(sheetCtx), width: 0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.border(sheetCtx), width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.accentChampagne, width: 1.2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filteredCodes.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                loc.isArabic ? 'لم يتم العثور على نتائج' : 'No countries found',
                                style: AppTypography.caption.copyWith(color: AppColors.mutedText(sheetCtx)),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: filteredCodes.length,
                            separatorBuilder: (context, index) => Divider(
                              color: AppColors.border(sheetCtx).withValues(alpha: 0.5),
                              height: 1,
                            ),
                            itemBuilder: (_, index) {
                              final country = filteredCodes[index];
                              final isSelected = country.dialCode == _selectedCountry.dialCode &&
                                  country.flag == _selectedCountry.flag;
                              return ListTile(
                                dense: true,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                tileColor: isSelected
                                    ? AppColors.accentChampagne.withValues(alpha: isDark ? 0.15 : 0.12)
                                    : null,
                                leading: Text(
                                  country.flag,
                                  style: const TextStyle(fontSize: 22),
                                ),
                                title: Text(
                                  loc.isArabic ? country.nameAr : country.nameEn,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.goldText(context)
                                        : (isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary),
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 13.5,
                                  ),
                                ),
                                trailing: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    country.dialCode,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.goldText(context)
                                          : AppColors.mutedText(sheetCtx),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedCountry = country;
                                  });
                                  Navigator.pop(sheetCtx);
                                  _syncExternalController(_localController.text);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    final defaultLabel = loc.tr('phone_uae');
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
        maxLength: 10,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
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
              : (isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover),
          prefixIcon: InkWell(
            onTap: widget.readOnly ? null : _showCountryPicker,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
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
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
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
          suffixIcon: widget.suffixIcon ??
              (widget.readOnly
                  ? Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.mutedText(context))
                  : null),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border(context), width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? AppColors.silverPrimary : AppColors.primarySoftNavy,
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
          if (widget.validator != null) {
            return widget.validator!(val);
          }
          if (widget.isRequired) {
            if (val == null || val.trim().isEmpty) {
              return loc.tr('val_phone_required');
            }
            var digits = val.replaceAll(RegExp(r'\D'), '');
            while (digits.startsWith('0')) {
              digits = digits.substring(1);
            }
            if (digits.length < 7) {
              return loc.isArabic
                  ? 'يرجى إدخال رقم هاتف محلي صالح'
                  : 'Please enter a valid local number';
            }
          }
          return null;
        },
      ),
    );
  }
}
