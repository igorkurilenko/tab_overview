import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

late StateSetter rebuildParent;

Future<TabOverviewController<int>> pumpOverview(WidgetTester tester) async {
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
  return controller;
}

Future<void> pumpFrames(WidgetTester tester, int frames) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

double scaleOf(WidgetTester tester, int tab) => tester
    .widget<ScaleTransition>(
      find
          .ancestor(
            of: find.text('T$tab'),
            matching: find.byType(ScaleTransition),
          )
          .first,
    )
    .scale
    .value;

void main() {
  for (final frames in [5, 15]) {
    testWidgets('a tab added again $frames frames into its removal shows', (
      tester,
    ) async {
      final controller = await pumpOverview(tester);

      controller.remove(2);
      await pumpFrames(tester, frames);
      controller.add(2);
      await tester.pumpAndSettle();

      expect(controller.tabs, [0, 1, 3, 2]);
      expect(find.text('T2'), findsOneWidget);
      expect(find.text('T2').hitTestable(), findsOneWidget);
      expect(scaleOf(tester, 2), 1);
    });
  }

  testWidgets('a tab removed and another added in the same event both show '
      'as they should', (tester) async {
    final controller = await pumpOverview(tester);

    controller.remove(1);
    controller.add(9);
    await tester.pumpAndSettle();

    expect(controller.tabs, [0, 2, 3, 9]);
    expect(find.text('T1'), findsNothing);
    for (final tab in controller.tabs) {
      expect(find.text('T$tab').hitTestable(), findsOneWidget);
    }
  });

  testWidgets('a tab added again in the same event as its removal shows', (
    tester,
  ) async {
    final controller = await pumpOverview(tester);

    controller.remove(1);
    controller.add(1);
    await tester.pumpAndSettle();

    expect(controller.tabs, [0, 2, 3, 1]);
    expect(find.text('T1').hitTestable(), findsOneWidget);
    expect(scaleOf(tester, 1), 1);
  });

  testWidgets('an added tab grows in while the parent rebuilds', (
    tester,
  ) async {
    final controller = await pumpOverview(tester);

    controller.add(4);
    final scales = <double>[];
    for (var frame = 0; frame < 25; frame++) {
      rebuildParent(() {});
      await tester.pump(const Duration(milliseconds: 16));
      scales.add(scaleOf(tester, 4));
    }

    expect(scales.first, lessThan(0.1));
    expect(scales.last, 1);
    for (var frame = 1; frame < scales.length; frame++) {
      expect(scales[frame], greaterThanOrEqualTo(scales[frame - 1]));
    }
    expect(
      scales.where((scale) => scale > 0 && scale < 1).length,
      greaterThan(15),
    );
  });
}
