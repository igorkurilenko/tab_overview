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

import 'dart:collection';

import 'package:flutter/widgets.dart';

class TabSwitcher<T> extends StatefulWidget {
  final TabSwitcherController<T> controller;
  final TabSwitcherMode initialMode;

  TabSwitcher.builder({
    super.key,
    this.initialMode = TabSwitcherMode.overview,
    TabSwitcherController<T>? controller,
  }) : controller = controller ?? TabSwitcherController<T>();

  @override
  State<TabSwitcher> createState() => _TabSwitcherState<T>();
}

class _TabSwitcherState<T> extends State<TabSwitcher<T>> {
  late TabSwitcherMode _mode;

  TabSwitcherMode get mode => _mode;
  bool get overviewMode => _mode == TabSwitcherMode.overview;
  bool get expandedMode => _mode == TabSwitcherMode.expanded;
  set mode(TabSwitcherMode value) {
    if (_mode == value) return;
    setState(() => _mode = value);
  }

  TabSwitcherController<T> get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    controller._initState(this);
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

enum TabSwitcherMode { expanded, overview }

abstract class ReorderableTab {
  bool get reorderable;
}

abstract class RemovableTab {
  bool get removable;
}

class TabSwitcherController<T> {
  final List<T> _tabs;
  _TabSwitcherState? _state;
  final ValueChanged<T>? onTabExpanded;
  final ValueChanged<T>? onTabCollapsed;
  final VoidCallback? onTabsReordered;
  final ValueChanged<T>? onTabRemoved;

  TabSwitcherController({
    Iterable<T>? initialTabs,
    this.onTabExpanded,
    this.onTabCollapsed,
    this.onTabsReordered,
    this.onTabRemoved,
  }) : _tabs = List<T>.from(initialTabs ?? <T>[]);

  void _initState(_TabSwitcherState<T> state) => _state = state;

  List<T> get tabs => UnmodifiableListView(_tabs);

  bool addTab(
    T newTab, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    // TODO: implement
    return false;
  }

  bool removeTab(
    T tab, {
    Duration duration = const Duration(milliseconds: 350),
  }) =>
      removeTabAt(tabs.indexOf(tab), duration: duration);

  bool removeTabAt(
    int index, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    // TODO: implement
    return false;
  }

  void expandTab(
    T tab, {
    Duration duration = const Duration(milliseconds: 350),
  }) =>
      expandTabAt(tabs.indexOf(tab), duration: duration);

  void expandTabAt(
    int index, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    // TODO: implement
  }

  bool isTabExpanded(T tab) => isTabExpandedAt(tabs.indexOf(tab));

  bool isTabExpandedAt(int index) {
    // TODO: implement
    return false;
  }

  void collapseTab({
    Duration duration = const Duration(milliseconds: 350),
  }) {
    // TODO: implement
  }

  void toggleMode({
    Duration duration = const Duration(milliseconds: 350),
  }) {
    // TODO: implement
    _state!.mode = _state!.overviewMode
        ? TabSwitcherMode.expanded
        : TabSwitcherMode.overview;
  }

  void scrollToTab(
    T tab, {
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOut,
  }) =>
      scrollToTabAt(tabs.indexOf(tab), duration: duration, curve: curve);

  void scrollToTabAt(
    int index, {
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOut,
  }) {
    // TODO: implement
  }
}
