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
/// tab's, as far as the tab is between them.
///
/// The same widgets in every phase. A change of widget type here would
/// re-create the tab content's State, losing its text, focus and scroll
/// position on the first rebuild after a flight.
class _TabDecoration<T> extends StatelessWidget {
  final TabOverview<T> overview;
  final T tab;
  final Decoration idleDecoration;
  final Widget child;

  const _TabDecoration({
    required this.overview,
    required this.tab,
    required this.idleDecoration,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final flight = overview.controller._tabFlights[tab];

    return AnimatedBuilder(
      animation: flight?.animation ?? kAlwaysCompleteAnimation,
      builder: (context, child) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: flight == null
            ? idleDecoration
            : Decoration.lerp(
                overview.thumbnailDecoration,
                overview.expandedTabDecoration,
                flight.expansion,
              ),
        child: child,
      ),
      child: child,
    );
  }
}

/// Scales and fades a tab's thumbnail, page or remove button in as the tab
/// is added, and out as it's removed.
///
/// The same widgets whether or not the tab is being added or removed, so
/// its content keeps its State when the animation ends.
class _TabPresence<T> extends StatelessWidget {
  final TabOverviewController<T> controller;
  final T tab;
  final Widget child;

  const _TabPresence({
    required this.controller,
    required this.tab,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation =
        controller._getTabRemoveAnimation(tab) ??
        controller._getTabInsertAnimation(tab) ??
        kAlwaysCompleteAnimation;

    return ScaleTransition(
      scale: animation,
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}
