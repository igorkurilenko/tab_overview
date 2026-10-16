import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

void main() {
  testWidgets('disposes the grid\'s scroll controller', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TabOverview<int>.builder(
          controller: TabOverviewController<int>(initialTabs: [0, 1]),
          tabBuilder: (context, tab) => Center(child: Text('T$tab')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final grid = tester.widget<Scrollable>(find.byType(Scrollable)).controller!;

    await tester.pumpWidget(const SizedBox());

    expect(() => grid.addListener(() {}), throwsFlutterError);
  });
}
