// Copyright 2026 Igor Kurilenko
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

part of '../tab_overview.dart';

/// A part of a tab, such as its title or its latest message, that flies on
/// its own between the tab's thumbnail and its page as the tab zooms in and
/// out: a hero animation of its own, in step with the tab's.
///
/// Put a [TabHero] with the same [tag] in what
/// [TabOverview.tabThumbnailBuilder] builds and in what
/// [TabOverview.tabBuilder] builds:
///
/// ```dart
/// TabOverview<Chat>.builder(
///   controller: controller,
///   tabThumbnailBuilder: (context, chat) => Column(
///     mainAxisAlignment: MainAxisAlignment.center,
///     children: [
///       TabHero(tag: 'name', child: Text(chat.name)),
///       TabHero(tag: 'last message', child: Text(chat.lastMessage)),
///     ],
///   ),
///   // ChatPage shows the name in its bar, and the last message at its
///   // bottom, each in a TabHero with the same tag.
///   tabBuilder: (context, chat) => ChatPage(chat),
/// )
/// ```
///
/// As the tab expands, each part flies from where it is on the thumbnail to
/// where it is on the page, and back as the tab collapses. A part that's a
/// scaled copy of the other, such as a name set bigger, grows or shrinks as
/// it flies. One of another shape, such as a message wrapped to another
/// width, is laid out again at each width it flies through, so its text
/// wraps anew, and fades from the one into the other.
///
/// A tag needs to be unique only among the tab's own parts. A part on only
/// one of the two, such as a message that the page's list hasn't built,
/// doesn't fly: it zooms and fades with the rest. Outside a [TabOverview], a
/// [TabHero] shows its [child].
class TabHero extends StatelessWidget {
  /// Creates a part of a tab that flies by [tag] between the tab's thumbnail
  /// and its page.
  const TabHero({super.key, required this.tag, required this.child});

  /// What the part flies by: the same on the tab's thumbnail and on its page,
  /// and unique among the tab's parts.
  final Object tag;

  /// What the part shows.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (_InTabShuttle.maybeOf(context) case final entry?) {
      return _HiddenWhileFlying(entry: entry, tag: tag, child: child);
    }
    return _TabPlace.maybeOf(context)?.buildPart(tag, child) ?? child;
  }
}

/// Where a tab's [TabHero]s are, on which side of the tab, which builds each
/// one's hero.
class _TabPlace extends InheritedWidget {
  const _TabPlace({
    required this.entry,
    required this.side,
    required this.buildPart,
    required super.child,
  });

  final Object entry;
  final _TabSide side;
  final Widget Function(Object tag, Widget child) buildPart;

  static _TabPlace? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TabPlace>();

  @override
  bool updateShouldNotify(_TabPlace oldWidget) =>
      entry != oldWidget.entry || side != oldWidget.side;
}

/// Marks the shuttle of [entry]'s flight, where the tab's [TabHero]s hide
/// while they fly on their own.
class _InTabShuttle extends InheritedWidget {
  const _InTabShuttle({required this.entry, required super.child});

  final _TabEntry<Object?> entry;

  static _TabEntry<Object?>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_InTabShuttle>()?.entry;

  @override
  bool updateShouldNotify(_InTabShuttle oldWidget) => entry != oldWidget.entry;
}

/// Shows [child], or, while the part of [entry]'s tab with [tag] flies,
/// keeps its space and shows nothing.
class _HiddenWhileFlying extends SingleChildRenderObjectWidget {
  const _HiddenWhileFlying({
    required this.entry,
    required this.tag,
    super.child,
  });

  final _TabEntry<Object?> entry;
  final Object tag;

  @override
  _RenderHiddenWhileFlying createRenderObject(BuildContext context) =>
      _RenderHiddenWhileFlying(entry, tag);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHiddenWhileFlying renderObject,
  ) => renderObject
    ..entry = entry
    ..tag = tag;
}

class _RenderHiddenWhileFlying extends RenderProxyBox {
  _RenderHiddenWhileFlying(this._entry, this._tag);

  _TabEntry<Object?> _entry;
  Object _tag;

  set entry(_TabEntry<Object?> value) {
    if (identical(value, _entry)) return;
    if (attached) {
      _entry.partFlightsChanged.removeListener(_changed);
      value.partFlightsChanged.addListener(_changed);
    }
    _entry = value;
    _changed();
  }

  set tag(Object value) {
    if (value == _tag) return;
    _tag = value;
    _changed();
  }

  bool get _hides => _entry.partFlies(_tag);

  void _changed() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _entry.partFlightsChanged.addListener(_changed);
  }

  @override
  void detach() {
    _entry.partFlightsChanged.removeListener(_changed);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_hides) super.paint(context, offset);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      !_hides && super.hitTest(result, position: position);

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (!_hides) super.visitChildrenForSemantics(visitor);
  }
}

