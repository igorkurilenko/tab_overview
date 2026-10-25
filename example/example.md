<h1 align="center">Flutter tab switcher example</h1>

<p align="center">This Flutter tab switcher example opens five numbered tabs as live thumbnails in a grid: tap one, and it zooms into its page. Swipe to the next page, or pull the page down to zoom back out. Drag a thumbnail to reorder the tabs, swipe it away or tap its close button to close it, and tap + to add a tab.<sup>1</sup></p>

<p align="center">
  <a href="#take-a-closer-look">See the code ›</a>&emsp;<a href="https://pub.dev/packages/tab_overview/install">Install tab_overview ›</a>
</p>

<p align="center">
  <img src="https://github.com/igorkurilenko/tab_overview/blob/main/assets/tab_overview_tab_switcher.webp?raw=true"
    alt="Flutter tab switcher example: a tap zooms a thumbnail into its page, a swipe turns to the next one, and a pull down zooms back out to the grid; + adds a tab, a drag takes it to the front, and a swipe closes it" width="300"/>
</p>

## Get the highlights.

- **Live thumbnails.** Each thumbnail is the tab's own page, scaled down to its cell, so it shows what the page shows.
- **Zoom in and out.** A tap zooms a thumbnail into its page, and the page back out, with a hero animation within the same page. A pull down zooms a page out too.
- **Swipe between pages.** An open tab is one page of many: swipe sideways to the next tab.
- **Drag to reorder.** A long press lifts a thumbnail, and the others slide out of its way as it moves.
- **Close and add.** A swipe or the close button closes a tab, and + adds one, as the grid closes the gap or makes room.

## Take a closer look.

Three steps, all in one `build` method:

1. **The controller.** A `TabOverviewController` holds the tabs, numbered 1 to 5, and whether they show as a grid of thumbnails or as pages.
2. **The tab switcher.** `TabOverview.builder` builds each tab's page with `tabBuilder`. The grid shows the same page, scaled down, as the tab's thumbnail, and `pullToCollapse` lets a pull down zoom a page back out.
3. **The changes.** A tap on a thumbnail calls `expand`, and a tap on a page `collapse`. The buttons call `toggleMode`, `remove` and `add`, and the tab switcher animates each change.

```dart
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
```

## More ways to use tab_overview.

One more Flutter tab switcher example, a pattern apps often need, built with a `TabOverview` and recorded as it runs.<sup>1</sup> It's code to learn from and copy, not a widget to import. Run it from the repository's [example folder](https://github.com/igorkurilenko/tab_overview/tree/main/example/lib) with `flutter run -t lib/chat_tabs/main.dart`. Its `main.dart` builds the tab switcher, and the files beside it draw the rest.

### Chats as tabs

A messenger's chats as tabs, each shown as a card of its own, which `tabThumbnailBuilder` builds, rather than as its page scaled down: the chat's avatar, its name and its latest message, in the shape of an Apple Watch Ultra's screen. A phone shows two columns of them, and a watch one per screen. Tap a card, and the chat opens on a spring, from `TabTransition.spring`, as its avatar, name and latest message fly to their places on its page in `TabHero`s. Pull the chat down by its bar, and it closes back into its card. New messages come in as it runs, on the cards and in the open chat. [See the chats code ›](https://github.com/igorkurilenko/tab_overview/tree/main/example/lib/chat_tabs)

<p align="center">
  <img src="https://github.com/igorkurilenko/tab_overview/blob/main/assets/tab_overview_chats.webp?raw=true"
    alt="Flutter chats as tabs: a tapped card opens into its chat on a spring, its avatar, name and latest message flying to their places, and a pull down on the chat's bar closes it back into its card" width="240"/>
</p>

## Questions? Answers.

<details>
<summary><b>How do I make a tab switcher in Flutter?</b></summary>

Give a `TabOverviewController` your tabs, and build their pages in `TabOverview.builder`, as the [example above](#take-a-closer-look) does. The tabs show as live thumbnails in a grid: `expand` zooms one into its page, and `collapse`, or a pull down with `pullToCollapse`, zooms it back out. A tab can be anything: a number, as here, or your own model of a document, a chat or a form.

</details>

<details>
<summary><b>Is this a TabBar?</b></summary>

No. Flutter's `TabBar` shows a row of tab labels, and its `TabBarView` swipes between their pages. tab_overview shows multiple tabs at once, each as a thumbnail of its page, and zooms the tapped one into a full page, where a swipe turns to the next tab. People add, close and reorder the tabs as they go.

</details>

<details>
<summary><b>How do I add and close tabs dynamically?</b></summary>

Call the controller's `add` with a new tab, or `remove` with the tab to close, as the example's buttons do. A tab's close button and a swipe to the left close it too, and `isTabRemovable` keeps a tab from being closed.

</details>

<details>
<summary><b>How do I reorder tabs with drag and drop?</b></summary>

There's nothing to add: a long press lifts a thumbnail, and a drag moves it, as the others slide out of its way. `isTabReorderable` keeps a tab in its place, and `addTabsReorderedListener` tells you when the order changes, which the controller's `tabs` then has.

</details>

<details>
<summary><b>What happens to a tab's state when it zooms?</b></summary>

The tab's page is built anew as it zooms in or out, so a `State` in it starts over. Keep what should carry over, such as a scroll offset or typed text, in your tab object, and give it to the page as it's built. Tabs added, closed or moved around a tab keep its state.

</details>

<details>
<summary><b>Can a thumbnail look different from its page?</b></summary>

Yes. `tabThumbnailBuilder` builds a tab's thumbnail, such as a card with the tab's title, in place of its scaled-down page. As the tab zooms in, the card fades into the page, and a `TabHero` with the same tag on both flies a part, such as the title, to its place on the page. The [chats example](#chats-as-tabs) shows it.

</details>

<p><small>1. Recorded from the examples frame by frame, at 60 fps, in an iPhone 15 frame.</small></p>
