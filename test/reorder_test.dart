import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

void main() {
  // Tab 3, dragged over tab 2 and back, and over it again as tab 2's slide
  // back ends. The pause before the last move lines that up for one of them.
  for (var pause = 10; pause <= 16; pause++) {
    testWidgets('a tab moved again as its slide ends slides, after a pause '
        'of $pause frames', (tester) async {
      tester.view.devicePixelRatio = 1;
      // 4 columns.
      tester.view.physicalSize = const Size(1300, 700);
      addTearDown(tester.view.reset);
      final controller = TabOverviewController<int>(
        initialTabs: List.generate(8, (i) => i + 1),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: TabOverview<int>.builder(
            controller: controller,
            tabBuilder: (context, tab) => ColoredBox(
              color: Colors.white,
              child: Center(child: Text('T$tab')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      double tab2() => tester.getCenter(find.text('T2')).dx;
      final slot = tester.getCenter(find.text('T3')).dx - tab2();
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('T3')),
      );
      // Long enough to pick it up.
      await tester.pump(const Duration(milliseconds: 600));

      var farthest = 0.0;
      Future<void> frames(int count, {double dx = 0}) async {
        for (var frame = 0; frame < count; frame++) {
          final before = tab2();
          if (dx != 0) await gesture.moveBy(Offset(dx, 0));
          await tester.pump(const Duration(milliseconds: 16));
          final step = (tab2() - before).abs();
          if (step > farthest) farthest = step;
        }
      }

      await frames(10, dx: -slot / 10);
      await frames(25);
      await frames(10, dx: slot / 10);
      await frames(pause);
      await frames(10, dx: -slot / 10);
      await frames(30);
      await gesture.up();
      await tester.pumpAndSettle();

      // A slide takes 350 ms. A jump takes the whole slot in one frame.
      expect(farthest, lessThan(slot / 4));
    });
  }
}
