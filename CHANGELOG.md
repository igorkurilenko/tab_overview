# Changelog

## [0.3.0]
### Added
- `TabHero`, a part of a tab, such as its title or its latest message, that flies on its own between the tab's thumbnail and its page as the tab zooms in and out. Put one with the same tag in what `tabThumbnailBuilder` builds and in what `tabBuilder` builds. A part that's a scaled copy of the other grows or shrinks as it flies, and one of another shape, such as a message wrapped to another width, wraps anew as it flies. A tag needs to be unique only among the tab's own parts.
- `TabTransition.spring`, which expands and collapses tabs on a spring: from where a tab is, at the speed it has, so a page let go of mid-pull collapses as fast as it was pulled. A spring with some bounce carries a tab a little past its page's size or its thumbnail's, and back. A call to `expand` or `collapse` that passes its own `duration` or `curve` flies along that instead.

### Changed
- A thumbnail of the app's own fades into its page as the tab zooms in, and back as it zooms out. On the way, the page shows as it would in a window of the zooming tab's shape, at the overview's width, so its bars stay at its top and bottom, and its text wraps as on the page. Before, the zoom showed only the page as it zoomed in, scaled to the tab's width, and only the thumbnail as it zoomed out, laid out anew at each size it took.

### Example
- Add a chats example, `lib/chat_tabs/`: chats as cards in the shape of an Apple Watch Ultra's screen, laid out as a watch shows a message, two columns of them on a phone and one on a watch. A tap opens a chat on a spring, its avatar, name and latest message flying to their places on its page, and a pull down on its bar closes it. Its page has a bar like Signal's, floating over the messages, and messages without bubbles.

## [0.2.10]
### Changed
- `pullToCollapse` pulls a tab only by a drag on a part of it outside its scroll views, such as an app bar above a list, or anywhere on a tab without one. A drag in a vertical scroll view now only scrolls it. Before, a list dragged down past its top pulled the tab, and so did a chat's list, which starts at its bottom, dragged up past its newest message. A `RefreshIndicator` at the top of a list no longer competes with the pull either.

## [0.2.9]
### Example
- Open the example with tabs 1 to 5 in the grid, in hero_here's look: Geist type, neutral grays with Pinterest's red as the one accent, squircle corners, and Unicons 4.0.0 line icons, under the Apache License 2.0, painted from their SVG paths. The look lives in `lib/style/` and `lib/tab_page.dart`, and `main.dart` builds the tab switcher in numbered steps. The README's recording shows it.

### Docs
- Give the Example tab a page of its own, `example/example.md`: what the example does, its recording, its highlights, its code in three steps, and answers to the questions people ask. A test keeps its code the same as `lib/main.dart`. The package ships only that page from the example folder.
- Lead the API docs with what the package does. The library's page says it's a tab switcher whose tabs show as live thumbnails in a grid and zoom into full pages, compares it with `TabBar`, lists what it does and gives a short example. `TabOverview`, `TabOverviewController`, `TabOverviewMode`, `RemoveTabButton` and `ModelWidgetBuilder` say first what they are. `TabOverview`'s docs pointed to a constructor that doesn't exist, rather than `TabOverview.builder`.

## [0.2.8]
### Changed
- Require animated_reorderable 2.9.0, and reorder tabs with its `ItemMoves` rather than `Permutations`, which 2.9.0 deprecates. pub.dev's analysis counted each use of `Permutations` as an issue, which cost the package 10 of its 160 points.

### Docs
- Describe the package in the words people search for. Its description now says it's a tab switcher with live thumbnails, which show the tabs an app keeps open in a grid and zoom into full pages, and it has the topics tabs, transition, animation, drag-and-drop and reorderable. The pubspec now gives the GitHub repository as its `repository` rather than its `homepage`.
- Head the README with "Tab switcher for Flutter", and open it with what the package does, in place of a paragraph about a "visually rich tab management interface".
- Show the example in the README as a recording in a phone frame: an animated WebP at 60 fps, centered, in place of a GIF with the debug banner. Its alt text describes it rather than calling it "The hero_here basic example". The README's recordings load from GitHub, so a `.pubignore` keeps `assets/` out of the package.

