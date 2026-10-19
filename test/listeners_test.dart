import 'package:flutter_test/flutter_test.dart';
import 'package:tab_overview/tab_overview.dart';

// A typed listener may add or remove listeners while it's notified, itself
// too, as a ChangeNotifier's may: one removed before its turn isn't called,
// and one added waits for the next change.
void main() {
  test('a listener removes itself while it is notified', () {
    final controller = TabOverviewController<int>();
    addTearDown(controller.dispose);
    final calls = <String>[];
    void once(int tab) {
      calls.add('once $tab');
      controller.removeTabAddedListener(once);
    }

    controller
      ..addTabAddedListener(once)
      ..addTabAddedListener((tab) => calls.add('always $tab'));

    controller.add(0);
    controller.add(1);

    expect(calls, ['once 0', 'always 0', 'always 1']);
  });

  test('a listener removed by another before its turn is not called', () {
    final controller = TabOverviewController<int>(initialTabs: [0, 1]);
    addTearDown(controller.dispose);
    final calls = <TabOverviewMode>[];
    void later(TabOverviewMode mode) => calls.add(mode);

    controller
      ..addModeChangedListener(
        (mode) => controller.removeModeChangedListener(later),
      )
      ..addModeChangedListener(later);

    controller.expand(1);

    expect(calls, isEmpty);
  });

  test('a listener added while others are notified waits for the next '
      'change', () {
    final controller = TabOverviewController<int>(initialTabs: [0, 1]);
    addTearDown(controller.dispose);
    final calls = <int>[];
    var added = false;

    controller.addActiveTabChangedListener(() {
      if (added) return;
      added = true;
      controller.addActiveTabChangedListener(
        () => calls.add(controller.activeTab!),
      );
    });

    controller.activeTab = 1;
    controller.activeTab = 0;

    expect(calls, [0]);
  });
}
