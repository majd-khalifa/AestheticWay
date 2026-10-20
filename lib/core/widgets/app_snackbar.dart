import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';

/// SnackBar severity types
enum AppSnackBarType { info, success, error, warning }

/// Unified Luxury App SnackBar Helper for AESTHETIC WAY
/// Uses rootOverlay to guarantee banners render on top of modal bottom sheets & dialogs,
/// with high-contrast readable text, distinct Dark/Light elevated surface,
/// floating behavior, icons, and consistent duration across all screens.
class AppSnackBar {
  static OverlayEntry? _currentEntry;

  static void dismissCurrent() {
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static void show(
    BuildContext context,
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (message.trim().isEmpty) return;

    final overlay =
        Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    if (overlay != null) {
      dismissCurrent();

      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (ctx) => _LuxuryToastOverlay(
          message: message,
          type: type,
          duration: duration,
          actionLabel: actionLabel,
          onAction: onAction,
          onDismiss: () {
            if (_currentEntry == entry) {
              entry.remove();
              _currentEntry = null;
            }
          },
        ),
      );
      _currentEntry = entry;
      overlay.insert(entry);
      return;
    }

    // Fallback to ScaffoldMessenger if overlay is not available
    _showScaffoldSnackBar(
      context,
      message,
      type: type,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void _showScaffoldSnackBar(
    BuildContext context,
    String message, {
    required AppSnackBarType type,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final style = _resolveStyle(context, type);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(style.icon, color: style.iconColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: style.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: style.bg,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: style.border, width: 1.0),
        ),
        duration: duration,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: style.iconColor,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static _SnackStyle _resolveStyle(BuildContext context, AppSnackBarType type) {
    final isDark = AppColors.isDark(context);
    switch (type) {
      case AppSnackBarType.success:
        return _SnackStyle(
          bg: isDark ? const Color(0xFF062817) : const Color(0xFFE8F8F0),
          border: const Color(0xFF10B981),
          iconColor: const Color(0xFF10B981),
          icon: Icons.check_circle_rounded,
          textColor: isDark ? const Color(0xFFE6F4EA) : const Color(0xFF065F46),
        );
      case AppSnackBarType.error:
        return _SnackStyle(
          bg: isDark ? const Color(0xFF2C0B0E) : const Color(0xFFFDE8E8),
          border: AppColors.errorRed,
          iconColor: AppColors.errorRed,
          icon: Icons.error_outline_rounded,
          textColor: isDark ? const Color(0xFFFCE8E6) : const Color(0xFF991B1B),
        );
      case AppSnackBarType.warning:
        return _SnackStyle(
          bg: isDark ? const Color(0xFF2B1D06) : const Color(0xFFFEF3C7),
          border: AppColors.accentChampagne,
          iconColor: isDark
              ? AppColors.accentChampagne
              : const Color(0xFFB45309),
          icon: Icons.warning_amber_rounded,
          textColor: isDark ? const Color(0xFFFEF3C7) : const Color(0xFF78350F),
        );
      case AppSnackBarType.info:
        return _SnackStyle(
          bg: isDark ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9),
          border: isDark
              ? AppColors.silverSecondary.withValues(alpha: 0.5)
              : const Color(0xFF94A3B8),
          iconColor: isDark
              ? AppColors.accentChampagne
              : const Color(0xFF0F172A),
          icon: Icons.info_outline_rounded,
          textColor: isDark ? AppColors.silverPrimary : const Color(0xFF0F172A),
        );
    }
  }

  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message, type: AppSnackBarType.success, duration: duration);
  }

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message, type: AppSnackBarType.error, duration: duration);
  }

  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message, type: AppSnackBarType.warning, duration: duration);
  }

  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message, type: AppSnackBarType.info, duration: duration);
  }
}

class _SnackStyle {
  final Color bg;
  final Color border;
  final Color iconColor;
  final IconData icon;
  final Color textColor;

  const _SnackStyle({
    required this.bg,
    required this.border,
    required this.iconColor,
    required this.icon,
    required this.textColor,
  });
}

class _LuxuryToastOverlay extends StatefulWidget {
  final String message;
  final AppSnackBarType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _LuxuryToastOverlay({
    required this.message,
    required this.type,
    required this.duration,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  @override
  State<_LuxuryToastOverlay> createState() => _LuxuryToastOverlayState();
}

class _LuxuryToastOverlayState extends State<_LuxuryToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;
  Timer? _timer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _animController.forward();

    _timer = Timer(widget.duration, () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (_isDismissing || !mounted) return;
    _isDismissing = true;
    _timer?.cancel();
    _animController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = AppSnackBar._resolveStyle(context, widget.type);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Dismissible(
                key: ValueKey('toast_${widget.message.hashCode}'),
                direction: DismissDirection.up,
                onDismissed: (_) => widget.onDismiss(),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: style.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: style.border, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(style.icon, color: style.iconColor, size: 20),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: AppTypography.bodyMedium.copyWith(
                              color: style.textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                        if (widget.actionLabel != null &&
                            widget.onAction != null) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              _dismiss();
                              widget.onAction?.call();
                            },
                            child: Text(
                              widget.actionLabel!,
                              style: TextStyle(
                                color: style.iconColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Global convenience function
void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackBarType type = AppSnackBarType.info,
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  AppSnackBar.show(
    context,
    message,
    type: type,
    duration: duration,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}
