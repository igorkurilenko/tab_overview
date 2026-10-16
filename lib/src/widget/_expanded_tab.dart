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

class _ExpandedTab<T> extends StatefulWidget {
  final TabOverviewController<T> controller;
  final ModelWidgetBuilder<T> tabBuilder;
  final ModelWidgetBuilder<T> removeTabButtonBuilder;
  final ScrollBehavior? scrollBehavior;
  final Decoration thumbnailDecoration;
  final Decoration expandedTabDecoration;

  const _ExpandedTab({
    super.key,
    required this.controller,
    required this.tabBuilder,
    required this.removeTabButtonBuilder,
    this.scrollBehavior,
    required this.thumbnailDecoration,
    required this.expandedTabDecoration,
  });

  @override
  State<_ExpandedTab> createState() => _ExpandedTabState<T>();
}

class _ExpandedTabState<T> extends State<_ExpandedTab<T>>
    with HeroTabHelper<T> {
  late PageController pageController;

  _TabOverviewModel<T> get model => controller._model;

  TabOverviewController<T> get controller => widget.controller;

  void jumpToPage(int page) => pageController.jumpToPage(page);

  void stateChanged() => setState(() {});

  void animateToPage(
    int index, {
    required Duration duration,
    required Curve curve,
  }) {
    pageController.animateToPage(index, duration: duration, curve: curve);
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController = PageController(
        initialPage: controller.indexOfActiveTab() ?? 0,
        viewportFraction: kExpandedTabPageViewportFraction,
      ),
      scrollBehavior: widget.scrollBehavior,
      onPageChanged: controller._handleExpandedTabPageChanged,
      itemCount: model.tabCount,
      itemBuilder: (context, index) => FractionallySizedBox(
        widthFactor: 1 / pageController.viewportFraction,
        child: _buildExpandedTab(context, model[index]),
      ),
    );
  }

  Widget _buildExpandedTab(BuildContext context, T tab) {
    Widget tabWidget = FittedTab(child: widget.tabBuilder(context, tab));
    tabWidget = _decorate(tabWidget, tab);
    tabWidget = _maybeAnimateScaleAndFade(tabWidget, tab);

    return Stack(
      children: [
        Positioned.fill(
          child: HeroHere(
            tag: tabHeroTag(tab),
            key: expandedTabHeroKey(tab),
            flightAnimationControllerFactory: (vsync, duration) =>
                _createTabHeroFlightAnimationController(vsync, duration, tab),
            flightAnimationFactory: (animationController) =>
                _createTabHeroFligthAnimation(animationController, tab),
            child: tabWidget,
          ),
        ),
        if (model.removable(tab))
          HeroHere(
            tag: removeButtonHeroTag(tab),
            key: expandedTabRemoveButtonHeroKey(tab),
            flightShuttleBuilder: _buildRemoveButtonHeroFlightShuttle,
            child: IgnorePointer(
              ignoring: true,
              child: Opacity(
                opacity: 0,
                child: widget.removeTabButtonBuilder(context, tab),
              ),
            ),
          ),
      ],
    );
  }

  // The same widgets in every phase. A change of widget type here would
  // re-create the tab content's State, losing its text, focus and scroll
  // position on the first rebuild after a flight.
  Widget _decorate(Widget tabWidget, T tab) {
    final Animation<Decoration> decoration;
    if (controller._hasTabExpandAnimationContext(tab)) {
      decoration = DecorationTween(
        begin: widget.thumbnailDecoration,
        end: widget.expandedTabDecoration,
      ).animate(controller._getTabExpandAnimation(tab)!);
    } else if (controller._hasTabCollapseAnimationContext(tab)) {
      decoration = DecorationTween(
        begin: widget.expandedTabDecoration,
        end: widget.thumbnailDecoration,
      ).animate(controller._getTabCollapseAnimation(tab)!);
    } else {
      decoration = AlwaysStoppedAnimation(widget.expandedTabDecoration);
    }

    return AnimatedBuilder(
      animation: decoration,
      builder: (context, child) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: decoration.value,
        child: child,
      ),
      child: tabWidget,
    );
  }

  Widget _maybeAnimateScaleAndFade(Widget tabWidget, T tab) {
    final animation =
        controller._getTabRemoveAnimation(tab) ??
        controller._getTabInsertAnimation(tab);

    return animation != null
        ? _animateScaleAndFade(animation, tabWidget)
        : tabWidget;
  }

  Widget _animateScaleAndFade(Animation<double> animation, Widget expandedTab) {
    return ScaleTransition(
      scale: animation,
      child: FadeTransition(opacity: animation, child: expandedTab),
    );
  }

  AnimationController _createTabHeroFlightAnimationController(
    TickerProvider vsync,
    Duration duration,
    T tab,
  ) {
    final animationContext =
        controller._getTabExpandAnimationContext(tab) ??
        controller._getTabCollapseAnimationContext(tab) ??
        controller._ensureTabCollapseAnimationContext(
          tab,
          duration: HeroHere.defaultFlightAnimationDuration,
          curve: HeroHere.defaultFlightAnimationCurve,
        );

    return AnimationController(
      vsync: vsync,
      duration: animationContext.duration,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller._expandAnimationCompleted(tab);
      }
      if (status == AnimationStatus.dismissed) {
        controller._expandAnimationDismissed(tab);
      }
    });
  }

  Animation<double> _createTabHeroFligthAnimation(
    AnimationController animationController,
    T tab,
  ) {
    final animationContext =
        controller._getTabExpandAnimationContext(tab) ??
        controller._getTabCollapseAnimationContext(tab) ??
        controller._ensureTabCollapseAnimationContext(
          tab,
          duration: HeroHere.defaultFlightAnimationDuration,
          curve: HeroHere.defaultFlightAnimationCurve,
        );

    return animationContext.animation = CurvedAnimation(
      parent: animationController,
      curve: animationContext.curve!,
    );
  }

  Widget _buildRemoveButtonHeroFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroHere fromHero,
    HeroHere toHero,
  ) => Stack(
    children: [
      FadeTransition(
        opacity: ReverseAnimation(animation),
        child: fromHero.child,
      ),
      FadeTransition(opacity: animation, child: toHero.child),
    ],
  );
}
