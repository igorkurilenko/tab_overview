import 'package:flutter/material.dart';
import 'package:tab_switcher/tab_switcher.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TabSwitcherController<Tab>();

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: TabSwitcher<Tab>.builder(
            controller: controller,
          ),
        ),
      ),
    );
  }
}

class Tab {}
