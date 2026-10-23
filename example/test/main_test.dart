import 'dart:io';

import 'package:example/main.dart';
import 'package:example/style/style.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

void main() {
  testWidgets('opens with tabs 1 to 5 in the grid', (tester) async {
    await _pumpExample(tester);

    expect(_controller(tester).mode, TabOverviewMode.overview);
    for (final tab in ['1', '2', '3', '4', '5']) {
      expect(find.text(tab), findsOneWidget);
    }
  });

  testWidgets('zooms a tapped tab into its page, and back out', (
    tester,
  ) async {
    await _pumpExample(tester);
    final controller = _controller(tester);

    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(controller.mode, TabOverviewMode.expanded);
    expect(controller.activeTab, 2);

    await tester.tap(find.text('2').hitTestable());
    await tester.pumpAndSettle();
    expect(controller.mode, TabOverviewMode.overview);
  });

  testWidgets('adds a tab with the next number', (tester) async {
    await _pumpExample(tester);

    await tester.tap(find.byTooltip('New tab'));
    await tester.pumpAndSettle();

    expect(_controller(tester).tabs, [1, 2, 3, 4, 5, 6]);
  });

  testWidgets('closes the active tab until none is left', (tester) async {
    await _pumpExample(tester);

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byTooltip('Close the active tab'));
      await tester.pumpAndSettle();
    }
    expect(_controller(tester).tabs, isEmpty);

    await tester.tap(find.byTooltip('New tab'));
    await tester.pumpAndSettle();
    expect(find.text('6'), findsOneWidget);
  });

  testWidgets('closes a tab with its close button', (tester) async {
    await _pumpExample(tester);

    await tester.tap(find.byTooltip('Close tab').first);
    await tester.pumpAndSettle();

    expect(_controller(tester).tabs, [2, 3, 4, 5]);
  });

  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets('pulls the expanded tab down to collapse it, by '
        '${kind.name}', (tester) async {
      await _pumpExample(tester);
      final controller = _controller(tester);
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
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

  test('shows the code of lib/main.dart on its pub.dev page', () {
    // pub.dev shows example.md on the package's Example tab.
    final page = File('example.md').readAsStringSync();
    final code = RegExp(
      r'```dart\n(.*?)```',
      dotAll: true,
    ).firstMatch(page)?.group(1);
    final main = File('lib/main.dart').readAsStringSync();

    expect(code, main.substring(main.indexOf('import ')));
  });
}

Future<void> _pumpExample(WidgetTester tester) => tester.pumpWidget(
  MaterialApp(theme: exampleTheme, home: const TabOverviewExample()),
);

TabOverviewController<int> _controller(WidgetTester tester) => tester
    .state<TabOverviewExampleState>(find.byType(TabOverviewExample))
    .controller;
