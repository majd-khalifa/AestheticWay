import 'package:flutter/material.dart';
import '../localization/app_locale.dart';
import '../theme/app_colors.dart';

/// A failed device write must never look like a successfully saved preference.
class PreferenceSaveStatus extends StatelessWidget {
  const PreferenceSaveStatus({
    super.key,
    required this.listenable,
    required this.saving,
    required this.failed,
    required this.onRetry,
  });
  final Listenable listenable;
  final bool Function() saving, failed;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: listenable,
    builder: (context, _) {
      final ar = LocaleService().isArabic;
      if (!saving() && !failed()) return const SizedBox.shrink();
      return Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              if (saving()) ...[
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  saving()
                      ? (ar ? 'جارٍ حفظ التفضيل' : 'Saving preference')
                      : (ar
                            ? 'تعذر حفظ التفضيل على الجهاز.'
                            : 'Could not save this preference on the device.'),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.subtext(context),
                  ),
                ),
              ),
              if (!saving() && failed())
                TextButton(
                  onPressed: onRetry,
                  child: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                ),
            ],
          ),
        ),
      );
    },
  );
}
