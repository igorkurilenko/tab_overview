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

library tab_overview;

import 'dart:collection';
import 'dart:math';

import 'package:animated_reorderable/animated_reorderable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hero_here/hero_here.dart';
import 'package:tab_overview/src/util/responsiveness.dart';
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
  /// This function allows customization of each tab’s appearance in the overview grid,
  /// by wrapping the main content of the tab with a [FittedTab].
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
    TabOverviewController<T>? controller,
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
  })  : controller = controller ?? TabOverviewController<T>(),
        thumbnailDecoration = thumbnailDecoration ?? const BoxDecoration(),
        expandedTabDecoration = expandedTabDecoration ?? const BoxDecoration(),
        tabThumbnailBuilder = tabThumbnailBuilder ??
            ((context, tab) => FittedTab(child: tabBuilder(context, tab))) {
    this.removeTabButtonBuilder = removeTabButtonBuilder ??
        ((context, tab) => RemoveTabButton(
              controller: this.controller,
              tab: tab,
            ));
  }

  @override
  State<TabOverview> createState() => _TabOverviewState<T>();
}

class _TabOverviewState<T> extends State<TabOverview<T>>
    with Responsiveness, TickerProviderStateMixin {
  final _thumbnailsGridKey = GlobalKey<_TabThumbnailsGridState<T>>();
  final _expandedTabKey = GlobalKey<_ExpandedTabState<T>>();

  TabOverviewController<T> get controller => widget.controller;

  bool get expanded => controller.mode == TabOverviewMode.expanded;

  @override
  void initState() {
    super.initState();
    controller._setThumbnailsGridKey(_thumbnailsGridKey);
    controller._setExpandedTabKey(_expandedTabKey);
    controller.addModeChangedListener(_handleModeChanged);
  }

  @override
  void dispose() {
    controller.removeModeChangedListener(_handleModeChanged);
    super.dispose();
  }

  @override
  Widget buildLarge(BuildContext context) => _build(
        context,
        widget.thumbnailsGridDelegate ??
            SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: constraints!.maxWidth / constraints!.maxHeight,
              mainAxisSpacing: kDefaultThumbnailsGridMainAxisSpacing,
              crossAxisSpacing: kDefaultThumbnailsGridCrossAxisSpacing,
            ),
      );

  @override
  Widget buildMedium(BuildContext context) => _build(
        context,
        widget.thumbnailsGridDelegate ??
            SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: constraints!.maxWidth / constraints!.maxHeight,
              mainAxisSpacing: kDefaultThumbnailsGridMainAxisSpacing,
              crossAxisSpacing: kDefaultThumbnailsGridCrossAxisSpacing,
            ),
      );

  @override
  Widget buildSmall(BuildContext context) => _build(
        context,
        widget.thumbnailsGridDelegate ??
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              mainAxisSpacing: kDefaultThumbnailsGridMainAxisSpacing,
              crossAxisSpacing: kDefaultThumbnailsGridCrossAxisSpacing,
            ),
      );

  @override
  Widget buildExtraSmall(BuildContext context) => const Placeholder();

  void _handleModeChanged(TabOverviewMode _) => setState(() {});

  Widget _build(
    BuildContext context,
    SliverGridDelegate thumbnailsGridDelegate,
  ) =>
      HeroHereSwitcher(
        layoutBuilder: (child, sky) => Stack(
          children: [child, sky],
        ),
        child: Stack(
          children: [
            _TabThumbnailsGrid(
              key: _thumbnailsGridKey,
              controller: controller,
              thumbnailsGridDelegate: thumbnailsGridDelegate,
              tabThumbBuilder: widget.tabThumbnailBuilder,
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
            if (expanded)
              _ExpandedTab(
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
