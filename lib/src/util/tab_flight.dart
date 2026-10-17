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

import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

/// A tab's flight between its thumbnail and its page, from when it's asked
/// for until the tab lands where it was last asked to go.
///
/// A switch that sends the tab elsewhere mid-flight diverts the flight
/// rather than starting another, so one flight may have several runs, each
/// from where the tab is to where it's asked to go. All of them take the
/// [duration] and [curve] the flight was first asked with.
class TabFlight {
  TabFlight({required bool toPage, required this.duration, required this.curve})
    : _toPage = toPage,
      _headsToPage = !toPage,
      _expansionAtSetOff = toPage ? 0 : 1;

  final Duration duration;

  final Curve curve;

  bool _toPage;

  bool _headsToPage;

  double _expansionAtSetOff;

  var _started = false;

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

  /// How far the tab is from its thumbnail, at 0, to its page, at 1.
  double get expansion =>
      lerpDouble(_expansionAtSetOff, _headsToPage ? 1 : 0, _animation.value)!;

  void ask({required bool toPage}) => _toPage = toPage;

  /// Starts with [animation], the flight's.
  void start(Animation<double> animation) {
    _started = true;
    _animation.parent = animation;
  }

  /// Starts a run toward where the tab is asked to go, from where it is.
  void setOff() {
    _expansionAtSetOff = expansion;
    _headsToPage = _toPage;
  }

  /// Lands where it headed, to wait for the next switch to start a flight
  /// to where the tab was asked to go since.
  void land() {
    _expansionAtSetOff = expansion;
    _started = false;
    _animation.parent = kAlwaysDismissedAnimation;
  }
}

/// A flight's controller, which calls [onDispose] as hero_here disposes it,
/// as the flight ends, however it ends.
class TabFlightController extends AnimationController {
  final VoidCallback onDispose;

  TabFlightController({
    required super.vsync,
    super.duration,
    required this.onDispose,
  });

  @override
  void dispose() {
    try {
      onDispose();
    } finally {
      super.dispose();
    }
  }
}
