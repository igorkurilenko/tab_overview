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
import 'package:flutter/rendering.dart';
import 'package:hero_here/hero_here.dart';
import 'package:tab_switcher/src/util/responsiveness.dart';

import 'util/sliver_grid_delegate_decorator.dart';

const kExpandedTabPageViewportFraction = 1.1;
const kDefaultThumbsGridCrossAxisSpacing = 2.0;
const kDefaultThumbsGridMainAxisSpacing = 2.0;
const kThumbsGridScaleWhenExpanded = 0.9;
const kThumbsGridOpacityWhenExpanded = 0.0;

class TabSwitcher<T> extends StatefulWidget {
  final TabSwitcherController<T> controller;
  final TabSwitcherMode initialMode;
  final TabSwitcherWidgetBuilder<T> tabBuilder;
  final TabSwitcherWidgetBuilder<T>? removeTabButtonBuilder;
  final EdgeInsets? thumbnailsGridPadding;
  final SliverGridDelegate? thumbnailsGridDelegate;
  final TabSwitcherWidgetBuilder<T> tabThumbBuilder;
  final Duration thumbnailsMotionAnimationDuration;
  final Curve thumbnailsMotionAnimationCurve;
  final ScrollBehavior? scrollBehavior;
  final Decoration thumbnailDecoration;
  final Decoration expandedTabDecoration;
  late final FlightShuttleBuilder<T> expandingFlightShuttleBuilder;
  late final FlightShuttleBuilder<T> collapsingFlightShuttleBuilder;

  TabSwitcher.builder({
    super.key,
    TabSwitcherController<T>? controller,
    this.initialMode = TabSwitcherMode.overview,
    required this.tabBuilder,
    this.removeTabButtonBuilder,
    this.thumbnailsGridPadding,
    this.thumbnailsGridDelegate,
    TabSwitcherWidgetBuilder<T>? tabThumbnailBuilder,
    this.thumbnailsMotionAnimationDuration = const Duration(milliseconds: 350),
    this.thumbnailsMotionAnimationCurve = Curves.easeInOut,
    this.scrollBehavior,
    Decoration? thumbnailDecoration,
    Decoration? expandedTabDecoration,
    FlightShuttleBuilder<T>? expandingFlightShuttleBuilder,
    FlightShuttleBuilder<T>? collapsingFlightShuttleBuilder,
  })  : controller = controller ?? TabSwitcherController<T>(),
        thumbnailDecoration = thumbnailDecoration ?? const BoxDecoration(),
        expandedTabDecoration = expandedTabDecoration ?? const BoxDecoration(),
        tabThumbBuilder = tabThumbnailBuilder ??
            ((context, tab) => FittedTab(
                  child: tabBuilder(context, tab),
                )) {
    this.expandingFlightShuttleBuilder = expandingFlightShuttleBuilder ??
        ((context, animation, tab) {
          final decorationAnimation = DecorationTween(
            begin: this.thumbnailDecoration,
            end: this.expandedTabDecoration,
          ).animate(animation);

          return AnimatedBuilder(
            animation: decorationAnimation,
            builder: (context, child) => Container(
              clipBehavior: Clip.antiAlias,
              decoration: decorationAnimation.value,
              child: child,
            ),
            child: tabThumbBuilder(context, tab),
          );
        });

    this.collapsingFlightShuttleBuilder = collapsingFlightShuttleBuilder ??
        ((context, animation, tab) {
          final decorationAnimation = DecorationTween(
            begin: this.expandedTabDecoration,
            end: this.thumbnailDecoration,
          ).animate(animation);

          return AnimatedBuilder(
            animation: decorationAnimation,
            builder: (context, child) => Container(
              clipBehavior: Clip.antiAlias,
              decoration: decorationAnimation.value,
              child: child,
            ),
            child: tabThumbBuilder(context, tab),
          );
        });
  }

  @override
  State<TabSwitcher> createState() => _TabSwitcherState<T>();
}

class _TabSwitcherState<T> extends State<TabSwitcher<T>> with Responsiveness {
  final thumbsGridKey = GlobalKey<AnimatedReorderableState>();
  SliverGridLayout? _thumbsGridLayout;
  late TabSwitcherMode _mode;
  final thumbsScrollController = ScrollController();
  late PageController expandedTabPageController;
  late StateSetter rebuildThumbs;
  late StateSetter rebuildExpandedTab;

  AnimatedReorderableState? get thumbsGridState => thumbsGridKey.currentState;

