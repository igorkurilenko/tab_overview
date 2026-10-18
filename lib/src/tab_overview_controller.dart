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

/// The [TabOverviewController] manages the state, behavior, and animations for the [TabOverview] widget,
/// allowing it to switch between `overview` and `expanded` modes, handle tab interactions, and manage animations.
///
/// This controller provides methods to add, remove, reorder, and activate tabs, as well as listeners for changes
/// in tab states, allowing detailed customization of the tab-switching experience.
class TabOverviewController<T> with _TabAnimations<T>, _Listeners<T> {
  TabOverviewMode _mode;
  T? _activeTab;
  final _TabOverviewModel<T> _model;
  GlobalKey<_TabThumbnailsGridState>? _thumbnailsGridKey;
  GlobalKey<_ExpandedTabState>? _expandedTabKey;

  // The tab whose expand waits a frame for its stand-in, as its thumb is
  // off screen, if any. A call that asks for something else in the
  // meantime takes it back.
  _TabEntry<T>? _waitingExpand;

  /// Constructor for [TabOverviewController] to initialize with optional tabs and display mode.
  ///
  /// - [initialTabs]: An optional list of tabs to initialize.
  /// - [initialMode]: The initial mode of display, defaulting to `overview`.
  TabOverviewController({
    List<T>? initialTabs,
    TabOverviewMode initialMode = TabOverviewMode.overview,
    T? activeTab,
  }) : _mode = initialMode,
       _model = _TabOverviewModel<T>(initialTabs: initialTabs),
       _activeTab = (initialTabs?.contains(activeTab) ?? false)
           ? activeTab
           : initialTabs?.first;

  /// The current display mode of the [TabOverview], either `overview` or `expanded`.
  ///
  /// In `overview` mode, tabs are shown as thumbnails; in `expanded` mode, the active tab is shown in detail.
  TabOverviewMode get mode => _mode;

  /// Returns `true` if the current mode is [TabOverviewMode.expanded].
  bool get expanded => mode == TabOverviewMode.expanded;

  /// Returns `true` if the current mode is [TabOverviewMode.overview].
  bool get overview => mode == TabOverviewMode.overview;

  _TabThumbnailsGridState? get _thumbnailsGridState =>
      _thumbnailsGridKey?.currentState;

  _ExpandedTabState? get _expandedTabState => _expandedTabKey?.currentState;

  /// Retrieves the current active tab.
  ///
  /// Setting [activeTab] triggers listeners to update the active tab display.
  T? get activeTab => _activeTab;

  /// Sets the active tab and updates the view if the mode is expanded: the
  /// tab's page shows at once. An expand still under way turns to the tab,
  /// and a tab still flying to its page flies back to its thumbnail, as the
  /// tab's page opens.
  set activeTab(T? value) {
    if (_activeTab == value) return;

    final entry = value == null ? null : _model.entryOf(value);
    final active = _activeTab == null ? null : _model.entryOf(_activeTab as T);
    if (_waitingExpand != null && entry != null) {
      // An expand waits for its stand-in: it turns to this tab.
      expand(entry.tab);
      return;
    }
    // Before the overview is built, it builds the pages at the active tab.
    if (!expanded || entry == null || _thumbnailsGridState == null) {
      _setActiveTab(value);
      return;
    }

    final pages = _expandedTabState;
    if (pages == null && active != null) {
      // Expanded since the last frame, the overview has no pages yet. The
      // expand turns to this tab, as it would for an expand of it.
      expand(entry.tab);
    } else if (active?.flight?.toPage ?? false) {
      // Still flying to its page, the active tab flies back to its
      // thumbnail, as this tab's page opens. Its page going away from under
      // its flight would leave its thumbnail hidden.
      collapse();
      expand(entry.tab);
    } else {
      _setActiveTab(value);
      pages?.jumpToPage(_model.indexOfEntry(entry));
    }
  }

  void _setActiveTab(T? value) {
    if (_activeTab == value) return;

    _activeTab = value;
    // Each thumbnail listens, and rebuilds if its tab expanded or stopped
    // being expanded.
    _notifyActiveTabChanged();
  }

