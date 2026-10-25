import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

import 'support.dart';

// A tab's page, all blue, on a white screen, so any gray on it is the
// shadow under a tab off the grid: black, see-through, over the white.
const _page = Color(0xFF0000FF);
const _screenColor = Color(0xFFFFFFFF);

final _screen = GlobalKey();

// The overview, at 800 by 600, of one tab, which a pull on its page
// collapses.
Future<TabOverviewController<int>> pumpOverview(WidgetTester tester) async {
  final controller = TabOverviewController<int>(initialTabs: [0]);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _screen,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: _screenColor,
          child: TabOverview<int>.builder(
            controller: controller,
            pullToCollapse: true,
            thumbnailsGridPadding: EdgeInsets.zero,
            removeTabButtonBuilder: (context, tab) => const SizedBox.shrink(),
            tabBuilder: (context, tab) => const ColoredBox(color: _page),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

// The shadow's gray: as dark in each channel, and darker than the white.
bool _isShadow(int r, int g, int b) => r == g && g == b && r < 250;

Future<int> shadowPixels(WidgetTester tester) async =>
    (await ScreenPixels.capture(tester, _screen)).where(_isShadow).count;

// Runs [body] with shadows blurred, as a device draws them, rather than as
// tests do, with no blur, so a shadow spills past a tab's sides too.
Future<void> withBlurredShadows(Future<void> Function() body) async {
  debugDisableShadows = false;
  try {
    await body();
  } finally {
    debugDisableShadows = true;
  }
}

void main() {
  testWidgets('a tab casts a shadow as it zooms, the most halfway, and none '
      'once it lands', (tester) async {
    await withBlurredShadows(() async {
      final controller = await pumpOverview(tester);
      expect(await shadowPixels(tester), 0);

      controller.expand(0);
      final expanding = await pumpFlight(
        tester,
        controller,
        () => shadowPixels(tester),
      );
      expect(expanding.length, greaterThan(5));
      final most = expanding.reduce((a, b) => a > b ? a : b);
      expect(most, greaterThan(1000));
      // It grows from next to none as the tab takes off, and fades to next
      // to none as it lands.
      expect(expanding.first, lessThan(most ~/ 10));
      expect(expanding.last, lessThan(most ~/ 10));
      await tester.pumpAndSettle();
      expect(await shadowPixels(tester), 0);

      controller.collapse();
      final collapsing = await pumpFlight(
        tester,
        controller,
        () => shadowPixels(tester),
      );
      expect(collapsing.reduce((a, b) => a > b ? a : b), greaterThan(1000));
      await tester.pumpAndSettle();
      expect(await shadowPixels(tester), 0);
    });
  });

  testWidgets('a page pulled down casts a shadow, which goes on as it '
      'collapses and goes as it lands', (tester) async {
    await withBlurredShadows(() async {
      final controller = await pumpOverview(tester);
      controller.expand(0);
      await tester.pumpAndSettle();
      expect(await shadowPixels(tester), 0);

      final gesture = await tester.startGesture(const Offset(400, 200));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, 12));
        await tester.pump(oneFrame);
      }
      final pulled = await shadowPixels(tester);
      expect(pulled, greaterThan(1000));

      // Let go, it flies to its thumbnail from as high as the pull lifted
      // it, its shadow fading as it lands rather than gone at once.
      await gesture.up();
      await tester.pump();
      await tester.pump(oneFrame);
      expect(await shadowPixels(tester), greaterThan(pulled ~/ 2));

      await tester.pumpAndSettle();
      expect(controller.mode, TabOverviewMode.overview);
      expect(await shadowPixels(tester), 0);
    });
  });
}