/// Tells [onLayout] the size its child is laid out at, unless it's empty,
/// as a stand-in's is.
class _LaidOutSize extends SingleChildRenderObjectWidget {
  const _LaidOutSize({required this.onLayout, super.child});

  final ValueSetter<Size> onLayout;

  @override
  _RenderLaidOutSize createRenderObject(BuildContext context) =>
      _RenderLaidOutSize(onLayout);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLaidOutSize renderObject,
  ) => renderObject.onLayout = onLayout;
}

class _RenderLaidOutSize extends RenderProxyBox {
  _RenderLaidOutSize(this.onLayout);

  ValueSetter<Size> onLayout;

  @override
  void performLayout() {
    super.performLayout();
    if (!size.isEmpty) onLayout(size);
  }
}

// How a part's two widgets fade into each other as it flies, from the hero
// it leaves to the one it flies to: a copy fades out over the first half of
// the way, and one of another shape fades out as the other fades in.
const _kCopyLeaves = Interval(0, .5);
const _kPartLeaves = Interval(0, .3);
const _kPartArrives = Interval(.1, .4);

/// A part's widget [from] the hero a flight leaves and [to] the one it flies
/// to, as [animation] runs between them, each with the size it was last laid
/// out at there, which [sizes] gives, from and to, as the flight lays itself
/// out on each frame. So a part whose widget changes as it flies, such as a
/// message that comes in as its tab collapses, flies at its size now.
///
/// Two of a shape, such as a title in two sizes, are a copy of each other,
/// scaled: each is laid out at its own size and stretched to the part's,
/// and the one the flight leaves fades out over the one it flies to. Two of
/// different shapes, such as a message wrapped to two widths, keep their
/// own lines, so no word jumps from line to line as they fly: each is laid
/// out at its own width, at the part's top and start, and the one the
/// flight leaves fades out as the other fades in. One wider than the part
/// is scaled down to the part's width, so it doesn't stick out of the tab
/// around it.
Widget _buildPartShuttle({
  required Animation<double> animation,
  required Widget from,
  required Widget to,
  required (Size?, Size?) Function() sizes,
}) => LayoutBuilder(
  builder: (context, constraints) {
    final (fromSize, toSize) = sizes();
    return _partShuttleOfSizes(
      animation: animation,
      width: constraints.maxWidth,
      from: from,
      fromSize: fromSize,
      to: to,
      toSize: toSize,
    );
  },
);

Widget _partShuttleOfSizes({
  required Animation<double> animation,
  required double width,
  required Widget from,
  required Size? fromSize,
  required Widget to,
  required Size? toSize,
}) {
  if (_ofAShape(fromSize, toSize)) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _laidOutAt(toSize, to, BoxFit.fill),
        FadeTransition(
          opacity: _Eased(animation, _kCopyLeaves, fadesOut: true),
          child: _laidOutAt(fromSize, from, BoxFit.fill),
        ),
      ],
    );
  }
  return Stack(
    fit: StackFit.expand,
    children: [
      FadeTransition(
        opacity: _Eased(animation, _kPartArrives),
        child: _laidOutAt(toSize, to, _fitIn(width, toSize)),
      ),
      FadeTransition(
        opacity: _Eased(animation, _kPartLeaves, fadesOut: true),
        child: _laidOutAt(fromSize, from, _fitIn(width, fromSize)),
      ),
    ],
  );
}

// How a part's widget laid out at [size] fits the part, [width] wide: as it
// is, or, where it's wider than the part, scaled down to the part's width.
BoxFit _fitIn(double width, Size? size) =>
    size != null && size.width > width ? BoxFit.fitWidth : BoxFit.none;

// Whether parts of sizes [a] and [b] are of about one shape, as a copy of
// each other scaled is. Unknown sizes count as one.
bool _ofAShape(Size? a, Size? b) {
  if (a == null || b == null || a.isEmpty || b.isEmpty) return true;
  return (a.aspectRatio / b.aspectRatio - 1).abs() < .1;
}

// [child] laid out at [size]'s width, as tall as it is at that width, and
// fitted to the part by [fit]. Not at [size]'s height, which may be a frame
// behind: as a part's widget changes mid-flight, such as to a message of two
// lines, its hero lays out anew after its flight may have on that frame.
Widget _laidOutAt(Size? size, Widget child, BoxFit fit) => size == null
    ? child
    : FittedBox(
        fit: fit,
        alignment: AlignmentDirectional.topStart,
        clipBehavior: Clip.none,
        child: SizedBox(width: size.width, child: child),
      );
