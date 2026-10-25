// Copyright 2024 Igor Kurilenko
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

part of 'tab_overview.dart';

/// Builds a tab's decoration as its thumbnail rests in the grid, as its page
/// shows, as it zooms between the two, and as its page is pulled down, from
/// [decoration], the one between the overview's `thumbnailDecoration` and
/// `expandedTabDecoration` where the tab is, which it may give back as it
/// is, change or replace. The tab clips to what it returns.
///
/// It's called on every frame of a zoom or a pull, so it gets [zoom]'s
/// values rather than an animation.
typedef TabDecorationBuilder<T> = Decoration Function(
  BuildContext context,
  T tab,
  Decoration decoration,
  TabZoom zoom,
);

/// Where a tab is on its way between its thumbnail and its page.
@immutable
class TabZoom {
  /// A tab [expansion] of the way from its thumbnail to its page, [lift]ed
  /// as far off the grid, and heading in [direction], such as for a test of
  /// a [TabDecorationBuilder].
  const TabZoom({required this.expansion, required this.lift, this.direction});

  /// How far the tab is from its thumbnail, at 0, to its page, at 1. While
  /// its page is pulled down, how far its decoration is from the
  /// thumbnail's: 0 at a pull of 50 pixels, with the page still 90% of its
  /// size.
  final double expansion;

  /// How far the tab is lifted off the grid: 0 as it rests and 1 halfway
  /// through a zoom, along an arc, so what grows with it, such as a shadow,
  /// grows as the tab leaves its place, fades as it lands, and goes on
  /// smoothly where a flight turns around. A page pulled down is lifted as
  /// far as it's pulled, fully at 50 pixels, and flies on from there.
  final double lift;

  /// Which way the tab heads: to its page, or to its thumbnail, as a page
  /// pulled down does. Null as it rests. A tab sent back mid-flight turns
  /// around, and its direction with it.
  final TabZoomDirection? direction;

  @override
  bool operator ==(Object other) =>
      other is TabZoom &&
      other.expansion == expansion &&
      other.lift == lift &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(expansion, lift, direction);

  @override
  String toString() => 'TabZoom($expansion, $lift, ${direction?.name})';
}

/// Which way a tab zooms.
enum TabZoomDirection {
  /// From its thumbnail to its page.
  expand,

  /// From its page to its thumbnail.
  collapse,
}

// One soft shadow, as hero_here's add to cart example lifts a picture off
// the page.
const _kLiftShadows = [
  BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 12)),
];

final _liftedByDefault = TabDecorations.lifted();

/// Ready-made builders of a tab's decoration, for
/// [TabOverview.tabDecorationBuilder].
abstract final class TabDecorations {
  /// Casts [shadows] under the tab, in its decoration's shape, as high as
  /// it's lifted: they grow from nothing as it leaves its place, are as
  /// given halfway, and fade as it lands. By default, one shadow: 20%
  /// black, blurred 24 pixels and 12 pixels down.
  ///
  /// A [BoxDecoration] gets them ahead of its own [BoxDecoration.boxShadow],
  /// so what this builds from one is a [BoxDecoration] too.
  static TabDecorationBuilder<Object?> lifted({
    List<BoxShadow> shadows = _kLiftShadows,
  }) =>
      (context, tab, decoration, zoom) => _lift(decoration, shadows, zoom.lift);

  // [decoration] over [shadows] as far as the tab is [lift]ed: none at 0,
  // and as given at 1, their colors as opaque and their blurs, spreads and
  // offsets as far. Too low for a shadow to show, just [decoration].
  static Decoration _lift(
    Decoration decoration,
    List<BoxShadow> shadows,
    double lift,
  ) {
    if (lift < .01 || shadows.isEmpty) return decoration;
    final lifted = [
      for (final shadow in shadows)
        BoxShadow(
          color: shadow.color.withValues(alpha: shadow.color.a * lift),
          offset: shadow.offset * lift,
          blurRadius: shadow.blurRadius * lift,
          spreadRadius: shadow.spreadRadius * lift,
          blurStyle: shadow.blurStyle,
        ),
    ];
    return switch (decoration) {
      BoxDecoration(:final boxShadow) => decoration.copyWith(
        boxShadow: [...lifted, ...?boxShadow],
      ),
      _ => _LiftedDecoration(decoration, lifted),
    };
  }

  /// Gives back the decoration as it is: no shadow.
  static TabDecorationBuilder<Object?> flat() => _flat;

  static Decoration _flat(
    BuildContext context,
    Object? tab,
    Decoration decoration,
    TabZoom zoom,
  ) => decoration;
}

/// A tab's [decoration] over [shadows] in its shape, as
/// [TabDecorations.lifted] casts them under a decoration other than a
/// [BoxDecoration], which casts them as its own. The tab clips to
/// [decoration], not to its shadows.
class _LiftedDecoration extends Decoration {
  const _LiftedDecoration(this.decoration, this.shadows);

  final Decoration decoration;
  final List<BoxShadow> shadows;

  @override
  EdgeInsetsGeometry get padding => decoration.padding;

  // A blurred shadow is.
  @override
  bool get isComplex => true;

  @override
  Path getClipPath(Rect rect, TextDirection textDirection) =>
      decoration.getClipPath(rect, textDirection);

  @override
  bool hitTest(Size size, Offset position, {TextDirection? textDirection}) =>
      decoration.hitTest(size, position, textDirection: textDirection);

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _LiftedDecorationPainter(this, onChanged);

  @override
  bool operator ==(Object other) =>
      other is _LiftedDecoration &&
      other.decoration == decoration &&
      listEquals(other.shadows, shadows);

  @override
  int get hashCode => Object.hash(decoration, Object.hashAll(shadows));
}

class _LiftedDecorationPainter extends BoxPainter {
  _LiftedDecorationPainter(this._lifted, VoidCallback? onChanged)
    : _painter = onChanged == null
          ? _lifted.decoration.createBoxPainter()
          : _lifted.decoration.createBoxPainter(onChanged),
      super(onChanged);

  final _LiftedDecoration _lifted;
  final BoxPainter _painter;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final textDirection = configuration.textDirection ?? TextDirection.ltr;
    for (final shadow in _lifted.shadows) {
      // The tab clips to its decoration's path, so its shape has one.
      final path = _lifted.decoration.getClipPath(
        rect.inflate(shadow.spreadRadius),
        textDirection,
      );
      canvas.drawPath(path.shift(shadow.offset), shadow.toPaint());
    }
    _painter.paint(canvas, offset, configuration);
  }

  @override
  void dispose() {
    _painter.dispose();
    super.dispose();
  }
}
