import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../localization/app_locale.dart';
import 'luxury_image.dart';
import 'app_snackbar.dart';

/// Luxury styled native image picker field supporting Camera and Gallery selection
/// with instant preview, remove/replace actions, and full RTL/LTR bilingual design.
class LuxuryImagePickerField extends StatefulWidget {
  final String label;
  final String? initialUrl;
  final String? initialLocalPath;
  final ValueChanged<String?> onImageSelected;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final String? helperText;
  final bool isRequired;
  final bool isCircular;
  final BoxFit fit;
  final bool compactPlaceholder;
  final String? mediaCacheKey;
  final bool enabled;

  /// Gallery mode selects multiple genuine images; existing single-image fields stay unchanged.
  final ValueChanged<List<String>>? onImagesSelected;

  /// Lets an owning editor defer lifecycle refresh until native selection ends.
  final ValueChanged<bool>? onPickingChanged;
  final int maxImages;

  const LuxuryImagePickerField({
    super.key,
    required this.label,
    this.initialUrl,
    this.initialLocalPath,
    required this.onImageSelected,
    this.height = 140,
    this.width,
    this.borderRadius,
    this.helperText,
    this.isRequired = false,
    this.isCircular = false,
    this.fit = BoxFit.cover,
    this.compactPlaceholder = false,
    this.mediaCacheKey,
    this.enabled = true,
    this.onImagesSelected,
    this.onPickingChanged,
    this.maxImages = 10,
  });

  @override
  State<LuxuryImagePickerField> createState() => _LuxuryImagePickerFieldState();
}

class _LuxuryImagePickerFieldState extends State<LuxuryImagePickerField> {
  final ImagePicker _picker = ImagePicker();
  bool _picking = false;
  bool _menuOpen = false;
  String? _localPath;
  String? _remoteUrl;

  @override
  void initState() {
    super.initState();
    _localPath = widget.initialLocalPath;
    _remoteUrl = widget.initialUrl;
  }

