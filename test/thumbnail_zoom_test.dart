import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

import 'support.dart';

// A thumbnail of the app's own, all red, and its tab's page, blue, with a
// green bar 50 pixels high along its bottom.
const _thumbnail = Color(0xFFFF0000);
const _page = Color(0xFF0000FF);
const _bar = Color(0xFF00FF00);
const _barHeight = 50.0;

final _screen = GlobalKey();

// The overview, at 800 by 600, of one tab, in a grid of [gridDelegate]'s
// cells, if given, or else of the default ones, the tab [decorated] if
// given.
Future<TabOverviewController<int>> pumpOverview(
  WidgetTester tester, {
  SliverGridDelegate? gridDelegate,
  Decoration? decorated,
}) async {
  final controller = TabOverviewController<int>(initialTabs: [0]);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _screen,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: TabOverview<int>.builder(
          controller: controller,
          pullToCollapse: true,
          thumbnailsGridDelegate: gridDelegate,
          thumbnailsGridPadding: EdgeInsets.zero,
          thumbnailDecoration: decorated,
          expandedTabDecoration: decorated,
          removeTabButtonBuilder: (context, tab) => const SizedBox.shrink(),
          tabThumbnailBuilder: (context, tab) =>
              const ColoredBox(color: _thumbnail),
          tabBuilder: (context, tab) => const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: ColoredBox(color: _page)),
              SizedBox(
                height: _barHeight,
                child: ColoredBox(color: _bar),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

// Any of the thumbnail's red, or of the page's blue, however faded and
// whatever is over or under it: the thumbnail is all red, and the page has
// no red, so each channel is the one's alone. The thumbnail shows more than
// half where its red is more than half of all red.
bool _isThumbnail(int r, int g, int b) => r > 20;
bool _isThumbnailMoreThanHalf(int r, int g, int b) => r > 128;
bool _isPage(int r, int g, int b) => b > 20;

// The page's blue, and its bar's green, showing more than the tab's dark
// gray, and anything on the screen's black.
bool _isPageBlue(int r, int g, int b) => b > 60 && r < 40 && g < 40;
bool _isBar(int r, int g, int b) => g > 60 && r < 40 && b < 40;
bool _isAnything(int r, int g, int b) => r + g + b > 0;

// The pixels of the thumbnail and of the page on each frame of the flight
// under way, and whether the thumbnail showed more than half on it.
Future<List<(int, int, bool)>> shownOnEachFrame(
  WidgetTester tester,
  TabOverviewController<int> controller,
) => pumpFlight(tester, controller, () async {
  final pixels = await ScreenPixels.capture(tester, _screen);
  return (
    pixels.where(_isThumbnail).count,
    pixels.where(_isPage).count,
    pixels.where(_isThumbnailMoreThanHalf).count > 0,
  );
});

// The thumbnail shows first, and the page last, which shows only once the
// thumbnail has faded more than half out, so they fade into each other
// rather than show at once.
void expectFadesIntoPage(List<(int, int, bool)> frames) {
  expect(frames.length, greaterThan(5));
  final (thumbnailFirst, pageFirst, _) = frames.first;
  expect(thumbnailFirst, greaterThan(0));
  expect(pageFirst, 0);
  for (final (_, page, thumbnailMoreThanHalf) in frames) {
    if (thumbnailMoreThanHalf) expect(page, 0);
  }
  final (thumbnailLast, pageLast, _) = frames.last;
  expect(thumbnailLast, 0);
  expect(pageLast, greaterThan(0));
}

void main() {
  testWidgets('a thumbnail of the app\'s own fades into its page as the tab '
      'expands', (tester) async {
    final controller = await pumpOverview(tester);

    controller.expand(0);
    expectFadesIntoPage(await shownOnEachFrame(tester, controller));
  });

  testWidgets('a thumbnail the size of its page, as on a watch, still fades '
      'into it', (tester) async {
    final controller = await pumpOverview(
      tester,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 800 / 600,
      ),
    );

    controller.expand(0);
    expectFadesIntoPage(await shownOnEachFrame(tester, controller));
  });

  testWidgets('a page let go of mid-pull sets off showing all of itself', (
    tester,
  ) async {
    final controller = await pumpOverview(tester);
    controller.expand(0);
    await tester.pumpAndSettle();

    await pullDown(tester, const Offset(400, 300), [20, 8, 8, 8, 8, 8, 8]);

    final frames = await shownOnEachFrame(tester, controller);
    final (thumbnailFirst, pageFirst, _) = frames.first;
    expect(thumbnailFirst, 0);
    expect(pageFirst, greaterThan(0));
    expect(controller.mode, TabOverviewMode.overview);
  });

  testWidgets('a page zooms laid out at its width, as tall as the shape it '
      'zooms through gives it, so its bottom bar stays at its bottom', (
    tester,
  ) async {
    // Square cells, unlike the page's 4:3, and the tab dark gray, so it
    // shows where the page doesn't reach.
    final controller = await pumpOverview(
      tester,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      decorated: const BoxDecoration(color: Color(0xFF282828)),
    );

    controller.expand(0);
    final checked = await pumpFlight(tester, controller, () async {
      final pixels = await ScreenPixels.capture(tester, _screen);
      // Once the thumbnail has faded out, over the page's bar.
      if (pixels.where(_isThumbnail).count > 0) return false;
      final page = pixels.where(_isPageBlue).bounds;
      final bar = pixels.where(_isBar).bounds;
      if (page == null || bar == null) return false;
      final tab = pixels.where(_isAnything).bounds!;
      expect(bar.bottom, moreOrLessEquals(tab.bottom, epsilon: 1));
      expect(bar.width, moreOrLessEquals(tab.width, epsilon: 1));
      expect(
        bar.height,
        moreOrLessEquals(_barHeight * tab.width / 800, epsilon: 1.5),
      );
      return true;
    });
    expect(checked.where((frame) => frame).length, greaterThan(3));
  });
}
