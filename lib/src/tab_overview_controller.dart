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

/// Holds a [TabOverview]'s tabs, its active tab, and whether it shows them as
/// a grid of thumbnails or the active tab as a full page: its [mode].
///
/// [add] and [remove] add and close tabs, [expand] and [collapse] zoom a tab
/// into its page and back out, and [toggleMode] switches between the two.
/// Listeners such as [addTabsReorderedListener] tell when tabs are added,
/// removed or reordered, the mode changes, or another tab becomes active.
///
/// It's a [ChangeNotifier]: it notifies its listeners when the mode, the
/// active tab or the tabs change, so a [ListenableBuilder] can rebuild with
/// it, as with a [ScrollController].
///
/// A method that takes a tab throws an [ArgumentError] for a tab that isn't
/// in the overview, except [remove], which returns `false`, as [add] does
/// for a tab that already is. A method that takes an index throws a
/// [RangeError] for an index out of range. Questions such as [isActiveTab]
/// and [isTabExpanded] answer `false` for a tab that isn't there.
class TabOverviewController<T> extends ChangeNotifier with _Listeners<T> {
  T? _activeTab;
  final _TabOverviewModel<T> _model;

  // Switches the overview between the grid and the pages as tabs expand and
  // collapse.
  late final _ModeSwitch<T> _modeSwitch;

  // The overview's thumbnails grid and its pages, while they're built. They
  // attach themselves, and a newer overview's take over from an older one's.
  _ThumbnailsView<T>? _thumbnails;
  _PagesView? _pages;

  // The tabs' flights between their thumbnails and their pages.
  late final _flights = _TabFlights<T>(this);

  /// How a tab expands to its page and collapses to its thumbnail, unless a
  /// call to [expand], [expandAt], [collapse] or [toggleMode] says otherwise:
  /// 300 ms along [Curves.easeInOut] by default.
  final TabTransition transition;

  /// How a tab added or removed scales and fades in or out, unless a call to
  /// [add], [remove] or [removeAt] says otherwise: 350 ms, linear, by
  /// default. A removal runs the curve backward, from 1 to 0.
  ///
  /// A tab swiped away doesn't scale or fade: it flies off as it is when let
  /// go, at the speed it's let go at, speeding up evenly if it would
  /// otherwise take more than a quarter of a second to get out of sight.
  ///
  /// The expanded tab, removed, flies to its thumbnail's place for as long,
  /// along [transition]'s curve.
  final TabTransition addRemoveTransition;

  /// How [scrollToTab] and [scrollToTabAt] scroll, unless a call says
  /// otherwise: 350 ms along [Curves.easeInOut] by default.
  final TabTransition scrollTransition;

  /// Constructor for [TabOverviewController] to initialize with optional tabs and display mode.
  ///
  /// - [initialTabs]: An optional list of tabs to initialize.
  /// - [initialMode]: The initial mode of display, defaulting to `overview`.
  /// - [activeTab]: The tab active at first, which must be among
  ///   [initialTabs], as the [activeTab] setter refuses a tab that isn't in
  ///   the overview. If null, the first of them is.
  /// - [transition]: How tabs expand and collapse.
  /// - [addRemoveTransition]: How tabs are added and removed.
  /// - [scrollTransition]: How the overview scrolls to a tab.
  TabOverviewController({
    List<T>? initialTabs,
    TabOverviewMode initialMode = TabOverviewMode.overview,
    T? activeTab,
    this.transition = const TabTransition(
      duration: HeroHere.defaultFlightAnimationDuration,
    ),
    this.addRemoveTransition = const TabTransition(
      duration: Duration(milliseconds: 350),
      curve: Curves.linear,
    ),
    this.scrollTransition = const TabTransition(
      duration: Duration(milliseconds: 350),
    ),
  }) : _model = _TabOverviewModel<T>(initialTabs: initialTabs),
       _activeTab = activeTab ?? initialTabs?.firstOrNull {
    _modeSwitch = _ModeSwitch(
      this,
      expanded: initialMode == TabOverviewMode.expanded,
    );
    if (activeTab != null) _entryOrThrow(activeTab);
  }

  /// The current display mode of the [TabOverview], either `overview` or `expanded`.
  ///
  /// In `overview` mode, tabs are shown as thumbnails; in `expanded` mode, the active tab is shown in detail.
  TabOverviewMode get mode => _modeSwitch.mode;

  /// Returns `true` if the current mode is [TabOverviewMode.expanded].
  bool get expanded => mode == TabOverviewMode.expanded;

  /// Returns `true` if the current mode is [TabOverviewMode.overview].
  bool get overview => mode == TabOverviewMode.overview;

  /// The tab the expanded view shows, and that [toggleMode] expands: the
  /// last one expanded, swiped to in the expanded view, or set here,
  /// wherever its thumbnail is scrolled in the overview. Removing it makes
  /// the tab after it active.
  ///
  /// Setting [activeTab] triggers listeners to update the active tab display.
  T? get activeTab => _activeTab;

