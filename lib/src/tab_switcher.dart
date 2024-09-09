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
import 'dart:math';

import 'package:animated_reorderable/animated_reorderable.dart';
import 'package:flutter/material.dart';
import 'package:tab_switcher/src/util/responsiveness.dart';
import 'package:tab_switcher/src/util/size_change_listener.dart';

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
  final ScrollBehavior? scrollBehavior;

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
    this.scrollBehavior,
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
  Size thumbnailSize = Size.zero;
  late TabSwitcherMode _mode;
  final thumbnailsScrollController = ScrollController();
  late PageController expandedTabPageController;
  late StateSetter rebuildThumbnails;
  late StateSetter rebuildExpandedTabBackground;
  late StateSetter rebuildExpandedTab;

  AnimatedReorderableState? get thumbnailsGridState =>
      thumbnailsGridKey.currentState;

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
  bool hasThumbnailAnimation(T tab) =>
      controller._thumbnailAnimationsByTab[tab] != null;
  Animation<double>? getThumbnailAnimation(T tab) =>
      controller._thumbnailAnimationsByTab[tab];

  TabSwitcherController<T> get controller => widget.controller;

  double getThumbnailScrollPosition(int thumbnailIndex) {
    final thumbnailsGridBox =
        thumbnailsGridState!.context.findRenderObject() as RenderBox;
    final canvasHeight = thumbnailsGridBox.size.height;
    final itemHeight = thumbnailSize.height;
    final paddingTop = widget.padding?.top ?? 0.0;
    final paddingBottom = widget.padding?.bottom ?? 0.0;
    final axisSpacing = widget.mainAxisSpacing;
    final rowCount = (tabs.length / crossAxisCount).ceil();
    final maxPosition = max(
        (itemHeight + axisSpacing) * rowCount -
            axisSpacing +
            paddingTop +
            paddingBottom -
            canvasHeight,
        0.0);
    final itemRowNumber = (thumbnailIndex / crossAxisCount).floor();
    final itemPosition = max(
        (itemHeight + axisSpacing) * itemRowNumber -
            canvasHeight / 2 +
            (itemHeight + axisSpacing) / 2,
        0.0);

    return min(maxPosition, itemPosition);
  }

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
    BuildContext context,
    SliverGridDelegate thumbnailsGridDelegate,
  ) {
    return Stack(
      children: [
        StatefulBuilder(builder: (context, setState) {
          rebuildThumbnails = setState;
          return Stack(
            children: [
              _buildThumbnails(thumbnailsGridDelegate),
            ],
          );
        }),
        StatefulBuilder(builder: (context, setState) {
          rebuildExpandedTabBackground = setState;
          return Container(
            color: controller._expandedTabBackgroundVisible
                ? Theme.of(context).scaffoldBackgroundColor
                : null,
          );
        }),
        if (expandedMode)
          StatefulBuilder(builder: (context, setState) {
            rebuildExpandedTab = setState;
            return _buildExpandedTab();
          }),
      ],
    );
  }

  Widget _buildThumbnails(SliverGridDelegate gridDelegate) {
    return ScrollConfiguration(
      behavior: widget.scrollBehavior ?? ScrollConfiguration.of(context),
      child: AnimatedReorderable.grid(
        key: thumbnailsGridKey,
        motionAnimationDuration: widget.animationDuration,
        keyGetter: (index) => ValueKey(tabs[index]),
        onReorder: controller._reorderTabs,
        onSwipeToRemove: controller.removeTabAt,
        reorderableGetter: isTabReorderableAt,
        gridView: GridView.builder(
          controller: thumbnailsScrollController,
          padding: widget.padding,
          gridDelegate: gridDelegate,
          itemCount: tabCount,
          itemBuilder: (context, index) => SizeChangeListener(
            child: _buildThumbnail(context, tabs[index]),
            onSizeChanged: (size) => thumbnailSize = size,
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, T tab) {
    final thumbnail = hasThumbnailAnimation(tab)
        ? ScaleTransition(
            scale: getThumbnailAnimation(tab)!,
            child: FadeTransition(
              opacity: getThumbnailAnimation(tab)!,
              child: widget.tabThumbnailBuilder(context, tab),
            ),
          )
        : widget.tabThumbnailBuilder(context, tab);

    return thumbnail;
  }

  Widget _buildExpandedTab() {
    return PageView.builder(
      controller: expandedTabPageController = PageController(
        initialPage: tabs.indexOf(controller._ensureActiveTab() as T),
        viewportFraction: kExpandedTabPageViewportFraction,
      ),
      scrollBehavior: widget.scrollBehavior,
      onPageChanged: controller._handleExpandedTabPageChanged,
      itemCount: tabCount,
      itemBuilder: (context, index) {
        final tab = tabs[index];

        return FractionallySizedBox(
          widthFactor: 1 / expandedTabPageController.viewportFraction,
          child: widget.tabBuilder(context, tab),
        );
      },
    );
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
  final _thumbnailAnimationsByTab = <T, Animation<double>>{};
  bool _expandedTabBackgroundVisible = false;
  T? _activeTab;

  TabSwitcherController({
    Iterable<T>? initialTabs,
    this.onTabExpanded,
    this.onTabCollapsed,
    this.onTabsReordered,
    this.onTabRemoved,
  }) : _tabs = List<T>.from(initialTabs ?? <T>[]);

  void _initState(_TabSwitcherState<T> state) => _state = state;

  List<T> get tabs => UnmodifiableListView(_tabs);

  bool get expandedMode => _state!.expandedMode;

  bool get overviewMode => _state!.overviewMode;

  T? get activeTab => _activeTab;

  bool addTab(
    T newTab, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    assert(_state != null,
        'TabSwitcherController not attached to any TabSwitcher.');

    if (_tabs.contains(newTab)) return false;

    final index = _tabs.length;
    _tabs.insert(index, newTab);

    _updateThumbnailsOnInsert(
      index: index,
      newTab: newTab,
      duration: duration,
    );

    if (_state!.expandedMode) {
      _updateExpandedTabOnInsert(
        newTab: newTab,
        duration: duration,
      );
    }

    return true;
  }

  void _updateThumbnailsOnInsert({
    required int index,
    required T newTab,
    required Duration duration,
  }) {
    _state!.thumbnailsGridState!.insertItem(index, (context, index, animation) {
      _thumbnailAnimationsByTab[newTab] = animation;
      animation.addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          _thumbnailAnimationsByTab.remove(newTab);
        }
      });
      return _state!._buildThumbnail(context, newTab);
    }, duration: duration);
  }

  void _updateExpandedTabOnInsert({
    required T newTab,
    required Duration duration,
  }) {
    _state!.rebuildExpandedTab.call(() {
      _state!.expandedTabPageController
          .jumpToPage(tabs.indexOf(_activeTab as T));
    });
  }

  void removeTab(
    T tab, {
    Duration duration = const Duration(milliseconds: 350),
  }) =>
      removeTabAt(tabs.indexOf(tab), duration: duration);

  T removeTabAt(
    int index, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    assert(_state != null,
        'TabSwitcherController not attached to any TabSwitcher.');

    final tab = _tabs.removeAt(index);

    _updateThumbnailsOnRemove(
      removedTabIndex: index,
      removedTab: tab,
      duration: duration,
    );

    if (expandedMode) {
      _updateExpandedTabOnRemove(
        removedTab: tab,
        duration: duration,
      );
    }

    return tab;
  }

  void _updateThumbnailsOnRemove({
    required int removedTabIndex,
    required T removedTab,
    required Duration duration,
  }) {
    _state!.thumbnailsGridState!.removeItem(
      removedTabIndex,
      (context, animation) {
        _thumbnailAnimationsByTab[removedTab] = animation;
        animation.addStatusListener((status) {
          if (status == AnimationStatus.completed ||
              status == AnimationStatus.dismissed) {
            _thumbnailAnimationsByTab.remove(removedTab);
            onTabRemoved?.call(removedTab);
          }
        });
        return _state!._buildThumbnail(context, removedTab);
      },
      duration: duration,
    );
  }

  void _updateExpandedTabOnRemove({
    required T removedTab,
    required Duration duration,
  }) {
    if (removedTab == _activeTab) {
      _state!.rebuildExpandedTabBackground(() {
        _expandedTabBackgroundVisible = false;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _state!.mode = TabSwitcherMode.overview;
        });
      });
    } else {
      _state!.rebuildExpandedTab(() {
        _state!.expandedTabPageController
            .jumpToPage(tabs.indexOf(_activeTab as T));
      });
    }
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
    assert(_state != null,
        'TabSwitcherController not attached to any TabSwitcher.');

    if (index < 0 || index >= tabs.length) {
      throw RangeError.index(index, tabs);
    }

    if (expandedMode) {
      scrollToTabAt(index);
      return;
    }

    _activeTab = tabs[index];
    _state!.mode = TabSwitcherMode.expanded;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _state!.rebuildExpandedTabBackground(() {
        _expandedTabBackgroundVisible = true;
      });
    });
  }

  bool isTabExpandedAt(int index) => isTabExpanded(tabs[index]);

  bool isTabExpanded(T tab) => expandedMode && _activeTab == tab;

  void collapseExpandedTab({
    Duration duration = const Duration(milliseconds: 350),
  }) {
    assert(_state != null,
        'TabSwitcherController not attached to any TabSwitcher.');

    if (_state!.overviewMode) return;

    _state!.rebuildExpandedTabBackground(() {
      _expandedTabBackgroundVisible = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _state!.mode = TabSwitcherMode.overview;
    });
  }

  void toggleMode({
    Duration duration = const Duration(milliseconds: 350),
  }) {
    assert(_state != null,
        'TabSwitcherController not attached to any TabSwitcher.');

    if (tabs.isEmpty) return;

    if (_state!.expandedMode) {
      collapseExpandedTab();
    } else {
      expandTab(_ensureActiveTab() as T);
    }
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
    assert(_state != null,
        'TabSwitcherController not attached to any tabs views.');

    if (expandedMode) {
      _state!.expandedTabPageController
          .animateToPage(index, duration: duration, curve: curve);
    } else {
      final position = _state!.getThumbnailScrollPosition(index);
      _state!.thumbnailsScrollController
          .animateTo(position, duration: duration, curve: curve);
    }
  }

  void _handleExpandedTabPageChanged(int page) {
    final position = _state!.getThumbnailScrollPosition(page);

    _state!.thumbnailsScrollController.jumpTo(position);
    _state!.rebuildThumbnails(() => _activeTab = tabs[page]);
  }

  void _reorderTabs(Permutations permutations) {
    permutations.apply(_tabs);
    onTabsReordered?.call();
  }

  T? _ensureActiveTab() =>
      _activeTab = _activeTab == null || !tabs.contains(activeTab as T)
          ? tabs.lastOrNull
          : activeTab;
}

class DefaultTabThumbnail<T> extends StatelessWidget {
  final Widget child;

  const DefaultTabThumbnail({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => FittedBox(
        clipBehavior: Clip.hardEdge,
        fit: BoxFit.fitWidth,
        child: SizedBox.fromSize(
          size: MediaQuery.of(context).size,
          child: child,
        ),
      );
}
