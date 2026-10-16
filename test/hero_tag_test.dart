import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

/// A tab whose hash code collides with every other's, as hash codes may.
class CollidingTab {
  CollidingTab(this.name);

  final String name;

  @override
  int get hashCode => 0;

  @override
  bool operator ==(Object other) => identical(this, other);
}

void main() {
  testWidgets('shows and flies tabs whose hash codes collide', (tester) async {
    final a = CollidingTab('A');
    final b = CollidingTab('B');
    final controller = TabOverviewController<CollidingTab>(initialTabs: [a, b]);
    await tester.pumpWidget(
      MaterialApp(
        home: TabOverview<CollidingTab>.builder(
          controller: controller,
          tabBuilder: (context, tab) => Center(child: Text(tab.name)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A').hitTestable(), findsOneWidget);
    expect(find.text('B').hitTestable(), findsOneWidget);

    controller.expand(b);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(PageView), matching: find.text('B')),
      findsOneWidget,
    );

    controller.collapse();
    await tester.pumpAndSettle();
    expect(find.text('A').hitTestable(), findsOneWidget);
    expect(find.text('B').hitTestable(), findsOneWidget);
  });
}
