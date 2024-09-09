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

import 'dart:collection';

import 'package:animated_reorderable/animated_reorderable.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:tab_switcher/src/util/responsiveness.dart';

const kExpandedTabPageViewportFraction = 1.1;
const kDefaultAnimationDuration = Duration(milliseconds: 350);

class TabSwitcher<T> extends StatefulWidget {
  final TabSwitcherController<T> controller;
  final TabSwitcherMode initialMode;
  final EdgeInsets? padding;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final TabSwitcherWidgetBuilder<T> tabThumbnailBuilder;
  final TabSwitcherWidgetBuilder<T> tabBuilder;
  final TabSwitcherWidgetBuilder<T>? removeTabButtonBuilder;
  final Duration animationDuration;

  TabSwitcher.builder({
    super.key,
    TabSwitcherController<T>? controller,
    this.initialMode = TabSwitcherMode.overview,
    this.padding,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    TabSwitcherWidgetBuilder<T>? tabThumbnailBuilder,
    required this.tabBuilder,
    this.removeTabButtonBuilder,
    this.animationDuration = kDefaultAnimationDuration,
  })  : controller = controller ?? TabSwitcherController<T>(),
        tabThumbnailBuilder = tabThumbnailBuilder ??
            ((context, tab) => DefaultTabThumbnail(
                  child: tabBuilder(context, tab),
                ));

  @override
  State<TabSwitcher> createState() => _TabSwitcherState<T>();
}

class _TabSwitcherState<T> extends State<TabSwitcher<T>> with Responsiveness {
  final thumbnailsGridKey = GlobalKey<AnimatedReorderableState>();
  int crossAxisCount = 0;
  late TabSwitcherMode _mode;
  T? activeTab;

  TabSwitcherMode get mode => _mode;
  bool get overviewMode => _mode == TabSwitcherMode.overview;
  bool get expandedMode => _mode == TabSwitcherMode.expanded;
  set mode(TabSwitcherMode value) {
    if (_mode == value) return;
    setState(() => _mode = value);
  }

  List<T> get tabs => controller.tabs;
  int get tabCount => tabs.length;
  bool isTabReorderableAt(int index) => isTabReorderable(tabs[index]);
  bool isTabReorderable(T tab) =>
      tab is ReorderableTab ? tab.reorderable : true;
  bool isTabRemovableAt(int index) => isTabRemovable(tabs[index]);
  bool isTabRemovable(T tab) => tab is RemovableTab ? tab.removable : true;
  bool isTabExpanded(T tab) => expandedMode && tab == activeTab;
  T? ensureActiveTab() =>
      activeTab = activeTab == null || !tabs.contains(activeTab as T)
          ? tabs.lastOrNull
          : activeTab;

  TabSwitcherController<T> get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    controller._initState(this);
  }

  @override
  Widget buildLarge(BuildContext context) {
    return _build(
      context,
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount = 4,
        childAspectRatio: constraints!.maxWidth / constraints!.maxHeight,
        mainAxisSpacing: widget.mainAxisSpacing,
        crossAxisSpacing: widget.crossAxisSpacing,
      ),
    );
  }

  @override
  Widget buildMedium(BuildContext context) => _build(
        context,
        SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount = 3,
          childAspectRatio: constraints!.maxWidth / constraints!.maxHeight,
          mainAxisSpacing: widget.mainAxisSpacing,
          crossAxisSpacing: widget.crossAxisSpacing,
        ),
      );

  @override
  Widget buildSmall(BuildContext context) => _build(
        context,
        SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount = 2,
          childAspectRatio: 0.7,
          mainAxisSpacing: widget.mainAxisSpacing,
          crossAxisSpacing: widget.crossAxisSpacing,
        ),
      );

  @override
  Widget buildExtraSmall(BuildContext context) => const Placeholder();

  Widget _build(
      BuildContext context, SliverGridDelegate thumbnailsGridDelegate) {
    return AnimatedReorderable.grid(
      key: thumbnailsGridKey,
      motionAnimationDuration: widget.animationDuration,
      keyGetter: (index) => ValueKey(tabs[index]),
      onReorder: controller._reorderTabs,
      onSwipeToRemove: controller.removeTabAt,
      reorderableGetter: isTabReorderableAt,
      gridView: GridView.builder(
        padding: widget.padding,
        gridDelegate: thumbnailsGridDelegate,
        itemCount: tabCount,
        itemBuilder: (context, index) => _buildThumbnail(context, tabs[index]),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, T tab) {
    return widget.tabThumbnailBuilder(context, tab);
  }
}

typedef TabSwitcherWidgetBuilder<T> = Widget Function(
    BuildContext context, T tab);
typedef TabSwitcherWidgetAnimatedBuilder<T> = Widget Function(
    BuildContext context, T tab, Animation<double> animation);

enum TabSwitcherMode { expanded, overview }

abstract class ReorderableTab {
  bool get reorderable;
}

abstract class RemovableTab {
  bool get removable;
}

class TabSwitcherController<T> {
  final List<T> _tabs;
  _TabSwitcherState? _state;
  final ValueChanged<T>? onTabExpanded;
  final ValueChanged<T>? onTabCollapsed;
  final VoidCallback? onTabsReordered;
  final ValueChanged<T>? onTabRemoved;

  TabSwitcherController({
    Iterable<T>? initialTabs,
    this.onTabExpanded,
    this.onTabCollapsed,
    this.onTabsReordered,
    this.onTabRemoved,
  }) : _tabs = List<T>.from(initialTabs ?? <T>[]);

  void _initState(_TabSwitcherState<T> state) => _state = state;

  List<T> get tabs => UnmodifiableListView(_tabs);

  bool addTab(
    T newTab, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    // TODO: implement
    return false;
  }

  bool removeTab(
    T tab, {
    Duration duration = const Duration(milliseconds: 350),
  }) =>
      removeTabAt(tabs.indexOf(tab), duration: duration);

  bool removeTabAt(
    int index, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    // TODO: implement
    return false;
  }

  void expandTab(
    T tab, {
    Duration duration = const Duration(milliseconds: 350),
  }) =>
      expandTabAt(tabs.indexOf(tab), duration: duration);

  void expandTabAt(
    int index, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    // TODO: implement
  }

  bool isTabExpanded(T tab) => isTabExpandedAt(tabs.indexOf(tab));

  bool isTabExpandedAt(int index) {
    // TODO: implement
    return false;
  }

  void collapseTab({
    Duration duration = const Duration(milliseconds: 350),
  }) {
    // TODO: implement
  }

  void toggleMode({
    Duration duration = const Duration(milliseconds: 350),
  }) {
    // TODO: implement
    _state!.mode = _state!.overviewMode
        ? TabSwitcherMode.expanded
        : TabSwitcherMode.overview;
  }

  void scrollToTab(
    T tab, {
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOut,
  }) =>
      scrollToTabAt(tabs.indexOf(tab), duration: duration, curve: curve);

  void scrollToTabAt(
    int index, {
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOut,
  }) {
    // TODO: implement
  }

  void _reorderTabs(Permutations permutations) {
    permutations.apply(_tabs);
    onTabsReordered?.call();
  }
}

class DefaultTabThumbnail<T> extends StatelessWidget {
  final Widget child;

  const DefaultTabThumbnail({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: ShapeDecoration(
          color: Colors.grey.shade300,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 32,
              cornerSmoothing: 0.7,
            ),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.fitWidth,
          child: SizedBox.fromSize(
            size: MediaQuery.of(context).size,
            child: child,
          ),
        ),
      );
}
