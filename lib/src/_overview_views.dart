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

/// What the controller and its model ask of the overview's thumbnails grid.
/// The grid attaches itself to the controller while it's built.
abstract interface class _ThumbnailsView<T> {
  void addTab(_TabEntry<T> entry, {required Duration duration});

  void removeTab(int index, _TabEntry<T> removed, {required Duration duration});

  /// Whether the tab's thumb is built, so has a hero for a flight to fly to
  /// or from.
  bool thumbBuilt(T tab);

  /// Whether most of the tab's thumb is in view, so a flight to it lands in
  /// view.
  bool thumbInView(T tab);

  double getThumbScrollOffset(int index);

  void animateTo(
    double offset, {
    required Duration duration,
    required Curve curve,
  });

  void jumpToThumb(T tab);
}

/// What the controller asks of the overview's pages, the expanded tabs.
/// They attach themselves to the controller while they're built.
abstract interface class _PagesView {
  void jumpToPage(int page);

  void animateToPage(
    int index, {
    required Duration duration,
    required Curve curve,
  });

  /// Builds the pages again, for the tabs as they are now.
  void stateChanged();
}