  double get _thumbsGridScale =>
      expandedMode ? kThumbsGridScaleWhenExpanded : 1.0;
  double get _thumbsGridOpacity =>
      expandedMode ? kThumbsGridOpacityWhenExpanded : 1.0;

  TabSwitcherMode get mode => _mode;
  bool get overviewMode => _mode == TabSwitcherMode.overview;
  bool get expandedMode => _mode == TabSwitcherMode.expanded;
  set mode(TabSwitcherMode value) {
    if (_mode == value) return;
    setState(() => _mode = value);
  }

  Size? get tabSwitcherSize => constraints?.biggest;
  Size get screenSize => MediaQuery.sizeOf(context);

  List<T> get tabs => controller.tabs;
  int get tabCount => tabs.length;
  bool reorderableAt(int index) => reorderable(tabs[index]);
  bool reorderable(T tab) => tab is ReorderableTab ? tab.reorderable : true;
  bool removableAt(int index) => removable(tabs[index]);
  bool removable(T tab) => tab is RemovableTab ? tab.removable : true;
  bool thumbOffScreen(T tab) => thumbOffScreenAt(controller._tabs.indexOf(tab));
  bool thumbOffScreenAt(int index) => !thumbsGridState!.isItemRendered(index);

  String tabHeroTag(T tab) => '${tab.runtimeType}-${tab.hashCode}';
  Key tabThumbHeroKey(T tab) => ValueKey('${tabHeroTag(tab)}-thumb');
  Key expandedTabHeroKey(T tab) => ValueKey('${tabHeroTag(tab)}-expanded');

  TabSwitcherController<T> get controller => widget.controller;

  Duration? get activeTabHeroAnimationDuration =>
      controller._activeTabAnimationContext()?.heroFlightAnimationDuration;
  Curve? get activeTabHeroAnimationCurve =>
      controller._activeTabAnimationContext()?.heroFlightAnimationCurve;

