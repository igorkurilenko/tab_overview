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

// TODO: debug removing during expanding

library;

import 'dart:collection';
import 'dart:math';

import 'package:animated_reorderable/animated_reorderable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hero_here/hero_here.dart';
import 'package:tab_overview/src/widget/remove_tab_button.dart';

import 'util/animation_context.dart';
import 'util/hero_tab_helper.dart';
import 'util/sliver_grid_delegate_decorator.dart';
import 'util/model_widget_builder.dart';
import 'widget/fitted_tab.dart';

part '_tab_overview_model.dart';
part 'tab_overview_controller.dart';
part 'widget/_tab_thumbnails_grid.dart';
part 'widget/_expanded_tab.dart';
part 'widget/_tab_transitions.dart';

const kExpandedTabPageViewportFraction = 1.1;
const kDefaultThumbnailsGridCrossAxisSpacing = 8.0;
const kDefaultThumbnailsGridMainAxisSpacing = 8.0;
const kThumbsGridScaleWhenExpanded = 0.9;
const kThumbsGridOpacityWhenExpanded = 0.0;

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
  /// If not provided, a default [RemoveTabButton] is used, allowing tabs to be removed.
  late final ModelWidgetBuilder<T> removeTabButtonBuilder;

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
  /// By default, it shows what [tabBuilder] builds in a [FittedTab].
  final ModelWidgetBuilder<T> tabThumbnailBuilder;

  /// Duration of the animation for transitions within the thumbnails grid.
  ///
  /// This duration applies when tabs change positions, such as during reordering.
  final Duration thumbnailsMotionAnimationDuration;

  /// Curve of the animation for transitions within the thumbnails grid.
  ///
  /// Controls the speed and motion style of animations affecting the thumbnails grid.
  final Curve thumbnailsMotionAnimationCurve;

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

  /// Constructor to create a customizable [TabOverview] with various builders and configurations.
  ///
  /// - [controller] manages the state and behavior of the widget.
  /// - [tabBuilder] defines the main content for each tab.
  /// - [removeTabButtonBuilder] allows customization of the remove button.
  /// - [thumbnailsGridPadding] sets padding around the thumbnails grid.
  /// - [thumbnailsGridDelegate] customizes the grid layout for thumbnails.
  /// - [tabThumbnailBuilder] customizes each thumbnail in overview mode.
  /// - [thumbnailsMotionAnimationDuration] sets the duration for animations.
  /// - [thumbnailsMotionAnimationCurve] sets the animation curve.
  /// - [scrollBehavior] configures input device interactions.
  /// - [thumbnailDecoration] and [expandedTabDecoration] allow styling for each mode.
  TabOverview.builder({
    super.key,
    required this.controller,
    required this.tabBuilder,
    ModelWidgetBuilder<T>? removeTabButtonBuilder,
    this.thumbnailsGridPadding,
    this.thumbnailsGridDelegate,
    ModelWidgetBuilder<T>? tabThumbnailBuilder,
    this.thumbnailsMotionAnimationDuration = const Duration(milliseconds: 350),
    this.thumbnailsMotionAnimationCurve = Curves.easeInOut,
    this.scrollBehavior,
    Decoration? thumbnailDecoration,
    Decoration? expandedTabDecoration,
  }) : thumbnailDecoration = thumbnailDecoration ?? const BoxDecoration(),
       expandedTabDecoration = expandedTabDecoration ?? const BoxDecoration(),
       tabThumbnailBuilder =
           tabThumbnailBuilder ??
           ((context, tab) => FittedTab(child: tabBuilder(context, tab))) {
    this.removeTabButtonBuilder =
        removeTabButtonBuilder ??
        ((context, tab) => RemoveTabButton(controller: controller, tab: tab));
  }

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

  void _attach(TabOverviewController<T> controller) {
    controller._setThumbnailsGridKey(_thumbnailsGridKey);
    controller._setExpandedTabKey(_expandedTabKey);
    controller.addModeChangedListener(_handleModeChanged);
  }

  void _detach(TabOverviewController<T> controller) {
    controller.removeModeChangedListener(_handleModeChanged);
    // A new overview may have taken the controller over already, such as
    // when this one is replaced by one with another key.
    if (controller._thumbnailsGridKey == _thumbnailsGridKey) {
      controller._setThumbnailsGridKey(null);
    }
    if (controller._expandedTabKey == _expandedTabKey) {
      controller._setExpandedTabKey(null);
    }
  }

  void _handleModeChanged(TabOverviewMode _) => setState(() {});

  // Wider than 900: 4 columns, wider than 600: 3, otherwise 2.
  SliverGridDelegate _thumbnailsGridDelegateFor(BoxConstraints constraints) =>
      widget.thumbnailsGridDelegate ??
      switch (constraints.maxWidth) {
        > 600 => SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: constraints.maxWidth > 900 ? 4 : 3,
          childAspectRatio: constraints.maxWidth / constraints.maxHeight,
          mainAxisSpacing: kDefaultThumbnailsGridMainAxisSpacing,
          crossAxisSpacing: kDefaultThumbnailsGridCrossAxisSpacing,
        ),
        _ => const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          mainAxisSpacing: kDefaultThumbnailsGridMainAxisSpacing,
          crossAxisSpacing: kDefaultThumbnailsGridCrossAxisSpacing,
        ),
      };

  @override
  Widget build(BuildContext context) => HeroHereSwitcher(
    // Only a mode change moves the heroes. Any other rebuild, such as the
    // parent's, shows the new child in place, with no snapshot.
    switchKey: controller.mode,
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
            controller: controller,
            thumbnailsGridDelegate: _thumbnailsGridDelegateFor(constraints),
            tabThumbnailBuilder: widget.tabThumbnailBuilder,
            removeTabButtonBuilder: widget.removeTabButtonBuilder,
            thumbnailDecoration: widget.thumbnailDecoration,
            expandedTabDecoration: widget.expandedTabDecoration,
            scrollBehavior: widget.scrollBehavior,
            thumbnailsGridPadding: widget.thumbnailsGridPadding,
            thumbnailsMotionAnimationDuration:
                widget.thumbnailsMotionAnimationDuration,
            thumbnailsMotionAnimationCurve:
                widget.thumbnailsMotionAnimationCurve,
          ),
        ),
        if (expanded)
          _ExpandedTab<T>(
            key: _expandedTabKey,
            controller: controller,
            tabBuilder: widget.tabBuilder,
            removeTabButtonBuilder: widget.removeTabButtonBuilder,
            scrollBehavior: widget.scrollBehavior,
            thumbnailDecoration: widget.thumbnailDecoration,
            expandedTabDecoration: widget.expandedTabDecoration,
          ),
      ],
    ),
  );
}
