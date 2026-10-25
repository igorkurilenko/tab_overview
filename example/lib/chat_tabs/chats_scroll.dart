// Copyright 2026 Igor Kurilenko
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

// How the chats' cards and pages scroll.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Scrolls as Material does, dragged with any pointer, the mouse too, and,
/// with a [cardExtent], snaps to a whole card of it, its gap to the next
/// included, as a swipe between the chats' pages snaps to a page.
class ChatsScrollBehavior extends MaterialScrollBehavior {
  const ChatsScrollBehavior({this.cardExtent});

  final double? cardExtent;

  @override
  Set<PointerDeviceKind> get dragDevices => PointerDeviceKind.values.toSet();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    final physics = super.getScrollPhysics(context);
    final extent = cardExtent;
    return extent == null
        ? physics
        : _CardSnapPhysics(extent: extent, parent: physics);
  }

  // Cards that snap show no scrollbar, as the chats' pages don't.
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => cardExtent != null
      ? child
      : super.buildScrollbar(context, child, details);

  @override
  bool shouldNotify(ChatsScrollBehavior oldDelegate) =>
      cardExtent != oldDelegate.cardExtent;
}

/// Lets a scroll go on to the card it heads for, a whole [extent] at a time,
/// as [PageScrollPhysics] does a page at a time: a fling on to the next one,
/// and a drag let go of at rest to the nearest.
class _CardSnapPhysics extends ScrollPhysics {
  const _CardSnapPhysics({required this.extent, super.parent});

  final double extent;

  @override
  _CardSnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _CardSnapPhysics(extent: extent, parent: buildParent(ancestor));

  // The offset of the card a scroll at [velocity] heads for.
  double _cardOffset(ScrollMetrics position, double velocity) {
    final tolerance = toleranceFor(position);
    var card = position.pixels / extent;
    if (velocity < -tolerance.velocity) {
      card -= .5;
    } else if (velocity > tolerance.velocity) {
      card += .5;
    }
    return (card.roundToDouble() * extent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // Past an end, the parent brings it back.
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final target = _cardOffset(position, velocity);
    if (target == position.pixels) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: toleranceFor(position),
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