  /// Returns the index of the current active tab in the [tabs] list.
  int? indexOfActiveTab() =>
      activeTab != null ? _model.indexOfTab(activeTab as T) : null;

  /// Checks if the specified [tab] is currently active.
  ///
  /// Returns `true` if [tab] is the active tab.
  bool isActiveTab(T tab) => tab == activeTab;

  /// List of all active tabs managed by this controller.
  List<T> get tabs => _model.tabs;

  /// Checks if a given [tab] is expanded.
  ///
  /// Returns `true` if the [tab] is active and the mode is `expanded`.
  bool isTabExpanded(T tab) => expanded && isActiveTab(tab);

  /// Checks if the tab at a specified [index] is expanded.
  ///
  /// Returns `true` if the tab at [index] is active and the mode is `expanded`.
  bool isTabExpandedAt(int index) => isTabExpanded(tabs[index]);

  void _setThumbnailsGridKey(GlobalKey<_TabThumbnailsGridState>? key) {
    _thumbnailsGridKey = key;
    _model._thumbnailsGridKey = key;
  }

  void _setExpandedTabKey(GlobalKey<_ExpandedTabState>? key) {
    _expandedTabKey = key;
  }

  /// Adds a new tab and animates its appearance, if the tab does not already exist.
  ///
  /// Returns `true` if the tab was added successfully.
  bool add(T newTab, {Duration duration = const Duration(milliseconds: 350)}) {
    if (_model.containsTab(newTab)) return false;

    _model.addTab(newTab, duration: duration);
    _notifyTabAdded(newTab);

    activeTab ??= newTab;

    _expandedTabState?.jumpToPage(indexOfActiveTab()!);
    _expandedTabState?.stateChanged();

    return true;
  }

  /// Removes the specified [tab] and animates its removal.
  ///
  /// Optionally accepts a [duration] for the removal animation.
  void remove(T tab, {Duration duration = const Duration(milliseconds: 350)}) =>
      removeTabAt(tabs.indexOf(tab), duration: duration);

  /// Removes the tab at a specified [index] and animates its removal.
  ///
  /// Removing the active tab makes the tab that takes its place active, or
  /// the one before it if it was the last. Removing the expanded tab also
  /// collapses it, and the mode is `overview` by the time this returns.
  ///
  /// Returns the removed tab.
  T removeTabAt(
    int index, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    // Its add animation, if any, is over, and may never end if its item
    // goes first.
    _model.entryAt(index).presence = null;
    final removed = _model.removeTabAt(index, duration: duration);
    final removedTab = removed.tab;
    _notifyTabRemoved(removedTab);

    // A tab removed as its expand waits for its stand-in stays in the grid.
    if (_waitingExpand == removed) _takeBackWaitingExpand();

    if (isActiveTab(removedTab)) {
      if (expanded) _collapseRemoved(removed, duration: duration);
      _setActiveTab(_neighbourOfRemovedTabAt(index));
    } else if (expanded) {
      _expandedTabState?.jumpToPage(indexOfActiveTab()!);
      _expandedTabState?.stateChanged();
    }

    return removedTab;
  }

  // Collapses the expanded tab, removed, to a stand-in, as its thumbnail
  // goes too. At once, so the switch finds the tab's page where the last
  // frame left it: a rebuild of the pages before the switch, such as one
  // for a tab added, or the parent's, builds them without it, and leaves the
  // flight nothing to set off from.
  void _collapseRemoved(_TabEntry<T> removed, {required Duration duration}) {
    if (_expandedTabState == null) {
      // Removed before the overview built its page, so it has no page to
      // collapse from. The overview goes back to the grid before it shows a
      // page, and stays where it was.
      _takeBackExpand(removed);
      return;
    }

    _addStandIn(removed);
    _doCollapse(
      removed,
      TabFlight(
        toPage: false,
        duration: duration,
        curve: HeroHere.defaultFlightAnimationCurve,
      ),
    );
  }

  // The tab that took the removed tab's place, or the one before it if the
  // removed tab was the last.
  T? _neighbourOfRemovedTabAt(int index) =>
      tabs.isNotEmpty ? tabs[index < tabs.length ? index : index - 1] : null;

