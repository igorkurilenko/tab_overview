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

part of 'tab_overview.dart';

/// Switches the overview between its grid and its pages as a tab expands
/// and collapses: where the switch heads, which tab is asked to fly where,
/// an off-screen tab's expand that waits a frame for its stand-in, and a
/// switch taken back before the overview builds the tab's page.
///
/// The controller is its façade: its methods check what they're given,
/// work out how the tab flies, and ask for the switch. [_TabFlights] flies
/// the tabs.
class _ModeSwitch<T> {
  _ModeSwitch(this._controller, {required bool expanded})
    : _phase = expanded ? const _Expanded() : const _Overview();

  final TabOverviewController<T> _controller;

  // Where the overview's switch heads: to the grid, to the pages, or to the
  // pages once an off-screen tab's stand-in is built.
  _Phase<T> _phase;

  _TabOverviewModel<T> get _model => _controller._model;

  TabOverviewMode get mode => switch (_phase) {
    _Expanded() => TabOverviewMode.expanded,
    _Overview() || _ExpandWaiting() => TabOverviewMode.overview,
  };

  bool get expanded => mode == TabOverviewMode.expanded;

  bool get overview => mode == TabOverviewMode.overview;

  /// Makes [tab], whose entry is [entry], active, as
  /// [TabOverviewController.activeTab] is set to it.
  void activate(T? tab, _TabEntry<T>? entry) {
    if (entry != null && _phase is _ExpandWaiting) {
      // An expand waits for its stand-in: it turns to this tab.
      _controller.expand(entry.tab);
    } else if (entry != null && _onPages) {
      _turnPagesTo(tab, entry);
    } else {
      // On the grid, or before the overview is built, which builds the
      // pages at the active tab.
      _controller._setActiveTab(tab);
    }
  }

  // Whether the overview is built, and shows the pages or switches to them.
  bool get _onPages => expanded && _controller._thumbnails != null;

  // Makes [tab], whose entry is [entry], active on the pages: the switch to
  // them turns to it, or they turn to its page.
  void _turnPagesTo(T? tab, _TabEntry<T> entry) {
    final active = _controller._activeTab == null
        ? null
        : _model.entryOf(_controller._activeTab as T);
    final pages = _controller._pages;
    if (pages == null && active != null) {
      // Expanded since the last frame, the overview has no pages yet. The
      // expand turns to this tab, as it would for an expand of it.
      _controller.expand(entry.tab);
    } else if (active?.flight?.toPage ?? false) {
      // Still flying to its page, the active tab flies back to its
      // thumbnail, as this tab's page opens. Its page going away from under
      // its flight would leave its thumbnail hidden.
      _controller.collapse();
      _controller.expand(entry.tab);
    } else {
      _controller._setActiveTab(tab);
      pages?.jumpToPage(_model.indexOfEntry(entry));
    }
  }

  /// Expands [tab], whose entry is [entry], by [asked].
  void expand(T tab, _TabEntry<T> entry, TabTransition asked) {
    if (_controller._thumbnails == null) {
      // Before the overview is built, with nothing to fly between: it
      // builds the pages at the active tab.
      _controller._setActiveTab(tab);
      if (!expanded) _switchTo(const _Expanded());
      return;
    }

    if (expanded && _controller._pages != null) {
      // On the pages, they scroll to the tab's.
      _controller.scrollToTab(
        tab,
        duration: asked.duration,
        curve: asked.curve,
      );
      return;
    }

    // Expanded to this tab since the last frame, the overview shows its
    // page as soon as it builds the pages.
    if (expanded && _controller.isActiveTab(tab)) return;
    _takeBackExpandsOtherThan(entry);
    _controller._setActiveTab(tab);

    final flight = TabFlight(toPage: true, transition: asked);
    if (!_controller._thumbnails!.thumbBuilt(tab)) {
      _expandOffScreen(entry, flight);
    } else {
      _expandWith(entry, flight);
    }
  }

  // Takes back the expand of a tab other than [entry]'s, as [entry]'s tab
  // expands: one to another tab since the last frame, whose page the
  // overview has yet to build, so the expand turns to this tab instead, or
  // one that waits for its stand-in.
  void _takeBackExpandsOtherThan(_TabEntry<T> entry) {
    if (expanded) {
      _takeBackExpand(_model.entryOf(_controller.activeTab as T)!);
    }
    if (_phase case _ExpandWaiting(entry: final waiting)
        when waiting != entry) {
      _takeBackWaitingExpand();
    }
  }

