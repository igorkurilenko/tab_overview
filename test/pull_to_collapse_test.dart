import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

const thumbnailDecoration = BoxDecoration(
  borderRadius: BorderRadius.all(Radius.circular(32)),
);

Widget staticTab(int tab) => ColoredBox(
  color: Colors.white,
  child: Center(child: Text('T$tab')),
);

Widget listTab(int tab, {ScrollPhysics? physics, ScrollController? scroll}) =>
    ListView(
      controller: scroll,
      physics: physics,
      children: [
        for (var row = 0; row < 40; row++)
          SizedBox(height: 60, child: Text('T$tab row $row')),
      ],
    );

// The overview, at 800 by 600, with tab 1 of 4 expanded.
Future<TabOverviewController<int>> pumpExpanded(
  WidgetTester tester, {
  bool pullToCollapse = true,
  Widget Function(int tab) tabBuilder = staticTab,
}) async {
  final controller = TabOverviewController<int>(initialTabs: [0, 1, 2, 3]);
  await tester.pumpWidget(
    MaterialApp(
      home: TabOverview<int>.builder(
        controller: controller,
        pullToCollapse: pullToCollapse,
        thumbnailDecoration: thumbnailDecoration,
        tabBuilder: (context, tab) => tabBuilder(tab),
      ),
    ),
  );
  await tester.pumpAndSettle();
  controller.expand(1);
  await tester.pumpAndSettle();
  return controller;
}

Finder page() => find
    .descendant(of: find.byType(PageView), matching: find.byType(FittedTab))
    .first;

Future<void> pull(WidgetTester tester, double distance) =>
    tester.timedDrag(page(), Offset(0, distance), const Duration(seconds: 1));

// The corner radius of every decoration with a border radius shown.
Iterable<double> cornerRadii(WidgetTester tester) => tester
    .widgetList<Container>(find.byType(Container))
    .map((container) => container.decoration)
    .whereType<BoxDecoration>()
    .map((decoration) => decoration.borderRadius)
    .whereType<BorderRadius>()
    .map((radius) => radius.topLeft.x);

void expectCollapsed(WidgetTester tester, TabOverviewController<int> c) {
  expect(c.mode, TabOverviewMode.overview);
  expect(c.isAnyCollapsing, isFalse);
  expect(find.text('T1').hitTestable(), findsOneWidget);
}

void expectExpandedAtFullSize(
  WidgetTester tester,
  TabOverviewController<int> controller,
) {
  expect(controller.mode, TabOverviewMode.expanded);
  expect(
    tester.getRect(page()),
    rectMoreOrLessEquals(Rect.fromLTWH(0, 0, 800, 600)),
  );
}

