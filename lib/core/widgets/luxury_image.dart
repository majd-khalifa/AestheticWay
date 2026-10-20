import '../services/local_media_cache.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';

/// Resolves network/storage URLs without treating assets or device files as HTTP.
String? resolveNetworkImageUrl(String? url) {
  final resolved = ApiConfig.resolveUrl(url);
  return isValidNetworkImageUrl(resolved) ? resolved : null;
}

bool isValidNetworkImageUrl(String? url) {
  final uri = Uri.tryParse(url?.trim() ?? '');
  return uri != null &&
      uri.host.isNotEmpty &&
      (uri.scheme.toLowerCase() == 'http' ||
          uri.scheme.toLowerCase() == 'https');
}

/// Use the actual source. A valid device/asset path is not a missing image.
ImageProvider? resolveImageProvider(String? source, {String? mediaCacheKey}) {
  final cached = LocalMediaCache().lookup(
    entityKey: mediaCacheKey,
    remoteUrl: source,
  );
  if (cached != null) return FileImage(File(cached));
  if (source == null || source.trim().isEmpty) return null;
  final value = source.trim();
  if (value.startsWith('assets/')) return AssetImage(value);
  // Uri treats a Windows drive letter as a scheme ("C:" becomes "c").
  // Classify absolute drive/UNC paths before URI parsing, just as file: URIs
  // use FileImage regardless of existence; load errors select the fallback.
  if (RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(value) || value.startsWith(r'\\')) {
    return FileImage(File(value));
  }
  final uri = Uri.tryParse(value);
  if (uri?.scheme == 'file') {
    try {
      return FileImage(File.fromUri(uri!));
    } on ArgumentError {
      return null;
    }
  }
  if (uri == null || !uri.hasScheme) {
    final file = File(value);
    if (file.existsSync()) return FileImage(file);
  }
  final network = resolveNetworkImageUrl(value);
  return network == null ? null : NetworkImage(network);
}

/// Computes RAM-safe decode width in physical pixels based on device pixel ratio.
/// Capped at a sensible maximum (e.g. 1080px for banners, 400px for thumbnails) to prevent memory bloat.
int? computeSafeCacheWidth(
  BuildContext context,
  double? targetWidth,
  double? targetHeight,
) {
  try {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    double effectiveWidth = 400;
    if (targetWidth != null && targetWidth.isFinite && targetWidth > 0) {
      effectiveWidth = targetWidth;
    } else if (targetHeight != null &&
        targetHeight.isFinite &&
        targetHeight > 0) {
      effectiveWidth = targetHeight * 1.4;
    }
    final pixelWidth = (effectiveWidth * dpr).round();
    return pixelWidth.clamp(100, 1080);
  } catch (_) {
    return 600;
  }
}

/// Shared app budget; active image streams still need bounded decode dimensions.
void configureImageCacheBudget() {
  PaintingBinding.instance.imageCache.maximumSize = 120;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 64 * 1024 * 1024;
}

/// Fit keeps the original aspect ratio. The height ceiling also bounds very
/// tall source files; normal cover resolution and signed URL bytes are retained.
ImageProvider boundedImageDecode(
  int? width,
  ImageProvider provider, {
  int maxHeight = 2160,
}) => ResizeImage(
  provider,
  width: width,
  height: maxHeight,
  policy: ResizeImagePolicy.fit,
);

