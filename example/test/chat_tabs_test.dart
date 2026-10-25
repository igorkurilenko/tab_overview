import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';
import 'package:example/chat_tabs/main.dart';
import 'package:example/style/style.dart';

void main() {
  Future<ChatTabsExampleState> pumpChats(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: exampleTheme, home: const ChatTabsExample()),
    );
    await tester.pumpAndSettle();
    return tester.state<ChatTabsExampleState>(find.byType(ChatTabsExample));
  }

  Future<void> pumpFrames(WidgetTester tester) async {
    for (var frame = 0; frame < 60; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
  }

  testWidgets('a card opens into its chat, which a pull on its bar closes', (
    tester,
  ) async {
    final state = await pumpChats(tester);
    final controller = state.controller;

    await tester.tap(find.text('Mia Collins'));
    await pumpFrames(tester);
    expect(controller.mode, TabOverviewMode.expanded);
    expect(controller.activeTab?.name, 'Mia Collins');

    // A message comes in, and the open chat shows it.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // The name in the bar, rather than a message's sender.
    final bar = find.descendant(
      of: find.byType(EdgeScrim),
      matching: find.text('Mia Collins'),
    );
    await tester.drag(bar, const Offset(0, 200));
    await pumpFrames(tester);
    expect(controller.mode, TabOverviewMode.overview);
    expect(tester.takeException(), isNull);
  });
}
