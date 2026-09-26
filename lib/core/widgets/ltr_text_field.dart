import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable text form field that guarantees Left-to-Right (LTR) typing and text alignment,
/// regardless of the ambient application locale (e.g., when the app is in Arabic RTL mode).
class LtrTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final InputDecoration decoration;
  final TextStyle? style;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? minLines;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool enabled;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;

  const LtrTextFormField({
    super.key,
    this.controller,
    this.initialValue,
    this.decoration = const InputDecoration(),
    this.style,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.onChanged,
    this.focusNode,
    this.enabled = true,
    this.textAlign = TextAlign.left,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        textDirection: TextDirection.ltr,
        textAlign: textAlign,
        decoration: decoration,
        style: style,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        minLines: minLines,
        readOnly: readOnly,
        onChanged: onChanged,
        focusNode: focusNode,
        enabled: enabled,
        inputFormatters: inputFormatters,
      ),
    );
  }
}
