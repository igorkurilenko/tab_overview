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
    with HeroTabHelper
    implements _ThumbnailsView<T> {
  final thumbsGridKey = GlobalKey<AnimatedReorderableState>();
  final scrollController = ScrollController();

  _TabOverviewModel<T> get model => controller._model;

  // Whether the tab's thumb is built, so has a hero for a flight to fly to
  // or from. A thumb that isn't needs a stand-in.
  @override
  bool thumbBuilt(T tab) =>
      thumbsGridState!.isItemRendered(model.indexOfTab(tab));

  // Whether most of the tab's thumb, its middle, is in the grid's viewport,
  // as last laid out, so a flight to it lands in view. The grid builds
  // thumbs a little past the viewport's edges too, so a thumb may be built,
  // with a hero to fly to, and still be out of view.
  @override
  bool thumbInView(T tab) {
    final index = model.indexOfTab(tab);
    final grid = _renderGrid;
    if (index == -1 || grid == null || grid.geometry == null) return false;
    final geometry = grid.gridDelegate
        .getLayout(grid.constraints)
        .getGeometryForChildIndex(index);
    final middle =
        grid.constraints.precedingScrollExtent +
        geometry.scrollOffset +
        geometry.mainAxisExtent / 2;
    final position = scrollController.position;
    return middle >= position.pixels &&
        middle <= position.pixels + position.viewportDimension;
  }

  TabOverview<T> get overview => widget.overview;

  TabOverviewController<T> get controller => overview.controller;

  AnimatedReorderableState? get thumbsGridState => thumbsGridKey.currentState;

  double get thumbsGridScale => controller.mode == TabOverviewMode.expanded
      ? _kThumbsGridScaleWhenExpanded
      : 1.0;

  double get thumbsGridOpacity => controller.mode == TabOverviewMode.expanded
      ? _kThumbsGridOpacityWhenExpanded
      : 1.0;

  Duration? get activeTabHeroAnimationDuration =>
      controller._flights.of(controller.activeTab)?.duration;

  Curve? get activeTabHeroAnimationCurve =>
      controller._flights.of(controller.activeTab)?.curve;

  // The scroll offset of the thumb at [index] in the grid as last laid out,
  // up to how far the grid scrolls.
  @override
  double getThumbScrollOffset(int index) {
    final grid = _renderGrid;
    // A sliver has no geometry until it's laid out.
    if (grid == null || grid.geometry == null) return 0;
    final offset = grid.gridDelegate
        .getLayout(grid.constraints)
        .getGeometryForChildIndex(index)
        .scrollOffset;
    return min(scrollController.position.maxScrollExtent, offset);
  }

  // The grid's sliver, found from the grid's own Scrollable, so as to stay
  // out of the layer that shows the thumbnails being dragged or moved.
  RenderSliverGrid? get _renderGrid {
    RenderSliverGrid? grid;
    void visit(RenderObject object) {
      if (object is RenderSliverGrid) {
        grid = object;
      } else if (grid == null) {
        object.visitChildren(visit);
      }
    }

    if (!scrollController.hasClients) return null;
    final scrollable = scrollController.position.context.notificationContext;
    final scrollableObject = scrollable?.findRenderObject();
    if (scrollableObject != null) visit(scrollableObject);
    return grid;
  }

  // The grid's items. A mode change or a flight rebuilds the rest of the
  // grid, not them: a cell listens to what changes it. Built anew when the
  // overview, or the delegate for its size, does.
  Widget? _items;

  @override
  void initState() {
    super.initState();
    controller._attachThumbnails(this);
  }

  @override
  void didUpdateWidget(_TabThumbnailsGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldController = oldWidget.overview.controller;
    if (controller != oldController) {
      oldController._detachThumbnails(this);
      controller._attachThumbnails(this);
    }
    if (widget.overview != oldWidget.overview ||
        widget.gridDelegate != oldWidget.gridDelegate) {
      _items = null;
    }
  }

  @override
  void dispose() {
    controller._detachThumbnails(this);
    scrollController.dispose();
    super.dispose();
  }

  // A relayout while expanded, such as a window resize, can move the active
  // thumb off screen. Collapse would then fly the tab off screen too. A
  // resize, the keyboard or a change of safe area changes the grid's
  // viewport or extent, which the grid's Scrollable tells after the frame.
  bool _handleScrollMetricsChanged(ScrollMetricsNotification notification) {
    if (notification.depth == 0) _revealActiveThumb();
    return false;
  }

  void _revealActiveThumb() {
    final tab = controller.activeTab;
    if (!controller.expanded || tab == null) return;
    if (controller._flights.of(tab) != null) return;
    if (!thumbInView(tab)) _jumpToThumbNow(tab);
  }

  // Jumps to the tab's thumb now, and once more after the next layout. A
  // tab added or removed in the same frame moves the thumb, and changes the
  // grid's scroll extent only at that layout.
  @override
  void jumpToThumb(T tab) {
    _jumpToThumbNow(tab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _jumpToThumbNow(tab);
    });
  }

  // A tab no longer in the overview has no thumb, such as the expanded tab,
  // removed, until its collapse starts.
  void _jumpToThumbNow(T tab) {
    final index = model.indexOfTab(tab);
    if (index != -1) scrollController.jumpTo(getThumbScrollOffset(index));
  }

  @override
  void animateTo(
    double offset, {
    required Duration duration,
    required Curve curve,
  }) {
    scrollController.animateTo(offset, duration: duration, curve: curve);
  }

  // The tab's thumb enters through _buildItemPresence.
  @override
  void addTab(_TabEntry<T> entry, {required Duration duration}) {
    thumbsGridState!.insertItem(model.indexOfEntry(entry), duration: duration);
    _relayoutGrid();
  }

  @override
  void removeTab(
    int index,
    _TabEntry<T> removed, {
    required Duration duration,
  }) {
    thumbsGridState!.removeItem(
      index,
      (context, animation) => _ItemPresence(
        animation: animation,
        endsAt: AnimationStatus.dismissed,
        child: _buildThumb(context, removed),
      ),
      duration: duration,
    );
    _relayoutGrid();
  }

  // A tab added or removed off screen changes no child on screen, so the
  // grid's sliver would skip its next layout and keep the scroll extent it
  // had, a row short or long, and scrolling to a tab on a new last row would
  // stop short of it.
  void _relayoutGrid() => _renderGrid?.markNeedsLayout();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListenableBuilder(
          listenable: controller._flights.changed,
          builder: (context, thumbs) => IgnorePointer(
            ignoring: controller.isTransitioning,
            child: thumbs,
          ),
          child: _buildThumbs(),
        ),
        // Needed to support hero transition
        // if the thumb is off-screen and not rendered.
        ListenableBuilder(
          listenable: model.standInsChanged,
          builder: (context, _) => _buildOffScreenThumbs(),
        ),
      ],
    );
  }

  Widget _buildThumbs() {
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
          child: _items ??= _buildItems(),
        ),
      ),
    );
  }

  Widget _buildItems() => NotificationListener<ScrollMetricsNotification>(
    onNotification: _handleScrollMetricsChanged,
    child: AnimatedReorderable.grid(
      key: thumbsGridKey,
      keyGetter: model.keyAt,
      motion: MotionOptions(
        duration: overview.thumbnailsMotionAnimationDuration,
        curve: overview.thumbnailsMotionAnimationCurve,
      ),
      reorder: ReorderOptions(
        onReorder: controller._reorderTabs,
        draggableGetter: (index) =>
            overview._isRemovable(model[index]) ||
            overview._isReorderable(model[index]),
        reorderableGetter: (index) => overview._isReorderable(model[index]),
      ),
      swipeToRemove: SwipeToRemoveOptions(
        onSwipeToRemove: controller.removeAt,
        directionGetter: (index) =>
            overview._isRemovable(model[index]) ? AxisDirection.left : null,
      ),
      insertTransition: _buildItemPresence,
      gridView: GridView.builder(
        clipBehavior: Clip.none,
        controller: scrollController,
        padding: overview.thumbnailsGridPadding,
        gridDelegate: widget.gridDelegate,
        itemCount: model.tabCount,
        itemBuilder: (context, index) =>
            _buildThumb(context, model.entryAt(index)),
      ),
    ),
  );

  // Every item, a tab's thumb, enters through it: an added tab's with its
  // add animation, and every other's with a completed one. The thumb picks
  // the animation up, as it knows its tab, and the index is left alone.
  Widget _buildItemPresence(
    Widget child,
    int index,
    Animation<double> animation,
  ) => _ItemPresence(
    animation: animation,
    endsAt: AnimationStatus.completed,
    child: child,
  );

  Widget _buildThumb(BuildContext context, _TabEntry<T> entry) =>
      _TabCellBuilder<T>(
        controller: controller,
        entry: entry,
        builder: (context) {
          // The thumb's add or remove animation, while it runs, which the
          // tab's page and stand-in scale and fade with too.
          final presence = _ItemPresence.maybeOf(context);
          if (presence != null) {
            controller._trackTabPresence(
              entry,
              presence.animation,
              endsAt: presence.endsAt,
            );
          }
          return _buildThumbOrEmptyCell(
            context,
            entry,
            presence?.animation ?? kAlwaysCompleteAnimation,
          );
        },
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

    if (entry.hasStandIn) {
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
        if (overview._isRemovable(tab))
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
          controller._flights.createController(entry, vsync, toPage: false),
      flightAnimationFactory: (animationController) =>
          controller._flights.createAnimation(entry, animationController),
      forwardFlightAnimation: (animationController, {from}) =>
          controller._flights.run(entry, animationController, from: from),
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

    return _TabCellBuilder<T>(
      controller: controller,
      entry: entry,
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

/// Builds again when whether its tab is expanded changes, as when the mode
/// changes or a swipe in expanded mode changes the active tab, or whether
/// the tab has a stand-in, without the rest of the grid.
class _TabCellBuilder<T> extends StatefulWidget {
  final TabOverviewController<T> controller;
  final _TabEntry<T> entry;
  final WidgetBuilder builder;

  const _TabCellBuilder({
    required this.controller,
    required this.entry,
    required this.builder,
  });

  @override
  State<_TabCellBuilder<T>> createState() => _TabCellBuilderState<T>();
}

class _TabCellBuilderState<T> extends State<_TabCellBuilder<T>> {
  late bool _expanded;
  late bool _hasStandIn;

  @override
  void initState() {
    super.initState();
    _listenTo(widget.controller, widget.entry);
  }

  @override
  void didUpdateWidget(_TabCellBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.entry != widget.entry) {
      _stopListeningTo(oldWidget.controller, oldWidget.entry);
      _listenTo(widget.controller, widget.entry);
    }
  }

  @override
  void dispose() {
    _stopListeningTo(widget.controller, widget.entry);
    super.dispose();
  }

  void _listenTo(TabOverviewController<T> controller, _TabEntry<T> entry) {
    controller
      ..addActiveTabChangedListener(_handleChange)
      ..addModeChangedListener(_handleModeChanged);
    entry.addListener(_handleChange);
  }

  void _stopListeningTo(
    TabOverviewController<T> controller,
    _TabEntry<T> entry,
  ) {
    controller
      ..removeActiveTabChangedListener(_handleChange)
      ..removeModeChangedListener(_handleModeChanged);
    entry.removeListener(_handleChange);
  }

  void _handleModeChanged(TabOverviewMode _) => _handleChange();

  void _handleChange() {
    if (widget.controller.isTabExpanded(widget.entry.tab) != _expanded ||
        widget.entry.hasStandIn != _hasStandIn) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    _expanded = widget.controller.isTabExpanded(widget.entry.tab);
    _hasStandIn = widget.entry.hasStandIn;
    return widget.builder(context);
  }
}
