import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/guest_auth_guard.dart';
import '../auth/token_storage.dart';
import 'patient_analytics.dart';

/// A clinic_view is a publicly verified profile visible on the current route
/// for500ms. Card builds, carousel preloads and covered/offstage routes do not
/// establish a profile view. Session deduplication is owned by PatientAnalytics.
class PatientClinicExposure extends StatefulWidget {
  const PatientClinicExposure({
    super.key,
    required this.clinicId,
    required this.publicDetailVerified,
    required this.child,
    this.analytics,
  });
  final String clinicId;
  final bool publicDetailVerified;
  final Widget child;
  final PatientAnalytics? analytics;
  @override
  State<PatientClinicExposure> createState() => _PatientClinicExposureState();
}

class _PatientClinicExposureState extends State<PatientClinicExposure>
    with WidgetsBindingObserver {
  Timer? _dwell;
  ModalRoute<dynamic>? _route;
  String? _observedScope;
  bool _scheduled = false, _tickerEnabled = false;
  PatientAnalytics get _analytics =>
      widget.analytics ?? PatientAnalytics.instance;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthState().addListener(_identityChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route?.animation?.removeStatusListener(_routeChanged);
    _route = ModalRoute.of(context);
    _route?.animation?.addStatusListener(_routeChanged);
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    _schedule();
  }

  void _identityChanged() {
    _dwell?.cancel();
    _dwell = null;
    _schedule();
  }

  void _routeChanged(AnimationStatus _) => _schedule();
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _dwell?.cancel();
    _dwell = null;
    _schedule();
  }

  bool get _visible {
    final foreground = WidgetsBinding.instance.lifecycleState;
    if (!mounted ||
        !_tickerEnabled ||
        !widget.publicDetailVerified ||
        _route?.isCurrent != true ||
        (foreground != null && foreground != AppLifecycleState.resumed) ||
        (_route?.animation != null &&
            _route!.animation!.status != AnimationStatus.completed)) {
      return false;
    }
    var hidden = false;
    context.visitAncestorElements((element) {
      if (element.widget is Offstage && (element.widget as Offstage).offstage) {
        hidden = true;
      }
      return !hidden;
    });
    if (hidden) return false;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || box.size.isEmpty) return false;
    final bounds = box.localToGlobal(Offset.zero) & box.size;
    final overlap = bounds.intersect(Offset.zero & MediaQuery.sizeOf(context));
    return !overlap.isEmpty &&
        overlap.width * overlap.height >= bounds.width * bounds.height * 0.5;
  }

  void _schedule() {
    if (!mounted || _scheduled || !_analytics.enabled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final scope =
          '${AuthState().sessionEpoch}:${TokenStorage().sessionEpoch}:${widget.clinicId}';
      if (!_analytics.canRecord || _observedScope == scope || !_visible) {
        _dwell?.cancel();
        _dwell = null;
        return;
      }
      _dwell ??= Timer(const Duration(milliseconds: 500), () {
        _dwell = null;
        if (_analytics.canRecord &&
            _visible &&
            scope ==
                '${AuthState().sessionEpoch}:${TokenStorage().sessionEpoch}:${widget.clinicId}') {
          _analytics.clinicViewed(PatientAttribution(widget.clinicId));
          _observedScope = scope;
        }
      });
    });
    // Auth/lifecycle notifications can arrive with no frame scheduled. A
    // post-frame callback alone would leave the fresh dwell gate stranded.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _dwell?.cancel();
    _route?.animation?.removeStatusListener(_routeChanged);
    AuthState().removeListener(_identityChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _schedule();
    return widget.child;
  }
}
