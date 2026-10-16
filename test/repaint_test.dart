import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

/// Counts how many times each tab's content paints.
class CountingPainter extends CustomPainter {
  CountingPainter(this.tab, this.paints);

  final int tab;
  final Map<int, int> paints;

  @override
  void paint(Canvas canvas, Size size) =>
      paints.update(tab, (n) => n + 1, ifAbsent: () => 1);

  @override
  bool shouldRepaint(CountingPainter oldDelegate) => false;
}

void main() {
  testWidgets('a flying tab paints its content once, not on every frame', (
    tester,
  ) async {
    final paints = <int, int>{};
    final controller = TabOverviewController<int>(initialTabs: [0, 1, 2, 3]);
    await tester.pumpWidget(
      MaterialApp(
        home: TabOverview<int>.builder(
          controller: controller,
          tabBuilder: (context, tab) => CustomPaint(
            painter: CountingPainter(tab, paints),
            child: Center(child: Text('T$tab')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<(int, Map<int, int>)> fly(void Function() flight) async {
      paints.clear();
      var frames = 0;
      flight();
      while (tester.binding.hasScheduledFrame) {
        await tester.pump(const Duration(milliseconds: 16));
        frames++;
      }
      return (frames, Map.of(paints));
    }

    final expand = await fly(() => controller.expand(1));
    final collapse = await fly(controller.collapse);
    // Once in the flight, and once where it lands.
    expect(expand.$2[1], 2);
    expect(collapse.$2[1], 2);
  });
}
