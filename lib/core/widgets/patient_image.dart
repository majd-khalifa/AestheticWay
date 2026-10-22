import 'package:flutter/material.dart';
import 'luxury_image.dart';
import 'patient_media_placeholder.dart';

/// Patient-only fallback policy; portal image pickers/previews remain unchanged.
class PatientImage extends StatelessWidget {
  const PatientImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.mediaCacheKey,
  });
  final String? imageUrl, mediaCacheKey;
  final double? width, height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  @override
  Widget build(BuildContext context) => LuxuryImage(
    imageUrl: imageUrl,
    mediaCacheKey: mediaCacheKey,
    width: width,
    height: height,
    fit: fit,
    borderRadius: borderRadius,
    customPlaceholder: PatientMediaPlaceholder(width: width, height: height),
  );
}
