import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

// The overview, at 800 by 600, of tabs 0 to 3, whose adds and removes take
// a second, linearly.
Future<TabOverviewController<int>> pumpOverview(
  WidgetTester tester, {
  List<int> tabs = const [0, 1, 2, 3],
}) async {
  final controller = TabOverviewController<int>(
    initialTabs: tabs,
    addRemoveTransition: const TabTransition(
      duration: Duration(seconds: 1),
      curve: Curves.linear,
    ),
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

// How far the tab's thumbnail is scaled in, by its add animation.
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

// The page the expanded view shows of [tab].
Finder shown(int tab) => find
    .descendant(of: find.byType(PageView), matching: find.text('T$tab'))
    .hitTestable();

void main() {
  for (final (index, tabs) in [
    (0, [9, 0, 1, 2, 3]),
    (2, [0, 1, 9, 2, 3]),
    (4, [0, 1, 2, 3, 9]),
  ]) {
    testWidgets('inserts a tab at $index, which scales in', (tester) async {
      final controller = await pumpOverview(tester);

      expect(controller.insert(index, 9), isTrue);
      expect(controller.tabs, tabs);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(thumbScale(tester, 9), moreOrLessEquals(.5, epsilon: .05));

      await tester.pumpAndSettle();
      expect(thumbScale(tester, 9), 1);
      // In its place in the grid, which lays tabs out in rows.
      final centers = {
        for (final tab in tabs) tab: tester.getCenter(find.text('T$tab')),
      };
      final byPlace = [...tabs]
        ..sort((a, b) {
          final (ca, cb) = (centers[a]!, centers[b]!);
          return (ca.dy - cb.dy).abs() > 1
              ? ca.dy.compareTo(cb.dy)
              : ca.dx.compareTo(cb.dx);
        });
      expect(byPlace, tabs);
    });
  }

  testWidgets('returns false for a tab already there, and does nothing', (
    tester,
  ) async {
    final controller = await pumpOverview(tester);
    final added = <int>[];
    controller.addTabAddedListener(added.add);

    expect(controller.insert(0, 2), isFalse);

    expect(controller.tabs, [0, 1, 2, 3]);
    expect(added, isEmpty);
  });

  testWidgets('throws a RangeError for an index out of range', (tester) async {
    final controller = await pumpOverview(tester);

    expect(() => controller.insert(-1, 9), throwsRangeError);
    expect(() => controller.insert(5, 9), throwsRangeError);
    expect(controller.tabs, [0, 1, 2, 3]);
  });

  testWidgets('tells its listeners, and makes the tab active if none was', (
    tester,
  ) async {
    final controller = await pumpOverview(tester, tabs: const []);
    final added = <int>[];
    controller.addTabAddedListener(added.add);

    controller.insert(0, 9);

    expect(added, [9]);
    expect(controller.activeTab, 9);
  });

  for (final index in [0, 4]) {
    testWidgets('keeps an expanded tab on screen as a tab is inserted at '
        '$index', (tester) async {
      final controller = await pumpOverview(tester);
      controller.expand(2);
      await tester.pumpAndSettle();

      controller.insert(index, 9);
      await tester.pumpAndSettle();

      expect(controller.activeTab, 2);
      expect(shown(2), findsOneWidget);

      // The page before it is the tab before it now.
      await tester.timedDrag(
        find.byType(PageView),
        const Offset(500, 0),
        const Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();
      expect(controller.activeTab, 1);
      expect(shown(1), findsOneWidget);
    });
  }

  for (final collapsing in [false, true]) {
    testWidgets('a tab inserted before one that '
        '${collapsing ? 'collapses' : 'expands'} lets it land', (tester) async {
      final controller = await pumpOverview(tester);
      if (collapsing) {
        controller.expand(2);
        await tester.pumpAndSettle();
        controller.collapse();
      } else {
        controller.expand(2);
      }
      for (var frame = 0; frame < 5; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      controller.insert(0, 9);
      await tester.pumpAndSettle();

      expect(controller.isTransitioning, isFalse);
      expect(controller.activeTab, 2);
      if (collapsing) {
        expect(controller.mode, TabOverviewMode.overview);
        expect(find.text('T2').hitTestable(), findsOneWidget);
      } else {
        expect(controller.mode, TabOverviewMode.expanded);
        expect(shown(2), findsOneWidget);
      }
    });
  }
}
