import 'package:example/main.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

void main() {
  testWidgets('adds tabs and shows them in the overview', (tester) async {
    await tester.pumpWidget(const MainApp());

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.auto_awesome_motion_outlined));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('closes the active tab until none is left', (tester) async {
    await tester.pumpWidget(const MainApp());
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
    }

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
    }
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
  });

  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets('pulls the expanded tab down to collapse it, by '
        '${kind.name}', (tester) async {
      await tester.pumpWidget(const MainApp());
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      final controller = tester
          .state<TabOverviewExampleState>(find.byType(TabOverviewExample))
          .controller;
      expect(controller.mode, TabOverviewMode.expanded);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
        kind: kind,
      );
      for (var step = 0; step < 15; step++) {
        await gesture.moveBy(const Offset(0, 10));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.mode, TabOverviewMode.overview);
    });
  }
}
