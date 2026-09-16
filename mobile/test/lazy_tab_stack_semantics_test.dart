import 'package:blocnet/shared/widgets/lazy_tab_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tab that reports whether its tickers are enabled.
class _Tab extends StatelessWidget {
  const _Tab(this.name, this.tickers);

  final String name;
  final Map<String, bool> tickers;

  @override
  Widget build(BuildContext context) {
    tickers[name] = TickerMode.of(context);
    return Column(
      children: [
        Text('$name body'),
        ElevatedButton(onPressed: () {}, child: Text('$name action')),
      ],
    );
  }
}

/// Keeps a counter to prove a hidden tab keeps its state.
class _CounterTab extends StatefulWidget {
  const _CounterTab();

  @override
  State<_CounterTab> createState() => _CounterTabState();
}

class _CounterTabState extends State<_CounterTab> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() => count++),
      child: Text('Mine count $count'),
    );
  }
}

void main() {
  final tickers = <String, bool>{};

  Widget host(int index) {
    return MaterialApp(
      home: Scaffold(
        body: LazyTabStack(
          index: index,
          builders: [
            (_) => const _CounterTab(),
            (_) => _Tab('Profile', tickers),
          ],
        ),
      ),
    );
  }

  testWidgets('hidden tabs have no semantics nodes and keep their state',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(host(0));
    await tester.tap(find.text('Mine count 0'));
    await tester.pump();
    expect(find.bySemanticsLabel('Mine count 1'), findsOneWidget);

    await tester.pumpWidget(host(1));
    expect(find.bySemanticsLabel('Profile body'), findsOneWidget);
    expect(find.bySemanticsLabel('Profile action'), findsOneWidget);
    // Still mounted, so still in the widget tree...
    expect(find.text('Mine count 1', skipOffstage: false), findsOneWidget);
    // ...but not in the accessibility tree.
    expect(find.bySemanticsLabel(RegExp('Mine count')), findsNothing);

    await tester.pumpWidget(host(0));
    expect(find.bySemanticsLabel('Mine count 1'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Profile')), findsNothing);

    semantics.dispose();
  });

  testWidgets('only the active tab has tickers enabled', (tester) async {
    tickers.clear();
    await tester.pumpWidget(host(1));
    expect(tickers['Profile'], isTrue);

    await tester.pumpWidget(host(0));
    expect(tickers['Profile'], isFalse);
  });
}
