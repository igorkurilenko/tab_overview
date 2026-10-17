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

part of '../tab_overview.dart';

class _TabThumbnailsGrid<T> extends StatefulWidget {
  final TabOverview<T> overview;

  /// The overview's [TabOverview.thumbnailsGridDelegate], or the default
  /// one for the overview's size.
  final SliverGridDelegate gridDelegate;

  const _TabThumbnailsGrid({
    super.key,
    required this.overview,
    required this.gridDelegate,
  });

  @override
  State<_TabThumbnailsGrid<T>> createState() => _TabThumbnailsGridState<T>();
}

class _TabThumbnailsGridState<T> extends State<_TabThumbnailsGrid<T>>
    with HeroTabHelper<T> {
  final thumbsGridKey = GlobalKey<AnimatedReorderableState>();
  SliverGridLayout? _thumbsGridLayout;
  final scrollController = ScrollController();

  _TabOverviewModel<T> get model => controller._model;

  bool thumbOffScreen(T tab) => thumbOffScreenAt(model.indexOfTab(tab));

  bool thumbOffScreenAt(int index) => !thumbsGridState!.isItemRendered(index);

  TabOverview<T> get overview => widget.overview;

  TabOverviewController<T> get controller => overview.controller;

  AnimatedReorderableState? get thumbsGridState => thumbsGridKey.currentState;

  double get thumbsGridScale => controller.mode == TabOverviewMode.expanded
      ? kThumbsGridScaleWhenExpanded
      : 1.0;

  double get thumbsGridOpacity => controller.mode == TabOverviewMode.expanded
      ? kThumbsGridOpacityWhenExpanded
      : 1.0;

  Duration? get activeTabHeroAnimationDuration {
    if (controller.activeTab == null) return null;
    final heroAnimationContext = controller._getTabFlightAnimationContext(
      controller.activeTab as T,
    );
    return heroAnimationContext?.duration;
  }

  Curve? get activeTabHeroAnimationCurve {
    if (controller.activeTab == null) return null;
    final heroAnimationContext = controller._getTabFlightAnimationContext(
      controller.activeTab as T,
    );
    return heroAnimationContext?.curve;
  }

  double getThumbScrollOffset(int index) {
    final maxOffset = scrollController.position.maxScrollExtent;
    final offset =
        _thumbsGridLayout?.getGeometryForChildIndex(index).scrollOffset ?? 0;
    return min(maxOffset, offset);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void stateChanged() => setState(() {});

  var _revealActiveThumbScheduled = false;

  // A relayout while expanded, such as a window resize, can move the active
  // thumb off screen. Collapse would then fly the tab off screen too.
  void _scheduleRevealActiveThumb() {
    if (_revealActiveThumbScheduled || !controller.expanded) return;
    _revealActiveThumbScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealActiveThumbScheduled = false;
      final tab = controller.activeTab;
      if (!mounted || !controller.expanded || tab == null) return;
      if (controller._hasTabExpandAnimationContext(tab) ||
          controller._hasTabCollapseAnimationContext(tab)) {
        return;
      }
      if (thumbOffScreen(tab)) controller._jumpToThumb(tab);
    });
  }

  void animateTo(
    double offset, {
    required Duration duration,
    required Curve curve,
  }) {
    scrollController.animateTo(offset, duration: duration, curve: curve);
  }

  void jumpTo(double offset) {
    scrollController.jumpTo(offset);
  }

  void addTab(T tab, {required Duration duration}) {
    thumbsGridState!.insertItem(model.indexOfTab(tab), (
      context,
      index,
      animation,
    ) {
      if (animation.status != AnimationStatus.completed) {
        controller._putTabInsertAnimation(tab, animation);
      }

      animation.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller._removeTabInsertAnimation(tab);
        }
      });

      return _buildThumb(context, model[index]);
    }, duration: duration);
  }

  void removeTab(int index, T removedTab, {required Duration duration}) {
    thumbsGridState!.removeItem(index, (context, animation) {
      if (animation.status != AnimationStatus.dismissed) {
        controller._putTabRemoveAnimation(removedTab, animation);
      }

      animation.addStatusListener((status) {
        if (animation.status == AnimationStatus.dismissed) {
          controller._removeTabRemoveAnimation(removedTab);
        }
      });

      return _buildThumb(context, removedTab);
    }, duration: duration);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          ignoring: controller.isAnyExpanding || controller.isAnyCollapsing,
          child: _buildThumbs(widget.gridDelegate),
        ),
        // Needed to support hero transition
        // if the thumb is off-screen and not rendered.
        _buildOffScreenThumbs(),
      ],
    );
  }

  Widget _buildThumbs(SliverGridDelegate gridDelegate) {
    return ScrollConfiguration(
      behavior: overview.scrollBehavior ?? ScrollConfiguration.of(context),
      child: AnimatedScale(
        scale: thumbsGridScale,
        duration:
            activeTabHeroAnimationDuration ??
            HeroHere.defaultFlightAnimationDuration,
        curve:
            activeTabHeroAnimationCurve ?? HeroHere.defaultFlightAnimationCurve,
        child: AnimatedOpacity(
          opacity: thumbsGridOpacity,
          duration:
              activeTabHeroAnimationDuration ??
              HeroHere.defaultFlightAnimationDuration,
          curve: controller.mode == TabOverviewMode.expanded
              ? Curves.fastOutSlowIn.flipped
              : Curves.fastOutSlowIn,
          child: AnimatedReorderable.grid(
            key: thumbsGridKey,
            motionAnimationDuration: overview.thumbnailsMotionAnimationDuration,
            motionAnimationCurve: overview.thumbnailsMotionAnimationCurve,
            keyGetter: (index) => ValueKey(model[index]),
            reorderableGetter: model.reorderableAt,
            onReorder: controller._reorderTabs,
            draggableGetter: (index) =>
                model.removableAt(index) || model.reorderableAt(index),
            swipeToRemoveDirectionGetter: (index) =>
                model.removableAt(index) ? AxisDirection.left : null,
            onSwipeToRemove: controller.removeTabAt,
            gridView: GridView.builder(
              clipBehavior: Clip.none,
              controller: scrollController,
              padding: overview.thumbnailsGridPadding,
              gridDelegate: SliverGridLayoutNotifier(
                gridDelegate: gridDelegate,
                onLayout: (layout) {
                  _thumbsGridLayout = layout;
                  _scheduleRevealActiveThumb();
                },
              ),
              itemCount: model.tabCount,
              itemBuilder: (context, index) =>
                  _buildThumb(context, model[index]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumb(BuildContext context, T tab) => _TabExpandedBuilder<T>(
    controller: controller,
    tab: tab,
    builder: (context) => _buildThumbOrEmptyCell(context, tab),
  );

  Widget _buildThumbOrEmptyCell(BuildContext context, T tab) {
    if (controller.isTabExpanded(tab)) {
      return Container();
    }

    if (model.containsOffScreenThumbTab(tab)) {
      return Container();
    }

    Widget thumb = overview.tabThumbnailBuilder(context, tab);
    thumb = _decorate(thumb, tab);
    thumb = _TabPresence<T>(controller: controller, tab: tab, child: thumb);

    Widget removeButton = overview.removeTabButtonBuilder(context, tab);
    removeButton = _TabPresence<T>(
      controller: controller,
      tab: tab,
      child: removeButton,
    );

    return Stack(
      children: [
        Positioned.fill(child: _buildThumbHero(thumb, tab)),
        if (model.removable(tab))
          _buildThumbRemoveButtonHero(removeButton, tab),
      ],
    );
  }

  Widget _buildThumbHero(Widget thumb, T tab) {
    return HeroHere(
      tag: tabHeroTag(tab),
      key: tabThumbHeroKey(tab),
      flightAnimationControllerFactory: (vsync, duration) {
        final animationContext = controller._getTabFlightAnimationContext(tab);
        return AnimationController(
          vsync: vsync,
          duration: animationContext!.duration,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed ||
              status == AnimationStatus.dismissed) {
            controller._collapseFlightEnded(tab);
          }
        });
      },
      flightAnimationFactory: (animationController) {
        final animationContext = controller._getTabFlightAnimationContext(tab);
        return animationContext!.animation = CurvedAnimation(
          parent: animationController,
          curve: animationContext.curve!,
        );
      },
      child: thumb,
    );
  }

  Widget _buildThumbRemoveButtonHero(Widget removeButton, T tab) {
    return HeroHere(
      tag: removeButtonHeroTag(tab),
      key: tabThumbRemoveButtonHeroKey(tab),
      child: removeButton,
    );
  }

  // The overview's own size, not the screen's, so the stand-ins sit at its
  // top and bottom centre wherever it is placed.
  Widget _buildOffScreenThumbs() => LayoutBuilder(
    builder: (context, constraints) =>
        _buildOffScreenThumbsIn(constraints.biggest),
  );

  Widget _buildOffScreenThumbsIn(Size overviewSize) {
    return Stack(
      children: [
        for (var tab in model.offScreenThumbTabs)
          Positioned(
            top:
                model.containsTab(tab) &&
                    getThumbScrollOffset(model.indexOfTab(tab)) <
                        scrollController.position.pixels
                ? 0
                : overviewSize.height,
            left: overviewSize.width / 2,
            child: SizedBox.fromSize(
              size: Size.zero,
              child: _buildOffScreenThumb(context, tab),
            ),
          ),
      ],
    );
  }

  Widget _buildOffScreenThumb(BuildContext context, T tab) {
    Widget thumb = overview.tabThumbnailBuilder(context, tab);
    thumb = _decorate(thumb, tab);
    thumb = _TabPresence<T>(controller: controller, tab: tab, child: thumb);

    return _TabExpandedBuilder<T>(
      controller: controller,
      tab: tab,
      builder: (context) => HeroMode(
        enabled: !controller.isTabExpanded(tab),
        child: _buildThumbHero(thumb, tab),
      ),
    );
  }

  Widget _decorate(Widget thumb, T tab) => _TabDecoration<T>(
    controller: controller,
    tab: tab,
    thumbnailDecoration: overview.thumbnailDecoration,
    expandedTabDecoration: overview.expandedTabDecoration,
    idleDecoration: overview.thumbnailDecoration,
    child: thumb,
  );
}

/// Builds again when whether [tab] is expanded changes, as when a swipe in
/// expanded mode changes the active tab, without the rest of the grid.
class _TabExpandedBuilder<T> extends StatefulWidget {
  final TabOverviewController<T> controller;
  final T tab;
  final WidgetBuilder builder;

  const _TabExpandedBuilder({
    required this.controller,
    required this.tab,
    required this.builder,
  });

  @override
  State<_TabExpandedBuilder<T>> createState() => _TabExpandedBuilderState<T>();
}

class _TabExpandedBuilderState<T> extends State<_TabExpandedBuilder<T>> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    widget.controller.addActiveTabChangedListener(_handleActiveTabChanged);
  }

  @override
  void didUpdateWidget(_TabExpandedBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeActiveTabChangedListener(
        _handleActiveTabChanged,
      );
      widget.controller.addActiveTabChangedListener(_handleActiveTabChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeActiveTabChangedListener(_handleActiveTabChanged);
    super.dispose();
  }

  void _handleActiveTabChanged() {
    if (widget.controller.isTabExpanded(widget.tab) != _expanded) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    _expanded = widget.controller.isTabExpanded(widget.tab);
    return widget.builder(context);
  }
}
