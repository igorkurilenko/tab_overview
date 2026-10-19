import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

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

Iterable<Rect> rectsOf(WidgetTester tester, Finder finder) => tester
    .renderObjectList<RenderBox>(finder)
    .map((box) => box.localToGlobal(Offset.zero) & box.size)
    .where((rect) => rect.top.isFinite);

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
  // The frame of the switch, before the flights start.
  await tester.pump();
  var frames = 0;
  while (controller.isTransitioning) {
    await tester.pump(const Duration(milliseconds: 16));
    for (final offset in buttonOffsets(tester)) {
      expect(offset.dx, moreOrLessEquals(atRest.dx, epsilon: 0.5));
      expect(offset.dy, moreOrLessEquals(atRest.dy, epsilon: 0.5));
    }
    frames++;
  }
  expect(frames, greaterThan(5));
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
    final gesture = await tester.startGesture(tester.getCenter(page));
    var time = Duration.zero;
    Future<void> move(double dy) async {
      time += const Duration(milliseconds: 16);
      await gesture.moveBy(Offset(0, dy), timeStamp: time);
      await tester.pump(const Duration(milliseconds: 16));
    }

    await move(20);
    for (var step = 0; step < 6; step++) {
      await move(8);
    }

    await gesture.up(timeStamp: time);
    await expectButtonInStep(tester, controller);
  });
}
