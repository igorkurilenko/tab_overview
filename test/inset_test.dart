import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

Finder content(int tab) => find.byKey(ValueKey('content$tab'));

Future<TabOverviewController<int>> pumpBesideSidebar(
  WidgetTester tester, {
  int tabCount = 3,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 800);
  addTearDown(tester.view.reset);
  final controller = TabOverviewController<int>(
    initialTabs: List.generate(tabCount, (i) => i),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('App')),
        body: Row(
          children: [
            const SizedBox(width: 200),
            Expanded(
              child: TabOverview<int>.builder(
                controller: controller,
                tabBuilder: (context, tab) => ColoredBox(
                  key: ValueKey('content$tab'),
                  color: Colors.white,
                  child: Center(child: Text('T$tab')),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  group('when the overview is beside a sidebar and under an app bar', () {
    testWidgets('an expanded tab fills the overview', (tester) async {
      final controller = await pumpBesideSidebar(tester);
      final overview = tester.getRect(find.byType(TabOverview<int>));

      controller.expand(1);
      await tester.pumpAndSettle();

      final expanded = find.descendant(
        of: find.byType(PageView),
        matching: content(1),
      );
      expect(tester.getSize(expanded), overview.size);
      expect(tester.getRect(expanded), overview);
    });

    testWidgets('an off-screen tab flies in from the overview\'s bottom', (
      tester,
    ) async {
      final controller = await pumpBesideSidebar(tester, tabCount: 40);
      final overview = tester.getRect(find.byType(TabOverview<int>));
      expect(content(38), findsNothing);

      controller.expand(38);
      Rect? start;
      for (var frame = 0; start == null && frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        start = content(38)
            .evaluate()
            // The page the tab lands on is laid out, hidden, from the frame
            // of the switch, before the flight starts.
            .where((e) => e.findAncestorWidgetOfExactType<PageView>() == null)
            .map((element) => tester.getRect(find.byWidget(element.widget)))
            .where((rect) => rect.isFinite && !rect.isEmpty)
            .firstOrNull;
      }
      await tester.pumpAndSettle();

      expect(start, isNotNull);
      expect((start!.center - overview.bottomCenter).distance, lessThan(10));
    });
  });
}
