import 'package:flutter/material.dart';

/// Geometry checks run at most once per frame, and notify only at visibility edges.
class ViewportActivity extends StatefulWidget {
  const ViewportActivity({
    super.key,
    required this.onChanged,
    required this.child,
  });
  final ValueChanged<bool> onChanged;
  final Widget child;
  @override
  State<ViewportActivity> createState() => _ViewportActivityState();
}

class _ViewportActivityState extends State<ViewportActivity> {
  final Set<ScrollPosition> _positions = {};
  bool? _visible;
  bool _scheduled = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final position in _positions) {
      position.removeListener(_schedule);
    }
    _positions.clear();
    context.visitAncestorElements((element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        final position = (element.state as ScrollableState).position;
        if (_positions.add(position)) position.addListener(_schedule);
      }
      return true;
    });
    _schedule();
  }

  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final bounds = box.localToGlobal(Offset.zero) & box.size;
      final viewport = Offset.zero & MediaQuery.sizeOf(context);
      final visible =
          bounds.width > 0 && bounds.height > 0 && bounds.overlaps(viewport);
      if (_visible != visible) {
        _visible = visible;
        widget.onChanged(visible);
      }
    });
  }

  @override
  void dispose() {
    for (final position in _positions) {
      position.removeListener(_schedule);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _schedule();
    return widget.child;
  }
}
