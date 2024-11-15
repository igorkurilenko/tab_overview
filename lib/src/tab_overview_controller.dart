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
class TabOverviewController<T> with _AnimationContexts<T>, _Listeners<T> {
  TabOverviewMode _mode;
  T? _activeTab;
  final _TabOverviewModel<T> _model;
  GlobalKey<_TabThumbnailsGridState>? _thumbnailsGridKey;
  GlobalKey<_ExpandedTabState>? _expandedTabKey;

  /// Constructor for [TabOverviewController] to initialize with optional tabs and display mode.
  ///
  /// - [initialTabs]: An optional list of tabs to initialize.
  /// - [initialMode]: The initial mode of display, defaulting to `overview`.
  TabOverviewController({
    List<T>? initialTabs,
    TabOverviewMode initialMode = TabOverviewMode.overview,
  })  : _mode = initialMode,
        _model = _TabOverviewModel<T>(initialTabs: initialTabs);

  /// The current display mode of the [TabOverview], either `overview` or `expanded`.
  ///
  /// In `overview` mode, tabs are shown as thumbnails; in `expanded` mode, the active tab is shown in detail.
  TabOverviewMode get mode => _mode;

  _TabThumbnailsGridState? get _thumbnailsGridState =>
      _thumbnailsGridKey?.currentState;

  _ExpandedTabState? get _expandedTabState => _expandedTabKey?.currentState;

  /// Retrieves the current active tab.
  ///
  /// Setting [activeTab] triggers listeners to update the active tab display.
  T? get activeTab => _activeTab;

  /// Sets the active tab and updates the view if the mode is expanded.
  set activeTab(T? value) {
    if (_activeTab == value) return;

    _activeTab = value;

    _notifyActiveTabChanged();

    if (mode == TabOverviewMode.expanded) {
      _thumbnailsGridState?.stateChanged();
    }
  }

  /// Returns the index of the current active tab in the [tabs] list.
  int? indexOfActiveTab() =>
      activeTab != null ? _model.indexOfTab(activeTab as T) : null;

  /// Checks if the specified [tab] is currently active.
  ///
  /// Returns `true` if [tab] is the active tab.
  bool isActiveTab(T tab) => tab == _activeTab;

  /// List of all active tabs managed by this controller.
  List<T> get tabs => _model.tabs;

  /// Checks if a given [tab] is expanded.
  ///
  /// Returns `true` if the [tab] is active and the mode is `expanded`.
  bool isTabExpanded(T tab) =>
      mode == TabOverviewMode.expanded && isActiveTab(tab);

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
  bool add(
    T newTab, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    if (_model.containsTab(newTab)) return false;

    _model.addTab(newTab, duration: duration);
    _notifyTabAdded(newTab);

    _ensureActiveTab();
    _expandedTabState?.jumpToPage(indexOfActiveTab()!);
    _expandedTabState?.stateChanged();

    return true;
  }

  /// Removes the specified [tab] and animates its removal.
  ///
  /// Optionally accepts a [duration] for the removal animation.
  void remove(
    T tab, {
    Duration duration = const Duration(milliseconds: 350),
  }) =>
      removeTabAt(tabs.indexOf(tab), duration: duration);

