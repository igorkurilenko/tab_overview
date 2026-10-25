import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

import 'support.dart';

// The overview, at 800 by 600, with tab 1 of 4 expanded. Each tab's remove
// button is keyed by its tab.
Future<TabOverviewController<int>> pumpExpanded(WidgetTester tester) async {
  final controller = TabOverviewController<int>(initialTabs: [0, 1, 2, 3]);
  await tester.pumpWidget(
    MaterialApp(
      home: TabOverview<int>.builder(
        controller: controller,
        pullToCollapse: true,
        removeTabButtonBuilder: (context, tab) => RemoveTabButton(
          key: ValueKey('remove $tab'),
          onPressed: () => controller.remove(tab),
        ),
        tabBuilder: (context, tab) => ColoredBox(
          color: Colors.white,
          child: Center(child: Text('T$tab')),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  controller.expand(1);
  await tester.pumpAndSettle();
  return controller;
}

// How far tab 1's remove button icon is from its tab's top right corner,
// wherever each shows: on the page, on the thumbnail, or flying.
Iterable<Offset> buttonOffsets(WidgetTester tester) {
  final tab = rectsOf(
    tester,
    find.ancestor(of: find.text('T1'), matching: find.byType(FittedTab)),
  ).single;
  return rectsOf(
    tester,
    find.descendant(
      of: find.byKey(const ValueKey('remove 1')),
      matching: find.byType(Icon),
    ),
  ).map((icon) => Offset(tab.right - icon.right, icon.top - tab.top));
}

// Pumps the frames of a collapse under way, expecting the button to keep
// to its tab's corner on each.
Future<void> expectButtonInStep(
  WidgetTester tester,
  TabOverviewController<int> controller,
) async {
  final atRest = buttonOffsets(tester).toSet().single;
  final frames = await pumpFlight(tester, controller, () {
    for (final offset in buttonOffsets(tester)) {
      expect(offset.dx, moreOrLessEquals(atRest.dx, epsilon: 0.5));
      expect(offset.dy, moreOrLessEquals(atRest.dy, epsilon: 0.5));
    }
  });
  expect(frames.length, greaterThan(5));
  expect(controller.mode, TabOverviewMode.overview);
}

void main() {
  testWidgets('the remove button keeps to its tab as the tab collapses', (
    tester,
  ) async {
    final controller = await pumpExpanded(tester);

    controller.collapse();
    await expectButtonInStep(tester, controller);
  });

  testWidgets('the remove button keeps to its tab over a collapse of its own '
      'duration', (tester) async {
    final controller = await pumpExpanded(tester);

    controller.collapse(duration: const Duration(seconds: 1));
    await expectButtonInStep(tester, controller);
  });

  testWidgets('the remove button keeps to its tab as a pulled tab is flung '
      'to its thumbnail', (tester) async {
    final controller = await pumpExpanded(tester);
    final page = find
        .descendant(of: find.byType(PageView), matching: find.byType(FittedTab))
        .first;
    await pullDown(tester, tester.getCenter(page), [20, 8, 8, 8, 8, 8, 8]);
    await expectButtonInStep(tester, controller);
  });
}
