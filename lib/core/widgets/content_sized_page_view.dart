import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Measures the real page content, including large text, without nested vertical
/// scrolling or fixed-height clipping. Only PageView's visible pages are built.
class ContentSizedPageView extends StatefulWidget {
  const ContentSizedPageView({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    required this.onPageChanged,
  });
  final PageController controller;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int> onPageChanged;
  @override
  State<ContentSizedPageView> createState() => _ContentSizedPageViewState();
}

class _ContentSizedPageViewState extends State<ContentSizedPageView> {
  final _heights = <int, double>{};
  int _index = 0;
  @override
  void didUpdateWidget(covariant ContentSizedPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount != oldWidget.itemCount) {
      _heights.clear();
      _index = 0;
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _heights[_index] ?? 340,
    child: PageView.builder(
      controller: widget.controller,
      itemCount: widget.itemCount,
      onPageChanged: (index) {
        setState(() => _index = index);
        widget.onPageChanged(index);
      },
      itemBuilder: (context, index) => OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: 0,
        maxHeight: double.infinity,
        child: _Measure(
          onSize: (size) {
            if (mounted && (_heights[index] ?? 0) != size.height) {
              setState(() => _heights[index] = size.height);
            }
          },
          child: widget.itemBuilder(context, index),
        ),
      ),
    ),
  );
}

class _Measure extends SingleChildRenderObjectWidget {
  const _Measure({required this.onSize, required super.child});
  final ValueChanged<Size> onSize;
  @override
  RenderObject createRenderObject(BuildContext context) => _MeasureBox(onSize);
  @override
  void updateRenderObject(
    BuildContext context,
    covariant _MeasureBox renderObject,
  ) => renderObject.onSize = onSize;
}

class _MeasureBox extends RenderProxyBox {
  _MeasureBox(this.onSize);
  ValueChanged<Size> onSize;
  Size? _last;
  @override
  void performLayout() {
    super.performLayout();
    if (size != _last) {
      _last = size;
      final measured = size;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (attached) onSize(measured);
      });
    }
  }
}
