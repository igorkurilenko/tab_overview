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
  final controller = TabSwitcherController<Tab>(initialTabs: [
    Tab(1),
    Tab(2),
    Tab(3),
    Tab(4),
    Tab(5),
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TabSwitcher<Tab>.builder(
          controller: controller,
          padding: const EdgeInsets.all(8),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          tabBuilder: _buildTab,
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
              onPressed: () {
                if (controller.tabs.length >= 2) {
                  controller.removeTabAt(1);
                }
              },
              child: const Icon(Icons.remove),
            ),
            FloatingActionButton(
              shape: const CircleBorder(),
              onPressed: () async {
                final newTab = Tab(controller.tabs.length + 1);
                controller.addTab(newTab);
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, Tab tab) => Center(
        child: Text(
          '$tab',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 60,
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
