import 'package:flutter/material.dart';
import 'patient_image.dart';
export 'patient_media_placeholder.dart' show PatientMediaCategory;

/// Real media and the neutral brand panel always share the same frame.
class PatientMediaBanner extends StatelessWidget {
  const PatientMediaBanner({
    super.key,
    required this.source,
    required this.category,
    this.height = 180,
    this.aspectRatio,
    this.semanticLabel,
    this.borderRadius = BorderRadius.zero,
  });
  final String? source;
  final PatientMediaCategory category;
  final double height;
  final double? aspectRatio;
  final String? semanticLabel;
  final BorderRadius borderRadius;
  @override
  Widget build(BuildContext context) {
    final frame = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final displayHeight = aspectRatio == null
            ? height
            : width / aspectRatio!;
        return PatientImage(
          imageUrl: source,
          category: category,
          width: width,
          height: displayHeight,
          borderRadius: borderRadius,
        );
      },
    );
    // The placeholder has its own honest semantics. A real media label describes
    // the expected image without inventing its visual contents.
    return semanticLabel == null
        ? frame
        : Semantics(label: semanticLabel, child: frame);
  }
}