  /// Sets the active tab and updates the view if the mode is expanded: the
  /// tab's page shows at once. An expand still under way turns to the tab,
  /// and a tab still flying to its page flies back to its thumbnail, as the
  /// tab's page opens.
  ///
  /// Throws an [ArgumentError] for a tab that isn't in the overview, as
  /// [expand] does.
  set activeTab(T? value) {
    if (_activeTab == value) return;

    final entry = value == null ? null : _entryOrThrow(value);
    _modeSwitch.activate(value, entry);
  }

  _TabEntry<T> _entryOrThrow(T tab) =>
      _model.entryOf(tab) ?? (throw ArgumentError('Tab $tab not found'));

  void _setActiveTab(T? value) {
    if (_activeTab == value) return;

    _activeTab = value;
    // Each thumbnail listens, and rebuilds if its tab expanded or stopped
    // being expanded.
    _notifyActiveTabChanged();
  }

  /// The active tab's index in [tabs], or `null` if no tab is active.
  int? get activeIndex {
    final tab = _activeTab;
    return tab == null ? null : _model.indexOfTab(tab);
  }

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

  void _attachThumbnails(_ThumbnailsView<T> grid) {
    _thumbnails = grid;
    _model._thumbnails = grid;
  }

  // Unless a newer overview's grid has taken over.
  void _detachThumbnails(_ThumbnailsView<T> grid) {
    if (!identical(_thumbnails, grid)) return;
    _thumbnails = null;
    _model._thumbnails = null;
  }

  void _attachPages(_PagesView pages) => _pages = pages;

  // Unless a newer overview's pages have taken over.
  void _detachPages(_PagesView pages) {
    if (identical(_pages, pages)) _pages = null;
  }

  /// Adds a new tab and animates its appearance, if the tab does not already exist.
  ///
  /// A [duration] and [curve] override the controller's
  /// [addRemoveTransition].
  ///
  /// Returns `true` if the tab was added successfully.
  bool add(T newTab, {Duration? duration, Curve? curve}) {
    if (_model.containsTab(newTab)) return false;

    final asked = addRemoveTransition._overriddenBy(
      duration: duration,
      curve: curve,
    );
    _model.addTab(newTab, duration: asked.duration, curve: asked.curve);
    _notifyTabAdded(newTab);

    activeTab ??= newTab;
    _showPagesAtActiveTab();

    return true;
  }

  // The pages, if built, for the tabs as they are now, at the active tab's.
  void _showPagesAtActiveTab() {
    _pages?.jumpToPage(activeIndex!);
    _pages?.stateChanged();
  }

  /// Removes the specified [tab] and animates its removal.
  ///
  /// A [duration] and [curve] override the controller's
  /// [addRemoveTransition].
  ///
  /// Returns `false`, and does nothing, if the tab isn't in the overview, as
  /// [add] does for a tab that already is.
  bool remove(T tab, {Duration? duration, Curve? curve}) {
    final index = _model.indexOfTab(tab);
    if (index == -1) return false;
    removeAt(index, duration: duration, curve: curve);
    return true;
  }

  /// Removes the tab at a specified [index] and animates its removal.
  ///
  /// Removing the active tab makes the tab that takes its place active, or
  /// the one before it if it was the last. Removing the expanded tab also
  /// collapses it, and the mode is `overview` by the time this returns.
  ///
  /// A [duration] and [curve] override the controller's
  /// [addRemoveTransition].
  ///
  /// Returns the removed tab.
  T removeAt(int index, {Duration? duration, Curve? curve}) {
    final asked = addRemoveTransition._overriddenBy(
      duration: duration,
      curve: curve,
    );
    // Its add animation, if any, is over, and may never end if its item
    // goes first.
    _model.entryAt(index).presence = null;
    final removed = _model.removeAt(
      index,
      duration: asked.duration,
      curve: asked.curve,
    );
    final removedTab = removed.tab;
    _notifyTabRemoved(removedTab);

    // A tab removed as its expand waits for its stand-in stays in the grid.
    _modeSwitch.takeBackWaitingExpandOf(removed);

    if (isActiveTab(removedTab)) {
      if (expanded) {
        _modeSwitch.collapseRemoved(removed, duration: asked.duration);
      }
      _setActiveTab(_neighbourOfRemovedTabAt(index));
    } else if (expanded) {
      _showPagesAtActiveTab();
    }

    return removedTab;
  }

  // The tab that took the removed tab's place, or the one before it if the
  // removed tab was the last.
  T? _neighbourOfRemovedTabAt(int index) =>
      tabs.isNotEmpty ? tabs[index < tabs.length ? index : index - 1] : null;

  /// Toggles between `overview` and `expanded` modes for the active tab.
  ///
  /// A [duration] and [curve] override the controller's [transition].
  void toggleMode({Duration? duration, Curve? curve}) {
    if (_model.tabs.isEmpty) return;

    if (expanded) {
      collapse(duration: duration, curve: curve);
    } else {
      final tab = activeTab ??= _model.tabs.last;
      expand(tab, duration: duration, curve: curve);
    }
  }

  /// Expands the tab at a specified [index], switching the mode to `expanded`.
  ///
  /// A [duration] and [curve] override the controller's [transition].
  void expandAt(int index, {Duration? duration, Curve? curve}) =>
      expand(_model[index], duration: duration, curve: curve);