  /// Toggles between `overview` and `expanded` modes for the active tab.
  ///
  /// Optionally, a [duration] and [curve] can be provided to control the animation.
  void toggleMode({
    Duration duration = HeroHere.defaultFlightAnimationDuration,
    Curve curve = Curves.easeInOut,
  }) {
    if (_model.tabs.isEmpty) return;

    if (expanded) {
      collapse(duration: duration, curve: curve);
    } else {
      final tab = activeTab ??= _model.tabs.last;
      expand(tab, duration: duration, curve: curve);
    }
  }

  /// Expands the tab at a specified [index], switching the mode to `expanded`.
  void expandAt(
    int index, {
    Duration duration = HeroHere.defaultFlightAnimationDuration,
    Curve curve = Curves.easeInOut,
  }) => expand(_model[index], duration: duration, curve: curve);

  /// Expands a specified tab, switching the mode to `expanded`.
  ///
  /// A tab still flying back to its thumbnail turns toward its page from
  /// where it is, over the duration and curve of the flight it's in.
  void expand(
    T tab, {
    Duration duration = HeroHere.defaultFlightAnimationDuration,
    Curve curve = Curves.easeInOut,
  }) {
    final entry = _model.entryOf(tab);
    if (entry == null) {
      throw ArgumentError('Tab $tab not found');
    }

    if (expanded && _expandedTabState != null) {
      scrollToTab(tab, duration: duration, curve: curve);
      return;
    }

    if (expanded) {
      // Expanded since the last frame, the overview has no pages to scroll
      // yet. The expand turns to this tab instead.
      if (isActiveTab(tab)) return;
      _takeBackExpand(_model.entryOf(activeTab as T)!);
    }

    if (_waitingExpand != entry) _takeBackWaitingExpand();
    _setActiveTab(tab);

    final flight = TabFlight(toPage: true, duration: duration, curve: curve);
    if (!_thumbnailsGridState!.thumbBuilt(tab)) {
      _expandOffScreen(entry, flight);
    } else {
      _doExpand(entry, flight);
    }
  }

  /// Scrolls to a specified [tab].
  ///
  /// An optional [duration] and [curve] can control the scroll animation.
  void scrollToTab(
    T tab, {
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOut,
  }) => scrollToTabAt(tabs.indexOf(tab), duration: duration, curve: curve);

  /// Scrolls to the tab at the specified [index].
  ///
  /// Optionally, [duration] and [curve] can be specified for smooth animation.
  void scrollToTabAt(
    int index, {
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOut,
  }) {
    if (expanded) {
      final pages = _expandedTabState;
      if (pages == null) {
        // Expanded since the last frame, with no pages to scroll yet.
        expand(tabs[index], duration: duration, curve: curve);
      } else {
        pages.animateToPage(index, duration: duration, curve: curve);
      }
    } else {
      final offset = _thumbnailsGridState!.getThumbScrollOffset(index);
      _thumbnailsGridState!.animateTo(offset, duration: duration, curve: curve);
    }
  }

  /// Collapses the active tab, returning to `overview` mode and animating the change.
  ///
  /// Accepts optional [duration] and [curve] parameters to control the animation.
  /// A tab still flying to its page turns toward its thumbnail from where it
  /// is, over the duration and curve of the flight it's in.
  void collapse({
    Duration duration = HeroHere.defaultFlightAnimationDuration,
    Curve curve = Curves.easeInOut,
  }) => _collapse(duration: duration, curve: curve);

  // Collapses the active tab from where a pull left its page: [expansion] of
  // the way from its thumbnail to its page, flung at [velocity], in flights
  // a second.
  void _collapseFromPull({
    required double velocity,
    required double expansion,
  }) => _collapse(
    duration: HeroHere.defaultFlightAnimationDuration,
    curve: Curves.easeInOut,
    // A fling the other way would land where it is at once.
    velocity: max(0, velocity),
    expansion: expansion,
  );

