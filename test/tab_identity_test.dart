import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

/// A tab whose equality and hash code follow a field that can change.
class MutableTab {
  MutableTab(this.name);

  String name;

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) => other is MutableTab && other.name == name;
}

Future<void> pumpFrames(WidgetTester tester, int frames) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets('a tab whose hash code changes mid-flight lands', (tester) async {
    final tabs = [MutableTab('A'), MutableTab('B'), MutableTab('C')];
    final controller = TabOverviewController<MutableTab>(initialTabs: tabs);
    await tester.pumpWidget(
      MaterialApp(
        home: TabOverview<MutableTab>.builder(
          controller: controller,
          tabBuilder: (context, tab) => GestureDetector(
            onTap: () => controller.expand(tab),
            child: ColoredBox(
              color: Colors.white,
              child: Center(child: Text(tab.name)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    controller.expand(tabs[1]);
    await pumpFrames(tester, 5);
    tabs[1].name = 'B2';
    await tester.pumpAndSettle();

    expect(controller.isAnyExpanding, isFalse);
    expect(controller.isAnyCollapsing, isFalse);

    controller.collapse();
    await tester.pumpAndSettle();
    expect(controller.isAnyExpanding, isFalse);
    expect(controller.isAnyCollapsing, isFalse);

    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();
    expect(controller.mode, TabOverviewMode.expanded);
    expect(controller.activeTab, tabs[2]);
  });

  testWidgets('a tab removed while expanded flies until it lands', (
    tester,
  ) async {
    final controller = TabOverviewController<int>(initialTabs: [0, 1, 2, 3]);
    await tester.pumpWidget(
      MaterialApp(
        home: TabOverview<int>.builder(
          controller: controller,
          tabBuilder: (context, tab) => Center(child: Text('T$tab')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.expand(2);
    await tester.pumpAndSettle();

    controller.remove(2);
    await pumpFrames(tester, 4);

    expect(controller.isAnyCollapsing, isTrue);
    expect(find.text('T0').hitTestable(), findsNothing);

    await tester.pumpAndSettle();
    expect(controller.isAnyCollapsing, isFalse);
    expect(find.text('T0').hitTestable(), findsOneWidget);
  });
}
