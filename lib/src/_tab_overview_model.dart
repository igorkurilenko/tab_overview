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

  /// Tells when a stand-in is added or removed.
  final standInsChanged = _Notifier();

  /// The overview's thumbnails grid, while it's built.
  _ThumbnailsView<T>? _thumbnails;

  _TabOverviewModel({Iterable<T>? initialTabs})
    : _entries = [for (final tab in initialTabs ?? <T>[]) _TabEntry(tab)];

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

  void addTab(T tab, {required Duration duration, required Curve curve}) {
    final entry = _TabEntry(tab)..presenceCurve = curve;
    _entries.add(entry);
    _thumbnails?.addTab(entry, duration: duration);
  }

  _TabEntry<T> removeAt(
    int index, {
    required Duration duration,
    required Curve curve,
  }) {
    final removed = _entries.removeAt(index)..presenceCurve = curve;
    _thumbnails?.removeTab(index, removed, duration: duration);

    return removed;
  }

  T operator [](int index) => _entries[index].tab;

  void reorderTabs(ItemMoves moves) => moves.apply(_entries);

  void addStandIn(_TabEntry<T> entry) => _changeStandIn(entry, true);

  void removeStandIn(_TabEntry<T> entry) => _changeStandIn(entry, false);

  void _changeStandIn(_TabEntry<T> entry, bool hasStandIn) {
    final changed = hasStandIn ? _standIns.add(entry) : _standIns.remove(entry);
    if (!changed) return;
    entry.hasStandIn = hasStandIn;
    standInsChanged.notify();
  }
}

/// A tab, from when it's added until it's removed and its last animation
/// ends. A tab removed and added again is a new entry, so the grid tells its
/// item from the removed one, which may still be animating out.
///
/// Entries are told apart by identity, never by the tab's equality or hash
/// code, which may change while the tab animates.
///
/// Tells its listeners, such as the tab's cell and decorations, when its
/// flight or its stand-in changes.
class _TabEntry<T> extends ChangeNotifier {
  final T tab;
  final key = UniqueKey();

  TabFlight? _flight;

  bool _hasStandIn = false;

  /// The tab's add or remove animation while it runs, which the tab's page
  /// and stand-in scale and fade with. Grid items get their own.
  Animation<double>? presence;

  /// The curve the tab's last add or remove animation scales and fades it
  /// along.
  Curve presenceCurve = Curves.linear;

  /// How far the tab's page is pulled toward collapsing it, from 0 to 1.
  ///
  /// Kept here rather than by the page, as a flight may build its shuttle
  /// from the page's hero after the page is gone.
  final pull = ValueNotifier<double>(0);

  _TabEntry(this.tab);

  /// The tab's flight between its thumbnail and its page, from when it's
  /// asked for until the tab lands.
  TabFlight? get flight => _flight;

  set flight(TabFlight? value) {
    if (identical(_flight, value)) return;
    _flight = value;
    notifyListeners();
  }

  /// Whether the tab's thumbnail is off screen, with a stand-in for a flight
  /// to fly to or from.
  bool get hasStandIn => _hasStandIn;

  set hasStandIn(bool value) {
    if (_hasStandIn == value) return;
    _hasStandIn = value;
    notifyListeners();
  }
}

/// A [ChangeNotifier] that whoever holds it tells when to notify.
class _Notifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Specifies the display mode of the [TabOverview].
///
/// - [expanded]: Displays the currently active tab in an expanded, detailed view.
/// - [overview]: Displays all tabs as thumbnails in an overview grid for easy selection and navigation.
enum TabOverviewMode { expanded, overview }
