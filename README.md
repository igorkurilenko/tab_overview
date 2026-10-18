`TabOverview` is a Flutter package that provides a visually rich tab management interface with both overview and expandable views. It supports smooth animations, custom styling, and flexible layouts, making it ideal for multi-tabbed applications where users can browse, reorder, and remove tabs seamlessly.

<p>
  <img src="https://github.com/igorkurilenko/tab_overview/blob/main/assets/tab_overview.gif?raw=true"
    alt="The hero_here basic example" width="180"/>
</p>

## Features

- **Overview and Expanded Modes**: Users can view all tabs in a grid format (overview mode) or expand a selected tab for a detailed view.
- **Reorderable and Removable Tabs**: Drag-and-drop reordering and tap-to-remove functionality provide a natural tab management experience.
- **Customizable Animations and Layouts**: Fine-tune animation duration, curve, grid layout, and decorations for thumbnails and expanded views.
- **Pull to Collapse**: Optionally, pull the expanded tab down to collapse it into its thumbnail, with `pullToCollapse: true`.

## Installation

To install `tab_overview` using the command line, you can run:

```sh
flutter pub add tab_overview
```

This command will automatically add the latest version of `tab_overview` to your `pubspec.yaml` file and download the package.

## Usage Example

Below is a comprehensive example to help you get started with `TabOverview`, demonstrating tab management with thumbnails, reordering, and removal.

```dart
import 'package:flutter/material.dart';
import 'package:tab_overview/tab_overview.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: TabOverviewExample(),
      );
}

class TabOverviewExample extends StatefulWidget {
  const TabOverviewExample({super.key});

  @override
  State<TabOverviewExample> createState() => TabOverviewExampleState();
}

class TabOverviewExampleState extends State<TabOverviewExample> {
  // Step 1: Initialize a TabOverviewController with your tab type.
  // This controller will manage the state, including switching tabs, adding, and removing.
  final controller = TabOverviewController<Tab>();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.grey.shade200,
        // Step 2: Use TabOverview.builder to create the TabOverview widget.
        // Configure the controller, padding, tab content builder, and styling for thumbnails.
        body: TabOverview<Tab>.builder(
          controller: controller, // Attach the controller
          thumbnailsGridPadding: MediaQuery.viewPaddingOf(context).copyWith(
            left: 16,
            right: 16,
          ), // Customize grid padding
          tabBuilder: (context, tab) => TabWidget(
            tab: tab,
            // Step 3: Toggle tab expansion or collapse when a thumbnail is tapped.
            onTap: () => controller.isTabExpanded(tab)
                ? controller.collapse() // Collapse if expanded
                : controller.expand(tab), // Expand on tap
          ),
          thumbnailDecoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(32), // Add rounded corners to thumbnails
          ),
          // Which tabs the user may close or move. Every tab may, by default.
          isTabRemovable: (tab) => tab.removable,
          isTabReorderable: (tab) => tab.reorderable,
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            mainAxisSize: MainAxisSize.max,
            children: [
              // A button to toggle between overview and expanded modes.
              IconButton(
                onPressed: controller.toggleMode,
                icon: const Icon(Icons.auto_awesome_motion_outlined),
              ),
              // A button to dynamically add new tabs.
              IconButton(
                onPressed: () =>
                    controller.add(Tab(controller.tabs.length + 1)),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      );
}

class TabWidget extends StatelessWidget {
  final Tab tab;
  final VoidCallback? onTap;

  const TabWidget({
    super.key,
    required this.tab,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.grey.shade300,
          child: Center(
            child: Text(
              '$tab',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 60,
                  ),
            ),
          ),
        ),
      );
}

// A Tab model. TabOverview's isTabRemovable and isTabReorderable read its
// `removable` and `reorderable`, which a tab could set to false to stay put.
class Tab {
  final int num;

  Tab(this.num);

  bool get removable => true;

  bool get reorderable => true;

  @override
  String toString() => '$num';
}
```

### Explanation of Key Components

