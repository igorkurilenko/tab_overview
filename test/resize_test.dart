import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

Widget overview(TabOverviewController<int> controller) => MaterialApp(
  home: Scaffold(
    body: TabOverview<int>.builder(
      controller: controller,
      tabBuilder: (context, tab) => ColoredBox(
        color: Colors.white,
        child: Center(child: Text('T$tab')),
      ),
    ),
  ),
);

void main() {
  testWidgets('collapses to the tab after the window shrinks', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.reset);
    final controller = TabOverviewController<int>(
      initialTabs: List.generate(24, (i) => i),
    );
    await tester.pumpWidget(overview(controller));
    controller.scrollToTab(18);
    await tester.pumpAndSettle();
    controller.expand(18);
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(500, 800);
    await tester.pumpAndSettle();
    controller.collapse();
    await tester.pumpAndSettle();

    final thumbnail = find.text('T18');
    expect(thumbnail.hitTestable(), findsOneWidget);
    expect(
      const Rect.fromLTWH(0, 0, 500, 800).contains(tester.getCenter(thumbnail)),
      isTrue,
    );
  });

  testWidgets('collapses to the tab after the safe area grows', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.reset);
    final controller = TabOverviewController<int>(
      initialTabs: List.generate(40, (i) => i),
    );
    await tester.pumpWidget(overview(controller));
    controller.expand(7);
    await tester.pumpAndSettle();

    // The grid's padding follows the safe area, which pushes tab 7's thumb
    // down past the grid's cache extent, so it's no longer built.
    tester.view.padding = const FakeViewPadding(top: 450);
    await tester.pumpAndSettle();
    controller.collapse();
    await tester.pumpAndSettle();

    expect(find.text('T7').hitTestable(), findsOneWidget);
  });

  group('shows the expanded tab on every frame', () {
    Future<void> expand(WidgetTester tester) async {
      final controller = TabOverviewController<int>(initialTabs: [0, 1, 2]);
      await tester.pumpWidget(overview(controller));
      controller.expand(1);
      await tester.pumpAndSettle();
    }

    testWidgets('while the keyboard opens', (tester) async {
      addTearDown(tester.view.reset);
      await expand(tester);
      for (var frame = 1; frame <= 15; frame++) {
        tester.view.viewInsets = FakeViewPadding(bottom: 20.0 * frame);
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.byType(PageView), findsOneWidget, reason: 'frame $frame');
      }
    });

    testWidgets('while the window resizes', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 800);
      addTearDown(tester.view.reset);
      await expand(tester);
      for (var frame = 1; frame <= 15; frame++) {
        tester.view.physicalSize = Size(1200 - 40.0 * frame, 800);
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.byType(PageView), findsOneWidget, reason: 'frame $frame');
      }
    });
  });
}
