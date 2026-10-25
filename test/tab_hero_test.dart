import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

import 'support.dart';

// A tab's title: red on its thumbnail, blue on its page, of one shape on
// both, and a green part only its page has.
const _thumbnailTitle = Color(0xFFFF0000);
const _pageTitle = Color(0xFF0000FF);
const _pageOnly = Color(0xFF00FF00);

// Where the parts are, on an 800 by 600 overview of the default grid, whose
// cells are 261 by 196: the title 10 pixels into a thumbnail's top left, at
// 60 by 30, and 40 pixels into the page's bottom right, at 120 by 60.
const _thumbnailTitleRect = Rect.fromLTWH(10, 10, 60, 30);
const _pageTitleRect = Rect.fromLTWH(640, 500, 120, 60);
const _pageOnlyRect = Rect.fromLTWH(40, 40, 100, 50);

final _screen = GlobalKey();

Widget _box(Color color, Size size) => SizedBox.fromSize(
  size: size,
  child: ColoredBox(color: color),
);

// The overview of [tabs], each with its title on its thumbnail and page.
Future<TabOverviewController<int>> pumpOverview(
  WidgetTester tester, {
  List<int> tabs = const [0],
}) async {
  final controller = TabOverviewController<int>(initialTabs: tabs);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _screen,
      child: MaterialApp(
        // Its red would count as the title's.
        debugShowCheckedModeBanner: false,
        home: TabOverview<int>.builder(
          controller: controller,
          tabThumbnailBuilder: (context, tab) => Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: TabHero(
                tag: 'title',
                child: _box(_thumbnailTitle, _thumbnailTitleRect.size),
              ),
            ),
          ),
          tabBuilder: (context, tab) => Stack(
            children: [
              Positioned(
                right: 40,
                bottom: 40,
                child: TabHero(
                  tag: 'title',
                  child: _box(_pageTitle, _pageTitleRect.size),
                ),
              ),
              Positioned(
                left: 40,
                top: 40,
                child: TabHero(
                  tag: 'only on page',
                  child: _box(_pageOnly, _pageOnlyRect.size),
                ),
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

// The title's pixels: red, blue, or the two fading into each other, on the
// screen's black.
bool _isTitle(int r, int g, int b) => g < 40 && r + b > 120;

bool _isPageOnly(int r, int g, int b) => g > 40 && r < 40 && b < 40;

// How far [rect]'s center is along the way from [from]'s to [to]'s, and how
// far off that line.
(double, double) _alongTheWay(Rect rect, Rect from, Rect to) {
  final way = to.center - from.center;
  final traveled = rect.center - from.center;
  final along =
      (traveled.dx * way.dx + traveled.dy * way.dy) / way.distanceSquared;
  final off = (traveled - way * along).distance;
  return (along, off);
}

// Pumps the frames of the flight under way, and checks on each that the
// title shows once, in one box, on its way from [from] to [to].
Future<void> expectTitleFlies(
  WidgetTester tester,
  TabOverviewController<int> controller, {
  required Rect from,
  required Rect to,
}) async {
  final ways = await pumpFlight(tester, controller, () async {
    final title = (await ScreenPixels.capture(tester, _screen)).where(_isTitle);
    final bounds = title.bounds!;
    // One box: not the title also zooming with the tab's page or thumbnail.
    expect(
      title.count,
      greaterThan(bounds.width * bounds.height * .9),
      reason: 'the title shows in more than one place at $bounds',
    );
    final (along, off) = _alongTheWay(bounds, from, to);
    expect(off, lessThan(3), reason: 'off its way at $bounds');
    return along;
  });
  expect(ways.length, greaterThan(5));
  expect(ways.first, lessThan(.2));
  expect(ways.last, greaterThan(.8));
}

void main() {
  testWidgets('a tab hero flies on its own from its thumbnail to its page, '
      'and lands there', (tester) async {
    final controller = await pumpOverview(tester);

    controller.expand(0);
    await expectTitleFlies(
      tester,
      controller,
      from: _thumbnailTitleRect,
      to: _pageTitleRect,
    );

    await tester.pumpAndSettle();
    final title = (await ScreenPixels.capture(tester, _screen)).where(_isTitle);
    expect(title.bounds, _pageTitleRect);
  });

  testWidgets('a tab hero flies back to its thumbnail as the tab collapses', (
    tester,
  ) async {
    final controller = await pumpOverview(tester);
    controller.expand(0);
    await tester.pumpAndSettle();

    controller.collapse();
    await expectTitleFlies(
      tester,
      controller,
      from: _pageTitleRect,
      to: _thumbnailTitleRect,
    );

    await tester.pumpAndSettle();
    final title = (await ScreenPixels.capture(tester, _screen)).where(_isTitle);
    expect(title.bounds, _thumbnailTitleRect);
  });

  testWidgets('a part only the page has zooms and fades in with the page, '
      'rather than flying', (tester) async {
    final controller = await pumpOverview(tester);

    controller.expand(0);
    final frames = await pumpFlight(tester, controller, () async {
      final pixels = await ScreenPixels.capture(tester, _screen);
      final bounds = pixels.where(_isPageOnly).bounds;
      if (bounds == null) return (smaller: false, faded: false);
      final (_, g, _) = pixels.at(
        bounds.center.dx.toInt(),
        bounds.center.dy.toInt(),
      );
      return (smaller: bounds.width < _pageOnlyRect.width - 2, faded: g < 240);
    });
    expect(frames.any((frame) => frame.smaller), isTrue);
    expect(frames.any((frame) => frame.faded), isTrue);

    await tester.pumpAndSettle();
    final part = (await ScreenPixels.capture(
      tester,
      _screen,
    )).where(_isPageOnly);
    expect(part.bounds, _pageOnlyRect);
  });

  testWidgets('tab heroes of one tag pair within their own tab only', (
    tester,
  ) async {
    await pumpOverview(tester, tabs: [0, 1, 2]);

    // Each thumbnail shows its title. Paired across tabs, all but one would
    // hide behind the last.
    final pixels = await ScreenPixels.capture(tester, _screen);
    for (final left in [0.0, 269.0, 538.0]) {
      final center = _thumbnailTitleRect.shift(Offset(left, 0)).center;
      final (r, g, b) = pixels.at(center.dx.toInt(), center.dy.toInt());
      expect((r, g, b), (255, 0, 0), reason: 'the title at $center');
    }
  });

  testWidgets('a tab hero outside an overview shows its child', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TabHero(tag: 'title', child: Text('Title')),
      ),
    );
    expect(find.text('Title'), findsOneWidget);
  });
}
