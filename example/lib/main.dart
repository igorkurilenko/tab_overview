// Copyright 2026 Igor Kurilenko
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

import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tab_overview/tab_overview.dart';

import 'style/style.dart';
import 'tab_page.dart';

void main() => runApp(
  MaterialApp(
    title: 'TabOverview Example',
    debugShowCheckedModeBanner: false,
    theme: exampleTheme,
    home: const TabOverviewExample(),
  ),
);

/// Numbered tabs in a tab switcher, as live thumbnails in a grid, each of
/// which zooms into its page:
///
/// 1. A [TabOverviewController] holds the tabs, and whether they show as a
///    grid of thumbnails or as pages.
/// 2. [TabOverview.builder] builds each tab's page, which the grid shows,
///    scaled down, as its thumbnail.
/// 3. A tap zooms a thumbnail into its page, and the buttons switch between
///    the grid and the pages, close the active tab and add one.
class TabOverviewExample extends StatefulWidget {
  const TabOverviewExample({super.key});

  @override
  State<TabOverviewExample> createState() => TabOverviewExampleState();
}

class TabOverviewExampleState extends State<TabOverviewExample> {
  // 1. The controller, with tabs 1 to 5 open in the grid.
  final controller = TabOverviewController<int>(initialTabs: [1, 2, 3, 4, 5]);

  // The number of the last tab added, so each new tab has one of its own.
  var _lastTab = 5;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      // 2. The tab switcher: the grid of thumbnails, or the tabs' pages.
      body: TabOverview<int>.builder(
        controller: controller,
        tabBuilder: (context, tab) => TabPage(
          tab,
          // 3. A tap zooms a thumbnail into its page, and a page back out.
          onTap: () => controller.isTabExpanded(tab)
              ? controller.collapse()
              : controller.expand(tab),
        ),
        removeTabButtonBuilder: (context, tab) =>
            CloseTabButton(onPressed: () => controller.remove(tab)),
        thumbnailsGridPadding: EdgeInsets.fromLTRB(
          S.s4,
          max(padding.top, S.s4),
          S.s4,
          max(padding.bottom, S.s4),
        ),
        thumbnailDecoration: ShapeDecoration(shape: squircle(S.s7)),
        // Pull a page down to zoom it back out.
        pullToCollapse: true,
        // Drag with the mouse too, to turn the page and to pull it down.
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: PointerDeviceKind.values.toSet(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: TabButtons(
        // 3. Switch between the grid and the pages.
        onSwitchView: controller.toggleMode,
        // 3. Close the active tab, if any is left.
        onClose: () {
          final tab = controller.activeTab;
          if (tab != null) controller.remove(tab);
        },
        // 3. Add a tab.
        onAdd: () => controller.add(++_lastTab),
      ),
    );
  }
}
