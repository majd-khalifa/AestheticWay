import 'package:aesthetic_way/core/widgets/patient_image.dart';
import '../../../../core/utils/entity_id.dart';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/auth/guest_auth_guard.dart';
import 'package:aesthetic_way/core/network/api_exception.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/widgets/luxury_phone_input_field.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';
import 'package:aesthetic_way/features/appointment_lead/data/leads_repository.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/appointment_success_screen.dart';

/// Dedicated Product Inquiry Modal (`lead_type: 'product'`)
/// Strictly omits practitioner selector, branch selector, and appointment date/time-window selectors.
class ProductInquiryBottomSheet extends StatefulWidget {
  final ProductModel product;
  final ClinicModel? clinic;
  final LeadsRepository? leadsRepository;

  const ProductInquiryBottomSheet({
    super.key,
    required this.product,
    this.clinic,
    this.leadsRepository,
  });

  static Future<void> show(
    BuildContext context, {
    required ProductModel product,
    ClinicModel? clinic,
    LeadsRepository? leadsRepository,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProductInquiryBottomSheet(
        product: product,
        clinic: clinic,
        leadsRepository: leadsRepository,
      ),
    );
  }

  @override
  State<ProductInquiryBottomSheet> createState() =>
      _ProductInquiryBottomSheetState();
}