  void _collapse({
    required Duration duration,
    required Curve curve,
    double? velocity,
    double? expansion,
  }) {
    if (overview) {
      _takeBackWaitingExpand();
      return;
    }

    final tab = activeTab as T;
    final entry = _model.entryOf(tab);
    // An active tab removed while expanded collapses on its own.
    if (entry == null) return;

    final flight = TabFlight(
      toPage: false,
      duration: duration,
      curve: curve,
      velocity: velocity,
      expansion: expansion,
    );
    // The stand-in is where the flight lands, which the switch looks for
    // after its frame, so it's there in time.
    if (!_thumbnailsGridState!.thumbBuilt(tab)) _addStandIn(entry);
    _doCollapse(entry, flight);
  }

  /// Disposes resources used by the controller.
  void dispose() {
    _activeTab = null;
    _waitingExpand = null;

    for (final entry in _flyingEntries) {
      entry.flight = null;
    }
    _flyingEntries.clear();

    _modeChangedListeners.clear();
    _activeTabChangedListeners.clear();
    _tabAddedListeners.clear();
    _tabRemovedListeners.clear();
    _offScreenThumbTabAddedListeners.clear();
    _offScreenThumbTabRemovedListeners.clear();
    _tabsReorderedListeners.clear();
  }

  void _reorderTabs(Permutations permutations) {
    _model.reorderTabs(permutations);
    _notifyTabsReordered();
  }

  // The stand-in is where the flight sets off, which the switch finds in the
  // frame before it, so the switch waits a frame for it to be built.
  void _expandOffScreen(_TabEntry<T> entry, TabFlight flight) {
    _addStandIn(entry);
    _waitingExpand = entry;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_waitingExpand != entry) return;
      _waitingExpand = null;
      _doExpand(entry, flight);
    });
  }

  // Takes back the expand waiting for its stand-in, if any: the tab stays
  // on its thumbnail.
  void _takeBackWaitingExpand() {
    final entry = _waitingExpand;
    if (entry == null) return;
    _waitingExpand = null;
    _removeStandIn(entry);
  }

  void _doExpand(_TabEntry<T> entry, TabFlight flight) {
    _askForTabFlight(entry, flight);
    // Collapsed in the same frame, the overview still has the pages, and
    // switches back to them with the page where the collapse left it.
    _expandedTabState?.jumpToPage(_model.indexOfEntry(entry));

    _mode = TabOverviewMode.expanded;
    _notifyModeChanged(_mode);
  }

  // Takes back the switch to the tab's page before the overview builds it:
  // the tab stays on its thumbnail, or keeps flying back to it.
  void _takeBackExpand(_TabEntry<T> entry) {
    final flight = entry.flight;
    if (flight != null && flight.started) {
      flight.ask(toPage: false);
    } else {
      _setFlight(entry, null);
      _removeStandIn(entry);
    }

    _mode = TabOverviewMode.overview;
    _notifyModeChanged(_mode);
  }

  void _doCollapse(_TabEntry<T> entry, TabFlight flight) {
    _askForTabFlight(entry, flight);

    _mode = TabOverviewMode.overview;
    _notifyModeChanged(_mode);
  }

  // Asks for the tab to fly where [asked] goes, to its page or its
  // thumbnail: in [asked], which the coming switch starts, or in the flight
  // it's in, which the switch diverts.
  void _askForTabFlight(_TabEntry<T> entry, TabFlight asked) {
    final toPage = asked.toPage;
    final flight = entry.flight;
    if (flight == null) {
      _setFlight(entry, asked);
    } else if (!flight.started && flight.headsToPage == toPage) {
      // Asked back to where it is before the switch, which now won't come,
      // nor a flight for its stand-in.
      _setFlight(entry, null);
      _removeStandIn(entry);
    } else {
      flight.ask(toPage: toPage);
    }
  }

  // hero_here asks the hero the flight lands on for its controller, else the
  // hero it leaves, as the flight starts. [toPage] is whether that's the
  // tab's page, for a flight nobody asked for.
  AnimationController _createTabFlightController(
    _TabEntry<T> entry,
    TickerProvider vsync, {
    required bool toPage,
  }) {
    var flight = entry.flight;
    if (flight == null) {
      flight = TabFlight(
        toPage: toPage,
        duration: HeroHere.defaultFlightAnimationDuration,
        curve: HeroHere.defaultFlightAnimationCurve,
      );
      _setFlight(entry, flight);
    }
    final startedFlight = flight;
    return TabFlightController(
      vsync: vsync,
      duration: flight.duration,
      onDispose: () => _tabFlightEnded(entry, startedFlight),
    );
  }

  Animation<double> _createTabFlightAnimation(
    _TabEntry<T> entry,
    AnimationController controller,
  ) {
    final flight = entry.flight!;
    // A fling sets its own pace.
    final animation = flight.velocity != null
        ? controller
        : CurvedAnimation(parent: controller, curve: flight.curve);
    flight.start(animation);
    return animation;
  }

  // Starts each run of the tab's flight: the first, and one on each divert.
  TickerFuture _runTabFlight(
    _TabEntry<T> entry,
    AnimationController controller, {
    double? from,
  }) {
    final velocity = entry.flight?.setOff();
    return velocity != null
        ? controller.fling(velocity: velocity)
        : controller.forward(from: from);
  }

  // However the flight ended: landed, or stopped by a switch that left no
  // hero for it, or by the overview going away.
  void _tabFlightEnded(_TabEntry<T> entry, TabFlight flight) {
    final tab = entry.tab;
    final landedOnPage = flight.headsToPage;
    if (flight.toPage == landedOnPage) {
      _setFlight(entry, null);
      _removeStandIn(entry);
    } else {
      // Asked elsewhere after the switch that sent it. The next switch
      // starts a flight for that, which needs the stand-in, if any.
      flight.land();
    }

    final grid = _thumbnailsGridState;
    if (landedOnPage && grid != null && !grid.thumbInView(tab)) {
      // After the frame: a flight also ends as the overview goes away.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _thumbnailsGridState?.jumpToThumb(tab);
      });
    }
  }

  void _addStandIn(_TabEntry<T> entry) {
    if (_model.addStandIn(entry)) _notifyOffScreenThumbTabAdded(entry.tab);
  }

  void _removeStandIn(_TabEntry<T> entry) {
    if (_model.removeStandIn(entry)) _notifyOffScreenThumbTabRemoved(entry.tab);
  }

  void _handleExpandedTabPageChanged(int page) {
    final tab = _model[page];
    _setActiveTab(tab);
    _thumbnailsGridState?.jumpToThumb(tab);
  }
}