  double getThumbScrollOffset(int index) {
    final maxOffset = thumbsScrollController.position.maxScrollExtent;
    final offset =
        _thumbsGridLayout?.getGeometryForChildIndex(index).scrollOffset ?? 0;
    return min(maxOffset, offset);
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
      widget.thumbnailsGridDelegate ??
          SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: constraints!.maxWidth / constraints!.maxHeight,
            mainAxisSpacing: kDefaultThumbsGridMainAxisSpacing,
            crossAxisSpacing: kDefaultThumbsGridCrossAxisSpacing,
          ),
    );
  }

  @override
  Widget buildMedium(BuildContext context) => _build(
        context,
        widget.thumbnailsGridDelegate ??
            SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: constraints!.maxWidth / constraints!.maxHeight,
              mainAxisSpacing: kDefaultThumbsGridMainAxisSpacing,
              crossAxisSpacing: kDefaultThumbsGridCrossAxisSpacing,
            ),
      );

  @override
  Widget buildSmall(BuildContext context) => _build(
        context,
        widget.thumbnailsGridDelegate ??
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              mainAxisSpacing: kDefaultThumbsGridMainAxisSpacing,
              crossAxisSpacing: kDefaultThumbsGridCrossAxisSpacing,
            ),
      );

  @override
  Widget buildExtraSmall(BuildContext context) => const Placeholder();

  Widget _build(
    BuildContext context,
    SliverGridDelegate thumbsGridDelegate,
  ) {
    return HeroHereSwitcher(
      child: Stack(
        children: [
          StatefulBuilder(builder: (context, setState) {
            rebuildThumbs = setState;
            return Stack(
              children: [
                IgnorePointer(
                  ignoring:
                      controller.isAnyExpanding || controller.isAnyCollapsing,
                  child: _buildThumbs(thumbsGridDelegate),
                ),
                // Needed to support hero transition
                // if the thumb is off-screen and not rendered.
                _buildOffScreenThumbs(),
              ],
            );
          }),
          if (expandedMode)
            StatefulBuilder(builder: (context, setState) {
              rebuildExpandedTab = setState;
              return _buildExpandedTabPageView();
            }),
        ],
      ),
    );
  }

  Widget _buildThumbs(SliverGridDelegate gridDelegate) {
    return ScrollConfiguration(
      behavior: widget.scrollBehavior ?? ScrollConfiguration.of(context),
      child: AnimatedScale(
        scale: _thumbsGridScale,
        duration: activeTabHeroAnimationDuration ??
            HeroHere.defaultFlightAnimationDuration,
        curve:
            activeTabHeroAnimationCurve ?? HeroHere.defaultFlightAnimationCurve,
        child: AnimatedOpacity(
          opacity: _thumbsGridOpacity,
          duration: activeTabHeroAnimationDuration ??
              HeroHere.defaultFlightAnimationDuration,
          curve: expandedMode
              ? Curves.fastOutSlowIn.flipped
              : Curves.fastOutSlowIn,
          child: AnimatedReorderable.grid(
            key: thumbsGridKey,
            motionAnimationDuration: widget.thumbnailsMotionAnimationDuration,
            keyGetter: (index) => ValueKey(tabs[index]),
            reorderableGetter: reorderableAt,
            onReorder: controller._reorderTabs,
            swipeToRemoveDirectionGetter: (index) =>
                removableAt(index) ? AxisDirection.left : null,
            onSwipeToRemove: controller.removeTabAt,
            gridView: GridView.builder(
              clipBehavior: Clip.none,
              controller: thumbsScrollController,
              padding: widget.thumbnailsGridPadding,
              gridDelegate: SliverGridLayoutNotifier(
                gridDelegate: gridDelegate,
                onLayout: (layout) => _thumbsGridLayout = layout,
              ),
              itemCount: tabCount,
              itemBuilder: (context, index) =>
                  _buildThumb(context, tabs[index]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumb(BuildContext context, T tab) {
    if (controller.expanded(tab)) {
      return Container();
    }

    if (controller._offScreenThumbTabs.contains(tab)) {
      return Container();
    }

    // TODO: close button
    // TODO: decoration animation

    final inserOrRemoveAnimation =
        controller._ensureAnimationContext(tab).insertOrRemoveAnimation;
    final thumb = inserOrRemoveAnimation != null
        ? ScaleTransition(
            scale: inserOrRemoveAnimation,
            child: FadeTransition(
              opacity: inserOrRemoveAnimation,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: widget.thumbnailDecoration,
                child: widget.tabThumbBuilder(context, tab),
              ),
            ),
          )
        : Container(
            clipBehavior: Clip.antiAlias,
            decoration: widget.thumbnailDecoration,
            child: widget.tabThumbBuilder(context, tab),
          );

    return HeroMode(
      enabled: !controller._offScreenThumbTabs.contains(tab),
      child: HeroHere(
        tag: tabHeroTag(tab),
        key: tabThumbHeroKey(tab),
        flightAnimationFactory: (animationController) =>
            _createThumbFlightAnimation(animationController, tab),
        flightShuttleBuilder: (context, animation, fromHero, toHero) =>
            widget.collapsingFlightShuttleBuilder(context, animation, tab),
        child: thumb,
      ),
    );
  }

  Widget _buildOffScreenThumbs() {
    return Stack(
      children: [
        for (var tab in controller._offScreenThumbTabs)
          Positioned(
            top: tabs.contains(tab) &&
                    getThumbScrollOffset(tabs.indexOf(tab)) <
                        thumbsScrollController.position.pixels
                ? 0
                : screenSize.height,
            left: screenSize.width / 2,
            child: SizedBox.fromSize(
              size: Size.zero,
              child: _buildOffScreenThumb(context, tab),
            ),
          ),
      ],
    );
  }

  Widget _buildOffScreenThumb(BuildContext context, T tab) {
    return HeroMode(
      enabled: !controller.expanded(tab),
      child: HeroHere(
        tag: tabHeroTag(tab),
        key: tabThumbHeroKey(tab),
        flightAnimationFactory: (animationController) =>
            _createOffScreenThumbFlightAnimation(animationController, tab),
        flightShuttleBuilder: (context, animation, fromHero, toHero) =>
            widget.collapsingFlightShuttleBuilder(context, animation, tab),
        child: widget.tabThumbBuilder(context, tab),
      ),
    );
  }

  Widget _buildExpandedTabPageView() {
    return PageView.builder(
      controller: expandedTabPageController = PageController(
        initialPage: tabs.indexOf(controller._ensureActiveTab() as T),
        viewportFraction: kExpandedTabPageViewportFraction,
      ),
      scrollBehavior: widget.scrollBehavior,
      onPageChanged: controller._handleExpandedTabPageChanged,
      itemCount: tabCount,
      itemBuilder: (context, index) => FractionallySizedBox(
        widthFactor: 1 / expandedTabPageController.viewportFraction,
        child: _buildExpandedTab(context, tabs[index]),
      ),
    );
  }

  Widget _buildExpandedTab(BuildContext context, T tab) {
    final insertOrRemoveAnimation =
        controller._ensureAnimationContext(tab).insertOrRemoveAnimation;
    final tabWidget = insertOrRemoveAnimation != null
        ? ScaleTransition(
            scale: insertOrRemoveAnimation,
            child: FadeTransition(
              opacity: insertOrRemoveAnimation,
              child: FittedTab(
                child: widget.tabBuilder(context, tab),
              ),
            ),
          )
        : FittedTab(
            child: widget.tabBuilder(context, tab),
          );

    return HeroHere(
      tag: tabHeroTag(tab),
      key: expandedTabHeroKey(tab),
      flightAnimationControllerFactory: (vsync, duration) =>
          _createTabFlightAnimationController(vsync, tab),
      flightAnimationFactory: (controller) =>
          _createExpandedTabFlightAnimation(controller, tab),
      flightShuttleBuilder: (context, animation, fromHero, toHero) =>
          widget.expandingFlightShuttleBuilder(context, animation, tab),
      child: tabWidget,
    );
  }

  AnimationController _createTabFlightAnimationController(
    TickerProvider tickerProvider,
    T tab,
  ) {
    final animationContext = controller._ensureAnimationContext(tab);

    return AnimationController(
      vsync: tickerProvider,
      duration: animationContext.heroFlightAnimationDuration!,
    );
  }

  Animation<double> _createThumbFlightAnimation(
    AnimationController animationController,
    T tab,
  ) {
    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller._thumbFlightAnimationCompleted(tab);
      }
      if (status == AnimationStatus.dismissed) {
        controller._thumbFlightAnimationDismissed(tab);
      }
    });

    final animationContext = controller._ensureAnimationContext(tab);

    return CurvedAnimation(
      parent: animationController,
      curve: animationContext.heroFlightAnimationCurve!,
    );
  }

  Animation<double> _createOffScreenThumbFlightAnimation(
    AnimationController animationController,
    T tab,
  ) {
    final animationContext = controller._ensureAnimationContext(tab);

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller._offScreenThumbFlightAnimationCompleted(tab);
      }
      if (status == AnimationStatus.dismissed) {
        controller._offScreenThumbFlightAnimationDismissed(tab);
      }
    });

    return CurvedAnimation(
      parent: animationController,
      curve: animationContext.heroFlightAnimationCurve!,
    );
  }

  Animation<double> _createExpandedTabFlightAnimation(
    AnimationController animationController,
    T tab,
  ) {
    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller._expandedTabFlightAnimationCompleted(tab);
      }
      if (status == AnimationStatus.dismissed) {
        controller._expandedTabFlightAnimationDismissed(tab);
      }
    });

    final animationContext = controller._ensureAnimationContext(tab);

    return CurvedAnimation(
      parent: animationController,
      curve: animationContext.heroFlightAnimationCurve!,
    );
  }
}