## [0.2.7]
### Changed
- A tab swiped away flies off as it is when let go, rather than shrinking and fading out over `addRemoveTransition`, and its thumbnail isn't built again as it goes. A tab removed with its remove button, `remove` or `removeAt` still scales and fades out. `addRemoveTransition`'s docs and the README now say so. From animated_reorderable 2.7.0.
- A thumbnail let go short of its place, after a short swipe or a drag, springs back smoothly: it speeds up over its first frames, rather than standing still for a frame and then jumping off, and lands sooner. Let go at rest 60 pixels from its place, it's within half a pixel of it after about 270 ms rather than 350. One flicked fast at its place stops there in 50 to 100 ms rather than 210 to 290, and its lift, which enlarges it a little and makes it see-through, drops back as it lands, in about 100 ms rather than 250. From animated_reorderable 2.8.0, which this release requires.

## [0.2.6]
### Changed
- Removing a tab, swiping it away or dragging it past others builds no other tab's thumbnail. The tabs that moved up into its place, and those a dragged tab passed, were built again, though only their place changed. Resizing the overview builds no thumbnail again either; wider than 600 pixels, it built every visible one on each frame of a window resize or of the keyboard opening. With thumbnails of 30-row lists, in a macOS profile build, the frame a tab is swiped away or removed on takes about 8 ms rather than 28. A thumbnail still builds again when the overview does, and when anything it depends on changes.

### Fixed
- A removed tab's thumbnail keeps its state as it fades out, whether it was removed or swiped away. It was built anew, so a thumbnail with state of its own, such as a video, started over as it went.
- A tab swiped away flies off at the speed it's let go at, and a slow swipe speeds up evenly to leave in a quarter of a second. It stood still for a frame as it was let go, went on at two to eight times the finger's speed, and slowed down on its way out. A tab swiped from the grid's right column flies over the tabs beside it, too, rather than dropping under them. Fixed in animated_reorderable 2.6.1, which this release requires.

## [0.2.5]
### Fixed
- With hero_here 2.1.1 or later, a tab whose thumbnail is off screen flies in from the overview's edge again as it expands. Its page showed at once, and its expand never ended: `isTransitioning` stayed true until the tab collapsed, and the grid didn't scroll to the tab, so removing it collapsed the overview to where the grid was rather than to its neighbour. The grid hid the tab's stand-in under a disabled `HeroMode`, which hero_here 2.1.1 leaves out of flights, as Flutter's `HeroMode` does. It now removes it.

## [0.2.4]
### Added
- A screen reader can move a thumbnail up or down a row, as well as left, right, and to the start or end of the grid. It comes with animated_reorderable 2.5.0, which this release requires.

## [0.2.3]
### Added
- `TabOverviewController.addRemoveTransition` and `scrollTransition` set how tabs are added and removed, and how the overview scrolls to a tab, for every call that doesn't say otherwise, as `transition` does for expanding and collapsing. `add`, `remove`, `removeAt`, `scrollToTab` and `scrollToTabAt` take a nullable `duration`, and `add`, `remove` and `removeAt` a `curve` too, which override them. The defaults are as before: 350 ms, linear, for adding and removing, and 350 ms along `easeInOut` for scrolling.

### Fixed
- On Android, a list pulled from its top to collapse its tab no longer stretches or glows with its own overscroll as the page moves. A fling into the top, which pulls nothing, still shows it.

## [0.2.2]
### Fixed
- Removing the only tab on the grid's last row, scrolled to the end, slides the tabs above down into its place as it fades. The grid jumped down a row in one frame, so the tab that took its place on screen covered the removed tab, and its removal didn't show. Fixed in animated_reorderable 2.4.0, which this release requires.
- A tab's remove button flies in step with its tab as the tab collapses or expands. It followed a 300 ms flight of its own, so it trailed a tab flung to its thumbnail by a pull, or one collapsing for a duration of its own, and caught up as both landed.
- A typed listener, such as one passed to `addModeChangedListener`, may add or remove listeners while it's notified, itself too. It threw a `ConcurrentModificationError`. As with a `ChangeNotifier`, a listener removed before its turn isn't called, and one added waits for the next change.

### Changed
- Requires animated_reorderable 2.4.0. Its default animations are faster, at the pace of Flutter's own lists: a thumbnail lifts as a drag begins, and drops back as it's let go or swiped, in 250 ms rather than 500, and a thumbnail flung back to its place, or swiped out, gets there in about half the time. Thumbnails moving to new places, and tabs added and removed, keep tab_overview's own pace.

## [0.2.1]
### Changed
- Pulling an expanded tab's page down to collapse it now brings the grid behind it back as you pull. Half way, the grid is half faded in and half zoomed back. Let go short, and it goes back with the page. Let go to collapse, and it carries on from where the pull left it. Before, the grid stayed hidden until the tab began to collapse.