/// A callback type that is triggered when a new tab is added to the [TabOverview].
///
/// The function takes the added [tab] as a parameter, allowing further actions to be taken
/// in response to a new tab being added.
typedef TabAddedListener<T> = void Function(T tab);

/// A callback type that is triggered when a tab is removed from the [TabOverview].
///
/// The function takes the [removedTab] as a parameter, allowing additional handling,
/// such as cleanup or UI updates in response to the tab removal.
typedef TabRemovedListener<T> = void Function(T removedTab);

/// A callback type that is triggered when the mode of the [TabOverview] changes.
///
/// The function provides the new [mode], which can be either `overview` or `expanded`,
/// allowing response to the mode change, such as UI adjustments.
typedef ModeChangedListener = void Function(TabOverviewMode mode);

/// A callback type that is triggered when the active tab changes.
typedef ActiveTabChangedListener = VoidCallback;

/// A callback type that is triggered when tabs are reordered within the [TabOverview].
typedef TabsReorderedListener = VoidCallback;

mixin _Listeners<T> {
  final _modeChangedListeners = <ModeChangedListener>[];
  final _activeTabChangedListeners = <ActiveTabChangedListener>[];
  final _tabAddedListeners = <TabAddedListener<T>>[];
  final _tabRemovedListeners = <TabRemovedListener<T>>[];
  final _offScreenThumbTabAddedListeners = <TabAddedListener<T>>[];
  final _offScreenThumbTabRemovedListeners = <TabRemovedListener<T>>[];
  final _tabsReorderedListeners = <TabsReorderedListener>[];

  void addModeChangedListener(ModeChangedListener listener) =>
      _modeChangedListeners.add(listener);

  void addActiveTabChangedListener(ActiveTabChangedListener listener) =>
      _activeTabChangedListeners.add(listener);

  void addTabAddedListener(TabAddedListener<T> listener) =>
      _tabAddedListeners.add(listener);

  void addTabRemovedListener(TabRemovedListener<T> listener) =>
      _tabRemovedListeners.add(listener);

  void addTabsReorderedListener(TabsReorderedListener listener) =>
      _tabsReorderedListeners.add(listener);

  void removeModeChangedListener(ModeChangedListener listener) =>
      _modeChangedListeners.remove(listener);

  void removeActiveTabChangedListener(ActiveTabChangedListener listener) =>
      _activeTabChangedListeners.remove(listener);

  void removeTabRemovedListener(TabRemovedListener<T> listener) =>
      _tabRemovedListeners.remove(listener);

  void removeTabAddedListener(TabAddedListener<T> listener) =>
      _tabAddedListeners.remove(listener);

  void removeTabsReorderedListener(TabsReorderedListener listener) =>
      _tabsReorderedListeners.remove(listener);

  void addOffScreenThumbTabAddedListener(TabAddedListener<T> listener) =>
      _offScreenThumbTabAddedListeners.add(listener);

  void addOffScreenThumbTabRemovedListener(TabRemovedListener<T> listener) =>
      _offScreenThumbTabRemovedListeners.add(listener);

  void removeOffScreenThumbTabAddedListener(TabAddedListener<T> listener) =>
      _offScreenThumbTabAddedListeners.remove(listener);

  void removeOffScreenThumbTabRemovedListener(TabRemovedListener<T> listener) =>
      _offScreenThumbTabRemovedListeners.remove(listener);

  void _notifyModeChanged(TabOverviewMode mode) {
    for (var listener in _modeChangedListeners) {
      listener(mode);
    }
  }

  void _notifyActiveTabChanged() {
    for (var listener in _activeTabChangedListeners) {
      listener();
    }
  }

  void _notifyTabAdded(T tab) {
    for (var listener in _tabAddedListeners) {
      listener(tab);
    }
  }

  void _notifyTabRemoved(T removedTab) {
    for (var listener in _tabRemovedListeners) {
      listener(removedTab);
    }
  }

  void _notifyOffScreenThumbTabAdded(T tab) {
    for (var listener in _offScreenThumbTabAddedListeners) {
      listener(tab);
    }
  }

  void _notifyOffScreenThumbTabRemoved(T removedTab) {
    for (var listener in _offScreenThumbTabRemovedListeners) {
      listener(removedTab);
    }
  }

  void _notifyTabsReordered() {
    for (var listener in _tabsReorderedListeners) {
      listener();
    }
  }
}

