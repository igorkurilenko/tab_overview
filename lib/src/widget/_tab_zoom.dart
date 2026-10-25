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

// How far the thumbnail fades out, and the page fades in, over the way from
// the one to the other.
const _kThumbnailFadeOut = Interval(0, 0.3);
const _kPageFadeIn = Interval(0.2, 0.8);

/// A tab with a thumbnail of the app's own as it flies between the two: the
/// tab's decoration, between the thumbnail's and the page's, around its page
/// and its thumbnail.
///
/// The page is laid out at the overview's width and the zoom's shape, so its
/// bars stay at its top and bottom, and scaled to the zoom; the thumbnail at
/// the size the grid gave it, scaled to the zoom's width at its top. As far
/// as [pageShown] shows the page, the thumbnail fades into it, even where
/// the two are of one size, as on a watch. The tab's [TabHero]s fly on their
/// own, and hide here while they do.
class _TabZoom<T> extends StatelessWidget {
  const _TabZoom({
    required this.overview,
    required this.entry,
    required this.pageShown,
  });

  final TabOverview<T> overview;
  final _TabEntry<T> entry;
  final Animation<double> pageShown;

  @override
  Widget build(BuildContext context) => _InTabShuttle(
    entry: entry,
    child: _TabPresence(
      animation: entry.presence ?? kAlwaysCompleteAnimation,
      curve: entry.presenceCurve,
      child: _TabDecoration<T>(
        overview: overview,
        entry: entry,
        idleDecoration: overview.expandedTabDecoration,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FadeTransition(
              opacity: _Eased(pageShown, _kPageFadeIn),
              child: _AtTabWidth(
                child: overview.tabBuilder(context, entry.tab),
              ),
            ),
            FadeTransition(
              opacity: _Eased(pageShown, _kThumbnailFadeOut, fadesOut: true),
              child: _atItsSize(
                entry.thumbnailSize,
                overview._buildTabThumbnail(context, entry.tab),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // [thumbnail] laid out at [size] and scaled to the width it's given, at
  // its top, so a list row keeps its layout as the zoom grows. Without a
  // size, as for a tab the grid hasn't laid out, it fills what it's given.
  static Widget _atItsSize(Size? size, Widget thumbnail) => size == null
      ? thumbnail
      : FittedBox(
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          clipBehavior: Clip.hardEdge,
          child: SizedBox.fromSize(size: size, child: thumbnail),
        );
}

/// How far the flight of [entry]'s tab shows its page rather than its
/// thumbnail, from 0 to 1: its [TabFlight.pageShown], or, without a flight,
/// how far [parent], the flight's animation, is on its way to the page.
class _PageShown extends Animation<double>
    with AnimationWithParentMixin<double> {
  @override
  final Animation<double> parent;

  final _TabEntry<Object?> entry;

  // Whether the flight flies to the page, rather than from it.
  final bool toPage;

  _PageShown(this.parent, this.entry, {required this.toPage});

  @override
  double get value =>
      entry.flight?.pageShown ?? (toPage ? parent.value : 1 - parent.value);
}

/// Lays [child], a tab's page, out at the width of the `TabOverview` it's
/// in, and as tall as gives it the shape of the space it's given, and scales
/// it to that space: the page as a window of that shape would show it, with
/// its bars at its top and bottom, and its text wrapped as on the page.
class _AtTabWidth extends SingleChildRenderObjectWidget {
  const _AtTabWidth({super.child});

  @override
  _RenderAtTabWidth createRenderObject(BuildContext context) =>
      _RenderAtTabWidth(_widthOf(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderAtTabWidth renderObject,
  ) => renderObject.width = _widthOf(context);

  static double _widthOf(BuildContext context) =>
      (TabContentSize.maybeOf(context) ?? MediaQuery.sizeOf(context)).width;
}

class _RenderAtTabWidth extends RenderProxyBox {
  _RenderAtTabWidth(this._width);

  double _width;

  set width(double value) {
    if (value == _width) return;
    _width = value;
    markNeedsLayout();
  }

  double get _scale => _width > 0 ? size.width / _width : 0;

  Matrix4 get _transform => Matrix4.diagonal3Values(_scale, _scale, 1);

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    size = constraints.biggest;
    final scale = _scale;
    child?.layout(
      BoxConstraints.tight(
        scale > 0 ? Size(_width, size.height / scale) : Size.zero,
      ),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null || _scale == 0) {
      layer = null;
      return;
    }
    layer = context.pushTransform(
      needsCompositing,
      offset,
      _transform,
      (context, offset) => context.paintChild(child, offset),
      oldLayer: layer is TransformLayer ? layer as TransformLayer : null,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      _scale > 0 &&
      result.addWithPaintTransform(
        transform: _transform,
        position: position,
        hitTest: (result, position) =>
            child?.hitTest(result, position: position) ?? false,
      );

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) =>
      transform.multiply(_transform);
}