## [0.2.0]
0.2.0 removes what 0.1.20 and 0.1.21 deprecated, and changes a few names and errors. Fix any deprecation warnings on 0.1.21 first; the table below covers the rest.

### Migrating from 0.1
| 0.1 | 0.2.0 |
|---|---|
| `removeTabAt(index)` | `removeAt(index)` |
| `indexOfActiveTab()` | `activeIndex`, which is `null` rather than −1 |
| `isAnyExpanding`, `isAnyCollapsing`, `isExpanding(tab)`, `isCollapsing(tab)` | `isTransitioning` |
| `addOffScreenThumbTabAddedListener` and the other three stand-in listener methods | Removed. Listen to the controller as a `ChangeNotifier`, or to its typed listeners. |
| A tab model implementing `RemovableTab` or `ReorderableTab` | `TabOverview(isTabRemovable: (tab) => tab.removable, isTabReorderable: (tab) => tab.reorderable)` |
| `RemoveTabButton(controller: controller, tab: tab)` | `RemoveTabButton(onPressed: () => controller.remove(tab))` |
| `thumbnailsMotionAnimationDuration` and `thumbnailsMotionAnimationCurve` | `thumbnailsMotion: TabTransition(duration: ..., curve: ...)` |
| `kExpandedTabPageViewportFraction`, `kThumbsGridScaleWhenExpanded`, `kThumbsGridOpacityWhenExpanded`, `kDefaultThumbnailsGrid…Spacing` | Removed. Set the grid's spacing through `thumbnailsGridDelegate`. |
| `activeTab = tab` for a tab not in the overview | Throws an `ArgumentError`, as `expand` does |
| `TabOverviewController(activeTab: tab)` with a tab not among `initialTabs` | Throws an `ArgumentError`, where it used to make the first tab active |
| `scrollToTab(tab)` for a tab not in the overview | Throws an `ArgumentError` |
| `scrollToTabAt(index)` for an index out of range | Throws a `RangeError` |

### Added
- `TabTransition(duration, curve)`, and `TabOverviewController.transition`. The transition sets how tabs expand and collapse, 300 ms along `easeInOut` by default. `expand`, `expandAt`, `collapse` and `toggleMode` take a nullable `duration` and `curve` that override it.
- `isTransitioning`: whether a tab is flying between its thumbnail and its page.
- `RemoveTabButton` is exported, so a custom `removeTabButtonBuilder` can keep the default look.
- `ModelWidgetBuilder` is exported.
- `TabOverview.builder` is `const`.

### Changed
- A controller method that takes a tab throws an `ArgumentError` for a tab that isn't in the overview. `remove` is the exception: it returns `false`. A method that takes an index throws a `RangeError` for an index out of range. The controller's docs say so.
- `removeTabButtonBuilder` and `tabThumbnailBuilder` are nullable. `null` means the default, built when the overview builds.
- The package exports each public name explicitly, so internal names can't leak into the API.
- Requires animated_reorderable 2.2.1.
- Allows hero_here 2.0.0, as well as 1.5.4 and later 1.x releases.
- Square tabs clip their content with a hard edge. Only a rounded or shaped decoration uses an anti-aliased clip, which costs more on every frame of a flight.

### Fixed
- `TabOverviewController(initialTabs: [])` no longer throws a `StateError`. With no tabs, no tab is active.
- Long-pressing a thumbnail while it's still sliding into place no longer makes it jump back where it was, up to a row away, as the drag begins. Fixed in animated_reorderable 2.2.1, which this release requires.
- With tabs added while a tab is expanded, setting `activeTab` shows that tab's page and keeps it active. The expanded pages kept the scroll length they had until a swipe, so the setter's jump stopped short, a different tab became active, and a collapse then left the overview ignoring taps. It goes back to 0.1.17 at least.

### Removed
- Everything deprecated in 0.1.20 and 0.1.21, as listed in the table above.
- The five `k…` tuning constants, and `RemoveTabButton`'s `buttonStyle` and `buttonColor` getters.

## [0.1.21]
### Added
- `activeIndex`: the active tab's index in `tabs`, or `null` if no tab is active.

### Fixed
- `expand`, `toggleMode`, `collapse` and `scrollToTab` no longer throw when called before the overview is first built, as from an app's `initState`. With nothing to animate yet:
  - `expand` makes the tab active and the mode expanded, and the overview builds showing that tab's page.
  - `collapse` makes the mode overview.
  - `scrollToTab` does nothing in overview mode, with no grid to scroll yet, and shows the tab's page in expanded mode.

