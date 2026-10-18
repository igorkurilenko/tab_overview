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

/// Decorates a tab's thumbnail or page with [idleDecoration] or, while the
/// tab flies, with a decoration between the thumbnail's and the expanded
/// tab's, as far as the tab is between them. A page pulled to collapse it,
/// by [pull], turns toward the thumbnail's as far as it's pulled.
///
/// The same widgets in every phase. A change of widget type here would
/// re-create the tab content's State, losing its text, focus and scroll
/// position on the first rebuild after a flight.
class _TabDecoration<T> extends StatelessWidget {
  final TabOverview<T> overview;
  final _TabEntry<T> entry;
  final Decoration idleDecoration;
  final ValueListenable<double>? pull;
  final Widget child;

  const _TabDecoration({
    required this.overview,
    required this.entry,
    required this.idleDecoration,
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
        builder: (context, child) => Container(
          clipBehavior: overview._tabClip,
          decoration: _decorationFor(flight),
          child: child,
        ),
        child: child,
      );
    },
    child: child,
  );

  Decoration? _decorationFor(TabFlight? flight) {
    final pulled = pull?.value ?? 0;
    final expansion = flight?.expansion ?? (pulled > 0 ? 1 - pulled : null);
    if (expansion == null) return idleDecoration;
    return Decoration.lerp(
      overview.thumbnailDecoration,
      overview.expandedTabDecoration,
      expansion,
    );
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

/// Scales and fades a tab's thumbnail, page or remove button with
/// [animation], in as the tab is added, and out as it's removed.
///
/// The same widgets whether or not the tab is being added or removed, so
/// its content keeps its State when the animation ends.
class _TabPresence extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _TabPresence({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: animation,
    child: FadeTransition(opacity: animation, child: child),
  );
}
