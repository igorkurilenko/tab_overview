import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

void main() {
  testWidgets('a custom thumbnail can fit the tab as the default does', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TabOverview<int>.builder(
          controller: TabOverviewController<int>(initialTabs: [0, 1]),
          tabBuilder: (context, tab) => SizedBox.expand(
            key: ValueKey('content$tab'),
            child: Text('T$tab'),
          ),
          tabThumbnailBuilder: (context, tab) => Stack(
            children: [
              FittedTab(
                child: SizedBox.expand(
                  key: ValueKey('content$tab'),
                  child: Text('T$tab'),
                ),
              ),
              const Icon(Icons.star),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final overview = tester.getSize(find.byType(TabOverview<int>));
    final content = find.byKey(const ValueKey('content0'));
    // Laid out at the overview's size, and scaled down to the thumbnail's.
    expect(tester.getSize(content), overview);
    expect(tester.getRect(content).width, lessThan(overview.width / 2));
  });
}