  @override
  void didUpdateWidget(covariant LuxuryImagePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLocalPath != oldWidget.initialLocalPath) {
      _localPath = widget.initialLocalPath;
    }
    if (widget.initialUrl != oldWidget.initialUrl && _localPath == null) {
      _remoteUrl = widget.initialUrl;
    }
  }

  bool get _hasImage {
    if (_localPath != null && _localPath!.isNotEmpty) {
      return File(_localPath!).existsSync();
    }
    return _remoteUrl != null && _remoteUrl!.isNotEmpty;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_picking || !widget.enabled) return;
    setState(() => _picking = true);
    widget.onPickingChanged?.call(true);
    try {
      if (source == ImageSource.gallery &&
          widget.onImagesSelected != null &&
          widget.maxImages > 1) {
        final files = await _picker.pickMultiImage(
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
          requestFullMetadata: false,
          limit: widget.maxImages,
        );
        if (mounted && widget.enabled && files.isNotEmpty) {
          widget.onImagesSelected!(files.map((f) => f.path).toList());
        }
        return;
      }
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 78,
        requestFullMetadata: false,
      );

      if (!mounted || !widget.enabled) return;
      if (file != null) {
        if (widget.onImagesSelected != null) {
          widget.onImagesSelected!([file.path]);
          return;
        }
        setState(() {
          _localPath = file.path;
        });
        widget.onImageSelected(file.path);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[image_picker] Selection failed');
      if (mounted) {
        showAppSnackBar(
          context,
          LocaleService().isArabic
              ? 'تعذر اختيار الصورة. تحقق من صلاحيات الصور والكاميرا وحاول مجدداً.'
              : 'Could not select an image. Check photo/camera permissions and try again.',
          type: AppSnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _picking = false);
        widget.onPickingChanged?.call(false);
      }
    }
  }

  void _clearImage() {
    if (!widget.enabled) return;
    setState(() {
      _localPath = null;
      _remoteUrl = null;
    });
    widget.onImageSelected(null);
  }

  Future<void> _showPickerOptions(BuildContext context) async {
    if (!widget.enabled || _menuOpen || _picking) return;
    _menuOpen = true;
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    await showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.mutedText(context).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.label,
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.silverPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentChampagne.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.accentChampagne,
                    size: 20,
                  ),
                ),
                title: Text(
                  loc.isArabic ? 'اختيار من معرض الصور' : 'Choose from Gallery',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentChampagne.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.accentChampagne,
                    size: 20,
                  ),
                ),
                title: Text(
                  loc.isArabic ? 'التقاط صورة بالكاميرا' : 'Take a Photo',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_hasImage) ...[
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.errorRed,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    loc.isArabic ? 'حذف الصورة' : 'Remove Photo',
                    style: const TextStyle(
                      color: AppColors.errorRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _clearImage();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
    _menuOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);
    final radius = widget.isCircular
        ? BorderRadius.circular(widget.height / 2)
        : (widget.borderRadius ?? BorderRadius.circular(14));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label & optional required mark
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: AppTypography.caption.copyWith(
                  color: isDark
                      ? AppColors.silverPrimary
                      : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            if (widget.isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: AppColors.goldText(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Dropzone / Preview Container
        GestureDetector(
          onTap: widget.enabled ? () => _showPickerOptions(context) : null,
          child: Container(
            height: widget.height,
            width: widget.isCircular
                ? widget.height
                : (widget.width ?? double.infinity),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardSurfaceHover
                  : AppColors.lightCardSurfaceHover,
              borderRadius: radius,
              border: Border.all(
                color: _hasImage
                    ? AppColors.accentChampagne.withValues(alpha: 0.6)
                    : AppColors.border(context),
                width: _hasImage ? 1.2 : 0.8,
              ),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: _hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image Rendering
                        if (_localPath != null &&
                            _localPath!.isNotEmpty &&
                            File(_localPath!).existsSync())
                          Image.file(
                            File(_localPath!),
                            cacheWidth: 480,
                            fit: widget.fit,
                          )
                        else if (_remoteUrl != null && _remoteUrl!.isNotEmpty)
                          LuxuryImage(
                            imageUrl: _remoteUrl!,
                            fit: widget.fit,
                            mediaCacheKey: widget.mediaCacheKey,
                          ),

                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton.filled(
                            tooltip: loc.isArabic
                                ? 'استبدال الصورة أو حذفها'
                                : 'Replace or remove photo',
                            onPressed: widget.enabled
                                ? () => _showPickerOptions(context)
                                : null,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(
                                alpha: .65,
                              ),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(48, 48),
                            ),
                            icon: const Icon(Icons.more_horiz, size: 22),
                          ),
                        ),
                      ],
                    )
                  : widget.isCircular || widget.compactPlaceholder
                  ? Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.goldText(context),
                      size: 28,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accentChampagne.withValues(
                              alpha: isDark ? 0.12 : 0.18,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.accentChampagne,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          loc.isArabic
                              ? 'اضغط لاختيار صورة'
                              : 'Tap to upload photo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.silverPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.isArabic
                              ? 'كاميرا أو استوديو (PNG, JPG)'
                              : 'Camera or Gallery (PNG, JPG)',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.mutedText(context),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),

        if (widget.isCircular) ...[
          const SizedBox(height: 8),
          Text(
            loc.isArabic ? 'اضغط لاختيار صورة' : 'Tap to upload photo',
            style: TextStyle(
              color: AppColors.text(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            loc.isArabic ? 'الكاميرا أو معرض الصور' : 'Camera or Gallery',
            style: TextStyle(color: AppColors.mutedText(context), fontSize: 11),
          ),
        ],
        if (widget.helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.helperText!,
            style: AppTypography.caption.copyWith(
              color: AppColors.mutedText(context),
              fontSize: 10.5,
            ),
          ),
        ],
      ],
    );
  }
}
