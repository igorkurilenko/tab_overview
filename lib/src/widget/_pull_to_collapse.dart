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

// As in hero_here's show details example: how far a page is pulled to
// shrink all the way and to collapse when let go, how fast it moves down to
// collapse when let go however little it's pulled, and how far it shrinks.
const _kPullToCollapseDistance = 50.0;
const _kPullToCollapseVelocity = 300.0;
const _kPulledTabScale = 0.9;

const _kPullGoBackDuration = Duration(milliseconds: 200);

// How long a trackpad's scrolling on the web pauses before the next scroll is
// another swipe, and before a pull it made is let go.
const _kTrackpadSwipePause = Duration(milliseconds: 120);

/// Lets a tab's page be pulled down to collapse the tab, if the overview's
/// `pullToCollapse` is on.
///
/// The page is pulled from the top of its vertical scroll view, by the
/// scroll view's overscroll, or by a vertical drag on a page without one.
/// It shrinks by its layout rather than by a transform, as the flight that
/// collapses it sets off from the rect the page's layout gives it.
///
/// A scroll view that bounces goes on moving as it's let go, and tells of no
/// let-go, so the page tracks the pointer for that, as the example does.
///
/// On the web, a trackpad's two-finger swipe comes as scrolling, with no
/// let-go either, and goes on scrolling after the fingers lift. So it pulls
/// the page only past the top, from the start of the swipe, and collapses
/// the tab once it's pulled far enough. A swipe that stops short of that
/// lets the page go back. A mouse wheel doesn't pull.
///
/// The same widgets whether or not the page is pulled, or pulling is on, so
/// the tab's content keeps its State.
class _PullToCollapse<T> extends StatefulWidget {
  final TabOverview<T> overview;
  final _TabEntry<T> entry;
  final Widget child;

  const _PullToCollapse({
    required this.overview,
    required this.entry,
    required this.child,
  });

  @override
  State<_PullToCollapse<T>> createState() => _PullToCollapseState<T>();
}

