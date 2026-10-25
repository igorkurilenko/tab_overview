import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';
import 'package:example/chat_tabs/main.dart';
import 'package:example/style/style.dart';

void main() {
  // The chats on a screen of [size]: an iPhone 15's by default.
  Future<ChatTabsExampleState> pumpChats(
    WidgetTester tester, {
    Size size = const Size(393, 852),
  }) async {
    tester.view.physicalSize = size;
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

  const watch = Size(205, 251);
  double top(WidgetTester tester, String name) =>
      tester.getTopLeft(find.text(name)).dy;

  testWidgets('on a watch, a card is the screen, and the next one shows a '
      'gap after it as they scroll', (tester) async {
    await pumpChats(tester, size: watch);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Alex Morgan')),
    );
    await gesture.moveBy(const Offset(0, -20));
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();
    expect(
      top(tester, 'Mia Collins') - top(tester, 'Alex Morgan'),
      moreOrLessEquals(watch.height + 8),
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('on a watch, a scroll of the cards snaps to one', (tester) async {
    await pumpChats(tester, size: watch);
    double top(String name) => tester.getTopLeft(find.text(name)).dy;
    final atRest = top('Alex Morgan');

    // A quick swipe up turns to the next card, whole.
    await tester.fling(find.text('Alex Morgan'), const Offset(0, -80), 1000);
    await tester.pumpAndSettle();
    expect(top('Mia Collins'), moreOrLessEquals(atRest));

    // A short, slow drag goes back to the card it started from.
    await tester.timedDrag(
      find.text('Mia Collins'),
      const Offset(0, -60),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    expect(top('Mia Collins'), moreOrLessEquals(atRest));
  });
}
