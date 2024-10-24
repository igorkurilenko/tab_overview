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

part of 'tab_switcher.dart';

class TabSwitcherController<T> with _AnimationContexts<T>, _Listeners<T> {
  TabSwitcherMode _mode;
  T? _activeTab;
  final _TabSwitcherModel<T> _model;
  GlobalKey<_TabThumbnailsGridState>? _thumbnailsGridKey;
  GlobalKey<_ExpandedTabState>? _expandedTabKey;

  TabSwitcherController({
    List<T>? initialTabs,
    TabSwitcherMode initialMode = TabSwitcherMode.overview,
  })  : _mode = initialMode,
        _model = _TabSwitcherModel<T>(initialTabs: initialTabs);

  TabSwitcherMode get mode => _mode;

  _TabThumbnailsGridState? get _thumbnailsGridState =>
      _thumbnailsGridKey?.currentState;

  _ExpandedTabState? get _expandedTabState => _expandedTabKey?.currentState;

  T? get activeTab => _activeTab;

  set activeTab(T? value) {
    if (_activeTab == value) return;

    _activeTab = value;

    _notifyActiveTabChanged();

    if (mode == TabSwitcherMode.expanded) {
      _thumbnailsGridState?.stateChanged();
    }
  }

  int indexOfActiveTab() => _model.indexOfTab(activeTab as T);

  bool isActiveTab(T tab) => tab == _activeTab;

  List<T> get tabs => _model.tabs;

  bool isTabExpanded(T tab) =>
      mode == TabSwitcherMode.expanded && isActiveTab(tab);

  bool isTabExpandedAt(int index) => isTabExpanded(tabs[index]);

  void _setThumbnailsGridKey(GlobalKey<_TabThumbnailsGridState>? key) {
    _thumbnailsGridKey = key;
    _model._thumbnailsGridKey = key;
  }

  void _setExpandedTabKey(GlobalKey<_ExpandedTabState>? key) {
    _expandedTabKey = key;
  }

  bool add(
    T newTab, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    if (_model.containsTab(newTab)) return false;

    _model.addTab(newTab, duration: duration);
    _notifyTabAdded(newTab);

    _expandedTabState?.jumpToPage(indexOfActiveTab());
    _expandedTabState?.stateChanged();

    return true;
  }

  void remove(
    T tab, {
    Duration duration = const Duration(milliseconds: 350),
  }) =>
      removeTabAt(tabs.indexOf(tab), duration: duration);

  T removeTabAt(
    int index, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    final removedTab = _model.removeTabAt(index, duration: duration);
    _notifyTabRemoved(removedTab);

    if (removedTab != activeTab) {
      _expandedTabState?.jumpToPage(indexOfActiveTab());
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

  void toggleMode({
    Duration duration = HeroHere.defaultFlightAnimationDuration,
    Curve curve = Curves.easeInOut,
  }) {
    if (_model.tabs.isEmpty) return;

    if (mode == TabSwitcherMode.expanded) {
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

  void expand(
    T tab, {
    Duration duration = HeroHere.defaultFlightAnimationDuration,
    Curve curve = Curves.easeInOut,
  }) {
    if (!_model.containsTab(tab)) {
      throw ArgumentError('Tab $tab not found');
    }

    if (mode == TabSwitcherMode.expanded) {
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

  void scrollToTabAt(
    int index, {
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOut,
  }) {
    if (mode == TabSwitcherMode.expanded) {
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

  void collapse({
    Duration duration = HeroHere.defaultFlightAnimationDuration,
    Curve curve = Curves.easeInOut,
  }) {
    if (mode == TabSwitcherMode.overview) return;

    if (_thumbnailsGridState!.thumbOffScreen(activeTab)) {
      _collapseOffScreen(duration: duration, curve: curve);
    } else {
      _doCollapse(duration: duration, curve: curve);
    }
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

    _mode = TabSwitcherMode.expanded;
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

    _mode = TabSwitcherMode.overview;
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

typedef TabAddedListener<T> = void Function(T tab);

typedef TabRemovedListener<T> = void Function(T removedTab);

typedef ModeChangedListener = void Function(TabSwitcherMode mode);

typedef ActiveTabChangedListener = VoidCallback;

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

  void _notifyModeChanged(TabSwitcherMode mode) {
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

  Animation<double>? _getTabInsertAnimation(T tab) => _insertAnimationByTab[tab];

  Animation<double>? _removeTabInsertAnimation(T tab) =>
      _insertAnimationByTab.remove(tab);

  void _putTabRemoveAnimation(T tab, Animation<double> animation) =>
      _removeAnimationByTab[tab] = animation;

  Animation<double>? _getTabRemoveAnimation(T tab) => _removeAnimationByTab[tab];

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