### Changed
- The controller is restructured inside, with no change in behaviour or public API:
  - The grid and the expanded pages connect to the controller through two small interfaces, rather than GlobalKeys.
  - The tabs' animations between thumbnail and page are tracked in a class of their own.
  - One sealed type tracks whether the overview is heading to the grid or to the expanded view, including an off-screen tab's expand while it waits a frame.

### Deprecated
- `indexOfActiveTab()`: use `activeIndex`. It goes in 0.2.0.

## [0.1.20]
### Added
- `TabOverviewController` is a `ChangeNotifier`. It notifies its listeners when the mode, the active tab or the tabs change, so a `ListenableBuilder` can rebuild with it. The typed listeners stay.
- `TabOverview.isTabRemovable` and `isTabReorderable` tell which tabs the user may close or move. The tab model no longer has to implement an interface.
- `removeAt(index)`, the name `List` uses.

### Fixed
- `remove(tab)` for a tab that isn't in the overview does nothing and returns `false`. Before, it threw a `RangeError`. It returns `true` once the tab is removed, so `remove` now returns a `bool`.

### Changed
- Requires hero_here 1.5.4 and animated_reorderable 2.1.0. Both fix problems found while testing tab_overview:
  - A flight no longer throws when the page view moves the page it's flying to.
  - A flight whose destination goes away mid-flight shows its source again.
  - Thumbnails move in place.
  - Opening the keyboard no longer rebuilds every thumbnail's content on each frame.
- Calling `dispose` twice, or using the controller after it, fails an assertion in debug mode, as Flutter's own controllers do.
- The `activeTab` docs say what the active tab is: the tab the expanded view shows and that `toggleMode` expands, wherever its thumbnail is scrolled.

### Deprecated
These go in 0.2.0:
- `removeTabAt`: use `removeAt`.
- `RemovableTab` and `ReorderableTab`: use `isTabRemovable` and `isTabReorderable`.
- The four stand-in listener methods, `add`/`removeOffScreenThumbTabAddedListener` and `add`/`removeOffScreenThumbTabRemovedListener`. Stand-ins are placeholders the overview keeps for its own animations, and nothing an app can act on.

## [0.1.19]
### Fixed
- A collapse lands in view when the expanded tab's thumbnail was built just past the edge of the grid's view. The grid builds thumbnails a little beyond its edges. It scrolled to the expanded tab's thumbnail only if that thumbnail wasn't built, so the tab flew out of view in two cases:
  - after a relayout, such as a window shrinking rows of a fixed height
  - after expanding a tab whose thumbnail was built out of view

  Now the grid scrolls to the thumbnail unless its middle is in view. A thumbnail mostly in view, such as one tapped at the bottom edge, stays where it is.

## [0.1.18]
### Fixed
- Setting `activeTab` while expanded shows that tab's page, as its doc says. Before, the pages went on showing the tab that was active, and a collapse then left the overview ignoring taps, with both tabs' thumbnails empty.
- Setting `activeTab` while an expand is still under way turns the expand to that tab. That covers both an expand whose pages aren't built yet, which left the overview ignoring taps, and an off-screen expand still waiting for its stand-in, which the setter cancelled.
- Setting `activeTab` while the active tab still flies to its page flies that tab back to its thumbnail as the new tab's page opens. The mode listeners are told of the collapse and the expand.

## [0.1.17]
### Fixed
- Expanding a tab, then expanding another or calling `scrollToTab` in the same event, no longer throws. The overview expands the second tab. It goes back to 0.0.5 at least.
- A call in the same event as expanding a tab whose thumbnail is off screen now wins. Before, the off-screen expand, which waits a frame for its stand-in, came last.
  - Expanding another tab expands that tab.
  - `collapse()` cancels the expand.
  - Making another tab active with the `activeTab` setter no longer leaves the overview ignoring taps.
- Collapsing a tab whose thumbnail is off screen switches to the grid at once, rather than a frame later. Its flight sets off a frame sooner.
  - An expand in the same event, of another tab or the same one, now expands it, rather than being lost.
  - Removing the tab in the same event tells the mode listeners of the change once, rather than twice.

## [0.1.16]
### Fixed
- The expanded tab keeps its State when a tab before it is removed: what was typed in a text field, its focus, and any other State of the tab's content. Its page was built anew one place down. It goes back to 0.0.5, where adding or removing any tab lost it.

