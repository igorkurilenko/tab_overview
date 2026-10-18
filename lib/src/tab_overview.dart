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

import 'package:animated_reorderable/animated_reorderable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hero_here/hero_here.dart';
import 'package:tab_overview/src/widget/remove_tab_button.dart';

import 'util/tab_flight.dart';
import 'util/hero_tab_helper.dart';
import 'util/model_widget_builder.dart';
import 'widget/fitted_tab.dart';

part '_overview_views.dart';
part '_tab_flights.dart';
part 'tab_transition.dart';
part '_tab_overview_model.dart';
part 'tab_overview_controller.dart';
part 'widget/_tab_thumbnails_grid.dart';
part 'widget/_expanded_tab.dart';
part 'widget/_pull_to_collapse.dart';
part 'widget/_tab_transitions.dart';

const _kExpandedTabPageViewportFraction = 1.1;
const _kDefaultThumbnailsGridCrossAxisSpacing = 8.0;
const _kDefaultThumbnailsGridMainAxisSpacing = 8.0;
const _kThumbsGridScaleWhenExpanded = 0.9;
const _kThumbsGridOpacityWhenExpanded = 0.0;

/// The [TabOverview] widget provides a flexible, animated interface for switching between multiple tabs.
/// It supports both overview and expanded modes with customizable animations, decorations, and layouts.
///
/// The widget displays tabs in an overview grid by default, with each tab represented as a thumbnail.
/// Users can switch to expanded mode to view a selected tab in detail.
///
/// Use the [TabOverview] constructor to build a [TabOverview] with custom configurations,
/// including thumbnails layout, padding, animations, and decorations.
class TabOverview<T> extends StatefulWidget {
  /// Manages the state and behavior of the tab overview.
  ///
  /// This controller allows for switching between tabs, setting the active tab,
  /// and switching between overview and expanded modes.
  final TabOverviewController<T> controller;

  /// Builds the main content for each tab when in expanded mode.
  ///
  /// The function takes the context and tab model data, returning a widget that
  /// represents the main content of the tab.
  final ModelWidgetBuilder<T> tabBuilder;

  /// Builder function for the tab's remove (close) button in overview mode.
  ///
  /// If null, a [RemoveTabButton] removes the tab from the controller.
  final ModelWidgetBuilder<T>? removeTabButtonBuilder;

  /// Padding around the thumbnails grid in overview mode.
  ///
  /// Sets the space between the edge of the widget and the grid of thumbnails.
  final EdgeInsets? thumbnailsGridPadding;

  /// Defines the layout of the thumbnails grid, such as column count and spacing.
  ///
  /// This delegate allows customization of the grid structure for displaying
  /// thumbnails in overview mode.
  final SliverGridDelegate? thumbnailsGridDelegate;

  /// Builder function for generating a thumbnail widget for each tab in overview mode.
  ///
  /// This function allows customization of each tab’s appearance in the overview grid.
  /// If null, a thumbnail shows what [tabBuilder] builds in a [FittedTab].
  final ModelWidgetBuilder<T>? tabThumbnailBuilder;

  /// How thumbnails move to new places in the grid, as when tabs are added,
  /// removed or reordered: 350 ms along [Curves.easeInOut] by default.
  final TabTransition thumbnailsMotion;

  /// Scroll behavior configuration for the thumbnails grid and [PageView] used in expanded mode.
  ///
  /// Determines how scrolling interactions are handled for different devices,
  /// including touch and mouse.
  final ScrollBehavior? scrollBehavior;

  /// Decoration for the thumbnail in overview mode.
  ///
  /// Allows customization of the appearance of each tab’s thumbnail,
  /// including background color, border, and shadows.
  final Decoration thumbnailDecoration;

  /// Decoration for the expanded tab in expanded mode.
  ///
  /// Provides styling options for the expanded tab view, such as background color and border.
  final Decoration expandedTabDecoration;

  /// Whether the expanded tab can be pulled down to collapse it, as in
  /// hero_here's show details example.
  ///
  /// A tab is pulled from the top of its vertical scroll view, or from
  /// anywhere on a tab without one. As it's pulled, it shrinks and its
  /// decoration turns toward [thumbnailDecoration]. Let go once it's pulled
  /// 50 pixels, or while it moves down fast, and it collapses from where it
  /// is, at the speed it had. Otherwise it goes back.
  ///
  /// Off by default, as a `RefreshIndicator` at the top of a tab reads the
  /// same pull.
  final bool pullToCollapse;

  /// Whether the user may remove a tab: its thumbnail shows a remove button
  /// and swipes away, and its expanded page shows the remove button too.
  ///
  /// If null, every tab may be removed.
  final bool Function(T tab)? isTabRemovable;

  /// Whether the user may drag a tab's thumbnail to a new place in the grid.
  ///
  /// If null, every tab may be moved.
  final bool Function(T tab)? isTabReorderable;

  bool _isRemovable(T tab) => isTabRemovable?.call(tab) ?? true;

  bool _isReorderable(T tab) => isTabReorderable?.call(tab) ?? true;

  /// Constructor to create a customizable [TabOverview] with various builders and configurations.
  ///
  /// - [controller] manages the state and behavior of the widget.
  /// - [tabBuilder] defines the main content for each tab.
  /// - [removeTabButtonBuilder] allows customization of the remove button.
  /// - [thumbnailsGridPadding] sets padding around the thumbnails grid.
  /// - [thumbnailsGridDelegate] customizes the grid layout for thumbnails.
  /// - [tabThumbnailBuilder] customizes each thumbnail in overview mode.
  /// - [thumbnailsMotion] sets how thumbnails move to new places.
  /// - [scrollBehavior] configures input device interactions.
  /// - [thumbnailDecoration] and [expandedTabDecoration] allow styling for each mode.
  /// - [pullToCollapse] lets the expanded tab be pulled down to collapse it.
  /// - [isTabRemovable] and [isTabReorderable] tell which tabs the user may
  ///   remove or move.
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
    this.pullToCollapse = false,
    this.isTabRemovable,
    this.isTabReorderable,
  }) : thumbnailDecoration = thumbnailDecoration ?? const BoxDecoration(),
       expandedTabDecoration = expandedTabDecoration ?? const BoxDecoration();

  // What removeTabButtonBuilder builds, or the default button.
  Widget _buildRemoveTabButton(BuildContext context, T tab) =>
      removeTabButtonBuilder?.call(context, tab) ??
      RemoveTabButton(onPressed: () => controller.remove(tab));

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
