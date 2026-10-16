import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

void main() {
  group('a swipe between expanded tabs', () {
    late List<int> built;

    Future<TabOverviewController<int>> pumpOverview(WidgetTester tester) async {
      built = [];
      final controller = TabOverviewController<int>(
        initialTabs: [0, 1, 2, 3, 4, 5],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: TabOverview<int>.builder(
            controller: controller,
            tabBuilder: (context, tab) => Center(child: Text('T$tab')),
            tabThumbnailBuilder: (context, tab) {
              built.add(tab);
              return Center(key: ValueKey('thumb$tab'), child: Text('T$tab'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('rebuilds only the thumbnails of those tabs', (tester) async {
      final controller = await pumpOverview(tester);
      controller.expand(1);
      await tester.pumpAndSettle();

      built.clear();
      controller.scrollToTab(2);
      await tester.pumpAndSettle();

      expect(controller.activeTab, 2);
      // Tab 1's thumbnail shows again. Tab 2's, now expanded, is an empty cell.
      expect(built, [1]);
    });

    testWidgets('collapses to the cell of the tab it ends on', (tester) async {
      final controller = await pumpOverview(tester);
      final cell = tester.getRect(find.byKey(const ValueKey('thumb2')));
      controller.expand(1);
      await tester.pumpAndSettle();
      controller.scrollToTab(2);
      await tester.pumpAndSettle();

      controller.collapse();
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byKey(const ValueKey('thumb2'))), cell);
      expect(find.byKey(const ValueKey('thumb1')), findsOneWidget);
    });
  });
}