## [0.1.15]
### Fixed
- Removing the expanded tab no longer leaves the overview ignoring taps when a tab is added or removed in the same event or the next frame, or when the overview's parent rebuilds then, as `setState(() => controller.remove(tab))` does. The removed tab's collapse never started, and adding or removing a tab showed the first tab's page for a frame.
- Collapsing the expanded tab and expanding another in the same event expands it. The overview kept showing the collapsed tab's page, and ignored taps from then on.
- Removing the expanded tab and expanding another, or calling `toggleMode`, in the same event expands that tab, rather than ending in the overview.
- Expanding a tab whose thumbnail is off screen and another tab in the same event no longer leaves the overview ignoring taps. It ends on the off-screen tab, whose expand waits a frame for its stand-in and so comes last.

The first two go back to 0.0.5 at least.

### Changed
- Removing the expanded tab collapses it at once: by the time `remove` returns, the mode is `overview` and the tab after it is active, and the listeners have been told, rather than two frames later. Its collapse sets off two frames sooner, together with its thumbnail's shrinking.

## [0.1.14]
### Changed
- Require animated_reorderable 2.0.0. An app that depends on animated_reorderable itself needs 2.0 too. tab_overview's API doesn't change.
- Thumbnails move with animated_reorderable 2.0's motion: a thumbnail whose place moves again while it's moving heads there at the speed it has, rather than starting over from rest.

## [0.1.13]
### Changed
- Add tabs through animated_reorderable's `insertTransition`, rather than the `insertItem` builder, which animated_reorderable 1.6 deprecates and 2.0 removes. Tabs are added and removed as before.

## [0.1.12]
### Fixed
- While tabs are reordered, a tab moved again just as its slide ends slides there, rather than jumping a slot without animating. Fixed in animated_reorderable 1.6.1.

### Changed
- Require animated_reorderable 1.6.1.

## [0.1.11]
### Added
- `pullToCollapse`, off by default: pull the expanded tab down to collapse it, as in hero_here's show details example. The tab is pulled from the top of its vertical scroll view, or from anywhere on a tab without one. As it's pulled, it shrinks and its corners round toward the thumbnail's. Let go once it's pulled 50 pixels, or while it moves down fast, and it collapses from where it is, at the speed it had. Otherwise it goes back. The example turns it on, and lets the mouse drag, as hero_here's examples do.

## [0.1.10]
### Fixed
- Removing a tab in the same event as expanding it from off screen no longer leaves the overview ignoring taps. The overview expanded the tab that took the removed one's place instead of staying put, and its grid ignored taps from then on, after a collapse too.
- Removing a tab right after expanding it, before the overview builds its page, leaves the overview where it was. It scrolled to its top, and the removed tab stayed built, hidden, for as long as the overview lived.
- Removing the active tab of a controller created expanded, before the overview is first built, no longer leaves the overview ignoring taps.

All three go back to 0.0.5 at least.

## [0.1.9]
### Fixed
- Removing a tab other than the last and adding one in the same event, such as closing a tab and opening another in one handler, no longer throws `RangeError`s. Fixed in animated_reorderable 1.6.0.

### Changed
- Require animated_reorderable 1.6.0.

## [0.1.8]
### Fixed
- Removing the expanded tab collapses to the tab that takes its place. Since 0.0.6, the overview scrolled to its top instead, leaving that tab off screen.
- Removing a tab while it expands from off screen leaves the overview where it was. It scrolled to the top.

## [0.1.7]
### Changed
- Rebuild only the thumbnail of the tab that expands or collapses, not every thumbnail. Expanding a tab rebuilt every other thumbnail once, and collapsing it rebuilt every thumbnail twice.

## [0.1.6]
### Fixed
- A tab whose hash code changes while it flies, such as one whose equality follows a title that changes as its page loads, no longer leaves the overview ignoring taps.
- `scrollToTab` scrolls all the way to a tab just added on a new row. It stopped a row short.

## [0.1.5]
### Fixed
- Show a tab that's added again while its removal still animates, as when a closed tab is brought back right away. It was in `tabs`, but its thumbnail never showed.
- Listen to a tab's add or remove animation once, rather than once more on every rebuild while it animated.
- In the example, the minus button closes the active tab. It removed the second tab, and threw once only one was left. New tabs are numbered from a counter, so numbers don't repeat after a removal.

## [0.1.4]
### Fixed
- Expanding a tab while it collapses, or collapsing it while it expands, no longer leaves the overview ignoring taps, or the expanded tab with the thumbnail's decoration. 0.1.0 had this when the turn came early in the flight; with hero_here 1.5.0 it came at any point. The same goes for expanding and collapsing in one go.

