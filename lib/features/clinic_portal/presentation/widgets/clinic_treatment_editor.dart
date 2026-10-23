import '../../../../core/auth/guest_auth_guard.dart';
import 'package:flutter/material.dart';
import '../../../../core/auth/session_snapshot.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/paged_entity_picker.dart';
import '../../../../core/widgets/silver_button.dart';
import '../../../practitioners/models/practitioner_model.dart';
import '../../../treatments/models/treatment_model.dart';
import '../../data/clinic_catalog_repository.dart';
import '../../services/clinic_portal_service.dart';
import 'clinic_category_field.dart';

class ClinicTreatmentEditor extends StatefulWidget {
  const ClinicTreatmentEditor({super.key, this.existing});
  final TreatmentModel? existing;
  @override
  State<ClinicTreatmentEditor> createState() => _ClinicTreatmentEditorState();
}

class _ClinicTreatmentEditorState extends State<ClinicTreatmentEditor> {
  final _service = ClinicPortalService();
  final _session = SessionSnapshot();
  final _form = GlobalKey<FormState>();
  late final TextEditingController _en,
      _ar,
      _descriptionEn,
      _descriptionAr,
      _price;
  late final Set<String> _practitioners;
  final _picked = <String, PractitionerModel>{};
  String? _category, _categoryLabel, _error;
  bool _busy = false, _picking = false;
  late bool _active;
  bool get ar => LocaleService().isArabic;
  @override
  void initState() {
    super.initState();
    AuthState().addListener(_identityChanged);
    final t = widget.existing;
    _en = TextEditingController(text: t?.nameEn);
    _ar = TextEditingController(text: t?.nameAr);
    _descriptionEn = TextEditingController(text: t?.descriptionEn);
    _descriptionAr = TextEditingController(text: t?.descriptionAr);
    _price = TextEditingController(text: t?.price?.toStringAsFixed(2) ?? '');
    _category = t?.categoryId;
    _categoryLabel = t == null ? null : (ar ? t.categoryAr : t.categoryEn);
    _active = t?.isActive ?? true;
    _practitioners = {...?t?.practitionerIds};
    _service.getOrFetchCategories();
    _service.loadCollection('practitioners');
  }

  void _identityChanged() {
    if (!_session.isCurrent && mounted) setState(() {});
  }

