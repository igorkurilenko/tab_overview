<h1 align="center">tab_overview: Tab switcher for Flutter</h1>

<p align="center">Like Flutter's <code>TabBarView</code>, but with every tab shown at once as a live thumbnail that zooms into its page.</p>

<p align="center">
  <a href="#installation">Get started ›</a>&emsp;<a href="https://pub.dev/packages/tab_overview/example">See the examples ›</a>
</p>

tab_overview is a Flutter package for a tab switcher: the tabs your app keeps open, such as chats, documents or forms, show as live thumbnails in a grid, and a tap zooms one into a full page. Swipe between the pages, then zoom back out to the grid with a button, or by pulling the page down with `pullToCollapse`. Drag a thumbnail to reorder the tabs, and swipe it away or tap its close button to close it. Flutter's `TabBar` switches between a row of tabs; tab_overview is for multiple tabs that people add, close and reorder as they go, as in the tab overview of Safari or the tab switcher of Chrome. Its zoom is a hero animation within the same page, from [hero_here](https://pub.dev/packages/hero_here), and its grid reorders with [animated_reorderable](https://pub.dev/packages/animated_reorderable).

## Flutter tab switcher examples

<table>
  <tr>
    <td align="center" valign="top" width="50%">
      <img src="https://github.com/igorkurilenko/tab_overview/blob/main/assets/tab_overview_tab_switcher.webp?raw=true"
        alt="Flutter tab switcher: a tap zooms a thumbnail into its page, a swipe turns to the next one, and a pull down zooms back out to the grid; + adds a tab, a drag takes it to the front, and a swipe closes it" width="220"/>
      <p><b>Tab switcher with live thumbnails</b></p>
      <p>Numbered tabs as live thumbnails in a grid: tap one, and it zooms into its page, where a swipe turns to the next tab. Pull the page down, and it zooms back out. Drag a thumbnail to reorder the tabs, swipe it away to close its tab, and tap + to add one. <a href="https://github.com/igorkurilenko/tab_overview/blob/main/example/lib/main.dart">See the code ›</a></p>
    </td>
    <td align="center" valign="top" width="50%">
      <img src="https://github.com/igorkurilenko/tab_overview/blob/main/assets/tab_overview_chats.webp?raw=true"
        alt="Flutter chats as tabs: a tapped card opens into its chat on a spring, its avatar, name and latest message flying to their places, and a pull down on the chat's bar closes it back into its card" width="220"/>
      <p><b>Chats as tabs</b></p>
      <p>A messenger's chats as cards of their own: tap one, and the chat opens on a spring, its avatar, name and latest message flying to their places on its page with <code>TabHero</code>. Pull it down by its bar, and it closes back into its card. <a href="https://github.com/igorkurilenko/tab_overview/tree/main/example/lib/chat_tabs">See the code ›</a></p>
    </td>
  </tr>
</table>

## Features

- **Overview and Expanded Modes**: Users can view all tabs in a grid format (overview mode) or expand a selected tab for a detailed view.
- **Reorderable and Removable Tabs**: Drag-and-drop reordering and tap-to-remove functionality provide a natural tab management experience.
- **Customizable Animations and Layouts**: Fine-tune animation duration and curve, or zoom on a spring, and the grid layout and decorations for thumbnails and expanded views.
- **Thumbnails of Your Own**: Show each tab as a card of your own, such as a chat's avatar, name and latest message, and fly its parts to their places on the page with `TabHero`.
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
- **dragGestureRecognizerFactory & heldThumbnailBuilder**: How a thumbnail is picked up to move it, a long press by default, and how it looks while it's held, scaled up and faded a little by default. A recognizer of your own can pick it up sooner, or only by a part of it, such as an avatar, and a builder of your own gets the animation of it being picked up and let go.
- **Expanded and Thumbnail Views**: Customize how each tab appears in both overview and expanded modes.

## API Overview

### Classes

- **TabOverview**: The widget that shows the tabs, as a grid of thumbnails or as the expanded tab's page.
- **TabOverviewController**: Holds the tabs, the active tab and the mode, and animates the changes:
  - `add` and `remove` return whether they changed anything. `removeAt` removes the tab at an index. Each takes an optional `duration` and `curve`, which override the controller's `addRemoveTransition`.
  - `scrollToTab` and `scrollToTabAt` scroll to a tab, over the controller's `scrollTransition` unless a call says otherwise.
  - `expand`, `expandAt`, `collapse` and `toggleMode` switch the mode. Each takes an optional `duration` and `curve`, which override the controller's `transition`.
  - `activeTab` is the tab the expanded view shows, and `activeIndex` is its index, or `null`.
  - `isTransitioning` tells whether a tab is flying between its thumbnail and its page.
  - It's a `ChangeNotifier`, and also has typed listeners for each kind of change.
