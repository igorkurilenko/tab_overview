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

  void insertTab(
    int index,
    T tab, {
    required Duration duration,
    required Curve curve,
  }) {
    final entry = _TabEntry(tab)..presenceCurve = curve;
    _entries.insert(index, entry);
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

  /// Keeps [animation] as [presence] until it ends, at [endsAt]. The grid
  /// builds an item on every rebuild while it animates, so it may ask for
  /// the same animation many times.
  void trackPresence(
    Animation<double> animation, {
    required AnimationStatus endsAt,
  }) {
    if (animation.status == endsAt || presence == animation) return;
    presence = animation;

    void handleStatus(AnimationStatus status) {
      if (status != endsAt) return;
      animation.removeStatusListener(handleStatus);
      if (presence == animation) presence = null;
    }

    animation.addStatusListener(handleStatus);
  }

  /// How far the tab's page is pulled toward collapsing it, from 0 to 1.
  ///
  /// Kept here rather than by the page, as a flight may build its shuttle
  /// from the page's hero after the page is gone.
  final pull = ValueNotifier<double>(0);

  /// The size the grid last laid the tab's thumbnail out at, which a flight
  /// lays a thumbnail of the app's own out at, so it keeps its layout as the
  /// flight grows or shrinks it.
  Size? thumbnailSize;

  /// The size each of the tab's [TabHero]s was last laid out at, by its tag
  /// and the side of the tab it's on, which its flight lays it out at.
  final partSizes = <(Object, _TabSide), Size>{};

  // How many flights each of the tab's parts is in, by its tag.
  final _partFlights = <Object, int>{};

  /// Tells when one of the tab's parts takes off or lands.
  final partFlightsChanged = _Notifier();

  /// Whether the part with [tag] flies, which the tab's shuttle hides it
  /// for.
  bool partFlies(Object tag) => _partFlights.containsKey(tag);

  void partTakesOff(Object tag) {
    _partFlights.update(tag, (flights) => flights + 1, ifAbsent: () => 1);
    partFlightsChanged.notify();
  }

  void partLands(Object tag) {
    final flights = (_partFlights[tag] ?? 1) - 1;
    if (flights > 0) {
      _partFlights[tag] = flights;
    } else {
      _partFlights.remove(tag);
    }
    partFlightsChanged.notify();
  }

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

/// Whether a [TabOverview] shows its tabs as a grid of thumbnails, or the
/// active tab as a full page.
enum TabOverviewMode {
  /// The active tab's page, full size, where a swipe turns to the next tab.
  expanded,

  /// The grid of the tabs' live thumbnails.
  overview,
}
