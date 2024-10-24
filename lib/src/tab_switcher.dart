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

library tab_switcher;

import 'dart:collection';
import 'dart:math';

import 'package:animated_reorderable/animated_reorderable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hero_here/hero_here.dart';
import 'package:tab_switcher/src/util/responsiveness.dart';
import 'package:tab_switcher/src/widget/remove_tab_button.dart';

import 'util/animation_context.dart';
import 'util/hero_tab_helper.dart';
import 'util/sliver_grid_delegate_decorator.dart';
import 'util/model_widget_builder.dart';
import 'widget/fitted_tab.dart';

part '_tab_switcher_model.dart';
part 'tab_switcher_controller.dart';
part 'widget/_tab_thumbnails_grid.dart';
part 'widget/_expanded_tab.dart';

const kExpandedTabPageViewportFraction = 1.1;
const kDefaultThumbnailsGridCrossAxisSpacing = 8.0;
const kDefaultThumbnailsGridMainAxisSpacing = 8.0;
const kThumbsGridScaleWhenExpanded = 0.9;
const kThumbsGridOpacityWhenExpanded = 0.0;

class TabSwitcher<T> extends StatefulWidget {
  final TabSwitcherController<T> controller;
  final ModelWidgetBuilder<T> tabBuilder;
  late final ModelWidgetBuilder<T> removeTabButtonBuilder;
  final EdgeInsets? thumbnailsGridPadding;
  final SliverGridDelegate? thumbnailsGridDelegate;
  final ModelWidgetBuilder<T> tabThumbnailBuilder;
  final Duration thumbnailsMotionAnimationDuration;
  final Curve thumbnailsMotionAnimationCurve;
  final ScrollBehavior? scrollBehavior;
  final Decoration thumbnailDecoration;
  final Decoration expandedTabDecoration;

  TabSwitcher.builder({
    super.key,
    TabSwitcherController<T>? controller,
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
  })  : controller = controller ?? TabSwitcherController<T>(),
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
  State<TabSwitcher> createState() => _TabSwitcherState<T>();
}

class _TabSwitcherState<T> extends State<TabSwitcher<T>>
    with Responsiveness, TickerProviderStateMixin {
  final _thumbnailsGridKey = GlobalKey<_TabThumbnailsGridState<T>>();
  final _expandedTabKey = GlobalKey<_ExpandedTabState<T>>();

  TabSwitcherController<T> get controller => widget.controller;

  bool get expanded => controller.mode == TabSwitcherMode.expanded;

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

  void _handleModeChanged(TabSwitcherMode _) => setState(() {});

  Widget _build(
    BuildContext context,
    SliverGridDelegate thumbnailsGridDelegate,
  ) =>
      HeroHereSwitcher(
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