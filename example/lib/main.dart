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