typedef TabSwitcherWidgetBuilder<T> = Widget Function(
    BuildContext context, T tab);

typedef TabSwitcherWidgetAnimatedBuilder<T> = Widget Function(
    BuildContext context, T tab, Animation<double> animation);

typedef FlightShuttleBuilder<T> = Widget Function(
    BuildContext context, Animation<double> animation, T tab);

enum TabSwitcherMode { expanded, overview }

abstract class ReorderableTab {
  bool get reorderable;
}

abstract class RemovableTab {
  bool get removable;
}

class TabSwitcherController<T> {
  final List<T> _tabs;
  final _offScreenThumbTabs = <T>{};
  final _animationContextsByTab = <T, _TabAnimationContext>{};
  final _expandingTabs = <T>{};
  final _collapsingTabs = <T>{};
  _TabSwitcherState? _state;
  final ValueChanged<T>? onTabExpanded;
  final ValueChanged<T>? onTabCollapsed;
  final VoidCallback? onTabsReordered;
  final ValueChanged<T>? onTabRemoved;
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

  bool get isAnyExpanding => _expandingTabs.isNotEmpty;
  bool get isAnyCollapsing => _collapsingTabs.isNotEmpty;
  bool isExpanding(T tab) => _expandingTabs.contains(tab);
  bool isCollapsing(T tab) => _collapsingTabs.contains(tab);

  T? get activeTab => _activeTab;

