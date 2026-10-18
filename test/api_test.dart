import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

Future<TabOverviewController<int>> pumpOverview(
  WidgetTester tester, {
  int tabCount = 4,
}) async {
  final controller = TabOverviewController<int>(
    initialTabs: List.generate(tabCount, (tab) => tab),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Column(
        children: [
          // Rebuilds with the controller, as a ChangeNotifier.
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => Text(
              'state ${controller.tabs.length} '
              '${controller.mode.name} ${controller.activeTab}',
            ),
          ),
          Expanded(
            child: TabOverview<int>.builder(
              controller: controller,
              tabBuilder: (context, tab) => ColoredBox(
                color: Colors.white,
                child: Center(child: Text('T$tab')),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  group('the controller as a ChangeNotifier', () {
    testWidgets('tells its listeners of tabs added and removed, the mode and '
        'the active tab', (tester) async {
      final controller = await pumpOverview(tester);
      expect(find.text('state 4 overview 0'), findsOneWidget);

      controller.add(4);
      await tester.pump();
      expect(find.text('state 5 overview 0'), findsOneWidget);

      controller.expand(2);
      await tester.pump();
      expect(find.text('state 5 expanded 2'), findsOneWidget);
      await tester.pumpAndSettle();

      controller.remove(2);
      await tester.pump();
      expect(find.text('state 4 overview 3'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('tells its listeners once per change of the mode', (
      tester,
    ) async {
      final controller = await pumpOverview(tester);
      var notices = 0;
      controller.addListener(() => notices++);

      controller.collapse();
      expect(notices, 0, reason: 'already in the overview');

      controller.toggleMode();
      expect(notices, 1);
      await tester.pumpAndSettle();
    });

    // An off-screen tab's expand switches to its page a frame later, which
    // may come after the app disposed the controller with its overview.
    testWidgets('disposes with an off-screen expand still waiting', (
      tester,
    ) async {
      final controller = await pumpOverview(tester, tabCount: 40);

      controller.expand(38);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
