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

library;

import 'dart:collection';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:animated_reorderable/animated_reorderable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:hero_here/hero_here.dart';
import 'package:tab_overview/src/widget/remove_tab_button.dart';

import 'util/model_widget_builder.dart';
import 'widget/fitted_tab.dart';

part '_overview_views.dart';
part '_mode_switch.dart';
part '_tab_flights.dart';
part 'tab_decoration.dart';
part 'tab_transition.dart';
part '_tab_overview_model.dart';
part 'tab_overview_controller.dart';
part 'util/tab_flight.dart';
part 'widget/_tab_heroes.dart';
part 'widget/_tab_thumbnails_grid.dart';
part 'widget/_expanded_tab.dart';
part 'widget/_pull_to_collapse.dart';
part 'widget/_tab_transitions.dart';
part 'widget/_tab_zoom.dart';
part 'widget/tab_hero.dart';

const _kExpandedTabPageViewportFraction = 1.1;
const _kDefaultThumbnailsGridCrossAxisSpacing = 8.0;
const _kDefaultThumbnailsGridMainAxisSpacing = 8.0;
const _kThumbsGridScaleWhenExpanded = 0.9;
const _kThumbsGridOpacityWhenExpanded = 0.0;

/// Builds a thumbnail in the grid, with its close button, as it looks while
/// it's held to be moved, around [thumbnail], from [animation], which runs
/// from 0 to 1 as the thumbnail is picked up and back to 0 as it's let go.
///
/// It's called for thumbnails at rest too, with [animation] at 0, where what
/// it builds should look as [thumbnail] does. So the widgets around a
/// thumbnail stay the same, and it keeps its State, as it's picked up and
/// let go, and a part of it, such as an avatar, can follow [animation]
/// through an inherited widget the builder puts around it.
///
/// It's called as the thumbnail builds, not on every frame, so it gets an
/// animation rather than its values, which a [ScaleTransition], a
/// [FadeTransition] or an [AnimatedBuilder] follows.
typedef HeldThumbnailBuilder<T> = Widget Function(
  BuildContext context,
  T tab,
  Widget thumbnail,
  Animation<double> animation,
);

/// A tab switcher: the tabs a [TabOverviewController] holds show as live
/// thumbnails in a grid, and [TabOverviewController.expand] zooms one into a
/// full page, where a swipe turns to the next tab.
///
/// Build it with [TabOverview.builder], whose [tabBuilder] builds each tab's
/// page. The grid shows that page, scaled down by a [FittedTab], as the
/// tab's thumbnail, unless [tabThumbnailBuilder] builds one of its own. A
/// long press drags a thumbnail to a new place, and a tab closes with its
/// close button or a swipe of its thumbnail, unless [isTabReorderable] or
/// [isTabRemovable] says no.
///
/// A tab's page is built anew as it zooms in or out, so keep what should
/// carry over, such as a scroll offset or typed text, in the tab object.
class TabOverview<T> extends StatefulWidget {
  /// The tabs, which one is active, and whether the grid or the active
  /// tab's page shows. Its methods add, remove, expand and collapse tabs.
  final TabOverviewController<T> controller;

  /// Builds a tab's page, which shows full size while the tab is expanded.
  ///
  /// Unless [tabThumbnailBuilder] builds one of its own, the grid shows the
  /// page, scaled down by a [FittedTab], as the tab's thumbnail. The page is
  /// built anew as the tab zooms in or out.
  final ModelWidgetBuilder<T> tabBuilder;

  /// Builds the close button over the thumbnail of a tab that
  /// [isTabRemovable] lets the user remove.
  ///
  /// If null, a [RemoveTabButton] removes the tab with
  /// [TabOverviewController.remove]. Return a [RemoveTabButton] with an
  /// `onPressed` of your own to keep its look and run code of your own
  /// first, such as asking.
  final ModelWidgetBuilder<T>? removeTabButtonBuilder;

  /// The space around the grid of thumbnails, inside its scroll view, so it
  /// scrolls with them.
  ///
  /// If null, the grid keeps clear of the safe area at its top and bottom,
  /// as a [GridView] does.
  final EdgeInsets? thumbnailsGridPadding;

  /// How the grid lays out its thumbnails: how many columns, how far apart,
  /// and in what shape.
  ///
  /// If null, the grid has 2 columns of thumbnails 0.7 as wide as they're
  /// tall, or, on an overview wider than 600 pixels, 3 columns of
  /// thumbnails in the overview's shape, and wider than 900, 4, all 8
  /// pixels apart.
  final SliverGridDelegate? thumbnailsGridDelegate;

