import 'package:flutter/material.dart';
import 'luxury_image.dart';

/// Photography has no reserved empty panel. Missing/failed media collapses while
/// the adjacent clinic/brand identity remains visible. No invented stock photo.
class PatientMediaBanner extends StatelessWidget {
  const PatientMediaBanner({
    super.key,
    required this.source,
    this.height = 180,
    this.borderRadius = BorderRadius.zero,
  });
  final String? source;
  final double height;
  final BorderRadius borderRadius;
  @override
  Widget build(BuildContext context) {
    final provider = resolveImageProvider(source);
    if (provider == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image(
        key: ValueKey(provider),
        image: ResizeImage.resizeIfNeeded(
          computeSafeCacheWidth(
            context,
            MediaQuery.sizeOf(context).width,
            height,
          ),
          null,
          provider,
        ),
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
