import 'package:flutter/material.dart';
import 'luxury_image.dart';
import 'patient_media_placeholder.dart';
export 'patient_media_placeholder.dart' show PatientMediaCategory;

/// Known video paths never enter an image codec. Opaque extensionless sources
/// remain governed by their backend image field and genuine decoding result.
bool isKnownVideoSource(String? source) {
  final path = Uri.tryParse(source?.trim() ?? '')?.path.toLowerCase() ?? '';
  return RegExp(r'\.(mp4|mov|m4v|webm|m3u8|avi)$').hasMatch(path);
}

/// Patient-only fallback policy; portal image pickers/previews remain unchanged.
class PatientImage extends StatelessWidget {
  const PatientImage({
    super.key,
    required this.imageUrl,
    required this.category,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.mediaCacheKey,
  });
  final String? imageUrl, mediaCacheKey;
  final PatientMediaCategory category;
  final double? width, height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  @override
  Widget build(BuildContext context) => LuxuryImage(
    imageUrl: isKnownVideoSource(imageUrl) ? null : imageUrl,
    mediaCacheKey: mediaCacheKey,
    width: width,
    height: height,
    fit: fit,
    borderRadius: borderRadius,
    customPlaceholder: PatientMediaPlaceholder(
      category: category,
      reason: isKnownVideoSource(imageUrl)
          ? PatientMediaFallbackReason.unsupportedSource
          : PatientMediaFallbackReason.missing,
      width: width,
      height: height,
    ),
    errorPlaceholder: PatientMediaPlaceholder(
      category: category,
      reason: PatientMediaFallbackReason.loadFailed,
      width: width,
      height: height,
    ),
  );
}