- **TabOverviewController**: Manages the active tab, mode switching, and tab list. It's a `ChangeNotifier`, so a `ListenableBuilder` can rebuild with it.
- **Active tab**: The tab the expanded view shows, and that `toggleMode` expands: the last one expanded, swiped to in the expanded view, or set with `activeTab`, wherever its thumbnail is scrolled in the overview.
- **TabOverview.builder**: Creates a `TabOverview` with customizable `tabBuilder` for expanded views and `tabThumbnailBuilder` for the thumbnail grid.
- **isTabRemovable & isTabReorderable**: Tell which tabs the user may close or move. Every tab may, by default.
- **Expanded and Thumbnail Views**: Customize how each tab appears in both overview and expanded modes.

## API Overview

### Classes

- **TabOverview**: The widget that shows the tabs, as a grid of thumbnails or as the expanded tab's page.
- **TabOverviewController**: Holds the tabs, the active tab and the mode, and animates the changes:
  - `add` and `remove` return whether they changed anything. `removeAt` removes the tab at an index.
  - `expand`, `expandAt`, `collapse` and `toggleMode` switch the mode. Each takes an optional `duration` and `curve`, which override the controller's `transition`.
  - `activeTab` is the tab the expanded view shows, and `activeIndex` is its index, or `null`.
  - `isTransitioning` tells whether a tab is flying between its thumbnail and its page.
  - It's a `ChangeNotifier`, and also has typed listeners for each kind of change.
- **TabTransition**: How long an animation takes, and how it eases. The controller's `transition` sets it for expanding and collapsing. The widget's `thumbnailsMotion` sets it for thumbnails moving in the grid.
- **FittedTab**: Shows a tab's content scaled down to fit a thumbnail, as the default thumbnail does.
- **RemoveTabButton**: The default remove button. Use it in a `removeTabButtonBuilder` to keep its look and do something else when it's pressed.

### Errors

A controller method that takes a tab throws an `ArgumentError` for a tab that isn't in the overview. `remove` is the exception: it returns `false`, as `add` does for a tab that's already there. A method that takes an index throws a `RangeError` for an index out of range.

### Enums

- **TabOverviewMode**: Specifies display mode (`overview` or `expanded`).

### Typedefs

- **ModelWidgetBuilder**: Builds a widget for a tab, as `tabBuilder` and the other builders do.
- **TabAddedListener**: Callback triggered when a tab is added.
- **TabRemovedListener**: Callback triggered when a tab is removed.
- **ModeChangedListener**: Callback triggered when the display mode changes.
- **ActiveTabChangedListener**: Callback triggered when the active tab changes.
- **TabsReorderedListener**: Callback triggered when tabs are reordered.

### Migrating from 0.1

0.2.0 removes what 0.1.20 and 0.1.21 deprecated, and changes a few names. The [changelog](CHANGELOG.md) has a table of each change and what to use instead.

## Customization

### Responsive Thumbnail Grid Layout

The `TabOverview` widget automatically adjusts the grid layout for thumbnails based on the screen size:

- **Large screens**: Displays thumbnails in a 4-column grid.
- **Medium screens**: Displays thumbnails in a 3-column grid.
- **Small screens**: Displays thumbnails in a 2-column grid with a different aspect ratio for a compact view.

You can also override this default layout by providing a custom `thumbnailsGridDelegate` to control the grid configuration manually.

### Decorations

Style your tabs with the following properties:
- **thumbnailDecoration**: Apply decoration to each thumbnail in overview mode.
- **expandedTabDecoration**: Apply decoration to the expanded view of a tab.

### Transitions

A tab expands and collapses over 300 ms along `Curves.easeInOut`. To change that everywhere, give the controller a `transition`:

```dart
final controller = TabOverviewController<Tab>(
  transition: const TabTransition(duration: Duration(milliseconds: 450)),
);
```

A call can still pass its own `duration` and `curve`, as in `controller.expand(tab, duration: ...)`. Thumbnails moving to new places in the grid follow the widget's `thumbnailsMotion`.

### Pull to Collapse

With `pullToCollapse: true`, the expanded tab can be pulled down to collapse it, as in hero_here's show details example. It's pulled from the top of its vertical scroll view, or from anywhere on a tab without one. As it's pulled, it shrinks and its corners round toward `thumbnailDecoration`'s. Let go once it's pulled 50 pixels, or while it moves down fast, and it collapses into its thumbnail from where it is, at the speed it had. Otherwise it goes back.

It's off by default, as a `RefreshIndicator` at the top of a tab reads the same pull.

## License

This package is licensed under the Apache License, Version 2.0. See [LICENSE](https://www.apache.org/licenses/LICENSE-2.0) for details.