- **TabTransition**: How long an animation takes, and how it eases. The controller's `transition` sets it for expanding and collapsing, its `addRemoveTransition` for adding and removing tabs, and its `scrollTransition` for scrolling to a tab. The widget's `thumbnailsMotion` sets it for thumbnails moving in the grid. `TabTransition.spring` makes one that tabs expand and collapse on as on a spring.
- **TabHero**: A part of a tab, such as its title, that flies on its own between the tab's thumbnail and its page.
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
- **tabDecorationBuilder**: Build each tab's decoration from where it is on its way, how high it's lifted and which way it heads, such as with a shadow of your own. `TabDecorations.lifted` and `TabDecorations.flat` are ready-made.

As a tab zooms, its decoration turns from the one into the other, and, by default, it casts a soft shadow in its decoration's shape, which grows as it leaves its place and fades as it lands, so it reads apart from the grid it flies over. A page pulled down with `pullToCollapse` casts one too.

### Transitions

A tab expands and collapses over 300 ms along `Curves.easeInOut`. To change that everywhere, give the controller a `transition`:

```dart
final controller = TabOverviewController<Tab>(
  transition: const TabTransition(duration: Duration(milliseconds: 450)),
);
```

A call can still pass its own `duration` and `curve`, as in `controller.expand(tab, duration: ...)`. Thumbnails moving to new places in the grid follow the widget's `thumbnailsMotion`.

To expand and collapse tabs on a spring, give the controller a `TabTransition.spring`. A tab then flies from where it is at the speed it has, so a page let go of mid-pull collapses as fast as it was pulled, and a spring with some bounce carries it a little past its page's size, or its thumbnail's, and back:

```dart
final controller = TabOverviewController<Tab>(
  transition: TabTransition.spring(
    SpringDescription.withDurationAndBounce(
      duration: const Duration(milliseconds: 350),
      bounce: .15,
    ),
  ),
);
```

Tabs added and removed scale and fade in and out over 350 ms, linearly, and scrolling to a tab takes 350 ms along `Curves.easeInOut`. The controller's `addRemoveTransition` and `scrollTransition` change those everywhere, and a call to `add`, `remove`, `removeAt`, `scrollToTab` or `scrollToTabAt` can pass its own:

```dart
final controller = TabOverviewController<Tab>(
  addRemoveTransition: const TabTransition(
    duration: Duration(milliseconds: 250),
    curve: Curves.easeOut,
  ),
  scrollTransition: const TabTransition(duration: Duration(milliseconds: 500)),
);
```

A tab swiped away doesn't scale or fade, whatever `addRemoveTransition` says: it flies off as it is when let go, at the speed it's let go at, speeding up evenly if it would otherwise take more than a quarter of a second to get out of sight.

### Thumbnails of Your Own

With `tabThumbnailBuilder`, a tab's thumbnail can be a card of its own rather than its page scaled down, such as a chat's avatar, name and latest message. As the tab zooms in, its card fades into its page, and back as it zooms out. Wrap a part that's on both, such as the chat's name, in a `TabHero` with the same tag on each, and it flies on its own from its place on the card to its place on the page:

```dart
TabOverview<Chat>.builder(
  controller: controller,
  tabThumbnailBuilder: (context, chat) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      TabHero(tag: 'avatar', child: Avatar(chat.name, size: 64)),
      TabHero(tag: 'name', child: Text(chat.name)),
      TabHero(tag: 'last message', child: Text(chat.lastMessage)),
    ],
  ),
  // ChatPage shows the avatar and the name in its bar, and the last
  // message at its bottom, each in a TabHero with the same tag.
  tabBuilder: (context, chat) => ChatPage(chat),
)
```

A part that's a scaled copy of the other, such as a name set bigger, grows or shrinks as it flies, and a message wrapped to another width fades from the one into the other, each keeping its own lines, so no word jumps from line to line. The [chats example](https://github.com/igorkurilenko/tab_overview/tree/main/example/lib/chat_tabs) shows chats as cards that open into their pages this way.

### Pull to Collapse

With `pullToCollapse: true`, the expanded tab can be pulled down to collapse it, as in hero_here's show details example. It's pulled by a drag on a part of it outside its scroll views, such as an app bar above a list, or anywhere on a tab without one. A drag in a vertical scroll view only scrolls it, so a list never pulls its tab, whether it's at its top or, as a chat's list is, at its bottom. As it's pulled, the tab shrinks and its corners round toward `thumbnailDecoration`'s. Let go once it's pulled 50 pixels, or while it moves down fast, and it collapses into its thumbnail from where it is, at the speed it had. Otherwise it goes back.

It's off by default.

## License

This package is licensed under the Apache License, Version 2.0. See [LICENSE](https://www.apache.org/licenses/LICENSE-2.0) for details.