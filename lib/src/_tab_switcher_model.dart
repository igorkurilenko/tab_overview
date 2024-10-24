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

class _TabSwitcherModel<T> {
  final List<T> _tabs;
  final _offScreenThumbTabs = <T>{};
  GlobalKey<_TabThumbnailsGridState>? _thumbnailsGridKey;

  _TabSwitcherModel({
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

enum TabSwitcherMode { expanded, overview }

abstract class ReorderableTab {
  bool get reorderable;
}

abstract class RemovableTab {
  bool get removable;
}
