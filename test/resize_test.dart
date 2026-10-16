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
}