class _PullToCollapseState<T> extends State<_PullToCollapse<T>>
    with SingleTickerProviderStateMixin {
  // How far the page is pulled down, in logical pixels.
  late final _distance = AnimationController.unbounded(vsync: this)
    ..addListener(_handleDistanceChanged);

  // Whether the page moves down with the pull. A scroll view that bounces
  // past its top moves the tab's content down itself, so the page doesn't.
  var _followsPull = false;

  // Whether a drag on the page, rather than in a scroll view, pulls it.
  var _dragging = false;

  // How fast the pointer moves, for a pull by a scroll view, let go when
  // the pointer is.
  VelocityTracker? _pointerVelocity;

  // Let go to collapse, the page stays as it is until it's gone, as the
  // flight sets off from where the page is then.
  var _collapsing = false;

  // A trackpad swipe on the web: when it last scrolled, its first scroll,
  // whether it may pull, as it scrolled nothing else first, and how far it
  // has scrolled, for its speed. A pause lets go of its pull.
  Duration? _swipeScrolledAt;
  PointerScrollEvent? _swipeStart;
  var _swipeMayPull = false;
  var _swipeOffset = 0.0;
  VelocityTracker? _swipeVelocity;
  Timer? _swipePause;

  TabOverview<T> get overview => widget.overview;

  TabOverviewController<T> get controller => overview.controller;

  _TabEntry<T> get entry => widget.entry;

  double get _progress =>
      min(_distance.value, _kPullToCollapseDistance) / _kPullToCollapseDistance;

  double get _scale => 1 - (1 - _kPulledTabScale) * _progress;

  bool get _canPull =>
      overview.pullToCollapse &&
      !_collapsing &&
      controller.isTabExpanded(entry.tab) &&
      entry.flight == null;

  @override
  void dispose() {
    _swipePause?.cancel();
    _distance.dispose();
    entry.pull.value = 0;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final on = overview.pullToCollapse;
    return Listener(
      onPointerDown: on ? _handlePointerDown : null,
      onPointerMove: on ? _handlePointerMove : null,
      onPointerUp: on ? _handlePointerUp : null,
      onPointerPanZoomStart: on ? _handlePanZoomStart : null,
      onPointerPanZoomUpdate: on ? _handlePanZoomUpdate : null,
      onPointerPanZoomEnd: on ? _handlePanZoomEnd : null,
      onPointerSignal: on ? _handlePointerSignal : null,
      child: NotificationListener<ScrollNotification>(
        onNotification: on ? _handleScrollNotification : null,
        child: GestureDetector(
          supportedDevices:
              (overview.scrollBehavior ?? ScrollConfiguration.of(context))
                  .dragDevices,
          onVerticalDragStart: on ? _handleDragStart : null,
          onVerticalDragUpdate: on ? _handleDragUpdate : null,
          onVerticalDragEnd: on ? _handleDragEnd : null,
          onVerticalDragCancel: on ? _handleDragCancel : null,
          child: AnimatedBuilder(
            animation: _distance,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _followsPull ? _distance.value : 0),
              child: FractionallySizedBox(
                widthFactor: _scale,
                heightFactor: _scale,
                child: child,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }

  void _handleDistanceChanged() => entry.pull.value = _progress;

  void _handlePointerDown(PointerDownEvent event) =>
      _pointerVelocity = VelocityTracker.withKind(event.kind)
        ..addPosition(event.timeStamp, event.position);

  void _handlePointerMove(PointerMoveEvent event) =>
      _pointerVelocity?.addPosition(event.timeStamp, event.position);

  void _handlePointerUp(PointerUpEvent event) => _letGoOfScrollView();

  void _handlePanZoomStart(PointerPanZoomStartEvent event) =>
      _pointerVelocity = VelocityTracker.withKind(event.kind)
        ..addPosition(event.timeStamp, Offset.zero);

  void _handlePanZoomUpdate(PointerPanZoomUpdateEvent event) =>
      _pointerVelocity?.addPosition(event.timeStamp, event.pan);

  void _handlePanZoomEnd(PointerPanZoomEndEvent event) => _letGoOfScrollView();

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent ||
        event.kind != PointerDeviceKind.trackpad) {
      return;
    }

    final lastScrolledAt = _swipeScrolledAt;
    _swipeScrolledAt = event.timeStamp;
    if (lastScrolledAt == null ||
        event.timeStamp - lastScrolledAt > _kTrackpadSwipePause) {
      // A new swipe.
      _swipeStart = event;
      _swipeMayPull = false;
      _swipeOffset = 0;
      _swipeVelocity = VelocityTracker.withKind(event.kind);
    }

    final delta = event.scrollDelta;
    final vertical = delta.dy.abs() > delta.dx.abs();
    final pulls = vertical && delta.dy < 0;
    final mayPull = identical(event, _swipeStart) ? pulls : _swipeMayPull;
    // Back up, it only takes back a pull.
    if (!mayPull || !vertical || (!pulls && _distance.value == 0)) return;

    // A scroll view the swipe scrolls, being deeper, takes it first.
    GestureBinding.instance.pointerSignalResolver.register(
      event,
      (event) => _pullBySwipe(event as PointerScrollEvent),
    );
  }

  void _pullBySwipe(PointerScrollEvent event) {
    if (identical(event, _swipeStart)) {
      if (!_canPull) return;
      _swipeMayPull = true;
    }
    if (_collapsing) return;

    _swipeOffset -= event.scrollDelta.dy;
    _swipeVelocity!.addPosition(event.timeStamp, Offset(0, _swipeOffset));
    _pull(_distance.value - event.scrollDelta.dy, follows: true);

    _swipePause?.cancel();
    final velocity = _swipeVelocity!.getVelocity();
    if (_progress >= 1) {
      // Pulled far enough, with no let-go to wait for.
      _letGo(velocity);
    } else if (_distance.value > 0) {
      _swipePause = Timer(_kTrackpadSwipePause, () {
        if (!_collapsing && _distance.value > 0) _letGo(velocity);
      });
    }
  }

  // A drag on the page lets go as it ends, which comes after this.
  void _letGoOfScrollView() {
    if (_dragging || _collapsing || _distance.value == 0) return;
    _letGo(_pointerVelocity?.getVelocity() ?? Velocity.zero);
  }

  void _handleDragStart(DragStartDetails details) {
    if (!_canPull) return;
    _dragging = true;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    _pull(_distance.value + details.delta.dy, follows: true);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    if (_distance.value > 0) _letGo(details.velocity);
  }

  void _handleDragCancel() {
    if (!_dragging) return;
    _dragging = false;
    _goBack();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_collapsing || notification.metrics.axis != Axis.vertical) {
      return false;
    }

    switch (notification) {
      case ScrollUpdateNotification(:final metrics, :final scrollDelta):
        final overscroll = metrics.minScrollExtent - metrics.pixels;
        final dragged = notification.dragDetails != null;
        if (!_followsPull && _distance.value > 0) {
          // Pulled on past its top, or bouncing back to it.
          _pull(overscroll, follows: false);
        } else if (overscroll > 0 && dragged) {
          // Pulled past its top, as a scroll view that bounces is. A fling
          // that bounces off it pulls nothing.
          _pull(overscroll, follows: false);
        } else if (_followsPull && dragged) {
          // Pushed back up, the pull gives way as the content scrolls.
          _pull(_distance.value - scrollDelta!, follows: true);
        }
      case OverscrollNotification(:final overscroll, dragDetails: _?)
          when overscroll < 0:
        // Held at its top, as a scroll view that doesn't bounce is.
        _pull(_distance.value - overscroll, follows: true);
    }
    return false;
  }

  // Pulls the page [distance] down, once it may be pulled.
  void _pull(double distance, {required bool follows}) {
    if (_distance.value == 0 && (distance <= 0 || !_canPull)) return;
    _followsPull = follows;
    _distance.value = max(0, distance);
  }

  // Collapses the tab if the page is let go far enough down, or moving down
  // fast enough, and lets it go back otherwise.
  void _letGo(Velocity velocity) {
    final progress = _progress;
    final pixelsPerSecond = velocity.pixelsPerSecond;
    if (progress < 1 && pixelsPerSecond.dy < _kPullToCollapseVelocity) {
      _goBack();
      return;
    }

    _collapsing = true;
    final size = context.size!;
    controller._collapseFromPull(
      // In flights a second, as hero_here's show details example has it.
      velocity: Offset(
        pixelsPerSecond.dx / size.width,
        pixelsPerSecond.dy / size.height,
      ).distance,
      expansion: 1 - progress,
    );
  }

  // A scroll view that bounced brings the content back itself.
  void _goBack() {
    if (!_followsPull) return;
    _distance.animateTo(
      0,
      duration: _kPullGoBackDuration,
      curve: Curves.easeOut,
    );
  }
}
