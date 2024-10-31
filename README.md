`TabOverview` is a Flutter package that provides a visually rich tab management interface with both overview and expandable views. It supports smooth animations, custom styling, and flexible layouts, making it ideal for multi-tabbed applications where users can browse, reorder, and remove tabs seamlessly.

<p>
  <img src="https://github.com/igorkurilenko/tab_overview/blob/main/assets/tab_overview.gif?raw=true"
    alt="The hero_here basic example" width="180"/>
</p>

## Features

- **Overview and Expanded Modes**: Users can view all tabs in a grid format (overview mode) or expand a selected tab for a detailed view.
- **Reorderable and Removable Tabs**: Drag-and-drop reordering and tap-to-remove functionality provide a natural tab management experience.
- **Customizable Animations and Layouts**: Fine-tune animation duration, curve, grid layout, and decorations for thumbnails and expanded views.

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

// A Tab model that implements RemovableTab and ReorderableTab.
//
// Note: Implementing `RemovableTab` and `ReorderableTab` interfaces in your tab model is optional.
// By default, all tabs are reorderable and removable (closeable).
// If you want to disable reordering or removing functionality for specific tabs,
// you can implement these interfaces in your tab model and set `reorderable` or `removable` to `false`.
class Tab implements RemovableTab, ReorderableTab {
  final int num;

  Tab(this.num);

  // Define if the tab is removable.
  @override
  bool get removable => true;

  // Define if the tab is reorderable.
  @override
  bool get reorderable => true;

  @override
  String toString() => '$num';
}
```

### Explanation of Key Components

- **TabOverviewController**: Manages the active tab, mode switching, and tab list.
- **TabOverview.builder**: Creates a `TabOverview` with customizable `tabBuilder` for expanded views and `tabThumbnailBuilder` for the thumbnail grid.
- **ReorderableTab & RemovableTab**: Interfaces for tabs that can be reordered or removed, enabling flexible tab interactions.
- **Expanded and Thumbnail Views**: Customize how each tab appears in both overview and expanded modes.

## API Overview

### Classes

- **TabOverview**: The main widget for managing and displaying tabs.
- **TabOverviewController**: Manages state and tab actions (add, remove, reorder).
- **ReorderableTab**: Abstract class for tabs that can be reordered.
- **RemovableTab**: Abstract class for tabs that can be removed.

### Enums

- **TabOverviewMode**: Specifies display mode (`overview` or `expanded`).

### Typedefs

- **TabAddedListener**: Callback triggered when a tab is added.
- **TabRemovedListener**: Callback triggered when a tab is removed.
- **ModeChangedListener**: Callback triggered when the display mode changes.
- **ActiveTabChangedListener**: Callback triggered when the active tab changes.
- **TabsReorderedListener**: Callback triggered when tabs are reordered.

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

## License

This package is licensed under the Apache License, Version 2.0. See [LICENSE](https://www.apache.org/licenses/LICENSE-2.0) for details.