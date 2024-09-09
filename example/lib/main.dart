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

class Tab {
  final int num;

  Tab(this.num);

  @override
  String toString() => '$num';
}