### Changed
- A tab turned around mid-flight now swings toward where it's sent, from where it is and at the speed it had, rather than going back along its path. Its decoration turns from what it shows, and the flight keeps its duration and curve.
- Require hero_here 1.5.1, whose diverted flights slide along the overview's edge rather than out of it.

## [0.1.3]
### Added
- Export `FittedTab`, so a custom `tabThumbnailBuilder` can show a tab as the default thumbnail does: laid out at the overview's size and scaled to fit.

## [0.1.2]
### Fixed
- Keep an added tab's state, such as its text, focus and scroll position, when its add animation ends. The first rebuild after the animation re-created the content of its thumbnail, or of its page if it was expanded right away.

### Changed
- Stop repainting a flying tab's content on each frame of the flight. During an expand or a collapse, it painted on 20 of the flight's 21 frames; now it paints twice, once as the flight starts and once where it lands.
- Rebuild only the thumbnails that a swipe between expanded tabs changes, not all of them.

## [0.1.1]
### Changed
- Require hero_here 1.5.0. Expanding or collapsing a tab no longer shows a screenshot of the overview for a frame, and the tab starts to fly a frame sooner.

## [0.1.0]
### Fixed
- Follow a new `controller` given to the overview. The overview showed the new tabs, but `expand` and `toggleMode` failed with a null check, and the old controller still drove it.
- Collapse a tab whose hash code is the same as another tab's. It failed with a null check, and the other tab's thumbnail stayed hidden.
- Move thumbnails along `thumbnailsMotionAnimationCurve`. It was ignored.
- Keep one `PageController` while a tab is expanded, rather than a new one on each build, and dispose it, and the grid's `ScrollController`, when they're no longer needed. Neither was disposed.

### Changed
- **Breaking:** `TabOverview.builder` requires a `controller`. Without one, the overview created its own on each rebuild, which nothing could add tabs to, so it was always empty.

## [0.0.6]
### Fixed
- Keep an expanded tab's state, such as its text, focus and scroll position, the first time something rebuilds it after it expands, such as the keyboard opening or a `setState` above the overview. It was re-created.
- Collapse to the tab's thumbnail after a window resize while expanded. The tab flew off the screen, and the overview showed other tabs.
- Size tabs by the overview, not the screen. Under an app bar, an expanded tab was cropped; beside a sidebar, it was letterboxed; and off-screen tabs flew in from outside the overview.

### Changed
- Require hero_here 1.4.1.
- Lay tab content out at the overview's size. Under a `Scaffold`, it now shrinks when the keyboard opens, like any other body, so content with a fixed height can overflow.
- Show the tabs on every frame while the window resizes, while the keyboard opens and when the overview's parent rebuilds. Only a change between overview and expanded runs a hero switch, which shows a snapshot for a frame.

## [0.0.5]
### Fixed
- Show the overview on screens narrower than 300 pixels; it showed a placeholder.

### Changed
- Require Dart 3.13 and Flutter 3.47.
- Require animated_reorderable 1.5.0 and hero_here 1.1.0, so thumbnails keep their state while they move and tab transitions stay in place when the overview isn't at the screen's top-left corner.
- Update the example to the current Flutter templates.

## [0.0.4]
### Fixed
- Fix tab activation.

## [0.0.3]
### Fixed
- Flight animation creation for expanded initial mode.

## [0.0.2]
### Fixed
- Resolved a bug where the `TabOverview` widget would cause an error when in expanded mode with no tabs present.

## [0.0.1]
### Added
- Initial release of `tab_overview`, a customizable widget for managing tabs with smooth transitions and a thumbnail grid view.
- **TabOverview widget**: Displays tabs in both overview (grid of thumbnails) and expanded modes.
- **Responsive grid layout**: Automatically adjusts the number of columns based on screen size (large, medium, small, and extra small).
- **TabOverviewController**: Manages tab state, allowing users to add, remove, reorder, and toggle between tabs.
- **Customizable animations**: Adjustable animation duration and curve for smooth transitions.
- **Reorderable and removable tabs**: Supports tab reordering and optional removal through the `ReorderableTab` and `RemovableTab` interfaces.
- **Optional Decorations**: Customizable styling for thumbnails and expanded tab views.
- **Dependencies**:
  - `animated_reorderable` for drag-and-drop functionality in the grid view.
  - `hero_here` for smooth transitions between thumbnail and expanded views.
