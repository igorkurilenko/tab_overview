import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tab_switcher/tab_switcher.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: TabSwitcherExample(),
      );
}

class TabSwitcherExample extends StatefulWidget {
  const TabSwitcherExample({super.key});

  @override
  State<TabSwitcherExample> createState() => TabSwitcherExampleState();
}

class TabSwitcherExampleState extends State<TabSwitcherExample> {
  final controller = TabSwitcherController<Tab>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TabSwitcher<Tab>.builder(
          controller: controller,
          thumbnailsGridPadding: const EdgeInsets.all(2.0),
          tabBuilder: _buildTab,
          scrollBehavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.unknown,
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.max,
          children: [
            FloatingActionButton(
              shape: const CircleBorder(),
              onPressed: controller.toggleMode,
              child: const Icon(Icons.expand),
            ),
            FloatingActionButton(
              shape: const CircleBorder(),
              onPressed: () {
                if (controller.tabs.length >= 2) {
                  controller.removeTabAt(controller.tabs.length - 1);
                }
              },
              child: const Icon(Icons.remove),
            ),
            FloatingActionButton(
              shape: const CircleBorder(),
              onPressed: () async {
                final newTab = Tab(controller.tabs.length + 1);
                controller.add(newTab);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // controller.expand(newTab);
                  // controller.scrollToTab(newTab);
                });
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, Tab tab) => GestureDetector(
        onTap: () => controller.expanded(tab)
            ? controller.collapse()
            : controller.expand(tab),
        child: Container(
          color: Colors.grey.shade300,
          child: Center(
            child: Text(
              '$tab',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 60,
                  ),
            ),
          ),
        ),
      );
}

class Tab implements RemovableTab, ReorderableTab {
  final int num;

  Tab(this.num);

  @override
  bool get removable => true;

  @override
  bool get reorderable => true;

  @override
  String toString() => '$num';
}
