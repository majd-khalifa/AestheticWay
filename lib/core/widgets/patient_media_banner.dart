import '../localization/app_locale.dart';
import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'luxury_image.dart';

/// Genuine photography keeps its intended framing. Absent or failed media uses
/// a compact editorial strip, never a large empty photograph or invented image.
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
    if (provider == null) return const PatientMediaFallback();
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
            errorBuilder: (_, _, _) => const PatientMediaFallback(),
          );
        },
      ),
    );
  }
}

/// Content-sized missing-media treatment, deliberately independent of photo ratio.
class PatientMediaFallback extends StatelessWidget {
  const PatientMediaFallback({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    color: AppColors.surfaceSubtle(context),
    child: Row(
      children: [
        Icon(
          Icons.photo_outlined,
          size: 22,
          color: AppColors.goldText(context),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            LocaleService().isArabic
                ? 'الصور غير متاحة'
                : 'Photography unavailable',
            style: TextStyle(fontSize: 12, color: AppColors.subtext(context)),
          ),
        ),
      ],
    ),
  );
}
