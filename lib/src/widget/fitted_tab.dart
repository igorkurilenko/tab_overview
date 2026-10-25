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

import 'package:flutter/widgets.dart';

/// Lays [child] out at the size of the `TabOverview` it's in, and scales it
/// to the width of the space it's given, cropping what doesn't fit, as the
/// default `tabThumbnailBuilder` does with each tab's content.
///
/// Use it in a custom `tabThumbnailBuilder` to show a tab as the default
/// thumbnail does, with something of your own around it or on top of it.
class FittedTab extends StatelessWidget {
  /// The tab's content, such as what `tabBuilder` builds.
  final Widget child;

  /// Shows [child], such as what `tabBuilder` builds, as the default
  /// thumbnail shows a tab's page.
  const FittedTab({super.key, required this.child});

  @override
  Widget build(BuildContext context) => FittedBox(
    clipBehavior: Clip.hardEdge,
    fit: BoxFit.fitWidth,
    alignment: Alignment.center,
    child: SizedBox.fromSize(
      size: TabContentSize.maybeOf(context) ?? MediaQuery.sizeOf(context),
      // The tab is laid out at one size and only scaled, so a flight, which
      // scales it on every frame, can reuse what it painted.
      child: RepaintBoundary(child: child),
    ),
  );
}

/// The size of the `TabOverview` that tabs are in. [FittedTab] lays its
/// child out at this size, so tabs match the overview rather than the screen.
class TabContentSize extends InheritedWidget {
  final Size size;

  const TabContentSize({super.key, required this.size, required super.child});

  static Size? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabContentSize>()?.size;

  @override
  bool updateShouldNotify(TabContentSize oldWidget) => size != oldWidget.size;
}
