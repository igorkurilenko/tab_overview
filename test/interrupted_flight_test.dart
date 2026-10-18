import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

const thumbnailDecoration = BoxDecoration(color: Color(0xFFFF0000));
const expandedTabDecoration = BoxDecoration(color: Color(0xFF0000FF));

Future<TabOverviewController<int>> pumpOverview(
  WidgetTester tester, {
  int tabCount = 4,
}) async {
  final controller = TabOverviewController<int>(
    initialTabs: List.generate(tabCount, (tab) => tab),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: TabOverview<int>.builder(
        controller: controller,
        thumbnailDecoration: thumbnailDecoration,
        expandedTabDecoration: expandedTabDecoration,
        tabBuilder: (context, tab) => GestureDetector(
          onTap: () => controller.expand(tab),
          child: ColoredBox(
            color: Colors.white,
            child: Center(child: Text('T$tab')),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

Future<void> pumpFrames(WidgetTester tester, int frames) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void expectNothingFlying(TabOverviewController<int> controller) {
  expect(controller.isAnyExpanding, isFalse, reason: 'expanding');
  expect(controller.isAnyCollapsing, isFalse, reason: 'collapsing');
}

Future<void> expectTapOnThumbnailExpands(
  WidgetTester tester,
  TabOverviewController<int> controller,
) async {
  await tester.tap(find.text('T2'));
  await tester.pumpAndSettle();
  expect(controller.mode, TabOverviewMode.expanded);
  expect(controller.activeTab, 2);
}

Iterable<Decoration?> pageDecorations(WidgetTester tester) => tester
    .widgetList<Container>(
      find.descendant(
        of: find.byType(PageView),
        matching: find.byType(Container),
      ),
    )
    .map((container) => container.decoration)
    .whereType<BoxDecoration>();

// How far the flying tab's decoration is from the thumbnail's, at 0, to the
// expanded tab's, at 1. Its blue channel goes from 0 to 1 on the way.
double flyingExpansion(WidgetTester tester) => tester
    .widgetList<Container>(find.byType(Container))
    .map((container) => container.decoration)
    .whereType<BoxDecoration>()
    .where(
      (decoration) =>
          decoration != thumbnailDecoration &&
          decoration != expandedTabDecoration,
    )
    .first
    .color!
    .b;

void main() {
  for (final frames in [1, 5, 10]) {
    group('$frames frame${frames == 1 ? '' : 's'} into a flight', () {
      testWidgets('a collapse turns an expand around', (tester) async {
        final controller = await pumpOverview(tester);

        controller.expand(1);
        await pumpFrames(tester, frames);
        controller.collapse();
        await tester.pumpAndSettle();

        expect(controller.mode, TabOverviewMode.overview);
        expectNothingFlying(controller);
        await expectTapOnThumbnailExpands(tester, controller);
      });

      testWidgets('an expand turns a collapse around', (tester) async {
        final controller = await pumpOverview(tester);
        controller.expand(1);
        await tester.pumpAndSettle();

        controller.collapse();
        await pumpFrames(tester, frames);
        controller.expand(1);
        await tester.pumpAndSettle();

        expect(controller.mode, TabOverviewMode.expanded);
        expectNothingFlying(controller);
        expect(pageDecorations(tester), [expandedTabDecoration]);

        controller.collapse();
        await tester.pumpAndSettle();
        expectNothingFlying(controller);
        await expectTapOnThumbnailExpands(tester, controller);
      });

      testWidgets('an expand turns a turned expand around again', (
        tester,
      ) async {
        final controller = await pumpOverview(tester);

        controller.expand(1);
        await pumpFrames(tester, frames);
        controller.collapse();
        await pumpFrames(tester, frames);
        controller.expand(1);
        await tester.pumpAndSettle();

        expect(controller.mode, TabOverviewMode.expanded);
        expectNothingFlying(controller);
        expect(pageDecorations(tester), [expandedTabDecoration]);
      });

      // Its page moves down a place, keeping its State. The flight measures
      // the page on its way, which must have a place in the view by then.
      testWidgets('removing a tab before it lands its expand on its page', (
        tester,
      ) async {
        final controller = await pumpOverview(tester);

        controller.expand(2);
        await pumpFrames(tester, frames);
        controller.remove(0);
        await tester.pumpAndSettle();

        expect(controller.mode, TabOverviewMode.expanded);
        expect(controller.activeTab, 2);
        expectNothingFlying(controller);
        expect(
          find
              .descendant(of: find.byType(PageView), matching: find.text('T2'))
              .hitTestable(),
          findsOneWidget,
        );
      });

      testWidgets('removing the tab ends its expand in the overview', (
        tester,
      ) async {
        final controller = await pumpOverview(tester);

        controller.expand(1);
        await pumpFrames(tester, frames);
        controller.remove(1);
        await tester.pumpAndSettle();

        expect(controller.mode, TabOverviewMode.overview);
        expect(controller.tabs, [0, 2, 3]);
        expect(find.text('T1'), findsNothing);
        expectNothingFlying(controller);
        await expectTapOnThumbnailExpands(tester, controller);
      });
    });
  }

  testWidgets('an off-screen tab turned around ends its flight in the '
      'overview, however late in the flight it turns', (tester) async {
    // Late enough, the tab lands on its page before the switch that turns it
    // around, which then starts a flight back to the stand-in of its own.
    for (var frames = 1; frames <= 20; frames++) {
      await tester.pumpWidget(const SizedBox());
      final controller = await pumpOverview(tester, tabCount: 40);
      expect(find.text('T38'), findsNothing);

      controller.expand(38);
      await pumpFrames(tester, frames);
      controller.collapse();
      await tester.pumpAndSettle();

      expect(controller.mode, TabOverviewMode.overview, reason: '$frames');
      expect(controller.isAnyExpanding, isFalse, reason: '$frames');
      expect(controller.isAnyCollapsing, isFalse, reason: '$frames');
    }
  });

  testWidgets('an overview that goes away mid-flight ends the flight', (
    tester,
  ) async {
    final controller = await pumpOverview(tester);

    controller.expand(1);
    await pumpFrames(tester, 5);
    await tester.pumpWidget(const SizedBox());

    expect(tester.takeException(), isNull);
    expectNothingFlying(controller);
  });

  testWidgets('a turned flight\'s decoration turns from where it is', (
    tester,
  ) async {
    final controller = await pumpOverview(tester);

    controller.expand(1);
    await pumpFrames(tester, 8);
    final turnedAt = flyingExpansion(tester);
    controller.collapse();
    await pumpFrames(tester, 2);

    expect(turnedAt, inExclusiveRange(0.1, 0.9));
    expect(flyingExpansion(tester), closeTo(turnedAt, 0.15));
  });

  testWidgets('removing a tab in the same event as its expand leaves it '
      'in the overview', (tester) async {
    // Tab 1 is on screen, so its expand switches to its page at once. Tab 38
    // is off screen, so its expand waits a frame for its stand-in.
    for (final tab in [1, 38]) {
      await tester.pumpWidget(const SizedBox());
      final controller = await pumpOverview(tester, tabCount: 40);

      controller.expand(tab);
      controller.remove(tab);
      await tester.pumpAndSettle();

      expect(controller.mode, TabOverviewMode.overview, reason: '$tab');
      expect(find.text('T$tab'), findsNothing, reason: '$tab');
      expectNothingFlying(controller);
      await expectTapOnThumbnailExpands(tester, controller);
    }
  });

  testWidgets('removing the expanded tab before the overview is built '
      'leaves nothing flying', (tester) async {
    final controller = TabOverviewController<int>(
      initialTabs: [0, 1, 2, 3],
      initialMode: TabOverviewMode.expanded,
      activeTab: 1,
    );
    controller.remove(1);
    await tester.pumpWidget(
      MaterialApp(
        home: TabOverview<int>.builder(
          controller: controller,
          tabBuilder: (context, tab) => GestureDetector(
            onTap: () => controller.expand(tab),
            child: ColoredBox(
              color: Colors.white,
              child: Center(child: Text('T$tab')),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.mode, TabOverviewMode.overview);
    expect(controller.activeTab, 2);
    expectNothingFlying(controller);
    await expectTapOnThumbnailExpands(tester, controller);
  });

  testWidgets('a collapse in the same event as an expand cancels it', (
    tester,
  ) async {
    final controller = await pumpOverview(tester);

    controller.expand(1);
    controller.collapse();
    await tester.pumpAndSettle();

    expect(controller.mode, TabOverviewMode.overview);
    expectNothingFlying(controller);
    await expectTapOnThumbnailExpands(tester, controller);
  });
}
