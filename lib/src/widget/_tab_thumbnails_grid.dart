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
  final TabOverviewController<T> controller;
  final ModelWidgetBuilder<T> removeTabButtonBuilder;
  final EdgeInsets? thumbnailsGridPadding;
  final SliverGridDelegate thumbnailsGridDelegate;
  final ModelWidgetBuilder<T> tabThumbBuilder;
  final Duration thumbnailsMotionAnimationDuration;
  final Curve thumbnailsMotionAnimationCurve;
  final ScrollBehavior? scrollBehavior;
  final Decoration thumbnailDecoration;
  final Decoration expandedTabDecoration;

  const _TabThumbnailsGrid({
    super.key,
    required this.controller,
    required this.removeTabButtonBuilder,
    this.thumbnailsGridPadding,
    required this.thumbnailsGridDelegate,
    required this.tabThumbBuilder,
    required this.thumbnailsMotionAnimationDuration,
    required this.thumbnailsMotionAnimationCurve,
    this.scrollBehavior,
    required this.thumbnailDecoration,
    required this.expandedTabDecoration,
  });

  @override
  State<_TabThumbnailsGrid> createState() => _TabThumbnailsGridState<T>();
}

class _TabThumbnailsGridState<T> extends State<_TabThumbnailsGrid<T>>
    with HeroTabHelper<T> {
  final thumbsGridKey = GlobalKey<AnimatedReorderableState>();
  SliverGridLayout? _thumbsGridLayout;
  final scrollController = ScrollController();

  _TabOverviewModel<T> get model => controller._model;

  bool thumbOffScreen(T tab) => thumbOffScreenAt(model.indexOfTab(tab));

  bool thumbOffScreenAt(int index) => !thumbsGridState!.isItemRendered(index);

  TabOverviewController<T> get controller => widget.controller;

  AnimatedReorderableState? get thumbsGridState => thumbsGridKey.currentState;

  double get thumbsGridScale => controller.mode == TabOverviewMode.expanded
      ? kThumbsGridScaleWhenExpanded
      : 1.0;

  double get thumbsGridOpacity => controller.mode == TabOverviewMode.expanded
      ? kThumbsGridOpacityWhenExpanded
      : 1.0;

  Duration? get activeTabHeroAnimationDuration {
    if (controller.activeTab == null) return null;
    final heroAnimationContext = controller
            ._getTabExpandAnimationContext(controller.activeTab as T) ??
        controller._getTabCollapseAnimationContext(controller.activeTab as T);
    return heroAnimationContext?.duration;
  }

  Curve? get activeTabHeroAnimationCurve {
    if (controller.activeTab == null) return null;
    final heroAnimationContext = controller
            ._getTabExpandAnimationContext(controller.activeTab as T) ??
        controller._getTabCollapseAnimationContext(controller.activeTab as T);
    return heroAnimationContext?.curve;
  }

  Size get screenSize => MediaQuery.sizeOf(context);

  double getThumbScrollOffset(int index) {
    final maxOffset = scrollController.position.maxScrollExtent;
    final offset =
        _thumbsGridLayout?.getGeometryForChildIndex(index).scrollOffset ?? 0;
    return min(maxOffset, offset);
  }

  void stateChanged() => setState(() {});

  void animateTo(
    double offset, {
    required Duration duration,
    required Curve curve,
  }) {
    scrollController.animateTo(
      offset,
      duration: duration,
      curve: curve,
    );
  }

  void jumpTo(double offset) {
    scrollController.jumpTo(offset);
  }

  void addTab(
    T tab, {
    required Duration duration,
  }) {
    thumbsGridState!.insertItem(
      model.indexOfTab(tab),
      (context, index, animation) {
        if (animation.status != AnimationStatus.completed) {
          controller._putTabInsertAnimation(tab, animation);
        }

        animation.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            controller._removeTabInsertAnimation(tab);
          }
        });

        return _buildThumb(context, model[index]);
      },
      duration: duration,
    );
  }

  void removeTab(
    int index,
    T removedTab, {
    required Duration duration,
  }) {
    thumbsGridState!.removeItem(
      index,
      (context, animation) {
        if (animation.status != AnimationStatus.dismissed) {
          controller._putTabRemoveAnimation(removedTab, animation);
        }

        animation.addStatusListener((status) {
          if (animation.status == AnimationStatus.dismissed) {
            controller._removeTabRemoveAnimation(removedTab);
          }
        });

        return _buildThumb(context, removedTab);
      },
      duration: duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          ignoring: controller.isAnyExpanding || controller.isAnyCollapsing,
          child: _buildThumbs(widget.thumbnailsGridDelegate),
        ),
        // Needed to support hero transition
        // if the thumb is off-screen and not rendered.
        _buildOffScreenThumbs(),
      ],
    );
  }

  Widget _buildThumbs(SliverGridDelegate gridDelegate) {
    return ScrollConfiguration(
      behavior: widget.scrollBehavior ?? ScrollConfiguration.of(context),
      child: AnimatedScale(
        scale: thumbsGridScale,
        duration: activeTabHeroAnimationDuration ??
            HeroHere.defaultFlightAnimationDuration,
        curve:
            activeTabHeroAnimationCurve ?? HeroHere.defaultFlightAnimationCurve,
        child: AnimatedOpacity(
          opacity: thumbsGridOpacity,
          duration: activeTabHeroAnimationDuration ??
              HeroHere.defaultFlightAnimationDuration,
          curve: controller.mode == TabOverviewMode.expanded
              ? Curves.fastOutSlowIn.flipped
              : Curves.fastOutSlowIn,
          child: AnimatedReorderable.grid(
            key: thumbsGridKey,
            motionAnimationDuration: widget.thumbnailsMotionAnimationDuration,
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
              padding: widget.thumbnailsGridPadding,
              gridDelegate: SliverGridLayoutNotifier(
                gridDelegate: gridDelegate,
                onLayout: (layout) => _thumbsGridLayout = layout,
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

  Widget _buildThumb(BuildContext context, T tab) {
    if (controller.isTabExpanded(tab)) {
      return Container();
    }

    if (model.containsOffScreenThumbTab(tab)) {
      return Container();
    }

    Widget thumb = widget.tabThumbBuilder(context, tab);
    thumb = _decorate(thumb, tab);
    thumb = _maybeAnimateScaleAndFade(thumb, tab);

    Widget removeButton = widget.removeTabButtonBuilder(context, tab);
    removeButton = _maybeAnimateScaleAndFade(removeButton, tab);

    return Stack(
      children: [
        Positioned.fill(
          child: HeroMode(
            enabled: !model.containsOffScreenThumbTab(tab),
            child: HeroHere(
              tag: tabHeroTag(tab),
              key: tabThumbHeroKey(tab),
              flightAnimationControllerFactory: (vsync, duration) {
                final animationContext =
                    controller._getTabExpandAnimationContext(tab) ??
                        controller._getTabCollapseAnimationContext(tab);
                return AnimationController(
                  vsync: vsync,
                  duration: animationContext!.duration,
                )..addStatusListener((status) {
                    if (status == AnimationStatus.completed) {
                      controller._collapseAnimationCompleted(tab);
                    }
                    if (status == AnimationStatus.dismissed) {
                      controller._collapseAnimationDismissed(tab);
                    }
                  });
              },
              flightAnimationFactory: (animationController) {
                final animationContext =
                    controller._getTabExpandAnimationContext(tab) ??
                        controller._getTabCollapseAnimationContext(tab);
                return animationContext!.animation = CurvedAnimation(
                  parent: animationController,
                  curve: animationContext.curve!,
                );
              },
              child: thumb,
            ),
          ),
        ),
        if (model.removable(tab))
          HeroMode(
            enabled: !model.containsOffScreenThumbTab(tab),
            child: HeroHere(
              tag: removeButtonHeroTag(tab),
              key: tabThumbRemoveButtonHeroKey(tab),
              child: removeButton,
            ),
          ),
      ],
    );
  }

  Widget _buildOffScreenThumbs() {
    return Stack(
      children: [
        for (var tab in model.offScreenThumbTabs)
          Positioned(
            top: model.containsTab(tab) &&
                    getThumbScrollOffset(model.indexOfTab(tab)) <
                        scrollController.position.pixels
                ? 0
                : screenSize.height,
            left: screenSize.width / 2,
            child: SizedBox.fromSize(
              size: Size.zero,
              child: _buildOffScreenThumbHero(context, tab),
            ),
          ),
      ],
    );
  }

  Widget _buildOffScreenThumbHero(BuildContext context, T tab) {
    Widget thumb = widget.tabThumbBuilder(context, tab);

    if (controller._hasTabExpandAnimationContext(tab)) {
      final animation = controller._getTabExpandAnimation(tab)!;
      final decorationAnimation = DecorationTween(
        begin: widget.thumbnailDecoration,
        end: widget.expandedTabDecoration,
      ).animate(animation);

      thumb = AnimatedBuilder(
        animation: decorationAnimation,
        builder: (context, child) => Container(
          clipBehavior: Clip.antiAlias,
          decoration: decorationAnimation.value,
          child: child,
        ),
        child: thumb,
      );
    } else if (controller._hasTabCollapseAnimationContext(tab)) {
      final collapseAnimation = controller._getTabCollapseAnimation(tab)!;
      final decorationAnimation = DecorationTween(
        begin: widget.expandedTabDecoration,
        end: widget.thumbnailDecoration,
      ).animate(collapseAnimation);

      thumb = AnimatedBuilder(
        animation: decorationAnimation,
        builder: (context, child) => Container(
          clipBehavior: Clip.antiAlias,
          decoration: decorationAnimation.value,
          child: child,
        ),
        child: thumb,
      );
    } else {
      thumb = Container(
        clipBehavior: Clip.antiAlias,
        decoration: widget.thumbnailDecoration,
        child: thumb,
      );
    }

    return HeroMode(
      enabled: !controller.isTabExpanded(tab),
      child: HeroHere(
        tag: tabHeroTag(tab),
        key: tabThumbHeroKey(tab),
        flightAnimationControllerFactory: (vsync, duration) =>
            _createThumbHeroFlightAnimationController(vsync, duration, tab),
        flightAnimationFactory: (animationController) =>
            _createThumbHeroFligthAnimation(animationController, tab),
        child: thumb,
      ),
    );
  }

  Widget _decorate(Widget thumb, T tab) {
    if (controller._hasTabExpandAnimationContext(tab)) {
      return _applyAnimatedDecorationOnExpand(thumb, tab);
    }

    if (controller._hasTabCollapseAnimationContext(tab)) {
      return _applyAnimatedDecorationOnCollapse(thumb, tab);
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: widget.thumbnailDecoration,
      child: thumb,
    );
  }

  Widget _applyAnimatedDecorationOnExpand(Widget thumb, T tab) {
    final animation = controller._getTabExpandAnimation(tab)!;
    final decorationAnimation = DecorationTween(
      begin: widget.thumbnailDecoration,
      end: widget.expandedTabDecoration,
    ).animate(animation);

    return AnimatedBuilder(
      animation: decorationAnimation,
      builder: (context, child) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: decorationAnimation.value,
        child: child,
      ),
      child: thumb,
    );
  }

  Widget _applyAnimatedDecorationOnCollapse(Widget thumb, T tab) {
    final animation = controller._getTabCollapseAnimation(tab)!;
    final decorationAnimation = DecorationTween(
      begin: widget.expandedTabDecoration,
      end: widget.thumbnailDecoration,
    ).animate(animation);

    return AnimatedBuilder(
      animation: decorationAnimation,
      builder: (context, child) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: decorationAnimation.value,
        child: child,
      ),
      child: thumb,
    );
  }

  Widget _maybeAnimateScaleAndFade(Widget widget, T tab) {
    final animation = controller._getTabRemoveAnimation(tab) ??
        controller._getTabInsertAnimation(tab);

    return animation != null ? _animateScaleAndFade(animation, widget) : widget;
  }

  Widget _animateScaleAndFade(
    Animation<double> animation,
    Widget widget,
  ) =>
      ScaleTransition(
        scale: animation,
        child: FadeTransition(
          opacity: animation,
          child: widget,
        ),
      );

  AnimationController _createThumbHeroFlightAnimationController(
    TickerProvider vsync,
    Duration duration,
    T tab,
  ) {
    final animationContext = controller._getTabExpandAnimationContext(tab) ??
        controller._getTabCollapseAnimationContext(tab);

    return AnimationController(
      vsync: vsync,
      duration: animationContext!.duration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller._collapseOffScreenAnimationCompleted(tab);
        }

        if (status == AnimationStatus.dismissed) {
          controller._collapseOffScreenAnimationDismissed(tab);
        }
      });
  }

  Animation<double> _createThumbHeroFligthAnimation(
    AnimationController animationController,
    T tab,
  ) {
    final animationContext = controller._getTabExpandAnimationContext(tab) ??
        controller._getTabCollapseAnimationContext(tab);

    return animationContext!.animation = CurvedAnimation(
      parent: animationController,
      curve: animationContext.curve!,
    );
  }
}