  /// Removes the tab at a specified [index] and animates its removal.
  ///
  /// Returns the removed tab.
  T removeTabAt(
    int index, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    final removedTab = _model.removeTabAt(index, duration: duration);
    _notifyTabRemoved(removedTab);

    if (removedTab != activeTab) {
      _expandedTabState?.jumpToPage(indexOfActiveTab()!);
      _expandedTabState?.stateChanged();
    }

    if (isTabExpanded(removedTab)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _collapseOffScreen(
          duration: duration,
          curve: HeroHere.defaultFlightAnimationCurve,
        );
      });
    }

    return removedTab;
  }

  /// Toggles between `overview` and `expanded` modes for the active tab.
  ///
  /// Optionally, a [duration] and [curve] can be provided to control the animation.
  void toggleMode({
    Duration duration = HeroHere.defaultFlightAnimationDuration,
    Curve curve = Curves.easeInOut,
  }) {
    if (_model.tabs.isEmpty) return;

    if (mode == TabOverviewMode.expanded) {
      collapse(
        duration: duration,
        curve: curve,
      );
    } else {
      expand(
        _ensureActiveTab(),
        duration: duration,
        curve: curve,
      );
    }
  }

  /// Expands the tab at a specified [index], switching the mode to `expanded`.
  void expandAt(
    int index, {
    Duration duration = HeroHere.defaultFlightAnimationDuration,
    Curve curve = Curves.easeInOut,
  }) =>
      expand(
        _model[index],
        duration: duration,
        curve: curve,
      );

  /// Expands a specified tab, switching the mode to `expanded`.
  void expand(
    T tab, {
    Duration duration = HeroHere.defaultFlightAnimationDuration,
    Curve curve = Curves.easeInOut,
  }) {
    if (!_model.containsTab(tab)) {
      throw ArgumentError('Tab $tab not found');
    }

    if (mode == TabOverviewMode.expanded) {
      scrollToTab(
        tab,
        duration: duration,
        curve: curve,
      );
      return;
    }

    activeTab = tab;

    if (_thumbnailsGridState!.thumbOffScreen(tab)) {
      _expandOffScreen(tab, duration: duration, curve: curve);
    } else {
      _doExpand(tab, duration: duration, curve: curve);
    }
  }

  /// Scrolls to a specified [tab].
  ///
  /// An optional [duration] and [curve] can control the scroll animation.
  void scrollToTab(
    T tab, {
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOut,
  }) =>
      scrollToTabAt(
        tabs.indexOf(tab),
        duration: duration,
        curve: curve,
      );

  /// Scrolls to the tab at the specified [index].
  ///
  /// Optionally, [duration] and [curve] can be specified for smooth animation.
  void scrollToTabAt(
    int index, {
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOut,
  }) {
    if (mode == TabOverviewMode.expanded) {
      _expandedTabState!.animateToPage(
        index,
        duration: duration,
        curve: curve,
      );
    } else {
      final offset = _thumbnailsGridState!.getThumbScrollOffset(index);
      _thumbnailsGridState!.animateTo(
        offset,
        duration: duration,
        curve: curve,
      );
    }
  }

  /// Collapses the active tab, returning to `overview` mode and animating the change.
  ///
  /// Accepts optional [duration] and [curve] parameters to control the animation.
  void collapse({
    Duration duration = HeroHere.defaultFlightAnimationDuration,
    Curve curve = Curves.easeInOut,
  }) {
    if (mode == TabOverviewMode.overview) return;

    if (_thumbnailsGridState!.thumbOffScreen(activeTab)) {
      _collapseOffScreen(duration: duration, curve: curve);
    } else {
      _doCollapse(duration: duration, curve: curve);
    }
  }

  /// Disposes resources used by the controller.
  void dispose() {
    _expandAnimationContextsByTab.clear();
    _collapseAnimationContextsByTab.clear();

    _insertAnimationByTab.clear();
    _removeAnimationByTab.clear();

    _modeChangedListeners.clear();
    _activeTabChangedListeners.clear();
    _tabAddedListeners.clear();
    _tabRemovedListeners.clear();
    _offScreenThumbTabAddedListeners.clear();
    _offscreenThumbTabRemovedListeners.clear();
    _tabsReorderedListeners.clear();
  }

  void _reorderTabs(Permutations permutations) {
    _model.reorderTabs(permutations);
    _notifyTabsReordered();
  }

  void _expandOffScreen(
    T tab, {
    required Duration duration,
    required Curve curve,
  }) {
    if (_model.addOffScreenThumbTab(tab)) {
      _notifyOffScreenThumbTabAdded(tab);
      _thumbnailsGridState?.stateChanged();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _doExpand(tab, duration: duration, curve: curve);
    });
  }

  void _doExpand(
    T tab, {
    required Duration duration,
    required Curve curve,
  }) {
    _ensureTabExpandAnimationContext(tab)
      ..duration = duration
      ..curve = curve;

    _mode = TabOverviewMode.expanded;
    _notifyModeChanged(_mode);
  }

  void _collapseOffScreen({
    required Duration duration,
    required Curve curve,
  }) {
    if (_model.addOffScreenThumbTab(activeTab as T)) {
      _notifyOffScreenThumbTabAdded(activeTab as T);
      _thumbnailsGridState?.stateChanged();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _doCollapse(duration: duration, curve: curve);
    });
  }

  void _doCollapse({
    required Duration duration,
    required Curve curve,
  }) {
    _ensureTabCollapseAnimationContext(activeTab as T)
      ..duration = duration
      ..curve = curve;

    _mode = TabOverviewMode.overview;
    _notifyModeChanged(_mode);
  }

  void _expandAnimationCompleted(T tab) {
    _removeTabExpandAnimationContext(tab);

    if (_model.removeOffScreenThumbTab(tab)) {
      _notifyOffScreenThumbTabRemoved(tab);
      _thumbnailsGridState?.stateChanged();
    }

    if (_thumbnailsGridState!.thumbOffScreen(tab)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _jumpToThumb(tab);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _jumpToThumb(tab);
        });
      });
    }
  }

  void _expandAnimationDismissed(T tab) {
    _removeTabExpandAnimationContext(tab);

    if (_model.removeOffScreenThumbTab(tab)) {
      _notifyOffScreenThumbTabRemoved(tab);
      _thumbnailsGridState?.stateChanged();
    }
  }

  void _collapseAnimationCompleted(T tab) {
    _removeTabCollapseAnimationContext(tab);

    if (_model.removeOffScreenThumbTab(tab)) {
      _notifyOffScreenThumbTabRemoved(tab);
    }

    _thumbnailsGridState?.stateChanged();
  }

  void _collapseAnimationDismissed(T tab) {
    _removeTabCollapseAnimationContext(tab);

    if (_model.removeOffScreenThumbTab(tab)) {
      _notifyOffScreenThumbTabRemoved(tab);
    }

    _thumbnailsGridState?.stateChanged();
  }

  void _collapseOffScreenAnimationCompleted(tab) {
    _removeTabCollapseAnimationContext(tab);

    if (_model.removeOffScreenThumbTab(tab)) {
      _notifyOffScreenThumbTabRemoved(tab);
    }

    _thumbnailsGridState?.stateChanged();
  }

  void _collapseOffScreenAnimationDismissed(tab) {
    _removeTabCollapseAnimationContext(tab);

    if (_model.removeOffScreenThumbTab(tab)) {
      _notifyOffScreenThumbTabRemoved(tab);
    }

    _thumbnailsGridState?.stateChanged();
  }

  T _ensureActiveTab() {
    assert(_model.tabs.isNotEmpty,
        'Failed to ensure active tab because model has no tabs');

    if (activeTab == null || !_model.containsTab(activeTab as T)) {
      activeTab = _model.tabs.last;
    }

    return activeTab as T;
  }

  void _handleExpandedTabPageChanged(int page) {
    activeTab = _model[page];

    _jumpToThumbAt(page);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToThumbAt(page);
    });
  }

  void _jumpToThumb(T tab) => _jumpToThumbAt(_model.indexOfTab(tab));

  void _jumpToThumbAt(int index) {
    final offset = _thumbnailsGridState!.getThumbScrollOffset(index);
    _thumbnailsGridState!.jumpTo(offset);
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
  final _offscreenThumbTabRemovedListeners = <TabRemovedListener<T>>[];
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
      _offscreenThumbTabRemovedListeners.add(listener);

  void removeOffScreenThumbTabAddedListener(TabAddedListener<T> listener) =>
      _offScreenThumbTabAddedListeners.remove(listener);

  void removeOffScreenThumbTabRemovedListener(TabRemovedListener<T> listener) =>
      _offscreenThumbTabRemovedListeners.remove(listener);

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
    for (var listener in _offscreenThumbTabRemovedListeners) {
      listener(removedTab);
    }
  }

  void _notifyTabsReordered() {
    for (var listener in _tabsReorderedListeners) {
      listener();
    }
  }
}

