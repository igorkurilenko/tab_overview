import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

// The States each tab's _Counter made and disposed.
final _made = <int, int>{};
final _disposed = <int, int>{};

// Tabs 0 to 3, whose pages show T and their number, as do the thumbnails
// [tabThumbnailBuilder] builds, if any.
Future<TabOverviewController<int>> pumpOverview(
  WidgetTester tester, {
  HeldThumbnailBuilder<int>? heldThumbnailBuilder,
  ModelWidgetBuilder<int>? tabThumbnailBuilder,
}) async {
  _made.clear();
  _disposed.clear();
  final controller = TabOverviewController<int>(initialTabs: [0, 1, 2, 3]);
  await tester.pumpWidget(
    MaterialApp(
      home: TabOverview<int>.builder(
        controller: controller,
        heldThumbnailBuilder: heldThumbnailBuilder,
        tabThumbnailBuilder: tabThumbnailBuilder,
        tabBuilder: (context, tab) => ColoredBox(
          color: Colors.white,
          child: Center(child: _Counter(tab)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

// Holds [tab]'s thumbnail long enough to pick it up, and till its held look
// has come.
Future<TestGesture> pickUp(WidgetTester tester, int tab) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.text('T$tab')),
  );
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
  return gesture;
}

void main() {
  testWidgets('builds each thumbnail at rest, at 0', (tester) async {
    final built = <int, Animation<double>>{};
    await pumpOverview(
      tester,
      heldThumbnailBuilder: (context, tab, thumbnail, animation) {
        built[tab] = animation;
        return thumbnail;
      },
    );

    expect(built.keys, unorderedEquals([0, 1, 2, 3]));
    for (final animation in built.values) {
      expect(animation.value, 0);
      expect(animation.status, AnimationStatus.dismissed);
    }
  });

  testWidgets('runs to 1 as a thumbnail is picked up, and back to 0 as '
      'it\'s let go, a frame\'s step at a time', (tester) async {
    final shown = <double>[];
    await pumpOverview(
      tester,
      heldThumbnailBuilder: (context, tab, thumbnail, animation) =>
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              if (tab == 3) shown.add(animation.value);
              return child!;
            },
            child: thumbnail,
          ),
    );

    final gesture = await pickUp(tester, 3);
    expect(shown.last, 1);

    shown.clear();
    await gesture.up();
    for (var frame = 0; frame < 60; frame++) {
      await tester.pump(const Duration(milliseconds: 8));
    }

    // Back to 0 as it lands in its cell, where it's built at rest, with no
    // jump on the way.
    expect(shown.last, 0);
    for (var i = 1; i < shown.length; i++) {
      expect(shown[i - 1] - shown[i], inInclusiveRange(0, .05));
    }
  });

  testWidgets('shows a held thumbnail only as it builds it, in place of '
      'the default', (tester) async {
    Future<double> grownWhileHeld() async {
      final atRest = tester.getRect(find.text('T3')).width;
      final gesture = await pickUp(tester, 3);
      final held = tester.getRect(find.text('T3')).width;
      await gesture.up();
      await tester.pumpAndSettle();
      return held / atRest;
    }

    await pumpOverview(tester);
    expect(await grownWhileHeld(), moreOrLessEquals(1.05));

    await pumpOverview(
      tester,
      heldThumbnailBuilder: (context, tab, thumbnail, animation) => thumbnail,
    );
    expect(await grownWhileHeld(), 1);
  });

  for (final own in [false, true]) {
    testWidgets('a thumbnail${own ? ' of the app\'s own' : ''} keeps its '
        'State as it\'s held, moved and let go', (tester) async {
      final controller = await pumpOverview(
        tester,
        tabThumbnailBuilder: own
            ? (context, tab) => ColoredBox(
                color: Colors.white,
                child: Center(child: _Counter(tab)),
              )
            : null,
        heldThumbnailBuilder: (context, tab, thumbnail, animation) =>
            _Held(animation: animation, child: thumbnail),
      );
      expect(_made, {0: 1, 1: 1, 2: 1, 3: 1});

      final from = tester.getCenter(find.text('T3'));
      final to = tester.getCenter(find.text('T2'));
      final gesture = await pickUp(tester, 3);
      for (var step = 1; step <= 10; step++) {
        await gesture.moveTo(Offset.lerp(from, to, step / 10)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.tabs, [0, 1, 3, 2]);
      expect(_made, {0: 1, 1: 1, 2: 1, 3: 1});
      expect(_disposed, isEmpty);
    });
  }

  // A tab removed while it's held keeps the index it had, which another
  // tab, or none, then has.
  for (final (held, removed) in [(3, 3), (2, 2), (3, 0)]) {
    testWidgets('a held thumbnail is built as tab $held\'s after tab '
        '$removed is removed', (tester) async {
      final builtHeld = <int>{};
      final controller = await pumpOverview(
        tester,
        heldThumbnailBuilder: (context, tab, thumbnail, animation) {
          if (animation != kAlwaysDismissedAnimation) builtHeld.add(tab);
          return thumbnail;
        },
      );

      final gesture = await pickUp(tester, held);
      expect(builtHeld, {held});

      controller.remove(removed);
      for (var frame = 0; frame < 40; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(builtHeld, {held});
      expect(controller.tabs, isNot(contains(removed)));
    });
  }
}

// Shows T and its tab's number, and counts the States it makes and disposes.
class _Counter extends StatefulWidget {
  final int tab;

  const _Counter(this.tab);

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  @override
  void initState() {
    super.initState();
    _made.update(widget.tab, (made) => made + 1, ifAbsent: () => 1);
  }

  @override
  void dispose() {
    _disposed.update(widget.tab, (disposed) => disposed + 1, ifAbsent: () => 1);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text('T${widget.tab}');
}

// Hands a held thumbnail's animation down to its parts, as an app would.
class _Held extends InheritedWidget {
  final Animation<double> animation;

  const _Held({required this.animation, required super.child});

  @override
  bool updateShouldNotify(_Held oldWidget) => animation != oldWidget.animation;
}
