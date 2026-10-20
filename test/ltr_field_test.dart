import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/widgets/ltr_text_field.dart';

void main() {
  testWidgets(
    'LtrTextFormField enforces LTR text direction inside RTL parent',
    (tester) async {
      final controller = TextEditingController(text: 'Dr. Sarah Al Mansoori');

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl, // Simulate Arabic RTL app layout
            child: Scaffold(
              body: LtrTextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Full Name (English)',
                ),
              ),
            ),
          ),
        ),
      );

      // Find the inner TextFormField / EditableText
      final editableFinder = find.byType(EditableText);
      expect(editableFinder, findsOneWidget);

      final editable = tester.widget<EditableText>(editableFinder);
      expect(editable.textDirection, TextDirection.ltr);
      expect(editable.textAlign, TextAlign.left);
    },
  );

  testWidgets('LtrTextFormField validates input correctly', (tester) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: LtrTextFormField(
              controller: controller,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);

    controller.text = 'HydraFacial Deluxe';
    expect(formKey.currentState!.validate(), isTrue);
  });
}
