import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

void main() {
  testWidgets('switches to a new controller', (tester) async {
    final first = TabOverviewController<int>(initialTabs: [1, 2]);
    final second = TabOverviewController<int>(initialTabs: [7, 8]);
    var controller = first;
    late StateSetter setController;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setController = setState;
            return TabOverview<int>.builder(
              controller: controller,
              tabBuilder: (context, tab) => Center(child: Text('T$tab')),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    setController(() => controller = second);
    await tester.pumpAndSettle();

    expect(find.text('T1'), findsNothing);
    expect(find.text('T7'), findsOneWidget);
    expect(find.text('T8'), findsOneWidget);

    second.expand(8);
    await tester.pumpAndSettle();

    expect(second.mode, TabOverviewMode.expanded);
    expect(
      find.descendant(of: find.byType(PageView), matching: find.text('T8')),
      findsOneWidget,
    );

    second.collapse();
    await tester.pumpAndSettle();

    expect(second.mode, TabOverviewMode.overview);
    expect(find.text('T8').hitTestable(), findsOneWidget);
  });

  testWidgets('keeps working when a new overview takes the controller over', (
    tester,
  ) async {
    final controller = TabOverviewController<int>(initialTabs: [1, 2]);
    var generation = 0;
    late StateSetter remount;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            remount = setState;
            return TabOverview<int>.builder(
              key: ValueKey(generation),
              controller: controller,
              tabBuilder: (context, tab) => Center(child: Text('T$tab')),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    remount(() => generation++);
    await tester.pumpAndSettle();
    controller.expand(2);
    await tester.pumpAndSettle();

    expect(controller.mode, TabOverviewMode.expanded);
    expect(
      find.descendant(of: find.byType(PageView), matching: find.text('T2')),
      findsOneWidget,
    );
  });
}
