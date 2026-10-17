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
}
