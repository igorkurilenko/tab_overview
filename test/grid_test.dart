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

  testWidgets('moves thumbnails along the motion curve', (tester) async {
    const duration = Duration(milliseconds: 400);
    final controller = TabOverviewController<int>(initialTabs: [0, 1, 2]);
    await tester.pumpWidget(
      MaterialApp(
        home: TabOverview<int>.builder(
          controller: controller,
          tabBuilder: (context, tab) => Center(child: Text('T$tab')),
          thumbnailsMotionAnimationDuration: duration,
          // Holds each thumbnail in place until the end of its motion.
          thumbnailsMotionAnimationCurve: const Threshold(0.99),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final start = tester.getCenter(find.text('T1'));
    final end = tester.getCenter(find.text('T0'));

    controller.remove(0);
    final path = <Offset>[];
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(duration ~/ 25);
      path.add(tester.getCenter(find.text('T1')));
    }
    await tester.pumpAndSettle();

    expect(path, everyElement(start));
    expect(tester.getCenter(find.text('T1')), end);
  });
}
