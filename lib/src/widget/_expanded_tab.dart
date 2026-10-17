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
  final TabOverview<T> overview;

  const _ExpandedTab({super.key, required this.overview});

  @override
  State<_ExpandedTab<T>> createState() => _ExpandedTabState<T>();
}

class _ExpandedTabState<T> extends State<_ExpandedTab<T>>
    with HeroTabHelper<T> {
  late final PageController pageController;

  _TabOverviewModel<T> get model => controller._model;

  TabOverview<T> get overview => widget.overview;

  TabOverviewController<T> get controller => overview.controller;

  @override
  void initState() {
    super.initState();
    pageController = PageController(
      initialPage: controller.indexOfActiveTab() ?? 0,
      viewportFraction: kExpandedTabPageViewportFraction,
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

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
      controller: pageController,
      scrollBehavior: overview.scrollBehavior,
      onPageChanged: controller._handleExpandedTabPageChanged,
      itemCount: model.tabCount,
      itemBuilder: (context, index) => FractionallySizedBox(
        widthFactor: 1 / pageController.viewportFraction,
        child: _buildExpandedTab(context, model[index]),
      ),
    );
  }

  Widget _buildExpandedTab(BuildContext context, T tab) {
    Widget tabWidget = FittedTab(child: overview.tabBuilder(context, tab));
    tabWidget = _TabDecoration<T>(
      overview: overview,
      tab: tab,
      idleDecoration: overview.expandedTabDecoration,
      child: tabWidget,
    );
    tabWidget = _TabPresence(
      animation: controller._tabPresence(tab),
      child: tabWidget,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: HeroHere(
            tag: tabHeroTag(tab),
            key: expandedTabHeroKey(tab),
            flightRedirect: HeroHereFlightRedirect.divert,
            flightAnimationControllerFactory: (vsync, duration) =>
                controller._createTabFlightController(tab, vsync, toPage: true),
            flightAnimationFactory: (animationController) =>
                controller._createTabFlightAnimation(tab, animationController),
            forwardFlightAnimation: (animationController, {from}) =>
                controller._runTabFlight(tab, animationController, from: from),
            child: tabWidget,
          ),
        ),
        if (model.removable(tab))
          HeroHere(
            tag: removeButtonHeroTag(tab),
            key: expandedTabRemoveButtonHeroKey(tab),
            flightRedirect: HeroHereFlightRedirect.divert,
            flightShuttleBuilder: _buildRemoveButtonHeroFlightShuttle,
            child: IgnorePointer(
              ignoring: true,
              child: Opacity(
                opacity: 0,
                child: overview.removeTabButtonBuilder(context, tab),
              ),
            ),
          ),
      ],
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
