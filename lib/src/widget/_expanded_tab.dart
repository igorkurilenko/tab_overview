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
    with HeroTabHelper
    implements _PagesView {
  late final PageController pageController;

  _TabOverviewModel<T> get model => controller._model;

  TabOverview<T> get overview => widget.overview;

  TabOverviewController<T> get controller => overview.controller;

  @override
  void initState() {
    super.initState();
    pageController = PageController(
      initialPage: controller.activeIndex ?? 0,
      viewportFraction: _kExpandedTabPageViewportFraction,
    );
    controller._attachPages(this);
  }

  @override
  void didUpdateWidget(_ExpandedTab<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldController = oldWidget.overview.controller;
    if (controller != oldController) {
      oldController._detachPages(this);
      controller._attachPages(this);
    }
  }

  @override
  void dispose() {
    controller._detachPages(this);
    pageController.dispose();
    super.dispose();
  }

  @override
  void jumpToPage(int page) => pageController.jumpToPage(page);

  // The pages built again, for the tabs as they are now. A tab added or
  // removed off screen changes no page on screen, so the page view's sliver
  // would skip its next layout and keep the scroll extent it had. A jump or
  // a scroll to a page past it would then stop short, and the view would
  // report the page it stopped at, making that tab active.
  @override
  void stateChanged() {
    setState(() {});
    _renderPages?.markNeedsLayout();
  }

  // The page view's sliver, found from its own Scrollable.
  RenderSliverMultiBoxAdaptor? get _renderPages {
    if (!pageController.hasClients) return null;
    RenderSliverMultiBoxAdaptor? pages;
    void visit(RenderObject object) {
      if (object is RenderSliverMultiBoxAdaptor) {
        pages = object;
      } else if (pages == null) {
        object.visitChildren(visit);
      }
    }

    final scrollable = pageController.position.context.notificationContext;
    final scrollableObject = scrollable?.findRenderObject();
    if (scrollableObject != null) visit(scrollableObject);
    return pages;
  }

  @override
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
      itemBuilder: (context, index) {
        final entry = model.entryAt(index);
        return FractionallySizedBox(
          // The page goes with its tab when a tab before it is removed, so
          // the tab's content keeps its State. Moved by a global key rather
          // than by findChildIndexCallback: a page moved that way has no
          // place in the view until the view lays it out, and a flight to
          // the tab's page measures it before then, as the flight builds
          // while the overview lays out. A page moved by its key is away,
          // which the flight waits out.
          key: GlobalObjectKey(entry),
          widthFactor: 1 / pageController.viewportFraction,
          // Around the remove button's hero too, so its flight sets off
          // from where the pull left the page.
          child: _PullToCollapse<T>(
            overview: overview,
            entry: entry,
            child: _buildExpandedTab(context, entry),
          ),
        );
      },
    );
  }

  Widget _buildExpandedTab(BuildContext context, _TabEntry<T> entry) {
    final tab = entry.tab;
    Widget tabWidget = FittedTab(child: overview.tabBuilder(context, tab));
    tabWidget = _TabDecoration<T>(
      overview: overview,
      entry: entry,
      idleDecoration: overview.expandedTabDecoration,
      pull: entry.pull,
      child: tabWidget,
    );
    tabWidget = _TabPresence(
      animation: entry.presence ?? kAlwaysCompleteAnimation,
      child: tabWidget,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: HeroHere(
            tag: tabHeroTag(entry),
            key: expandedTabHeroKey(entry),
            flightRedirect: HeroHereFlightRedirect.divert,
            flightAnimationControllerFactory: (vsync, duration) => controller
                ._flights
                .createController(entry, vsync, toPage: true),
            flightAnimationFactory: (animationController) =>
                controller._flights.createAnimation(entry, animationController),
            forwardFlightAnimation: (animationController, {from}) =>
                controller._flights.run(entry, animationController, from: from),
            child: tabWidget,
          ),
        ),
        if (overview._isRemovable(tab))
          HeroHere(
            tag: removeButtonHeroTag(entry),
            key: expandedTabRemoveButtonHeroKey(entry),
            flightRedirect: HeroHereFlightRedirect.divert,
            flightAnimationControllerFactory: (vsync, duration) =>
                controller._flights.createButtonController(entry, vsync),
            flightAnimationFactory: (animationController) => controller._flights
                .createButtonAnimation(entry, animationController),
            forwardFlightAnimation: (animationController, {from}) => controller
                ._flights
                .runButton(entry, animationController, from: from),
            flightShuttleBuilder: _buildRemoveButtonHeroFlightShuttle,
            child: IgnorePointer(
              ignoring: true,
              child: Opacity(
                opacity: 0,
                child: overview._buildRemoveTabButton(context, tab),
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
