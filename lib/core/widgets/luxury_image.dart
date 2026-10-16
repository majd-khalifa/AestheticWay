import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';

/// Resolves a full HTTP/HTTPS or relative `/media/...` URL against [ApiConfig.siteOrigin].
/// Returns `null` if [url] is null, empty, or invalid.
String? resolveNetworkImageUrl(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  final lower = trimmed.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return trimmed;
  }
  if (trimmed.startsWith('/')) {
    return '${ApiConfig.siteOrigin}$trimmed';
  }
  if (lower.startsWith('media/')) {
    return '${ApiConfig.siteOrigin}/$trimmed';
  }
  return null;
}

/// Helper to validate network image URLs safely before calling NetworkImage or Image.network
bool isValidNetworkImageUrl(String? url) {
  if (url == null) return false;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;
  final lower = trimmed.toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

/// Computes RAM-safe decode width in physical pixels based on device pixel ratio.
/// Capped at a sensible maximum (e.g. 1080px for banners, 400px for thumbnails) to prevent memory bloat.
int? computeSafeCacheWidth(BuildContext context, double? targetWidth, double? targetHeight) {
  try {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    double effectiveWidth = 400;
    if (targetWidth != null && targetWidth.isFinite && targetWidth > 0) {
      effectiveWidth = targetWidth;
    } else if (targetHeight != null && targetHeight.isFinite && targetHeight > 0) {
      effectiveWidth = targetHeight * 1.4;
    }
    final pixelWidth = (effectiveWidth * dpr).round();
    return pixelWidth.clamp(100, 1080);
  } catch (_) {
    return 600;
  }
}

/// Bulletproof Luxury Image widget with Smart Brand/Clinic Logo Fallbacks & RAM-Safe Image Decoding
class LuxuryImage extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackLogoUrl;
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
    this.fallbackLogoUrl,
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
    final safeCacheWidth = computeSafeCacheWidth(context, width, height);

    Widget buildBrandEmblemFallback() {
      final emblemSize = (height != null && height!.isFinite
              ? (height! * 0.42).clamp(24.0, 64.0)
              : (width != null && width!.isFinite ? (width! * 0.42).clamp(24.0, 64.0) : 42.0))
          .toDouble();

      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF070C1A),
          borderRadius: borderRadius,
          border: Border.all(
            color: AppColors.accentChampagne.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1527),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.silverPrimary.withValues(alpha: 0.20),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/aesthetic_way_logo.png',
              width: emblemSize,
              height: emblemSize,
              fit: BoxFit.contain,
              cacheWidth: (emblemSize * 2).round().clamp(48, 200),
              errorBuilder: (_, _, _) => Icon(
                placeholderIcon,
                size: iconSize ?? emblemSize * 0.8,
                color: AppColors.accentChampagne,
              ),
            ),
          ),
        ),
      );
    }

    Widget buildClinicLogoFallback(String resolvedLogoUrl) {
      final logoSize = (height != null && height!.isFinite
              ? (height! * 0.48).clamp(30.0, 72.0)
              : (width != null && width!.isFinite ? (width! * 0.48).clamp(30.0, 72.0) : 48.0))
          .toDouble();

      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF070C1A),
          borderRadius: borderRadius,
          border: Border.all(
            color: AppColors.border(context).withValues(alpha: 0.4),
            width: 0.7,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1527),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accentChampagne.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: ClipOval(
              child: Image.network(
                resolvedLogoUrl,
                width: logoSize,
                height: logoSize,
                fit: BoxFit.cover,
                cacheWidth: (logoSize * 2).round().clamp(60, 300),
                errorBuilder: (_, _, _) => buildBrandEmblemFallback(),
              ),
            ),
          ),
        ),
      );
    }

    Widget buildSmartFallback() {
      if (customPlaceholder != null) return customPlaceholder!;
      final resolvedLogo = resolveNetworkImageUrl(fallbackLogoUrl);
      if (resolvedLogo != null && resolvedLogo.isNotEmpty) {
        return buildClinicLogoFallback(resolvedLogo);
      }
      return buildBrandEmblemFallback();
    }

    final resolvedUrl = resolveNetworkImageUrl(imageUrl);
    if (resolvedUrl == null) {
      Widget fallback = buildSmartFallback();
      if (borderRadius != null) {
        fallback = ClipRRect(borderRadius: borderRadius!, child: fallback);
      }
      return fallback;
    }

    Widget image = Image.network(
      resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: safeCacheWidth,
      errorBuilder: (context, error, stackTrace) => buildSmartFallback(),
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

/// Bulletproof Luxury Circular Avatar with Clinic Logo and Brand Fallback
class LuxuryAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackLogoUrl;
  final double radius;
  final IconData fallbackIcon;
  final Color? backgroundColor;

  const LuxuryAvatar({
    super.key,
    required this.imageUrl,
    this.fallbackLogoUrl,
    this.radius = 24,
    this.fallbackIcon = Icons.person_outline_rounded,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final safeCacheWidth = (radius * 2 * dpr).round().clamp(60, 400);

    Widget buildBrandEmblemFallback() {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF070C1A),
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accentChampagne.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          padding: EdgeInsets.all(radius * 0.28),
          child: Image.asset(
            'assets/images/aesthetic_way_logo.png',
            fit: BoxFit.contain,
            cacheWidth: safeCacheWidth,
            errorBuilder: (_, _, _) => Icon(
              fallbackIcon,
              size: radius * 1.1,
              color: AppColors.accentChampagne,
            ),
          ),
        ),
      );
    }

    Widget buildClinicLogoFallback(String resolvedLogo) {
      return ClipOval(
        child: Container(
          width: radius * 2,
          height: radius * 2,
          color: const Color(0xFF070C1A),
          child: Image.network(
            resolvedLogo,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            cacheWidth: safeCacheWidth,
            errorBuilder: (_, _, _) => buildBrandEmblemFallback(),
          ),
        ),
      );
    }

    Widget buildFallback() {
      final resolvedLogo = resolveNetworkImageUrl(fallbackLogoUrl);
      if (resolvedLogo != null && resolvedLogo.isNotEmpty) {
        return buildClinicLogoFallback(resolvedLogo);
      }
      return buildBrandEmblemFallback();
    }

    final resolvedUrl = resolveNetworkImageUrl(imageUrl);
    if (resolvedUrl == null) {
      return buildFallback();
    }

    return ClipOval(
      child: Image.network(
        resolvedUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        cacheWidth: safeCacheWidth,
        errorBuilder: (context, error, stackTrace) => buildFallback(),
      ),
    );
  }
}
