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

/// A tab's flight between its thumbnail and its page, from when it's asked
/// for until the tab lands where it was last asked to go.
///
/// A switch that sends the tab elsewhere mid-flight diverts the flight
/// rather than starting another, so one flight may have several runs, each
/// from where the tab is to where it's asked to go. All of them take the
/// [transition] the flight was first asked with.
///
/// A tab's page pulled to collapse it sets off part of the way to its
/// thumbnail, at the `expansion` it's given, as high off the grid as the
/// pull lifted it, at the `lift` it's given, and flings its first run at
/// [velocity], with no curve, rather than over [duration].
///
/// A flight with a [spring] runs on it instead: each run from where the tab
/// is, at the speed it has, with no curve.
class TabFlight {
  TabFlight({
    required bool toPage,
    required this.transition,
    this.velocity,
    double? expansion,
    double lift = 0,
  }) : _toPage = toPage,
       _headsToPage = !toPage,
       _expansionAtSetOff = expansion ?? (toPage ? 0 : 1),
       _pageShownAtSetOff = toPage ? 0 : 1,
       _liftPhaseAtSetOff = _liftPhaseOf(lift);

  /// How the flight runs: for as long as it says, along its curve, or on
  /// its spring.
  final TabTransition transition;

  Duration get duration => transition.duration;

  Curve get curve => transition.curve;

  /// The spring the flight runs on, if any, rather than along [curve] over
  /// [duration].
  SpringDescription? get spring => transition.spring;

  /// How fast the first run sets off, in runs a second, if it's flung.
  final double? velocity;

  bool _toPage;

  bool _headsToPage;

  double _expansionAtSetOff;

  double _pageShownAtSetOff;

  // Where on its arc the run under way set off: at 0, on the ground, or
  // as far as halfway, where the arc is at its height.
  double _liftPhaseAtSetOff;

  var _started = false;

  var _runs = 0;

  double? _runVelocity;

  final _animation = ProxyAnimation(kAlwaysDismissedAnimation);

  /// Whether the tab is asked to go to its page, rather than its thumbnail.
  bool get toPage => _toPage;

  /// Whether the tab heads for its page on this run, or, before the first
  /// run or after it landed, whether it's on its page.
  bool get headsToPage => _headsToPage;

  /// Whether a flight has started for it and not yet landed.
  bool get started => _started;

  /// The animation of the run under way, from 0 to 1. Until the flight
  /// starts, it stays at 0.
  Animation<double> get animation => _animation;

  /// The speed the run under way was flung at, if it was.
  double? get runVelocity => _runVelocity;

  /// How far the tab is from its thumbnail, at 0, to its page, at 1.
  double get expansion =>
      lerpDouble(_expansionAtSetOff, _headsToPage ? 1 : 0, _animation.value)!;

  /// How far what the tab shows is from its thumbnail's content, at 0, to
  /// its page's, at 1, which a thumbnail of the app's own fades between.
  /// Unlike [expansion], a page pulled to collapse it sets off showing all
  /// of itself, as it did while pulled.
  double get pageShown =>
      lerpDouble(_pageShownAtSetOff, _headsToPage ? 1 : 0, _animation.value)!;

  /// How far the tab is lifted off the grid, from 0, where it rests, to 1:
  /// it rises as the tab leaves where it was and settles as it lands, along
  /// an arc, so a shadow under it grows and fades and nothing jumps. A run
  /// that sets off mid-air, such as a diverted one, goes on from as high as
  /// the tab is. Past its end, as a spring carries it, the tab has landed.
  double get lift {
    final run = clampDouble(_animation.value, 0, 1);
    return sin(pi * lerpDouble(_liftPhaseAtSetOff, 1, run)!);
  }

  // Where on the arc a tab [lift] high is, on its way up.
  static double _liftPhaseOf(double lift) => asin(clampDouble(lift, 0, 1)) / pi;

  /// Asks the tab to go to its page, or to its thumbnail.
  void ask({required bool toPage}) => _toPage = toPage;

  /// Starts with [animation], the flight's.
  void start(Animation<double> animation) {
    _started = true;
    _animation.parent = animation;
  }

  /// Starts a run toward where the tab is asked to go, from where it is.
  /// Returns the speed to fling it at: the flight's [velocity], if any, on
  /// its first run.
  double? setOff() {
    _expansionAtSetOff = expansion;
    _pageShownAtSetOff = pageShown;
    _liftPhaseAtSetOff = _liftPhaseOf(lift);
    _headsToPage = _toPage;
    return _runVelocity = _runs++ == 0 ? velocity : null;
  }

  /// Lands where it headed, to wait for the next switch to start a flight
  /// to where the tab was asked to go since.
  void land() {
    _expansionAtSetOff = expansion;
    _pageShownAtSetOff = pageShown;
    _liftPhaseAtSetOff = 0;
    _started = false;
    _animation.parent = kAlwaysDismissedAnimation;
  }
}

/// A flight's controller, which calls [onDispose] as hero_here disposes it,
/// as the flight ends, however it ends.
///
/// One for a flight on a spring has no bounds, so the spring may carry it
/// past its end and back.
class TabFlightController extends AnimationController {
  final VoidCallback onDispose;

  TabFlightController({
    required super.vsync,
    super.duration,
    bool unbounded = false,
    required this.onDispose,
  }) : super(
         value: 0,
         lowerBound: unbounded ? double.negativeInfinity : 0,
         upperBound: unbounded ? double.infinity : 1,
       );

  @override
  void dispose() {
    try {
      onDispose();
    } finally {
      super.dispose();
    }
  }
}
