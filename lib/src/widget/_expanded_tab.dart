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
    pageController.animateToPage(
      index,
      duration: duration,
      curve: curve,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController = PageController(
        initialPage: controller.indexOfActiveTab(),
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
            child: Opacity(
              opacity: 0,
              child: widget.removeTabButtonBuilder(context, tab),
            ),
          ),
      ],
    );
  }

  Widget _decorate(Widget tabWidget, T tab) {
    if (controller._hasTabExpandAnimationContext(tab)) {
      return _applyAnimatedDecorationOnExpand(tabWidget, tab);
    }

    if (controller._hasTabCollapseAnimationContext(tab)) {
      return _applyAnimatedDecorationOnCollapse(tabWidget, tab);
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: widget.expandedTabDecoration,
      child: tabWidget,
    );
  }

  Widget _applyAnimatedDecorationOnExpand(Widget tabWidget, T tab) {
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
      child: tabWidget,
    );
  }

  Widget _applyAnimatedDecorationOnCollapse(Widget tabWidget, T tab) {
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
      child: tabWidget,
    );
  }

  Widget _maybeAnimateScaleAndFade(Widget tabWidget, T tab) {
    final animation = controller._getTabRemoveAnimation(tab) ??
        controller._getTabInsertAnimation(tab);

    return animation != null
        ? _animateScaleAndFade(animation, tabWidget)
        : tabWidget;
  }

  Widget _animateScaleAndFade(Animation<double> animation, Widget expandedTab) {
    return ScaleTransition(
      scale: animation,
      child: FadeTransition(
        opacity: animation,
        child: expandedTab,
      ),
    );
  }

  AnimationController _createTabHeroFlightAnimationController(
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
    final animationContext = controller._getTabExpandAnimationContext(tab) ??
        controller._getTabCollapseAnimationContext(tab);

    return animationContext!.animation = CurvedAnimation(
      parent: animationController,
      curve: animationContext.curve!,
    );
  }

  Widget _buildRemoveButtonHeroFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroHere fromHero,
    HeroHere toHero,
  ) =>
      Stack(
        children: [
          FadeTransition(
            opacity: ReverseAnimation(animation),
            child: fromHero.child,
          ),
          FadeTransition(
            opacity: animation,
            child: toHero.child,
          ),
        ],
      );
}
