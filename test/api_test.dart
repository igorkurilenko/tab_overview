import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

Future<TabOverviewController<int>> pumpOverview(
  WidgetTester tester, {
  int tabCount = 4,
  bool Function(int tab)? isTabRemovable,
  bool Function(int tab)? isTabReorderable,
  Widget Function(BuildContext context, int tab)? removeTabButtonBuilder,
  TabTransition? transition,
}) async {
  final tabs = List.generate(tabCount, (tab) => tab);
  final controller = transition == null
      ? TabOverviewController<int>(initialTabs: tabs)
      : TabOverviewController<int>(initialTabs: tabs, transition: transition);
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
              removeTabButtonBuilder: removeTabButtonBuilder,
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
  group('remove', () {
    testWidgets('returns false, and does nothing, for a tab that isn\'t '
        'there', (tester) async {
      final controller = await pumpOverview(tester);

      expect(controller.remove(9), isFalse);
      await tester.pumpAndSettle();

      expect(controller.tabs, [0, 1, 2, 3]);
    });

    testWidgets('returns true for a tab it removes', (tester) async {
      final controller = await pumpOverview(tester);

      expect(controller.remove(1), isTrue);
      await tester.pumpAndSettle();

      expect(controller.tabs, [0, 2, 3]);
    });
  });

  testWidgets('removeAt removes the tab at an index and returns it', (
    tester,
  ) async {
    final controller = await pumpOverview(tester);

    expect(controller.removeAt(2), 2);
    await tester.pumpAndSettle();

    expect(controller.tabs, [0, 1, 3]);
  });

  group('a tab or an index that isn\'t there', () {
    testWidgets('throws an ArgumentError from a method that takes a tab', (
      tester,
    ) async {
      final controller = await pumpOverview(tester);

      expect(() => controller.expand(9), throwsArgumentError);
      expect(() => controller.scrollToTab(9), throwsArgumentError);
      expect(() => controller.activeTab = 9, throwsArgumentError);
    });

    testWidgets('throws a RangeError from a method that takes an index', (
      tester,
    ) async {
      final controller = await pumpOverview(tester);

      expect(() => controller.expandAt(9), throwsRangeError);
      expect(() => controller.scrollToTabAt(9), throwsRangeError);
      expect(() => controller.removeAt(9), throwsRangeError);
      expect(() => controller.isTabExpandedAt(9), throwsRangeError);
      expect(controller.tabs, [0, 1, 2, 3]);
    });

    testWidgets('answers false from a question', (tester) async {
      final controller = await pumpOverview(tester);

      expect(controller.isActiveTab(9), isFalse);
      expect(controller.isTabExpanded(9), isFalse);
    });
  });

  group('the constructor', () {
    test('takes an empty list of tabs, with no tab active', () {
      final controller = TabOverviewController<int>(initialTabs: []);

      expect(controller.tabs, isEmpty);
      expect(controller.activeTab, isNull);
    });

    test('makes the first tab active, unless told another', () {
      expect(TabOverviewController<int>(initialTabs: [0, 1]).activeTab, 0);
      expect(
        TabOverviewController<int>(initialTabs: [0, 1], activeTab: 1).activeTab,
        1,
      );
    });

    test('refuses an active tab that isn\'t among its tabs, as the '
        'activeTab setter does', () {
      expect(
        () => TabOverviewController<int>(initialTabs: [0, 1], activeTab: 9),
        throwsArgumentError,
      );
    });
  });

  group('activeIndex', () {
    testWidgets('is the active tab\'s index in tabs', (tester) async {
      final controller = await pumpOverview(tester);
      expect(controller.activeIndex, 0);

      controller.expand(2);
      await tester.pumpAndSettle();
      expect(controller.activeIndex, 2);

      controller.remove(0);
      await tester.pumpAndSettle();
      expect(controller.activeIndex, 1);
    });

    testWidgets('is null with no tab active', (tester) async {
      final controller = TabOverviewController<int>();

      expect(controller.activeIndex, isNull);
    });

    testWidgets('can\'t be of a tab that isn\'t in the overview, as the '
        'activeTab setter refuses one', (tester) async {
      final controller = TabOverviewController<int>(initialTabs: [0, 1, 2]);

      expect(() => controller.activeTab = 42, throwsArgumentError);

      expect(controller.activeTab, 0);
      expect(controller.activeIndex, 0);
    });
  });

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

  // An app may call the controller from its own initState, before the
  // overview is first built. These threw on a null check.
  group('before the overview is built', () {
    Future<void> pumpLater(
      WidgetTester tester,
      TabOverviewController<int> controller,
    ) async {
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
    }

    Finder page(int tab) => find
        .descendant(of: find.byType(PageView), matching: find.text('T$tab'))
        .hitTestable();

    testWidgets('expand shows the tab\'s page once it is', (tester) async {
      final controller = TabOverviewController<int>(initialTabs: [0, 1, 2]);

      controller.expand(2);
      await pumpLater(tester, controller);

      expect(controller.mode, TabOverviewMode.expanded);
      expect(controller.activeTab, 2);
      expect(page(2), findsOneWidget);
      expect(controller.isTransitioning, isFalse);
    });

    testWidgets('toggleMode expands the active tab', (tester) async {
      final controller = TabOverviewController<int>(initialTabs: [0, 1, 2]);

      controller.toggleMode();
      await pumpLater(tester, controller);

      expect(controller.mode, TabOverviewMode.expanded);
      expect(page(0), findsOneWidget);
    });

    testWidgets('collapse takes an expand back', (tester) async {
      final controller = TabOverviewController<int>(initialTabs: [0, 1, 2]);

      controller.expand(2);
      controller.collapse();
      await pumpLater(tester, controller);

      expect(controller.mode, TabOverviewMode.overview);
      expect(controller.activeTab, 2);
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('scrollToTab does nothing in the overview, with no grid to '
        'scroll', (tester) async {
      final controller = TabOverviewController<int>(initialTabs: [0, 1, 2]);

      controller.scrollToTab(2);
      await pumpLater(tester, controller);

      expect(controller.mode, TabOverviewMode.overview);
      expect(controller.activeTab, 0);
    });

    testWidgets('scrollToTab shows the tab\'s page when expanded', (
      tester,
    ) async {
      final controller = TabOverviewController<int>(
        initialTabs: [0, 1, 2],
        initialMode: TabOverviewMode.expanded,
      );

      controller.scrollToTab(2);
      await pumpLater(tester, controller);

      expect(controller.activeTab, 2);
      expect(page(2), findsOneWidget);
    });
  });

  group('transition', () {
    // How long a tab flies to its page, to the frame.
    Future<int> framesToExpand(
      WidgetTester tester,
      void Function() expand,
    ) async {
      expand();
      var frames = 0;
      do {
        await tester.pump(const Duration(milliseconds: 20));
        frames++;
      } while (frames < 200 &&
          !find
              .descendant(of: find.byType(PageView), matching: find.text('T1'))
              .hitTestable()
              .evaluate()
              .isNotEmpty);
      await tester.pumpAndSettle();
      return frames;
    }

    testWidgets('is 300 ms by default', (tester) async {
      final controller = await pumpOverview(tester);
      expect(
        controller.transition,
        const TabTransition(duration: Duration(milliseconds: 300)),
      );

      final frames = await framesToExpand(tester, () => controller.expand(1));

      expect(frames * 20, inInclusiveRange(300, 360));
    });

    testWidgets('times every expand the controller isn\'t told otherwise', (
      tester,
    ) async {
      final controller = await pumpOverview(
        tester,
        transition: const TabTransition(duration: Duration(seconds: 1)),
      );

      final frames = await framesToExpand(tester, () => controller.expand(1));

      expect(frames * 20, inInclusiveRange(1000, 1060));
    });

    testWidgets('gives way to a call\'s own duration', (tester) async {
      final controller = await pumpOverview(
        tester,
        transition: const TabTransition(duration: Duration(seconds: 1)),
      );

      final frames = await framesToExpand(
        tester,
        () => controller.expand(1, duration: const Duration(milliseconds: 100)),
      );

      expect(frames * 20, inInclusiveRange(100, 160));
    });
  });

  group('the remove button', () {
    testWidgets('removes its tab by default', (tester) async {
      final controller = await pumpOverview(tester);

      await tester.tap(find.byIcon(Icons.close).at(1));
      await tester.pumpAndSettle();

      expect(controller.tabs, [0, 2, 3]);
    });

    testWidgets('keeps its look and calls its own onPressed in a custom '
        'builder', (tester) async {
      final pressed = <int>[];
      final controller = await pumpOverview(
        tester,
        removeTabButtonBuilder: (context, tab) =>
            RemoveTabButton(onPressed: () => pressed.add(tab)),
      );

      await tester.tap(find.byIcon(Icons.close).at(1));
      await tester.pumpAndSettle();

      expect(pressed, [1]);
      expect(controller.tabs, [0, 1, 2, 3]);
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
