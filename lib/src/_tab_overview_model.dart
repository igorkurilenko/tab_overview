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
  final List<T> _tabs;
  final _offScreenThumbTabs = <T>{};
  GlobalKey<_TabThumbnailsGridState>? _thumbnailsGridKey;

  _TabOverviewModel({
    Iterable<T>? initialTabs,
  }) : _tabs = List<T>.from(initialTabs ?? <T>[]);

  _TabThumbnailsGridState? get _thumbnailsGridState =>
      _thumbnailsGridKey?.currentState;

  List<T> get tabs => UnmodifiableListView(_tabs);

  int get tabCount => _tabs.length;

  List<T> get offScreenThumbTabs => UnmodifiableListView(_offScreenThumbTabs);

  int indexOfTab(T tab) => _tabs.indexOf(tab);

  bool containsTab(T tab) => _tabs.contains(tab);

  bool reorderableAt(int index) => reorderable(tabs[index]);

  bool reorderable(T tab) => tab is ReorderableTab ? tab.reorderable : true;

  bool removableAt(int index) => removable(tabs[index]);

  bool removable(T tab) => tab is RemovableTab ? tab.removable : true;

  void addTab(T tab, {required Duration duration}) {
    _tabs.add(tab);
    _thumbnailsGridState?.addTab(tab, duration: duration);
  }

  T removeTabAt(int index, {required Duration duration}) {
    final removedTab = _tabs.removeAt(index);
    _thumbnailsGridState?.removeTab(index, removedTab, duration: duration);

    return removedTab;
  }

  T operator [](int index) => _tabs[index];

  void reorderTabs(Permutations permutations) => permutations.apply(_tabs);

  bool addOffScreenThumbTab(T tab) => _offScreenThumbTabs.add(tab);

  bool containsOffScreenThumbTab(T tab) => _offScreenThumbTabs.contains(tab);

  bool removeOffScreenThumbTab(T tab) => _offScreenThumbTabs.remove(tab);
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