  /// Builds a tab's thumbnail of the app's own, such as a card with the
  /// tab's title, in place of its page scaled down by a [FittedTab], as when
  /// it's null.
  ///
  /// As the tab zooms in, its thumbnail fades into its page, and back as it
  /// zooms out. On the way, the page shows as it would in a window of the
  /// zooming tab's shape, at the overview's width: its bars at its top and
  /// bottom, and its text wrapped as on the page. [TabHero]s fly parts of
  /// the thumbnail, such as its title, to their places on the page.
  final ModelWidgetBuilder<T>? tabThumbnailBuilder;

  /// How thumbnails move to new places in the grid, as when tabs are added,
  /// removed or reordered: 350 ms along [Curves.easeInOut] by default.
  final TabTransition thumbnailsMotion;

  /// How the grid of thumbnails and the pages scroll: which pointers drag
  /// them, and their physics and scrollbars. A pull with [pullToCollapse]
  /// takes the same pointers.
  ///
  /// If null, the [ScrollConfiguration] around the overview sets it. On
  /// desktop and the web, give it [ScrollBehavior.dragDevices] that include
  /// `PointerDeviceKind.mouse`, so a mouse drag swipes between pages and
  /// pulls a page down.
  final ScrollBehavior? scrollBehavior;

  /// How each thumbnail looks in the grid, such as its color, its rounded
  /// corners or a shadow. A thumbnail clips to it.
  ///
  /// As a tab zooms, its decoration turns from this into
  /// [expandedTabDecoration], or back, and [tabDecorationBuilder] builds on
  /// it: by default, it casts a soft shadow in its decoration's shape, which
  /// grows as the tab leaves its place and fades as it lands, so it reads
  /// apart from the grid it flies over. An empty [BoxDecoration] by default.
  final Decoration thumbnailDecoration;

  /// How the expanded tab's page looks, such as its color, or square
  /// corners where thumbnails have rounded ones. The page clips to it. An
  /// empty [BoxDecoration] by default.
  final Decoration expandedTabDecoration;

  /// Builds each tab's decoration, at rest and as it zooms or its page is
  /// pulled, from the one between [thumbnailDecoration] and
  /// [expandedTabDecoration] where the tab is, and from how far it is on
  /// its way, how high it's lifted and which way it heads. If null,
  /// [TabDecorations.lifted].
  ///
  /// A builder of the app's own can build on a ready-made one, such as to
  /// cast a shadow in each tab's color, where tabs have one:
  ///
  /// ```dart
  /// tabDecorationBuilder: (context, tab, decoration, zoom) =>
  ///     TabDecorations.lifted(
  ///       shadows: [
  ///         BoxShadow(
  ///           color: tab.color.withValues(alpha: .4),
  ///           blurRadius: 32,
  ///           offset: const Offset(0, 16),
  ///         ),
  ///       ],
  ///     )(context, tab, decoration, zoom),
  /// ```
  final TabDecorationBuilder<T>? tabDecorationBuilder;

  /// Whether the expanded tab can be pulled down to collapse it, as in
  /// hero_here's show details example.
  ///
  /// A tab is pulled by a drag on a part of it outside its scroll views,
  /// such as an app bar above a list, or anywhere on a tab without one. A
  /// drag that starts in a vertical scroll view never pulls the tab,
  /// whatever the pointer: it scrolls the view, unless the view doesn't
  /// scroll with that pointer, as a list doesn't with a mouse by default.
  /// So a list never pulls its tab, whether it's at its top or, as a
  /// chat's list is, at its bottom. As it's pulled, a tab shrinks, its
  /// decoration turns toward [thumbnailDecoration], and it's lifted off
  /// the grid, as a tab is while it zooms, so it casts the same shadow by
  /// default, which it takes along as it collapses. Let go once it's
  /// pulled 50 pixels, or while it moves down fast, and it collapses from
  /// where it is, at the speed it had. Otherwise it goes back.
  ///
  /// Off by default.
  final bool pullToCollapse;

  /// Whether the user may remove a tab: its thumbnail shows a close button
  /// and swipes away to the left.
  ///
  /// If null, every tab may be removed. [TabOverviewController.remove]
  /// removes any tab, whatever this says.
  final bool Function(T tab)? isTabRemovable;

