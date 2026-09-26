import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';

/// Helper to validate network image URLs safely before calling NetworkImage or Image.network
bool isValidNetworkImageUrl(String? url) {
  if (url == null) return false;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;
  final lower = trimmed.toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

/// Bulletproof Luxury Image widget that avoids "No host specified in URI" crashes
class LuxuryImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;
  final double? iconSize;
  final Widget? customPlaceholder;

  const LuxuryImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.local_hospital_outlined,
    this.iconSize,
    this.customPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    Widget buildPlaceholder() {
      if (customPlaceholder != null) return customPlaceholder!;

      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131A26) : const Color(0xFFE2E8F0),
          borderRadius: borderRadius,
          border: Border.all(
            color: AppColors.border(context).withValues(alpha: 0.5),
            width: 0.7,
          ),
        ),
        child: Center(
          child: Icon(
            placeholderIcon,
            size: iconSize ?? (height != null ? (height! * 0.38).clamp(20.0, 48.0) : 32.0),
            color: isDark ? AppColors.silverMuted : AppColors.lightTextMuted,
          ),
        ),
      );
    }

    if (!isValidNetworkImageUrl(imageUrl)) {
      return buildPlaceholder();
    }

    Widget image = Image.network(
      imageUrl!.trim(),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => buildPlaceholder(),
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}

/// Bulletproof Luxury Circular Avatar for Doctors and Staff
class LuxuryAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData fallbackIcon;
  final Color? backgroundColor;

  const LuxuryAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24,
    this.fallbackIcon = Icons.person_outline_rounded,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bg = backgroundColor ??
        (isDark ? const Color(0xFF161E2E) : const Color(0xFFE2E8F0));

    Widget fallback() {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: Icon(
          fallbackIcon,
          size: radius * 1.1,
          color: AppColors.accentChampagne,
        ),
      );
    }

    if (!isValidNetworkImageUrl(imageUrl)) {
      return fallback();
    }

    return ClipOval(
      child: Image.network(
        imageUrl!.trim(),
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback(),
      ),
    );
  }
}