mixin _AnimationContexts<T> {
  final _expandAnimationContextsByTab = <T, AnimationContext<T>>{};
  final _collapseAnimationContextsByTab = <T, AnimationContext<T>>{};
  final _insertAnimationByTab = <T, Animation<double>>{};
  final _removeAnimationByTab = <T, Animation<double>>{};

  bool get isAnyExpanding => _expandAnimationContextsByTab.isNotEmpty;

  bool get isAnyCollapsing => _collapseAnimationContextsByTab.isNotEmpty;

  bool isExpanding(T tab) => _expandAnimationContextsByTab.containsKey(tab);

  bool isCollapsing(T tab) => _collapseAnimationContextsByTab.containsKey(tab);

  void _putTabInsertAnimation(T tab, Animation<double> animation) =>
      _insertAnimationByTab[tab] = animation;

  Animation<double>? _getTabInsertAnimation(T tab) =>
      _insertAnimationByTab[tab];

  Animation<double>? _removeTabInsertAnimation(T tab) =>
      _insertAnimationByTab.remove(tab);

  void _putTabRemoveAnimation(T tab, Animation<double> animation) =>
      _removeAnimationByTab[tab] = animation;

  Animation<double>? _getTabRemoveAnimation(T tab) =>
      _removeAnimationByTab[tab];

  Animation<double>? _removeTabRemoveAnimation(T tab) =>
      _removeAnimationByTab.remove(tab);

  AnimationContext _ensureTabExpandAnimationContext(T tab) =>
      _expandAnimationContextsByTab.putIfAbsent(tab, () => AnimationContext());

  bool _hasTabExpandAnimationContext(T tab) =>
      _expandAnimationContextsByTab[tab] != null;

  AnimationContext? _getTabExpandAnimationContext(T tab) =>
      _expandAnimationContextsByTab[tab];

  Animation<double>? _getTabExpandAnimation(T tab) =>
      _expandAnimationContextsByTab[tab]?.animation;

  AnimationContext? _removeTabExpandAnimationContext(T tab) =>
      _expandAnimationContextsByTab.remove(tab);

  AnimationContext _ensureTabCollapseAnimationContext(T tab) =>
      _collapseAnimationContextsByTab.putIfAbsent(
          tab, () => AnimationContext());

  bool _hasTabCollapseAnimationContext(T tab) =>
      _collapseAnimationContextsByTab[tab] != null;

  AnimationContext? _getTabCollapseAnimationContext(T tab) =>
      _collapseAnimationContextsByTab[tab];

  Animation<double>? _getTabCollapseAnimation(T tab) =>
      _collapseAnimationContextsByTab[tab]?.animation;

  AnimationContext? _removeTabCollapseAnimationContext(T tab) =>
      _collapseAnimationContextsByTab.remove(tab);
}
