import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../localization/app_locale.dart';
import '../theme/app_colors.dart';

/// A neutral brand panel, never a photograph or evidence of entity media.
/// Geometry belongs to the caller and is identical for missing/failed media.
class PatientMediaPlaceholder extends StatelessWidget {
  const PatientMediaPlaceholder({super.key, this.width, this.height});
  final double? width, height;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: LocaleService(),
    builder: (context, _) => _panel(context),
  );

  Widget _panel(BuildContext context) {
    final dark = AppColors.isDark(context);
    return Semantics(
      image: true,
      label: LocaleService().isArabic
          ? 'الصورة غير متوفرة'
          : 'Image unavailable',
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _BrandPanel(dark: dark),
          size: const Size(80, 120),
        ),
      ),
    );
  }
}

class _BrandPanel extends CustomPainter {
  const _BrandPanel({required this.dark});
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final ink = dark ? const Color(0xFFDCC59C) : const Color(0xFF756041);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF192537), Color(0xFF0C1420)]
              : const [Color(0xFFF8F4EB), Color(0xFFECE3D3)],
        ).createShader(rect),
    );
    final short = math.min(size.width, size.height);
    final center = size.center(Offset.zero);
    canvas.save();
    canvas.clipRect(rect);
    final line = Paint()
      ..color = ink.withValues(alpha: .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    for (final scale in [1.0, 1.25]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: short * .68 * scale,
          height: short * .9 * scale,
        ),
        line,
      );
    }
    void text(
      String value,
      double fontSize,
      Offset position, {
      String? family,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            fontFamily: family ?? 'PatientDisplay',
            color: ink,
            fontSize: fontSize,
            letterSpacing: 1.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      painter.paint(
        canvas,
        position - Offset(painter.width / 2, painter.height / 2),
      );
    }

    text('AW', (short * .24).clamp(15, 64), center, family: 'PatientDisplay');
    if (short >= 96) {
      text(
        'AESTHETIC WAY',
        (short * .045).clamp(8, 12),
        center + Offset(0, short * .22),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BrandPanel oldDelegate) => dark != oldDelegate.dark;
}
