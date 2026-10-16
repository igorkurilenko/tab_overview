import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

void main() {
  group('when the parent rebuilds, shows the tabs on every frame', () {
    late StateSetter rebuildParent;

    Future<TabOverviewController<int>> pumpOverview(WidgetTester tester) async {
      final controller = TabOverviewController<int>(initialTabs: [0, 1, 2]);
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuildParent = setState;
              return TabOverview<int>.builder(
                controller: controller,
                tabBuilder: (context, tab) => Center(child: Text('T$tab')),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      return controller;
    }

    Future<void> expectOnEveryFrame(WidgetTester tester, Finder tabs) async {
      rebuildParent(() {});
      for (var frame = 1; frame <= 5; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(tabs, findsWidgets, reason: 'frame $frame');
      }
    }

    testWidgets('in the overview', (tester) async {
      await pumpOverview(tester);
      await expectOnEveryFrame(tester, find.text('T0'));
    });

    testWidgets('with a tab expanded', (tester) async {
      final controller = await pumpOverview(tester);
      controller.expand(1);
      await tester.pumpAndSettle();
      await expectOnEveryFrame(tester, find.byType(PageView));
    });
  });
}