  @override
  void dispose() {
    AuthState().removeListener(_identityChanged);
    for (final c in [_en, _ar, _descriptionEn, _descriptionAr, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy ||
        _picking ||
        !_session.isCurrent ||
        _form.currentState?.validate() != true) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _session.ensureCurrent();
      final data = <String, dynamic>{
        'category': _category,
        'name_en': _en.text.trim(), 'name_ar': _ar.text.trim(),
        'description_en': _descriptionEn.text.trim(),
        'description_ar': _descriptionAr.text.trim(),
        'price': _price.text.trim().isEmpty ? null : _price.text.trim(),
        'is_active': _active,
        'practitioners': _practitioners.toList(),
        // Preserve moderation state on edits; Django supplies the create default.
      };
      if (widget.existing case final existing?) {
        await _service.updateTreatment(existing.id, data);
      } else {
        await _service.createTreatment(data);
      }
      _session.ensureCurrent();
      if (!mounted) return;
      Navigator.pop(context);
      showAppSnackBar(
        context,
        ar ? 'تم حفظ الإجراء بنجاح' : 'Treatment saved successfully',
        type: AppSnackBarType.success,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = !_session.isCurrent
              ? (ar
                    ? 'تغيرت الجلسة. أغلق النموذج وأعد فتحه.'
                    : 'Your session changed. Close and reopen this form.')
              : e is ApiException
              ? e.message
              : (ar
                    ? 'تعذر حفظ الإجراء. حاول مجدداً.'
                    : 'Could not save treatment. Please try again.');
        });
      }
    }
  }

  Future<void> _pickPractitioner() async {
    if (_busy || _picking || !_session.isCurrent) return;
    setState(() => _picking = true);
    try {
      final picked = await showPagedEntityPicker<PractitionerModel>(
        context,
        title: ar ? 'اختيار الممارس' : 'Select practitioner',
        hint: ar ? 'البحث في كادر العيادة' : 'Search clinic staff',
        keyOf: (p) => p.id,
        labelOf: (p) => ar ? p.nameAr : p.nameEn,
        loader: (page, search) => ClinicCatalogRepository().getPractitioners(
          page: page,
          search: search,
        ),
      );
      if (mounted && _session.isCurrent && picked?.value != null) {
        setState(() {
          _picked[picked!.value!.id] = picked.value!;
          _practitioners.add(picked.value!.id);
        });
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Widget _text(
    String key,
    String label,
    TextEditingController c, {
    bool required = false,
    bool rtl = false,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      key: ValueKey(key),
      controller: c,
      enabled: !_busy,
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      maxLines: lines,
      maxLength: key.startsWith('treatment-name') ? 200 : null,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      validator: (v) => required && (v == null || v.trim().isEmpty)
          ? LocaleService().tr('clinic_validation_required')
          : null,
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!_session.isCurrent) {
      return Center(
        child: Text(
          ar
              ? 'تغيرت الجلسة. أغلق النموذج وأعد فتحه.'
              : 'Your session changed. Close and reopen this form.',
        ),
      );
    }
    return PopScope(
      canPop: !_busy,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: SizedBox(
            height:
                (MediaQuery.sizeOf(context).height -
                    MediaQuery.viewInsetsOf(context).bottom) *
                .85,
            child: ListenableBuilder(
              listenable: _service,
              builder: (context, _) {
                final staff = {
                  for (final p in _service.clinicPractitioners) p.id: p,
                  ..._picked,
                };
                return Form(
                  key: _form,
                  child: ListView(
                    children: [
                      Text(
                        widget.existing == null
                            ? (ar
                                  ? 'إضافة إجراء / خدمة'
                                  : 'Add Treatment / Service')
                            : (ar
                                  ? 'تعديل الإجراء / الخدمة'
                                  : 'Edit Treatment'),
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_error != null)
                        Semantics(
                          liveRegion: true,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      AbsorbPointer(
                        absorbing: _busy,
                        child: ClinicCategoryField(
                          categories: _service.categories,
                          value: _category,
                          valueLabel: _categoryLabel,
                          onChanged: (c) => setState(() {
                            _category = c?.id;
                            _categoryLabel = c == null
                                ? null
                                : (ar ? c.nameAr : c.nameEn);
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _text(
                        'treatment-name-en',
                        ar
                            ? 'اسم الإجراء بالإنجليزية *'
                            : 'Treatment Name (English) *',
                        _en,
                        required: true,
                      ),
                      _text(
                        'treatment-name-ar',
                        ar ? 'اسم الإجراء بالعربية' : 'Treatment Name (Arabic)',
                        _ar,
                        rtl: true,
                      ),
                      TextFormField(
                        key: const ValueKey('treatment-price'),
                        controller: _price,
                        enabled: !_busy,
                        textDirection: TextDirection.ltr,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: ar
                              ? 'السعر التقديري (درهم إماراتي)'
                              : 'Estimated Price (AED)',
                          helperText: ar
                              ? 'اختياري، بحد أقصى منزلتين عشريتين.'
                              : 'Optional, up to two decimal places.',
                        ),
                        validator: (v) =>
                            v == null ||
                                v.trim().isEmpty ||
                                RegExp(
                                  r'^\d{1,8}(\.\d{1,2})?$',
                                ).hasMatch(v.trim())
                            ? null
                            : (ar
                                  ? 'أدخل سعراً صالحاً بحد أقصى منزلتين عشريتين.'
                                  : 'Enter a valid price with up to two decimal places.'),
                      ),
                      const SizedBox(height: 12),
                      _text(
                        'treatment-description-en',
                        ar ? 'الوصف بالإنجليزية' : 'Description (English)',
                        _descriptionEn,
                        lines: 3,
                      ),
                      _text(
                        'treatment-description-ar',
                        ar ? 'الوصف بالعربية' : 'Description (Arabic)',
                        _descriptionAr,
                        rtl: true,
                        lines: 3,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          ar
                              ? 'متاح للمرضى عند الموافقة'
                              : 'Available to patients when approved',
                        ),
                        value: _active,
                        onChanged: _busy
                            ? null
                            : (v) => setState(() => _active = v),
                      ),
                      Text(
                        ar
                            ? 'الظهور العام يخضع أيضاً لحالة اعتماد العيادة والإجراء والتصنيف.'
                            : 'Public visibility also depends on clinic, treatment and category approval.',
                        style: TextStyle(color: AppColors.mutedText(context)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        ar ? 'الممارسون المعينون' : 'Assigned practitioners',
                      ),
                      Wrap(
                        spacing: 8,
                        children: _practitioners.map((id) {
                          final p = staff[id];
                          return InputChip(
                            label: Text(
                              p == null
                                  ? (ar
                                        ? 'ممارس معين'
                                        : 'Assigned practitioner')
                                  : ar
                                  ? p.nameAr
                                  : p.nameEn,
                            ),
                            onDeleted: _busy
                                ? null
                                : () =>
                                      setState(() => _practitioners.remove(id)),
                          );
                        }).toList(),
                      ),
                      TextButton.icon(
                        onPressed: _busy || _picking ? null : _pickPractitioner,
                        icon: const Icon(Icons.person_add_outlined),
                        label: Text(
                          ar ? 'تصفح كادر العيادة' : 'Browse clinic staff',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SilverButton(
                        key: const ValueKey('treatment-save'),
                        label: widget.existing == null
                            ? (ar ? 'حفظ الإجراء' : 'Save Treatment')
                            : (ar ? 'حفظ التعديلات' : 'Update Treatment'),
                        isLoading: _busy,
                        isFullWidth: true,
                        onPressed: _busy ? null : _save,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
