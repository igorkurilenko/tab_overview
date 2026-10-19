import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

// The overview, at 800 by 600, with [tabCount] tabs.
Future<TabOverviewController<int>> pumpOverview(
  WidgetTester tester, {
  int tabCount = 4,
  TabTransition? addRemoveTransition,
  TabTransition? scrollTransition,
}) async {
  final controller = TabOverviewController<int>(
    initialTabs: List.generate(tabCount, (tab) => tab),
    addRemoveTransition:
        addRemoveTransition ??
        const TabTransition(
          duration: Duration(milliseconds: 350),
          curve: Curves.linear,
        ),
    scrollTransition:
        scrollTransition ??
        const TabTransition(duration: Duration(milliseconds: 350)),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: TabOverview<int>.builder(
        controller: controller,
        tabBuilder: (context, tab) => ColoredBox(
          color: Colors.white,
          child: Center(child: Text('T$tab')),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

// How far the tab's thumbnail is scaled in, by its add or remove animation.
double thumbScale(WidgetTester tester, int tab) => tester
    .widget<ScaleTransition>(
      find
          .ancestor(
            of: find.text('T$tab'),
            matching: find.byType(ScaleTransition),
          )
          .first,
    )
    .scale
    .value;

ScrollPosition gridPosition(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first).position;

void main() {
  test('adds and removes over 350 ms, linearly, and scrolls over 350 ms '
      'along easeInOut, by default', () {
    final controller = TabOverviewController<int>();
    addTearDown(controller.dispose);

    expect(
      controller.addRemoveTransition,
      const TabTransition(
        duration: Duration(milliseconds: 350),
        curve: Curves.linear,
      ),
    );
    expect(
      controller.scrollTransition,
      const TabTransition(
        duration: Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      ),
    );
  });

  testWidgets('a tab added scales in over the controller\'s add and remove '
      'transition', (tester) async {
    final controller = await pumpOverview(
      tester,
      addRemoveTransition: const TabTransition(
        duration: Duration(seconds: 1),
        curve: Curves.linear,
      ),
    );

    controller.add(4);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(thumbScale(tester, 4), moreOrLessEquals(0.5, epsilon: 0.05));

    await tester.pump(const Duration(milliseconds: 520));
    expect(thumbScale(tester, 4), 1);
  });

  testWidgets('a tab removed scales out over the controller\'s add and '
      'remove transition', (tester) async {
    final controller = await pumpOverview(
      tester,
      addRemoveTransition: const TabTransition(
        duration: Duration(seconds: 1),
        curve: Curves.linear,
      ),
    );

    controller.remove(3);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(thumbScale(tester, 3), moreOrLessEquals(0.5, epsilon: 0.05));

    await tester.pumpAndSettle();
    expect(find.text('T3'), findsNothing);
  });

  testWidgets('an add follows its transition\'s curve', (tester) async {
    final controller = await pumpOverview(tester);

    controller.add(4, curve: Curves.easeIn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 175));

    // Half way along easeIn, where linear would be at 0.5.
    expect(thumbScale(tester, 4), lessThan(0.4));
  });

  testWidgets('a call\'s own duration wins over the controller\'s', (
    tester,
  ) async {
    final controller = await pumpOverview(
      tester,
      addRemoveTransition: const TabTransition(
        duration: Duration(seconds: 1),
        curve: Curves.linear,
      ),
    );

    controller.add(4, duration: const Duration(milliseconds: 100));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(thumbScale(tester, 4), 1);
  });

  testWidgets('scrolling to a tab follows the controller\'s scroll '
      'transition', (tester) async {
    final controller = await pumpOverview(
      tester,
      tabCount: 30,
      scrollTransition: const TabTransition(duration: Duration(seconds: 1)),
    );
    final position = gridPosition(tester);

    controller.scrollToTab(29);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(position.pixels, greaterThan(0));
    expect(position.pixels, lessThan(position.maxScrollExtent));

    await tester.pumpAndSettle();
    expect(position.pixels, position.maxScrollExtent);
  });

  testWidgets('a scroll\'s own duration wins over the controller\'s', (
    tester,
  ) async {
    final controller = await pumpOverview(
      tester,
      tabCount: 30,
      scrollTransition: const TabTransition(duration: Duration(seconds: 1)),
    );
    final position = gridPosition(tester);

    controller.scrollToTab(29, duration: const Duration(milliseconds: 100));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(position.pixels, position.maxScrollExtent);
  });
}
