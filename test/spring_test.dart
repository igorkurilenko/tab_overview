import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

import 'support.dart';

// A bouncy spring, which carries a tab about 5% past where it lands.
final _bouncy = SpringDescription.withDurationAndBounce(
  duration: const Duration(milliseconds: 300),
  bounce: .3,
);

// The overview, at 800 by 600, of tabs 0 to 3, which expand and collapse by
// [transition], or else on the bouncy spring.
Future<TabOverviewController<int>> pumpOverview(
  WidgetTester tester, {
  TabTransition? transition,
}) async {
  final controller = TabOverviewController<int>(
    initialTabs: [0, 1, 2, 3],
    transition: transition ?? TabTransition.spring(_bouncy),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: TabOverview<int>.builder(
        controller: controller,
        pullToCollapse: true,
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

// Where tab 1 shows: on its thumbnail, on its page, or flying.
Rect tabRect(WidgetTester tester) => rectsOf(
  tester,
  find.ancestor(of: find.text('T1'), matching: find.byType(FittedTab)),
).single;

// Where tab 1 shows on each frame of the flight under way.
Future<List<Rect>> flightOf(
  WidgetTester tester,
  TabOverviewController<int> controller,
) => pumpFlight(tester, controller, () => tabRect(tester));

// Pulls tab 1's page down 80 pixels, then lets go of it [fast], or after
// holding it still.
Future<void> pull(WidgetTester tester, {required bool fast}) => pullDown(
  tester,
  const Offset(400, 300),
  [20, 15, 15, 15, 15, if (!fast) ...List.filled(10, 0.0)],
);

void main() {
  test('a spring transition runs for as long as its spring takes to settle, '
      'along its path', () {
    final transition = TabTransition.spring(_bouncy);

    expect(transition.spring, same(_bouncy));
    expect(transition.duration, greaterThan(Duration.zero));
    expect(transition.curve.transform(0), 0);
    expect(transition.curve.transform(1), 1);
    final path = [
      for (var t = 0; t <= 100; t++) transition.curve.transform(t / 100),
    ];
    expect(path.any((value) => value > 1), isTrue);

    final again = TabTransition.spring(
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 300),
        bounce: .3,
      ),
    );
    expect(again, transition);
    expect(again.hashCode, transition.hashCode);
    expect(
      const TabTransition(duration: Duration(milliseconds: 300)).spring,
      isNull,
    );
  });

  testWidgets('a tab expands on a bouncy spring a little past its page\'s '
      'size, and lands on its page', (tester) async {
    final controller = await pumpOverview(tester);

    controller.expand(1);
    final rects = await flightOf(tester, controller);
    expect(rects.any((rect) => rect.width > 801), isTrue);

    await tester.pumpAndSettle();
    expect(
      tabRect(tester),
      rectMoreOrLessEquals(Offset.zero & const Size(800, 600)),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tab collapses on a bouncy spring a little past its '
      'thumbnail\'s size, and lands on its thumbnail', (tester) async {
    final controller = await pumpOverview(tester);
    final thumbnail = tabRect(tester);
    controller.expand(1);
    await tester.pumpAndSettle();

    controller.collapse();
    final rects = await flightOf(tester, controller);
    expect(rects.any((rect) => rect.width < thumbnail.width - 1), isTrue);

    await tester.pumpAndSettle();
    expect(tabRect(tester), rectMoreOrLessEquals(thumbnail));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a duration and a curve given to a call fly along the curve '
      'over the duration, rather than on the spring', (tester) async {
    final controller = await pumpOverview(tester);

    controller.expand(
      1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    final rects = await flightOf(tester, controller);
    expect(rects.every((rect) => rect.width <= 800.5), isTrue);
    expect(rects.length, inInclusiveRange(24, 27));
  });

  testWidgets('a page let go of mid-pull collapses on the spring at the '
      'speed it was let go at, a little past its thumbnail\'s size', (
    tester,
  ) async {
    // Where the tab is on each frame of its flight, from the pulled page,
    // and where its thumbnail is.
    Future<(List<Rect>, Rect)> collapse({required bool fast}) async {
      final controller = await pumpOverview(tester);
      final thumbnail = tabRect(tester);
      controller.expand(1);
      await tester.pumpAndSettle();
      await pull(tester, fast: fast);
      final rects = await flightOf(tester, controller);
      await tester.pumpAndSettle();
      expect(controller.mode, TabOverviewMode.overview);
      return (rects, thumbnail);
    }

    final (fast, thumbnail) = await collapse(fast: true);
    final (heldStill, _) = await collapse(fast: false);
    // Two frames in, the one let go of fast is further on its way.
    expect(fast[2].width, lessThan(heldStill[2].width - 5));
    expect(fast.any((rect) => rect.width < thumbnail.width - 1), isTrue);
  });
}
