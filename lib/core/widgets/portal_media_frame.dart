import 'package:flutter/material.dart';
import '../localization/app_locale.dart';
import '../theme/app_colors.dart';
import 'luxury_image.dart';

/// Portal-only first-frame, error and expansion behavior. No patient styling,
/// invented photographs, URL rewriting or global image-cache clearing.
class PortalMediaFrame extends StatefulWidget {
  const PortalMediaFrame({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.aspectRatio = 16 / 9,
    this.fit = BoxFit.cover,
    this.mediaCacheKey,
    this.expandable = false,
    this.label,
    this.radius = 20,
    this.icon = Icons.image_outlined,
    this.verifyRemoteDelivery = false,
  });
  final String? imageUrl, mediaCacheKey, label;
  final double? width, height;
  final double aspectRatio, radius;
  final BoxFit fit;
  final bool expandable;
  final IconData icon;

  /// Gallery audit only: do not substitute the selected local file for its URL.
  final bool verifyRemoteDelivery;
  @override
  State<PortalMediaFrame> createState() => _PortalMediaFrameState();
}

class _PortalMediaFrameState extends State<PortalMediaFrame> {
  int _attempt = 0;
  bool _retrying = false, _opening = false;
  ImageProvider? _decodedProvider, _originalProvider;
  String _text(String en, String ar) => LocaleService().isArabic ? ar : en;
  bool get _hasImage =>
      widget.imageUrl?.trim().isNotEmpty == true &&
      !RegExp(
        r'\.(mp4|mov|webm)(?:[?#]|$)',
        caseSensitive: false,
      ).hasMatch(widget.imageUrl!);

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    final configuration = createLocalImageConfiguration(context);
    try {
      await _decodedProvider?.evict(configuration: configuration);
      await _originalProvider?.evict(configuration: configuration);
    } finally {
      if (mounted) {
        setState(() {
          _attempt++;
          _retrying = false;
        });
      }
    }
  }

  Future<void> _expand() async {
    if (_opening || !_hasImage) return;
    _opening = true;
    try {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: AppColors.bg(context),
            appBar: AppBar(
              title: Text(
                widget.label ?? _text('Original image', 'الصورة الأصلية'),
              ),
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, box) => InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: PortalMediaFrame(
                    imageUrl: widget.imageUrl,
                    mediaCacheKey: widget.mediaCacheKey,
                    width: box.maxWidth,
                    height: box.maxHeight,
                    fit: BoxFit.contain,
                    radius: 0,
                    verifyRemoteDelivery: widget.verifyRemoteDelivery,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      _opening = false;
    }
  }

  Widget _panel({
    required bool loading,
    bool failed = false,
    Object? failure,
  }) => LayoutBuilder(
    builder: (context, box) {
      final roomy = box.maxWidth >= 170 && box.maxHeight >= 160;
      final message = loading
          ? _text('Loading image…', 'جارٍ تحميل الصورة…')
          : failed
          ? _text('Image unavailable', 'تعذر تحميل الصورة')
          : _text('No image added', 'لم تُضف صورة');
      return Semantics(
        label: message,
        liveRegion: loading || failed,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [
                AppColors.surfaceHover(context),
                AppColors.surface(context),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(roomy ? 12 : 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (roomy ||
                      (!failed && !loading) ||
                      !isValidNetworkImageUrl(
                        resolveNetworkImageUrl(widget.imageUrl),
                      ))
                    Icon(
                      loading
                          ? Icons.photo_outlined
                          : failed
                          ? Icons.broken_image_outlined
                          : widget.icon,
                      color: AppColors.goldText(context),
                      size: roomy ? 30 : 20,
                    ),
                  if (roomy) ...[
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.mutedText(context),
                        fontSize: 12,
                      ),
                    ),
                    if (failed && widget.verifyRemoteDelivery) ...[
                      const SizedBox(height: 6),
                      Text(
                        _text(
                          'Saved record and image delivery are separate.',
                          'سجل الصورة وتسليم ملفها مرحلتان مستقلتان.',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        'stage=imageLoad; HTTP=${failure is NetworkImageLoadException ? failure.statusCode : "none"}; kind=${failure is NetworkImageLoadException ? "network" : "decode_or_transport"}',
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ],
                  if ((failed || loading) &&
                      isValidNetworkImageUrl(
                        resolveNetworkImageUrl(widget.imageUrl),
                      ))
                    roomy
                        ? TextButton.icon(
                            onPressed: _retrying ? null : _retry,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: Text(_text('Retry', 'إعادة التحميل')),
                          )
                        : SizedBox(
                            height: 28,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              iconSize: 18,
                              tooltip: _text(
                                'Retry image',
                                'إعادة تحميل الصورة',
                              ),
                              onPressed: _retrying ? null : _retry,
                              icon: const Icon(Icons.refresh),
                            ),
                          ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    Widget frame = LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth.isFinite ? box.maxWidth : widget.width;
        final height = box.maxHeight.isFinite ? box.maxHeight : widget.height;
        _originalProvider = resolveImageProvider(
          _hasImage ? widget.imageUrl : null,
          mediaCacheKey: widget.mediaCacheKey,
          allowLocalCache: !widget.verifyRemoteDelivery,
        );
        _decodedProvider = _originalProvider == null
            ? null
            : boundedImageDecode(
                computeSafeCacheWidth(context, width, height),
                _originalProvider!,
              );
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: LuxuryImage(
            key: ValueKey('${widget.imageUrl}:$_attempt'),
            imageUrl: _hasImage ? widget.imageUrl : null,
            mediaCacheKey: widget.mediaCacheKey,
            allowLocalCache: !widget.verifyRemoteDelivery,
            width: width,
            height: height,
            fit: widget.fit,
            customPlaceholder: _panel(loading: false),
            errorPlaceholder: _panel(loading: false, failed: true),
            errorPlaceholderBuilder: widget.verifyRemoteDelivery
                ? (error) =>
                      _panel(loading: false, failed: true, failure: error)
                : null,
            loadingPlaceholder: _panel(loading: true),
          ),
        );
      },
    );
    frame = widget.height != null
        ? SizedBox(width: widget.width, height: widget.height, child: frame)
        : AspectRatio(aspectRatio: widget.aspectRatio, child: frame);
    if (!widget.expandable || !_hasImage) return frame;
    return Stack(
      children: [
        Semantics(
          button: true,
          label: _text('Expand original image', 'عرض الصورة الأصلية'),
          child: GestureDetector(onTap: _expand, child: frame),
        ),
        if (widget.width == null || widget.width! >= 160)
          PositionedDirectional(
            end: 8,
            top: 8,
            child: IconButton.filledTonal(
              onPressed: _expand,
              tooltip: _text('Expand original image', 'عرض الصورة الأصلية'),
              icon: const Icon(Icons.open_in_full, size: 18),
            ),
          ),
      ],
    );
  }
}
