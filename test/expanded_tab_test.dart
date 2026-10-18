import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

void main() {
  group('an expanded tab', () {
    late StateSetter rebuildParent;

    // Expands [tab], and lets it land, or only lets [frames] pass.
    Future<TabOverviewController<int>> expand(
      WidgetTester tester,
      int tab, {
      int? frames,
    }) async {
      final controller = TabOverviewController<int>(initialTabs: [0, 1, 2, 3]);
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuildParent = setState;
              return TabOverview<int>.builder(
                controller: controller,
                tabBuilder: (context, tab) => Center(child: Text('T$tab')),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.expand(tab);
      if (frames == null) {
        await tester.pumpAndSettle();
      } else {
        for (var frame = 0; frame < frames; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
      return controller;
    }

    PageController pageController(WidgetTester tester) =>
        tester.widget<PageView>(find.byType(PageView)).controller!;

    Finder shown(int tab) => find
        .descendant(of: find.byType(PageView), matching: find.text('T$tab'))
        .hitTestable();

    testWidgets('keeps its page controller when the parent rebuilds', (
      tester,
    ) async {
      await expand(tester, 2);
      final before = pageController(tester);

      rebuildParent(() {});
      await tester.pumpAndSettle();

      expect(pageController(tester), same(before));
    });

    testWidgets('disposes its page controller when it collapses', (
      tester,
    ) async {
      final controller = await expand(tester, 2);
      final pages = pageController(tester);

      controller.collapse();
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsNothing);
      expect(() => pages.addListener(() {}), throwsFlutterError);
    });

    testWidgets('stays on screen when a tab before it is removed', (
      tester,
    ) async {
      final controller = await expand(tester, 2);

      controller.remove(0);
      await tester.pumpAndSettle();

      expect(controller.activeTab, 2);
      expect(shown(2), findsOneWidget);
    });

    testWidgets('collapses to the overview when it is removed', (tester) async {
      final controller = await expand(tester, 1);

      controller.remove(1);
      await tester.pumpAndSettle();

      expect(controller.mode, TabOverviewMode.overview);
      expect(controller.tabs, [0, 2, 3]);
      expect(controller.activeTab, 2);
      expect(find.text('T1'), findsNothing);
      for (final tab in [0, 2, 3]) {
        expect(find.text('T$tab').hitTestable(), findsOneWidget);
      }
    });

    testWidgets('stays on screen when a tab is added', (tester) async {
      final controller = await expand(tester, 2);

      controller.add(4);
      await tester.pumpAndSettle();

      expect(controller.activeTab, 2);
      expect(shown(2), findsOneWidget);
    });

    testWidgets('collapses at once when it is removed, with the tab after '
        'it active', (tester) async {
      final controller = await expand(tester, 1);
      final modes = <TabOverviewMode>[];
      final activeTabs = <int?>[];
      controller
        ..addModeChangedListener(modes.add)
        ..addActiveTabChangedListener(
          () => activeTabs.add(controller.activeTab),
        );

      controller.remove(1);

      expect(modes, [TabOverviewMode.overview]);
      expect(activeTabs, [2]);
      expect(controller.activeIndex, 1);
    });

    // Its collapse sets off from its page. Built again before the collapse
    // switched to the grid, the pages had no page of it, and the flight
    // never set off, so the grid ignored taps from then on.
    for (final frames in [0, 1]) {
      final when = frames == 0 ? 'in the same event' : 'a frame later';
      for (final (what, then)
          in <(String, void Function(TabOverviewController<int>))>[
            ('a tab is added', (controller) => controller.add(4)),
            ('another tab is removed', (controller) => controller.remove(3)),
            ('the parent rebuilds', (_) => rebuildParent(() {})),
          ]) {
        testWidgets('collapses when it is removed and $what $when', (
          tester,
        ) async {
          final controller = await expand(tester, 1);
          final pageWidth = tester.getRect(shown(1)).width;

          controller.remove(1);
          for (var frame = 0; frame < frames; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
          }
          then(controller);
          for (var frame = 0; frame < 5; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
          }

          // It flies away, shrinking.
          final widths = find
              .text('T1')
              .evaluate()
              .map((element) => tester.getRect(find.byWidget(element.widget)))
              .map((rect) => rect.width)
              .where((width) => width > 0);
          expect(widths, [lessThan(pageWidth)]);

          await tester.pumpAndSettle();
          expect(controller.mode, TabOverviewMode.overview);
          expect(controller.isAnyCollapsing, isFalse);
          expect(find.text('T1'), findsNothing);
          for (final tab in controller.tabs) {
            expect(find.text('T$tab').hitTestable(), findsOneWidget);
          }
        });
      }
    }

    // A switch to the grid and back to the pages in the same event ran no
    // switch, so the flights both asked for waited for one forever.
    testWidgets('expands another tab asked for in the same event as its '
        'collapse', (tester) async {
      final controller = await expand(tester, 1);

      controller.collapse();
      controller.expand(3);
      await tester.pumpAndSettle();

      expect(controller.mode, TabOverviewMode.expanded);
      expect(controller.activeTab, 3);
      expect(shown(3), findsOneWidget);
      expect(controller.isAnyExpanding, isFalse);
      expect(controller.isAnyCollapsing, isFalse);
    });

    testWidgets('expands another tab asked for in the same event as its '
        'removal', (tester) async {
      final controller = await expand(tester, 1);

      controller.remove(1);
      controller.expand(3);
      await tester.pumpAndSettle();

      expect(controller.mode, TabOverviewMode.expanded);
      expect(controller.activeTab, 3);
      expect(shown(3), findsOneWidget);
      expect(find.text('T1'), findsNothing);
      expect(controller.isAnyExpanding, isFalse);
      expect(controller.isAnyCollapsing, isFalse);
    });

    testWidgets('toggled in the same event as its removal, expands the tab '
        'after it', (tester) async {
      final controller = await expand(tester, 1);

      controller.remove(1);
      controller.toggleMode();
      await tester.pumpAndSettle();

      expect(controller.mode, TabOverviewMode.expanded);
      expect(controller.activeTab, 2);
      expect(shown(2), findsOneWidget);
      expect(find.text('T1'), findsNothing);
      expect(controller.isAnyExpanding, isFalse);
      expect(controller.isAnyCollapsing, isFalse);
    });

    // The setter only set the field: the pages went on showing the tab
    // that was active, and a collapse then froze the overview.
    testWidgets('shows the page of a tab made active at once', (tester) async {
      final controller = await expand(tester, 1);

      controller.activeTab = 3;
      await tester.pump();

      expect(controller.mode, TabOverviewMode.expanded);
      expect(shown(3), findsOneWidget);

      controller.collapse();
      await tester.pumpAndSettle();
      expect(controller.isAnyCollapsing, isFalse);
      for (final tab in controller.tabs) {
        expect(find.text('T$tab').hitTestable(), findsOneWidget);
      }
    });

    // Made active before the expand's flight sets off, its page had none to
    // land on, and the flight waited forever. Made active as it flies, its
    // page went from under it, and its thumbnail stayed hidden.
    for (final frames in [0, 1, 5]) {
      testWidgets('shows the page of a tab made active $frames frames into '
          'its expand', (tester) async {
        final controller = await expand(tester, 1, frames: frames);

        controller.activeTab = 3;
        await tester.pumpAndSettle();

        expect(controller.mode, TabOverviewMode.expanded);
        expect(controller.activeTab, 3);
        expect(shown(3), findsOneWidget);
        expect(controller.isAnyExpanding, isFalse);
        expect(controller.isAnyCollapsing, isFalse);

        controller.collapse();
        await tester.pumpAndSettle();
        for (final tab in controller.tabs) {
          expect(find.text('T$tab').hitTestable(), findsOneWidget);
        }
      });
    }
  });
}
