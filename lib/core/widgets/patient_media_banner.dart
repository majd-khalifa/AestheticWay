import 'package:flutter/material.dart';
import 'luxury_image.dart';

/// Photography has no reserved empty panel. Missing/failed media collapses while
/// the adjacent clinic/brand identity remains visible. No invented stock photo.
class PatientMediaBanner extends StatelessWidget {
  const PatientMediaBanner({
    super.key,
    required this.source,
    this.height = 180,
    this.aspectRatio,
    this.semanticLabel,
    this.borderRadius = BorderRadius.zero,
  });
  final String? source;
  final double height;
  final double? aspectRatio;
  final String? semanticLabel;
  final BorderRadius borderRadius;
  @override
  Widget build(BuildContext context) {
    final provider = resolveImageProvider(source);
    if (provider == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: borderRadius,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final displayHeight = aspectRatio == null
              ? height
              : width / aspectRatio!;
          return Image(
            key: ValueKey(provider),
            image: boundedImageDecode(
              computeSafeCacheWidth(context, width, displayHeight),
              provider,
            ),
            width: double.infinity,
            height: displayHeight,
            fit: BoxFit.cover,
            semanticLabel: semanticLabel,
            excludeFromSemantics: semanticLabel == null,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
