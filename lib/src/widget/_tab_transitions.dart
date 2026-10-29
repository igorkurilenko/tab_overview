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

/// Decorates a tab's thumbnail or page with what the overview's
/// `tabDecorationBuilder` builds from where the tab is: where it rests, on
/// its thumbnail or, as [onPage] says, its page, or, while it flies, as far
/// as it is between them, lifted off the grid. A page pulled to collapse
/// it, by [pull], turns toward its thumbnail, and lifts, as far as it's
/// pulled.
///
/// The same widgets in every phase. A change of widget type here would
/// re-create the tab content's State, losing its text, focus and scroll
/// position on the first rebuild after a flight.
class _TabDecoration<T> extends StatelessWidget {
  final TabOverview<T> overview;
  final _TabEntry<T> entry;

  /// Whether the tab rests on its page, rather than its thumbnail, while it
  /// neither flies nor is pulled.
  final bool onPage;
  final ValueListenable<double>? pull;
  final Widget child;

  const _TabDecoration({
    required this.overview,
    required this.entry,
    required this.onPage,
    this.pull,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    // A new flight, or the end of one.
    listenable: entry,
    builder: (context, child) {
      final flight = entry.flight;
      return AnimatedBuilder(
        animation: flight?.animation ?? pull ?? kAlwaysCompleteAnimation,
        builder: (context, child) {
          final decoration = overview._buildTabDecoration(
            context,
            entry.tab,
            _zoomOf(flight, pull?.value ?? 0),
          );
          return Container(
            clipBehavior: overview._tabClip(decoration),
            decoration: decoration,
            child: child,
          );
        },
        child: child,
      );
    },
    child: child,
  );

  // Where the tab is: as far as its flight has taken it, or its page is
  // [pulled], or, with neither, where it rests.
  TabZoom _zoomOf(TabFlight? flight, double pulled) {
    if (flight != null) {
      return TabZoom(
        // A flight on a spring may run past either end, where the decoration
        // stays the end's, rather than rounding corners past it.
        expansion: clampDouble(flight.expansion, 0, 1),
        lift: flight.lift,
        // Until it sets off, where it's asked to go, as a page let go of
        // after a pull collapses.
        direction: (flight.started ? flight.headsToPage : flight.toPage)
            ? TabZoomDirection.expand
            : TabZoomDirection.collapse,
      );
    }
    if (pulled > 0) {
      // A page is lifted as far as it's pulled, toward its thumbnail.
      return TabZoom(
        expansion: 1 - pulled,
        lift: pulled,
        direction: TabZoomDirection.collapse,
      );
    }
    return TabZoom(expansion: onPage ? 1 : 0, lift: 0);
  }
}

/// Hands a grid item's add or remove animation, which [endsAt] ends, down to
/// its thumb, whose thumbnail and remove button scale and fade with it.
///
/// animated_reorderable puts every item in the transition it enters with,
/// around the item's subtree, and the remove builder puts the thumb of a
/// tab being removed in one of its own, which the thumb finds first.
class _ItemPresence extends InheritedWidget {
  final Animation<double> animation;
  final AnimationStatus endsAt;

  const _ItemPresence({
    required this.animation,
    required this.endsAt,
    required super.child,
  });

  static _ItemPresence? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ItemPresence>();

  @override
  bool updateShouldNotify(_ItemPresence oldWidget) =>
      animation != oldWidget.animation || endsAt != oldWidget.endsAt;
}

/// Hands a held grid item's animation, which runs to 1 as it's picked up
/// and back to 0 as it's let go, down to its thumb, which builds itself with
/// the overview's heldThumbnailBuilder from it.
///
/// animated_reorderable puts a held item in its decoration, around the
/// item's subtree, which it moves there with its State.
class _ItemHold extends InheritedWidget {
  final Animation<double> animation;

  const _ItemHold({required this.animation, required super.child});

  static _ItemHold? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ItemHold>();

  @override
  bool updateShouldNotify(_ItemHold oldWidget) =>
      animation != oldWidget.animation;
}

/// Scales and fades a tab's thumbnail, page or remove button with
/// [animation] along [curve], in as the tab is added, and out as it's
/// removed.
///
/// The same widgets whether or not the tab is being added or removed, so
/// its content keeps its State when the animation ends.
class _TabPresence extends StatelessWidget {
  final Animation<double> animation;
  final Curve curve;
  final Widget child;

  const _TabPresence({
    required this.animation,
    required this.curve,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Driven anew on each build, a curve listens to nothing of its own.
    final curved = curve == Curves.linear
        ? animation
        : animation.drive(CurveTween(curve: curve));
    return ScaleTransition(
      scale: curved,
      child: FadeTransition(opacity: curved, child: child),
    );
  }
}

/// [parent]'s value, kept from 0 to 1, as a spring may carry it past either,
/// along [curve], or, if it [fadesOut], what's left of 1 after that.
class _Eased extends Animation<double> with AnimationWithParentMixin<double> {
  @override
  final Animation<double> parent;

  final Curve curve;

  final bool fadesOut;

  _Eased(this.parent, this.curve, {this.fadesOut = false});

  @override
  double get value {
    final eased = curve.transform(clampDouble(parent.value, 0, 1));
    return fadesOut ? 1 - eased : eased;
  }
}