  /// Whether the user may drag a tab's thumbnail to a new place in the grid.
  ///
  /// If null, every tab may be moved.
  final bool Function(T tab)? isTabReorderable;

  /// Makes the recognizer of the gesture that picks a thumbnail up to move
  /// it: a long press, if null.
  ///
  /// One of the app's own can pick a thumbnail up sooner, or only by a part
  /// of it, such as an avatar, by the pointers it allows
  /// ([GestureRecognizer.isPointerAllowed]). This one picks a thumbnail up
  /// after 250 ms. The multi-drag recognizers come from
  /// `package:flutter/gestures.dart`, which `material.dart` doesn't export:
  ///
  /// ```dart
  /// dragGestureRecognizerFactory: (context) =>
  ///     DelayedMultiDragGestureRecognizer(
  ///       delay: const Duration(milliseconds: 250),
  ///     )..gestureSettings = MediaQuery.maybeGestureSettingsOf(context),
  /// ```
  final MultiDragGestureRecognizer Function(BuildContext context)?
  dragGestureRecognizerFactory;

  /// Builds each thumbnail in the grid as it looks while it's held to be
  /// moved: if null, it scales up a little and fades a little, as a thumbnail
  /// swiped away to close it always does.
  ///
  /// This one scales a held thumbnail up more, and doesn't fade it:
  ///
  /// ```dart
  /// heldThumbnailBuilder: (context, tab, thumbnail, animation) =>
  ///     ScaleTransition(
  ///       scale: animation.drive(Tween(begin: 1.0, end: 1.1)),
  ///       child: thumbnail,
  ///     ),
  /// ```
  final HeldThumbnailBuilder<T>? heldThumbnailBuilder;

  bool _isRemovable(T tab) => isTabRemovable?.call(tab) ?? true;

  // How a tab clips its content to [decoration], which tabDecorationBuilder
  // built: anti-aliased only if it, or either decoration it's built from,
  // rounds or shapes the tab, as a path clip with anti-aliasing costs more
  // than a square one. Always some clip, so a change of it changes no
  // widget around the tab's content.
  Clip _tabClip(Decoration decoration) =>
      _isRounded(thumbnailDecoration) ||
          _isRounded(expandedTabDecoration) ||
          _isRounded(decoration)
      ? Clip.antiAlias
      : Clip.hardEdge;

  static bool _isRounded(Decoration decoration) => switch (decoration) {
    // The tab clips to the decoration under the shadows.
    _LiftedDecoration(decoration: final under) => _isRounded(under),
    BoxDecoration(:final shape, :final borderRadius) =>
      shape != BoxShape.rectangle ||
          (borderRadius != null &&
              borderRadius != BorderRadius.zero &&
              borderRadius != BorderRadiusDirectional.zero),
    _ => true,
  };

  bool _isReorderable(T tab) => isTabReorderable?.call(tab) ?? true;

  /// Creates a tab switcher whose [tabBuilder] builds each tab's page, which
  /// the grid also shows, scaled down, as the tab's thumbnail, unless
  /// [tabThumbnailBuilder] builds one of its own.
  const TabOverview.builder({
    super.key,
    required this.controller,
    required this.tabBuilder,
    this.removeTabButtonBuilder,
    this.thumbnailsGridPadding,
    this.thumbnailsGridDelegate,
    this.tabThumbnailBuilder,
    this.thumbnailsMotion = const TabTransition(
      duration: Duration(milliseconds: 350),
    ),
    this.scrollBehavior,
    Decoration? thumbnailDecoration,
    Decoration? expandedTabDecoration,
    this.tabDecorationBuilder,
    this.pullToCollapse = false,
    this.isTabRemovable,
    this.isTabReorderable,
    this.dragGestureRecognizerFactory,
    this.heldThumbnailBuilder,
  }) : thumbnailDecoration = thumbnailDecoration ?? const BoxDecoration(),
       expandedTabDecoration = expandedTabDecoration ?? const BoxDecoration();

  // What removeTabButtonBuilder builds, or the default button.
  Widget _buildRemoveTabButton(BuildContext context, T tab) =>
      removeTabButtonBuilder?.call(context, tab) ??
      RemoveTabButton(onPressed: () => controller.remove(tab));

  // What tabDecorationBuilder builds for [tab] at [zoom], or
  // TabDecorations.lifted, from the decoration between the thumbnail's and
  // the page's where the tab is.
  Decoration _buildTabDecoration(BuildContext context, T tab, TabZoom zoom) =>
      (tabDecorationBuilder ?? _liftedByDefault)(
        context,
        tab,
        Decoration.lerp(
          thumbnailDecoration,
          expandedTabDecoration,
          zoom.expansion,
        )!,
        zoom,
      );

