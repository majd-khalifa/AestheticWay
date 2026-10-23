import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/auth/guest_auth_guard.dart';
import '../../../core/auth/session_snapshot.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/network/api_exception.dart';
import '../models/category_model.dart';

String categoryText(String en, String ar) => LocaleService().isArabic ? ar : en;

/// Controllers and rejected input stay alive until the user intentionally closes.
class CategoryEditor extends StatefulWidget {
  const CategoryEditor({
    super.key,
    this.existing,
    this.request = false,
    required this.onSave,
  });
  final CategoryModel? existing;
  final bool request;
  final Future<void> Function(String en, String ar, int order, bool active)
  onSave;
  @override
  State<CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<CategoryEditor> {
  final _session = SessionSnapshot();
  final _form = GlobalKey<FormState>();
  late final _en = TextEditingController(text: widget.existing?.nameEn);
  late final _ar = TextEditingController(text: widget.existing?.nameAr);
  late final _order = TextEditingController(
    text: '${widget.existing?.displayOrder ?? 0}',
  );
  late bool _active = widget.existing?.isActive ?? true;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    AuthState().addListener(_changed);
  }

  void _changed() {
    if (mounted && !_session.isCurrent) setState(() {});
  }

  @override
  void dispose() {
    AuthState().removeListener(_changed);
    _en.dispose();
    _ar.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_session.isCurrent || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave(
        _en.text,
        _ar.text,
        int.tryParse(_order.text) ?? 0,
        _active,
      );
      if (mounted && _session.isCurrent) Navigator.pop(context, true);
    } catch (e) {
      if (mounted && _session.isCurrent) {
        setState(
          () => _error = e is ApiException
              ? e.message
              : categoryText(
                  'Unable to save. Please try again.',
                  'تعذر الحفظ. يرجى المحاولة مجدداً.',
                ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(
        widget.request
            ? categoryText('Request a category', 'طلب تصنيف')
            : categoryText(
                widget.existing == null ? 'Add Category' : 'Edit category',
                widget.existing == null ? 'إضافة تصنيف' : 'تعديل التصنيف',
              ),
      ),
      content: !_session.isCurrent
          ? Text(
              categoryText(
                'Your session changed. Close this form.',
                'تغيّرت الجلسة. أغلق النموذج.',
              ),
            )
          : SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.request)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            categoryText(
                              'A Super Admin must approve your request before the category can be selected for a treatment.',
                              'يجب موافقة المشرف العام قبل إتاحة التصنيف للاختيار في العلاج.',
                            ),
                          ),
                        ),
                      TextFormField(
                        key: const ValueKey('category-name-en'),
                        controller: _en,
                        enabled: !_busy,
                        maxLength: 200,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'Name (English) *',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? categoryText(
                                'Enter an English name.',
                                'أدخل الاسم بالإنجليزية.',
                              )
                            : null,
                      ),
                      TextFormField(
                        key: const ValueKey('category-name-ar'),
                        controller: _ar,
                        enabled: !_busy,
                        maxLength: 200,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                          labelText: 'الاسم بالعربية',
                        ),
                      ),
                      if (!widget.request) ...[
                        TextFormField(
                          key: const ValueKey('category-order'),
                          controller: _order,
                          enabled: !_busy,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: categoryText(
                              'Display order',
                              'ترتيب العرض',
                            ),
                          ),
                          validator: (v) => int.tryParse(v ?? '') == null
                              ? categoryText(
                                  'Enter a non-negative whole number.',
                                  'أدخل عدداً صحيحاً غير سالب.',
                                )
                              : null,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(categoryText('Active', 'نشط')),
                          value: _active,
                          onChanged: _busy
                              ? null
                              : (v) => setState(() => _active = v),
                        ),
                      ],
                      if (_error != null)
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(categoryText('Cancel', 'إلغاء')),
        ),
        FilledButton(
          key: const ValueKey('category-save'),
          onPressed: _busy || !_session.isCurrent ? null : _save,
          child: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  widget.request
                      ? categoryText('Submit for approval', 'إرسال للموافقة')
                      : categoryText('Save', 'حفظ'),
                ),
        ),
      ],
    ),
  );
}
