import 'package:flutter/material.dart';

/// Visibility is independent of mounting: visited tabs keep state while hidden.
class TabActivity extends InheritedWidget {
  const TabActivity({super.key, required this.active, required super.child});
  final bool active;
  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabActivity>()?.active ?? true;
  @override
  bool updateShouldNotify(TabActivity oldWidget) => active != oldWidget.active;
}

class LazyTabStack extends StatefulWidget {
  const LazyTabStack({super.key, required this.index, required this.builders});
  final int index;
  final List<WidgetBuilder> builders;
  @override
  State<LazyTabStack> createState() => _LazyTabStackState();
}

class _LazyTabStackState extends State<LazyTabStack> {
  final Set<int> _visitedTabs = {};
  @override
  Widget build(BuildContext context) {
    _visitedTabs.add(widget.index);
    return IndexedStack(
      index: widget.index,
      children: List.generate(
        widget.builders.length,
        (index) => _visitedTabs.contains(index)
            ? TabActivity(
                active: index == widget.index,
                child: TickerMode(
                  enabled: index == widget.index,
                  child: KeyedSubtree(
                    key: ValueKey(index),
                    child: Builder(builder: widget.builders[index]),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