  bool add(
    T newTab, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    assert(_state != null,
        'TabSwitcherController not attached to any TabSwitcher.');

    if (_tabs.contains(newTab)) return false;

    _tabs.add(newTab);

    _updateThumbsOnInsert(
      newTab: newTab,
      duration: duration,
    );

    if (_state!.expandedMode) {
      _updateExpandedTabOnInsert(newTab: newTab);
    }

    return true;
  }

  void _updateThumbsOnInsert({
    required T newTab,
    required Duration duration,
  }) {
    _state!.thumbsGridState!.insertItem(_tabs.indexOf(newTab),
        (context, index, animation) {
      _ensureAnimationContext(newTab).insertOrRemoveAnimation = animation;

      animation.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _ensureAnimationContext(_tabs[index]).insertOrRemoveAnimation = null;
        }
      });

      return _state!._buildThumb(context, _tabs[index]);
    }, duration: duration);
  }

  void _updateExpandedTabOnInsert({required T newTab}) {
    _state!.rebuildExpandedTab.call(() {
      _state!.expandedTabPageController
          .jumpToPage(tabs.indexOf(_activeTab as T));
    });
  }

  void remove(
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

    final removedTab = _tabs.removeAt(index);
    _animationContextsByTab.remove(removedTab);

    _updateThumbsOnRemove(
      removedTabIndex: index,
      removedTab: removedTab,
      duration: duration,
    );

    if (expandedMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateExpandedTabOnRemove(
          removedTab: removedTab,
          duration: duration,
        );
      });
    }

    return removedTab;
  }

  void _updateThumbsOnRemove({
    required int removedTabIndex,
    required T removedTab,
    required Duration duration,
  }) {
    _state!.thumbsGridState!.removeItem(
      removedTabIndex,
      (context, animation) {
        _ensureAnimationContext(removedTab).insertOrRemoveAnimation = animation;

        animation.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _animationContextsByTab.remove(removedTab);
            onTabRemoved?.call(removedTab);
          }
        });

        return _state!._buildThumb(context, removedTab);
      },
      duration: duration,
    );
  }

  void _updateExpandedTabOnRemove({
    required T removedTab,
    required Duration duration,
  }) {
    if (removedTab == _activeTab) {
      _state!.rebuildThumbs(() {
        _offScreenThumbTabs.add(removedTab);
      });

      _ensureAnimationContext(removedTab)
        ..heroFlightAnimationDuration = duration
        ..heroFlightAnimationCurve = HeroHere.defaultFlightAnimationCurve;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _state!.mode = TabSwitcherMode.overview;
      });
    } else {
      _state!.rebuildExpandedTab(() {
        _state!.expandedTabPageController
            .jumpToPage(tabs.indexOf(_activeTab as T));
      });
    }
  }

  void expandAt(
    int index, {
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOut,
  }) =>
      expand(
        _tabs[index],
        duration: duration,
        curve: curve,
      );

  void expand(
    T tab, {
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOut,
  }) {
    assert(_state != null,
        'TabSwitcherController not attached to any TabSwitcher.');

    if (!_tabs.contains(tab)) {
      throw ArgumentError('Tab $tab not found');
    }

    if (expandedMode) {
      scrollToTab(
        tab,
        duration: duration,
        curve: curve,
      );
      return;
    }

    _activeTab = tab;
    _expandingTabs.add(tab);

    _ensureAnimationContext(tab)
      ..heroFlightAnimationDuration = duration
      ..heroFlightAnimationCurve = curve;

    if (_state!.thumbOffScreen(tab)) {
      _state!.rebuildThumbs(() {
        _offScreenThumbTabs.add(tab);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _state!.mode = TabSwitcherMode.expanded;
      });
    } else {
      _state!.mode = TabSwitcherMode.expanded;
    }
  }

  bool expandedAt(int index) => expanded(tabs[index]);

  bool expanded(T tab) => expandedMode && _activeTab == tab;

  void _expandedTabFlightAnimationCompleted(T tab) {
    _state!.rebuildThumbs(() {
      _expandingTabs.remove(tab);
      _offScreenThumbTabs.remove(tab);
    });

    if (_state!.thumbOffScreen(tab)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _jumpToThumb(tab);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _jumpToThumb(tab);
        });
      });
    }
  }

  void _expandedTabFlightAnimationDismissed(T tab) {
    _state!.rebuildThumbs(() {
      _expandingTabs.remove(tab);
      _collapsingTabs.remove(tab);
      _offScreenThumbTabs.remove(tab);
    });
  }

  void collapse({
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOut,
  }) {
    assert(_state != null,
        'TabSwitcherController not attached to any TabSwitcher.');

    if (_state!.overviewMode) return;

    final activeTab = _activeTab as T;

    _ensureAnimationContext(activeTab)
      ..heroFlightAnimationDuration = duration
      ..heroFlightAnimationCurve = curve;

    _collapsingTabs.add(activeTab);

    if (_state!.thumbOffScreen(activeTab)) {
      _state!.rebuildThumbs(() {
        _offScreenThumbTabs.add(activeTab);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _state!.mode = TabSwitcherMode.overview;
      });
    } else {
      _state!.mode = TabSwitcherMode.overview;
    }
  }

  void _thumbFlightAnimationCompleted(T tab) {
    _state!.rebuildThumbs(() {
      _collapsingTabs.remove(tab);
      _offScreenThumbTabs.remove(tab);
      _animationContextsByTab.remove(tab);
    });
  }

  void _thumbFlightAnimationDismissed(T tab) {
    _state!.rebuildThumbs(() {
      _collapsingTabs.remove(tab);
      _expandingTabs.remove(tab);
      _offScreenThumbTabs.remove(tab);
    });
  }

  void _offScreenThumbFlightAnimationCompleted(tab) {
    _offScreenThumbTabs.remove(tab);
    _animationContextsByTab.remove(tab);
  }

  void _offScreenThumbFlightAnimationDismissed(tab) {}

  void toggleMode({
    Duration duration = const Duration(milliseconds: 350),
  }) {
    assert(_state != null,
        'TabSwitcherController not attached to any TabSwitcher.');

    if (_tabs.isEmpty) return;

    if (_state!.expandedMode) {
      collapse();
    } else {
      expand(_ensureActiveTab() as T);
    }
  }

  void scrollToTab(
    T tab, {
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOut,
  }) =>
      scrollToTabAt(
        tabs.indexOf(tab),
        duration: duration,
        curve: curve,
      );

  void scrollToTabAt(
    int index, {
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOut,
  }) {
    assert(_state != null,
        'TabSwitcherController not attached to any TabSwitcher.');

    if (expandedMode) {
      _state!.expandedTabPageController
          .animateToPage(index, duration: duration, curve: curve);
    } else {
      final offset = _state!.getThumbScrollOffset(index);

      _state!.thumbsScrollController
          .animateTo(offset, duration: duration, curve: curve);
    }
  }

  void _handleExpandedTabPageChanged(int page) {
    final activeTabAnimationContext = _ensureAnimationContext(activeTab as T);
    final curTab = tabs[page];

    _ensureAnimationContext(curTab)
      ..heroFlightAnimationDuration =
          activeTabAnimationContext.heroFlightAnimationDuration
      ..heroFlightAnimationCurve =
          activeTabAnimationContext.heroFlightAnimationCurve;

    _jumpToThumbAt(page);

    _state!.rebuildThumbs(() => _activeTab = curTab);
  }

  void _reorderTabs(Permutations permutations) {
    permutations.apply(_tabs);
    onTabsReordered?.call();
  }

  T? _ensureActiveTab() =>
      _activeTab = _activeTab == null || !tabs.contains(activeTab as T)
          ? tabs.lastOrNull
          : activeTab;

  void _jumpToThumb(T tab) => _jumpToThumbAt(_tabs.indexOf(tab));

  void _jumpToThumbAt(int index) {
    final offset = _state!.getThumbScrollOffset(index);
    _state!.thumbsScrollController.jumpTo(offset);
  }

  _TabAnimationContext? _activeTabAnimationContext() =>
      _animationContextsByTab[_activeTab];

  _TabAnimationContext _ensureAnimationContext(T tab) =>
      _animationContextsByTab.putIfAbsent(tab, () => _TabAnimationContext());
}

class FittedTab<T> extends StatelessWidget {
  final Widget child;

  const FittedTab({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => FittedBox(
        clipBehavior: Clip.hardEdge,
        fit: BoxFit.fitWidth,
        alignment: Alignment.center,
        child: SizedBox.fromSize(
          size: MediaQuery.of(context).size,
          child: child,
        ),
      );
}

class _TabAnimationContext {
  Duration? heroFlightAnimationDuration;
  Curve? heroFlightAnimationCurve;
  Animation<double>? insertOrRemoveAnimation;
  Offset? thumbPosition;
}