mixin _TabAnimations<T> {
  /// The entries with a flight, a removed tab's among them.
  final _flyingEntries = <_TabEntry<T>>{};

  /// Tells when a tab starts or stops flying, as the grid ignores taps
  /// while any does.
  final _flightsChanged = _Notifier();

  void _setFlight(_TabEntry<T> entry, TabFlight? flight) {
    entry.flight = flight;
    final changed = flight == null
        ? _flyingEntries.remove(entry)
        : _flyingEntries.add(entry);
    if (changed) _flightsChanged.notify();
  }

  bool get isAnyExpanding =>
      _flyingEntries.any((entry) => entry.flight!.toPage);

  bool get isAnyCollapsing =>
      _flyingEntries.any((entry) => !entry.flight!.toPage);

  bool isExpanding(T tab) => _flightOf(tab)?.toPage ?? false;

  bool isCollapsing(T tab) => !(_flightOf(tab)?.toPage ?? true);

  // The flight of the tab, a removed one too, found by equality, which a tab
  // keeps with itself however its hash code changes.
  TabFlight? _flightOf(T? tab) =>
      _flyingEntries.where((entry) => entry.tab == tab).firstOrNull?.flight;

  // Keeps [animation] as the entry's add or remove animation until it ends.
  // The grid builds an item on every rebuild while it animates, so it may
  // ask for the same animation many times.
  void _trackTabPresence(
    _TabEntry<T> entry,
    Animation<double> animation, {
    required AnimationStatus endsAt,
  }) {
    if (animation.status == endsAt || entry.presence == animation) return;
    entry.presence = animation;

    void handleStatus(AnimationStatus status) {
      if (status != endsAt) return;
      animation.removeStatusListener(handleStatus);
      if (entry.presence == animation) entry.presence = null;
    }

    animation.addStatusListener(handleStatus);
  }
}