class _ProductInquiryBottomSheetState extends State<ProductInquiryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  final TextEditingController _notesController = TextEditingController();
  late final LeadsRepository _leadsRepository;

  bool _consentAccepted = false;
  bool _isSubmitting = false;
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    _leadsRepository = widget.leadsRepository ?? LeadsRepository();
    final auth = AuthState();
    _nameController = TextEditingController(
      text: auth.isLoggedIn ? auth.userName : '',
    );

    _phoneController = TextEditingController(
      text: auth.isLoggedIn ? auth.userPhone : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitProductInquiry() async {
    if (_isSubmitting ||
        !isEntityUuid(widget.product.id) ||
        !AuthState().isLoggedIn ||
        !AuthState().isPatient) {
      return;
    }
    final sessionEpoch = AuthState().sessionEpoch;
    final loc = LocaleService();
    if (!_formKey.currentState!.validate()) return;
    if (!_consentAccepted) {
      setState(
        () => _submissionError = loc.isArabic
            ? 'يرجى الموافقة على مشاركة البيانات لإرسال الاستفسار'
            : 'Please accept consent to share your contact details for this inquiry',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    final rawPhone = _phoneController.text.trim();
    final formattedPhone = LuxuryPhoneInputField.normalizeToE164(rawPhone);

    final productName = loc.isArabic
        ? widget.product.nameAr
        : widget.product.nameEn;
    final clinicId = widget.product.clinicId.trim().isNotEmpty
        ? widget.product.clinicId.trim()
        : widget.clinic?.id ?? '';

    final payload = <String, dynamic>{
      if (isEntityUuid(clinicId)) 'clinic': clinicId,
      'product': widget.product.id,
      'lead_type': 'product_inquiry',
      'service_name': productName,
      'patient_name': _nameController.text.trim(),
      'patient_phone': formattedPhone,
      'consent_accepted': true,
      if (_notesController.text.trim().isNotEmpty)
        'notes': _notesController.text.trim(),
    };

    try {
      final result = await _leadsRepository.createLead(payload);
      if (!result.success || result.leadReference.isEmpty) {
        throw const ApiException(
          message: 'The server did not confirm this inquiry.',
        );
      }
      if (!mounted || sessionEpoch != AuthState().sessionEpoch) return;

      setState(() {
        _isSubmitting = false;
      });

      final request = AppointmentRequestModel(
        id: result.leadReference,
        referenceCode: result.leadReference,
        clinicId: clinicId,
        clinicNameAr: (widget.clinic?.nameAr ?? widget.product.clinicNameAr),
        clinicNameEn:
            (widget.clinic?.nameEn ?? widget.product.clinicNameEn ?? ''),
        branchNameAr: '',
        branchNameEn: '',
        serviceNameAr: widget.product.nameAr,
        serviceNameEn: widget.product.nameEn,
        patientFullName: _nameController.text.trim(),
        patientPhone: formattedPhone,
        notes: _notesController.text.trim(),
        consentAccepted: true,
        status: AppointmentLeadStatus.sent,
        createdAt: result.createdAt,
        leadType: 'product_inquiry',
      );

      final navigator = Navigator.of(context);
      navigator.pop(); // Close bottom sheet
      navigator.push(
        LuxuryPageRoute(
          page: AppointmentSuccessScreen(
            request: request,
            clinic: widget.clinic,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted || sessionEpoch != AuthState().sessionEpoch) return;
      final is429 =
          e.statusCode == 429 ||
          e.message.toLowerCase().contains('already submitted') ||
          e.message.toLowerCase().contains('too many requests') ||
          e.message.contains('مؤخراً') ||
          e.message.contains('مؤخرا');
      final isSuspendedOrInactive =
          e.statusCode == 403 ||
          e.statusCode == 404 ||
          (e.statusCode == 400 &&
              (e.message.toLowerCase().contains('suspended') ||
                  e.message.toLowerCase().contains('inactive') ||
                  e.message.contains('معلقة') ||
                  e.message.contains('غير متاحة') ||
                  e.message.toLowerCase().contains('not found')));

      final friendlyMessage = is429
          ? (loc.isArabic
                ? 'يرجى الانتظار لحظات قبل إرسال طلب جديد لنفس العيادة'
                : 'Please wait a moment before submitting another request to this clinic')
          : isSuspendedOrInactive
          ? (loc.isArabic
                ? 'العيادة غير متاحة حالياً لتلقي الاستفسارات. يرجى اختيار عيادة أخرى'
                : 'This clinic is currently unavailable to accept inquiries. Please choose another clinic.')
          : e.message;

      setState(() {
        _isSubmitting = false;
        _submissionError = friendlyMessage;
      });
    } catch (_) {
      if (!mounted || sessionEpoch != AuthState().sessionEpoch) return;
      setState(() {
        _isSubmitting = false;
        _submissionError = loc.isArabic
            ? 'فشل إرسال الطلب، يرجى المحاولة مرة أخرى'
            : 'Failed to send inquiry. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final clinicName = loc.isArabic
        ? (widget.clinic?.nameAr ?? widget.product.clinicNameAr)
        : (widget.clinic?.nameEn ?? widget.product.clinicNameEn ?? '');

    return Directionality(
      textDirection: loc.textDirection,
      child: Container(
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: AppColors.bg(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.border(context), width: 0.9),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border(context),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Modal Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.tr('product_inquiry_btn'),
                        style: AppTypography.screenTitle.copyWith(
                          color: AppColors.text(context),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.subtext(context),
                          size: 20,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 1. Product & Clinic Header Card
                  LuxuryCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        PatientImage(
                          category: PatientMediaCategory.product,
                          imageUrl: widget.product.imageUrl,

                          width: 64,
                          height: 64,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.isArabic
                                    ? widget.product.nameAr
                                    : widget.product.nameEn,
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text(context),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (clinicName.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.business_outlined,
                                      size: 13,
                                      color: AppColors.accentChampagne,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        clinicName,
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.subtext(context),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_submissionError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.errorRed.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.errorRed,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _submissionError!,
                              style: TextStyle(
                                color: AppColors.text(context),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 2. Patient Name Field
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: loc.tr('full_name'),
                      hintText: loc.isArabic
                          ? 'الاسم الكامل كما تود أن تناديك العيادة'
                          : 'Your full name',
                      hintStyle: TextStyle(
                        color: AppColors.text(context).withValues(alpha: 0.68),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                      labelStyle: TextStyle(
                        color: AppColors.subtext(context),
                        fontSize: 12.5,
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: AppColors.subtext(context),
                        size: 18,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.cardSurfaceHover
                          : AppColors.lightCardSurfaceHover,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.border(context),
                          width: 0.8,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.accentChampagne,
                          width: 1.3,
                        ),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return loc.tr('val_name_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // 3. Patient Phone Field
                  LuxuryPhoneInputField(
                    controller: _phoneController,
                    isRequired: true,
                  ),
                  const SizedBox(height: 12),

                  // 4. Multiline Inquiry / Notes Field ("استفسار أو ملاحظات")
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 13.5,
                    ),
                    decoration: InputDecoration(
                      labelText: loc.isArabic
                          ? 'استفسار أو ملاحظات'
                          : 'Inquiry / Notes',
                      hintText: loc.isArabic
                          ? 'اكتب استفسارك حول توفر المنتج أو طريقة الاستخدام...'
                          : 'Write your question about product availability or usage...',
                      hintStyle: TextStyle(
                        color: AppColors.text(context).withValues(alpha: 0.68),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      labelStyle: TextStyle(
                        color: AppColors.subtext(context),
                        fontSize: 12.5,
                      ),
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.cardSurfaceHover
                          : AppColors.lightCardSurfaceHover,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.border(context),
                          width: 0.8,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.accentChampagne,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5. Consent Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _consentAccepted,
                        activeColor: AppColors.accentChampagne,
                        onChanged: (v) =>
                            setState(() => _consentAccepted = v ?? false),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(
                            () => _consentAccepted = !_consentAccepted,
                          ),
                          child: Text(
                            loc.isArabic
                                ? 'أوافق على مشاركة اسمي ورقم هاتفي لمتابعة الاستفسار عن هذا المنتج'
                                : 'I agree to share my name and phone number for follow-up about this product',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.subtext(context),
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 6. Submit Inquiry CTA
                  SilverButton(
                    label: loc.tr('submit_lead_btn'),
                    icon: Icons.send_rounded,
                    isFullWidth: true,
                    height: 48,
                    isLoading: _isSubmitting,
                    onPressed: _submitProductInquiry,
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