void main() {
  testWidgets('a tab pulled far enough collapses when let go', (tester) async {
    final controller = await pumpExpanded(tester);

    await pull(tester, 150);
    await tester.pumpAndSettle();

    expectCollapsed(tester, controller);
  });

  testWidgets('a tab pulled a little and let go slowly goes back', (
    tester,
  ) async {
    final controller = await pumpExpanded(tester);

    await pull(tester, 40);
    await tester.pumpAndSettle();

    expectExpandedAtFullSize(tester, controller);
    expect(cornerRadii(tester), everyElement(32));
  });

  testWidgets('a tab flicked down collapses however little it is pulled', (
    tester,
  ) async {
    final controller = await pumpExpanded(tester);

    // Past the touch slop, the tab is pulled 42 of the 50 pixels.
    await tester.fling(page(), const Offset(0, 60), 1000);
    await tester.pumpAndSettle();

    expectCollapsed(tester, controller);
  });

  testWidgets('a pulled tab shrinks, follows the pull, and turns toward its '
      'thumbnail', (tester) async {
    await pumpExpanded(tester);

    final gesture = await tester.startGesture(tester.getCenter(page()));
    // Past the touch slop, then halfway.
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 25));
    await tester.pump();

    // 95% of the overview, centred, and 25 pixels down.
    expect(
      tester.getRect(page()),
      rectMoreOrLessEquals(Rect.fromLTRB(20, 40, 780, 610)),
    );
    // Halfway from the expanded tab's square corners to the thumbnail's.
    expect(cornerRadii(tester), contains(16));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a tab let go partway collapses from the corners it was '
      'pulled to', (tester) async {
    await pumpExpanded(tester);
    final gesture = await tester.startGesture(tester.getCenter(page()));
    var time = Duration.zero;
    Future<void> move(double dy) {
      time += const Duration(milliseconds: 16);
      return gesture.moveBy(Offset(0, dy), timeStamp: time);
    }

    // Past the touch slop, then 30 of the 50 pixels, fast enough to
    // collapse when let go.
    await move(20);
    for (var step = 0; step < 3; step++) {
      await move(10);
    }
    await tester.pump();
    // The thumbnails' corners, and the page's, 60% of the way to them.
    double pageRadius() => cornerRadii(tester).singleWhere((r) => r < 31.9);
    expect(pageRadius(), moreOrLessEquals(19.2));

    await gesture.up(timeStamp: time);
    await tester.pump(const Duration(milliseconds: 16));
    final setOff = pageRadius();
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final onTheWay = pageRadius();
    await tester.pumpAndSettle();

    // From where the pull left them, rather than from the expanded tab's
    // square corners, to the thumbnail's.
    expect(setOff, moreOrLessEquals(19.2, epsilon: 0.5));
    expect(onTheWay, inExclusiveRange(setOff, 32));
    expect(cornerRadii(tester), everyElement(32));
  });

  testWidgets('a tab collapses from where it was let go', (tester) async {
    await pumpExpanded(tester);

    await pull(tester, 150);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    // Pulled all the way, the tab has the thumbnail's corners already. The
    // flight sets off with them, rather than with the expanded tab's.
    expect(cornerRadii(tester), everyElement(32));
    await tester.pumpAndSettle();
  });

  testWidgets('a tab let go faster sets off faster', (tester) async {
    // How far up tab 1 is three frames after it's let go: pulled 100 pixels
    // slowly, then 100 more in steps of [lastSteps] a frame.
    Future<double> topAfterLetGo({required double lastSteps}) async {
      await tester.pumpWidget(const SizedBox());
      await pumpExpanded(tester);
      final gesture = await tester.startGesture(tester.getCenter(page()));
      var time = Duration.zero;
      Future<void> move(double dy) {
        time += const Duration(milliseconds: 16);
        return gesture.moveBy(Offset(0, dy), timeStamp: time);
      }

      for (var moved = 0; moved < 100; moved += 5) {
        await move(5);
      }
      for (var moved = 0.0; moved < 100; moved += lastSteps) {
        await move(lastSteps);
      }
      await gesture.up(timeStamp: time);
      for (var frame = 0; frame < 3; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // The flying tab, the one 'T1' with a place on screen.
      final top = tester
          .renderObjectList<RenderBox>(find.text('T1'))
          .map((box) => box.localToGlobal(Offset.zero).dy)
          .singleWhere((top) => top.isFinite);
      await tester.pumpAndSettle();
      return top;
    }

    // About 300 and 3,000 pixels a second.
    final slow = await topAfterLetGo(lastSteps: 5);
    final fast = await topAfterLetGo(lastSteps: 50);

    // Without the fling's speed, both would be at the same place.
    expect(fast, lessThan(slow - 4));
  });

  for (final physics in [
    const BouncingScrollPhysics(),
    const ClampingScrollPhysics(),
  ]) {
    testWidgets('a list at its top pulls the tab, with '
        '${physics.runtimeType}', (tester) async {
      final controller = await pumpExpanded(
        tester,
        tabBuilder: (tab) => listTab(tab, physics: physics),
      );

      // A list that bounces moves less than the pointer past its top.
      await pull(tester, 250);
      await tester.pumpAndSettle();

      expect(controller.mode, TabOverviewMode.overview);
      expect(controller.isAnyCollapsing, isFalse);
    });
  }

  testWidgets('a list scrolled down scrolls rather than pulls', (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final controller = await pumpExpanded(
      tester,
      tabBuilder: (tab) => listTab(tab, scroll: tab == 1 ? scroll : null),
    );
    scroll.jumpTo(400);
    await tester.pump();

    await pull(tester, 150);
    await tester.pumpAndSettle();

    expectExpandedAtFullSize(tester, controller);
    expect(scroll.offset, lessThan(400));
  });

  testWidgets('a swipe still turns the page', (tester) async {
    final controller = await pumpExpanded(tester);

    await tester.timedDrag(
      page(),
      const Offset(-500, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();

    expect(controller.mode, TabOverviewMode.expanded);
    expect(controller.activeTab, 2);
  });

  testWidgets('a tab turned back while it collapses can be pulled again', (
    tester,
  ) async {
    final controller = await pumpExpanded(tester);

    await pull(tester, 150);
    await tester.pump(const Duration(milliseconds: 16));
    controller.expand(1);
    await tester.pumpAndSettle();
    expectExpandedAtFullSize(tester, controller);

    await pull(tester, 150);
    await tester.pumpAndSettle();
    expectCollapsed(tester, controller);
  });

  testWidgets('pulling is off by default', (tester) async {
    final controller = TabOverviewController<int>(initialTabs: [0, 1, 2, 3]);
    await tester.pumpWidget(
      MaterialApp(
        home: TabOverview<int>.builder(
          controller: controller,
          tabBuilder: (context, tab) => staticTab(tab),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.expand(1);
    await tester.pumpAndSettle();

    await pull(tester, 150);
    await tester.pumpAndSettle();

    expectExpandedAtFullSize(tester, controller);
  });
}
