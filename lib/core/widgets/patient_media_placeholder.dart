import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../localization/app_locale.dart';
import '../theme/app_colors.dart';

/// Artwork identifies the *slot*, never the identity or contents of a record.
enum PatientMediaCategory {
  clinicCover,
  clinicLogo,
  product,
  treatment,
  offer,
  article,
  practitioner,
  consultation,
}

/// Inspectable without logging a URL, entity identifier or exception payload.
enum PatientMediaFallbackReason { missing, loadFailed, unsupportedSource }

/// Offline vector artwork. The caller owns the exact image frame and clipping.
class PatientMediaPlaceholder extends StatelessWidget {
  const PatientMediaPlaceholder({
    super.key,
    required this.category,
    this.reason = PatientMediaFallbackReason.missing,
    this.width,
    this.height,
  });
  final PatientMediaCategory category;
  final PatientMediaFallbackReason reason;
  final double? width, height;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: LocaleService(),
    builder: (context, _) {
      final ar = LocaleService().isArabic;
      return Semantics(
        image: true,
        label: reason == PatientMediaFallbackReason.unsupportedSource
            ? (ar ? 'هذا الملف ليس صورة' : 'This media is not an image')
            : reason == PatientMediaFallbackReason.loadFailed
            ? (ar ? 'تعذّر تحميل الصورة' : 'Image could not load')
            : (ar ? 'الصورة غير متوفرة' : 'Image unavailable'),
        hint:
            '${_motifLabel(category, ar)}. ${ar ? 'رسم توضيحي محايد، ليس صورة فعلية' : 'Neutral illustration, not a photograph'}',
        child: SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _PremiumArtwork(
              category: category,
              dark: AppColors.isDark(context),
            ),
            size: const Size(80, 120),
          ),
        ),
      );
    },
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty('category', category));
    properties.add(EnumProperty('reason', reason));
  }
}

String _motifLabel(PatientMediaCategory category, bool ar) =>
    switch (category) {
      PatientMediaCategory.clinicCover =>
        ar ? 'أقواس معمارية' : 'Architectural arches',
      PatientMediaCategory.clinicLogo =>
        ar ? 'هوية التطبيق' : 'App brand hallmark',
      PatientMediaCategory.product =>
        ar ? 'أوعية تجميلية مجردة' : 'Abstract cosmetic vessels',
      PatientMediaCategory.treatment =>
        ar ? 'طبقات وبوتانيات مجردة' : 'Abstract contours and botanical forms',
      PatientMediaCategory.offer => ar ? 'ظرف وشريط' : 'Envelope and ribbon',
      PatientMediaCategory.article => ar ? 'صفحات تحريرية' : 'Editorial pages',
      PatientMediaCategory.practitioner =>
        ar ? 'هيئة شخص توضيحية' : 'Illustrative person silhouette',
      PatientMediaCategory.consultation =>
        ar ? 'فقاعات حوار' : 'Conversation forms',
    };

/// Original deterministic compositions, not Material icons or generated photos.
/// All paths are local vector geometry. Small frames omit editorial detail.
class _PremiumArtwork extends CustomPainter {
  _PremiumArtwork({required this.category, required this.dark});
  final PatientMediaCategory category;
  final bool dark;
  Color get ink => dark ? const Color(0xFFDCC6A3) : const Color(0xFF725B42);
  Color get plane => dark ? const Color(0xFF28384B) : const Color(0xFFE6DBCA);
  Color get pearl => dark ? const Color(0xFF35475A) : const Color(0xFFFFFCF6);
  Color get shade => dark ? const Color(0xFF080F1B) : const Color(0xFFCFC0AB);
  late double lineWidth;
  Paint fill(Color c) => Paint()..color = c;
  Paint line([double opacity = .8]) => Paint()
    ..color = ink.withValues(alpha: opacity)
    ..style = PaintingStyle.stroke
    ..strokeWidth = lineWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  void rounded(
    Canvas c,
    Rect r,
    double radius,
    Color color, {
    bool outline = false,
  }) {
    final box = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(box, fill(color));
    if (outline) c.drawRRect(box, line(.65));
  }

