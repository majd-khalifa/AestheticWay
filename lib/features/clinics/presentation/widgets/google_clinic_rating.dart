import '../../../../core/widgets/lazy_tab_stack.dart';
import '../../../../core/auth/session_changed_exception.dart';
import '../../../../core/widgets/async_action_button.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/widgets/rating_chip.dart';
import '../../models/clinic_model.dart';

/// Only ClinicModel's validated Google fields can enter this patient badge.
class GoogleClinicRating extends StatefulWidget {
  const GoogleClinicRating({super.key, required this.clinic, this.openMap});
  final ClinicModel clinic;
  final Future<bool> Function(Uri)? openMap;
  @override
  State<GoogleClinicRating> createState() => _GoogleClinicRatingState();
}

class _GoogleClinicRatingState extends State<GoogleClinicRating> {
  bool _busy = false, _failed = false;
  Future<void> _open(Uri uri) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    final action = AsyncActionScope(
      () =>
          mounted &&
          TabActivity.isActive(context) &&
          (ModalRoute.isCurrentOf(context) ?? true),
    );
    try {
      final opened = await action.wait(
        widget.openMap?.call(uri) ??
            launchUrl(uri, mode: LaunchMode.externalApplication),
      );
      if (!opened) throw StateError('Map handler unavailable');
    } on SessionChangedException {
      // A disposed route or changed account must not show stale feedback.
    } catch (_) {
      try {
        action.ensureCurrent();
        setState(() => _failed = true);
      } on SessionChangedException {
        /* silent cancellation */
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.clinic.hasGoogleRating) return const SizedBox.shrink();
    final uri = widget.clinic.mapsUri;
    final badge = RatingChip(
      rating: widget.clinic.googleRating,
      reviewCount: widget.clinic.googleReviewsCount,
      showGoogleSource: true,
    );
    if (uri == null) return badge;
    return Semantics(
      button: true,
      label: LocaleService().isArabic
          ? 'تقييم Google، افتح الخرائط'
          : 'Google rating, open Maps',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _busy ? null : () => _open(uri),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_busy)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          LocaleService().isArabic
                              ? 'جارٍ فتح الخرائط'
                              : 'Opening Maps',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  )
                else
                  badge,
                if (_failed)
                  Text(
                    LocaleService().isArabic
                        ? 'تعذر فتح الخرائط. اضغط للمحاولة مجدداً.'
                        : 'Maps could not open. Tap to retry.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
