import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

Future<TabOverviewController<int>> pumpOverview(
  WidgetTester tester, {
  int tabCount = 4,
  bool Function(int tab)? isTabRemovable,
  bool Function(int tab)? isTabReorderable,
}) async {
  final controller = TabOverviewController<int>(
    initialTabs: List.generate(tabCount, (tab) => tab),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Column(
        children: [
          // Rebuilds with the controller, as a ChangeNotifier.
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => Text(
              'state ${controller.tabs.length} '
              '${controller.mode.name} ${controller.activeTab}',
            ),
          ),
          Expanded(
            child: TabOverview<int>.builder(
              controller: controller,
              isTabRemovable: isTabRemovable,
              isTabReorderable: isTabReorderable,
              tabBuilder: (context, tab) => ColoredBox(
                color: Colors.white,
                child: Center(child: Text('T$tab')),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

// Drags tab 3's thumbnail over tab 2's, after holding it long enough to pick
// it up.
Future<void> dragThumbnail3Over2(WidgetTester tester) async {
  final from = tester.getCenter(find.text('T3'));
  final to = tester.getCenter(find.text('T2'));
  final gesture = await tester.startGesture(from);
  await tester.pump(const Duration(milliseconds: 600));
  for (var step = 1; step <= 10; step++) {
    await gesture.moveTo(Offset.lerp(from, to, step / 10)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  group('the controller as a ChangeNotifier', () {
    testWidgets('tells its listeners of tabs added and removed, the mode and '
        'the active tab', (tester) async {
      final controller = await pumpOverview(tester);
      expect(find.text('state 4 overview 0'), findsOneWidget);

      controller.add(4);
      await tester.pump();
      expect(find.text('state 5 overview 0'), findsOneWidget);

      controller.expand(2);
      await tester.pump();
      expect(find.text('state 5 expanded 2'), findsOneWidget);
      await tester.pumpAndSettle();

      controller.remove(2);
      await tester.pump();
      expect(find.text('state 4 overview 3'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('tells its listeners once per change of the mode', (
      tester,
    ) async {
      final controller = await pumpOverview(tester);
      var notices = 0;
      controller.addListener(() => notices++);

      controller.collapse();
      expect(notices, 0, reason: 'already in the overview');

      controller.toggleMode();
      expect(notices, 1);
      await tester.pumpAndSettle();
    });

    // An off-screen tab's expand switches to its page a frame later, which
    // may come after the app disposed the controller with its overview.
    testWidgets('disposes with an off-screen expand still waiting', (
      tester,
    ) async {
      final controller = await pumpOverview(tester, tabCount: 40);

      controller.expand(38);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('isTabRemovable', () {
    testWidgets('leaves a remove button off a tab it rules out', (
      tester,
    ) async {
      final controller = await pumpOverview(
        tester,
        isTabRemovable: (tab) => tab != 2,
      );
      expect(find.byIcon(Icons.close), findsNWidgets(3));

      controller.expand(2);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(PageView),
          matching: find.byIcon(Icons.close),
        ),
        findsNothing,
      );
    });

    testWidgets('keeps a tab it rules out from being swiped away', (
      tester,
    ) async {
      final controller = await pumpOverview(
        tester,
        isTabRemovable: (tab) => tab != 2,
      );

      await tester.fling(find.text('T2'), const Offset(-400, 0), 2000);
      await tester.pumpAndSettle();
      expect(controller.tabs, [0, 1, 2, 3]);

      await tester.fling(find.text('T1'), const Offset(-400, 0), 2000);
      await tester.pumpAndSettle();
      expect(controller.tabs, [0, 2, 3]);
    });
  });

  group('isTabReorderable', () {
    testWidgets('lets every tab move when not given', (tester) async {
      final controller = await pumpOverview(tester);

      await dragThumbnail3Over2(tester);

      expect(controller.tabs, [0, 1, 3, 2]);
    });

    testWidgets('keeps a tab it rules out in its place', (tester) async {
      final controller = await pumpOverview(
        tester,
        isTabReorderable: (tab) => tab != 3,
      );

      await dragThumbnail3Over2(tester);

      expect(controller.tabs, [0, 1, 2, 3]);
    });
  });
}