  void path(Canvas c, Path p, {Color? color, double opacity = .8}) =>
      c.drawPath(p, color == null ? line(opacity) : fill(color));
  void segment(
    Canvas c,
    double x,
    double y,
    double ex,
    double ey, [
    double opacity = .6,
  ]) => c.drawLine(Offset(x, y), Offset(ex, ey), line(opacity));

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRect(rect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF1D2D41), Color(0xFF0A1321)]
              : const [Color(0xFFFCF9F2), Color(0xFFEDE3D5)],
        ).createShader(rect),
    );
    // Broad planes add depth without reading as fabricated photographic content.
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * .67, 0)
        ..lineTo(size.width * .18, size.height)
        ..lineTo(0, size.height)
        ..close(),
      fill(pearl.withValues(alpha: dark ? .13 : .2)),
    );
    final compact = size.shortestSide < 96;
    final portrait = size.height > size.width * 1.05;
    final viewbox = switch (category) {
      PatientMediaCategory.clinicLogo => const Size(280, 280),
      PatientMediaCategory.clinicCover => const Size(360, 280),
      PatientMediaCategory.product =>
        portrait ? const Size(270, 300) : const Size(300, 300),
      PatientMediaCategory.treatment => const Size(340, 280),
      PatientMediaCategory.offer =>
        portrait ? const Size(300, 300) : const Size(360, 300),
      PatientMediaCategory.article => const Size(280, 300),
      PatientMediaCategory.practitioner =>
        portrait ? const Size(220, 300) : const Size(260, 300),
      PatientMediaCategory.consultation => const Size(360, 280),
    };
    final scale = math.min(
      size.width / viewbox.width,
      size.height / viewbox.height,
    );
    lineWidth = math.max(1.4, .75 / scale);
    canvas.translate(
      size.width / 2,
      size.height / 2 - (compact ? 0 : size.height * .035),
    );
    canvas.scale(scale);
    canvas.translate(-200, -150);
    switch (category) {
      case PatientMediaCategory.clinicCover:
        _architecture(canvas, compact);
      case PatientMediaCategory.clinicLogo:
        _identity(canvas);
      case PatientMediaCategory.product:
        _vessels(canvas, compact);
      case PatientMediaCategory.treatment:
        _skinCare(canvas, compact);
      case PatientMediaCategory.offer:
        _ribbon(canvas, compact);
      case PatientMediaCategory.article:
        _editorial(canvas, compact);
      case PatientMediaCategory.practitioner:
        _portrait(canvas, compact);
      case PatientMediaCategory.consultation:
        _conversation(canvas, compact);
    }
    canvas.restore();
  }

  void _architecture(Canvas c, bool compact) {
    // Layered arches, a recessed doorway and a stepped plinth; no real interior.
    path(
      c,
      Path()
        ..moveTo(77, 238)
        ..lineTo(77, 118)
        ..cubicTo(77, 33, 204, 33, 204, 118)
        ..lineTo(204, 238)
        ..close(),
      color: plane,
    );
    path(
      c,
      Path()
        ..moveTo(108, 238)
        ..lineTo(108, 121)
        ..cubicTo(108, 62, 186, 62, 186, 121)
        ..lineTo(186, 238),
      opacity: .55,
    );
    path(
      c,
      Path()
        ..moveTo(174, 238)
        ..lineTo(174, 104)
        ..cubicTo(174, 6, 316, 6, 316, 104)
        ..lineTo(316, 238)
        ..close(),
      color: pearl,
    );
    path(
      c,
      Path()
        ..moveTo(174, 238)
        ..lineTo(174, 104)
        ..cubicTo(174, 6, 316, 6, 316, 104)
        ..lineTo(316, 238),
      opacity: .75,
    );
    path(
      c,
      Path()
        ..moveTo(203, 238)
        ..lineTo(203, 111)
        ..cubicTo(203, 51, 288, 51, 288, 111)
        ..lineTo(288, 238)
        ..close(),
      color: shade.withValues(alpha: .35),
    );
    rounded(c, const Rect.fromLTWH(62, 238, 274, 12), 2, plane);
    segment(c, 62, 238, 336, 238);
    if (!compact) {
      segment(c, 44, 262, 355, 262, .3);
      segment(c, 233, 114, 233, 227, .25);
      segment(c, 292, 77, 292, 218, .25);
      segment(c, 87, 258, 87, 266, .25);
    }
  }

  void _identity(Canvas c) {
    // A square hallmark is reserved for logo slots, never a repeated cover.
    rounded(c, const Rect.fromLTWH(92, 42, 216, 216), 30, pearl, outline: true);
    final inner = RRect.fromRectAndRadius(
      const Rect.fromLTWH(106, 56, 188, 188),
      const Radius.circular(23),
    );
    c.drawRRect(inner, line(.25));
    final painter = TextPainter(
      text: TextSpan(
        text: 'AW',
        style: TextStyle(
          fontFamily: 'PatientDisplay',
          color: ink,
          fontSize: 68,
          letterSpacing: -2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(c, Offset(200 - painter.width / 2, 150 - painter.height / 2));
    painter.dispose();
    path(
      c,
      Path()
        ..moveTo(200, 64)
        ..lineTo(207, 73)
        ..lineTo(200, 82)
        ..lineTo(193, 73)
        ..close(),
      color: ink.withValues(alpha: .55),
    );
    segment(c, 166, 219, 234, 219, .55);
  }

  void _vessels(Canvas c, bool compact) {
    // Unlabelled generic vessels, no imaginary packaging, brands or claims.
    c.drawOval(
      const Rect.fromLTWH(83, 243, 243, 23),
      fill(shade.withValues(alpha: .3)),
    );
    rounded(
      c,
      const Rect.fromLTWH(105, 115, 87, 130),
      19,
      plane,
      outline: true,
    );
    rounded(c, const Rect.fromLTWH(125, 84, 46, 31), 4, pearl, outline: true);
    rounded(
      c,
      const Rect.fromLTWH(215, 126, 82, 120),
      12,
      pearl,
      outline: true,
    );
    rounded(c, const Rect.fromLTWH(231, 104, 49, 22), 4, plane, outline: true);
    segment(c, 244, 103, 244, 75);
    path(
      c,
      Path()
        ..moveTo(244, 75)
        ..lineTo(276, 75)
        ..quadraticBezierTo(287, 75, 287, 86),
    );
    if (!compact) {
      segment(c, 119, 144, 119, 220, .3);
      segment(c, 228, 149, 228, 222, .22);
      segment(c, 137, 97, 161, 97, .35);
      path(
        c,
        Path()
          ..moveTo(322, 211)
          ..quadraticBezierTo(349, 194, 340, 161)
          ..quadraticBezierTo(312, 177, 322, 211)
          ..close(),
        color: plane,
      );
      segment(c, 316, 229, 337, 171, .4);
    }
  }

  void _skinCare(Canvas c, bool compact) {
    // Layered skin-inspired contours and one botanical sprig, no procedure.
    path(
      c,
      Path()
        ..moveTo(65, 200)
        ..cubicTo(119, 145, 167, 209, 221, 161)
        ..cubicTo(264, 125, 306, 151, 339, 127)
        ..lineTo(339, 237)
        ..lineTo(65, 237)
        ..close(),
      color: plane,
    );
    path(
      c,
      Path()
        ..moveTo(65, 200)
        ..cubicTo(119, 145, 167, 209, 221, 161)
        ..cubicTo(264, 125, 306, 151, 339, 127),
    );
    path(
      c,
      Path()
        ..moveTo(65, 219)
        ..cubicTo(125, 171, 171, 225, 230, 182)
        ..cubicTo(279, 149, 309, 172, 339, 151),
      opacity: .4,
    );
    path(
      c,
      Path()
        ..moveTo(251, 141)
        ..cubicTo(245, 99, 267, 73, 288, 52),
      opacity: .8,
    );
    path(
      c,
      Path()
        ..moveTo(262, 105)
        ..quadraticBezierTo(224, 98, 231, 70)
        ..quadraticBezierTo(263, 72, 262, 105)
        ..close(),
      color: pearl,
    );
    path(
      c,
      Path()
        ..moveTo(272, 82)
        ..quadraticBezierTo(302, 84, 308, 55)
        ..quadraticBezierTo(282, 53, 272, 82)
        ..close(),
      color: plane,
    );
    path(
      c,
      Path()
        ..moveTo(113, 145)
        ..cubicTo(84, 120, 113, 92, 124, 72)
        ..cubicTo(135, 93, 162, 121, 137, 144)
        ..quadraticBezierTo(125, 157, 113, 145)
        ..close(),
      color: pearl,
    );
    if (!compact) {
      segment(c, 76, 251, 324, 251, .3);
      c.drawCircle(const Offset(187, 112), 3, fill(ink.withValues(alpha: .5)));
      c.drawCircle(const Offset(201, 94), 2, fill(ink.withValues(alpha: .35)));
    }
  }

  void _ribbon(Canvas c, bool compact) {
    // Folded envelope and broad satin band, with no monetary or purchase mark.
    rounded(c, const Rect.fromLTWH(78, 95, 244, 155), 10, plane, outline: true);
    path(
      c,
      Path()
        ..moveTo(80, 104)
        ..lineTo(200, 183)
        ..lineTo(320, 104)
        ..close(),
      color: pearl,
    );
    path(
      c,
      Path()
        ..moveTo(80, 104)
        ..lineTo(200, 183)
        ..lineTo(320, 104),
      opacity: .6,
    );
    path(
      c,
      Path()
        ..moveTo(87, 239)
        ..lineTo(161, 177)
        ..moveTo(314, 239)
        ..lineTo(240, 177),
      opacity: .3,
    );
    rounded(
      c,
      const Rect.fromLTWH(184, 94, 32, 157),
      1,
      ink.withValues(alpha: .26),
    );
    path(
      c,
      Path()
        ..moveTo(201, 106)
        ..cubicTo(154, 98, 142, 48, 176, 52)
        ..cubicTo(197, 55, 205, 91, 201, 106)
        ..close(),
      color: pearl,
    );
    path(
      c,
      Path()
        ..moveTo(201, 106)
        ..cubicTo(246, 102, 262, 48, 227, 52)
        ..cubicTo(211, 56, 204, 89, 201, 106)
        ..close(),
      color: plane,
    );
    path(
      c,
      Path()
        ..moveTo(201, 106)
        ..cubicTo(154, 98, 142, 48, 176, 52)
        ..cubicTo(197, 55, 205, 91, 201, 106)
        ..moveTo(201, 106)
        ..cubicTo(246, 102, 262, 48, 227, 52)
        ..cubicTo(211, 56, 204, 89, 201, 106),
      opacity: .7,
    );
    if (!compact) segment(c, 109, 265, 291, 265, .25);
  }

  void _editorial(Canvas c, bool compact) {
    // Offset paper leaves, an abstract drop-cap and ruled editorial columns.
    rounded(c, const Rect.fromLTWH(113, 58, 196, 213), 5, plane);
    rounded(c, const Rect.fromLTWH(87, 35, 196, 216), 5, pearl, outline: true);
    rounded(c, const Rect.fromLTWH(107, 62, 60, 63), 2, plane);
    path(
      c,
      Path()
        ..moveTo(119, 110)
        ..lineTo(138, 76)
        ..lineTo(156, 110)
        ..moveTo(128, 97)
        ..lineTo(148, 97),
      opacity: .65,
    );
    segment(c, 184, 68, 259, 68);
    segment(c, 184, 85, 247, 85, .45);
    segment(c, 184, 103, 259, 103, .35);
    for (var i = 0; i < (compact ? 3 : 5); i++) {
      segment(c, 109, 146 + i * 16, 177, 146 + i * 16, .35);
      segment(
        c,
        194,
        146 + i * 16,
        260 - (i.isEven ? 0 : 12),
        146 + i * 16,
        .35,
      );
    }
    if (!compact) segment(c, 148, 232, 225, 232, .25);
  }

  void _portrait(Canvas c, bool compact) {
    // Faceless, visibly illustrative profile; no gender, clothing or credentials.
    rounded(c, const Rect.fromLTWH(110, 30, 182, 246), 46, plane);
    path(
      c,
      Path()
        ..moveTo(126, 255)
        ..cubicTo(126, 204, 155, 186, 200, 186)
        ..cubicTo(245, 186, 275, 204, 275, 255)
        ..close(),
      color: pearl,
    );
    c.drawOval(const Rect.fromLTWH(166, 78, 69, 87), fill(pearl));
    c.drawOval(const Rect.fromLTWH(166, 78, 69, 87), line(.65));
    path(
      c,
      Path()
        ..moveTo(126, 255)
        ..cubicTo(126, 204, 155, 186, 200, 186)
        ..cubicTo(245, 186, 275, 204, 275, 255),
      opacity: .65,
    );
    if (!compact) {
      segment(c, 147, 56, 174, 56, .3);
      segment(c, 226, 251, 254, 251, .3);
      path(
        c,
        Path()
          ..moveTo(183, 196)
          ..quadraticBezierTo(200, 211, 218, 196),
        opacity: .25,
      );
    }
  }

  void _conversation(Canvas c, bool compact) {
    rounded(
      c,
      const Rect.fromLTWH(143, 117, 182, 110),
      25,
      plane,
      outline: true,
    );
    path(
      c,
      Path()
        ..moveTo(273, 225)
        ..lineTo(292, 248)
        ..lineTo(294, 222),
      color: plane,
    );
    rounded(c, const Rect.fromLTWH(69, 53, 207, 127), 28, pearl, outline: true);
    path(
      c,
      Path()
        ..moveTo(107, 176)
        ..lineTo(91, 201)
        ..lineTo(135, 177),
      color: pearl,
    );
    for (final x in [132.0, 171.0, 210.0]) {
      c.drawCircle(
        Offset(x, 117),
        compact ? 4 : 3,
        fill(ink.withValues(alpha: .6)),
      );
    }
    if (!compact) {
      segment(c, 213, 199, 269, 199, .3);
      segment(c, 61, 242, 100, 242, .25);
      segment(c, 80, 232, 80, 252, .25);
    }
  }

  @override
  bool shouldRepaint(_PremiumArtwork oldDelegate) =>
      category != oldDelegate.category || dark != oldDelegate.dark;
}
