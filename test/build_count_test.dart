import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

void main() {
  late List<int> built;

  Future<TabOverviewController<int>> pumpOverview(
    WidgetTester tester, {
    int tabCount = 6,
  }) async {
    built = [];
    final controller = TabOverviewController<int>(
      initialTabs: List.generate(tabCount, (tab) => tab),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TabOverview<int>.builder(
          controller: controller,
          tabBuilder: (context, tab) => Center(child: Text('T$tab')),
          tabThumbnailBuilder: (context, tab) {
            built.add(tab);
            return Center(child: Text('T$tab'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('expanding a tab rebuilds no other thumbnail', (tester) async {
    final controller = await pumpOverview(tester);

    built.clear();
    controller.expand(1);
    await tester.pumpAndSettle();

    expect(built.where((tab) => tab != 1), isEmpty);
  });

  testWidgets('collapsing a tab rebuilds only its thumbnail', (tester) async {
    final controller = await pumpOverview(tester);
    controller.expand(1);
    await tester.pumpAndSettle();

    built.clear();
    controller.collapse();
    await tester.pumpAndSettle();

    expect(built, isNotEmpty);
    expect(built.where((tab) => tab != 1), isEmpty);
  });

  testWidgets('an off-screen tab\'s expand and collapse rebuild no other '
      'thumbnail', (tester) async {
    final controller = await pumpOverview(tester, tabCount: 40);

    built.clear();
    controller.expand(38);
    await tester.pumpAndSettle();
    controller.collapse();
    await tester.pumpAndSettle();

    // Expanding scrolls the grid to tab 38's cell, which builds the cells
    // that come into view once.
    final rebuilt = <int>{};
    final seen = <int>{};
    for (final tab in built) {
      if (tab != 38 && !seen.add(tab)) rebuilt.add(tab);
    }
    expect(rebuilt, isEmpty);
  });

  testWidgets('a removal, then another tab\'s expand and collapse, shows '
      'the tabs left', (tester) async {
    // The grid keeps its items, and the count of tabs it was built with,
    // through mode changes.
    final controller = await pumpOverview(tester, tabCount: 4);

    controller.remove(1);
    await tester.pumpAndSettle();
    controller.expand(2);
    await tester.pumpAndSettle();
    controller.collapse();
    await tester.pumpAndSettle();

    expect(controller.tabs, [0, 2, 3]);
    expect(find.text('T1'), findsNothing);
    for (final tab in [0, 2, 3]) {
      expect(find.text('T$tab').hitTestable(), findsOneWidget);
    }
    expect(controller.isTransitioning, isFalse);

    controller.add(4);
    await tester.pumpAndSettle();
    controller.expand(4);
    await tester.pumpAndSettle();
    controller.collapse();
    await tester.pumpAndSettle();
    expect(find.text('T4').hitTestable(), findsOneWidget);
  });

  group('builds no other thumbnail', () {
    testWidgets('when a tab is removed', (tester) async {
      final controller = await pumpOverview(tester, tabCount: 9);

      built.clear();
      controller.remove(1);
      await tester.pumpAndSettle();

      expect(built.where((tab) => tab != 1), isEmpty);
    });

    testWidgets('when a tab is swiped away', (tester) async {
      final controller = await pumpOverview(tester, tabCount: 9);

      built.clear();
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('T1')),
      );
      for (var step = 0; step < 10; step++) {
        await gesture.moveBy(const Offset(-40, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.tabs, isNot(contains(1)));
      expect(built.where((tab) => tab != 1), isEmpty);
    });

    testWidgets('when a tab is dragged past others', (tester) async {
      final controller = await pumpOverview(tester, tabCount: 9);
      final from = tester.getCenter(find.text('T0'));
      final to = tester.getCenter(find.text('T2'));
      final gesture = await tester.startGesture(from);
      // Long enough to pick it up.
      await tester.pump(const Duration(milliseconds: 600));

      built.clear();
      for (var step = 1; step <= 10; step++) {
        await gesture.moveTo(Offset.lerp(from, to, step / 10)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.tabs.take(3), [1, 2, 0]);
      expect(built.where((tab) => tab != 0), isEmpty);
    });

    // A size of the overview's own brings a new grid delegate.
    for (final (width, columns) in [(820.0, 3), (1000.0, 4)]) {
      testWidgets('when the overview is resized to $columns columns', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(800, 600);
        addTearDown(tester.view.reset);
        await pumpOverview(tester, tabCount: 9);
        final builtBefore = built.toSet();

        built.clear();
        tester.view.physicalSize = Size(width, 600);
        await tester.pumpAndSettle();

        expect(built.where(builtBefore.contains), isEmpty);
      });
    }
  });
}
