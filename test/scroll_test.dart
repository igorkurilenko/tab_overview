import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

void main() {
  testWidgets('scrolls to a tab added on a new row', (tester) async {
    // 39 tabs fill 13 rows of 3, so a 40th starts a 14th, off screen.
    final controller = TabOverviewController<int>(
      initialTabs: List.generate(39, (tab) => tab),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TabOverview<int>.builder(
          controller: controller,
          tabBuilder: (context, tab) => Center(child: Text('T$tab')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    controller.add(99);
    await tester.pumpAndSettle();
    controller.scrollToTab(99);
    await tester.pumpAndSettle();

    expect(find.text('T99').hitTestable(), findsOneWidget);
  });

  testWidgets('removing the expanded tab collapses to its neighbour', (
    tester,
  ) async {
    // Tab 20 is on the 7th row of 3, off screen until expanded.
    final controller = TabOverviewController<int>(
      initialTabs: List.generate(40, (tab) => tab),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TabOverview<int>.builder(
          controller: controller,
          tabBuilder: (context, tab) => Center(child: Text('T$tab')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.expand(20);
    await tester.pumpAndSettle();

    controller.remove(20);
    await tester.pumpAndSettle();

    expect(controller.mode, TabOverviewMode.overview);
    expect(controller.activeTab, 21);
    expect(find.text('T21').hitTestable(), findsOneWidget);
  });
}
