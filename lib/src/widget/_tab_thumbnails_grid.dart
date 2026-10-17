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
    with HeroTabHelper {
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

  Duration? get activeTabHeroAnimationDuration =>
      controller._flightOf(controller.activeTab)?.duration;

  Curve? get activeTabHeroAnimationCurve =>
      controller._flightOf(controller.activeTab)?.curve;

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
      if (controller._flightOf(tab) != null) return;
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

  void addTab(_TabEntry<T> entry, {required Duration duration}) {
    thumbsGridState!.insertItem(model.indexOfEntry(entry), (
      context,
      index,
      animation,
    ) {
      controller._trackTabPresence(
        entry,
        animation,
        endsAt: AnimationStatus.completed,
      );
      return _buildThumb(context, model.entryAt(index), presence: animation);
    }, duration: duration);
    _relayoutGrid();
  }

  void removeTab(
    int index,
    _TabEntry<T> removed, {
    required Duration duration,
  }) {
    thumbsGridState!.removeItem(index, (context, animation) {
      controller._trackTabPresence(
        removed,
        animation,
        endsAt: AnimationStatus.dismissed,
      );
      return _buildThumb(context, removed, presence: animation);
    }, duration: duration);
    _relayoutGrid();
  }

  // A tab added or removed off screen changes no child on screen, so the
  // grid's sliver would skip its next layout and keep the scroll extent it
  // had, a row short or long, and scrolling to a tab on a new last row would
  // stop short of it.
  void _relayoutGrid() {
    void visit(RenderObject object) {
      if (object is RenderSliverMultiBoxAdaptor) {
        object.markNeedsLayout();
      } else {
        object.visitChildren(visit);
      }
    }

    final gridObject = thumbsGridKey.currentContext?.findRenderObject();
    if (gridObject != null) visit(gridObject);
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
            keyGetter: model.keyAt,
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
                  _buildThumb(context, model.entryAt(index)),
            ),
          ),
        ),
      ),
    );
  }

  // [presence] is the item's add or remove animation while that runs.
  Widget _buildThumb(
    BuildContext context,
    _TabEntry<T> entry, {
    Animation<double> presence = kAlwaysCompleteAnimation,
  }) => _TabExpandedBuilder<T>(
    controller: controller,
    tab: entry.tab,
    builder: (context) => _buildThumbOrEmptyCell(context, entry, presence),
  );

  Widget _buildThumbOrEmptyCell(
    BuildContext context,
    _TabEntry<T> entry,
    Animation<double> presence,
  ) {
    final tab = entry.tab;
    if (controller.isTabExpanded(tab)) {
      return Container();
    }

    if (model.hasStandIn(entry)) {
      return Container();
    }

    final thumb = _buildThumbnail(context, entry, presence);
    final removeButton = _TabPresence(
      animation: presence,
      child: overview.removeTabButtonBuilder(context, tab),
    );

    return Stack(
      children: [
        Positioned.fill(child: _buildThumbHero(thumb, entry)),
        if (model.removable(tab))
          _buildThumbRemoveButtonHero(removeButton, entry),
      ],
    );
  }

  Widget _buildThumbHero(Widget thumb, _TabEntry<T> entry) {
    return HeroHere(
      tag: tabHeroTag(entry),
      key: tabThumbHeroKey(entry),
      flightRedirect: HeroHereFlightRedirect.divert,
      flightAnimationControllerFactory: (vsync, duration) =>
          controller._createTabFlightController(entry, vsync, toPage: false),
      flightAnimationFactory: (animationController) =>
          controller._createTabFlightAnimation(entry, animationController),
      forwardFlightAnimation: (animationController, {from}) =>
          controller._runTabFlight(entry, animationController, from: from),
      child: thumb,
    );
  }

  Widget _buildThumbRemoveButtonHero(Widget removeButton, _TabEntry<T> entry) {
    return HeroHere(
      tag: removeButtonHeroTag(entry),
      key: tabThumbRemoveButtonHeroKey(entry),
      flightRedirect: HeroHereFlightRedirect.divert,
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
        for (final entry in model.standIns)
          Positioned(
            top: _isAbove(model.indexOfEntry(entry)) ? 0 : overviewSize.height,
            left: overviewSize.width / 2,
            child: SizedBox.fromSize(
              size: Size.zero,
              child: _buildOffScreenThumb(context, entry),
            ),
          ),
      ],
    );
  }

  // Whether the thumbnail at [index] is above the grid's viewport, rather
  // than below it, or nowhere, as a removed tab's.
  bool _isAbove(int index) =>
      index != -1 &&
      getThumbScrollOffset(index) < scrollController.position.pixels;

  Widget _buildOffScreenThumb(BuildContext context, _TabEntry<T> entry) {
    final tab = entry.tab;
    final thumb = _buildThumbnail(
      context,
      entry,
      entry.presence ?? kAlwaysCompleteAnimation,
    );

    return _TabExpandedBuilder<T>(
      controller: controller,
      tab: tab,
      builder: (context) => HeroMode(
        enabled: !controller.isTabExpanded(tab),
        child: _buildThumbHero(thumb, entry),
      ),
    );
  }

  // What tabThumbnailBuilder builds, decorated, and scaled and faded in and
  // out as the tab is added and removed.
  Widget _buildThumbnail(
    BuildContext context,
    _TabEntry<T> entry,
    Animation<double> presence,
  ) => _TabPresence(
    animation: presence,
    child: _TabDecoration<T>(
      overview: overview,
      entry: entry,
      idleDecoration: overview.thumbnailDecoration,
      child: overview.tabThumbnailBuilder(context, entry.tab),
    ),
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
