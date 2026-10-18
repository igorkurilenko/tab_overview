import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

void main() {
  group('an expanded tab keeps its state', () {
    late StateSetter rebuildParent;

    final expandedTabField = find.descendant(
      of: find.byType(PageView),
      matching: find.byKey(const ValueKey(1)),
    );

    Future<TabOverviewController<int>> typeInExpandedTab(
      WidgetTester tester, {
      List<int> tabs = const [0, 1, 2],
    }) async {
      final controller = TabOverviewController<int>(initialTabs: tabs);
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuildParent = setState;
              return Scaffold(
                body: TabOverview<int>.builder(
                  controller: controller,
                  tabBuilder: (context, tab) =>
                      ListView(children: [TextField(key: ValueKey(tab))]),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.expand(1);
      await tester.pumpAndSettle();
      await tester.enterText(expandedTabField, 'hello');
      await tester.pump();
      return controller;
    }

    String expandedTabText(WidgetTester tester) => tester
        .widget<EditableText>(
          find.descendant(
            of: expandedTabField,
            matching: find.byType(EditableText),
          ),
        )
        .controller
        .text;

    testWidgets('when the parent rebuilds', (tester) async {
      await typeInExpandedTab(tester);
      final focus = FocusManager.instance.primaryFocus;

      rebuildParent(() {});
      await tester.pumpAndSettle();

      expect(expandedTabText(tester), 'hello');
      expect(FocusManager.instance.primaryFocus, same(focus));
    });

    testWidgets('when the keyboard opens', (tester) async {
      addTearDown(tester.view.resetViewInsets);
      await typeInExpandedTab(tester);
      final focus = FocusManager.instance.primaryFocus;

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();

      expect(expandedTabText(tester), 'hello');
      expect(FocusManager.instance.primaryFocus, same(focus));
    });

    // Its page moves down a place. The pages were built by place, so the
    // tab's content was built anew there, and lost what was typed.
    testWidgets('when a tab before it is removed', (tester) async {
      final controller = await typeInExpandedTab(tester);
      final focus = FocusManager.instance.primaryFocus;

      controller.remove(0);
      await tester.pumpAndSettle();

      expect(controller.activeTab, 1);
      expect(expandedTabText(tester), 'hello');
      expect(FocusManager.instance.primaryFocus, same(focus));
    });

    testWidgets('when tabs before and after it are removed and added', (
      tester,
    ) async {
      final controller = await typeInExpandedTab(tester, tabs: [0, 3, 1, 2]);
      final focus = FocusManager.instance.primaryFocus;

      controller
        ..remove(3)
        ..add(4)
        ..remove(0)
        ..remove(2);
      await tester.pumpAndSettle();

      expect(controller.tabs, [1, 4]);
      expect(controller.activeTab, 1);
      expect(expandedTabText(tester), 'hello');
      expect(FocusManager.instance.primaryFocus, same(focus));
    });
  });
}
