import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

  testWidgets('a screen reader moves a thumbnail up and down a row', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.devicePixelRatio = 1;
    // 3 columns.
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.reset);
    final controller = TabOverviewController<int>(
      initialTabs: List.generate(9, (i) => i),
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

    // The thumbnail's moves by label, each with the node that holds it.
    Map<String, (int node, int action)> moves(int tab) {
      SemanticsNode? node = tester.getSemantics(find.text('T$tab'));
      while (node != null) {
        final holder = node;
        final ids = holder.getSemanticsData().customSemanticsActionIds ?? [];
        if (ids.isNotEmpty) {
          return {
            for (final id in ids)
              CustomSemanticsAction.getAction(id)!.label!: (holder.id, id),
          };
        }
        node = holder.parent;
      }
      return {};
    }

    Future<void> move(int tab, String label) async {
      final (node, action) = moves(tab)[label]!;
      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          type: SemanticsAction.customAction,
          viewId: tester.view.viewId,
          nodeId: node,
          arguments: action,
        ),
      );
      await tester.pumpAndSettle();
    }

    expect(moves(4).keys, containsAll(['Move up', 'Move down']));
    expect(moves(1).keys, isNot(contains('Move up')));
    expect(moves(7).keys, isNot(contains('Move down')));

    await move(4, 'Move up');
    expect(controller.tabs, [0, 4, 1, 2, 3, 5, 6, 7, 8]);

    await move(4, 'Move down');
    expect(controller.tabs, [0, 1, 2, 3, 4, 5, 6, 7, 8]);

    semantics.dispose();
  });
}
