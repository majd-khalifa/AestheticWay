import 'package:flutter/material.dart';
import '../../../../core/network/api_exception.dart';
import '../../services/admin_portal_service.dart';
import 'admin_components.dart';
import 'admin_clinic_editor.dart';

class AdminPasswordResetDialog extends StatefulWidget {
  const AdminPasswordResetDialog({super.key, required this.clinicId});
  final String clinicId;
  @override
  State<AdminPasswordResetDialog> createState() =>
      _AdminPasswordResetDialogState();
}

class _AdminPasswordResetDialogState extends State<AdminPasswordResetDialog> {
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false, _completed = false;
  String? _error;
  @override
  void dispose() {
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      scrollable: true,
      title: Text(
        adminText('Reset Admin Password', 'إعادة تعيين كلمة مرور المشرف'),
      ),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              adminText(
                'Generate a temporary password for this clinic administrator.',
                'تعيين كلمة مرور مؤقتة لمسؤول هذه العيادة.',
              ),
            ),
            if (_error != null) AdminNotice(message: _error!, error: true),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              enabled: !_busy,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              textDirection: TextDirection.ltr,
              maxLength: 128,
              decoration: InputDecoration(
                labelText: adminText(
                  'Custom Password (Optional)',
                  'كلمة مرور مخصصة (اختياري)',
                ),
                hintText: adminText(
                  'Leave blank to auto-generate',
                  'اتركه فارغاً للتوليد التلقائي',
                ),
              ),
              validator: (v) => v != null && v.isNotEmpty && v.length < 8
                  ? adminText(
                      'Use at least 8 characters.',
                      'استخدم 8 أحرف على الأقل.',
                    )
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(adminText('Cancel', 'إلغاء')),
        ),
        FilledButton(
          onPressed: _busy || _completed
              ? null
              : () async {
                  if (!_form.currentState!.validate()) return;
                  setState(() {
                    _busy = true;
                    _error = null;
                  });
                  try {
                    final response = await AdminPortalService()
                        .resetClinicAdminPassword(
                          widget.clinicId,
                          customPassword: _password.text.isEmpty
                              ? null
                              : _password.text,
                        );
                    if (!context.mounted) return;
                    _password.clear();
                    setState(() {
                      _busy = false;
                      _completed = true;
                    });
                    await showAdminCredentials(
                      context,
                      result: response,
                      reset: true,
                    );
                    if (context.mounted) Navigator.pop(context);
                  } catch (error) {
                    if (mounted) {
                      setState(() {
                        _busy = false;
                        _error = error is ApiException
                            ? error.message
                            : adminText(
                                'Could not reset password.',
                                'تعذر إعادة تعيين كلمة المرور.',
                              );
                      });
                    }
                  }
                },
          child: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(adminText('Confirm Reset', 'تأكيد التعيين')),
        ),
      ],
    ),
  );
}
