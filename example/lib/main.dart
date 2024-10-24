import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tab_switcher/tab_switcher.dart';

void main() {
  // timeDilation = 5;
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
          thumbnailsGridPadding: const EdgeInsets.all(16.0),
          tabBuilder: _buildTab,
          thumbnailDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
          ),
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
            IconButton(
              onPressed: controller.toggleMode,
              icon: const Icon(Icons.auto_awesome_motion_outlined),
            ),
            IconButton(
              onPressed: () {
                if (controller.tabs.length >= 2) {
                  controller.removeTabAt(1);
                  // controller.removeTabAt(controller.tabs.length - 1);
                }
              },
              icon: const Icon(Icons.remove),
            ),
            IconButton(
              onPressed: () async {
                final newTab = Tab(controller.tabs.length + 1);
                controller.add(newTab);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // controller.expand(newTab);
                  // controller.scrollToTab(newTab);
                });
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, Tab tab) => GestureDetector(
        onTap: () => controller.isTabExpanded(tab)
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
