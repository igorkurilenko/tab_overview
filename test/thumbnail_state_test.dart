import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

class Content extends StatefulWidget {
  const Content(this.tab, {super.key});

  final int tab;

  @override
  State<Content> createState() => _ContentState();
}

class _ContentState extends State<Content> {
  @override
  Widget build(BuildContext context) => Center(child: Text('T${widget.tab}'));
}

void main() {
  group('an added tab keeps its state when the overview rebuilds', () {
    late StateSetter rebuildParent;

    Future<TabOverviewController<int>> pumpOverview(WidgetTester tester) async {
      final controller = TabOverviewController<int>(initialTabs: [0, 1]);
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuildParent = setState;
              return TabOverview<int>.builder(
                controller: controller,
                tabBuilder: (context, tab) => Content(tab),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      return controller;
    }

    State content(WidgetTester tester, int tab, {Finder? within}) {
      final finder = find.byWidgetPredicate(
        (w) => w is Content && w.tab == tab,
      );
      return tester.state(
        within == null ? finder : find.descendant(of: within, matching: finder),
      );
    }

    testWidgets('in its thumbnail', (tester) async {
      final controller = await pumpOverview(tester);
      controller.add(2);
      await tester.pumpAndSettle();
      final before = content(tester, 2);

      rebuildParent(() {});
      await tester.pumpAndSettle();

      expect(content(tester, 2), same(before));
    });

    testWidgets('when expanded right away', (tester) async {
      final controller = await pumpOverview(tester);
      controller.expand(0);
      await tester.pumpAndSettle();
      controller.add(2);
      controller.expand(2);
      await tester.pumpAndSettle();
      final pages = find.byType(PageView);
      final before = content(tester, 2, within: pages);

      rebuildParent(() {});
      await tester.pumpAndSettle();

      expect(content(tester, 2, within: pages), same(before));
    });
  });
}
