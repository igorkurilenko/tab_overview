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

/// How long one of the overview's animations takes, and how it eases, or the
/// spring it runs on.
///
/// [TabOverviewController.transition] holds the default for a tab expanding
/// to its page and collapsing to its thumbnail,
/// [TabOverviewController.addRemoveTransition] the one for a tab added or
/// removed, [TabOverviewController.scrollTransition] the one for scrolling
/// to a tab, and [TabOverview.thumbnailsMotion] the one for thumbnails
/// moving to new places in the grid. [TabTransition.spring] makes one that
/// a tab expands and collapses on as on a spring.
@immutable
class TabTransition {
  /// How long the animation takes.
  final Duration duration;

  /// How the animation eases.
  final Curve curve;

  /// The spring a tab expands and collapses on, if [TabTransition.spring]
  /// made this transition.
  final SpringDescription? spring;

  /// Creates a transition that takes [duration] and eases along [curve],
  /// [Curves.easeInOut] by default.
  const TabTransition({required this.duration, this.curve = Curves.easeInOut})
    : spring = null;

  /// As [TabOverviewController.transition], a tab expands and collapses on
  /// [spring]: from where it is, at the speed it has, such as a pulled
  /// page's as it's let go. A spring with some bounce, such as one that
  /// `SpringDescription.withDurationAndBounce` makes with a bounce above 0,
  /// carries the tab a little past its page's size or its thumbnail's, and
  /// back:
  ///
  /// ```dart
  /// final controller = TabOverviewController<Tab>(
  ///   transition: TabTransition.spring(
  ///     SpringDescription.withDurationAndBounce(
  ///       duration: const Duration(milliseconds: 350),
  ///       bounce: .15,
  ///     ),
  ///   ),
  /// );
  /// ```
  ///
  /// A call to [TabOverviewController.expand] or
  /// [TabOverviewController.collapse] that passes its own `duration` or
  /// `curve` flies along that instead. Anything else the transition times,
  /// such as a scroll, runs for as long as the spring takes to settle from
  /// rest, along the path it takes.
  factory TabTransition.spring(SpringDescription spring) {
    final curve = _SpringCurve(spring);
    return TabTransition._(
      duration: curve.settlingTime,
      curve: curve,
      spring: spring,
    );
  }

  const TabTransition._({
    required this.duration,
    required this.curve,
    required this.spring,
  });

  // This transition as a call that gives it a [duration] or a [curve] makes
  // it: over that duration, along that curve, and on no spring.
  TabTransition _overriddenBy({Duration? duration, Curve? curve}) =>
      duration == null && curve == null
      ? this
      : TabTransition(
          duration: duration ?? this.duration,
          curve: curve ?? this.curve,
        );

  // A spring's curve is equal to another of an equal spring.
  @override
  bool operator ==(Object other) =>
      other is TabTransition &&
      other.duration == duration &&
      other.curve == curve;

  @override
  int get hashCode => Object.hash(duration, curve);

  @override
  String toString() => 'TabTransition($duration, $curve)';
}

/// How close to its end, and how slow, a tab's flight on a spring has to be
/// to land: a pixel or two from its place on a phone, and too slow to see.
const _kSpringTolerance = Tolerance(distance: .002, velocity: .02);

/// The path [spring] takes from 0 to 1 from rest, over the time it takes to
/// settle.
class _SpringCurve extends Curve {
  _SpringCurve(this.spring)
    : _simulation = SpringSimulation(
        spring,
        0,
        1,
        0,
        tolerance: _kSpringTolerance,
        snapToEnd: true,
      ),
      settlingTime = _settlingTimeOf(spring);

  final SpringDescription spring;

  final SpringSimulation _simulation;

  /// How long the spring takes to settle from rest.
  final Duration settlingTime;

  static Duration _settlingTimeOf(SpringDescription spring) {
    final simulation = SpringSimulation(
      spring,
      0,
      1,
      0,
      tolerance: _kSpringTolerance,
    );
    const step = 1 / 240;
    var seconds = step;
    while (seconds < 10 && !simulation.isDone(seconds)) {
      seconds += step;
    }
    return Duration(microseconds: (seconds * 1e6).round());
  }

  @override
  double transformInternal(double t) => _simulation.x(
    t * settlingTime.inMicroseconds / Duration.microsecondsPerSecond,
  );

  @override
  bool operator ==(Object other) =>
      other is _SpringCurve &&
      other.spring.mass == spring.mass &&
      other.spring.stiffness == spring.stiffness &&
      other.spring.damping == spring.damping;

  @override
  int get hashCode =>
      Object.hash(spring.mass, spring.stiffness, spring.damping);

  @override
  String toString() => '_SpringCurve($spring)';
}
