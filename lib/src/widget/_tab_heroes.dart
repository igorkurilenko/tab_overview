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

/// Where a tab shows: as its thumbnail, in the grid, or as its page.
enum _TabSide {
  thumbnail,
  page;

  /// The tab's other side.
  _TabSide get other => this == thumbnail ? page : thumbnail;
}

/// Builds the heroes of a tab, on its thumbnail and on its page: the tab's
/// own, its remove button's, and those of its parts, its [TabHero]s. All of
/// them fly between the thumbnail and the page on the tab's flight.
mixin _TabHeroes<T> {
  TabOverviewController<T> get controller;

  TabOverview<T> get overview;

  // What each of a tab's heroes is: the tab itself, its remove button, or one
  // of its parts, by the part's tag.
  static const _tabRole = 'tab';
  static const _removeButtonRole = 'remove button';
  static Object _partRole(Object tag) => ('part', tag);

  // A hero's tag and keys hold the tab's entry, which is equal only to
  // itself. So a tab's heroes pair with each other only, whatever the tab's
  // equality and hash code do, and a tab removed and added again pairs with
  // none of its old heroes. The key of each tells its side.
  static Key _keyOf(Object entry, Object role, _TabSide side) =>
      ValueKey((entry, role, side));

  // The side of [entry]'s tab that [hero], of [role], is on.
  static _TabSide _sideOf(HeroHere hero, Object entry, Object role) =>
      hero.key == _keyOf(entry, role, _TabSide.page)
      ? _TabSide.page
      : _TabSide.thumbnail;

  // The hero that's [role] on [side] of [entry]'s tab, whose flight runs as
  // [flight] says and turns wherever the tab is asked to go next.
  HeroHere _hero(
    _TabEntry<T> entry,
    Object role,
    _TabSide side,
    _FlightWiring flight, {
    HeroHereFlightShuttleBuilder? shuttle,
    required Widget child,
  }) => HeroHere(
    tag: (entry, role),
    key: _keyOf(entry, role, side),
    flightRedirect: HeroHereFlightRedirect.divert,
    flightAnimationControllerFactory: flight.controller,
    flightAnimationFactory: flight.animation,
    forwardFlightAnimation: flight.forward,
    flightShuttleBuilder: shuttle,
    child: child,
  );

  HeroHere tabHero(
    _TabEntry<T> entry, {
    required _TabSide side,
    required Widget child,
  }) => _hero(
    entry,
    _tabRole,
    side,
    controller._flights.leaderOf(entry, toPage: side == _TabSide.page),
    // A thumbnail of the app's own isn't its tab's page, so the flight
    // zooms one into the other. The default thumbnail is the page, which
    // flies alone.
    shuttle: (context, animation, fromHero, toHero) =>
        overview.tabThumbnailBuilder == null
        ? _InTabShuttle(entry: entry, child: toHero.child)
        : _TabZoom<T>(
            overview: overview,
            entry: entry,
            pageShown: _PageShown(
              animation,
              entry,
              toPage: _sideOf(toHero, entry, _tabRole) == _TabSide.page,
            ),
          ),
    child: child,
  );

  // The page's button is hidden, so the flight fades between the page's and
  // the thumbnail's, either way.
  HeroHere removeButtonHero(
    _TabEntry<T> entry, {
    required _TabSide side,
    required Widget child,
  }) => _hero(
    entry,
    _removeButtonRole,
    side,
    controller._flights.followerOf(entry),
    shuttle: side == _TabSide.page ? _buildRemoveButtonFlightShuttle : null,
    child: child,
  );

  /// Wraps what [TabOverview.tabBuilder] or [TabOverview.tabThumbnailBuilder]
  /// builds for [entry]'s tab, on its [side], so its [TabHero]s fly.
  Widget placeTab(
    _TabEntry<T> entry, {
    required _TabSide side,
    required Widget child,
  }) => _TabPlace(
    entry: entry,
    side: side,
    buildPart: (tag, child) => _partHero(entry, tag, side, child),
    child: child,
  );

  // The hero of the part of [entry]'s tab that a [TabHero] with [tag] is,
  // on its [side], which flies in step with the tab.
  Widget _partHero(
    _TabEntry<T> entry,
    Object tag,
    _TabSide side,
    Widget child,
  ) {
    final role = _partRole(tag);
    return _LaidOutSize(
      onLayout: (size) => entry.partSizes[(tag, side)] = size,
      child: _hero(
        entry,
        role,
        side,
        controller._flights.followerOf(entry, part: tag),
        shuttle: (context, animation, fromHero, toHero) {
          final toSide = _sideOf(toHero, entry, role);
          return _buildPartShuttle(
            animation: animation,
            from: fromHero.child,
            fromSize: entry.partSizes[(tag, toSide.other)],
            to: toHero.child,
            toSize: entry.partSizes[(tag, toSide)],
          );
        },
        child: child,
      ),
    );
  }

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