/// Bulletproof Luxury Image widget with Smart Brand/Clinic Logo Fallbacks & RAM-Safe Image Decoding
class LuxuryImage extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackLogoUrl;
  final String? mediaCacheKey;
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
    this.mediaCacheKey,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.local_hospital_outlined,
    this.iconSize,
    this.customPlaceholder,
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: LocalMediaCache(),
    builder: (context, _) => _buildImage(context),
  );

  Widget _buildImage(BuildContext context) {
    final safeCacheWidth = computeSafeCacheWidth(context, width, height);
    final primaryProvider = resolveImageProvider(
      imageUrl,
      mediaCacheKey: mediaCacheKey,
    );

    Widget buildBrandEmblemFallback() => Container(
      width: width,
      height: height,
      color: AppColors.surfaceHover(context),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Image.asset(
          'assets/images/aesthetic_way_logo.png',
          width: 64,
          height: 64,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Icon(
            placeholderIcon,
            size: iconSize ?? 32,
            color: AppColors.mutedText(context),
          ),
        ),
      ),
    );

    Widget buildClinicLogoFallback(ImageProvider logoProvider) {
      final shortestSide =
          (width != null &&
              width!.isFinite &&
              height != null &&
              height!.isFinite)
          ? (width! < height! ? width! : height!)
          : (height != null && height!.isFinite
                ? height!
                : (width != null && width!.isFinite ? width! : 120.0));
      final logoPadding = (shortestSide * 0.16).clamp(8.0, 28.0);
      final logoBadgeSize = (shortestSide * 0.75).clamp(34.0, 145.0);

      return Container(
        width: width,
        height: height,
        color: AppColors.surfaceHover(context),
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.all(logoPadding),
          child: Image(
            image: boundedImageDecode(
              (logoBadgeSize * MediaQuery.devicePixelRatioOf(context))
                  .round()
                  .clamp(60, 400),
              logoProvider,
            ),
            width: logoBadgeSize,
            height: logoBadgeSize,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                customPlaceholder ?? buildBrandEmblemFallback(),
          ),
        ),
      );
    }

    Widget buildSmartFallback() {
      final logoProvider = resolveImageProvider(fallbackLogoUrl);
      if (logoProvider != null && logoProvider != primaryProvider) {
        return buildClinicLogoFallback(logoProvider);
      }
      return customPlaceholder ?? buildBrandEmblemFallback();
    }

    if (primaryProvider == null) {
      Widget fallback = buildSmartFallback();
      if (borderRadius != null) {
        fallback = ClipRRect(borderRadius: borderRadius!, child: fallback);
      }
      return fallback;
    }

    Widget image = Image(
      key: ValueKey(primaryProvider),
      image: boundedImageDecode(safeCacheWidth, primaryProvider),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => buildSmartFallback(),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}

/// Bulletproof Luxury Circular Avatar with Clinic Logo and Brand Fallback
class LuxuryAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackLogoUrl;
  final String? mediaCacheKey;
  final double radius;
  final IconData fallbackIcon;
  final Color? backgroundColor;

  const LuxuryAvatar({
    super.key,
    required this.imageUrl,
    this.fallbackLogoUrl,
    this.mediaCacheKey,
    this.radius = 24,
    this.fallbackIcon = Icons.person_outline_rounded,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: LocalMediaCache(),
    builder: (context, _) => _buildImage(context),
  );

  Widget _buildImage(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final safeCacheWidth = (radius * 2 * dpr).round().clamp(60, 400);
    final primaryProvider = resolveImageProvider(
      imageUrl,
      mediaCacheKey: mediaCacheKey,
    );

    Widget buildBrandEmblemFallback() {
      final emblemPadding = (radius * 2 * 0.20).clamp(6.0, 20.0);
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0xFF070C1A),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.accentChampagne.withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
        padding: EdgeInsets.all(emblemPadding),
        child: Image.asset(
          'assets/images/aesthetic_way_logo.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => Icon(
            fallbackIcon,
            size: radius * 1.1,
            color: AppColors.accentChampagne,
          ),
        ),
      );
    }

    Widget buildClinicLogoFallback(ImageProvider logoProvider) {
      final logoPadding = (radius * 2 * 0.16).clamp(4.0, 16.0);
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0xFF070C1A),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.accentChampagne.withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
        padding: EdgeInsets.all(logoPadding),
        child: Image(
          image: boundedImageDecode(
            safeCacheWidth,
            logoProvider,
            maxHeight: 1600,
          ),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => buildBrandEmblemFallback(),
        ),
      );
    }

    Widget buildFallback() {
      final logoProvider = resolveImageProvider(fallbackLogoUrl);
      if (logoProvider != null && logoProvider != primaryProvider) {
        return buildClinicLogoFallback(logoProvider);
      }
      return buildBrandEmblemFallback();
    }

    if (primaryProvider == null) {
      return buildFallback();
    }

    return ClipOval(
      child: Image(
        key: ValueKey(primaryProvider),
        image: boundedImageDecode(
          safeCacheWidth,
          primaryProvider,
          maxHeight: 1600,
        ),
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => buildFallback(),
      ),
    );
  }
}
