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

class _TabOverviewModel<T> {
  final List<_TabEntry<T>> _entries;
  final _standIns = <_TabEntry<T>>{};
  GlobalKey<_TabThumbnailsGridState>? _thumbnailsGridKey;

  _TabOverviewModel({Iterable<T>? initialTabs})
    : _entries = [for (final tab in initialTabs ?? <T>[]) _TabEntry(tab)];

  _TabThumbnailsGridState? get _thumbnailsGridState =>
      _thumbnailsGridKey?.currentState;

  List<T> get tabs => UnmodifiableListView(_entries.map((entry) => entry.tab));

  int get tabCount => _entries.length;

  /// The tabs whose thumbnails are off screen, with a stand-in for a flight
  /// to fly to or from. A removed tab may have one, which it flies to.
  Iterable<_TabEntry<T>> get standIns => _standIns;

  int indexOfTab(T tab) => _entries.indexWhere((entry) => entry.tab == tab);

  bool containsTab(T tab) => indexOfTab(tab) != -1;

  _TabEntry<T> entryAt(int index) => _entries[index];

  _TabEntry<T>? entryOf(T tab) {
    final index = indexOfTab(tab);
    return index == -1 ? null : _entries[index];
  }

  int indexOfEntry(_TabEntry<T> entry) => _entries.indexOf(entry);

  /// The key of the grid's item for the tab at [index].
  Key keyAt(int index) => _entries[index].key;

  bool reorderableAt(int index) => reorderable(tabs[index]);

  bool reorderable(T tab) => tab is ReorderableTab ? tab.reorderable : true;

  bool removableAt(int index) => removable(tabs[index]);

  bool removable(T tab) => tab is RemovableTab ? tab.removable : true;

  void addTab(T tab, {required Duration duration}) {
    final entry = _TabEntry(tab);
    _entries.add(entry);
    _thumbnailsGridState?.addTab(entry, duration: duration);
  }

  _TabEntry<T> removeTabAt(int index, {required Duration duration}) {
    final removed = _entries.removeAt(index);
    _thumbnailsGridState?.removeTab(index, removed, duration: duration);

    return removed;
  }

  T operator [](int index) => _entries[index].tab;

  void reorderTabs(Permutations permutations) => permutations.apply(_entries);

  bool addStandIn(_TabEntry<T> entry) => _standIns.add(entry);

  bool hasStandIn(_TabEntry<T> entry) => _standIns.contains(entry);

  bool removeStandIn(_TabEntry<T> entry) => _standIns.remove(entry);
}

/// A tab, from when it's added until it's removed and its last animation
/// ends. A tab removed and added again is a new entry, so the grid tells its
/// item from the removed one, which may still be animating out.
class _TabEntry<T> {
  final T tab;
  final key = UniqueKey();

  _TabEntry(this.tab);
}

/// Specifies the display mode of the [TabOverview].
///
/// - [expanded]: Displays the currently active tab in an expanded, detailed view.
/// - [overview]: Displays all tabs as thumbnails in an overview grid for easy selection and navigation.
enum TabOverviewMode { expanded, overview }

/// An abstract class that provides a property to determine if a tab can be reordered within the [TabOverview].
///
/// Implement this class in a tab model to enable/disable reordering functionality,
/// allowing tabs to be dragged and rearranged within the overview interface.
abstract class ReorderableTab {
  bool get reorderable;
}

/// An abstract class that provides a property to determine if a tab can be removed from the [TabOverview].
///
/// Implement this class in a tab model to allow removal functionality,
/// enabling tabs to be deleted by the user when `removable` is `true`.
abstract class RemovableTab {
  bool get removable;
}
