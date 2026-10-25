import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

import 'support.dart';

const _screenColor = Color(0xFFFFFFFF);
const _blue = Color(0xFF0000FF);

final _screen = GlobalKey();

// The overview, at 800 by 600, of [tabs] with pages of [page], which a pull
// on a page collapses.
Future<TabOverviewController<int>> pumpOverview(
  WidgetTester tester, {
  List<int> tabs = const [0],
  Widget page = const ColoredBox(color: _blue),
  Decoration? thumbnailDecoration,
  Decoration? expandedTabDecoration,
  TabDecorationBuilder<int>? tabDecorationBuilder,
}) async {
  final controller = TabOverviewController<int>(initialTabs: tabs);
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
            thumbnailDecoration: thumbnailDecoration,
            expandedTabDecoration: expandedTabDecoration,
            tabDecorationBuilder: tabDecorationBuilder,
            removeTabButtonBuilder: (context, tab) => const SizedBox.shrink(),
            tabBuilder: (context, tab) => page,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

Future<int> pixelsWhere(
  WidgetTester tester,
  bool Function(int r, int g, int b) test,
) async => (await ScreenPixels.capture(tester, _screen)).where(test).count;

bool Function(int r, int g, int b) _isColor(Color color) =>
    (r, g, b) =>
        r == (color.r * 255).round() &&
        g == (color.g * 255).round() &&
        b == (color.b * 255).round();

// A black shadow's gray over the white screen.
bool _isGray(int r, int g, int b) => r == g && g == b && r < 250;

// A red shadow's pink over the white screen.
bool _isPink(int r, int g, int b) => r > 250 && g == b && g < 245;

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
  testWidgets('what the builder returns decorates each tab, at rest and as '
      'it zooms', (tester) async {
    const red = Color(0xFFFF0000);
    const green = Color(0xFF00FF00);
    final controller = await pumpOverview(
      tester,
      tabs: [0, 1],
      // See-through, so the decorations show.
      page: const SizedBox.expand(),
      tabDecorationBuilder: (context, tab, decoration, zoom) =>
          BoxDecoration(color: tab == 0 ? red : green),
    );
    expect(await pixelsWhere(tester, _isColor(red)), greaterThan(10000));
    expect(await pixelsWhere(tester, _isColor(green)), greaterThan(10000));

    controller.expand(0);
    final zooming = await pumpFlight(
      tester,
      controller,
      () => pixelsWhere(tester, _isColor(red)),
    );
    expect(zooming, isNotEmpty);
    expect(zooming, everyElement(greaterThan(10000)));
    await tester.pumpAndSettle();
    expect(await pixelsWhere(tester, _isColor(red)), 800 * 600);
  });

  testWidgets('the builder gets where a tab is: at rest, as it zooms each '
      'way, and as its page is pulled', (tester) async {
    final zooms = <TabZoom>[];
    final controller = await pumpOverview(
      tester,
      tabDecorationBuilder: (context, tab, decoration, zoom) {
        zooms.add(zoom);
        return decoration;
      },
    );
    expect(zooms.last, const TabZoom(expansion: 0, lift: 0));

    zooms.clear();
    controller.expand(0);
    // A frame at a time, so the zooms on the way are all there.
    await pumpFlight(tester, controller, () {});
    await tester.pumpAndSettle();
    final expanding = zooms.where((zoom) => zoom.direction != null).toList();
    expect(expanding, isNotEmpty);
    // Expanding from the first frame it's sent on, before it sets off.
    expect(
      expanding.map((zoom) => zoom.direction),
      everyElement(TabZoomDirection.expand),
    );
    expect(expanding.map((zoom) => zoom.lift).reduce(max), greaterThan(.9));
    for (var i = 1; i < expanding.length; i++) {
      expect(
        expanding[i].expansion,
        greaterThanOrEqualTo(expanding[i - 1].expansion),
      );
    }
    expect(zooms.last, const TabZoom(expansion: 1, lift: 0));

    zooms.clear();
    final gesture = await tester.startGesture(const Offset(400, 200));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, 12));
      await tester.pump(oneFrame);
    }
    expect(zooms, isNotEmpty);
    for (final zoom in zooms) {
      expect(zoom.direction, TabZoomDirection.collapse);
      expect(zoom.expansion, closeTo(1 - zoom.lift, 1e-9));
    }
    // Pulled past 50 pixels.
    expect(
      zooms.last,
      const TabZoom(
        expansion: 0,
        lift: 1,
        direction: TabZoomDirection.collapse,
      ),
    );

    // Let go, it collapses from as high as the pull lifted it, heading the
    // same way all along.
    zooms.clear();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(zooms.first.lift, greaterThan(.99));
    expect(controller.mode, TabOverviewMode.overview);
    final collapsing = zooms.sublist(0, zooms.length - 1);
    expect(
      collapsing.map((zoom) => zoom.direction),
      everyElement(TabZoomDirection.collapse),
    );
    expect(zooms.last, const TabZoom(expansion: 0, lift: 0));
  });

  testWidgets('TabDecorations.flat casts no shadow as a tab zooms', (
    tester,
  ) async {
    await withBlurredShadows(() async {
      final controller = await pumpOverview(
        tester,
        tabDecorationBuilder: TabDecorations.flat(),
      );
      controller.expand(0);
      final zooming = await pumpFlight(
        tester,
        controller,
        () => pixelsWhere(tester, _isGray),
      );
      expect(zooming, isNotEmpty);
      expect(zooming, everyElement(0));
    });
  });

  testWidgets("TabDecorations.lifted casts the shadows it's given", (
    tester,
  ) async {
    await withBlurredShadows(() async {
      final controller = await pumpOverview(
        tester,
        tabDecorationBuilder: TabDecorations.lifted(
          shadows: const [
            BoxShadow(
              color: Color(0x80FF0000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
      );
      controller.expand(0);
      final zooming = await pumpFlight(
        tester,
        controller,
        () async => (
          pink: await pixelsWhere(tester, _isPink),
          gray: await pixelsWhere(tester, _isGray),
        ),
      );
      expect(zooming.map((frame) => frame.pink).reduce(max), greaterThan(1000));
      // Not the default shadow.
      expect(zooming.map((frame) => frame.gray), everyElement(0));
    });
  });

  testWidgets('TabDecorations.lifted casts its shadows under any '
      'decoration, such as a ShapeDecoration', (tester) async {
    await withBlurredShadows(() async {
      const shape = ShapeDecoration(
        color: _blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      );
      final controller = await pumpOverview(
        tester,
        thumbnailDecoration: shape,
        expandedTabDecoration: shape,
      );
      expect(await pixelsWhere(tester, _isGray), 0);

      controller.expand(0);
      final zooming = await pumpFlight(
        tester,
        controller,
        () => pixelsWhere(tester, _isGray),
      );
      expect(zooming.reduce(max), greaterThan(1000));
    });
  });

  testWidgets('TabDecorations.lifted keeps a BoxDecoration one, its own '
      'shadows over the lifted ones', (tester) async {
    const own = BoxShadow(color: Color(0x80FF0000), offset: Offset(0, -20));
    const decoration = BoxDecoration(boxShadow: [own]);
    final built = <Decoration>[];
    final controller = await pumpOverview(
      tester,
      thumbnailDecoration: decoration,
      expandedTabDecoration: decoration,
      tabDecorationBuilder: (context, tab, decoration, zoom) {
        final lifted = TabDecorations.lifted()(context, tab, decoration, zoom);
        built.add(lifted);
        return lifted;
      },
    );
    controller.expand(0);
    await pumpFlight(tester, controller, () {});

    expect(built, everyElement(isA<BoxDecoration>()));
    final shadows = [
      for (final decoration in built.cast<BoxDecoration>())
        decoration.boxShadow!,
    ];
    expect(shadows.map((shadows) => shadows.last), everyElement(own));
    expect(shadows.map((shadows) => shadows.length).reduce(max), 2);
  });

  testWidgets('a tab clips to what the builder returns', (tester) async {
    final rounded = BoxDecoration(borderRadius: BorderRadius.circular(16));
    await pumpOverview(
      tester,
      // Square at either end, as by default.
      tabDecorationBuilder: (context, tab, decoration, zoom) => rounded,
    );
    final decorated = tester.widgetList<Container>(
      find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration == rounded,
      ),
    );
    expect(decorated, isNotEmpty);
    expect(
      decorated.map((container) => container.clipBehavior),
      everyElement(Clip.antiAlias),
    );
  });
}