  /// Collapses the active tab by [asked], flung at [velocity] from
  /// [expansion] of the way and [lift] off the grid, if given.
  void collapse(
    TabTransition asked, {
    double? velocity,
    double? expansion,
    double lift = 0,
  }) {
    if (overview) {
      _takeBackWaitingExpand();
      return;
    }

    final tab = _controller.activeTab as T;
    final entry = _model.entryOf(tab);
    // An active tab removed while expanded collapses on its own.
    if (entry == null) return;

    if (_controller._thumbnails == null) {
      // Before the overview is built, with nothing to fly between.
      _switchTo(const _Overview());
      return;
    }

    final flight = TabFlight(
      toPage: false,
      transition: asked,
      velocity: velocity,
      expansion: expansion,
      lift: lift,
    );
    // The stand-in is where the flight lands, which the switch looks for
    // after its frame, so it's there in time.
    if (!_controller._thumbnails!.thumbBuilt(tab)) _model.addStandIn(entry);
    _collapseWith(entry, flight);
  }

  /// Collapses the expanded tab, [removed], to a stand-in, as its thumbnail
  /// goes too, its flight taking [duration]. At once, so the switch finds
  /// the tab's page where the last frame left it: a rebuild of the pages
  /// before the switch, such as one for a tab added, or the parent's, builds
  /// them without it, and leaves the flight nothing to set off from.
  void collapseRemoved(_TabEntry<T> removed, {required Duration duration}) {
    if (_controller._pages == null) {
      // Removed before the overview built its page, so it has no page to
      // collapse from. The overview goes back to the grid before it shows a
      // page, and stays where it was.
      _takeBackExpand(removed);
      return;
    }

    _model.addStandIn(removed);
    _collapseWith(
      removed,
      TabFlight(
        toPage: false,
        transition: TabTransition(
          duration: duration,
          curve: _controller.transition.curve,
        ),
      ),
    );
  }

  /// Takes back the expand of [removed]'s tab if it waits for its stand-in:
  /// the tab, removed, stays in the grid.
  void takeBackWaitingExpandOf(_TabEntry<T> removed) {
    if (_phase case _ExpandWaiting(entry: final waiting)
        when waiting == removed) {
      _takeBackWaitingExpand();
    }
  }

  /// As the controller goes away: an expand waiting for its stand-in never
  /// switches.
  void dispose() {
    if (_phase is _ExpandWaiting) _phase = const _Overview();
  }

  // Switches the overview to the grid or to the pages, and tells of it.
  void _switchTo(_Phase<T> phase) {
    _phase = phase;
    _controller._notifyModeChanged(mode);
  }

  // The stand-in is where the flight sets off, which the switch finds in the
  // frame before it, so the switch waits a frame for it to be built.
  void _expandOffScreen(_TabEntry<T> entry, TabFlight flight) {
    _model.addStandIn(entry);
    final waiting = _ExpandWaiting(entry);
    _phase = waiting;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Taken back, or turned to another tab, in the meantime.
      if (!identical(_phase, waiting)) return;
      _phase = const _Overview();
      _expandWith(entry, flight);
    });
  }

  // Takes back the expand waiting for its stand-in, if any: the tab stays
  // on its thumbnail.
  void _takeBackWaitingExpand() {
    if (_phase case _ExpandWaiting(:final entry)) {
      _phase = const _Overview();
      _model.removeStandIn(entry);
    }
  }

  void _expandWith(_TabEntry<T> entry, TabFlight flight) {
    _controller._flights.ask(entry, flight);
    // Collapsed in the same frame, the overview still has the pages, and
    // switches back to them with the page where the collapse left it.
    _controller._pages?.jumpToPage(_model.indexOfEntry(entry));

    _switchTo(const _Expanded());
  }

  // Takes back the switch to the tab's page before the overview builds it:
  // the tab stays on its thumbnail, or keeps flying back to it.
  void _takeBackExpand(_TabEntry<T> entry) {
    final flight = entry.flight;
    if (flight != null && flight.started) {
      flight.ask(toPage: false);
    } else {
      _controller._flights.settle(entry);
    }

    _switchTo(const _Overview());
  }

  void _collapseWith(_TabEntry<T> entry, TabFlight flight) {
    _controller._flights.ask(entry, flight);

    _switchTo(const _Overview());
  }
}

/// Where the overview's switch heads. The mode is `expanded` in [_Expanded]
/// only: an off-screen tab's expand shows the grid while it waits.
sealed class _Phase<T> {
  const _Phase();
}

/// The grid, shown or switched to.
final class _Overview<T> extends _Phase<T> {
  const _Overview();
}

/// An expand that waits a frame for the stand-in of its tab's thumb, which
/// is off screen, before it switches to the pages. The stand-in is where
/// its flight sets off, which the switch finds in the frame before it.
final class _ExpandWaiting<T> extends _Phase<T> {
  final _TabEntry<T> entry;

  const _ExpandWaiting(this.entry);
}

/// The pages, shown or switched to.
final class _Expanded<T> extends _Phase<T> {
  const _Expanded();
}
