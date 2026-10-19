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

/// Builds a tab's heroes on its thumbnail and, [onPage], on its page: the
/// tab's own, and its remove button's. Both fly between the thumbnail and
/// the page on the tab's flight.
mixin _TabHeroes<T> {
  TabOverviewController<T> get controller;

  // Tags and keys hold the tab's entry, which is equal only to itself. So a
  // tab's heroes pair with each other only, whatever the tab's equality and
  // hash code do, and a tab removed and added again pairs with neither of
  // its old heroes.
  static Object _tabTag(Object entry) => (entry, 'tab');

  static Key _tabKey(Object entry, {required bool onPage}) =>
      ValueKey((entry, onPage ? 'expanded' : 'thumb'));

  static Object _removeButtonTag(Object entry) => (entry, 'remove button');

  static Key _removeButtonKey(Object entry, {required bool onPage}) => ValueKey(
    (entry, onPage ? 'remove button expanded' : 'remove button thumb'),
  );

  HeroHere tabHero(
    _TabEntry<T> entry, {
    required bool onPage,
    required Widget child,
  }) => HeroHere(
    tag: _tabTag(entry),
    key: _tabKey(entry, onPage: onPage),
    flightRedirect: HeroHereFlightRedirect.divert,
    flightAnimationControllerFactory: (vsync, duration) =>
        controller._flights.createController(entry, vsync, toPage: onPage),
    flightAnimationFactory: (animationController) =>
        controller._flights.createAnimation(entry, animationController),
    forwardFlightAnimation: (animationController, {from}) =>
        controller._flights.run(entry, animationController, from: from),
    child: child,
  );

  // The page's button is hidden, so the flight fades between the page's and
  // the thumbnail's, either way.
  HeroHere removeButtonHero(
    _TabEntry<T> entry, {
    required bool onPage,
    required Widget child,
  }) => HeroHere(
    tag: _removeButtonTag(entry),
    key: _removeButtonKey(entry, onPage: onPage),
    flightRedirect: HeroHereFlightRedirect.divert,
    flightAnimationControllerFactory: (vsync, duration) =>
        controller._flights.createButtonController(entry, vsync),
    flightAnimationFactory: (animationController) =>
        controller._flights.createButtonAnimation(entry, animationController),
    forwardFlightAnimation: (animationController, {from}) =>
        controller._flights.runButton(entry, animationController, from: from),
    flightShuttleBuilder: onPage ? _buildRemoveButtonFlightShuttle : null,
    child: child,
  );

  static Widget _buildRemoveButtonFlightShuttle(
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
