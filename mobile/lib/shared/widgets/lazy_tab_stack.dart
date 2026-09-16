import 'package:flutter/widgets.dart';

/// Tab bodies built on first visit and kept alive afterwards.
///
/// Only the tab at [index] is on screen. Hidden tabs keep their state but are
/// left out of the accessibility tree and have their tickers stopped (F-62):
/// an `IndexedStack` on its own keeps hidden tabs' tickers running, so a
/// hidden Mine hero kept animating and a screen reader could still land on it.
class LazyTabStack extends StatefulWidget {
  const LazyTabStack({
    super.key,
    required this.index,
    required this.builders,
  });

  final int index;
  final List<WidgetBuilder> builders;

  @override
  State<LazyTabStack> createState() => _LazyTabStackState();
}

class _LazyTabStackState extends State<LazyTabStack> {
  late final List<Widget?> _builtChildren =
      List<Widget?>.filled(widget.builders.length, null, growable: true);

  @override
  void didUpdateWidget(covariant LazyTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.builders.length != widget.builders.length) {
      _builtChildren
        ..clear()
        ..addAll(List<Widget?>.filled(widget.builders.length, null));
    }
  }

  @override
  Widget build(BuildContext context) {
    _builtChildren[widget.index] ??= widget.builders[widget.index](context);

    return IndexedStack(
      index: widget.index,
      children: List<Widget>.generate(widget.builders.length, (index) {
        final active = index == widget.index;
        return TickerMode(
          enabled: active,
          child: ExcludeSemantics(
            excluding: !active,
            child: _builtChildren[index] ?? const SizedBox.shrink(),
          ),
        );
      }),
    );
  }
}
