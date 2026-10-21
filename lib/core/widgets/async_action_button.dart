import 'package:flutter/material.dart';
import '../auth/session_snapshot.dart';
import '../auth/session_changed_exception.dart';
import '../network/api_exception.dart';
import '../localization/app_locale.dart';
import 'silver_button.dart';
import 'lazy_tab_stack.dart';

/// Check after each prerequisite, before navigation or any UI side effect.
class AsyncActionScope {
  AsyncActionScope(this._mounted);
  final bool Function() _mounted;
  final SessionSnapshot _session = SessionSnapshot();
  void ensureCurrent() {
    if (!_mounted()) throw const SessionChangedException();
    _session.ensureCurrent();
  }

  Future<T> wait<T>(Future<T> prerequisite) async {
    final result = await prerequisite;
    ensureCurrent();
    return result;
  }
}

typedef AsyncPatientAction = Future<void> Function(AsyncActionScope action);

/// A local, synchronous duplicate guard; never locks unrelated controls.
class AsyncActionButton extends StatefulWidget {
  const AsyncActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loadingLabel,
    this.errorLabel,
    this.icon,
    this.isFullWidth = false,
    this.variant = SilverButtonVariant.primary,
  });
  final String label;
  final String? loadingLabel, errorLabel;
  final AsyncPatientAction? onPressed;
  final IconData? icon;
  final bool isFullWidth;
  final SilverButtonVariant variant;
  @override
  State<AsyncActionButton> createState() => _AsyncActionButtonState();
}

class _AsyncActionButtonState extends State<AsyncActionButton> {
  bool _busy = false;
  String? _error;

  Future<void> _run() async {
    if (_busy || widget.onPressed == null) return;
    final action = AsyncActionScope(
      () =>
          mounted &&
          TabActivity.isActive(context) &&
          (ModalRoute.isCurrentOf(context) ?? true),
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onPressed!(action);
    } on SessionChangedException {
      // An old account/route must not navigate or display a stale error.
    } catch (error) {
      try {
        action.ensureCurrent();
        if (error is! ApiException || !error.isCancelled) {
          setState(
            () => _error =
                widget.errorLabel ??
                (LocaleService().isArabic
                    ? 'تعذر إتمام الطلب. اضغط للمحاولة مجدداً.'
                    : 'Unable to complete. Tap to try again.'),
          );
        }
      } on SessionChangedException {
        /* silent cancellation */
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SilverButton(
        label: widget.label,
        loadingLabel:
            widget.loadingLabel ??
            (LocaleService().isArabic ? 'جارٍ إتمام الطلب' : 'Please wait'),
        onPressed: widget.onPressed == null ? null : _run,
        isLoading: _busy,
        icon: widget.icon,
        variant: widget.variant,
        isFullWidth: widget.isFullWidth,
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        ),
    ],
  );
}
