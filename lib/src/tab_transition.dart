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

/// How long one of the overview's animations takes, and how it eases.
///
/// [TabOverviewController.transition] holds the default for a tab expanding
/// to its page and collapsing to its thumbnail, and
/// [TabOverview.thumbnailsMotion] the one for thumbnails moving to new
/// places in the grid.
@immutable
class TabTransition {
  /// How long the animation takes.
  final Duration duration;

  /// How the animation eases.
  final Curve curve;

  const TabTransition({required this.duration, this.curve = Curves.easeInOut});

  @override
  bool operator ==(Object other) =>
      other is TabTransition &&
      other.duration == duration &&
      other.curve == curve;

  @override
  int get hashCode => Object.hash(duration, curve);

  @override
  String toString() => 'TabTransition($duration, $curve)';
}