  /// Expands a specified tab, switching the mode to `expanded`.
  ///
  /// A [duration] and [curve] override the controller's [transition]. A tab
  /// still flying back to its thumbnail turns toward its page from where it
  /// is, over the duration and curve of the flight it's in.
  void expand(T tab, {Duration? duration, Curve? curve}) {
    final entry = _entryOrThrow(tab);
    final asked = transition._overriddenBy(duration: duration, curve: curve);
    _modeSwitch.expand(tab, entry, asked);
  }

  /// Scrolls to a specified [tab].
  ///
  /// A [duration] and [curve] override the controller's [scrollTransition].
  void scrollToTab(T tab, {Duration? duration, Curve? curve}) {
    final index = _model.indexOfEntry(_entryOrThrow(tab));
    scrollToTabAt(index, duration: duration, curve: curve);
  }

  /// Scrolls to the tab at the specified [index].
  ///
  /// A [duration] and [curve] override the controller's [scrollTransition].
  void scrollToTabAt(int index, {Duration? duration, Curve? curve}) {
    RangeError.checkValidIndex(index, tabs, 'index');
    final asked = scrollTransition._overriddenBy(
      duration: duration,
      curve: curve,
    );
    if (expanded) {
      final pages = _pages;
      if (pages == null) {
        // Expanded since the last frame, with no pages to scroll yet.
        expand(tabs[index], duration: asked.duration, curve: asked.curve);
      } else {
        pages.animateToPage(
          index,
          duration: asked.duration,
          curve: asked.curve,
        );
      }
    } else {
      // Before the overview is built, there's no grid to scroll.
      final grid = _thumbnails;
      if (grid == null) return;
      final offset = grid.getThumbScrollOffset(index);
      grid.animateTo(offset, duration: asked.duration, curve: asked.curve);
    }
  }

  /// Collapses the active tab, returning to `overview` mode and animating the change.
  ///
  /// A [duration] and [curve] override the controller's [transition]. A tab
  /// still flying to its page turns toward its thumbnail from where it is,
  /// over the duration and curve of the flight it's in.
  void collapse({Duration? duration, Curve? curve}) => _modeSwitch.collapse(
    transition._overriddenBy(duration: duration, curve: curve),
  );

  // Collapses the active tab from where a pull left its page: [expansion] of
  // the way from its thumbnail to its page, flung at [velocity], in flights
  // a second.
  void _collapseFromPull({
    required double velocity,
    required double expansion,
  }) => _modeSwitch.collapse(
    transition,
    // A fling the other way would land where it is at once.
    velocity: max(0, velocity),
    expansion: expansion,
  );

  /// Disposes resources used by the controller.
  @override
  void dispose() {
    _activeTab = null;
    _modeSwitch.dispose();

    _flights.clear();

    _clearListeners();
    super.dispose();
  }

  void _reorderTabs(ItemMoves moves) {
    _model.reorderTabs(moves);
    _notifyTabsReordered();
  }

  /// Whether any tab is flying between its thumbnail and its page, as it
  /// expands, collapses or is removed. The overview ignores taps on its
  /// thumbnails meanwhile.
  bool get isTransitioning => _flights.any;

  void _handleExpandedTabPageChanged(int page) {
    final tab = _model[page];
    _setActiveTab(tab);
    _thumbnails?.jumpToThumb(tab);
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

// The typed listeners. Each change also notifies the controller's
// ChangeNotifier listeners.
mixin _Listeners<T> on ChangeNotifier {
  final _modeChangedListeners = <ModeChangedListener>[];
  final _activeTabChangedListeners = <ActiveTabChangedListener>[];
  final _tabAddedListeners = <TabAddedListener<T>>[];
  final _tabRemovedListeners = <TabRemovedListener<T>>[];
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

  void _clearListeners() {
    _modeChangedListeners.clear();
    _activeTabChangedListeners.clear();
    _tabAddedListeners.clear();
    _tabRemovedListeners.clear();
    _tabsReorderedListeners.clear();
  }

  void _notifyModeChanged(TabOverviewMode mode) =>
      _notify(_modeChangedListeners, (listener) => listener(mode));

  void _notifyActiveTabChanged() =>
      _notify(_activeTabChangedListeners, (listener) => listener());

  void _notifyTabAdded(T tab) =>
      _notify(_tabAddedListeners, (listener) => listener(tab));

  void _notifyTabRemoved(T removedTab) =>
      _notify(_tabRemovedListeners, (listener) => listener(removedTab));

  void _notifyTabsReordered() =>
      _notify(_tabsReorderedListeners, (listener) => listener());

  // Calls each of [listeners], then the ChangeNotifier's. A listener may
  // add or remove listeners, itself too, as a ChangeNotifier's may: those
  // there as the change happens are called, unless removed before their
  // turn, and those added wait for the next change.
  void _notify<L>(List<L> listeners, void Function(L listener) call) {
    for (final listener in List.of(listeners)) {
      if (listeners.contains(listener)) call(listener);
    }
    notifyListeners();
  }
}
