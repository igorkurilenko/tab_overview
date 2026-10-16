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

    Future<void> typeInExpandedTab(WidgetTester tester) async {
      final controller = TabOverviewController<int>(initialTabs: [0, 1, 2]);
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
  });
}
