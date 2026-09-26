import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/theme/app_theme.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';

void main() {
  group('AppSnackBar Unified & High-Contrast Widget Tests', () {
    testWidgets('AppSnackBar renders readable high-contrast text and icon in Dark Mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAppSnackBar(
                      context,
                      'تم نسخ كود الدعوة بنجاح',
                      type: AppSnackBarType.success,
                    );
                  },
                  child: const Text('Show Dark SnackBar'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dark SnackBar'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 750)); // Settle in view

      expect(find.text('تم نسخ كود الدعوة بنجاح'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      final textWidget = tester.widget<Text>(find.text('تم نسخ كود الدعوة بنجاح'));
      expect(textWidget.style?.color, isNotNull);
      // High contrast light text
      expect(textWidget.style?.color, const Color(0xFFE6F4EA));
    });

    testWidgets('AppSnackBar renders readable high-contrast text and icon in Light Mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAppSnackBar(
                      context,
                      'تم تسجيل استخدام الكود وتطبيق الخصم بنجاح',
                      type: AppSnackBarType.success,
                    );
                  },
                  child: const Text('Show Light SnackBar'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Light SnackBar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('تم تسجيل استخدام الكود وتطبيق الخصم بنجاح'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      final textWidget = tester.widget<Text>(find.text('تم تسجيل استخدام الكود وتطبيق الخصم بنجاح'));
      expect(textWidget.style?.color, isNotNull);
      // High contrast dark text on light background
      expect(textWidget.style?.color, const Color(0xFF065F46));
    });

    testWidgets('AppSnackBar handles error and info types properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAppSnackBar(
                      context,
                      'رمز الكود غير صحيح أو منتهي',
                      type: AppSnackBarType.error,
                    );
                  },
                  child: const Text('Show Error SnackBar'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error SnackBar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('رمز الكود غير صحيح أو منتهي'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });
}
