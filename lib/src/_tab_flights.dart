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

part of 'tab_overview.dart';

/// The tabs' flights between their thumbnails and their pages: which tab
/// flies where, and what hero_here's heroes ask of a tab's flight as it
/// starts, runs and ends. The controller decides when a tab is asked to fly.
class _TabFlights<T> {
  _TabFlights(this._controller);

  final TabOverviewController<T> _controller;

  /// The entries with a flight, a removed tab's among them.
  final _flying = <_TabEntry<T>>{};

  /// Tells when a tab starts or stops flying, as the grid ignores taps
  /// while any does.
  final changed = _Notifier();

  void set(_TabEntry<T> entry, TabFlight? flight) {
    entry.flight = flight;
    final changes = flight == null ? _flying.remove(entry) : _flying.add(entry);
    if (changes) changed.notify();
  }

  bool get any => _flying.isNotEmpty;

  // Leaves the tab where it is, with no flight, nor a stand-in for one.
  void settle(_TabEntry<T> entry) {
    set(entry, null);
    _controller._removeStandIn(entry);
  }

  // The flight of the tab, a removed one too, found by equality, which a tab
  // keeps with itself however its hash code changes.
  TabFlight? of(T? tab) =>
      _flying.where((entry) => entry.tab == tab).firstOrNull?.flight;

  // As the controller goes away.
  void clear() {
    for (final entry in _flying) {
      entry.flight = null;
    }
    _flying.clear();
  }

  // Asks for the tab to fly where [asked] goes, to its page or its
  // thumbnail: in [asked], which the coming switch starts, or in the flight
  // it's in, which the switch diverts.
  void ask(_TabEntry<T> entry, TabFlight asked) {
    final toPage = asked.toPage;
    final flight = entry.flight;
    if (flight == null) {
      set(entry, asked);
    } else if (!flight.started && flight.headsToPage == toPage) {
      // Asked back to where it is before the switch, which now won't come,
      // nor a flight for its stand-in.
      settle(entry);
    } else {
      flight.ask(toPage: toPage);
    }
  }

  // hero_here asks the hero the flight lands on for its controller, else the
  // hero it leaves, as the flight starts. [toPage] is whether that's the
  // tab's page, for a flight nobody asked for.
  AnimationController createController(
    _TabEntry<T> entry,
    TickerProvider vsync, {
    required bool toPage,
  }) {
    var flight = entry.flight;
    if (flight == null) {
      flight = TabFlight(
        toPage: toPage,
        duration: _controller.transition.duration,
        curve: _controller.transition.curve,
      );
      set(entry, flight);
    }
    final startedFlight = flight;
    return TabFlightController(
      vsync: vsync,
      duration: flight.duration,
      onDispose: () => _ended(entry, startedFlight),
    );
  }

  Animation<double> createAnimation(
    _TabEntry<T> entry,
    AnimationController controller,
  ) {
    final flight = entry.flight!;
    final animation = _animate(
      controller,
      flung: flight.velocity != null,
      curve: flight.curve,
    );
    flight.start(animation);
    return animation;
  }

  // Starts each run of the tab's flight: the first, and one on each divert.
  TickerFuture run(
    _TabEntry<T> entry,
    AnimationController controller, {
    double? from,
  }) {
    final velocity = entry.flight?.setOff();
    return _runForward(controller, velocity: velocity, from: from);
  }

  // The tab's remove button flies in step with the tab: for as long, along
  // the same curve, and flung as fast. Its hero comes after the tab's, so
  // each run of its flight starts after the tab's run has set off.
  AnimationController createButtonController(
    _TabEntry<T> entry,
    TickerProvider vsync,
  ) => AnimationController(
    vsync: vsync,
    duration: entry.flight?.duration ?? _controller.transition.duration,
  );

  Animation<double> createButtonAnimation(
    _TabEntry<T> entry,
    AnimationController controller,
  ) {
    final flight = entry.flight;
    return _animate(
      controller,
      flung: flight?.velocity != null,
      curve: flight?.curve ?? _controller.transition.curve,
    );
  }

  TickerFuture runButton(
    _TabEntry<T> entry,
    AnimationController controller, {
    double? from,
  }) {
    final velocity = entry.flight?.runVelocity;
    return _runForward(controller, velocity: velocity, from: from);
  }

  // A flight that's flung sets its own pace. Any other follows its curve.
  static Animation<double> _animate(
    AnimationController controller, {
    required bool flung,
    required Curve curve,
  }) => flung ? controller : CurvedAnimation(parent: controller, curve: curve);

  // Flings a run at [velocity], if it's flung, or runs it forward [from]
  // where it is told.
  static TickerFuture _runForward(
    AnimationController controller, {
    double? velocity,
    double? from,
  }) => velocity != null
      ? controller.fling(velocity: velocity)
      : controller.forward(from: from);

  // However the flight ended: landed, or stopped by a switch that left no
  // hero for it, or by the overview going away.
  void _ended(_TabEntry<T> entry, TabFlight flight) {
    final tab = entry.tab;
    final landedOnPage = flight.headsToPage;
    if (flight.toPage == landedOnPage) {
      settle(entry);
    } else {
      // Asked elsewhere after the switch that sent it. The next switch
      // starts a flight for that, which needs the stand-in, if any.
      flight.land();
    }

    final grid = _controller._thumbnails;
    if (landedOnPage && grid != null && !grid.thumbInView(tab)) {
      // After the frame: a flight also ends as the overview goes away.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller._thumbnails?.jumpToThumb(tab);
      });
    }
  }
}