  // What tabThumbnailBuilder builds, or the tab's content in a FittedTab.
  Widget _buildTabThumbnail(BuildContext context, T tab) =>
      tabThumbnailBuilder?.call(context, tab) ??
      FittedTab(child: tabBuilder(context, tab));

  @override
  State<TabOverview<T>> createState() => _TabOverviewState<T>();
}

class _TabOverviewState<T> extends State<TabOverview<T>> {
  final _thumbnailsGridKey = GlobalKey<_TabThumbnailsGridState<T>>();
  final _expandedTabKey = GlobalKey<_ExpandedTabState<T>>();

  TabOverviewController<T> get controller => widget.controller;

  bool get expanded => controller.mode == TabOverviewMode.expanded;

  @override
  void initState() {
    super.initState();
    _attach(controller);
  }

  @override
  void didUpdateWidget(TabOverview<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != controller) {
      _detach(oldWidget.controller);
      _attach(controller);
    }
  }

  @override
  void dispose() {
    _detach(controller);
    super.dispose();
  }

  // The grid and the pages attach themselves to the controller.
  void _attach(TabOverviewController<T> controller) {
    controller.addModeChangedListener(_handleModeChanged);
  }

  void _detach(TabOverviewController<T> controller) {
    controller.removeModeChangedListener(_handleModeChanged);
  }

  // How many times the controller told of a mode change, to the mode it was
  // in too. With the mode, it keys the switch, so a change and a change
  // back in the same frame run one too: the flights asked for wait for it.
  var _modeChanges = 0;

  void _handleModeChanged(TabOverviewMode _) => setState(() => _modeChanges++);

  BoxConstraints? _defaultGridDelegateConstraints;
  SliverGridDelegate? _defaultGridDelegate;

  // The same delegate for the same size, so a mode change, which builds the
  // grid again, keeps its items.
  SliverGridDelegate _thumbnailsGridDelegateFor(BoxConstraints constraints) {
    if (widget.thumbnailsGridDelegate case final delegate?) return delegate;
    if (constraints != _defaultGridDelegateConstraints) {
      _defaultGridDelegateConstraints = constraints;
      _defaultGridDelegate = _defaultThumbnailsGridDelegateFor(constraints);
    }
    return _defaultGridDelegate!;
  }

  // Wider than 900: 4 columns, wider than 600: 3, otherwise 2.
  SliverGridDelegate _defaultThumbnailsGridDelegateFor(
    BoxConstraints constraints,
  ) => switch (constraints.maxWidth) {
    > 600 => SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: constraints.maxWidth > 900 ? 4 : 3,
      childAspectRatio: constraints.maxWidth / constraints.maxHeight,
      mainAxisSpacing: _kDefaultThumbnailsGridMainAxisSpacing,
      crossAxisSpacing: _kDefaultThumbnailsGridCrossAxisSpacing,
    ),
    _ => const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.7,
      mainAxisSpacing: _kDefaultThumbnailsGridMainAxisSpacing,
      crossAxisSpacing: _kDefaultThumbnailsGridCrossAxisSpacing,
    ),
  };

  @override
  Widget build(BuildContext context) => HeroHereSwitcher(
    // Only a mode change moves the heroes. Any other rebuild, such as the
    // parent's, shows the new child in place, with no snapshot. A new
    // controller in the same mode shows in place too.
    switchKey: (controller.mode, _modeChanges),
    // Tabs and their flights take the overview's size, not the screen's.
    layoutBuilder: (child, sky) => LayoutBuilder(
      builder: (context, constraints) => TabContentSize(
        size: constraints.biggest,
        child: Stack(children: [child, sky]),
      ),
    ),
    child: Stack(
      children: [
        // Only the grid depends on the overview's size. So a window resize
        // or the keyboard rebuilds the grid, not the switcher, which would
        // run a switch and hide the tabs behind a snapshot.
        LayoutBuilder(
          builder: (context, constraints) => _TabThumbnailsGrid<T>(
            key: _thumbnailsGridKey,
            overview: widget,
            gridDelegate: _thumbnailsGridDelegateFor(constraints),
          ),
        ),
        if (expanded) _ExpandedTab<T>(key: _expandedTabKey, overview: widget),
      ],
    ),
  );
}
