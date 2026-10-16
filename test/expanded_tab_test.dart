import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

void main() {
  group('an expanded tab', () {
    late StateSetter rebuildParent;

    Future<TabOverviewController<int>> expand(
      WidgetTester tester,
      int tab,
    ) async {
      final controller = TabOverviewController<int>(initialTabs: [0, 1, 2, 3]);
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
      controller.expand(tab);
      await tester.pumpAndSettle();
      return controller;
    }

    PageController pageController(WidgetTester tester) =>
        tester.widget<PageView>(find.byType(PageView)).controller!;

    Finder shown(int tab) => find
        .descendant(of: find.byType(PageView), matching: find.text('T$tab'))
        .hitTestable();

    testWidgets('keeps its page controller when the parent rebuilds', (
      tester,
    ) async {
      await expand(tester, 2);
      final before = pageController(tester);

      rebuildParent(() {});
      await tester.pumpAndSettle();

      expect(pageController(tester), same(before));
    });

    testWidgets('disposes its page controller when it collapses', (
      tester,
    ) async {
      final controller = await expand(tester, 2);
      final pages = pageController(tester);

      controller.collapse();
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsNothing);
      expect(() => pages.addListener(() {}), throwsFlutterError);
    });

    testWidgets('stays on screen when a tab before it is removed', (
      tester,
    ) async {
      final controller = await expand(tester, 2);

      controller.remove(0);
      await tester.pumpAndSettle();

      expect(controller.activeTab, 2);
      expect(shown(2), findsOneWidget);
    });

    testWidgets('stays on screen when a tab is added', (tester) async {
      final controller = await expand(tester, 2);

      controller.add(4);
      await tester.pumpAndSettle();

      expect(controller.activeTab, 2);
      expect(shown(2), findsOneWidget);
    });
  });
}
