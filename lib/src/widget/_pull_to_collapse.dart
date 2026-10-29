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

/// Lets a tab's page be pulled down to collapse the tab, if the overview's
/// `pullToCollapse` is on.
///
/// The page is pulled by a vertical drag outside its scroll views, such as
/// one on an app bar above a list. A drag that starts in a vertical scroll
/// view never pulls it, whatever the pointer: it goes to the scroll view,
/// which scrolls, unless it doesn't scroll with that pointer, as a list
/// doesn't with a mouse by default. So a list never pulls the page, whether
/// it's at its top or, as a chat's list, at its bottom.
///
/// The page shrinks by its layout rather than by a transform, as the flight
/// that collapses it sets off from the rect the page's layout gives it.
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

  // Whether a drag on the page pulls it.
  var _dragging = false;

  // Let go to collapse, the page stays as it is until it's gone, as the
  // flight sets off from where the page is then.
  var _collapsing = false;

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
    _distance.dispose();
    // After the frame: the page goes as the overview builds, when the grid,
    // which follows the pull, can't rebuild.
    final pull = entry.pull;
    if (pull.value != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => pull.value = 0);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final on = overview.pullToCollapse;
    final devices = (overview.scrollBehavior ?? ScrollConfiguration.of(context))
        .dragDevices;
    final gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
    return RawGestureDetector(
      gestures: {
        _PullGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<_PullGestureRecognizer>(
              () => _PullGestureRecognizer(
                goesDownInScrollView: _goesDownInScrollView,
              ),
              (recognizer) => recognizer
                ..supportedDevices = devices
                ..gestureSettings = gestureSettings
                ..onStart = on ? _handleDragStart : null
                ..onUpdate = on ? _handleDragUpdate : null
                ..onEnd = on ? _handleDragEnd : null
                ..onCancel = on ? _handleDragCancel : null,
            ),
      },
      semantics: _PullSemantics(on ? _handleSemanticPull : null),
      child: AnimatedBuilder(
        animation: _distance,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _distance.value),
          child: FractionallySizedBox(
            widthFactor: _scale,
            heightFactor: _scale,
            child: child,
          ),
        ),
        child: widget.child,
      ),
    );
  }

  // Whether [event] goes down in a vertical scroll view of the page, which
  // keeps the drag from the pull whatever the pointer, though a mouse
  // doesn't scroll a list by default.
  bool _goesDownInScrollView(PointerDownEvent event) {
    final page = context.findRenderObject();
    if (page is! RenderBox || !page.hasSize) return false;
    final hits = BoxHitTestResult();
    page.hitTest(hits, position: page.globalToLocal(event.position));
    final hit = {for (final entry in hits.path) entry.target};
    var found = false;
    void visit(Element element) {
      if (found) return;
      if (element case StatefulElement(state: final ScrollableState scrollable)
          when axisDirectionToAxis(scrollable.axisDirection) == Axis.vertical &&
              hit.contains(
                scrollable.notificationContext?.findRenderObject(),
              )) {
        found = true;
        return;
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return found;
  }

  void _handleDistanceChanged() => entry.pull.value = _progress;

  // A screen reader's scroll of the page, which pulls it as far as a drag
  // would, as a GestureDetector's vertical drag has it.
  void _handleSemanticPull(DragUpdateDetails details) {
    _handleDragStart(DragStartDetails());
    _handleDragUpdate(details);
    _handleDragEnd(DragEndDetails(primaryVelocity: 0));
  }

  void _handleDragStart(DragStartDetails details) {
    if (!_canPull) return;
    _dragging = true;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    _pull(_distance.value + details.delta.dy);
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

  // Pulls the page [distance] down, once it may be pulled.
  void _pull(double distance) {
    if (_distance.value == 0 && (distance <= 0 || !_canPull)) return;
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

  void _goBack() => _distance.animateTo(
    0,
    duration: _kPullGoBackDuration,
    curve: Curves.easeOut,
  );
}

// A vertical drag that doesn't take a pointer that goes down in a vertical
// scroll view, as [goesDownInScrollView] says.
class _PullGestureRecognizer extends VerticalDragGestureRecognizer {
  final bool Function(PointerDownEvent event) goesDownInScrollView;

  _PullGestureRecognizer({required this.goesDownInScrollView});

  @override
  bool isPointerAllowed(PointerEvent event) =>
      super.isPointerAllowed(event) &&
      !(event is PointerDownEvent && goesDownInScrollView(event));
}

// Gives a pullable page the scroll actions a GestureDetector's vertical drag
// gives it, which [onPull] handles.
class _PullSemantics extends SemanticsGestureDelegate {
  final GestureDragUpdateCallback? onPull;

  const _PullSemantics(this.onPull);

  @override
  void assignSemantics(RenderSemanticsGestureHandler renderObject) =>
      renderObject.onVerticalDragUpdate = onPull;
}
